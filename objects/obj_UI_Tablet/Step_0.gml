/// Step obj_UI_Tablet
/// @description Блокировка кликов, эффекты и закрытие планшета.


// ═══════════════════════════════════════════════════════════════
// 1. ТАЙМЕРЫ
// ═══════════════════════════════════════════════════════════════

if (tablet_click_lock > 0) {
    tablet_click_lock -= 1;
}

if (condition_flash_timer > 0) {
    condition_flash_timer -= 1;
}


// ═══════════════════════════════════════════════════════════════
// 2. ЛЕТЯЩИЕ ЭФФЕКТЫ
// ═══════════════════════════════════════════════════════════════

for (var _effect_index = array_length(fly_effects) - 1; _effect_index >= 0; _effect_index--) {
    var _effect = fly_effects[_effect_index];
    _effect.timer += 1;

    if (
        !_effect.flash_done
        && _effect.timer >= floor(_effect.timer_max * 0.82)
    ) {
        condition_flash_timer = condition_flash_timer_max;
        condition_flash_color = _effect.color;
        _effect.flash_done = true;
    }

    if (_effect.timer >= _effect.timer_max) {
        array_delete(fly_effects, _effect_index, 1);
    } else {
        fly_effects[_effect_index] = _effect;
    }
}


// ═══════════════════════════════════════════════════════════════
// 3. ЗАКРЫТЫЙ ПЛАНШЕТ
// ═══════════════════════════════════════════════════════════════

if (!visible) {
    tablet_was_open = false;
    tablet_last_target_id = noone;
    fly_effects = [];
    exit;
}


// ═══════════════════════════════════════════════════════════════
// 4. ПРОВЕРКА ЦЕЛИ
// ═══════════════════════════════════════════════════════════════

if (target_id == noone || !instance_exists(target_id)) {
    visible = false;
    target_id = noone;
    tablet_was_open = false;
    tablet_last_target_id = noone;
    fly_effects = [];
    exit;
}


// ═══════════════════════════════════════════════════════════════
// 5. ЗАКРЫТИЕ ПО ESC
// ═══════════════════════════════════════════════════════════════

if (keyboard_check_pressed(vk_escape)) {
    visible = false;
    target_id = noone;
    tablet_was_open = false;
    tablet_last_target_id = noone;
    fly_effects = [];
    exit;
}


// ═══════════════════════════════════════════════════════════════
// 6. ЗАКРЫТИЕ ПО КНОПКЕ X
// Координаты совпадают с Draw GUI.
// ═══════════════════════════════════════════════════════════════

var _center_x = display_get_gui_width() * 0.5;
var _center_y = display_get_gui_height() * 0.5;

var _close_x = _center_x + 285 * ui_scale;
var _close_y = _center_y - 205 * ui_scale;
var _close_size = 10 * ui_scale;

var _mouse_x = device_mouse_x_to_gui(0);
var _mouse_y = device_mouse_y_to_gui(0);

var _close_hovered = point_distance(
    _mouse_x,
    _mouse_y,
    _close_x,
    _close_y
) <= _close_size * 1.5;

if (
    _close_hovered
    && tablet_click_lock <= 0
    && mouse_check_button_pressed(mb_left)
) {
    tablet_click_lock = 5;
    visible = false;
    target_id = noone;
    tablet_was_open = false;
    tablet_last_target_id = noone;
    fly_effects = [];
    exit;
}
