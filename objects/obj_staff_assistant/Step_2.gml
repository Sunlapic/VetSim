/// End Step obj_staff_assistant
/// @description Стационар использует те же анимации тела и деталей лица, что обычные процедуры.

var _real_assistant_state = assistant_state;
var _assistant_custom_state = (
    string_pos("inpatient_", _real_assistant_state) == 1
    || string_pos("cleaning_", _real_assistant_state) == 1
    || _real_assistant_state == "operating_idle"
);

// Временно подставляем знакомое родителю состояние только на время End Step.
if (_assistant_custom_state) {
    switch (_real_assistant_state) {
        case "inpatient_treating":
        case "cleaning_dirt":
            assistant_state = "performing_procedure";
        break;

        case "cleaning_going_to_dirt":
        case "inpatient_moving_to_station":
        case "inpatient_moving_to_home":
        case "inpatient_going_to_patient":
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
// Пакет №76: НЕ перебиваем глубину поверх стола.
// Раньше здесь было depth = -y, и руки ассистента уходили под койку.
// Теперь, если ассистент в рабочем состоянии у стола, сохраняем
// глубину поверх стола (как на приёме).
// ═══════════════════════════════════════════════════════════════

if (
    variable_instance_exists(id, "assigned_table")
    && instance_exists(assigned_table)
    && variable_instance_exists(id, "assistant_state")
    && (
        assistant_state == "performing_procedure"
        || assistant_state == "inpatient_treating"
    )
) {
    depth = assigned_table.depth - 3;
} else {
    depth = -y;
}
