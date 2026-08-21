/// inpatient_system.gml
/// @description Стационар с несколькими койками: перевод, персонал, назначения, циклы лечения и возврат владельца.
/// Пакет №73: 4 койки в одной палате. Койка определяется по exam_slot_id (101–104),
/// как у столов приёма. Врач и ассистент общие на палату.
/// Пакет №110: роли операционной (Хирург / Анестезиолог / Ассистент).
/// Пакет №112: послеоперационный пациент принимается в стационар при любом состоянии.
/// Пакет №135: ссылки койки обновляются раз в 10 кадров (оптимизация логики).


// ═══════════════════════════════════════════════════════════════
// 1. ВРЕМЯ И ОСНОВНЫЕ ССЫЛКИ
// ═══════════════════════════════════════════════════════════════

function inpatient_now_absolute_minute() {
    var _day = variable_global_exists("game_day") ? global.game_day : 1;
    var _hour = variable_global_exists("game_hour") ? global.game_hour : 0;
    var _minute = variable_global_exists("game_minute") ? global.game_minute : 0;

    return _day * 1440 + _hour * 60 + _minute;
}

function inpatient_get_controller() {
    return instance_exists(obj_inpatient_controller)
        ? instance_find(obj_inpatient_controller, 0)
        : noone;
}


// ═══════════════════════════════════════════════════════════════
// 1.1 НЕСКОЛЬКО КОЕК (пакет №73)
// ═══════════════════════════════════════════════════════════════

function inpatient_find_by_slot(_object, _slot) {
    var _fallback = noone;

    for (var _index = 0; _index < instance_number(_object); _index++) {
        var _inst = instance_find(_object, _index);

        if (!instance_exists(_inst)) continue;
        if (!instance_exists(_fallback)) _fallback = _inst;

        var _exam_match = (
            variable_instance_exists(_inst, "exam_slot_id")
            && _inst.exam_slot_id == _slot
        );

        // Пакет №73 (hotfix): точки стационара раньше не имели exam_slot_id,
        // у них было только ward_slot_id. Принимаем оба поля.
        var _ward_match = (
            variable_instance_exists(_inst, "ward_slot_id")
            && _inst.ward_slot_id == _slot
        );

        if (_exam_match || _ward_match) {
            return _inst;
        }
    }

    // Для новых коек (101+) точное совпадение обязательно,
    // чтобы койка 102 случайно не взяла точку койки 101.
    if (_slot >= 101) return noone;

    // Для старой схемы (слот 100) возвращаем первый экземпляр.
    return _fallback;
}


// ── Один общий шкаф на весь стационар (пакет №73 hotfix) ──
// Кабинетные шкафы приёма имеют exam_slot_id 1/2/3.
// Шкаф стационара — один на палату, его exam_slot_id >= 100.

function inpatient_find_cabinet() {
    for (var _index = 0; _index < instance_number(obj_storage_cabinet); _index++) {
        var _cabinet = instance_find(obj_storage_cabinet, _index);

        if (
            instance_exists(_cabinet)
            && variable_instance_exists(_cabinet, "exam_slot_id")
            && _cabinet.exam_slot_id >= 100
        ) {
            return _cabinet;
        }
    }

    return noone;
}

function inpatient_get_ward_for_pet(_pet) {
    if (!instance_exists(_pet)) return noone;

    if (
        variable_instance_exists(_pet, "inpatient_controller")
        && instance_exists(_pet.inpatient_controller)
    ) {
        return _pet.inpatient_controller;
    }

    return noone;
}

function inpatient_find_ward_with_player(_player) {
    if (!instance_exists(_player)) return noone;

    for (var _index = 0; _index < instance_number(obj_inpatient_controller); _index++) {
        var _ward = instance_find(obj_inpatient_controller, _index);

        if (
            instance_exists(_ward)
            && _ward.player_actor == _player
        ) {
            return _ward;
        }
    }

    return noone;
}

function inpatient_find_free_ward() {
    for (var _index = 0; _index < instance_number(obj_inpatient_controller); _index++) {
        var _ward = instance_find(obj_inpatient_controller, _index);

        if (!instance_exists(_ward)) continue;

        // Пакет №173: некупленная койка не принимает пациентов.
        if (
            variable_instance_exists(_ward, "exam_slot_id")
            && !clinic_bed_is_open(_ward.exam_slot_id)
        ) {
            continue;
        }

        if (!inpatient_refresh_room_links(_ward)) continue;
        if (_ward.phase != "empty") continue;
        if (instance_exists(_ward.patient)) continue;

        // Восстанавливаем старую зависшую бронь пустой койки.
        if (
            _ward.ward_table.table_busy
            && !instance_exists(_ward.ward_table.assigned_pet)
        ) {
            _ward.ward_table.table_busy = false;
            _ward.ward_table.assigned_owner = noone;
            _ward.ward_table.assigned_doctor = noone;
            _ward.ward_table.assigned_pet = noone;
        }

        if (_ward.ward_table.table_busy) continue;

        return _ward;
    }

    return noone;
}

function inpatient_any_bed_needs_doctor() {
    for (var _index = 0; _index < instance_number(obj_inpatient_controller); _index++) {
        var _ward = instance_find(obj_inpatient_controller, _index);

        if (!instance_exists(_ward)) continue;

        if (
            _ward.phase == "waiting_doctor"
            || _ward.phase == "player_going_assign"
            || _ward.phase == "player_assigning"
        ) {
            return true;
        }
    }

    return false;
}

function inpatient_any_bed_needs_assistant() {
    for (var _index = 0; _index < instance_number(obj_inpatient_controller); _index++) {
        var _ward = instance_find(obj_inpatient_controller, _index);

        if (!instance_exists(_ward)) continue;

        if (
            _ward.phase == "player_going_treat"
            || _ward.phase == "player_treating"
            || _ward.phase == "waiting_stock"
        ) {
            return true;
        }

        // Пакет №77: в waiting_cycle ассистент нужен только тогда,
        // когда цикл лечения вот-вот начнётся. Пока до него далеко —
        // ассистент свободен и может гулять или пополнять шкафы.
        if (_ward.phase == "waiting_cycle") {
            if (_ward.next_treatment_minute
                <= inpatient_now_absolute_minute() + 30) {
                return true;
            }
        }
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 1.2 ПРИВЯЗКА КОЙКИ К СВОЕМУ СТОЛУ И ТОЧКАМ
// ═══════════════════════════════════════════════════════════════

function inpatient_refresh_room_links(_ward) {
    if (!instance_exists(_ward)) return false;

    // Номер койки = exam_slot_id самого контроллера (101–104).
    var _slot = variable_instance_exists(_ward, "exam_slot_id")
        ? _ward.exam_slot_id
        : 100;

    _ward.ward_table = inpatient_find_by_slot(obj_inpatient_table, _slot);
    _ward.doctor_point = inpatient_find_by_slot(obj_inpatient_point_doctor, _slot);
    _ward.assistant_point = inpatient_find_by_slot(obj_inpatient_point_assistant, _slot);
    _ward.pet_floor_point = inpatient_find_by_slot(obj_inpatient_point_pet_floor, _slot);
    _ward.pet_table_point = inpatient_find_by_slot(obj_inpatient_point_pet_table, _slot);
    _ward.owner_point = inpatient_find_by_slot(obj_inpatient_point_owner, _slot);

    // Общие для всей палаты: стул/диван отдыха врача.
    _ward.doctor_chair = instance_exists(obj_inpatient_doctor_chair)
        ? instance_find(obj_inpatient_doctor_chair, 0)
        : noone;
    _ward.doctor_rest_point = instance_exists(obj_inpatient_point_doctor_rest)
        ? instance_find(obj_inpatient_point_doctor_rest, 0)
        : _ward.doctor_chair;

    // Точка отдыха не должна блокировать саму госпитализацию.
    if (!instance_exists(_ward.doctor_rest_point)) {
        _ward.doctor_rest_point = instance_exists(_ward.doctor_chair)
            ? _ward.doctor_chair
            : _ward.doctor_point;
    }

    var _complete = (
        instance_exists(_ward.ward_table)
        && instance_exists(_ward.doctor_point)
        && instance_exists(_ward.assistant_point)
        && instance_exists(_ward.pet_floor_point)
        && instance_exists(_ward.pet_table_point)
        && instance_exists(_ward.owner_point)
    );

    // ── Диагностика (пакет №73 hotfix) ──
    // Раз в секунду печатает, чего не хватает у несобранной койки.
    if (!_complete) {
        if (_ward.link_retry_timer <= 0) {
            _ward.link_retry_timer = max(1, game_get_speed(gamespeed_fps));

            var _missing = "";

            if (!instance_exists(_ward.ward_table)) _missing += "стол, ";
            if (!instance_exists(_ward.doctor_point)) _missing += "точка врача, ";
            if (!instance_exists(_ward.assistant_point)) _missing += "точка ассистента, ";
            if (!instance_exists(_ward.pet_floor_point)) _missing += "точка pet_floor, ";
            if (!instance_exists(_ward.pet_table_point)) _missing += "точка pet_table, ";
            if (!instance_exists(_ward.owner_point)) _missing += "точка владельца, ";

            if (_missing != "") {
                _missing = string_copy(_missing, 1, string_length(_missing) - 2);
            } else {
                _missing = "что-то ещё";
            }

            show_debug_message(
                "[INPATIENT] Койка " + string(_slot)
                + " не собрана. Не хватает: " + _missing
                + ". Проверь exam_slot_id у ВСЕХ объектов этой койки."
            );
        }
    } else {
        _ward.link_retry_timer = 0;
    }

    return _complete;
}

function inpatient_can_admit(_pet = noone) {
    if (instance_exists(_pet)) {
        var _condition = variable_instance_exists(_pet, "condition")
            ? _pet.condition
            : 100;

        if (
            variable_instance_exists(_pet, "current_case")
            && is_struct(_pet.current_case)
            && variable_struct_exists(_pet.current_case, "condition")
        ) {
            _condition = _pet.current_case.condition;
        }

        // Пакет №112: пациент после операции (флаг or_post_surgery) принимается
        // в стационар даже при состоянии ≥ 50 — ему нужна койка восстановления.
        var _post_surgery = (
            variable_instance_exists(_pet, "or_post_surgery")
            && _pet.or_post_surgery
        );

        // Пакет №170: пациент, которому назначена операция, ложится в
        // стационар при ЛЮБОМ состоянии — койка работает как
        // предоперационная палата и ждёт освобождения операционной.
        var _waiting_surgery = (
            variable_instance_exists(_pet, "or_waiting_surgery")
            && _pet.or_waiting_surgery
        );

        if (!_post_surgery && !_waiting_surgery && _condition >= 50) return false;
    }

    return instance_exists(inpatient_find_free_ward());
}


// ═══════════════════════════════════════════════════════════════
// 2. БЕЗОПАСНОЕ ДВИЖЕНИЕ
// ═══════════════════════════════════════════════════════════════

function inpatient_stop_actor(_actor) {
    if (!instance_exists(_actor)) return false;

    with (_actor) {
        path_end();
        speed = 0;
        hspeed = 0;
        vspeed = 0;
        is_walking = false;
        move_towards_point(x, y, 0);
    }

    return true;
}

function inpatient_walk_to(_actor, _target_x, _target_y) {
    if (!instance_exists(_actor)) return false;
    if (!variable_instance_exists(_actor, "my_path")) return false;

    inpatient_stop_actor(_actor);

    // Запоминаем отдельно логический маркер и реальную достижимую точку.
    _actor.inpatient_requested_target_x = _target_x;
    _actor.inpatient_requested_target_y = _target_y;
    _actor.inpatient_actual_target_x = _target_x;
    _actor.inpatient_actual_target_y = _target_y;

    // Нельзя вызывать move_towards_point с положительной скоростью,
    // если сотрудник уже стоит в цели: GameMaker задаст направление 0
    // и персонаж начнёт бесконечно скользить вправо.
    if (point_distance(_actor.x, _actor.y, _target_x, _target_y) <= 10) {
        return true;
    }

    var _path_built = false;

    with (_actor) {
        _path_built = mp_grid_path(
            global.ai_grid,
            my_path,
            x,
            y,
            _target_x,
            _target_y,
            true
        );

        // Если центр маркера попал на закрытую клетку, ищем ближайшую
        // достижимую точку, не телепортируя сотрудника.
        if (!_path_built) {
            var _offsets = [-24, -16, 0, 16, 24];

            for (var _offset_x = 0; _offset_x < array_length(_offsets); _offset_x++) {
                for (var _offset_y = 0; _offset_y < array_length(_offsets); _offset_y++) {
                    var _candidate_x = _target_x + _offsets[_offset_x];
                    var _candidate_y = _target_y + _offsets[_offset_y];

                    if (mp_grid_path(
                        global.ai_grid,
                        my_path,
                        x,
                        y,
                        _candidate_x,
                        _candidate_y,
                        true
                    )) {
                        inpatient_actual_target_x = _candidate_x;
                        inpatient_actual_target_y = _candidate_y;
                        _path_built = true;
                        break;
                    }
                }

                if (_path_built) break;
            }
        }

        if (_path_built) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
            image_speed = 1;
        } else {
            move_towards_point(_target_x, _target_y, p_move_speed);
            is_walking = true;
            image_speed = 1;
        }
    }

    return _path_built;
}

function inpatient_actor_at_target(
    _actor,
    _logical_target_x,
    _logical_target_y,
    _tolerance = 12
) {
    if (!instance_exists(_actor)) return false;

    var _check_x = _logical_target_x;
    var _check_y = _logical_target_y;

    var _same_requested_target = (
        variable_instance_exists(_actor, "inpatient_requested_target_x")
        && variable_instance_exists(_actor, "inpatient_requested_target_y")
        && abs(_actor.inpatient_requested_target_x - _logical_target_x) <= 1
        && abs(_actor.inpatient_requested_target_y - _logical_target_y) <= 1
    );

    if (
        _same_requested_target
        && variable_instance_exists(_actor, "inpatient_actual_target_x")
        && variable_instance_exists(_actor, "inpatient_actual_target_y")
    ) {
        _check_x = _actor.inpatient_actual_target_x;
        _check_y = _actor.inpatient_actual_target_y;
    }

    return point_distance(
        _actor.x,
        _actor.y,
        _check_x,
        _check_y
    ) <= _tolerance;
}

function inpatient_ensure_walk(_actor, _target_x, _target_y) {
    if (!instance_exists(_actor)) return false;

    if (inpatient_actor_at_target(_actor, _target_x, _target_y, 10)) {
        return true;
    }

    if (_actor.path_index < 0 && !_actor.is_walking) {
        return inpatient_walk_to(_actor, _target_x, _target_y);
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. МЕСТО РАБОТЫ ПЕРСОНАЛА
// reception / inpatient / operating
// ═══════════════════════════════════════════════════════════════

function staff_workplace_init(_staff) {
    if (!instance_exists(_staff)) return false;

    if (!variable_instance_exists(_staff, "workplace_id")) {
        _staff.workplace_id = "reception";
    }

    if (!variable_instance_exists(_staff, "workplace_pending")) {
        _staff.workplace_pending = "";
    }

    return true;
}

function staff_workplace_get_label(_workplace_id) {
    switch (string(_workplace_id)) {
        case "inpatient": return "СТАЦИОНАР";
        case "operating": return "ОПЕРАЦИОННАЯ";
        case "op_surgeon": return "ОПЕРАЦИОННАЯ: ХИРУРГ";
        case "op_anesthetist": return "ОПЕРАЦИОННАЯ: АНЕСТЕЗИОЛОГ";
        case "op_assistant": return "ОПЕРАЦИОННАЯ";
    }

    return "НА ПРИЁМЕ";
}

// ═══════════════════════════════════════════════════════════════
// РОЛИ ОПЕРАЦИОННОЙ (пакет №110)
// Роль хранится как workplace_id = "operating" + operating_role.
// op_surgeon / op_anesthetist / op_assistant — id из выпадающего списка.
// ═══════════════════════════════════════════════════════════════

function staff_operating_role_of(_workplace_id) {
    switch (string(_workplace_id)) {
        case "op_surgeon": return "surgeon";
        case "op_anesthetist": return "anesthetist";
        case "op_assistant": return "assistant";
    }

    return "";
}

function staff_operating_role_skill_name(_role) {
    switch (string(_role)) {
        case "surgeon": return "Хирургия";
        case "anesthetist": return "Анестезиология";
        case "assistant": return "Процедуры";
    }

    return "";
}

// Допуск к роли: Хирургия(2) ≥ 3, Анестезиология(7) ≥ 3, Процедуры(1) ≥ 3.
function staff_operating_role_allowed(_staff, _role) {
    if (!instance_exists(_staff)) return false;

    var _idx = -1;

    switch (string(_role)) {
        case "surgeon": _idx = 2; break;
        case "anesthetist": _idx = 7; break;
        case "assistant": _idx = 1; break;
    }

    if (_idx < 0) return true; // не операционная роль — всегда можно

    var _skills = (
        variable_instance_exists(_staff, "skills")
        && is_array(_staff.skills)
    ) ? _staff.skills : [];

    var _lvl = (_idx < array_length(_skills))
        ? clamp(round(_skills[_idx]), 1, 10)
        : 1;

    return _lvl >= 3;
}

// Метка для кнопки «Место работы» с учётом роли.
function staff_workplace_label_for(_staff) {
    if (!instance_exists(_staff)) return "НА ПРИЁМЕ";

    var _wp = variable_instance_exists(_staff, "workplace_id")
        ? string(_staff.workplace_id)
        : "reception";

    if (_wp == "operating") {
        var _role = variable_instance_exists(_staff, "operating_role")
            ? string(_staff.operating_role)
            : "";

        switch (_role) {
            case "surgeon": return "ОПЕРАЦИОННАЯ: ХИРУРГ";
            case "anesthetist": return "ОПЕРАЦИОННАЯ: АНЕСТЕЗИОЛОГ";
            case "assistant": return "ОПЕРАЦИОННАЯ";
        }
    }

    return staff_workplace_get_label(_wp);
}

function staff_workplace_is_free(_staff) {
    if (!instance_exists(_staff)) return false;

    if (variable_instance_exists(_staff, "doctor_state")) {
        return (
            _staff.doctor_state == "idle"
            || _staff.doctor_state == "inpatient_available"
            || _staff.doctor_state == "inpatient_at_chair"
            || _staff.doctor_state == "operating_idle"
        );
    }

    if (variable_instance_exists(_staff, "assistant_state")) {
        return (
            _staff.assistant_state == "idle"
            || _staff.assistant_state == "inpatient_available"
            || _staff.assistant_state == "inpatient_waiting_stock"
            || _staff.assistant_state == "operating_idle"
        );
    }

    return false;
}

function staff_workplace_apply(_staff, _workplace_id) {
    if (!instance_exists(_staff)) return false;

    staff_workplace_init(_staff);

    // Пакет №110: операционные роли хранятся как workplace_id = "operating"
    // + operating_role, чтобы старая логика (операционная = один блок) работала.
    var _op_role = staff_operating_role_of(_workplace_id);
    var _final_wp = (_op_role != "") ? "operating" : string(_workplace_id);

    _staff.workplace_id = _final_wp;
    _staff.operating_role = _op_role;
    _staff.workplace_pending = "";

    with (_staff) {
        path_end();
        speed = 0;
        is_walking = false;
        action_progress_active = false;
        action_progress_timer = 0;
        action_progress_timer_max = 0;
    }

    if (variable_instance_exists(_staff, "doctor_state")) {
        switch (_final_wp) {
            case "inpatient": {
                var _doctor_ward = inpatient_get_controller();

                if (
                    instance_exists(_doctor_ward)
                    && inpatient_refresh_room_links(_doctor_ward)
                ) {
                    _staff.doctor_state = "inpatient_moving_to_chair";
                    inpatient_walk_to(
                        _staff,
                        _doctor_ward.doctor_rest_point.x,
                        _doctor_ward.doctor_rest_point.y
                    );
                } else {
                    _staff.doctor_state = "inpatient_available";
                }
            }
            break;

            case "operating":
                _staff.doctor_state = "operating_idle";
                inpatient_walk_to(_staff, _staff.home_x, _staff.home_y);
            break;

            default:
                _staff.doctor_state = "idle";
        }
    }

    if (variable_instance_exists(_staff, "assistant_state")) {
        switch (_final_wp) {
            case "inpatient": {
                // Пока врач не создал назначения, ассистент не занимает
                // рабочую точку у животного: возвращается домой и пополняет шкафы.
                _staff.assistant_state = "inpatient_moving_to_home";
                inpatient_walk_to(
                    _staff,
                    _staff.home_x,
                    _staff.home_y
                );
            }
            break;

            case "operating":
                _staff.assistant_state = "operating_idle";
                inpatient_walk_to(_staff, _staff.home_x, _staff.home_y);
            break;

            default:
                _staff.assistant_state = "idle";
        }
    }

    return true;
}

function staff_workplace_request(_staff, _workplace_id) {
    if (!instance_exists(_staff)) return false;

    staff_workplace_init(_staff);

    var _wid = string(_workplace_id);
    var _op_role = staff_operating_role_of(_wid);
    var _is_op = (_op_role != "");

    if (
        _wid != "reception"
        && _wid != "inpatient"
        && _wid != "operating"
        && !_is_op
    ) {
        return false;
    }

    // Допуск к роли в операционной (пакет №110).
    if (_is_op && !staff_operating_role_allowed(_staff, _op_role)) {
        if (instance_exists(obj_UI_HUD)) {
            var _hud_deny = instance_find(obj_UI_HUD, 0);

            if (
                instance_exists(_hud_deny)
                && variable_instance_exists(_hud_deny, "show_notice")
            ) {
                with (_hud_deny) {
                    show_notice(
                        "НУЖЕН НАВЫК 3+",
                        staff_operating_role_skill_name(_op_role)
                            + " не ниже 3 уровня.",
                        room_speed * 3
                    );
                }
            }
        }

        return false;
    }

    var _same_role = (
        !_is_op
        || (
            variable_instance_exists(_staff, "operating_role")
            && _staff.operating_role == _op_role
        )
    );

    if (_staff.workplace_id == (_is_op ? "operating" : _wid) && _same_role) {
        _staff.workplace_pending = "";
        return true;
    }

    if (staff_workplace_is_free(_staff)) {
        return staff_workplace_apply(_staff, _wid);
    }

    // Сотрудник закончит текущую задачу и только потом сменит место работы.
    _staff.workplace_pending = _workplace_id;

    if (instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);
        var _staff_name = variable_instance_exists(_staff, "char_name")
            ? _staff.char_name
            : "Сотрудник";
        var _workplace_name = staff_workplace_get_label(_workplace_id);

        if (
            instance_exists(_hud)
            && variable_instance_exists(_hud, "show_notice")
        ) {
            with (_hud) {
                show_notice(
                    "МЕСТО РАБОТЫ",
                    _staff_name + " перейдёт: " + _workplace_name,
                    room_speed * 3
                );
            }
        }
    }

    return true;
}

function inpatient_staff_begin_step(_staff) {
    if (!instance_exists(_staff)) return false;

    staff_workplace_init(_staff);

    if (
        _staff.workplace_pending != ""
        && staff_workplace_is_free(_staff)
    ) {
        staff_workplace_apply(_staff, _staff.workplace_pending);
    }

    // Самовосстановление старого состояния: сотрудник с местом работы
    // «На приёме» не должен оставаться в служебном состоянии стационара.
    if (_staff.workplace_id == "reception") {
        if (variable_instance_exists(_staff, "doctor_state")) {
            var _doctor_old_inpatient_state = (
                string_pos("inpatient_", _staff.doctor_state) == 1
            );
            var _doctor_is_escort = (
                _staff.doctor_state == "inpatient_escort"
                || _staff.doctor_state == "inpatient_escort_return"
            );

            if (_doctor_old_inpatient_state && !_doctor_is_escort) {
                inpatient_stop_actor(_staff);
                _staff.doctor_state = "idle";
            }
        }

        if (variable_instance_exists(_staff, "assistant_state")) {
            if (string_pos("inpatient_", _staff.assistant_state) == 1) {
                inpatient_stop_actor(_staff);
                _staff.assistant_state = "idle";
            }
        }
    }

    if (variable_instance_exists(_staff, "doctor_state")) {
        if (
            _staff.workplace_id == "inpatient"
            && _staff.doctor_state == "idle"
        ) {
            _staff.doctor_state = "inpatient_available";
        }
        else if (
            _staff.workplace_id == "operating"
            && _staff.doctor_state == "idle"
        ) {
            _staff.doctor_state = "operating_idle";
        }
    }

    if (variable_instance_exists(_staff, "assistant_state")) {
        var _assistant_busy_with_stock = (
            string_pos("restock_", _staff.assistant_state) == 1
            || _staff.assistant_state == "putting_in"
            || _staff.assistant_state == "restocking"
        );

        if (!_assistant_busy_with_stock) {
            if (
                _staff.workplace_id == "inpatient"
                && _staff.assistant_state == "idle"
            ) {
                _staff.assistant_state = "inpatient_available";
            }
            else if (
                _staff.workplace_id == "operating"
                && _staff.assistant_state == "idle"
            ) {
                _staff.assistant_state = "operating_idle";
            }
        }
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3.1 АНИМАЦИЯ И ФИНАЛЬНАЯ ОСТАНОВКА ПЕРСОНАЛА СТАЦИОНАРА
// ═══════════════════════════════════════════════════════════════

function inpatient_update_staff_animation(_staff) {
    if (!instance_exists(_staff)) return false;

    var _state = "";

    if (variable_instance_exists(_staff, "doctor_state")) {
        _state = string(_staff.doctor_state);
    }
    else if (variable_instance_exists(_staff, "assistant_state")) {
        _state = string(_staff.assistant_state);
    }

    var _is_inpatient_state = (string_pos("inpatient_", _state) == 1);
    var _is_operating_state = (_state == "operating_idle");

    if (!_is_inpatient_state && !_is_operating_state) {
        if (variable_instance_exists(_staff, "_owner_sitting")) {
            _staff._owner_sitting = false;
        }
        return false;
    }

    var _stationary_state = (
        _state == "inpatient_available"
        || _state == "inpatient_at_chair"
        || _state == "inpatient_waiting_stock"
        || _state == "inpatient_prescribing"
        || _state == "inpatient_treating"
        || _state == "operating_idle"
    );

    if (_stationary_state) {
        inpatient_stop_actor(_staff);

        // Полностью та же схема, что у владельца в par_visitors End Step:
        // флаг _owner_sitting, spr_human_FR_sit и таймер 12 кадров.
        var _rest_point = noone;

        if (instance_exists(obj_inpatient_point_doctor_rest)) {
            _rest_point = instance_find(obj_inpatient_point_doctor_rest, 0);
        } else {
            var _sit_ward = inpatient_get_controller();

            if (instance_exists(_sit_ward)) {
                inpatient_refresh_room_links(_sit_ward);
                _rest_point = _sit_ward.doctor_rest_point;
            }
        }

        if (
            _state == "inpatient_at_chair"
            && variable_instance_exists(_staff, "doctor_state")
            && instance_exists(_rest_point)
        ) {

            if (!variable_instance_exists(_staff, "_owner_sitting")) {
                _staff._owner_sitting = false;
            }
            if (!variable_instance_exists(_staff, "_sit_anim_timer")) {
                _staff._sit_anim_timer = 0;
            }
            if (!variable_instance_exists(_staff, "_idle_anim_timer")) {
                _staff._idle_anim_timer = 0;
            }

            _staff._owner_sitting = true;
            _staff.pFacing = 1;
            _staff.x = _rest_point.x;
            _staff.y = _rest_point.y;
            _staff._sit_anim_timer += 1;
            _staff._idle_anim_timer = 0;

            if (sprite_exists(spr_human_FR_sit)) {
                var _sit_frames = max(
                    1,
                    sprite_get_number(spr_human_FR_sit)
                );

                _staff.sprite_index = spr_human_FR_sit;
                _staff.image_index = floor(
                    _staff._sit_anim_timer / 12
                ) mod _sit_frames;
                _staff.image_speed = 0;
            }

            _staff.image_xscale = abs(_staff.image_xscale) * _staff.pFacing;
            _staff.depth = -_staff.y - 500;
        }
        else {
            if (variable_instance_exists(_staff, "_owner_sitting")) {
                _staff._owner_sitting = false;
            }
            if (variable_instance_exists(_staff, "_sit_anim_timer")) {
                _staff._sit_anim_timer = 0;
            }
        }
    }
    else {
        if (variable_instance_exists(_staff, "_owner_sitting")) {
            _staff._owner_sitting = false;
        }

        _staff.is_walking = true;

        if (_staff.image_speed <= 0) {
            _staff.image_speed = 1;
        }
    }

    return true;
}

// ═══════════════════════════════════════════════════════════════
// 4. ДАННЫЕ ВЛАДЕЛЬЦА И ОЧИСТКА ОЧЕРЕДЕЙ
// ═══════════════════════════════════════════════════════════════

function inpatient_capture_owner_snapshot(_owner) {
    if (!instance_exists(_owner)) return {};

    return {
        owner_record_id : variable_instance_exists(_owner, "owner_record_id") ? _owner.owner_record_id : "",
        pet_record_id : variable_instance_exists(_owner, "pet_record_id") ? _owner.pet_record_id : "",
        pending_payment_total : variable_instance_exists(_owner, "pending_payment_total") ? _owner.pending_payment_total : 0,
        visit_price : variable_instance_exists(_owner, "visit_price") ? _owner.visit_price : 0,
        visit_type_id : variable_instance_exists(_owner, "visit_type_id") ? _owner.visit_type_id : "doctor_visit",
        visit_type_name_ru : variable_instance_exists(_owner, "visit_type_name_ru") ? _owner.visit_type_name_ru : "Приём врача",
        visit_reason_ru : variable_instance_exists(_owner, "visit_reason_ru") ? _owner.visit_reason_ru : "Стационар",
        visit_outcome_id : variable_instance_exists(_owner, "visit_outcome_id") ? _owner.visit_outcome_id : "",
        visit_outcome_name_ru : variable_instance_exists(_owner, "visit_outcome_name_ru") ? _owner.visit_outcome_name_ru : "",
        visit_reputation_awarded : variable_instance_exists(_owner, "visit_reputation_awarded") ? _owner.visit_reputation_awarded : false,
        scheduled_visit_id : variable_instance_exists(_owner, "scheduled_visit_id") ? _owner.scheduled_visit_id : "",

        char_name : variable_instance_exists(_owner, "char_name") ? _owner.char_name : "Владелец",
        age : variable_instance_exists(_owner, "age") ? _owner.age : 30,
        is_female : variable_instance_exists(_owner, "is_female") ? _owner.is_female : false,
        character_trait : variable_instance_exists(_owner, "character_trait") ? _owner.character_trait : 0,
        owner_trust : variable_instance_exists(_owner, "owner_trust") ? _owner.owner_trust : 60,
        loyalty_level : variable_instance_exists(_owner, "loyalty_level") ? _owner.loyalty_level : 5,
        loyalty_success_progress : variable_instance_exists(_owner, "loyalty_success_progress") ? _owner.loyalty_success_progress : 0,
        patience_level : variable_instance_exists(_owner, "patience_level") ? _owner.patience_level : 1,
        owner_feature_id : variable_instance_exists(_owner, "owner_feature_id") ? _owner.owner_feature_id : "none",
        owner_feature_name_ru : variable_instance_exists(_owner, "owner_feature_name_ru") ? _owner.owner_feature_name_ru : "Нет особенности",

        hair_color : variable_instance_exists(_owner, "hair_color") ? _owner.hair_color : c_white,
        my_hair : variable_instance_exists(_owner, "my_hair") ? _owner.my_hair : -1,
        my_hair_back : variable_instance_exists(_owner, "my_hair_back") ? _owner.my_hair_back : -1,
        my_eyes : variable_instance_exists(_owner, "my_eyes") ? _owner.my_eyes : -1,
        my_nose : variable_instance_exists(_owner, "my_nose") ? _owner.my_nose : -1,
        my_mouth : variable_instance_exists(_owner, "my_mouth") ? _owner.my_mouth : -1,
        portrait_x : variable_instance_exists(_owner, "portrait_x") ? _owner.portrait_x : 150,
        portrait_y : variable_instance_exists(_owner, "portrait_y") ? _owner.portrait_y : 50,
        portrait_zoom : variable_instance_exists(_owner, "portrait_zoom") ? _owner.portrait_zoom : 1
    };
}

function inpatient_remove_owner_from_clinic_queues(_owner) {
    if (!instance_exists(_owner)) return;

    if (
        variable_instance_exists(_owner, "wait_spot_index")
        && _owner.wait_spot_index >= 0
        && variable_global_exists("wait_spots")
        && _owner.wait_spot_index < array_length(global.wait_spots)
    ) {
        if (global.wait_spots[_owner.wait_spot_index].occupied_by == _owner) {
            global.wait_spots[_owner.wait_spot_index].occupied_by = noone;
        }
        _owner.wait_spot_index = -1;
    }

    if (
        variable_instance_exists(_owner, "assigned_desk")
        && instance_exists(_owner.assigned_desk)
        && variable_instance_exists(_owner.assigned_desk, "queue_list")
        && ds_exists(_owner.assigned_desk.queue_list, ds_type_list)
    ) {
        var _queue_index = ds_list_find_index(
            _owner.assigned_desk.queue_list,
            _owner
        );

        if (_queue_index >= 0) {
            ds_list_delete(_owner.assigned_desk.queue_list, _queue_index);
            _owner.assigned_desk.alarm[0] = 1;
        }
    }

    _owner.queue_slot = -1;
    _owner.registration_in_progress = false;
    _owner.registration_timer = 0;
    _owner.registration_timer_max = 0;
    _owner.registration_actor_name = "";
}


// ═══════════════════════════════════════════════════════════════
// 5. ПЕРЕВОД ПАЦИЕНТА В СТАЦИОНАР
// ═══════════════════════════════════════════════════════════════

function inpatient_clear_outpatient_prescriptions(_pet) {
    if (!instance_exists(_pet)) return false;
    if (!variable_instance_exists(_pet, "current_case")) return false;
    if (!is_struct(_pet.current_case)) return false;

    var _case = _pet.current_case;

    // Обычный NPC-врач успевает автоматически выбрать лечение до End Step.
    // Для тяжёлого пациента свободного стационара эти назначения отменяются:
    // врач приёма оставляет только обследования и подтверждённый диагноз.
    _case.prescribed_treatment_ids = [];
    _case.pending_procedure_actions = [];
    _case.visit_prescribed_actions = [];
    _case.visit_treatments_done = [];
    _case.visit_treatment_feedback_ok_ids = [];
    _case.visit_treatment_feedback_bad_ids = [];
    _case.stock_blocked = false;
    _case.stock_missing_item_id = "";
    _case.stock_missing_item_name = "";
    _case.stock_blocked_action_id = "";
    _case.case_status = "awaiting_inpatient_prescription";

    _pet.current_case = _case;
    animal_apply_case(_pet, _case);
    return true;
}

function inpatient_start_admission(_owner, _pet, _escort_doctor) {
    if (!instance_exists(_owner)) return false;
    if (!instance_exists(_pet)) return false;
    if (!inpatient_can_admit(_pet)) return false;

    var _ward = inpatient_find_free_ward();
    if (!instance_exists(_ward)) return false;
    if (!inpatient_refresh_room_links(_ward)) return false;

    inpatient_clear_outpatient_prescriptions(_pet);

    _ward.patient = _pet;
    _ward.departing_owner = _owner;
    _ward.returning_owner = noone;
    _ward.escort_doctor = instance_exists(_escort_doctor)
        ? _escort_doctor
        : noone;
    _ward.escort_return_x = instance_exists(_escort_doctor)
        ? (variable_instance_exists(_escort_doctor, "home_x")
            ? _escort_doctor.home_x
            : _escort_doctor.x)
        : 0;
    _ward.escort_return_y = instance_exists(_escort_doctor)
        ? (variable_instance_exists(_escort_doctor, "home_y")
            ? _escort_doctor.home_y
            : _escort_doctor.y)
        : 0;
    _ward.owner_snapshot = inpatient_capture_owner_snapshot(_owner);
    _ward.phase = "admitting";
    _ward.prescriptions_assigned = false;
    _ward.treatment_actions = [];
    _ward.admission_timer = 0;
    _ward.cycle_action_index = 0;
    _ward.cycle_active = false;
    _ward.next_treatment_minute = -1;
    _ward.stock_retry_timer = 0;

    inpatient_remove_owner_from_clinic_queues(_owner);

    // Освобождаем обычный смотровой стол.
    if (
        variable_instance_exists(_pet, "assigned_table")
        && instance_exists(_pet.assigned_table)
        && _pet.assigned_table != _ward.ward_table
    ) {
        var _old_table = _pet.assigned_table;
        _old_table.table_busy = false;
        _old_table.assigned_owner = noone;
        _old_table.assigned_doctor = noone;
        _old_table.assigned_pet = noone;
    }

    with (_ward.ward_table) {
        table_busy = true;
        assigned_owner = noone;
        assigned_doctor = noone;
        assigned_pet = _pet;
    }

    // Животное использует общие состояния родителя par_animals.
    // Благодаря этому ни один вид животного не требует отдельной логики стационара.
    with (_pet) {
        inpatient_active = true;
        inpatient_controller = _ward;
        inpatient_owner_record_id = _ward.owner_snapshot.owner_record_id;
        inpatient_pet_record_id = _ward.owner_snapshot.pet_record_id;

        assigned_table = _ward.ward_table;
        assigned_doctor = _ward.escort_doctor;
        exam_floor_x = _ward.pet_floor_point.x;
        exam_floor_y = _ward.pet_floor_point.y;
        exam_table_x = _ward.pet_table_point.x;
        exam_table_y = _ward.pet_table_point.y;
        state = "going_to_exam_floor";

        path_end();
        speed = 0;
        is_walking = false;

        if (mp_grid_path(
            global.ai_grid,
            my_path,
            x,
            y,
            exam_floor_x,
            exam_floor_y,
            true
        )) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
        } else {
            move_towards_point(exam_floor_x, exam_floor_y, p_move_speed);
            is_walking = true;
        }
    }

    // Сразу отвязываем животное, поэтому Cleanup владельца не удалит
    // пациента, оставшегося на стационарном столе.
    _owner.my_pet = noone;
    _pet.my_owner = noone;

    // Владелец визуально уходит домой через уже существующее состояние.
    with (_owner) {
        assigned_doctor = noone;
        assigned_table = noone;
        service_queue_type = "inpatient";
        state = "leaving_clinic";
        leave_target_x = global.clinic_exit_x;
        leave_target_y = global.clinic_exit_y;

        path_end();
        speed = 0;
        is_walking = false;

        if (mp_grid_path(
            global.ai_grid,
            my_path,
            x,
            y,
            leave_target_x,
            leave_target_y,
            true
        )) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
        } else {
            move_towards_point(leave_target_x, leave_target_y, p_move_speed);
            is_walking = true;
        }
    }

    if (instance_exists(_escort_doctor)) {
        staff_workplace_init(_escort_doctor);
        _escort_doctor.assigned_owner = noone;
        _escort_doctor.assigned_table = noone;
        _escort_doctor.assigned_pet = _pet;
        _escort_doctor.doctor_state = "inpatient_escort";
        inpatient_walk_to(
            _escort_doctor,
            _ward.doctor_point.x,
            _ward.doctor_point.y
        );
    }

    if (instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);

        if (
            instance_exists(_hud)
            && variable_instance_exists(_hud, "show_notice")
        ) {
            with (_hud) {
                show_notice(
                    "СТАЦИОНАР",
                    "Тяжёлый пациент направлен в стационар",
                    room_speed * 4
                );
            }
        }
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 6. АВТОМАТИЧЕСКИЙ ПЕРЕВОД ПОСЛЕ ПРИЁМА NPC-ВРАЧА
// ═══════════════════════════════════════════════════════════════

function inpatient_doctor_begin_snapshot(_doctor) {
    if (!instance_exists(_doctor)) return;

    inpatient_staff_begin_step(_doctor);

    if (!variable_instance_exists(_doctor, "inpatient_previous_doctor_state")) {
        _doctor.inpatient_previous_doctor_state = _doctor.doctor_state;
        _doctor.inpatient_exam_owner = noone;
        _doctor.inpatient_exam_pet = noone;
    }

    _doctor.inpatient_previous_doctor_state = _doctor.doctor_state;

    if (_doctor.doctor_state == "examining") {
        _doctor.inpatient_exam_owner = _doctor.assigned_owner;
        _doctor.inpatient_exam_pet = _doctor.assigned_pet;
    }
}

function inpatient_doctor_after_step(_doctor) {
    if (!instance_exists(_doctor)) return false;

    var _completed_exam = (
        variable_instance_exists(_doctor, "inpatient_previous_doctor_state")
        && _doctor.inpatient_previous_doctor_state == "examining"
        && _doctor.doctor_state == "idle"
    );

    if (_completed_exam) {
        var _owner = _doctor.inpatient_exam_owner;
        var _pet = _doctor.inpatient_exam_pet;

        _doctor.inpatient_exam_owner = noone;
        _doctor.inpatient_exam_pet = noone;

        if (
            instance_exists(_owner)
            && instance_exists(_pet)
            && inpatient_can_admit(_pet)
        ) {
            return inpatient_start_admission(_owner, _pet, _doctor);
        }
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 7. НАЗНАЧЕНИЯ ВРАЧА СТАЦИОНАРА
// ═══════════════════════════════════════════════════════════════

function inpatient_assign_treatments(_ward, _doctor) {
    if (!instance_exists(_ward)) return false;
    if (!instance_exists(_ward.patient)) return false;
    if (!instance_exists(_doctor)) return false;

    var _pet = _ward.patient;
    if (!variable_instance_exists(_pet, "current_case")) return false;
    if (!is_struct(_pet.current_case)) return false;

    // Страховка для пациентов, поступивших до установки этого исправления.
    inpatient_clear_outpatient_prescriptions(_pet);

    // Все решения врача в стационаре используют только новый навык.
    var _inpatient_level = doctor_get_inpatient_level(_doctor);
    var _choices = case_get_visible_treatment(
        _pet.current_case,
        _inpatient_level
    );

    for (var _choice_index = 0; _choice_index < array_length(_choices); _choice_index++) {
        var _choice = _choices[_choice_index];

        if (_choice.is_correct) {
            case_assign_treatment_action(_pet, _choice.action_id);
        }
    }

    doctor_visit_mark_inpatient_prescriber(_pet, _doctor);

    var _actions = case_build_next_procedure_assignments(_pet.current_case);

    if (array_length(_actions) <= 0) {
        if (
            variable_struct_exists(_pet.current_case, "pending_procedure_actions")
            && is_array(_pet.current_case.pending_procedure_actions)
        ) {
            _actions = _pet.current_case.pending_procedure_actions;
        }
    }

    // Пакет №170: хирургические действия из цикла палаты убираем —
    // их выполнит операционная, а не медсестра у койки.
    var _ward_actions = [];

    for (var _filter_index = 0; _filter_index < array_length(_actions); _filter_index++) {
        var _filter_entry = _actions[_filter_index];

        var _filter_id = is_struct(_filter_entry)
            ? (variable_struct_exists(_filter_entry, "action_id")
                ? _filter_entry.action_id
                : "")
            : _filter_entry;

        if (operating_action_is_surgery(_filter_id)) continue;

        array_push(_ward_actions, _filter_entry);
    }

    _pet.current_case.pending_procedure_actions = _actions;
    _ward.treatment_actions = _ward_actions;
    _ward.prescriptions_assigned = true;
    _ward.next_treatment_minute = inpatient_now_absolute_minute();
    _ward.phase = "waiting_cycle";

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 8. ПОВТОРНОЕ ВЫПОЛНЕНИЕ ОДНОГО НАЗНАЧЕНИЯ
// Не использует дневной лимит; препараты списываются каждый раз.
// Пакет №73 hotfix: препараты берутся из ОДНОГО общего шкафа палаты.
// ═══════════════════════════════════════════════════════════════

function inpatient_consume_action(_action_id) {
    var _required_items = treatment_get_required_items(_action_id);

    if (array_length(_required_items) <= 0) {
        return { ok : true, missing_item_id : "", missing_item_name : "" };
    }

    var _cabinet = inpatient_find_cabinet();

    if (!instance_exists(_cabinet)) {
        return {
            ok : false,
            missing_item_id : "",
            missing_item_name : "шкаф стационара"
        };
    }

    if (
        !variable_instance_exists(_cabinet, "storage_inventory")
        || !is_struct(_cabinet.storage_inventory)
    ) {
        _cabinet.storage_inventory = {};

        for (
            var _init_index = 0;
            _init_index < array_length(global.item_ids);
            _init_index++
        ) {
            inventory_add_amount(
                _cabinet.storage_inventory,
                global.item_ids[_init_index],
                3
            );
        }
    }

    var _cabinet_inventory = _cabinet.storage_inventory;

    // Сначала проверяем весь список, затем списываем.
    for (
        var _check_index = 0;
        _check_index < array_length(_required_items);
        _check_index++
    ) {
        var _requirement = _required_items[_check_index];

        if (!inventory_has_amount(
            _cabinet_inventory,
            _requirement.item_id,
            _requirement.amount
        )) {
            restock_request_urgent(
                _cabinet,
                _requirement.item_id,
                _requirement.amount
            );

            return {
                ok : false,
                missing_item_id : _requirement.item_id,
                missing_item_name : item_get_name(_requirement.item_id)
            };
        }
    }

    for (
        var _remove_index = 0;
        _remove_index < array_length(_required_items);
        _remove_index++
    ) {
        var _remove_requirement = _required_items[_remove_index];

        inventory_remove_amount(
            _cabinet_inventory,
            _remove_requirement.item_id,
            _remove_requirement.amount
        );
    }

    return { ok : true, missing_item_id : "", missing_item_name : "" };
}

function inpatient_get_action_stock_status(_ward, _action_id) {
    if (!instance_exists(_ward)) {
        return { ok : false, missing_item_id : "", missing_item_name : "шкаф не найден" };
    }

    var _required_items = treatment_get_required_items(_action_id);

    if (array_length(_required_items) <= 0) {
        return { ok : true, missing_item_id : "", missing_item_name : "" };
    }

    var _cabinet = inpatient_find_cabinet();

    if (!instance_exists(_cabinet)) {
        return {
            ok : false,
            missing_item_id : "",
            missing_item_name : "шкаф стационара"
        };
    }

    if (
        !variable_instance_exists(_cabinet, "storage_inventory")
        || !is_struct(_cabinet.storage_inventory)
    ) {
        return {
            ok : false,
            missing_item_id : "",
            missing_item_name : "шкаф стационара"
        };
    }

    for (var _index = 0; _index < array_length(_required_items); _index++) {
        var _requirement = _required_items[_index];

        if (!inventory_has_amount(
            _cabinet.storage_inventory,
            _requirement.item_id,
            _requirement.amount
        )) {
            return {
                ok : false,
                missing_item_id : _requirement.item_id,
                missing_item_name : item_get_name(_requirement.item_id)
            };
        }
    }

    return { ok : true, missing_item_id : "", missing_item_name : "" };
}

// Пакет №170: пациент ждёт операцию — выписывать его нельзя.
function inpatient_patient_waits_surgery(_ward) {
    if (!instance_exists(_ward)) return false;
    if (!instance_exists(_ward.patient)) return false;

    return (
        variable_instance_exists(_ward.patient, "or_waiting_surgery")
        && _ward.patient.or_waiting_surgery
    );
}

function inpatient_apply_treatment_action(_ward, _action_id) {
    // Пакет №170: хирургию выполняет только операционная.
    // Иначе стационар «вылечил» бы перелом уколом прямо на койке.
    if (operating_action_is_surgery(_action_id)) return false;

    if (!instance_exists(_ward)) return { ok : false, missing_item_id : "", missing_item_name : "" };
    if (!instance_exists(_ward.patient)) return { ok : false, missing_item_id : "", missing_item_name : "" };

    var _pet = _ward.patient;
    if (!variable_instance_exists(_pet, "current_case")) return { ok : false, missing_item_id : "", missing_item_name : "" };
    if (!is_struct(_pet.current_case)) return { ok : false, missing_item_id : "", missing_item_name : "" };

    var _stock_result = inpatient_consume_action(_action_id);
    var _case = _pet.current_case;

    if (!_stock_result.ok) {
        _case.stock_blocked = true;
        _case.stock_missing_item_id = variable_struct_exists(_stock_result, "missing_item_id")
            ? _stock_result.missing_item_id
            : "";
        _case.stock_missing_item_name = variable_struct_exists(_stock_result, "missing_item_name")
            ? _stock_result.missing_item_name
            : "";
        _case.stock_blocked_action_id = _action_id;
        _pet.current_case = _case;
        animal_apply_case(_pet, _case);

        return {
            ok : false,
            missing_item_id : variable_struct_exists(_stock_result, "missing_item_id")
                ? _stock_result.missing_item_id
                : "",
            missing_item_name : variable_struct_exists(_stock_result, "missing_item_name")
                ? _stock_result.missing_item_name
                : ""
        };
    }

    _case.stock_blocked = false;
    _case.stock_missing_item_id = "";
    _case.stock_missing_item_name = "";
    _case.stock_blocked_action_id = "";

    if (!variable_struct_exists(_case, "treatment_progress")) _case.treatment_progress = [];
    if (!variable_struct_exists(_case, "visit_treatments_done")) _case.visit_treatments_done = [];
    if (!variable_struct_exists(_case, "visit_procedure_log")) _case.visit_procedure_log = [];
    if (!variable_struct_exists(_case, "inpatient_treatment_log")) _case.inpatient_treatment_log = [];
    if (!variable_struct_exists(_case, "visit_treatment_feedback_ok_ids")) _case.visit_treatment_feedback_ok_ids = [];
    if (!variable_struct_exists(_case, "visit_treatment_feedback_bad_ids")) _case.visit_treatment_feedback_bad_ids = [];

    array_push(_case.treatment_progress, _action_id);
    array_push(_case.visit_treatments_done, _action_id);

    var _feedback_already_added = false;

    for (
        var _feedback_index = 0;
        _feedback_index < array_length(_case.visit_treatment_feedback_ok_ids);
        _feedback_index++
    ) {
        if (_case.visit_treatment_feedback_ok_ids[_feedback_index] == _action_id) {
            _feedback_already_added = true;
            break;
        }
    }

    if (!_feedback_already_added) {
        array_push(_case.visit_treatment_feedback_ok_ids, _action_id);
    }
    array_push(_case.inpatient_treatment_log, {
        action_id : _action_id,
        absolute_minute : inpatient_now_absolute_minute()
    });
    array_push(_case.visit_procedure_log, {
        proc_type : "inpatient_treatment",
        proc_id : _action_id,
        proc_name_ru : db_get_treatment_action_name(_action_id)
    });

    // Пакет №81: прирост состояния читается НАПРЯМУЮ из med_db, как в
    // case_apply_treatment_action (пакет №68). Раньше использовался
    // treatment_get_condition_delta, который для новых действий мог
    // вернуть 0 — состояние пациента не менялось после лечения.
    var _condition_delta = 0;

    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "treatment_actions")
        && variable_struct_exists(global.med_db.treatment_actions, _action_id)
    ) {
        var _action_ref = variable_struct_get(
            global.med_db.treatment_actions,
            _action_id
        );

        if (variable_struct_exists(_action_ref, "condition_delta")) {
            _condition_delta = max(0, _action_ref.condition_delta);
        }
    }

    // Страховка для старых действий без поля condition_delta.
    if (_condition_delta <= 0) {
        switch (_action_id) {
            case "treat_iv_drip": _condition_delta = 5; break;
            case "treat_antiprotozoal": _condition_delta = 5; break;
            case "treat_painkiller": _condition_delta = 5; break;
            case "treat_limb_fixation": _condition_delta = 8; break;
        }
    }

    var _condition_before = _case.condition;
    _case.condition = clamp(
        _condition_before + _condition_delta,
        0,
        100
    );
    _case.case_status = (_case.condition >= 100)
        ? "recovered"
        : "inpatient";

    _pet.current_case = _case;
    _pet.condition = _case.condition;
    animal_apply_case(_pet, _case);

    show_debug_message(
        "[INPATIENT] Лечение " + string(_action_id)
        + " delta=" + string(_condition_delta)
        + " состояние " + string(_condition_before)
        + " -> " + string(_case.condition)
    );

    // Единственная крупная награда врачу выдаётся при полном выздоровлении.
    if (_condition_before < 100 && _case.condition >= 100) {
        doctor_visit_award_inpatient_cure(_pet);
    }

    return {
        ok : true,
        missing_item_id : "",
        missing_item_name : "",
        condition_delta : _condition_delta
    };
}


// ═══════════════════════════════════════════════════════════════
// 9. ВОЗВРАТ ВЛАДЕЛЬЦА И ОПЛАТА
// ═══════════════════════════════════════════════════════════════

function inpatient_spawn_returning_owner(_ward) {
    if (!instance_exists(_ward)) return noone;
    if (!instance_exists(_ward.patient)) return noone;
    if (instance_exists(_ward.returning_owner)) return _ward.returning_owner;

    var _owner = instance_create_layer(
        global.clinic_exit_x,
        global.clinic_exit_y,
        "Instances",
        obj_owner
    );

    if (!instance_exists(_owner)) return noone;

    // Create владельца автоматически создаёт нового питомца. Он не нужен:
    // в стационаре остаётся исходный пациент с накопленным лечением.
    if (instance_exists(_owner.my_pet)) {
        var _temporary_pet = _owner.my_pet;
        _owner.my_pet = noone;
        _temporary_pet.my_owner = noone;

        with (_temporary_pet) {
            instance_destroy();
        }
    }

    var _snapshot = _ward.owner_snapshot;
    var _owner_record_id = variable_struct_exists(_snapshot, "owner_record_id")
        ? _snapshot.owner_record_id
        : "";

    if (
        _owner_record_id != ""
        && variable_global_exists("owner_db")
        && is_struct(global.owner_db)
        && variable_struct_exists(global.owner_db, _owner_record_id)
    ) {
        var _owner_record = variable_struct_get(
            global.owner_db,
            _owner_record_id
        );
        db_apply_owner_record_to_instance(_owner_record, _owner);
    }

    // Снимок гарантирует возвращение именно того же владельца,
    // даже если запись базы ещё не была создана к моменту госпитализации.
    _owner.char_name = _snapshot.char_name;
    _owner.age = _snapshot.age;
    _owner.is_female = _snapshot.is_female;
    _owner.character_trait = _snapshot.character_trait;
    _owner.owner_trust = _snapshot.owner_trust;
    _owner.loyalty_level = _snapshot.loyalty_level;
    _owner.loyalty_success_progress = _snapshot.loyalty_success_progress;
    _owner.patience_level = _snapshot.patience_level;
    _owner.owner_feature_id = _snapshot.owner_feature_id;
    _owner.owner_feature_name_ru = _snapshot.owner_feature_name_ru;
    _owner.hair_color = _snapshot.hair_color;
    _owner.my_hair = _snapshot.my_hair;
    _owner.my_hair_back = _snapshot.my_hair_back;
    _owner.my_eyes = _snapshot.my_eyes;
    _owner.my_nose = _snapshot.my_nose;
    _owner.my_mouth = _snapshot.my_mouth;
    _owner.portrait_x = _snapshot.portrait_x;
    _owner.portrait_y = _snapshot.portrait_y;
    _owner.portrait_zoom = _snapshot.portrait_zoom;

    with (_owner) {
        portrait_bake();
    }

    _owner.alarm[0] = -1;
    _owner.owner_record_id = _owner_record_id;
    _owner.pet_record_id = variable_struct_exists(_snapshot, "pet_record_id")
        ? _snapshot.pet_record_id
        : "";
    _owner.scheduled_visit_id = variable_struct_exists(_snapshot, "scheduled_visit_id")
        ? _snapshot.scheduled_visit_id
        : "";
    _owner.pending_payment_total = variable_struct_exists(_snapshot, "pending_payment_total")
        ? _snapshot.pending_payment_total
        : 0;
    _owner.visit_price = variable_struct_exists(_snapshot, "visit_price")
        ? _snapshot.visit_price
        : 0;
    _owner.visit_reputation_awarded = variable_struct_exists(_snapshot, "visit_reputation_awarded")
        ? _snapshot.visit_reputation_awarded
        : false;

    _owner.my_pet = _ward.patient;
    _owner.registered = true;
    _owner.queue_purpose = "payment";
    _owner.payment_pending = true;
    _owner.payment_done = false;
    _owner.assigned_doctor = noone;
    _owner.assigned_table = noone;
    _owner.exam_target_x = _ward.owner_point.x;
    _owner.exam_target_y = _ward.owner_point.y;
    _owner.state = "going_to_exam";

    with (_ward.patient) {
        my_owner = _owner;
        state = "in_exam";
        path_end();
        is_walking = false;
    }

    array_push(global.city_pet_owners, _owner);
    array_push(global.active_visitors, _owner);

    _ward.returning_owner = _owner;
    _ward.phase = "owner_returning";

    inpatient_walk_to(
        _owner,
        _ward.owner_point.x,
        _ward.owner_point.y
    );

    return _owner;
}

function inpatient_finish_pickup(_ward) {
    if (!instance_exists(_ward)) return false;
    if (!instance_exists(_ward.patient)) return false;
    if (!instance_exists(_ward.returning_owner)) return false;

    var _pet = _ward.patient;
    var _owner = _ward.returning_owner;

    with (_pet) {
        inpatient_active = false;
        inpatient_controller = noone;
        assigned_doctor = noone;
        assigned_table = noone;
        state = "follow_owner";
        follow_offset_x = 30;
        follow_offset_y = 20;
        path_end();
        is_walking = false;
    }

    with (_owner) {
        my_pet = _pet;
        registered = true;
        queue_purpose = "payment";
        payment_pending = true;
        payment_done = false;
        assigned_doctor = noone;
        assigned_table = noone;
    }

    reception_enqueue_priority_payment(_owner);

    if (instance_exists(_ward.ward_table)) {
        with (_ward.ward_table) {
            table_busy = false;
            assigned_owner = noone;
            assigned_doctor = noone;
            assigned_pet = noone;
        }
    }

    _ward.patient = noone;
    _ward.departing_owner = noone;
    _ward.returning_owner = noone;
    _ward.escort_doctor = noone;
    _ward.ward_doctor = noone;
    _ward.ward_assistant = noone;
    _ward.owner_snapshot = {};
    _ward.phase = "empty";
    _ward.prescriptions_assigned = false;
    _ward.treatment_actions = [];
    _ward.cycle_action_index = 0;
    _ward.cycle_active = false;
    _ward.next_treatment_minute = -1;

    if (instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);

        if (
            instance_exists(_hud)
            && variable_instance_exists(_hud, "show_notice")
        ) {
            with (_hud) {
                show_notice(
                    "ВЫПИСКА",
                    "Владелец забрал выздоровевшего питомца",
                    room_speed * 4
                );
            }
        }
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 9.1 РУЧНАЯ РАБОТА ГЛАВНОГО ИГРОКА В СТАЦИОНАРЕ
// ═══════════════════════════════════════════════════════════════

function inpatient_player_release(_ward, _next_phase) {
    if (!instance_exists(_ward)) return false;

    var _player = _ward.player_actor;

    if (instance_exists(_player)) {
        with (_player) {
            path_end();
            speed = 0;
            is_walking = false;
            assigned_owner = noone;
            assigned_table = noone;
            assigned_pet = noone;
            service_mode = "";
            inpatient_manual_task = "";
            doctor_state = "idle";
            action_progress_active = false;
        }
    }

    if (instance_exists(_ward.patient)) {
        _ward.patient.assigned_doctor = noone;
    }

    _ward.player_actor = noone;
    _ward.player_task = "";
    _ward.phase = _next_phase;

    return true;
}

function inpatient_player_request_task(_pet, _task) {
    var _ward = inpatient_get_ward_for_pet(_pet);
    if (!instance_exists(_ward)) return false;
    if (!instance_exists(_pet) || _ward.patient != _pet) return false;
    if (!instance_exists(obj_player)) return false;

    var _player = instance_find(obj_player, 0);
    if (!instance_exists(_player)) return false;
    if (_player.doctor_state != "idle") return false;
    if (instance_exists(_ward.player_actor)) return false;

    if (_task == "assign") {
        if (_ward.phase != "waiting_doctor") return false;
        if (instance_exists(_ward.ward_doctor)) return false;

        // В ручном режиме игрок также начинает с чистых кнопок назначения.
        inpatient_clear_outpatient_prescriptions(_pet);
    }
    else if (_task == "treat") {
        if (_ward.phase != "waiting_cycle") return false;
        if (inpatient_now_absolute_minute() < _ward.next_treatment_minute) return false;
        if (array_length(_ward.treatment_actions) <= 0) return false;
        if (instance_exists(_ward.ward_assistant)) return false;
    }
    else {
        return false;
    }

    _ward.player_actor = _player;
    _ward.player_task = _task;
    _ward.phase = (_task == "assign")
        ? "player_going_assign"
        : "player_going_treat";

    _player.inpatient_manual_task = _task;
    _player.assigned_owner = noone;
    _player.assigned_table = _ward.ward_table;
    _player.assigned_pet = _pet;
    _player.service_mode = (_task == "assign") ? "doctor" : "procedure";
    _player.doctor_state = "inpatient_player_going";

    _pet.assigned_doctor = _player;

    var _target = (_task == "assign")
        ? _ward.doctor_point
        : _ward.assistant_point;

    inpatient_walk_to(_player, _target.x, _target.y);
    return true;
}

function inpatient_player_finish_assignments(_player, _pet) {
    var _ward = inpatient_get_ward_for_pet(_pet);
    if (!instance_exists(_ward)) return false;
    if (!instance_exists(_player) || _ward.player_actor != _player) return false;
    if (!instance_exists(_pet) || _ward.patient != _pet) return false;
    if (!is_struct(_pet.current_case)) return false;

    var _actions = case_build_next_procedure_assignments(_pet.current_case);

    if (array_length(_actions) <= 0) {
        return false;
    }

    doctor_visit_mark_inpatient_prescriber(_pet, _player);

    _pet.current_case.pending_procedure_actions = _actions;
    _ward.treatment_actions = _actions;
    _ward.prescriptions_assigned = true;
    _ward.cycle_action_index = 0;
    _ward.cycle_active = false;
    _ward.next_treatment_minute = inpatient_now_absolute_minute();

    inpatient_player_release(_ward, "waiting_cycle");
    return true;
}

function inpatient_player_all_actions_done(_ward) {
    if (!instance_exists(_ward)) return false;
    if (!instance_exists(_ward.patient)) return false;
    if (!is_struct(_ward.patient.current_case)) return false;

    var _done = variable_struct_exists(
        _ward.patient.current_case,
        "visit_treatments_done"
    ) ? _ward.patient.current_case.visit_treatments_done : [];

    for (var _index = 0; _index < array_length(_ward.treatment_actions); _index++) {
        var _action_id = _ward.treatment_actions[_index];
        var _found = false;

        for (var _done_index = 0; _done_index < array_length(_done); _done_index++) {
            if (_done[_done_index] == _action_id) {
                _found = true;
                break;
            }
        }

        if (!_found) return false;
    }

    return array_length(_ward.treatment_actions) > 0;
}

function inpatient_player_finish_treatment(_player, _pet) {
    var _ward = inpatient_get_ward_for_pet(_pet);
    if (!instance_exists(_ward)) return false;
    if (!instance_exists(_player) || _ward.player_actor != _player) return false;
    if (!instance_exists(_pet) || _ward.patient != _pet) return false;
    if (!inpatient_player_all_actions_done(_ward)) return false;

    var _next_phase = "waiting_cycle";

    // Пакет №170: пока операция не сделана, выписки нет.
    if (_pet.condition >= 100 && !inpatient_patient_waits_surgery(_ward)) {
        _next_phase = "recovered";
    } else {
        _ward.next_treatment_minute = inpatient_now_absolute_minute() + 120;
    }

    _ward.cycle_action_index = 0;
    _ward.cycle_active = false;
    inpatient_player_release(_ward, _next_phase);
    return true;
}

function inpatient_player_cancel_task(_player) {
    var _ward = inpatient_find_ward_with_player(_player);
    if (!instance_exists(_ward)) return false;
    if (!instance_exists(_player) || _ward.player_actor != _player) return false;

    var _return_phase = (_ward.player_task == "assign")
        ? "waiting_doctor"
        : "waiting_cycle";

    return inpatient_player_release(_ward, _return_phase);
}


// ═══════════════════════════════════════════════════════════════
// 10. ПОИСК ПЕРСОНАЛА СТАЦИОНАРА
// ═══════════════════════════════════════════════════════════════

function inpatient_find_doctor() {
    for (var _index = 0; _index < instance_number(obj_staff_doctor); _index++) {
        var _doctor = instance_find(obj_staff_doctor, _index);

        if (!instance_exists(_doctor)) continue;
        staff_workplace_init(_doctor);

        if (
            _doctor.workplace_id == "inpatient"
            && (
                _doctor.doctor_state == "inpatient_available"
                || _doctor.doctor_state == "inpatient_at_chair"
            )
        ) {
            return _doctor;
        }
    }

    return noone;
}

function inpatient_find_assistant() {
    for (var _index = 0; _index < instance_number(obj_staff_assistant); _index++) {
        var _assistant = instance_find(obj_staff_assistant, _index);

        if (!instance_exists(_assistant)) continue;
        staff_workplace_init(_assistant);

        if (
            _assistant.workplace_id == "inpatient"
            && _assistant.assistant_state == "inpatient_available"
        ) {
            return _assistant;
        }
    }

    return noone;
}


// ═══════════════════════════════════════════════════════════════
// 11. ОСНОВНОЙ STEP КОНТРОЛЛЕРА
// ═══════════════════════════════════════════════════════════════

function inpatient_controller_step(_ward) {
    if (!instance_exists(_ward)) return;

    // ═══ Пакет №170: пациента увезли в операционную ═══
    // Койка закреплена за ним и никому не отдаётся, лечение и выписка
    // на паузе. Флаг снимает operating_system, когда пациент вернулся.
    if (
        variable_instance_exists(_ward, "or_surgery_hold")
        && _ward.or_surgery_hold
    ) {
        inpatient_refresh_room_links(_ward);
        return;
    }

    // Пакет №73 (hotfix): один раз печатаем полную сводку по койке, чтобы
    // в логе было видно, чего не хватает (стол, точки, шкаф).
    if (!variable_instance_exists(_ward, "_bed_logged")) {
        _ward._bed_logged = true;

        var _log_slot = variable_instance_exists(_ward, "exam_slot_id")
            ? _ward.exam_slot_id
            : -1;

        show_debug_message(
            "[INPATIENT] Контроллер койки exam_slot_id = " + string(_log_slot)
        );

        inpatient_refresh_room_links(_ward);

        var _has_table = instance_exists(_ward.ward_table);
        var _has_doc = instance_exists(_ward.doctor_point);
        var _has_asst = instance_exists(_ward.assistant_point);
        var _has_floor = instance_exists(_ward.pet_floor_point);
        var _has_tablept = instance_exists(_ward.pet_table_point);
        var _has_owner = instance_exists(_ward.owner_point);

        var _cabinet = inpatient_find_cabinet();
        var _cab_txt = instance_exists(_cabinet) ? "есть" : "НЕТ ШКАФА";

        show_debug_message(
            "[INPATIENT] Койка " + string(_log_slot)
            + " -> стол:" + (_has_table ? "есть" : "НЕТ")
            + " | врач:" + (_has_doc ? "есть" : "НЕТ")
            + " | ассист:" + (_has_asst ? "есть" : "НЕТ")
            + " | пол:" + (_has_floor ? "есть" : "НЕТ")
            + " | точка-стола:" + (_has_tablept ? "есть" : "НЕТ")
            + " | владелец:" + (_has_owner ? "есть" : "НЕТ")
            + " | шкаф:" + _cab_txt
        );
    }

    // Пакет №135: ссылки на объекты койки не меняются каждый кадр, поэтому
    // обновляем их раз в 10 кадров (а не 4 раза за кадр — по разу на койку).
    // Если ссылка потерялась (instance пропал) — обновляем сразу.
    if (!variable_instance_exists(_ward, "_link_tick")) _ward._link_tick = 0;
    _ward._link_tick += 1;

    if (
        _ward._link_tick >= 10
        || !instance_exists(_ward.ward_table)
        || !instance_exists(_ward.doctor_point)
    ) {
        _ward._link_tick = 0;
        inpatient_refresh_room_links(_ward);
    }

    // Пакет №73: общими сотрудниками (врач/ассистент) управляет только
    // главный контроллер койки №1. Койки 2–4 не дёргают одного врача
    // в разные стороны одновременно.
    var _is_primary = (_ward == inpatient_get_controller());

    // Сотрудники, выбранные через карточку, физически приходят на свои места.
    if (_is_primary) {
        for (var _position_doctor_index = 0; _position_doctor_index < instance_number(obj_staff_doctor); _position_doctor_index++) {
            var _position_doctor = instance_find(obj_staff_doctor, _position_doctor_index);

            if (!instance_exists(_position_doctor)) continue;
            staff_workplace_init(_position_doctor);

            if (
                _position_doctor.doctor_state == "inpatient_moving_to_chair"
                && instance_exists(_ward.doctor_rest_point)
            ) {
                inpatient_ensure_walk(
                    _position_doctor,
                    _ward.doctor_rest_point.x,
                    _ward.doctor_rest_point.y
                );
            }

            if (
                _position_doctor.workplace_id == "inpatient"
                && _position_doctor.doctor_state == "inpatient_moving_to_chair"
                && instance_exists(_ward.doctor_rest_point)
                && inpatient_actor_at_target(
                    _position_doctor,
                    _ward.doctor_rest_point.x,
                    _ward.doctor_rest_point.y,
                    12
                )
            ) {
                inpatient_stop_actor(_position_doctor);
                _position_doctor.doctor_state = "inpatient_at_chair";
            }

            // Свободный врач идёт к стулу только если ни одна койка
            // не ждёт назначений.
            if (
                _ward.phase == "empty"
                && !inpatient_any_bed_needs_doctor()
                && _position_doctor.workplace_id == "inpatient"
                && _position_doctor.doctor_state == "inpatient_available"
                && instance_exists(_ward.doctor_rest_point)
                && !inpatient_actor_at_target(
                    _position_doctor,
                    _ward.doctor_rest_point.x,
                    _ward.doctor_rest_point.y,
                    12
                )
            ) {
                _position_doctor.doctor_state = "inpatient_moving_to_chair";
                inpatient_walk_to(
                    _position_doctor,
                    _ward.doctor_rest_point.x,
                    _ward.doctor_rest_point.y
                );
            }
        }

        for (var _position_assistant_index = 0; _position_assistant_index < instance_number(obj_staff_assistant); _position_assistant_index++) {
            var _position_assistant = instance_find(obj_staff_assistant, _position_assistant_index);

            if (!instance_exists(_position_assistant)) continue;
            staff_workplace_init(_position_assistant);

            if (
                _position_assistant.assistant_state == "inpatient_moving_to_station"
                && instance_exists(_ward.assistant_point)
            ) {
                inpatient_ensure_walk(
                    _position_assistant,
                    _ward.assistant_point.x,
                    _ward.assistant_point.y
                );
            }
            else if (_position_assistant.assistant_state == "inpatient_moving_to_home") {
                inpatient_ensure_walk(
                    _position_assistant,
                    _position_assistant.home_x,
                    _position_assistant.home_y
                );
            }

            if (
                _position_assistant.workplace_id == "inpatient"
                && _position_assistant.assistant_state == "inpatient_moving_to_station"
                && instance_exists(_ward.assistant_point)
                && inpatient_actor_at_target(
                    _position_assistant,
                    _ward.assistant_point.x,
                    _ward.assistant_point.y,
                    12
                )
            ) {
                inpatient_stop_actor(_position_assistant);
                _position_assistant.assistant_state = "inpatient_available";
            }

            if (
                _position_assistant.workplace_id == "inpatient"
                && _position_assistant.assistant_state == "inpatient_moving_to_home"
                && inpatient_actor_at_target(
                    _position_assistant,
                    _position_assistant.home_x,
                    _position_assistant.home_y,
                    12
                )
            ) {
                inpatient_stop_actor(_position_assistant);
                _position_assistant.assistant_state = "inpatient_available";
            }
        }
    }

    if (_ward.link_retry_timer > 0) {
        _ward.link_retry_timer -= 1;
    }

    if (
        _ward.departing_owner != noone
        && !instance_exists(_ward.departing_owner)
    ) {
        _ward.departing_owner = noone;
    }

    if (!instance_exists(_ward.patient) && _ward.phase != "empty") {
        if (instance_exists(_ward.ward_table)) {
            _ward.ward_table.table_busy = false;
            _ward.ward_table.assigned_pet = noone;
        }
        _ward.phase = "empty";
        _ward.patient = noone;
        _ward.departing_owner = noone;
        _ward.returning_owner = noone;
        _ward.treatment_actions = [];
    }

    // До появления назначений ассистент стационара не дежурит у животного.
    // Он использует обычную очередь пополнения всех шкафов клиники.
    var _assistant_may_restock = (
        _ward.phase == "empty"
        || _ward.phase == "admitting"
        || _ward.phase == "waiting_doctor"
        || _ward.phase == "player_going_assign"
        || _ward.phase == "player_assigning"
        || _ward.phase == "waiting_cycle"
    );

    // Пакет №73: ассистент уходит пополнять шкафы только если ни одна
    // койка сейчас не ждёт его для цикла лечения.
    if (_is_primary && _assistant_may_restock && !inpatient_any_bed_needs_assistant()) {
        if (_ward.assistant_idle_restock_timer > 0) {
            _ward.assistant_idle_restock_timer -= 1;
        } else {
            _ward.assistant_idle_restock_timer = room_speed;

            for (var _idle_assistant_index = 0; _idle_assistant_index < instance_number(obj_staff_assistant); _idle_assistant_index++) {
                var _idle_assistant = instance_find(
                    obj_staff_assistant,
                    _idle_assistant_index
                );

                if (!instance_exists(_idle_assistant)) continue;
                staff_workplace_init(_idle_assistant);

                if (
                    _idle_assistant.workplace_id == "inpatient"
                    && _idle_assistant.assistant_state == "inpatient_available"
                    && !_idle_assistant.wander_walking
                ) {
                    _idle_assistant.assistant_state = "idle";
                    var _restock_taken = assistant_try_take_restock_job(
                        _idle_assistant,
                        false
                    );

                    if (!_restock_taken) {
                        if (!inpatient_actor_at_target(
                            _idle_assistant,
                            _idle_assistant.home_x,
                            _idle_assistant.home_y,
                            12
                        )) {
                            _idle_assistant.assistant_state = "inpatient_moving_to_home";
                            inpatient_walk_to(
                                _idle_assistant,
                                _idle_assistant.home_x,
                                _idle_assistant.home_y
                            );
                        } else {
                            _idle_assistant.assistant_state = "inpatient_available";
                        }
                    }

                    break;
                }
            }
        }
    }

    // Владелец дошёл до выхода — сохраняем пациента и удаляем только владельца.
    if (instance_exists(_ward.departing_owner)) {
        if (
            _ward.departing_owner.path_index < 0
            && point_distance(
                _ward.departing_owner.x,
                _ward.departing_owner.y,
                global.clinic_exit_x,
                global.clinic_exit_y
            ) > 18
        ) {
            with (_ward.departing_owner) {
                move_towards_point(
                    global.clinic_exit_x,
                    global.clinic_exit_y,
                    p_move_speed
                );
                is_walking = true;
            }
        }

        if (point_distance(
            _ward.departing_owner.x,
            _ward.departing_owner.y,
            global.clinic_exit_x,
            global.clinic_exit_y
        ) <= 18) {
            var _departing = _ward.departing_owner;
            _ward.departing_owner = noone;

            if (instance_exists(_ward.patient)) {
                _departing.my_pet = noone;
                _ward.patient.my_owner = noone;
            }

            with (_departing) {
                instance_destroy();
            }
        }
    }

    // Сопровождающий врач возвращается на обычный приём после посадки пациента.
    // Проверяем не только state, но и фактическую позицию: видовая анимация
    // может зафиксировать животное на несколько пикселей выше маркера.
    if (_ward.phase == "admitting" && instance_exists(_ward.patient)) {
        _ward.admission_timer += 1;

        var _patient_distance_to_bed = point_distance(
            _ward.patient.x,
            _ward.patient.y,
            _ward.pet_table_point.x,
            _ward.pet_table_point.y
        );
        var _patient_on_bed = (
            _ward.patient.state == "in_exam"
            && _patient_distance_to_bed <= 24
        );

        // Страховка от недостижимого маркера: через 12 секунд животное
        // фиксируется на койке, а врач не остаётся навсегда у стола.
        if (!_patient_on_bed && _ward.admission_timer >= room_speed * 12) {
            inpatient_stop_actor(_ward.patient);
            _ward.patient.x = _ward.pet_table_point.x;
            _ward.patient.y = _ward.pet_table_point.y;
            _ward.patient.exam_table_x = _ward.pet_table_point.x;
            _ward.patient.exam_table_y = _ward.pet_table_point.y;
            _ward.patient.state = "in_exam";
            _patient_on_bed = true;
        }

        if (_patient_on_bed) {
            _ward.phase = "waiting_doctor";
            _ward.admission_timer = 0;
            _ward.patient.assigned_doctor = noone;

            if (instance_exists(_ward.escort_doctor)) {
                var _escort = _ward.escort_doctor;
                _escort.assigned_pet = noone;
                _escort.doctor_state = "inpatient_escort_return";
                inpatient_walk_to(
                    _escort,
                    _ward.escort_return_x,
                    _ward.escort_return_y
                );
            }
        }
    }

    if (instance_exists(_ward.escort_doctor)) {
        if (
            _ward.escort_doctor.doctor_state == "inpatient_escort_return"
            && !inpatient_actor_at_target(
                _ward.escort_doctor,
                _ward.escort_return_x,
                _ward.escort_return_y,
                12
            )
            && (
                _ward.escort_doctor.path_index < 0
                || !_ward.escort_doctor.is_walking
            )
        ) {
            inpatient_walk_to(
                _ward.escort_doctor,
                _ward.escort_return_x,
                _ward.escort_return_y
            );
        }

        if (
            _ward.escort_doctor.doctor_state == "inpatient_escort_return"
            && inpatient_actor_at_target(
                _ward.escort_doctor,
                _ward.escort_return_x,
                _ward.escort_return_y,
                12
            )
        ) {
            var _escort_done = _ward.escort_doctor;
            _ward.escort_doctor = noone;

            inpatient_stop_actor(_escort_done);

            if (_escort_done.workplace_id == "reception") {
                _escort_done.doctor_state = "idle";
            } else {
                inpatient_staff_begin_step(_escort_done);
            }
        }
    }

    // Главный игрок может вручную занять точку врача или ассистента.
    if (instance_exists(_ward.player_actor)) {
        var _manual_player = _ward.player_actor;
        var _manual_target = (_ward.player_task == "assign")
            ? _ward.doctor_point
            : _ward.assistant_point;

        if (_manual_player.doctor_state == "inpatient_player_going") {
            inpatient_ensure_walk(
                _manual_player,
                _manual_target.x,
                _manual_target.y
            );

            if (inpatient_actor_at_target(
                _manual_player,
                _manual_target.x,
                _manual_target.y,
                12
            )) {
                inpatient_stop_actor(_manual_player);

                if (_ward.player_task == "assign") {
                    _manual_player.doctor_state = "manual_exam";
                    _ward.phase = "player_assigning";
                } else {
                    _manual_player.doctor_state = "manual_procedure";
                    _ward.phase = "player_treating";

                    if (is_struct(_ward.patient.current_case)) {
                        if (!_ward.cycle_active) {
                            _ward.patient.current_case.visit_treatments_done = [];
                            _ward.cycle_active = true;
                        }

                        // Зелёная отметка назначения относится к выбору врача,
                        // а не к выполнению текущего двухчасового цикла.
                        // Перед процедурами начинаем с нейтральных кнопок.
                        _ward.patient.current_case.visit_treatment_feedback_ok_ids = [];
                        _ward.patient.current_case.visit_treatment_feedback_bad_ids = [];

                        // При повторном открытии после пополнения зелёными остаются
                        // только действительно выполненные действия этого цикла.
                        for (
                            var _manual_done_index = 0;
                            _manual_done_index < array_length(
                                _ward.patient.current_case.visit_treatments_done
                            );
                            _manual_done_index++
                        ) {
                            array_push(
                                _ward.patient.current_case.visit_treatment_feedback_ok_ids,
                                _ward.patient.current_case.visit_treatments_done[_manual_done_index]
                            );
                        }

                        _ward.patient.current_case.stock_blocked = false;
                        _ward.patient.current_case.stock_missing_item_id = "";
                        _ward.patient.current_case.stock_missing_item_name = "";
                    }
                }

                if (instance_exists(obj_UI_Tablet)) {
                    var _manual_tablet = instance_find(obj_UI_Tablet, 0);
                    _manual_tablet.target_id = _ward.patient;
                    _manual_tablet.visible = true;
                    _manual_tablet.tablet_click_lock = 5;
                }
            }
        }
    }
    else if (
        _ward.phase == "player_going_assign"
        || _ward.phase == "player_assigning"
    ) {
        _ward.phase = "waiting_doctor";
    }
    else if (
        _ward.phase == "player_going_treat"
        || _ward.phase == "player_treating"
    ) {
        _ward.phase = "waiting_cycle";
    }

    // Врач стационара подходит и один раз назначает лечение.
    if (_ward.phase == "waiting_doctor") {
        if (!instance_exists(_ward.ward_doctor)) {
            _ward.ward_doctor = inpatient_find_doctor();

            if (instance_exists(_ward.ward_doctor)) {
                _ward.ward_doctor.doctor_state = "inpatient_going_to_patient";
                inpatient_walk_to(
                    _ward.ward_doctor,
                    _ward.doctor_point.x,
                    _ward.doctor_point.y
                );
            }
        }
    }

    if (instance_exists(_ward.ward_doctor)) {
        var _doctor = _ward.ward_doctor;

        if (_doctor.doctor_state == "inpatient_going_to_patient") {
            inpatient_ensure_walk(
                _doctor,
                _ward.doctor_point.x,
                _ward.doctor_point.y
            );
        }
        else if (_doctor.doctor_state == "inpatient_returning_to_chair") {
            inpatient_ensure_walk(
                _doctor,
                _ward.doctor_rest_point.x,
                _ward.doctor_rest_point.y
            );
        }

        if (
            _doctor.doctor_state == "inpatient_going_to_patient"
            && inpatient_actor_at_target(
                _doctor,
                _ward.doctor_point.x,
                _ward.doctor_point.y,
                12
            )
        ) {
            inpatient_stop_actor(_doctor);
            _doctor.doctor_state = "inpatient_prescribing";
            // Пакет №75: привязываем стол койки, чтобы родитель par_staff
            // развернул врача лицом к столу и рисовал его поверх стола.
            _doctor.assigned_table = _ward.ward_table;
            _ward.doctor_action_timer_max = max(
                game_get_speed(gamespeed_fps) * 2,
                doctor_get_exam_duration_frames(
                    doctor_get_inpatient_level(_doctor)
                )
            );
            _ward.doctor_action_timer = _ward.doctor_action_timer_max;
        }

        if (_doctor.doctor_state == "inpatient_prescribing") {
            _doctor.exam_timer = _ward.doctor_action_timer;
            _doctor.exam_timer_max = _ward.doctor_action_timer_max;
            _doctor.action_progress_active = true;
            _doctor.action_progress_timer = _ward.doctor_action_timer;
            _doctor.action_progress_timer_max = _ward.doctor_action_timer_max;
            _doctor.action_progress_label = "НАЗНАЧЕНИЯ";
            _doctor.action_progress_color = make_color_rgb(80, 140, 220);

            _ward.doctor_action_timer -= 1;

            if (_ward.doctor_action_timer <= 0) {
                inpatient_assign_treatments(_ward, _doctor);
                _doctor.exam_timer = 0;
                _doctor.exam_timer_max = 0;
                _doctor.action_progress_active = false;
                _doctor.assigned_table = noone;
                _doctor.doctor_state = "inpatient_returning_to_chair";
                inpatient_walk_to(
                    _doctor,
                    _ward.doctor_rest_point.x,
                    _ward.doctor_rest_point.y
                );
            }
        }

        if (
            _doctor.doctor_state == "inpatient_returning_to_chair"
            && inpatient_actor_at_target(
                _doctor,
                _ward.doctor_rest_point.x,
                _ward.doctor_rest_point.y,
                12
            )
        ) {
            inpatient_stop_actor(_doctor);
            _doctor.doctor_state = "inpatient_at_chair";
            _ward.ward_doctor = noone;
        }
    }

    // Если назначений нет, ждём врача и не запускаем пустой цикл.
    if (
        _ward.phase == "waiting_cycle"
        && array_length(_ward.treatment_actions) <= 0
    ) {
        _ward.phase = "waiting_doctor";
        _ward.prescriptions_assigned = false;
    }

    // Ассистент начинает немедленный или очередной двухчасовой цикл.
    if (
        _ward.phase == "waiting_cycle"
        && inpatient_now_absolute_minute() >= _ward.next_treatment_minute
    ) {
        if (!instance_exists(_ward.ward_assistant)) {
            _ward.ward_assistant = inpatient_find_assistant();

            if (instance_exists(_ward.ward_assistant)) {
                _ward.cycle_active = true;
                _ward.ward_assistant.assistant_state = "inpatient_going_to_patient";
                inpatient_walk_to(
                    _ward.ward_assistant,
                    _ward.assistant_point.x,
                    _ward.assistant_point.y
                );
            }
        }
    }

    if (instance_exists(_ward.ward_assistant)) {
        var _assistant = _ward.ward_assistant;

        if (_assistant.assistant_state == "inpatient_going_to_patient") {
            inpatient_ensure_walk(
                _assistant,
                _ward.assistant_point.x,
                _ward.assistant_point.y
            );
        }

        if (
            _assistant.assistant_state == "inpatient_going_to_patient"
            && inpatient_actor_at_target(
                _assistant,
                _ward.assistant_point.x,
                _ward.assistant_point.y,
                12
            )
        ) {
            inpatient_stop_actor(_assistant);
            _assistant.assistant_state = "inpatient_treating";
            // Пакет №75: привязываем стол койки, чтобы родитель par_staff
            // развернул ассистента лицом к столу и рисовал его поверх стола.
            _assistant.assigned_table = _ward.ward_table;
            _ward.assistant_action_timer_max = max(
                room_speed * 2,
                _assistant.procedure_duration
            );
            _ward.assistant_action_timer = _ward.assistant_action_timer_max;
        }

        if (_assistant.assistant_state == "inpatient_treating") {
            _assistant.procedure_timer = _ward.assistant_action_timer;
            _assistant.procedure_duration = _ward.assistant_action_timer_max;
            _assistant.action_progress_active = true;
            _assistant.action_progress_timer = _ward.assistant_action_timer;
            _assistant.action_progress_timer_max = _ward.assistant_action_timer_max;
            _assistant.action_progress_label = "СТАЦИОНАР";
            _assistant.action_progress_color = make_color_rgb(80, 170, 90);

            _ward.assistant_action_timer -= 1;

            if (_ward.assistant_action_timer <= 0) {
                _assistant.procedure_timer = 0;

                var _action_id = _ward.treatment_actions[
                    clamp(
                        _ward.cycle_action_index,
                        0,
                        array_length(_ward.treatment_actions) - 1
                    )
                ];
                var _result = inpatient_apply_treatment_action(
                    _ward,
                    _action_id
                );

                if (_result.ok) {
                    _ward.cycle_action_index += 1;
                    _ward.stock_retry_timer = 0;

                    if (
                        variable_global_exists("daily_stats")
                        && variable_struct_exists(global.daily_stats, "procedures_done")
                    ) {
                        global.daily_stats.procedures_done += 1;
                    }

                    _assistant.staff_spend_energy(3);
                    assistant_add_skill_xp(_assistant, 0, 2, true);
                    _assistant.add_xp_log("+2 ПРОЦЕДУРЫ");

                    if (
                        instance_exists(_ward.patient)
                        && _ward.patient.condition >= 100
                        && !inpatient_patient_waits_surgery(_ward)
                    ) {
                        _assistant.action_progress_active = false;
                        _assistant.assigned_table = noone;
                        _assistant.assistant_state = "inpatient_available";
                        _ward.ward_assistant = noone;
                        _ward.phase = "recovered";
                    }
                    else if (
                        _ward.cycle_action_index
                        >= array_length(_ward.treatment_actions)
                    ) {
                        _ward.cycle_action_index = 0;
                        _ward.cycle_active = false;
                        _ward.next_treatment_minute = inpatient_now_absolute_minute() + 120;
                        _ward.phase = "waiting_cycle";
                        _assistant.action_progress_active = false;
                        _assistant.assigned_table = noone;
                        _assistant.assistant_state = "inpatient_available";
                        _ward.ward_assistant = noone;
                    }
                    else {
                        _ward.assistant_action_timer = _ward.assistant_action_timer_max;
                    }
                }
                else {
                    _assistant.action_progress_active = false;
                    _ward.phase = "waiting_stock";
                    _ward.stock_retry_timer = room_speed * 2;
                    _ward.missing_item_id = _result.missing_item_id;
                    _ward.missing_item_name = _result.missing_item_name;

                    // urgent job уже создан storage_prepare...; разрешаем этому же
                    // ассистенту временно использовать существующую систему пополнения.
                    _assistant.assigned_owner = noone;
                    _assistant.assigned_table = noone;
                    _assistant.assigned_pet = noone;
                    _assistant.assistant_state = "idle";

                    var _restock_started = assistant_try_take_restock_job(
                        _assistant,
                        false
                    );

                    if (!_restock_started) {
                        // Пакет №80: запоминаем на ассистенте название недостающего
                        // препарата, чтобы над его головой рисовалась табличка.
                        _assistant.inpatient_missing_item_name = _result.missing_item_name;
                        _assistant.assistant_state = "inpatient_waiting_stock";
                    } else {
                        _assistant.inpatient_missing_item_name = "";
                    }

                    _ward.ward_assistant = noone;

                    if (instance_exists(obj_UI_HUD)) {
                        var _hud_stock = instance_find(obj_UI_HUD, 0);

                        if (
                            instance_exists(_hud_stock)
                            && variable_instance_exists(_hud_stock, "show_notice")
                        ) {
                            with (_hud_stock) {
                                show_notice(
                                    "СТАЦИОНАР: НЕТ ПРЕПАРАТА",
                                    _result.missing_item_name,
                                    room_speed * 4
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    // После пополнения повторяем незавершённое назначение, не повторяя прошлые.
    if (_ward.phase == "waiting_stock") {
        if (_ward.stock_retry_timer > 0) {
            _ward.stock_retry_timer -= 1;
        } else {
            var _cabinet = inpatient_find_cabinet();
            var _stock_ready = false;

            if (
                instance_exists(_cabinet)
                && _ward.missing_item_id != ""
            ) {
                _stock_ready = inventory_get_amount(
                    _cabinet.storage_inventory,
                    _ward.missing_item_id
                ) > 0;
            }

            if (_stock_ready) {
                _ward.phase = "waiting_cycle";
                _ward.next_treatment_minute = inpatient_now_absolute_minute();
                _ward.missing_item_id = "";
                _ward.missing_item_name = "";

                for (var _waiting_assistant_index = 0; _waiting_assistant_index < instance_number(obj_staff_assistant); _waiting_assistant_index++) {
                    var _waiting_assistant = instance_find(
                        obj_staff_assistant,
                        _waiting_assistant_index
                    );

                    if (
                        instance_exists(_waiting_assistant)
                        && _waiting_assistant.workplace_id == "inpatient"
                        && _waiting_assistant.assistant_state == "inpatient_waiting_stock"
                    ) {
                        _waiting_assistant.assistant_state = "inpatient_available";
                        _waiting_assistant.inpatient_missing_item_name = "";
                    }
                }
            } else {
                _ward.stock_retry_timer = room_speed * 2;
            }
        }
    }

    // Выздоровевший пациент ждёт владельца до рабочего времени.
    if (_ward.phase == "recovered") {
        var _now_day_minute = global.game_hour * 60 + global.game_minute;
        var _return_allowed = (
            _now_day_minute >= 8 * 60
            && _now_day_minute < 22 * 60
            && !instance_exists(_ward.departing_owner)
        );

        if (_return_allowed) {
            inpatient_spawn_returning_owner(_ward);
        }
    }

    if (
        _ward.phase == "owner_returning"
        && instance_exists(_ward.returning_owner)
        && _ward.returning_owner.path_index < 0
        && point_distance(
            _ward.returning_owner.x,
            _ward.returning_owner.y,
            _ward.owner_point.x,
            _ward.owner_point.y
        ) > 14
    ) {
        with (_ward.returning_owner) {
            move_towards_point(
                _ward.owner_point.x,
                _ward.owner_point.y,
                p_move_speed
            );
            is_walking = true;
        }
    }

    if (
        _ward.phase == "owner_returning"
        && instance_exists(_ward.returning_owner)
        && point_distance(
            _ward.returning_owner.x,
            _ward.returning_owner.y,
            _ward.owner_point.x,
            _ward.owner_point.y
        ) <= 14
    ) {
        inpatient_finish_pickup(_ward);
    }
}
