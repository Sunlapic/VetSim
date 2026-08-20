/// End Step obj_staff_doctor
/// @description Стационар использует те же анимации тела и деталей лица, что обычный приём.

var _real_doctor_state = doctor_state;
var _doctor_custom_state = (
    string_pos("inpatient_", _real_doctor_state) == 1
    || _real_doctor_state == "operating_idle"
);

// Перед родительским End Step временно подставляем стандартное состояние.
// Родитель выбирает обычные спрайты, кадры, волосы, глаза, нос и рот.
if (_doctor_custom_state) {
    switch (_real_doctor_state) {
        case "inpatient_prescribing":
            doctor_state = "examining";
        break;

        case "inpatient_escort":
        case "inpatient_escort_return":
        case "inpatient_moving_to_chair":
        case "inpatient_going_to_patient":
        case "inpatient_returning_to_chair":
            doctor_state = "going_to_doctor_point";
        break;

        default:
            doctor_state = "idle";
        break;
    }
}

event_inherited();

// Сразу возвращаем настоящее служебное состояние: основная логика врача
// никогда не увидит examining/going_to_doctor_point из визуальной подмены.
doctor_state = _real_doctor_state;

// Для обычного приёма основной Step уже создал фазу Терапии.
// Здесь один раз добавляется профильная фаза и обновляется её подпись.
doctor_visit_update_npc_timing(id);

inpatient_doctor_after_step(id);
inpatient_update_staff_animation(id);

// Финальная страховка: тот же флаг, который читает Draw владельцев.
if (doctor_state == "inpatient_at_chair") {
    _owner_sitting = true;
    pFacing = 1;

    if (!variable_instance_exists(id, "_sit_anim_timer")) {
        _sit_anim_timer = 1;
    }

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
} else {
    _owner_sitting = false;

    // Пакет №76: НЕ перебиваем глубину поверх стола.
    // Раньше здесь было depth = -y, и руки врача уходили под койку.
    if (
        variable_instance_exists(id, "assigned_table")
        && instance_exists(assigned_table)
        && variable_instance_exists(id, "doctor_state")
        && (
            doctor_state == "examining"
            || doctor_state == "performing_procedure"
            || doctor_state == "inpatient_prescribing"
        )
    ) {
        depth = assigned_table.depth - 3;
    } else {
        depth = -y;
    }
}
