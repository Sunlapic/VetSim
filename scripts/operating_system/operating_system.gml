/// operating_system.gml
/// @description Операционная: подбор бригады, движение к точкам, шкала операции,
/// койка восстановления и перевод в стационар.
/// Пакет №111 (логика). Пакет №112: после операции — койка восстановления,
/// ассистент ухаживает, перевод в стационар при освобождении койки.
/// Пакет №113: операция стартует сразу (без фазы «сбор бригады»), бригада идёт
/// к точкам параллельно таймеру — зависания больше нет.


// ═══════════════════════════════════════════════════════════════
// 1. СПРАВОЧНИК ДЕЙСТВИЙ
// ═══════════════════════════════════════════════════════════════

function operating_action_is_surgery(_action_id) {
    if (!variable_global_exists("med_db")) return false;
    if (!is_struct(global.med_db)) return false;
    if (!variable_struct_exists(global.med_db, "treatment_actions")) return false;
    if (!variable_struct_exists(global.med_db.treatment_actions, string(_action_id))) return false;

    var _ref = variable_struct_get(
        global.med_db.treatment_actions,
        string(_action_id)
    );

    return (
        variable_struct_exists(_ref, "is_surgery")
        && _ref.is_surgery
    );
}


// ═══════════════════════════════════════════════════════════════
// 2. НАВЫКИ И ВРЕМЯ
// ═══════════════════════════════════════════════════════════════

function operating_role_skill_index(_role) {
    switch (string(_role)) {
        case "surgeon": return 2;       // Хирургия
        case "anesthetist": return 7;   // Анестезиология
        case "assistant": return 1;     // Процедуры
    }

    return -1;
}

function operating_actor_skill_level(_actor, _role) {
    if (!instance_exists(_actor)) return 1;

    var _idx = operating_role_skill_index(_role);
    if (_idx < 0) return 1;

    var _skills = (
        variable_instance_exists(_actor, "skills")
        && is_array(_actor.skills)
    ) ? _actor.skills : [];

    if (_idx >= array_length(_skills)) return 1;

    return clamp(round(_skills[_idx]), 1, 10);
}

function operating_role_time(_level) {
    return max(2, 22 - 2 * clamp(round(_level), 1, 10));
}


// ═══════════════════════════════════════════════════════════════
// 3. ОБЪЕКТЫ ОПЕРАЦИОННОЙ
// ═══════════════════════════════════════════════════════════════

function operating_find_table() {
    return instance_exists(obj_operating_table)
        ? instance_find(obj_operating_table, 0)
        : noone;
}

function operating_find_recovery_bed() {
    return instance_exists(obj_or_recovery_bed)
        ? instance_find(obj_or_recovery_bed, 0)
        : noone;
}

function operating_find_point(_obj) {
    return instance_exists(_obj) ? instance_find(_obj, 0) : noone;
}


// ═══════════════════════════════════════════════════════════════
// 4. ПОДБОР БРИГАДЫ
// ═══════════════════════════════════════════════════════════════

function operating_doctor_is_free(_doc) {
    if (!instance_exists(_doc)) return false;
    if (!variable_instance_exists(_doc, "doctor_state")) return false;
    if (!variable_instance_exists(_doc, "workplace_id")) return false;

    return (
        _doc.workplace_id == "operating"
        && _doc.doctor_state == "operating_idle"
    );
}

function operating_assistant_is_free(_asst) {
    if (!instance_exists(_asst)) return false;
    if (!variable_instance_exists(_asst, "assistant_state")) return false;
    if (!variable_instance_exists(_asst, "workplace_id")) return false;

    return (
        _asst.workplace_id == "operating"
        && _asst.assistant_state == "operating_idle"
    );
}

function operating_find_role_actor(_role) {
    var _role_str = string(_role);

    // Ассистент.
    if (_role_str == "assistant") {
        for (var _i = 0; _i < instance_number(obj_staff_assistant); _i++) {
            var _a = instance_find(obj_staff_assistant, _i);

            if (
                operating_assistant_is_free(_a)
                && variable_instance_exists(_a, "operating_role")
                && _a.operating_role == "assistant"
                && operating_actor_skill_level(_a, "assistant") >= 3
            ) {
                return _a;
            }
        }

        return noone;
    }

    // Хирург / анестезиолог — врачи.
    for (var _i = 0; _i < instance_number(obj_staff_doctor); _i++) {
        var _d = instance_find(obj_staff_doctor, _i);

        if (
            operating_doctor_is_free(_d)
            && variable_instance_exists(_d, "operating_role")
            && _d.operating_role == _role_str
            && operating_actor_skill_level(_d, _role_str) >= 3
        ) {
            return _d;
        }
    }

    // Игрок заменяет отсутствующего хирурга или анестезиолога.
    var _player = instance_exists(obj_player)
        ? instance_find(obj_player, 0)
        : noone;

    if (
        instance_exists(_player)
        && operating_actor_skill_level(_player, _role_str) >= 3
    ) {
        return _player;
    }

    return noone;
}


// ═══════════════════════════════════════════════════════════════
// 5. ПРЕПАРАТЫ (расход из основного склада)
// ═══════════════════════════════════════════════════════════════

function operating_required_items(_action_id) {
    if (!variable_global_exists("med_db")) return [];
    if (!is_struct(global.med_db)) return [];
    if (!variable_struct_exists(global.med_db, "treatment_actions")) return [];
    if (!variable_struct_exists(global.med_db.treatment_actions, string(_action_id))) return [];

    var _ref = variable_struct_get(
        global.med_db.treatment_actions,
        string(_action_id)
    );

    if (
        variable_struct_exists(_ref, "required_items")
        && is_array(_ref.required_items)
    ) {
        return _ref.required_items;
    }

    return [];
}

function operating_missing_item(_action_id) {
    var _items = operating_required_items(_action_id);

    for (var _i = 0; _i < array_length(_items); _i++) {
        var _req = _items[_i];

        if (
            inventory_get_amount(
                global.inventory_main,
                _req.item_id
            ) < _req.amount
        ) {
            return item_get_name(_req.item_id);
        }
    }

    return "";
}

function operating_consume_items(_action_id) {
    var _items = operating_required_items(_action_id);

    for (var _i = 0; _i < array_length(_items); _i++) {
        var _req = _items[_i];

        inventory_remove_amount(
            global.inventory_main,
            _req.item_id,
            _req.amount
        );
    }
}


// ═══════════════════════════════════════════════════════════════
// 6. УВЕДОМЛЕНИЕ
// ═══════════════════════════════════════════════════════════════

function operating_notify(_title, _text, _frames) {
    if (!instance_exists(obj_UI_HUD)) return;

    var _hud = instance_find(obj_UI_HUD, 0);

    if (
        instance_exists(_hud)
        && variable_instance_exists(_hud, "show_notice")
    ) {
        with (_hud) {
            show_notice(_title, _text, _frames);
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 7. КОНТРОЛЛЕР: ИНИЦИАЛИЗАЦИЯ
// ═══════════════════════════════════════════════════════════════

function operating_controller_init(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    _ctrl.or_phase = "empty";
    _ctrl.or_pet = noone;
    _ctrl.or_action_id = "";
    _ctrl.or_action_name = "";
    _ctrl.or_surgeon = noone;
    _ctrl.or_anesthetist = noone;
    _ctrl.or_assistant = noone;
    _ctrl.or_timer = 0;
    _ctrl.or_timer_max = 0;
    _ctrl.or_surgeon_level = 1;
    _ctrl.or_anest_level = 1;
    _ctrl.or_assist_level = 1;
    _ctrl.or_table = noone;
    _ctrl.or_warned_room = false;
    _ctrl.or_warned_bed = false;
}


// ═══════════════════════════════════════════════════════════════
// 8. ЗАПРОС ОПЕРАЦИИ (вызывается из case_apply_treatment_action)
// ═══════════════════════════════════════════════════════════════

function operating_request(_pet, _action_id) {
    if (!instance_exists(_pet)) return false;

    var _ctrl = instance_exists(obj_operating_controller)
        ? instance_find(obj_operating_controller, 0)
        : noone;

    if (!instance_exists(_ctrl)) {
        operating_notify(
            "НЕТ ОПЕРАЦИОННОЙ",
            "Добавьте объект obj_operating_controller в комнату.",
            room_speed * 3
        );
        return false;
    }

    if (_ctrl.or_phase != "empty") {
        if (_ctrl.or_pet == _pet && _ctrl.or_action_id == string(_action_id)) {
            return false; // эта операция уже идёт
        }

        operating_notify(
            "ОПЕРАЦИОННАЯ ЗАНЯТА",
            "Идёт операция или восстановление. Подождите.",
            room_speed * 3
        );
        return false;
    }

    // ── Бригада ──
    var _surgeon = operating_find_role_actor("surgeon");
    var _anest = operating_find_role_actor("anesthetist");
    var _assist = operating_find_role_actor("assistant");

    if (!instance_exists(_surgeon)) {
        operating_notify(
            "НЕТ ХИРУРГА",
            "Нужен врач «ОПЕРАЦИОННАЯ: ХИРУРГ» (Хирургия 3+).",
            room_speed * 3
        );
        return false;
    }

    if (!instance_exists(_anest)) {
        operating_notify(
            "НЕТ АНЕСТЕЗИОЛОГА",
            "Нужен врач «ОПЕРАЦИОННАЯ: АНЕСТЕЗИОЛОГ» (Анестезиология 3+).",
            room_speed * 3
        );
        return false;
    }

    if (!instance_exists(_assist)) {
        operating_notify(
            "НЕТ АССИСТЕНТА",
            "Нужен ассистент «ОПЕРАЦИОННАЯ» (Процедуры 3+).",
            room_speed * 3
        );
        return false;
    }

    // ── Препараты ──
    var _missing = operating_missing_item(_action_id);

    if (_missing != "") {
        operating_notify(
            "НЕТ ПРЕПАРАТА",
            _missing + ". Пополните основной склад.",
            room_speed * 3
        );
        return false;
    }

    operating_consume_items(_action_id);

    // ── Время по сумме навыков бригады ──
    var _sl = operating_actor_skill_level(_surgeon, "surgeon");
    var _al = operating_actor_skill_level(_anest, "anesthetist");
    var _asl = operating_actor_skill_level(_assist, "assistant");

    var _seconds = operating_role_time(_sl)
        + operating_role_time(_al)
        + operating_role_time(_asl);

    _ctrl.or_phase = "operating";   // пакет №113: сразу оперируем, без отдельного сбора
    _ctrl.or_pet = _pet;
    _ctrl.or_action_id = string(_action_id);
    _ctrl.or_action_name = db_get_treatment_action_name(_action_id);
    _ctrl.or_surgeon = _surgeon;
    _ctrl.or_anesthetist = _anest;
    _ctrl.or_assistant = _assist;
    _ctrl.or_surgeon_level = _sl;
    _ctrl.or_anest_level = _al;
    _ctrl.or_assist_level = _asl;
    _ctrl.or_timer_max = _seconds * max(1, game_get_speed(gamespeed_fps));
    _ctrl.or_timer = _ctrl.or_timer_max;
    _ctrl.or_warned_room = false;

    operating_notify(
        "ОПЕРАЦИЯ НАЧАТА",
        _ctrl.or_action_name + " — бригада собирается и оперирует.",
        room_speed * 3
    );

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 9. ПРИМЕНЕНИЕ РЕЗУЛЬТАТА (копия финала case_apply_treatment_action)
// ═══════════════════════════════════════════════════════════════

function operating_apply_result(_pet, _action_id) {
    if (!instance_exists(_pet)) return;
    if (!variable_instance_exists(_pet, "current_case")) return;
    if (!is_struct(_pet.current_case)) return;

    var _case = _pet.current_case;

    if (!variable_struct_exists(_case, "treatment_progress")) _case.treatment_progress = [];
    if (!variable_struct_exists(_case, "visit_treatments_done")) _case.visit_treatments_done = [];
    if (!variable_struct_exists(_case, "visit_procedure_log")) _case.visit_procedure_log = [];
    if (!variable_struct_exists(_case, "visit_treatment_feedback_ok_ids")) _case.visit_treatment_feedback_ok_ids = [];

    array_push(_case.treatment_progress, _action_id);
    array_push(_case.visit_treatments_done, _action_id);
    array_push(_case.visit_procedure_log, {
        proc_type : "treatment",
        proc_id : _action_id,
        proc_name_ru : db_get_treatment_action_name(_action_id)
    });

    var _already_ok = false;

    for (
        var _ok_index = 0;
        _ok_index < array_length(_case.visit_treatment_feedback_ok_ids);
        _ok_index++
    ) {
        if (_case.visit_treatment_feedback_ok_ids[_ok_index] == _action_id) {
            _already_ok = true;
            break;
        }
    }

    if (!_already_ok) {
        array_push(_case.visit_treatment_feedback_ok_ids, _action_id);
    }

    var _condition_delta = 0;

    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "treatment_actions")
        && variable_struct_exists(global.med_db.treatment_actions, string(_action_id))
    ) {
        var _action_ref = variable_struct_get(
            global.med_db.treatment_actions,
            string(_action_id)
        );

        if (variable_struct_exists(_action_ref, "condition_delta")) {
            _condition_delta = max(0, _action_ref.condition_delta);
        }
    }

    _case.condition = clamp(_case.condition + _condition_delta, 0, 100);
    _case.case_status = (_case.condition >= 100)
        ? "recovered"
        : "in_treatment";

    _pet.current_case = _case;
    _pet.condition = _case.condition;
    animal_apply_case(_pet, _case);
}


// ═══════════════════════════════════════════════════════════════
// 10. ПЕРСОНАЛ: ДОМОЙ / ОТПУСК
// ═══════════════════════════════════════════════════════════════

function operating_send_home(_actor, _kind) {
    if (!instance_exists(_actor)) return;
    if (_actor.object_index == obj_player) return;

    var _home_x = variable_instance_exists(_actor, "home_x")
        ? _actor.home_x : _actor.x;
    var _home_y = variable_instance_exists(_actor, "home_y")
        ? _actor.home_y : _actor.y;

    if (string(_kind) == "assistant") {
        _actor.assistant_state = "operating_idle";
    } else {
        _actor.doctor_state = "operating_idle";
    }

    inpatient_walk_to(_actor, _home_x, _home_y);
}

function operating_release_staff(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    operating_send_home(_ctrl.or_surgeon, "doctor");
    operating_send_home(_ctrl.or_anesthetist, "doctor");
    operating_send_home(_ctrl.or_assistant, "assistant");
}

function operating_reset_fields(_ctrl) {
    _ctrl.or_phase = "empty";
    _ctrl.or_pet = noone;
    _ctrl.or_action_id = "";
    _ctrl.or_action_name = "";
    _ctrl.or_surgeon = noone;
    _ctrl.or_anesthetist = noone;
    _ctrl.or_assistant = noone;
    _ctrl.or_timer = 0;
    _ctrl.or_timer_max = 0;
}

function operating_controller_abort(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    operating_release_staff(_ctrl);
    operating_reset_fields(_ctrl);
}


// ═══════════════════════════════════════════════════════════════
// 11. КОЙКА ВОССТАНОВЛЕНИЯ (пакет №112)
// ═══════════════════════════════════════════════════════════════

function operating_pet_condition(_pet) {
    if (!instance_exists(_pet)) return 100;

    if (
        variable_instance_exists(_pet, "current_case")
        && is_struct(_pet.current_case)
        && variable_struct_exists(_pet.current_case, "condition")
    ) {
        return _pet.current_case.condition;
    }

    return variable_instance_exists(_pet, "condition")
        ? _pet.condition
        : 100;
}

function operating_recovery_bed_free(_ctrl) {
    var _bed = operating_find_recovery_bed();

    if (
        instance_exists(_bed)
        && variable_instance_exists(_bed, "table_busy")
    ) {
        _bed.table_busy = false;
        _bed.assigned_owner = noone;
        _bed.assigned_doctor = noone;
        _bed.assigned_pet = noone;
    }
}

// После операции пациент переводится на койку восстановления операционной.
function operating_start_recovery(_ctrl) {
    if (!instance_exists(_ctrl)) return;
    if (!instance_exists(_ctrl.or_pet)) {
        operating_controller_abort(_ctrl);
        return;
    }

    var _pet = _ctrl.or_pet;
    var _bed = operating_find_recovery_bed();
    var _pet_point = operating_find_point(obj_or_recovery_point_pet);

    if (!instance_exists(_bed) || !instance_exists(_pet_point)) {
        if (!_ctrl.or_warned_bed) {
            _ctrl.or_warned_bed = true;

            operating_notify(
                "НЕТ КОЙКИ ВОССТАНОВЛЕНИЯ",
                "Добавьте obj_or_recovery_bed и точку восстановления.",
                room_speed * 3
            );
        }

        // Койки нет — просто отпускаем бригаду (пациент остаётся у себя).
        operating_release_staff(_ctrl);
        operating_reset_fields(_ctrl);
        return;
    }

    // Освобождаем старый стол приёма.
    if (
        variable_instance_exists(_pet, "assigned_table")
        && instance_exists(_pet.assigned_table)
        && _pet.assigned_table != _bed
    ) {
        var _old_table = _pet.assigned_table;

        if (variable_instance_exists(_old_table, "table_busy")) {
            _old_table.table_busy = false;
            _old_table.assigned_owner = noone;
            _old_table.assigned_doctor = noone;
            _old_table.assigned_pet = noone;
        }
    }

    // Занимаем койку восстановления.
    if (variable_instance_exists(_bed, "table_busy")) {
        _bed.table_busy = true;
        _bed.assigned_owner = noone;
        _bed.assigned_doctor = noone;
        _bed.assigned_pet = _pet;
    }

    // Пометка: пациент после операции — стационар примет его даже при
    // состоянии ≥ 50 (inpatient_can_admit обходит порог по этому флагу).
    _pet.or_post_surgery = true;

    with (_pet) {
        assigned_table = _bed;
        assigned_doctor = noone;
        exam_floor_x = _pet_point.x;
        exam_floor_y = _pet_point.y;
        exam_table_x = _pet_point.x;
        exam_table_y = _pet_point.y;
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

    // Хирург и анестезиолог — домой.
    operating_send_home(_ctrl.or_surgeon, "doctor");
    operating_send_home(_ctrl.or_anesthetist, "doctor");

    // Ассистент — ухаживать у койки восстановления.
    var _asst_point = operating_find_point(obj_or_recovery_point_assistant);

    if (instance_exists(_ctrl.or_assistant) && instance_exists(_asst_point)) {
        _ctrl.or_assistant.assistant_state = "operating_going_to_recovery";
        inpatient_walk_to(
            _ctrl.or_assistant,
            _asst_point.x,
            _asst_point.y
        );
    }

    _ctrl.or_phase = "recovery";
    _ctrl.or_timer = 0;
    _ctrl.or_timer_max = 0;

    operating_notify(
        "ВОССТАНОВЛЕНИЕ",
        _ctrl.or_action_name + ": пациент на койке операционной.",
        room_speed * 4
    );
}

// Пациент выздоровел на койке операционной — возвращается к владельцу.
function operating_pet_return_to_owner(_ctrl) {
    if (!instance_exists(_ctrl)) return;
    if (!instance_exists(_ctrl.or_pet)) return;

    var _pet = _ctrl.or_pet;
    var _owner = (
        variable_instance_exists(_pet, "my_owner")
        && instance_exists(_pet.my_owner)
    ) ? _pet.my_owner : noone;

    operating_recovery_bed_free(_ctrl);

    _pet.or_post_surgery = false;

    if (instance_exists(_owner)) {
        with (_pet) {
            state = "follow_owner";
            follow_offset_x = 30;
            follow_offset_y = 20;

            path_end();
            speed = 0;
            is_walking = false;
        }
    }
}

// Перевод в стационар при освобождении койки.
function operating_try_transfer_to_inpatient(_ctrl) {
    if (!instance_exists(_ctrl)) return false;
    if (!instance_exists(_ctrl.or_pet)) return false;

    var _pet = _ctrl.or_pet;
    var _owner = (
        variable_instance_exists(_pet, "my_owner")
        && instance_exists(_pet.my_owner)
    ) ? _pet.my_owner : noone;

    if (!instance_exists(_owner)) return false;

    if (!instance_exists(inpatient_find_free_ward())) return false;

    if (inpatient_start_admission(_owner, _pet, noone)) {
        // Пациент переведён; койку операционной освобождаем и бригаду отпускаем.
        operating_recovery_bed_free(_ctrl);
        operating_send_home(_ctrl.or_assistant, "assistant");
        operating_reset_fields(_ctrl);
        return true;
    }

    return false;
}

// Полная очистка после восстановления.
function operating_clear_recovery(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    operating_recovery_bed_free(_ctrl);
    operating_send_home(_ctrl.or_assistant, "assistant");
    operating_reset_fields(_ctrl);
}


// ═══════════════════════════════════════════════════════════════
// 12. КОНТРОЛЛЕР: ОСНОВНОЙ ШАГ
// ═══════════════════════════════════════════════════════════════

function operating_controller_step(_ctrl) {
    if (!instance_exists(_ctrl)) return;
    if (_ctrl.or_phase == "empty") return;

    // Пациент исчез (визит отменён) — сворачиваем операцию.
    if (!instance_exists(_ctrl.or_pet)) {
        operating_controller_abort(_ctrl);
        return;
    }

    // ── Объекты комнаты ──
    var _table = operating_find_table();
    var _p_surg = operating_find_point(obj_operating_point_surgeon);
    var _p_anest = operating_find_point(obj_operating_point_anesthetist);
    var _p_assist = operating_find_point(obj_operating_point_assistant);

    _ctrl.or_table = _table;

    if (!instance_exists(_table) && !_ctrl.or_warned_room) {
        _ctrl.or_warned_room = true;

        operating_notify(
            "НЕТ ОПЕРАЦИОННОЙ",
            "Не найден стол операционной (obj_operating_table).",
            room_speed * 3
        );
    }

    if (instance_exists(_table)) {
        _ctrl.depth = _table.depth - 5;
    }

    // ── Фаза: операция (шкала идёт, бригада идёт параллельно) ──
    // Пакет №113: бригада больше не блокирует старт операции — таймер тикает
    // сразу, персонал подходит к точкам, пока идёт операция.
    if (_ctrl.or_phase == "operating") {
        if (
            instance_exists(_ctrl.or_surgeon)
            && _ctrl.or_surgeon.object_index != obj_player
            && instance_exists(_p_surg)
        ) {
            if (inpatient_actor_at_target(_ctrl.or_surgeon, _p_surg.x, _p_surg.y, 30)) {
                if (_ctrl.or_surgeon.doctor_state != "operating_at_point") {
                    inpatient_stop_actor(_ctrl.or_surgeon);
                    _ctrl.or_surgeon.doctor_state = "operating_at_point";
                }
            } else {
                inpatient_ensure_walk(_ctrl.or_surgeon, _p_surg.x, _p_surg.y);
                _ctrl.or_surgeon.doctor_state = "operating_going_to_point";
            }
        }

        if (
            instance_exists(_ctrl.or_anesthetist)
            && _ctrl.or_anesthetist.object_index != obj_player
            && instance_exists(_p_anest)
        ) {
            if (inpatient_actor_at_target(_ctrl.or_anesthetist, _p_anest.x, _p_anest.y, 30)) {
                if (_ctrl.or_anesthetist.doctor_state != "operating_at_point") {
                    inpatient_stop_actor(_ctrl.or_anesthetist);
                    _ctrl.or_anesthetist.doctor_state = "operating_at_point";
                }
            } else {
                inpatient_ensure_walk(_ctrl.or_anesthetist, _p_anest.x, _p_anest.y);
                _ctrl.or_anesthetist.doctor_state = "operating_going_to_point";
            }
        }

        if (
            instance_exists(_ctrl.or_assistant)
            && instance_exists(_p_assist)
        ) {
            if (inpatient_actor_at_target(_ctrl.or_assistant, _p_assist.x, _p_assist.y, 30)) {
                if (_ctrl.or_assistant.assistant_state != "operating_at_point") {
                    inpatient_stop_actor(_ctrl.or_assistant);
                    _ctrl.or_assistant.assistant_state = "operating_at_point";
                }
            } else {
                inpatient_ensure_walk(_ctrl.or_assistant, _p_assist.x, _p_assist.y);
                _ctrl.or_assistant.assistant_state = "operating_going_to_point";
            }
        }

        if (!global.time_paused) {
            _ctrl.or_timer -= max(1, global.time_speed);
        }

        if (_ctrl.or_timer <= 0) {
            _ctrl.or_phase = "finishing";
        }
    }
    // ── Фаза: завершение → восстановление ──
    else if (_ctrl.or_phase == "finishing") {
        operating_apply_result(_ctrl.or_pet, _ctrl.or_action_id);

        operating_notify(
            "ОПЕРАЦИЯ ЗАВЕРШЕНА",
            _ctrl.or_action_name + " — состояние пациента улучшено.",
            room_speed * 3
        );

        operating_start_recovery(_ctrl);
    }
    // ── Фаза: восстановление на койке операционной ──
    else if (_ctrl.or_phase == "recovery") {
        // Ассистент ухаживает у койки.
        var _asst_point = operating_find_point(obj_or_recovery_point_assistant);

        if (instance_exists(_ctrl.or_assistant) && instance_exists(_asst_point)) {
            if (inpatient_actor_at_target(_ctrl.or_assistant, _asst_point.x, _asst_point.y, 12)) {
                if (_ctrl.or_assistant.assistant_state != "operating_recovery_care") {
                    inpatient_stop_actor(_ctrl.or_assistant);
                    _ctrl.or_assistant.assistant_state = "operating_recovery_care";
                }
            } else {
                inpatient_ensure_walk(_ctrl.or_assistant, _asst_point.x, _asst_point.y);
            }
        }

        if (!instance_exists(_ctrl.or_pet)) {
            operating_clear_recovery(_ctrl);
            return;
        }

        var _cond = operating_pet_condition(_ctrl.or_pet);

        // Выздоровел на койке — возвращается к владельцу.
        if (_cond >= 100) {
            operating_pet_return_to_owner(_ctrl);
            operating_clear_recovery(_ctrl);
            return;
        }

        // Освободилась койка в стационаре — переводим.
        if (operating_try_transfer_to_inpatient(_ctrl)) {
            return;
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 13. ОТРИСОВКА ШКАЛЫ ОПЕРАЦИИ (мировые координаты, над столом)
// ═══════════════════════════════════════════════════════════════

function operating_controller_draw(_ctrl) {
    if (!instance_exists(_ctrl)) return;
    if (_ctrl.or_phase == "empty") return;
    if (_ctrl.or_phase == "finishing") return;
    if (!instance_exists(_ctrl.or_table)) return;

    if (font_exists(fnt_main)) draw_set_font(fnt_main);

    var _tx = _ctrl.or_table.x;
    var _ty = _ctrl.or_table.y - 84;

    var _label;

    switch (_ctrl.or_phase) {
        case "operating": _label = "ОПЕРАЦИЯ: "; break;
        case "recovery": _label = "ВОССТАНОВЛЕНИЕ: "; break;
        default: _label = "ОПЕРАЦИЯ: ";
    }

    // Тень подписи.
    draw_set_alpha(0.35);
    draw_set_color(c_black);
    draw_text(_tx + 2, _ty + 2, _label + _ctrl.or_action_name);
    draw_set_alpha(1);

    // Подпись.
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text(_tx, _ty, _label + _ctrl.or_action_name);

    // Шкала — только на этапе операции.
    if (_ctrl.or_phase == "operating") {
        var _bar_w = 220;
        var _bar_h = 16;
        var _bx = _tx - _bar_w * 0.5;
        var _by = _ty + 24;

        draw_set_color(make_color_rgb(74, 49, 31));
        draw_roundrect_ext(_bx - 2, _by - 2, _bx + _bar_w + 2, _by + _bar_h + 2, 7, 7, false);
        draw_set_color(make_color_rgb(242, 232, 214));
        draw_roundrect_ext(_bx, _by, _bx + _bar_w, _by + _bar_h, 5, 5, false);

        var _ratio = 1 - (_ctrl.or_timer / max(1, _ctrl.or_timer_max));
        _ratio = clamp(_ratio, 0, 1);
        var _fill_w = _bar_w * _ratio;

        if (_fill_w > 1) {
            draw_set_color(make_color_rgb(148, 74, 64));
            draw_roundrect_ext(_bx, _by, _bx + _fill_w, _by + _bar_h, 5, 5, false);
        }

        draw_set_color(make_color_rgb(58, 39, 24));
        draw_roundrect_ext(_bx, _by, _bx + _bar_w, _by + _bar_h, 5, 5, true);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
}
