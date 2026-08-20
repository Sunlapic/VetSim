/// Step par_visitors
/// @description Наведение, планшет и базовая анимация движения посетителя.


// ═══════════════════════════════════════════════════════════════
// 1. ПРОПОРЦИОНАЛЬНЫЙ РОСТ И НАВЕДЕНИЕ
// ═══════════════════════════════════════════════════════════════

// Исправляет уже сохранённых старых посетителей и не позволяет будущему
// изменению роста снова растянуть тело только по вертикали.
if (!variable_instance_exists(id, "_height_scale")) {
    _height_scale = 1;
}

_height_scale = clamp(abs(_height_scale), 0.85, 1.15);
_width_scale = _height_scale;

is_hovered = (global.hover_target == id);

if (
    is_hovered
    && mouse_check_button_pressed(mb_left)
    && !world_clicks_blocked()
) {
    if (instance_exists(obj_UI_Tablet)) {
        obj_UI_Tablet.visible = true;
        obj_UI_Tablet.target_id = id;
    }
}


// ═══════════════════════════════════════════════════════════════
// 2. АНИМАЦИЯ ДВИЖЕНИЯ ПО PATH
// ═══════════════════════════════════════════════════════════════

if (path_index != -1 && path_position < 1) {
    image_speed = 1;

    var _next_x = path_get_x(
        my_path,
        min(path_position + 0.01, 1)
    );
    var _next_y = path_get_y(
        my_path,
        min(path_position + 0.01, 1)
    );

    sprite_index = (_next_y < y)
        ? spr_human_B_walk
        : spr_human_FR_walk;

    if (_next_x > x) {
        pFacing = (sprite_index == spr_human_B_walk) ? -1 : 1;
    }
    else if (_next_x < x) {
        pFacing = (sprite_index == spr_human_B_walk) ? 1 : -1;
    }
} else {
    image_speed = 0;
    image_index = 0;
    is_walking = false;
}


depth = -y;
