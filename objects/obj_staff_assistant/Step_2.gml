/// End Step obj_staff_assistant
/// @description Стационар и операционная используют те же анимации тела и деталей
/// лица, что обычные процедуры.
/// Пакет №161: добавлены состояния операционной (operating_*), посадка на стул
/// ожидания (флаг or_seated) и запрет «гуляния» для персонала операционной,
/// пока он занят операцией.

if (!variable_instance_exists(id, "or_seated")) or_seated = false;
if (!variable_instance_exists(id, "or_working")) or_working = false;

var _real_assistant_state = assistant_state;
var _assistant_custom_state = (
    string_pos("inpatient_", _real_assistant_state) == 1
    || string_pos("cleaning_", _real_assistant_state) == 1
    || string_pos("operating_", _real_assistant_state) == 1
);

// Временно подставляем знакомое родителю состояние только на время End Step.
if (_assistant_custom_state) {
    switch (_real_assistant_state) {
        case "inpatient_treating":
        case "cleaning_dirt":
            assistant_state = "performing_procedure";
        break;

        // Пакет №168: у операционного стола ассистент машет руками только
        // во время самой операции (флаг or_working). Пока пациента везут —
        // стоит и ждёт.
        case "operating_at_point":
            assistant_state = or_working ? "performing_procedure" : "idle";
        break;

        case "cleaning_going_to_dirt":
        case "inpatient_moving_to_station":
        case "inpatient_moving_to_home":
        case "inpatient_going_to_patient":
        case "operating_going_to_point":
        case "operating_escort":
        case "operating_recovery":
            assistant_state = "going_to_assistant_point";
        break;

        default:
            assistant_state = "idle";
        break;
    }
}

event_inherited();

assistant_state = _real_assistant_state;

inpatient_update_staff_animation(id);


// ═══════════════════════════════════════════════════════════════
// СВОБОДНОЕ ГУЛЯНИЕ АССИСТЕНТА ВНУТРИ КЛИНИКИ
// Использует те же два прямоугольника, в которых появляется грязь.
// ═══════════════════════════════════════════════════════════════

staff_workplace_init(id);

if (!variable_instance_exists(id, "idle_zone_home_ready")) {
    idle_zone_home_ready = false;
    idle_wander_target_valid = false;
    idle_wander_target_x = x;
    idle_wander_target_y = y;
}

// Точка появления кандидата больше не является постоянным домом ассистента.
// Каждому ассистенту назначается собственная точка внутри клиники.
if (!idle_zone_home_ready || !staff_idle_home_is_valid(id)) {
    staff_idle_assign_indoor_home(id);
}

var _assistant_can_wander = (
    !is_tired
    && !is_exhausted
    && assigned_owner == noone
    && assigned_table == noone
    && assigned_pet == noone
    && (
        (workplace_id == "reception" && assistant_state == "idle")
        // Пакет №77: свободный ассистент стационара тоже гуляет по клинике,
        // когда нет работы (inpatient_available).
        || (workplace_id == "inpatient" && assistant_state == "inpatient_available")
    )
);

if (_assistant_can_wander) {
    if (!variable_instance_exists(id, "wander_idle_timer")) {
        wander_idle_timer = irandom_range(
            room_speed,
            room_speed * 3
        );
    }

    var _path_active = (
        path_index != -1
        && path_position < 1
    );

    // Родитель или старый код мог отправить свободного ассистента обратно
    // к месту найма. Такой маршрут отменяем и заменяем внутренним гулянием.
    if (_path_active && !idle_wander_target_valid) {
        path_end();
        speed = 0;
        is_walking = false;
        wander_walking = false;
        _path_active = false;
        wander_idle_timer = 0;
    }

    if (_path_active && idle_wander_target_valid) {
        is_walking = true;
        wander_walking = true;
        image_speed = 1;
    }
    else {
        if (idle_wander_target_valid) {
            idle_wander_target_valid = false;
            path_end();
            speed = 0;
            is_walking = false;
            wander_walking = false;
            wander_idle_timer = irandom_range(
                room_speed,
                room_speed * 4
            );
        }
        else {
            wander_idle_timer -= 1;
        }

        if (wander_idle_timer <= 0) {
            var _wander_started = staff_idle_start_indoor_wander(id);

            if (!_wander_started) {
                path_end();
                speed = 0;
                is_walking = false;
                wander_walking = false;
                idle_wander_target_valid = false;
                wander_idle_timer = room_speed;
            }
        }
    }
}
else {
    // Рабочий маршрут не трогаем, только забываем старую свободную цель.
    idle_wander_target_valid = false;
    wander_walking = false;
}


// ═══════════════════════════════════════════════════════════════
// ПОСАДКА НА СТУЛ ОЖИДАНИЯ ОПЕРАЦИОННОЙ (пакет №161)
// ═══════════════════════════════════════════════════════════════

if (assistant_state != "operating_idle") {
    or_seated = false;
}

if (or_seated && assistant_state == "operating_idle") {
    _owner_sitting = true;
    pFacing = 1;

    if (!variable_instance_exists(id, "_sit_anim_timer")) {
        _sit_anim_timer = 1;
    }

    _sit_anim_timer += 1;

    if (sprite_exists(spr_human_FR_sit)) {
        sprite_index = spr_human_FR_sit;
        image_index = floor(_sit_anim_timer / 12)
            mod max(1, sprite_get_number(spr_human_FR_sit));
        image_speed = 0;
    }

    path_end();
    speed = 0;
    is_walking = false;
    depth = -y - 500;

    exit;
}

_owner_sitting = false;


// ═══════════════════════════════════════════════════════════════
// Пакет №76: НЕ перебиваем глубину поверх стола.
// Раньше здесь было depth = -y, и руки ассистента уходили под койку.
// Теперь, если ассистент в рабочем состоянии у стола, сохраняем
// глубину поверх стола (как на приёме).
// ═══════════════════════════════════════════════════════════════

// Пакет №166: у операционного стола и у койки восстановления ассистент
// стоит ВЫШЕ мебели, поэтому по обычному depth = -y его руки уходят под стол.
// Ссылки assigned_table у бригады нет специально (её сбрасывает сторож
// зависаний в par_staff → Begin Step), поэтому мебель ищется здесь.

var _work_table = noone;

if (
    variable_instance_exists(id, "assigned_table")
    && instance_exists(assigned_table)
    && (
        assistant_state == "performing_procedure"
        || assistant_state == "inpatient_treating"
    )
) {
    _work_table = assigned_table;
}
else if (assistant_state == "operating_at_point") {
    _work_table = operating_find_table();
}


if (instance_exists(_work_table)) {
    depth = _work_table.depth - 3;
} else {
    depth = -y;
}

// Пакет №169: разворот лицом к столу операционной и к койке восстановления.
if (assistant_state == "operating_at_point") {
    operating_face_work_table(id, operating_find_table());
}

