///Step par_staff

// 1. Подсветка приходит из obj_Render
is_hovered = (global.hover_target == id);

// 2. Проверка: это кандидат?
var _is_candidate = (variable_instance_exists(id, "is_candidate") && is_candidate);

// 3. Клик — обычный планшет открывают только обычные сотрудники
if (is_hovered && mouse_check_button_pressed(mb_left) && !global.ui_block_world_click && !(instance_exists(obj_UI_Tablet) && obj_UI_Tablet.visible)) {
    if (!_is_candidate) {
        if (instance_exists(obj_UI_Tablet)) {
            obj_UI_Tablet.visible = true;
            obj_UI_Tablet.target_id = id;
        }
    }
}

// 4. Анимация движения
if (path_index != -1 && path_position < 1) {
    image_speed = 1;

    var _nx = path_get_x(my_path, path_position + 0.01);
    var _ny = path_get_y(my_path, path_position + 0.01);

    if (_ny < y) sprite_index = spr_human_B_walk; else sprite_index = spr_human_FR_walk;

    if (_nx > x) {
        if (sprite_index == spr_human_B_walk) pFacing = -1; else pFacing = 1;
    }
    else if (_nx < x) {
        if (sprite_index == spr_human_B_walk) pFacing = 1; else pFacing = -1;
    }

} else {
    image_speed = 0;
    image_index = 0;
    is_walking = false;
}

// ─────────────────────────────────────────────
// РАЗВОРОТ ЛИЦОМ К СТОЛУ
// Когда стоим у своей точки на приёме — всегда смотрим на стол с питомцем,
// не стоим спиной/боком. ТОЛЬКО МЕНЯЕМ ПОВОРОТ, НЕ ПЕРЕЗАПИСЫВАЕМ СПРАЙТ!
// Пакет №75: добавлены состояния стационара (inpatient_prescribing /
// inpatient_treating), чтобы персонал тоже разворачивался к койке.
// ─────────────────────────────────────────────
if (variable_instance_exists(id, "assigned_table") && instance_exists(assigned_table)) {
    var _at_table = false;
    if (variable_instance_exists(id, "doctor_state")) {
        if (doctor_state == "waiting_positions"
         || doctor_state == "examining"
         || doctor_state == "manual_exam"
         || doctor_state == "manual_procedure"
         || doctor_state == "inpatient_prescribing") _at_table = true;
    }
    if (variable_instance_exists(id, "assistant_state")) {
        if (assistant_state == "waiting_positions"
         || assistant_state == "performing_procedure"
         || assistant_state == "inpatient_treating") _at_table = true;
    }
    if (_at_table) {
        var _table_cy = assigned_table.y;
        var _dx = assigned_table.x - x;
        // Только корректируем поворот по горизонтали, не трогаем спрайт!
        // (спрайт работы/idle будет установлен в финальном блоке ниже)
        var _face_right = (_dx > 0);
        if (y < _table_cy) {
            // смотрим вниз на стол, лицом к игроку
            pFacing = _face_right ? 1 : -1;
        } else {
            // смотрим вверх на стол, спиной к игроку, инвертируем поворот
            pFacing = _face_right ? -1 : 1;
        }
    }
}
depth = -y;
