/// End Step obj_staff_doctor
/// @description Стационар и операционная используют те же анимации тела и деталей
/// лица, что обычный приём.
/// Пакет №161: добавлены состояния операционной (operating_*) и посадка бригады
/// на стулья ожидания (флаг or_seated ставит operating_system).

if (!variable_instance_exists(id, "or_seated")) or_seated = false;
if (!variable_instance_exists(id, "or_working")) or_working = false;

var _real_doctor_state = doctor_state;
var _doctor_custom_state = (
    string_pos("inpatient_", _real_doctor_state) == 1
    || string_pos("operating_", _real_doctor_state) == 1
);

// Перед родительским End Step временно подставляем стандартное состояние.
// Родитель выбирает обычные спрайты, кадры, волосы, глаза, нос и рот.
if (_doctor_custom_state) {
    switch (_real_doctor_state) {
        case "inpatient_prescribing":
            doctor_state = "examining";
        break;

        // Пакет №161: врач у операционного стола.
        // Пакет №168: рабочая анимация включается ТОЛЬКО когда операция реально
        // идёт (or_working ставит operating_system в фазе "operating").
        // Пока пациента везут — врач просто стоит и ждёт.
        case "operating_at_point":
            doctor_state = or_working ? "examining" : "idle";
        break;

        case "inpatient_escort":
        case "inpatient_escort_return":
        case "inpatient_moving_to_chair":
        case "inpatient_going_to_patient":
        case "inpatient_returning_to_chair":
        case "operating_going_to_point":
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

// ═══════════════════════════════════════════════════════════════
// ПОСАДКА: стул стационара или стул ожидания операционной (пакет №161)
// ═══════════════════════════════════════════════════════════════

var _doctor_is_sitting = (
    doctor_state == "inpatient_at_chair"
    || (or_seated && doctor_state == "operating_idle")
);

// Флаг посадки в операционной снимается сам, как только врач выходит
// из свободного состояния (его двигает operating_system).
if (doctor_state != "operating_idle") {
    or_seated = false;
}

// Финальная страховка: тот же флаг, который читает Draw владельцев.
if (_doctor_is_sitting) {
    _owner_sitting = true;
    pFacing = 1;

    if (!variable_instance_exists(id, "_sit_anim_timer")) {
        _sit_anim_timer = 1;
    }

    // На стуле операционной анимацию сидения крутим здесь
    // (в стационаре её уже прокрутил inpatient_update_staff_animation).
    if (doctor_state == "operating_idle") {
        _sit_anim_timer += 1;
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
    //
    // Пакет №166: то же самое для операционной. Бригада стоит ВЫШЕ стола
    // (у точек y меньше, чем у obj_operating_table), поэтому по обычному
    // depth = -y стол рисуется поверх врача и руки проваливаются под него.
    // Ссылки assigned_table у бригады нет специально (её сбрасывает
    // сторож зависаний в par_staff → Begin Step), поэтому стол ищется здесь.

    var _work_table = noone;

    if (
        variable_instance_exists(id, "assigned_table")
        && instance_exists(assigned_table)
        && (
            doctor_state == "examining"
            || doctor_state == "performing_procedure"
            || doctor_state == "inpatient_prescribing"
        )
    ) {
        _work_table = assigned_table;
    }
    // Пакет №167: анестезиолог стоит ЗА операционным столом, значит стол
    // должен закрывать его снизу; хирург стоит сбоку и рисуется поверх стола.
    var _or_behind_table = false;

    if (doctor_state == "operating_at_point") {
        _work_table = operating_find_table();

        _or_behind_table = (
            variable_instance_exists(id, "operating_role")
            && string(operating_role) == "anesthetist"
        );
    }

    if (instance_exists(_work_table)) {
        depth = _or_behind_table
            ? _work_table.depth + 3
            : _work_table.depth - 3;
    } else {
        depth = -y;
    }

    // Пакет №169: разворот лицом к операционному столу.
    // par_staff делает это только при живом assigned_table, а у бригады
    // операционной его нет — поэтому хирург стоял к столу спиной.
    if (doctor_state == "operating_at_point") {
        operating_face_work_table(id, operating_find_table());
    }
}
