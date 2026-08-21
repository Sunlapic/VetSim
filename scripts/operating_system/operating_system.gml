/// operating_system.gml
/// @description Операционная: подбор бригады, транспортировка пациента на
/// операционный стол, стулья ожидания бригады, шкала операции, койка
/// восстановления и перевод в стационар.
///
/// Пакет №111 (логика). Пакет №112: койка восстановления, ассистент ухаживает,
/// перевод в стационар при освобождении койки. Пакет №113: операция стартовала
/// сразу, без сбора бригады.
///
/// Пакет №161 (этот файл):
///   • Пациента ФИЗИЧЕСКИ переводят в операционную. Ассистент бригады подходит
///     к пациенту (фаза "escort"), затем животное идёт к obj_operating_point_pet
///     и забирается на obj_operating_table через штатные состояния par_animals
///     (going_to_exam_floor → jumping_to_table → in_exam), точно как в стационаре.
///   • Свободная бригада (operating_idle) сидит на стульях: новые точки
///     obj_operating_seat с or_seat_role = "surgeon"/"anesthetist"/"assistant".
///     Флаг or_seated читает End Step врача и ассистента и включает spr_human_FR_sit.
///   • Как только начинается операция — все встают со стульев и идут на свои
///     рабочие точки у стола (obj_operating_point_surgeon/anesthetist/assistant).
///   • Таймер операции стартует ТОЛЬКО когда пациент лежит на столе и вся
///     бригада стоит на своих точках. Есть страховочные таймауты от зависания.
///   • Владелец на время операции уходит в зал ожидания и освобождает
///     смотровой стол (полный сценарий «ушёл домой и вернулся забрать»
///     запланирован отдельным пакетом).


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

// Пакет №170: койка восстановления операционной больше не используется —
// пациент возвращается на свою койку стационара. Объекты
// obj_or_recovery_bed / obj_or_recovery_point_pet / obj_or_recovery_point_assistant
// можно удалить из проекта, в коде на них ссылок не осталось.

function operating_find_point(_obj) {
    return instance_exists(_obj) ? instance_find(_obj, 0) : noone;
}

// Пакет №161: точка «пациент лежит на операционном столе» — это уже
// существующая obj_operating_point_pet (та же схема, что у койки
// восстановления). Новых объектов не нужно.
function operating_find_pet_table_point() {
    return operating_find_point(obj_operating_point_pet);
}

// Пакет №161: точка подхода на полу рядом с операционным столом.
// Стол стоит в mp_grid как препятствие, поэтому путь строим не в саму
// точку укладки, а в ближайшую достижимую клетку возле неё; финальные
// пару шагов животное делает состоянием "jumping_to_table".
function operating_pet_floor_target(_pet, _table_point) {
    var _result = {
        px : _table_point.x,
        py : _table_point.y
    };

    if (!instance_exists(_pet)) return _result;
    if (!variable_instance_exists(_pet, "my_path")) return _result;

    // Сначала пробуем встать снизу от стола, затем по бокам и сверху.
    var _offsets = [
        [0, 56], [0, 72], [-40, 56], [40, 56],
        [-56, 16], [56, 16], [-56, -16], [56, -16],
        [0, -56], [-40, -56], [40, -56]
    ];

    for (var _i = 0; _i < array_length(_offsets); _i++) {
        var _cx = _table_point.x + _offsets[_i][0];
        var _cy = _table_point.y + _offsets[_i][1];

        if (mp_grid_path(
            global.ai_grid,
            _pet.my_path,
            _pet.x,
            _pet.y,
            _cx,
            _cy,
            true
        )) {
            _result.px = _cx;
            _result.py = _cy;
            return _result;
        }
    }

    return _result;
}

// Пакет №161: стул ожидания по роли.
// Пакет №162: если or_seat_role не проставлен в Creation Code (самая частая
// причина «персонал никуда не идёт»), стулья раздаются по порядку ролей,
// чтобы рассадка работала в любом случае.

function operating_role_seat_index(_role) {
    switch (string(_role)) {
        case "surgeon": return 0;
        case "anesthetist": return 1;
        case "assistant": return 2;
    }

    return -1;
}

function operating_find_seat(_role) {
    if (!instance_exists(obj_operating_seat)) return noone;

    var _role_str = string(_role);
    var _count = instance_number(obj_operating_seat);

    // 1. Точное совпадение роли.
    for (var _i = 0; _i < _count; _i++) {
        var _seat = instance_find(obj_operating_seat, _i);

        if (
            instance_exists(_seat)
            && variable_instance_exists(_seat, "or_seat_role")
            && string(_seat.or_seat_role) == _role_str
        ) {
            return _seat;
        }
    }

    var _idx = operating_role_seat_index(_role_str);
    if (_idx < 0) return noone;

    // 2. Стулья без роли — раздаём по порядку ролей.
    var _free_seats = [];

    for (var _j = 0; _j < _count; _j++) {
        var _s = instance_find(obj_operating_seat, _j);

        if (!instance_exists(_s)) continue;

        var _s_role = variable_instance_exists(_s, "or_seat_role")
            ? string(_s.or_seat_role)
            : "";

        if (_s_role == "") {
            array_push(_free_seats, _s);
        }
    }

    if (_idx < array_length(_free_seats)) {
        return _free_seats[_idx];
    }

    // 3. Крайний случай — любой стул по номеру роли.
    if (_idx < _count) {
        return instance_find(obj_operating_seat, _idx);
    }

    return noone;
}

// Пакет №162: надёжный проход к цели.
// inpatient_ensure_walk строит путь только когда сотрудник полностью
// остановлен — из-за этого персонал мог «замереть» и не пойти на стул.
// Здесь маршрут перестраивается при смене цели и раз в секунду.
function operating_walk_actor_to(_actor, _target_x, _target_y) {
    if (!instance_exists(_actor)) return false;

    if (!variable_instance_exists(_actor, "or_walk_goal_x")) {
        _actor.or_walk_goal_x = -99999;
        _actor.or_walk_goal_y = -99999;
        _actor.or_walk_repath = 0;
    }

    var _goal_changed = (
        abs(_actor.or_walk_goal_x - _target_x) > 2
        || abs(_actor.or_walk_goal_y - _target_y) > 2
    );

    var _path_active = (
        _actor.path_index != -1
        && _actor.path_position < 1
    );

    _actor.or_walk_repath -= 1;

    if (_goal_changed || !_path_active || _actor.or_walk_repath <= 0) {
        _actor.or_walk_goal_x = _target_x;
        _actor.or_walk_goal_y = _target_y;
        _actor.or_walk_repath = max(1, game_get_speed(gamespeed_fps));

        inpatient_walk_to(_actor, _target_x, _target_y);
    }

    return true;
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
        // 1. Свободный на стуле.
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

        // 2. Пакет №169: занят хозяйственным делом — бросает его и идёт
        //    на операцию. Товар из рук возвращается на склад, грязь
        //    освобождается для других.
        for (var _b = 0; _b < instance_number(obj_staff_assistant); _b++) {
            var _busy = instance_find(obj_staff_assistant, _b);

            if (!instance_exists(_busy)) continue;

            if (
                !variable_instance_exists(_busy, "workplace_id")
                || _busy.workplace_id != "operating"
            ) {
                continue;
            }

            if (
                !variable_instance_exists(_busy, "operating_role")
                || _busy.operating_role != "assistant"
            ) {
                continue;
            }

            if (operating_actor_skill_level(_busy, "assistant") < 3) continue;

            // Уже занят самой операционной — не трогаем.
            if (string_pos("operating_", string(_busy.assistant_state)) == 1) {
                continue;
            }

            operating_assistant_abort_chore(_busy);

            return _busy;
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
    _ctrl.or_owner = noone;
    _ctrl.or_action_id = "";
    _ctrl.or_action_name = "";
    _ctrl.or_surgeon = noone;
    _ctrl.or_anesthetist = noone;
    _ctrl.or_assistant = noone;
    _ctrl.or_timer = 0;
    _ctrl.or_timer_max = 0;
    _ctrl.or_seconds_planned = 0;
    _ctrl.or_surgeon_level = 1;
    _ctrl.or_anest_level = 1;
    _ctrl.or_assist_level = 1;
    _ctrl.or_table = noone;
    _ctrl.or_warned_room = false;
    _ctrl.or_warned_bed = false;

    // Пакет №161: страховочные таймеры фаз подготовки.
    _ctrl.or_escort_timer = 0;
    _ctrl.or_transfer_timer = 0;

    // Пакет №168: точка схода пациента с операционного стола.
    _ctrl.or_pet_floor_x = 0;
    _ctrl.or_pet_floor_y = 0;

    // Пакет №170: палата, из которой привезли пациента.
    _ctrl.or_ward = noone;
    _ctrl.or_return_timer = 0;
}


// ═══════════════════════════════════════════════════════════════
// 7.1 ПАКЕТ №161: ОБЩИЕ ХЕЛПЕРЫ ПО ПЕРСОНАЛУ
// ═══════════════════════════════════════════════════════════════

// Единое чтение состояния: у врача doctor_state, у ассистента assistant_state.
function operating_actor_state(_actor) {
    if (!instance_exists(_actor)) return "";

    if (variable_instance_exists(_actor, "doctor_state")) {
        return string(_actor.doctor_state);
    }

    if (variable_instance_exists(_actor, "assistant_state")) {
        return string(_actor.assistant_state);
    }

    return "";
}

function operating_actor_set_state(_actor, _state) {
    if (!instance_exists(_actor)) return false;

    if (variable_instance_exists(_actor, "doctor_state")) {
        _actor.doctor_state = _state;
        return true;
    }

    if (variable_instance_exists(_actor, "assistant_state")) {
        _actor.assistant_state = _state;
        return true;
    }

    return false;
}

// Флаг посадки на стул операционной (читает End Step врача и ассистента).
function operating_actor_seat_init(_actor) {
    if (!instance_exists(_actor)) return false;

    if (!variable_instance_exists(_actor, "or_seated")) {
        _actor.or_seated = false;
    }

    return true;
}

function operating_actor_stand_up(_actor) {
    if (!instance_exists(_actor)) return false;

    operating_actor_seat_init(_actor);
    _actor.or_seated = false;

    return true;
}

// Пакет №168: флаг «бригада реально оперирует».
// End Step врача и ассистента включает рабочую анимацию только по нему,
// иначе персонал махал руками ещё до того, как пациента привезли на стол.
function operating_actor_set_working(_actor, _on) {
    if (!instance_exists(_actor)) return false;

    _actor.or_working = _on;

    return true;
}

function operating_set_working(_ctrl, _on) {
    if (!instance_exists(_ctrl)) return;

    operating_actor_set_working(_ctrl.or_surgeon, _on);
    operating_actor_set_working(_ctrl.or_anesthetist, _on);
    operating_actor_set_working(_ctrl.or_assistant, _on);
}

// Пакет №168: гасим остаточную скорость пациента.
// move_towards_point (запасной путь, когда mp_grid не построил маршрут)
// задаёт speed НАВСЕГДА — par_animals его не обнуляет. Из-за этого животное
// дёргалось сидя на столе и «уезжало» с койки по комнате.
function operating_pet_stop_drift(_pet) {
    if (!instance_exists(_pet)) return false;

    with (_pet) {
        path_end();
        speed = 0;
        hspeed = 0;
        vspeed = 0;
        move_towards_point(x, y, 0);
        is_walking = false;
    }

    return true;
}

// Участник текущей операции?
function operating_is_brigade_member(_ctrl, _actor) {
    if (!instance_exists(_ctrl)) return false;
    if (!instance_exists(_actor)) return false;

    return (
        _actor == _ctrl.or_surgeon
        || _actor == _ctrl.or_anesthetist
        || _actor == _ctrl.or_assistant
    );
}

// Сотрудник может спокойно сидеть на стуле?
// Пакет №162: состояние "idle" у сотрудника операционной тоже принимается и
// сразу переводится в "operating_idle" (раньше рассадка молча пропускала его,
// если Begin Step ещё не успел переключить состояние), а усталость больше
// не мешает сесть — наоборот, на стуле сотрудник отдыхает.
function operating_actor_can_sit(_actor) {
    if (!instance_exists(_actor)) return false;
    if (_actor.object_index == obj_player) return false;

    if (
        !variable_instance_exists(_actor, "workplace_id")
        || _actor.workplace_id != "operating"
    ) {
        return false;
    }

    // Реальная работа важнее стула.
    if (
        variable_instance_exists(_actor, "assigned_pet")
        && instance_exists(_actor.assigned_pet)
    ) {
        return false;
    }

    var _state = operating_actor_state(_actor);

    if (_state == "idle") {
        operating_actor_set_state(_actor, "operating_idle");
        _state = "operating_idle";
    }

    return (_state == "operating_idle");
}


// ═══════════════════════════════════════════════════════════════
// 7.2 ПАКЕТ №161: СТУЛЬЯ ОЖИДАНИЯ
// Свободная бригада сидит; во время операции все встают и уходят к столу.
// ═══════════════════════════════════════════════════════════════

// Пакет №164: поиск достижимой точки посадки.
// Стул может стоять в клетке, закрытой в mp_grid (мебель, стена, край стола).
// Тогда путь не строится, inpatient_walk_to уходит на move_towards_point по
// прямой, сотрудника упирает в препятствие — и он «идёт на месте».
// Здесь заранее подбирается ближайшая КЛЕТКА, куда путь реально строится.
function operating_seat_reachable_target(_actor, _seat) {
    var _result = {
        px : _seat.x,
        py : _seat.y,
        ok : false
    };

    if (!instance_exists(_actor)) return _result;
    if (!instance_exists(_seat)) return _result;
    if (!variable_instance_exists(_actor, "my_path")) return _result;

    // Сам стул.
    if (mp_grid_path(
        global.ai_grid,
        _actor.my_path,
        _actor.x,
        _actor.y,
        _seat.x,
        _seat.y,
        true
    )) {
        _result.ok = true;
        return _result;
    }

    // Кольца вокруг стула: сначала вплотную, потом дальше.
    var _rings = [20, 32, 48, 64, 88];
    var _dirs = [
        [0, 1], [0, -1], [1, 0], [-1, 0],
        [1, 1], [1, -1], [-1, 1], [-1, -1]
    ];

    for (var _r = 0; _r < array_length(_rings); _r++) {
        for (var _d = 0; _d < array_length(_dirs); _d++) {
            var _cx = _seat.x + _dirs[_d][0] * _rings[_r];
            var _cy = _seat.y + _dirs[_d][1] * _rings[_r];

            if (mp_grid_path(
                global.ai_grid,
                _actor.my_path,
                _actor.x,
                _actor.y,
                _cx,
                _cy,
                true
            )) {
                _result.px = _cx;
                _result.py = _cy;
                _result.ok = true;
                return _result;
            }
        }
    }

    return _result;
}

function operating_seat_state_init(_actor) {
    if (!instance_exists(_actor)) return false;

    if (!variable_instance_exists(_actor, "or_seat_stuck_timer")) {
        _actor.or_seat_stuck_timer = 0;
        _actor.or_seat_last_x = _actor.x;
        _actor.or_seat_last_y = _actor.y;
        _actor.or_seat_attempts = 0;
        _actor.or_seat_unreachable = false;
        _actor.or_seat_retry_timer = 0;
    }

    return true;
}

function operating_seat_actor(_ctrl, _actor, _seat) {
    if (!instance_exists(_actor)) return false;

    operating_actor_seat_init(_actor);
    operating_seat_state_init(_actor);

    // Участник операции никогда не сидит.
    if (operating_is_brigade_member(_ctrl, _actor)) {
        _actor.or_seated = false;
        return false;
    }

    if (!operating_actor_can_sit(_actor)) {
        _actor.or_seated = false;
        return false;
    }

    // Стул не поставлен — сотрудник просто стоит, как раньше.
    if (!instance_exists(_seat)) {
        _actor.or_seated = false;
        return false;
    }

    var _fps = max(1, game_get_speed(gamespeed_fps));
    var _dist = point_distance(_actor.x, _actor.y, _seat.x, _seat.y);

    // ── Пакет №169: пока операций нет, ассистент занимается делами ──
    if (
        _actor.object_index == obj_staff_assistant
        && (!instance_exists(_ctrl) || _ctrl.or_phase == "empty")
    ) {
        if (!variable_instance_exists(_actor, "or_chore_timer")) {
            _actor.or_chore_timer = 0;
        }

        _actor.or_chore_timer -= 1;

        if (_actor.or_chore_timer <= 0) {
            _actor.or_chore_timer = max(1, game_get_speed(gamespeed_fps));

            if (operating_assistant_try_chore(_actor)) {
                return false;
            }
        }
    }

    // ── Дошёл: садимся ──
    if (_dist <= 24) {
        if (!_actor.or_seated) {
            inpatient_stop_actor(_actor);

            // Мягкая доводка до стула (не телепорт — максимум 24 пикселя).
            _actor.x = _seat.x;
            _actor.y = _seat.y;

            _actor.or_seated = true;
            _actor.or_seat_attempts = 0;
            _actor.or_seat_stuck_timer = 0;
            _actor.or_seat_unreachable = false;
        }

        return true;
    }

    _actor.or_seated = false;

    // ── Стул признан недостижимым: стоим спокойно, без «ходьбы на месте» ──
    if (_actor.or_seat_unreachable) {
        inpatient_stop_actor(_actor);

        _actor.or_seat_retry_timer -= 1;

        // Раз в 10 секунд пробуем снова: mp_grid могла обновиться
        // (открыли помещение, передвинули мебель).
        if (_actor.or_seat_retry_timer <= 0) {
            _actor.or_seat_unreachable = false;
            _actor.or_seat_attempts = 0;
            _actor.or_seat_stuck_timer = 0;
        }

        return false;
    }

    // ── Контроль реального движения ──
    var _moved = point_distance(
        _actor.x,
        _actor.y,
        _actor.or_seat_last_x,
        _actor.or_seat_last_y
    ) > 0.6;

    _actor.or_seat_last_x = _actor.x;
    _actor.or_seat_last_y = _actor.y;

    if (_moved) {
        _actor.or_seat_stuck_timer = 0;
    } else {
        _actor.or_seat_stuck_timer += 1;
    }

    // Полторы секунды без движения — маршрут перестраивается заново.
    if (_actor.or_seat_stuck_timer > _fps * 1.5) {
        _actor.or_seat_stuck_timer = 0;
        _actor.or_seat_attempts += 1;

        if (_actor.or_seat_attempts >= 4) {
            _actor.or_seat_unreachable = true;
            _actor.or_seat_retry_timer = _fps * 10;
            inpatient_stop_actor(_actor);
            return false;
        }

        var _retry = operating_seat_reachable_target(_actor, _seat);
        _actor.or_walk_goal_x = _retry.px;
        _actor.or_walk_goal_y = _retry.py;
        _actor.or_walk_repath = _fps;
        inpatient_walk_to(_actor, _retry.px, _retry.py);

        return false;
    }

    // ── Обычный ход: цель пересчитывается только при перестроении пути ──
    if (!variable_instance_exists(_actor, "or_walk_repath")) {
        _actor.or_walk_goal_x = -99999;
        _actor.or_walk_goal_y = -99999;
        _actor.or_walk_repath = 0;
    }

    var _path_active = (
        _actor.path_index != -1
        && _actor.path_position < 1
    );

    _actor.or_walk_repath -= 1;

    if (!_path_active || _actor.or_walk_repath <= 0) {
        var _target = operating_seat_reachable_target(_actor, _seat);

        _actor.or_walk_goal_x = _target.px;
        _actor.or_walk_goal_y = _target.py;
        _actor.or_walk_repath = _fps;

        inpatient_walk_to(_actor, _target.px, _target.py);
    }

    return false;
}

// Пакет №164: стулья раздаются одним проходом, чтобы двое не шли на один
// стул и чтобы сотрудник без роли всё равно получил свободное место.
// ═══════════════════════════════════════════════════════════════
// 7.3 ПАКЕТ №169: СВОБОДНЫЙ АССИСТЕНТ ОПЕРАЦИОННОЙ ЗАНЯТ ДЕЛОМ
// Пока операций нет — пополняет шкафы и убирает грязь, как обычный
// ассистент. Как только назначили операцию, дело бросается и он идёт
// к пациенту (operating_find_role_actor → operating_assistant_abort_chore).
// ═══════════════════════════════════════════════════════════════

// Ближайшая свободная грязь внутри клиники.
function operating_find_free_dirt(_asst) {
    if (!instance_exists(obj_floor_dirt)) return noone;

    var _best = noone;
    var _best_distance = 1000000;

    for (var _i = 0; _i < instance_number(obj_floor_dirt); _i++) {
        var _dirt = instance_find(obj_floor_dirt, _i);

        if (!instance_exists(_dirt)) continue;
        if (_dirt.targeted_by_player || _dirt.targeted_by_assistant) continue;
        if (_dirt.cleaning_active || _dirt.assistant_cleaning_active) continue;
        if (!cleanliness_position_inside_clinic(_dirt.x, _dirt.y)) continue;

        var _distance = point_distance(_asst.x, _asst.y, _dirt.x, _dirt.y);

        if (_distance < _best_distance) {
            _best_distance = _distance;
            _best = _dirt;
        }
    }

    return _best;
}

// Попытка взять хозяйственное дело. true — дело взято.
function operating_assistant_try_chore(_asst) {
    if (!instance_exists(_asst)) return false;
    if (_asst.object_index == obj_player) return false;

    if (
        variable_instance_exists(_asst, "is_tired") && _asst.is_tired
        || variable_instance_exists(_asst, "is_exhausted") && _asst.is_exhausted
    ) {
        return false;
    }

    // 1. Пополнение шкафов. Штатная функция требует состояние "idle",
    //    поэтому подставляем его на время вызова.
    var _previous_state = _asst.assistant_state;

    _asst.assistant_state = "idle";

    if (assistant_try_take_restock_job(_asst)) {
        _asst.or_seated = false;
        return true;
    }

    _asst.assistant_state = _previous_state;

    // 2. Уборка грязи.
    var _dirt = operating_find_free_dirt(_asst);

    if (instance_exists(_dirt)) {
        if (dirt_send_assistant_to(_dirt, _asst)) {
            _asst.or_seated = false;
            return true;
        }
    }

    return false;
}

// Бросить хозяйственное дело ради операции.
function operating_assistant_abort_chore(_asst) {
    if (!instance_exists(_asst)) return false;

    if (
        variable_instance_exists(_asst, "cleaning_target")
        && instance_exists(_asst.cleaning_target)
    ) {
        dirt_release_assistant(_asst.cleaning_target);
    }

    with (_asst) {
        if (variable_instance_exists(id, "assistant_reset_restock")) {
            assistant_reset_restock();
        }

        if (variable_instance_exists(id, "assistant_reset_procedure")) {
            assistant_reset_procedure();
        }
    }

    inpatient_stop_actor(_asst);

    _asst.assistant_state = "operating_idle";
    _asst.or_seated = false;

    return true;
}

function operating_seats_update(_ctrl) {
    var _staff = [];

    for (var _i = 0; _i < instance_number(obj_staff_doctor); _i++) {
        var _doc = instance_find(obj_staff_doctor, _i);
        if (instance_exists(_doc)) array_push(_staff, _doc);
    }

    for (var _j = 0; _j < instance_number(obj_staff_assistant); _j++) {
        var _asst = instance_find(obj_staff_assistant, _j);
        if (instance_exists(_asst)) array_push(_staff, _asst);
    }

    var _seat_count = instance_exists(obj_operating_seat)
        ? instance_number(obj_operating_seat)
        : 0;

    var _seats = [];
    var _taken = [];

    for (var _s = 0; _s < _seat_count; _s++) {
        array_push(_seats, instance_find(obj_operating_seat, _s));
        array_push(_taken, false);
    }

    // 1-й проход: точное совпадение роли.
    var _assigned = array_create(array_length(_staff), noone);

    for (var _a = 0; _a < array_length(_staff); _a++) {
        var _actor = _staff[_a];

        var _role = variable_instance_exists(_actor, "operating_role")
            ? string(_actor.operating_role)
            : "";

        if (_role == "") continue;

        for (var _b = 0; _b < array_length(_seats); _b++) {
            if (_taken[_b]) continue;

            var _seat_role = (
                instance_exists(_seats[_b])
                && variable_instance_exists(_seats[_b], "or_seat_role")
            ) ? string(_seats[_b].or_seat_role) : "";

            if (_seat_role == _role) {
                _assigned[_a] = _seats[_b];
                _taken[_b] = true;
                break;
            }
        }
    }

    // 2-й проход: оставшимся — любой свободный стул.
    for (var _a2 = 0; _a2 < array_length(_staff); _a2++) {
        if (instance_exists(_assigned[_a2])) continue;

        var _actor2 = _staff[_a2];

        if (
            !variable_instance_exists(_actor2, "workplace_id")
            || _actor2.workplace_id != "operating"
        ) {
            continue;
        }

        for (var _c = 0; _c < array_length(_seats); _c++) {
            if (_taken[_c]) continue;

            _assigned[_a2] = _seats[_c];
            _taken[_c] = true;
            break;
        }
    }

    // Рассадка.
    for (var _d = 0; _d < array_length(_staff); _d++) {
        operating_seat_actor(_ctrl, _staff[_d], _assigned[_d]);
    }
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

    if (!variable_instance_exists(_pet, "or_waiting_surgery")) {
        _pet.or_waiting_surgery = false;
        _pet.or_pending_action = "";
    }

    // Уже в очереди — просто обновляем назначенную операцию.
    if (_pet.or_waiting_surgery) {
        _pet.or_pending_action = string(_action_id);
        return true;
    }

    _pet.or_waiting_surgery = true;
    _pet.or_pending_action = string(_action_id);

    var _action_name = db_get_treatment_action_name(_action_id);

    // Пациент уже лежит в стационаре — ждёт своей очереди прямо там.
    var _ward = operating_get_ward(_pet);

    if (instance_exists(_ward)) {
        operating_notify(
            "НАЗНАЧЕНА ОПЕРАЦИЯ",
            _action_name + ": пациент ждёт на койке стационара.",
            room_speed * 4
        );
        return true;
    }

    // ── Пакет №170: терапевт отвозит пациента в стационар ──
    var _owner = (
        variable_instance_exists(_pet, "my_owner")
        && instance_exists(_pet.my_owner)
    ) ? _pet.my_owner : noone;

    var _escort_doctor = (
        variable_instance_exists(_pet, "assigned_doctor")
        && instance_exists(_pet.assigned_doctor)
    ) ? _pet.assigned_doctor : noone;

    if (!instance_exists(_owner)) {
        _pet.or_waiting_surgery = false;
        _pet.or_pending_action = "";

        operating_notify(
            "НЕТ ВЛАДЕЛЬЦА",
            "Пациента некому оформить в стационар.",
            room_speed * 3
        );
        return false;
    }

    if (!instance_exists(inpatient_find_free_ward())) {
        _pet.or_waiting_surgery = false;
        _pet.or_pending_action = "";

        operating_notify(
            "НЕТ МЕСТ В СТАЦИОНАРЕ",
            "Операция назначается только через койку. Освободите место.",
            room_speed * 4
        );
        return false;
    }

    if (!inpatient_start_admission(_owner, _pet, _escort_doctor)) {
        _pet.or_waiting_surgery = false;
        _pet.or_pending_action = "";

        operating_notify(
            "СТАЦИОНАР НЕ ПРИНЯЛ",
            "Проверьте койки стационара.",
            room_speed * 3
        );
        return false;
    }

    operating_notify(
        "НАПРАВЛЕН НА ОПЕРАЦИЮ",
        _action_name + ": терапевт отвозит пациента в стационар.",
        room_speed * 4
    );

    return true;
}

// ═══════════════════════════════════════════════════════════════
// 8.1 ПАКЕТ №161: ПЕРЕВОД ПАЦИЕНТА НА ОПЕРАЦИОННЫЙ СТОЛ
// ═══════════════════════════════════════════════════════════════

// Освобождаем смотровой стол и снимаем «занятость» персонала приёма.
function operating_release_exam_place(_ctrl) {
    if (!instance_exists(_ctrl)) return;
    if (!instance_exists(_ctrl.or_pet)) return;

    var _pet = _ctrl.or_pet;
    var _table = (
        variable_instance_exists(_pet, "assigned_table")
        && instance_exists(_pet.assigned_table)
    ) ? _pet.assigned_table : noone;

    // Врач приёма (в том числе игрок) отпускается.
    var _exam_doctor = (
        variable_instance_exists(_pet, "assigned_doctor")
        && instance_exists(_pet.assigned_doctor)
    ) ? _pet.assigned_doctor : noone;

    if (
        instance_exists(_exam_doctor)
        && !operating_is_brigade_member(_ctrl, _exam_doctor)
    ) {
        with (_exam_doctor) {
            assigned_owner = noone;
            assigned_table = noone;
            assigned_pet = noone;

            if (variable_instance_exists(id, "service_mode")) {
                service_mode = "";
            }

            if (
                variable_instance_exists(id, "doctor_state")
                && (
                    doctor_state == "examining"
                    || doctor_state == "waiting_positions"
                    || doctor_state == "going_to_doctor_point"
                    || doctor_state == "going_to_owner"
                )
            ) {
                path_end();
                speed = 0;
                is_walking = false;
                doctor_state = "idle";
            }
        }
    }

    if (
        instance_exists(_table)
        && _table != _ctrl.or_table
        && variable_instance_exists(_table, "table_busy")
    ) {
        _table.table_busy = false;
        _table.assigned_owner = noone;
        _table.assigned_doctor = noone;
        _table.assigned_pet = noone;
    }
}

// Владелец на время операции возвращается в зал ожидания.
function operating_owner_to_waiting(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    var _owner = _ctrl.or_owner;

    if (!instance_exists(_owner)) return;
    if (!variable_instance_exists(_owner, "state")) return;
    if (_owner.state == "leaving_clinic") return;

    _owner.assigned_doctor = noone;
    _owner.assigned_table = noone;

    var _spot_index = (
        variable_instance_exists(_owner, "wait_spot_index")
        && _owner.wait_spot_index >= 0
        && variable_global_exists("wait_spots")
        && _owner.wait_spot_index < array_length(global.wait_spots)
        && global.wait_spots[_owner.wait_spot_index].occupied_by == _owner
    ) ? _owner.wait_spot_index : reception_find_free_wait_spot();

    // Свободного кресла нет — владелец просто остаётся стоять.
    if (_spot_index < 0) {
        with (_owner) {
            path_end();
            speed = 0;
            is_walking = false;
            state = "waiting";
        }

        return;
    }

    global.wait_spots[_spot_index].occupied_by = _owner;

    with (_owner) {
        wait_spot_index = _spot_index;
        state = "going_to_waiting";

        var _spot = global.wait_spots[_spot_index];

        path_end();
        speed = 0;
        is_walking = false;

        if (mp_grid_path(
            global.ai_grid,
            my_path,
            x,
            y,
            _spot.x,
            _spot.y,
            true
        )) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
        } else {
            move_towards_point(_spot.x, _spot.y, p_move_speed);
            is_walking = true;
        }
    }
}

// Пациент отправляется своим ходом к операционному столу.
function operating_send_pet_to_table(_ctrl) {
    if (!instance_exists(_ctrl)) return false;
    if (!instance_exists(_ctrl.or_pet)) return false;

    var _table = operating_find_table();
    var _pet_table = operating_find_pet_table_point();

    if (!instance_exists(_table) || !instance_exists(_pet_table)) {
        return false;
    }

    var _pet_inst = _ctrl.or_pet;

    // Пакет №170: пациент приезжает с койки стационара, а не с приёма.
    // Койку НЕ освобождаем — она закреплена за ним на время операции.
    if (instance_exists(_ctrl.or_ward)) {
        var _ward_from = _ctrl.or_ward;

        inpatient_refresh_room_links(_ward_from);

        // Сходим с койки на пол палаты: клетка койки закрыта в mp_grid,
        // маршрут прямо с неё не строится.
        operating_pet_stop_drift(_pet_inst);

        if (instance_exists(_ward_from.pet_floor_point)) {
            if (
                point_distance(
                    _pet_inst.x,
                    _pet_inst.y,
                    _ward_from.pet_floor_point.x,
                    _ward_from.pet_floor_point.y
                ) <= 160
            ) {
                _pet_inst.x = _ward_from.pet_floor_point.x;
                _pet_inst.y = _ward_from.pet_floor_point.y;
            }
        }
    }
    else {
        // Запасной путь: пациента забирают прямо с приёмного стола.
        operating_release_exam_place(_ctrl);
        operating_owner_to_waiting(_ctrl);
    }

    // Достижимая точка подхода на полу рядом со столом.
    var _floor = operating_pet_floor_target(_pet_inst, _pet_table);

    // Пакет №168: запоминаем её — по ней пациент потом сойдёт со стола.
    _ctrl.or_pet_floor_x = _floor.px;
    _ctrl.or_pet_floor_y = _floor.py;

    with (_table) {
        table_busy = true;
        assigned_owner = noone;
        assigned_doctor = noone;
        assigned_pet = _pet_inst;
    }

    // Животное использует общие состояния par_animals — как в стационаре.
    with (_pet_inst) {
        assigned_table = _table;
        assigned_doctor = noone;

        exam_floor_x = _floor.px;
        exam_floor_y = _floor.py;
        exam_table_x = _pet_table.x;
        exam_table_y = _pet_table.y;

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

    return true;
}

// Пациент уже лежит на операционном столе?
function operating_pet_on_table(_ctrl) {
    if (!instance_exists(_ctrl)) return false;
    if (!instance_exists(_ctrl.or_pet)) return false;

    var _pet = _ctrl.or_pet;

    if (!variable_instance_exists(_pet, "state")) return false;

    return (
        _pet.state == "in_exam"
        && variable_instance_exists(_pet, "assigned_table")
        && _pet.assigned_table == operating_find_table()
    );
}

// Один член бригады идёт на свою точку у стола и встаёт на ней.
// Пакет №167: сотрудник встаёт РОВНО на свою точку.
//
// Раньше приход засчитывался с допуском 30 пикселей, причём
// inpatient_actor_at_target сверяется с ФАКТИЧЕСКОЙ целью маршрута, а она
// может отличаться от точки ещё на 24 пикселя: клетка самой точки закрыта
// в mp_grid (точки стоят вплотную к операционному столу), и inpatient_walk_to
// уводит маршрут на соседнюю свободную клетку. В сумме персонал замирал в
// полусотне пикселей от места — «стоят где-то рядом».
//
// Теперь маршрут строится через поиск достижимой клетки, а на финише
// сотрудник аккуратно доводится точно в координату точки.
function operating_move_member_to_point(_ctrl, _actor, _point) {
    if (!instance_exists(_actor)) return true;          // некого ждать
    if (_actor.object_index == obj_player) return true; // игроком управляет игрок
    if (!instance_exists(_point)) return true;          // точка не поставлена

    operating_actor_stand_up(_actor);

    if (!variable_instance_exists(_actor, "or_point_stuck_timer")) {
        _actor.or_point_stuck_timer = 0;
        _actor.or_point_last_x = _actor.x;
        _actor.or_point_last_y = _actor.y;
    }

    var _fps = max(1, game_get_speed(gamespeed_fps));
    var _dist = point_distance(_actor.x, _actor.y, _point.x, _point.y);

    // ── Финальная доводка ──
    if (_dist <= 28) {
        if (
            operating_actor_state(_actor) != "operating_at_point"
            || _dist > 0.5
        ) {
            inpatient_stop_actor(_actor);

            _actor.x = _point.x;
            _actor.y = _point.y;

            operating_actor_set_state(_actor, "operating_at_point");
            operating_face_table(_actor);
        }

        _actor.or_point_stuck_timer = 0;

        return true;
    }

    // ── Контроль движения: клетка точки может быть наглухо закрыта ──
    var _moved = point_distance(
        _actor.x,
        _actor.y,
        _actor.or_point_last_x,
        _actor.or_point_last_y
    ) > 0.6;

    _actor.or_point_last_x = _actor.x;
    _actor.or_point_last_y = _actor.y;

    if (_moved) {
        _actor.or_point_stuck_timer = 0;
    } else {
        _actor.or_point_stuck_timer += 1;
    }

    // Полторы секунды стоит на месте и уже почти дошёл — доводим силой,
    // иначе операция ждала бы бесконечно.
    if (_actor.or_point_stuck_timer > _fps * 1.5 && _dist <= 70) {
        inpatient_stop_actor(_actor);

        _actor.x = _point.x;
        _actor.y = _point.y;

        operating_actor_set_state(_actor, "operating_at_point");
        operating_face_table(_actor);

        _actor.or_point_stuck_timer = 0;

        return true;
    }

    // ── Обычный ход через достижимую клетку ──
    if (!variable_instance_exists(_actor, "or_walk_repath")) {
        _actor.or_walk_goal_x = -99999;
        _actor.or_walk_goal_y = -99999;
        _actor.or_walk_repath = 0;
    }

    var _path_active = (
        _actor.path_index != -1
        && _actor.path_position < 1
    );

    _actor.or_walk_repath -= 1;

    if (!_path_active || _actor.or_walk_repath <= 0) {
        var _target = operating_seat_reachable_target(_actor, _point);

        _actor.or_walk_goal_x = _target.px;
        _actor.or_walk_goal_y = _target.py;
        _actor.or_walk_repath = _fps;

        inpatient_walk_to(_actor, _target.px, _target.py);
    }

    operating_actor_set_state(_actor, "operating_going_to_point");

    return false;
}

// Пакет №169: разворот к столу ровно по формуле par_staff → End Step
// (раздел 4 «РАЗВОРОТ К СТОЛУ»). Свой упрощённый вариант из №167 давал
// хирургу спину: у спрайтов персонала знак разворота зависит ещё и от того,
// стоит человек выше или ниже мебели.
//
// Важно: par_staff применяет этот разворот только при живом assigned_table,
// а у бригады операционной его нет (иначе сторож зависаний выкинет её из
// операции). Поэтому разворот вызывается из End Step врача и ассистента.
function operating_face_work_table(_actor, _table) {
    if (!instance_exists(_actor)) return false;
    if (!instance_exists(_table)) return false;
    if (!variable_instance_exists(_actor, "pFacing")) return false;

    var _face_right = ((_table.x - _actor.x) > 0);

    if (_actor.y < _table.y) {
        _actor.pFacing = _face_right ? 1 : -1;
    } else {
        _actor.pFacing = _face_right ? -1 : 1;
    }

    return true;
}

// Развернуть сотрудника лицом к операционному столу.
function operating_face_table(_actor) {
    return operating_face_work_table(_actor, operating_find_table());
}

// Вся бригада стоит на местах?
function operating_brigade_in_place(_ctrl) {
    var _p_surg = operating_find_point(obj_operating_point_surgeon);
    var _p_anest = operating_find_point(obj_operating_point_anesthetist);
    var _p_assist = operating_find_point(obj_operating_point_assistant);

    var _ok_surg = operating_move_member_to_point(_ctrl, _ctrl.or_surgeon, _p_surg);
    var _ok_anest = operating_move_member_to_point(_ctrl, _ctrl.or_anesthetist, _p_anest);
    var _ok_assist = operating_move_member_to_point(_ctrl, _ctrl.or_assistant, _p_assist);

    return (_ok_surg && _ok_anest && _ok_assist);
}

// Старт шкалы операции.
function operating_begin_surgery(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    _ctrl.or_timer_max = _ctrl.or_seconds_planned * max(1, game_get_speed(gamespeed_fps));
    _ctrl.or_timer = _ctrl.or_timer_max;
    _ctrl.or_phase = "operating";

    // Пакет №168: только теперь бригада работает руками.
    operating_set_working(_ctrl, true);

    operating_notify(
        "ОПЕРАЦИЯ НАЧАТА",
        _ctrl.or_action_name + " — бригада приступила.",
        room_speed * 3
    );
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
// 10. ПЕРСОНАЛ: ВОЗВРАТ НА СТУЛ
// ═══════════════════════════════════════════════════════════════

// Пакет №161: после операции сотрудник не бежит к точке найма, а
// возвращается в operating_idle — стулья подхватывают его сами.
function operating_send_home(_actor, _kind) {
    if (!instance_exists(_actor)) return;
    if (_actor.object_index == obj_player) return;

    operating_actor_stand_up(_actor);
    operating_actor_set_working(_actor, false);
    inpatient_stop_actor(_actor);

    if (string(_kind) == "assistant") {
        _actor.assistant_state = "operating_idle";
    } else {
        _actor.doctor_state = "operating_idle";
    }
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
    _ctrl.or_owner = noone;
    _ctrl.or_action_id = "";
    _ctrl.or_action_name = "";
    _ctrl.or_surgeon = noone;
    _ctrl.or_anesthetist = noone;
    _ctrl.or_assistant = noone;
    _ctrl.or_timer = 0;
    _ctrl.or_timer_max = 0;
    _ctrl.or_seconds_planned = 0;
    _ctrl.or_escort_timer = 0;
    _ctrl.or_transfer_timer = 0;

    // Пакет №170.
    _ctrl.or_ward = noone;
    _ctrl.or_return_timer = 0;
}

// Освобождаем операционный стол.
function operating_table_free(_ctrl) {
    var _table = operating_find_table();

    if (
        instance_exists(_table)
        && variable_instance_exists(_table, "table_busy")
    ) {
        _table.table_busy = false;
        _table.assigned_owner = noone;
        _table.assigned_doctor = noone;
        _table.assigned_pet = noone;
    }
}

function operating_controller_abort(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    operating_table_free(_ctrl);
    operating_release_staff(_ctrl);
    operating_reset_fields(_ctrl);
}


// ═══════════════════════════════════════════════════════════════
// 11. ПАКЕТ №170: ПАЦИЕНТ ЖИВЁТ В СТАЦИОНАРЕ
// Операционная больше не имеет своей койки восстановления: пациента
// привозят с койки стационара и туда же возвращают. Койка всё это время
// закреплена за ним (ward.or_surgery_hold) и никому не отдаётся.
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

// Палата, где лежит пациент.
function operating_get_ward(_pet) {
    if (!instance_exists(_pet)) return noone;

    return inpatient_get_ward_for_pet(_pet);
}

function operating_ward_hold(_ward, _on) {
    if (!instance_exists(_ward)) return false;

    _ward.or_surgery_hold = _on;

    return true;
}

// Пациент ждёт операцию и лежит на койке?
function operating_pet_ready_for_surgery(_pet) {
    if (!instance_exists(_pet)) return false;

    if (
        !variable_instance_exists(_pet, "or_waiting_surgery")
        || !_pet.or_waiting_surgery
    ) {
        return false;
    }

    if (
        !variable_instance_exists(_pet, "or_pending_action")
        || string(_pet.or_pending_action) == ""
    ) {
        return false;
    }

    var _ward = operating_get_ward(_pet);

    if (!instance_exists(_ward)) return false;

    // Дожидаемся, пока пациента уложили на койку.
    return (
        variable_instance_exists(_pet, "state")
        && _pet.state == "in_exam"
    );
}

// Первый в очереди на операцию.
function operating_find_pending_pet() {
    if (!instance_exists(par_animals)) return noone;

    for (var _i = 0; _i < instance_number(par_animals); _i++) {
        var _pet = instance_find(par_animals, _i);

        if (!instance_exists(_pet)) continue;
        if (variable_instance_exists(_pet, "is_dead") && _pet.is_dead) continue;

        if (operating_pet_ready_for_surgery(_pet)) return _pet;
    }

    return noone;
}

// Операционная свободна — пробуем забрать пациента из стационара.
function operating_try_start_pending(_ctrl) {
    if (!instance_exists(_ctrl)) return false;
    if (_ctrl.or_phase != "empty") return false;

    var _pet = operating_find_pending_pet();

    if (!instance_exists(_pet)) return false;

    var _action_id = string(_pet.or_pending_action);

    // Комната собрана?
    var _table = operating_find_table();
    var _pet_point = operating_find_point(obj_operating_point_pet);

    if (!instance_exists(_table) || !instance_exists(_pet_point)) return false;

    // Бригада на месте? Проверка молчаливая — пациент просто ждёт на койке.
    var _surgeon = operating_find_role_actor("surgeon");
    if (!instance_exists(_surgeon)) return false;

    var _anest = operating_find_role_actor("anesthetist");
    if (!instance_exists(_anest)) return false;

    var _assist = operating_find_role_actor("assistant");
    if (!instance_exists(_assist)) return false;

    // Препараты.
    if (operating_missing_item(_action_id) != "") return false;

    operating_consume_items(_action_id);

    var _sl = operating_actor_skill_level(_surgeon, "surgeon");
    var _al = operating_actor_skill_level(_anest, "anesthetist");
    var _asl = operating_actor_skill_level(_assist, "assistant");

    _ctrl.or_pet = _pet;
    _ctrl.or_ward = operating_get_ward(_pet);
    _ctrl.or_owner = noone;
    _ctrl.or_action_id = _action_id;
    _ctrl.or_action_name = db_get_treatment_action_name(_action_id);
    _ctrl.or_surgeon = _surgeon;
    _ctrl.or_anesthetist = _anest;
    _ctrl.or_assistant = _assist;
    _ctrl.or_surgeon_level = _sl;
    _ctrl.or_anest_level = _al;
    _ctrl.or_assist_level = _asl;
    _ctrl.or_seconds_planned = operating_role_time(_sl)
        + operating_role_time(_al)
        + operating_role_time(_asl);
    _ctrl.or_timer = 0;
    _ctrl.or_timer_max = 0;
    _ctrl.or_table = _table;
    _ctrl.or_warned_room = false;

    // Койка держится за пациентом, пока он в операционной.
    operating_ward_hold(_ctrl.or_ward, true);

    operating_actor_stand_up(_surgeon);
    operating_actor_stand_up(_anest);
    operating_actor_stand_up(_assist);
    operating_set_working(_ctrl, false);

    if (_surgeon.object_index != obj_player) {
        _surgeon.doctor_state = "operating_going_to_point";
    }

    if (_anest.object_index != obj_player) {
        _anest.doctor_state = "operating_going_to_point";
    }

    _assist.assistant_state = "operating_escort";

    var _fps = max(1, game_get_speed(gamespeed_fps));

    _ctrl.or_phase = "escort";
    _ctrl.or_escort_timer = _fps * 20;
    _ctrl.or_transfer_timer = _fps * 40;
    _ctrl.or_return_timer = _fps * 40;

    operating_notify(
        "ЗАБИРАЮТ НА ОПЕРАЦИЮ",
        _ctrl.or_action_name + ": ассистент везёт пациента из стационара.",
        room_speed * 3
    );

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 11.1 ВОЗВРАТ ПАЦИЕНТА НА СВОЮ КОЙКУ
// ═══════════════════════════════════════════════════════════════

function operating_send_pet_back_to_ward(_ctrl) {
    if (!instance_exists(_ctrl)) return false;
    if (!instance_exists(_ctrl.or_pet)) return false;

    var _pet = _ctrl.or_pet;
    var _ward = _ctrl.or_ward;

    // Операционный стол свободен в любом случае.
    operating_table_free(_ctrl);

    if (!instance_exists(_ward)) return false;

    inpatient_refresh_room_links(_ward);

    if (
        !instance_exists(_ward.ward_table)
        || !instance_exists(_ward.pet_floor_point)
        || !instance_exists(_ward.pet_table_point)
    ) {
        return false;
    }

    // Сходим с операционного стола на пол.
    operating_pet_stop_drift(_pet);

    var _step_off_x = _ctrl.or_pet_floor_x;
    var _step_off_y = _ctrl.or_pet_floor_y;

    if (
        _step_off_x != 0
        && _step_off_y != 0
        && point_distance(_pet.x, _pet.y, _step_off_x, _step_off_y) <= 140
    ) {
        _pet.x = _step_off_x;
        _pet.y = _step_off_y;
    }

    _pet.or_post_surgery = true;
    _pet.or_waiting_surgery = false;
    _pet.or_pending_action = "";

    with (_pet) {
        assigned_table = _ward.ward_table;
        assigned_doctor = noone;

        exam_floor_x = _ward.pet_floor_point.x;
        exam_floor_y = _ward.pet_floor_point.y;
        exam_table_x = _ward.pet_table_point.x;
        exam_table_y = _ward.pet_table_point.y;

        state = "going_to_exam_floor";

        path_end();
        speed = 0;
        hspeed = 0;
        vspeed = 0;
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

    // Ассистент провожает пациента до койки.
    if (
        instance_exists(_ctrl.or_assistant)
        && _ctrl.or_assistant.object_index != obj_player
    ) {
        operating_actor_stand_up(_ctrl.or_assistant);
        operating_actor_set_working(_ctrl.or_assistant, false);
        _ctrl.or_assistant.assistant_state = "operating_escort";
        operating_walk_actor_to(
            _ctrl.or_assistant,
            _ward.pet_floor_point.x,
            _ward.pet_floor_point.y
        );
    }

    // Врачи свободны сразу.
    operating_send_home(_ctrl.or_surgeon, "doctor");
    operating_send_home(_ctrl.or_anesthetist, "doctor");

    return true;
}

// Пациент снова на своей койке — палата просыпается.
function operating_finish_return(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    operating_ward_hold(_ctrl.or_ward, false);
    operating_send_home(_ctrl.or_assistant, "assistant");
    operating_table_free(_ctrl);

    operating_notify(
        "ПАЦИЕНТ В СТАЦИОНАРЕ",
        "Послеоперационный уход продолжает палата.",
        room_speed * 3
    );

    operating_reset_fields(_ctrl);
}


// ═══════════════════════════════════════════════════════════════
// 12. КОНТРОЛЛЕР: ОСНОВНОЙ ШАГ
// Пакет №170: цепочка фаз
// empty → escort → transfer → operating → finishing → returning → empty
// ═══════════════════════════════════════════════════════════════

function operating_controller_step(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    if (!variable_instance_exists(_ctrl, "or_ward")) _ctrl.or_ward = noone;
    if (!variable_instance_exists(_ctrl, "or_return_timer")) _ctrl.or_return_timer = 0;

    // Стулья и хозяйственные дела бригады работают всегда.
    operating_seats_update(_ctrl);

    // ── Свободно: забираем следующего пациента из стационара ──
    if (_ctrl.or_phase == "empty") {
        operating_try_start_pending(_ctrl);
        return;
    }

    // Пациент исчез — сворачиваемся.
    if (!instance_exists(_ctrl.or_pet)) {
        operating_ward_hold(_ctrl.or_ward, false);
        operating_controller_abort(_ctrl);
        return;
    }

    var _table = operating_find_table();

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

    // ── Фаза: ассистент идёт за пациентом в стационар ──
    if (_ctrl.or_phase == "escort") {
        _ctrl.or_escort_timer -= 1;

        operating_set_working(_ctrl, false);
        operating_brigade_in_place(_ctrl);

        var _asst = _ctrl.or_assistant;
        var _pet_inst = _ctrl.or_pet;

        var _reach_x = (
            variable_instance_exists(_pet_inst, "exam_floor_x")
            && _pet_inst.exam_floor_x != 0
        ) ? _pet_inst.exam_floor_x : _pet_inst.x;

        var _reach_y = (
            variable_instance_exists(_pet_inst, "exam_floor_y")
            && _pet_inst.exam_floor_y != 0
        ) ? _pet_inst.exam_floor_y : _pet_inst.y;

        var _escort_ready = false;

        if (!instance_exists(_asst) || _asst.object_index == obj_player) {
            _escort_ready = true;
        }
        else {
            operating_actor_stand_up(_asst);

            if (inpatient_actor_at_target(_asst, _reach_x, _reach_y, 56)) {
                _escort_ready = true;
            } else {
                operating_walk_actor_to(_asst, _reach_x, _reach_y);
                _asst.assistant_state = "operating_escort";
            }
        }

        if (_ctrl.or_escort_timer <= 0) _escort_ready = true;

        if (_escort_ready) {
            if (operating_send_pet_to_table(_ctrl)) {
                _ctrl.or_phase = "transfer";
            } else {
                operating_notify(
                    "ОПЕРАЦИОННАЯ НЕ ГОТОВА",
                    "Нет obj_operating_table или obj_operating_point_pet.",
                    room_speed * 3
                );

                operating_ward_hold(_ctrl.or_ward, false);
                operating_controller_abort(_ctrl);
            }
        }

        return;
    }

    // ── Фаза: пациент едет на стол, бригада занимает места ──
    if (_ctrl.or_phase == "transfer") {
        _ctrl.or_transfer_timer -= 1;

        operating_set_working(_ctrl, false);

        var _brigade_ok = operating_brigade_in_place(_ctrl);
        var _pet_ok = operating_pet_on_table(_ctrl);

        if (_pet_ok) operating_pet_stop_drift(_ctrl.or_pet);

        if ((_brigade_ok && _pet_ok) || _ctrl.or_transfer_timer <= 0) {
            operating_begin_surgery(_ctrl);
        }

        return;
    }

    // ── Фаза: операция ──
    if (_ctrl.or_phase == "operating") {
        operating_brigade_in_place(_ctrl);
        operating_set_working(_ctrl, true);
        operating_pet_stop_drift(_ctrl.or_pet);

        if (!global.time_paused) {
            _ctrl.or_timer -= max(1, global.time_speed);
        }

        if (_ctrl.or_timer <= 0) {
            _ctrl.or_phase = "finishing";
        }

        return;
    }

    // ── Фаза: завершение → пациента везут обратно на койку ──
    if (_ctrl.or_phase == "finishing") {
        operating_apply_result(_ctrl.or_pet, _ctrl.or_action_id);
        operating_set_working(_ctrl, false);

        operating_notify(
            "ОПЕРАЦИЯ ЗАВЕРШЕНА",
            _ctrl.or_action_name + " — пациента везут в стационар.",
            room_speed * 3
        );

        if (operating_send_pet_back_to_ward(_ctrl)) {
            _ctrl.or_phase = "returning";
            _ctrl.or_return_timer = max(1, game_get_speed(gamespeed_fps)) * 40;
        } else {
            operating_ward_hold(_ctrl.or_ward, false);
            operating_release_staff(_ctrl);
            operating_table_free(_ctrl);
            operating_reset_fields(_ctrl);
        }

        return;
    }

    // ── Фаза: пациент возвращается на свою койку ──
    if (_ctrl.or_phase == "returning") {
        _ctrl.or_return_timer -= 1;

        var _ward_back = _ctrl.or_ward;
        var _back_ok = false;

        if (
            instance_exists(_ward_back)
            && instance_exists(_ward_back.ward_table)
            && variable_instance_exists(_ctrl.or_pet, "state")
            && _ctrl.or_pet.state == "in_exam"
            && _ctrl.or_pet.assigned_table == _ward_back.ward_table
        ) {
            operating_pet_stop_drift(_ctrl.or_pet);
            _back_ok = true;
        }

        if (
            instance_exists(_ctrl.or_assistant)
            && _ctrl.or_assistant.object_index != obj_player
            && instance_exists(_ward_back)
            && instance_exists(_ward_back.pet_floor_point)
            && !_back_ok
        ) {
            operating_walk_actor_to(
                _ctrl.or_assistant,
                _ward_back.pet_floor_point.x,
                _ward_back.pet_floor_point.y
            );
        }

        if (_back_ok || _ctrl.or_return_timer <= 0) {
            operating_finish_return(_ctrl);
        }

        return;
    }
}


// ═══════════════════════════════════════════════════════════════
// 12.1 ПАКЕТ №165: ОТЛАДОЧНЫЕ КЛАВИШИ ОПЕРАЦИОННОЙ
// Работают только при global.vetsim_debug_mode = true.
//
//   O — тестовая операция на ближайшем к игроку пациенте:
//       при необходимости пациенту выдаётся случай, на склад
//       докладываются недостающие препараты, операция стартует сразу.
//   P — промотать текущую фазу:
//       подготовка → сразу операция, операция → сразу завершение,
//       восстановление → пациент выздоровел.
// ═══════════════════════════════════════════════════════════════

function operating_debug_enabled() {
    return (
        variable_global_exists("vetsim_debug_mode")
        && global.vetsim_debug_mode
    );
}

// Все хирургические действия из медбазы.
function operating_debug_surgery_actions() {
    var _list = [];

    if (!variable_global_exists("med_db")) return _list;
    if (!is_struct(global.med_db)) return _list;
    if (!variable_struct_exists(global.med_db, "treatment_action_ids")) return _list;

    var _ids = global.med_db.treatment_action_ids;

    for (var _i = 0; _i < array_length(_ids); _i++) {
        if (operating_action_is_surgery(_ids[_i])) {
            array_push(_list, _ids[_i]);
        }
    }

    return _list;
}

// Ближайший к игроку пациент (в приоритете — тот, что уже лежит на столе).
function operating_debug_find_pet() {
    if (!instance_exists(par_animals)) return noone;

    var _from_x = 0;
    var _from_y = 0;

    if (instance_exists(obj_player)) {
        var _pl = instance_find(obj_player, 0);
        _from_x = _pl.x;
        _from_y = _pl.y;
    } else {
        var _tbl = operating_find_table();

        if (instance_exists(_tbl)) {
            _from_x = _tbl.x;
            _from_y = _tbl.y;
        }
    }

    var _best = noone;
    var _best_score = 999999999;

    for (var _i = 0; _i < instance_number(par_animals); _i++) {
        var _pet = instance_find(par_animals, _i);

        if (!instance_exists(_pet)) continue;

        if (variable_instance_exists(_pet, "is_dead") && _pet.is_dead) continue;

        // Уже оперируется — пропускаем.
        if (
            variable_instance_exists(_pet, "or_post_surgery")
            && _pet.or_post_surgery
        ) {
            continue;
        }

        var _score = point_distance(_from_x, _from_y, _pet.x, _pet.y);

        // Пациент на смотровом столе интереснее всего для теста.
        if (
            variable_instance_exists(_pet, "state")
            && _pet.state == "in_exam"
        ) {
            _score -= 100000;
        }

        if (_score < _best_score) {
            _best_score = _score;
            _best = _pet;
        }
    }

    return _best;
}

// Докладываем на основной склад всё, чего не хватает для операции.
function operating_debug_grant_items(_action_id) {
    var _items = operating_required_items(_action_id);

    for (var _i = 0; _i < array_length(_items); _i++) {
        var _req = _items[_i];

        var _have = inventory_get_amount(global.inventory_main, _req.item_id);

        if (_have < _req.amount) {
            inventory_add_amount(
                global.inventory_main,
                _req.item_id,
                _req.amount - _have + 4
            );
        }
    }
}

function operating_debug_force_surgery() {
    if (!operating_debug_enabled()) return false;

    var _ctrl = instance_exists(obj_operating_controller)
        ? instance_find(obj_operating_controller, 0)
        : noone;

    if (!instance_exists(_ctrl)) return false;

    if (_ctrl.or_phase != "empty") {
        operating_notify(
            "DEBUG",
            "Операционная занята — сначала P (промотать фазу).",
            room_speed * 3
        );
        return false;
    }

    var _pet = operating_debug_find_pet();

    if (!instance_exists(_pet)) {
        operating_notify(
            "DEBUG",
            "В клинике нет ни одного пациента.",
            room_speed * 3
        );
        return false;
    }

    var _actions = operating_debug_surgery_actions();

    if (array_length(_actions) <= 0) {
        operating_notify(
            "DEBUG",
            "В медбазе нет действий с is_surgery.",
            room_speed * 3
        );
        return false;
    }

    var _action_id = _actions[irandom(array_length(_actions) - 1)];

    // Случай нужен, чтобы работали состояние пациента и восстановление.
    if (
        !variable_instance_exists(_pet, "current_case")
        || !is_struct(_pet.current_case)
    ) {
        var _species = variable_instance_exists(_pet, "species_id")
            ? _pet.species_id
            : "dog";

        var _new_case = case_create_random_for_species(_species);

        if (is_struct(_new_case)) {
            animal_apply_case(_pet, _new_case);
        }
    }

    // Состояние 45% — пациент тяжёлый, значит после операции пойдёт
    // сценарий восстановления и перевода в стационар.
    if (
        variable_instance_exists(_pet, "current_case")
        && is_struct(_pet.current_case)
    ) {
        var _case = _pet.current_case;
        _case.condition = 45;
        _pet.current_case = _case;
        _pet.condition = 45;
    }

    operating_debug_grant_items(_action_id);

    var _started = operating_request(_pet, _action_id);

    if (_started) {
        operating_notify(
            "DEBUG: ТЕСТ-ОПЕРАЦИЯ",
            db_get_treatment_action_name(_action_id),
            room_speed * 3
        );
    }

    return _started;
}

function operating_debug_skip_phase(_ctrl) {
    if (!operating_debug_enabled()) return false;
    if (!instance_exists(_ctrl)) return false;

    switch (_ctrl.or_phase) {
        case "empty":
            operating_notify("DEBUG", "Операционная пуста. O — тест-операция.", room_speed * 2);
        break;

        case "escort":
        case "transfer":
            // Ставим пациента на стол и бригаду по местам мгновенно.
            if (_ctrl.or_phase == "escort") {
                operating_send_pet_to_table(_ctrl);
            }

            var _pet_table = operating_find_pet_table_point();

            if (instance_exists(_ctrl.or_pet) && instance_exists(_pet_table)) {
                with (_ctrl.or_pet) {
                    path_end();
                    speed = 0;
                    is_walking = false;
                    x = _pet_table.x;
                    y = _pet_table.y;
                    state = "in_exam";
                }
            }

            operating_debug_place_member(_ctrl.or_surgeon, obj_operating_point_surgeon);
            operating_debug_place_member(_ctrl.or_anesthetist, obj_operating_point_anesthetist);
            operating_debug_place_member(_ctrl.or_assistant, obj_operating_point_assistant);

            operating_begin_surgery(_ctrl);
        break;

        case "operating":
            _ctrl.or_timer = 0;
            operating_notify("DEBUG", "Операция промотана до конца.", room_speed * 2);
        break;

        // Пакет №170: пациент возвращается на свою койку стационара.
        case "finishing":
        case "returning":
            if (
                instance_exists(_ctrl.or_pet)
                && instance_exists(_ctrl.or_ward)
                && instance_exists(_ctrl.or_ward.pet_table_point)
            ) {
                var _ward_point = _ctrl.or_ward.pet_table_point;

                with (_ctrl.or_pet) {
                    path_end();
                    speed = 0;
                    hspeed = 0;
                    vspeed = 0;
                    is_walking = false;
                    x = _ward_point.x;
                    y = _ward_point.y;
                    state = "in_exam";
                }
            }

            operating_finish_return(_ctrl);

            operating_notify("DEBUG", "Пациент возвращён в стационар.", room_speed * 2);
        break;
    }

    return true;
}

// Мгновенная расстановка члена бригады по своей точке (только debug).
function operating_debug_place_member(_actor, _point_obj) {
    if (!instance_exists(_actor)) return false;
    if (_actor.object_index == obj_player) return false;

    var _point = operating_find_point(_point_obj);

    if (!instance_exists(_point)) return false;

    operating_actor_stand_up(_actor);
    inpatient_stop_actor(_actor);

    _actor.x = _point.x;
    _actor.y = _point.y;

    operating_actor_set_state(_actor, "operating_at_point");
    operating_face_table(_actor);

    return true;
}

function operating_debug_keys(_ctrl) {
    if (!operating_debug_enabled()) return;

    if (keyboard_check_pressed(ord("O"))) {
        operating_debug_force_surgery();
    }

    if (keyboard_check_pressed(ord("P"))) {
        operating_debug_skip_phase(_ctrl);
    }
}


// ═══════════════════════════════════════════════════════════════
// 13. ОТРИСОВКА
// ═══════════════════════════════════════════════════════════════

// Пакет №162: диагностика операционной прямо в комнате.
// Показывается только при global.vetsim_debug_mode = true
// (obj_Render → Create). Перед релизом просто выключается там же.
function operating_debug_draw(_ctrl) {
    if (!variable_global_exists("vetsim_debug_mode")) return;
    if (!global.vetsim_debug_mode) return;
    if (!instance_exists(_ctrl)) return;

    var _table = operating_find_table();
    var _dx = instance_exists(_table) ? _table.x + 200 : _ctrl.x;
    var _dy = instance_exists(_table) ? _table.y - 300 : _ctrl.y;

    if (font_exists(fnt_main_smaill)) draw_set_font(fnt_main_smaill);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var _lines = [];

    array_push(
        _lines,
        "ОПЕРАЦИОННАЯ: фаза " + string(_ctrl.or_phase)
    );

    // Пакет №165: подсказка по отладочным клавишам.
    array_push(
        _lines,
        "DEBUG: O — тест-операция на ближайшем пациенте, P — промотать фазу"
    );

    // ── Стулья ──
    var _seat_count = instance_exists(obj_operating_seat)
        ? instance_number(obj_operating_seat)
        : 0;

    var _seat_line = "СТУЛЬЯ (obj_operating_seat): " + string(_seat_count);

    for (var _i = 0; _i < _seat_count; _i++) {
        var _seat = instance_find(obj_operating_seat, _i);

        var _seat_role = (
            instance_exists(_seat)
            && variable_instance_exists(_seat, "or_seat_role")
        ) ? string(_seat.or_seat_role) : "НЕТ ПЕРЕМЕННОЙ";

        if (_seat_role == "") _seat_role = "ПУСТО";

        _seat_line += "  [" + string(_i) + "]=" + _seat_role;
    }

    array_push(_lines, _seat_line);

    // ── Персонал операционной ──
    var _staff_found = 0;

    for (var _d = 0; _d < instance_number(obj_staff_doctor); _d++) {
        var _doc = instance_find(obj_staff_doctor, _d);

        if (!instance_exists(_doc)) continue;
        if (!variable_instance_exists(_doc, "workplace_id")) continue;
        if (_doc.workplace_id != "operating") continue;

        _staff_found += 1;
        array_push(_lines, operating_debug_actor_line(_doc));
    }

    for (var _a = 0; _a < instance_number(obj_staff_assistant); _a++) {
        var _asst = instance_find(obj_staff_assistant, _a);

        if (!instance_exists(_asst)) continue;
        if (!variable_instance_exists(_asst, "workplace_id")) continue;
        if (_asst.workplace_id != "operating") continue;

        _staff_found += 1;
        array_push(_lines, operating_debug_actor_line(_asst));
    }

    if (_staff_found == 0) {
        array_push(
            _lines,
            "НЕТ ПЕРСОНАЛА С workplace_id = operating"
        );
    }

    // ── Подложка ──
    var _line_h = 26;
    var _w = 720;
    var _h = array_length(_lines) * _line_h + 16;

    draw_set_alpha(0.75);
    draw_set_color(c_black);
    draw_roundrect_ext(_dx - 8, _dy - 8, _dx + _w, _dy + _h, 8, 8, false);
    draw_set_alpha(1);

    draw_set_color(make_color_rgb(120, 255, 140));

    for (var _l = 0; _l < array_length(_lines); _l++) {
        draw_text(_dx, _dy + _l * _line_h, _lines[_l]);
    }

    draw_set_color(c_white);
    draw_set_alpha(1);

    if (font_exists(fnt_main)) draw_set_font(fnt_main);
}

function operating_debug_actor_line(_actor) {
    var _name = variable_instance_exists(_actor, "char_name")
        ? string(_actor.char_name)
        : "сотрудник";

    var _role = variable_instance_exists(_actor, "operating_role")
        ? string(_actor.operating_role)
        : "НЕТ";

    if (_role == "") _role = "ПУСТО";

    var _state = operating_actor_state(_actor);

    var _seated = (
        variable_instance_exists(_actor, "or_seated")
        && _actor.or_seated
    ) ? "да" : "нет";

    var _seat = operating_find_seat(_role);

    var _seat_info = instance_exists(_seat)
        ? ("стул " + string(round(point_distance(_actor.x, _actor.y, _seat.x, _seat.y))) + "px")
        : "СТУЛ НЕ НАЙДЕН";

    // Пакет №164: видно, идёт ли человек на самом деле.
    var _path_active = (
        _actor.path_index != -1
        && _actor.path_position < 1
    );

    var _move_info = _path_active ? "путь: есть" : "путь: НЕТ";

    if (
        variable_instance_exists(_actor, "or_seat_unreachable")
        && _actor.or_seat_unreachable
    ) {
        _move_info = "СТУЛ НЕДОСТИЖИМ (mp_grid)";
    }
    else if (
        variable_instance_exists(_actor, "or_seat_stuck_timer")
        && _actor.or_seat_stuck_timer > 0
    ) {
        _move_info += " | стоит " + string(_actor.or_seat_stuck_timer) + "к";
    }

    return (
        _name
        + " | роль: " + _role
        + " | " + _state
        + " | сидит: " + _seated
        + " | " + _seat_info
        + " | " + _move_info
    );
}


// ═══════════════════════════════════════════════════════════════
// 13.1 ШКАЛА ОПЕРАЦИИ (мировые координаты, над столом)
// ═══════════════════════════════════════════════════════════════

// Пакет №170: деревянная табличка в стиле приёма.
function operating_draw_plaque(_cx, _cy, _label, _has_bar, _ratio) {
    if (string(_label) == "") return;

    var _wood_dark = make_color_rgb(74, 49, 31);
    var _wood_light = make_color_rgb(150, 107, 73);
    var _paper = make_color_rgb(242, 232, 214);
    var _line_dark = make_color_rgb(58, 39, 24);
    var _text_dark = make_color_rgb(50, 38, 28);
    var _bar_bg = make_color_rgb(200, 184, 160);
    var _bar_color = make_color_rgb(148, 74, 64);

    var _pad_x = 12;
    var _pad_y = 6;
    var _bar_h = 6;
    var _bar_gap = 5;

    if (font_exists(fnt_main)) draw_set_font(fnt_main);

    var _text_w = string_width(_label);
    var _text_h = string_height(_label);

    var _tw = max(_text_w + _pad_x * 2 + 8, 140);
    var _th = _text_h + _pad_y * 2 + 4;

    if (_has_bar) _th += _bar_gap + _bar_h;

    var _bx1 = _cx - (_tw * 0.5);
    var _by1 = _cy;
    var _bx2 = _bx1 + _tw;
    var _by2 = _by1 + _th;

    var _in_x1 = _bx1 + 5;
    var _in_y1 = _by1 + 5;
    var _in_x2 = _bx2 - 5;
    var _in_y2 = _by2 - 5;

    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(_bx1 + 2, _by1 + 3, _bx2 + 2, _by2 + 3, 8, 8, false);
    draw_set_alpha(1);

    draw_set_color(_wood_dark);
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, false);
    draw_set_color(_wood_light);
    draw_roundrect_ext(_bx1 + 2, _by1 + 2, _bx2 - 2, _by2 - 2, 6, 6, false);

    draw_set_color(_paper);
    draw_roundrect_ext(_in_x1, _in_y1, _in_x2, _in_y2, 5, 5, false);

    draw_set_color(_line_dark);
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, true);

    draw_set_color(_text_dark);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text((_bx1 + _bx2) * 0.5, _by1 + _pad_y + 1, _label);

    if (_has_bar) {
        var _bar_x1 = _in_x1 + 6;
        var _bar_x2 = _in_x2 - 6;
        var _bar_y1 = _by1 + _pad_y + _text_h + _bar_gap;
        var _bar_y2 = _bar_y1 + _bar_h;

        draw_set_color(_bar_bg);
        draw_roundrect_ext(_bar_x1, _bar_y1, _bar_x2, _bar_y2, 2, 2, false);

        if (_ratio > 0.02) {
            draw_set_color(_bar_color);
            draw_roundrect_ext(
                _bar_x1,
                _bar_y1,
                _bar_x1 + (_bar_x2 - _bar_x1) * clamp(_ratio, 0, 1),
                _bar_y2,
                2,
                2,
                false
            );
        }

        draw_set_color(_line_dark);
        draw_roundrect_ext(_bar_x1, _bar_y1, _bar_x2, _bar_y2, 2, 2, true);
    }

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// Пакет №170: таблички «ЖДЁТ ОПЕРАЦИЮ» над пациентом и «НА ОПЕРАЦИИ»
// над закреплённой за ним койкой стационара.
function operating_draw_ward_labels(_ctrl) {
    if (!instance_exists(obj_inpatient_controller)) return;

    for (var _i = 0; _i < instance_number(obj_inpatient_controller); _i++) {
        var _ward = instance_find(obj_inpatient_controller, _i);

        if (!instance_exists(_ward)) continue;

        var _hold = (
            variable_instance_exists(_ward, "or_surgery_hold")
            && _ward.or_surgery_hold
        );

        // Койка занята пациентом, который сейчас в операционной.
        if (_hold) {
            if (instance_exists(_ward.ward_table)) {
                operating_draw_plaque(
                    _ward.ward_table.x,
                    _ward.ward_table.y - 150,
                    "НА ОПЕРАЦИИ",
                    false,
                    0
                );
            }

            continue;
        }

        // Пациент лежит и ждёт своей очереди.
        var _patient = _ward.patient;

        if (!instance_exists(_patient)) continue;

        if (
            variable_instance_exists(_patient, "or_waiting_surgery")
            && _patient.or_waiting_surgery
        ) {
            operating_draw_plaque(
                _patient.x,
                _patient.y - 150,
                "ЖДЁТ ОПЕРАЦИЮ",
                false,
                0
            );
        }
    }
}

function operating_controller_draw(_ctrl) {
    if (!instance_exists(_ctrl)) return;

    operating_debug_draw(_ctrl);
    operating_draw_ward_labels(_ctrl);

    // Пакет №169: одна табличка со шкалой в стиле приёма
    // (actor_draw_action_progress), и только во время самой операции.
    //
    // Раньше рисовались ДВЕ подписи: «тень» текста печаталась при
    // halign = fa_left, а основной текст — уже при fa_center, поэтому копия
    // уезжала вбок и читалась как вторая надпись. Плюс отдельные подписи
    // «ПОДГОТОВКА» на фазах escort и transfer.
    if (_ctrl.or_phase != "operating") return;
    if (!instance_exists(_ctrl.or_table)) return;

    var _label = string(_ctrl.or_action_name);

    if (_label == "") _label = "ОПЕРАЦИЯ";

    var _ratio = 1 - (_ctrl.or_timer / max(1, _ctrl.or_timer_max));
    _ratio = clamp(_ratio, 0, 1);

    // ── Палитра как у таблички «КАНДИДАТ» / действий персонала ──
    var _wood_dark = make_color_rgb(74, 49, 31);
    var _wood_light = make_color_rgb(150, 107, 73);
    var _paper = make_color_rgb(242, 232, 214);
    var _line_dark = make_color_rgb(58, 39, 24);
    var _text_dark = make_color_rgb(50, 38, 28);
    var _bar_bg = make_color_rgb(200, 184, 160);
    var _bar_color = make_color_rgb(148, 74, 64);

    var _pad_x = 12;
    var _pad_y = 6;
    var _bar_h = 6;
    var _bar_gap = 5;

    if (font_exists(fnt_main)) draw_set_font(fnt_main);

    var _text_w = string_width(_label);
    var _text_h = string_height(_label);

    var _tw = max(_text_w + _pad_x * 2 + 8, 140);
    var _th = _text_h + _pad_y * 2 + 4 + _bar_gap + _bar_h;

    var _bx1 = _ctrl.or_table.x - (_tw * 0.5);
    var _by1 = _ctrl.or_table.y - 150;
    var _bx2 = _bx1 + _tw;
    var _by2 = _by1 + _th;

    var _in_x1 = _bx1 + 5;
    var _in_y1 = _by1 + 5;
    var _in_x2 = _bx2 - 5;
    var _in_y2 = _by2 - 5;

    // Тень
    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(_bx1 + 2, _by1 + 3, _bx2 + 2, _by2 + 3, 8, 8, false);
    draw_set_alpha(1);

    // Двойная коричневая рамка
    draw_set_color(_wood_dark);
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, false);
    draw_set_color(_wood_light);
    draw_roundrect_ext(_bx1 + 2, _by1 + 2, _bx2 - 2, _by2 - 2, 6, 6, false);

    // Бумага
    draw_set_color(_paper);
    draw_roundrect_ext(_in_x1, _in_y1, _in_x2, _in_y2, 5, 5, false);

    // Контур
    draw_set_color(_line_dark);
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, true);

    // Название операции
    draw_set_color(_text_dark);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text((_bx1 + _bx2) * 0.5, _by1 + _pad_y + 1, _label);

    // Шкала под текстом
    var _bar_x1 = _in_x1 + 6;
    var _bar_x2 = _in_x2 - 6;
    var _bar_y1 = _by1 + _pad_y + _text_h + _bar_gap;
    var _bar_y2 = _bar_y1 + _bar_h;

    draw_set_color(_bar_bg);
    draw_roundrect_ext(_bar_x1, _bar_y1, _bar_x2, _bar_y2, 2, 2, false);

    if (_ratio > 0.02) {
        draw_set_color(_bar_color);
        draw_roundrect_ext(
            _bar_x1,
            _bar_y1,
            _bar_x1 + (_bar_x2 - _bar_x1) * _ratio,
            _bar_y2,
            2,
            2,
            false
        );
    }

    draw_set_color(_line_dark);
    draw_roundrect_ext(_bar_x1, _bar_y1, _bar_x2, _bar_y2, 2, 2, true);

    // Сброс
    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
