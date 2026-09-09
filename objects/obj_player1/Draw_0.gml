///Draw obj_player

actor_draw_action_progress();


// ═══════════════════════════════════════════════════════════════
// ПАКЕТ №330: ПРЕВЬЮ ВАРИАНТОВ ШКАЛЫ ОЖИДАНИЯ — КЛАВИША V
//
// Показывает все шесть оформлений сразу над головой героя: с
// подписями и с разными цветами, чтобы выбрать и вариант, и
// палитру за один взгляд. Работает только в режиме отладки.
//
// Выбрал номер — впиши его в макрос WAIT_BAR_STYLE (скрипт
// wait_bar_system) и нажми V ещё раз, чтобы убрать превью.
//
// Буква V свободна: отладкой заняты N, Q, W (R освободилась в
// пакете №329, но её не трогаем — привычка).
// ═══════════════════════════════════════════════════════════════

if (
    variable_global_exists("vetsim_debug_mode")
    && global.vetsim_debug_mode
    && keyboard_check_pressed(ord("V"))
) {
    if (!variable_global_exists("wait_bar_preview_on")) {
        global.wait_bar_preview_on = false;
    }

    global.wait_bar_preview_on = !global.wait_bar_preview_on;

    show_debug_message(
        "[ШКАЛА] Превью вариантов "
        + (global.wait_bar_preview_on ? "включено" : "выключено")
        + ". Выбранный стиль: WAIT_BAR_STYLE = "
        + string(WAIT_BAR_STYLE) + "."
    );
}

if (
    variable_global_exists("wait_bar_preview_on")
    && global.wait_bar_preview_on
    && script_exists(asset_get_index("draw_wait_bar_preview"))
) {
    draw_wait_bar_preview();
}

// 1. РИСУЕМ ДОРОЖКУ ПУТИ (Только для главного героя)
if (path_index != -1 && path_position < 1) {
    draw_set_alpha(0.6);
    draw_set_color(c_lime);
    
    // Рисуем точки от текущей позиции до конца пути
    for (var i = path_position; i < 1; i += 0.05) {
        var _px = path_get_x(my_path, i);
        var _py = path_get_y(my_path, i);
        draw_circle(_px, _py, 2, false);
    }
    
    draw_set_alpha(1.0);
    draw_set_color(c_white);
}

event_inherited();

// Подпись во время ручного приёма
if (doctor_state == "manual_exam") {

    var _label = "ОСМОТР";
    var _pad_x = 10;
    var _pad_y = 4;

    var _tw = string_width(_label) + _pad_x * 2 + 8;
    var _th = string_height(_label) + _pad_y * 2 + 4;

    var _bx1 = x - (_tw * 0.5);
    var _by1 = y - 180;
    var _bx2 = _bx1 + _tw;
    var _by2 = _by1 + _th;

    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(_bx1 + 2, _by1 + 3, _bx2 + 2, _by2 + 3, 8, 8, false);
    draw_set_alpha(1);

    draw_set_color(make_color_rgb(74, 49, 31));
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, false);

    draw_set_color(make_color_rgb(150, 107, 73));
    draw_roundrect_ext(_bx1 + 2, _by1 + 2, _bx2 - 2, _by2 - 2, 6, 6, false);

    draw_set_color(make_color_rgb(242, 232, 214));
    draw_roundrect_ext(_bx1 + 5, _by1 + 5, _bx2 - 5, _by2 - 5, 5, 5, false);

    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text(_bx1 + _pad_x + 4, _by1 + _pad_y + 1, _label);

    draw_set_color(c_white);
    draw_set_alpha(1);
}