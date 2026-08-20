/// Draw obj_owner
/// @description Владелец и компактная шкала терпения с текстом внутри.


// ═══════════════════════════════════════════════════════════════
// 1. ОСНОВНАЯ ОТРИСОВКА ВЛАДЕЛЬЦА
// Тело, голова, подсветка и овальная тень рисуются в par_visitors.
// ═══════════════════════════════════════════════════════════════

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 2. ПРОВЕРКА ШКАЛЫ ТЕРПЕНИЯ
// ═══════════════════════════════════════════════════════════════

var _show_wait_bar = (
    variable_instance_exists(id, "action_progress_active")
    && action_progress_active
);

if (_show_wait_bar) {
    var _current_value = variable_instance_exists(id, "action_progress_timer")
        ? action_progress_timer
        : 0;

    var _maximum_value = variable_instance_exists(id, "action_progress_timer_max")
        ? max(1, action_progress_timer_max)
        : 1;

    var _ratio = clamp(
        _current_value / _maximum_value,
        0,
        1
    );

    var _bar_color = variable_instance_exists(id, "action_progress_color")
        ? action_progress_color
        : make_color_rgb(200, 140, 60);


    // ═══════════════════════════════════════════════════════════
    // 3. РАЗМЕР И ПОЛОЖЕНИЕ
    // Панель стала значительно ниже, поэтому соседние шкалы не перекрываются.
    // ═══════════════════════════════════════════════════════════

    var _bar_width = 82;
    var _bar_height = 12;
    var _padding_x = 7;
    var _padding_y = 4;

    var _panel_width = _bar_width + _padding_x * 2;
    var _panel_height = _bar_height + _padding_y * 2;

    var _panel_x1 = x - _panel_width * 0.5;
    var _panel_y1 = y - 170;
    var _panel_x2 = _panel_x1 + _panel_width;
    var _panel_y2 = _panel_y1 + _panel_height;

    var _bar_x1 = _panel_x1 + _padding_x;
    var _bar_y1 = _panel_y1 + _padding_y;
    var _bar_x2 = _bar_x1 + _bar_width;
    var _bar_y2 = _bar_y1 + _bar_height;


    // ═══════════════════════════════════════════════════════════
    // 4. КОМПАКТНАЯ БУМАЖНАЯ РАМКА
    // ═══════════════════════════════════════════════════════════

    var _wood_dark = make_color_rgb(74, 49, 31);
    var _wood_light = make_color_rgb(150, 107, 73);
    var _paper = make_color_rgb(242, 232, 214);
    var _line_dark = make_color_rgb(58, 39, 24);
    var _bar_background = make_color_rgb(200, 184, 160);

    // Тень.
    draw_set_alpha(0.16);
    draw_set_color(c_black);
    draw_roundrect_ext(
        _panel_x1 + 2,
        _panel_y1 + 3,
        _panel_x2 + 2,
        _panel_y2 + 3,
        7,
        7,
        false
    );
    draw_set_alpha(1);

    // Двойная рамка.
    draw_set_color(_wood_dark);
    draw_roundrect_ext(
        _panel_x1,
        _panel_y1,
        _panel_x2,
        _panel_y2,
        7,
        7,
        false
    );

    draw_set_color(_wood_light);
    draw_roundrect_ext(
        _panel_x1 + 2,
        _panel_y1 + 2,
        _panel_x2 - 2,
        _panel_y2 - 2,
        5,
        5,
        false
    );

    draw_set_color(_paper);
    draw_roundrect_ext(
        _panel_x1 + 4,
        _panel_y1 + 4,
        _panel_x2 - 4,
        _panel_y2 - 4,
        4,
        4,
        false
    );

    draw_set_color(_line_dark);
    draw_roundrect_ext(
        _panel_x1,
        _panel_y1,
        _panel_x2,
        _panel_y2,
        7,
        7,
        true
    );


    // ═══════════════════════════════════════════════════════════
    // 5. УБЫВАЮЩАЯ ПОЛОСКА
    // ═══════════════════════════════════════════════════════════

    draw_set_color(_bar_background);
    draw_roundrect_ext(
        _bar_x1,
        _bar_y1,
        _bar_x2,
        _bar_y2,
        2,
        2,
        false
    );

    if (_ratio > 0.01) {
        var _fill_x2 = _bar_x1
            + (_bar_x2 - _bar_x1) * _ratio;

        draw_set_color(_bar_color);
        draw_roundrect_ext(
            _bar_x1,
            _bar_y1,
            _fill_x2,
            _bar_y2,
            2,
            2,
            false
        );
    }

    draw_set_color(_line_dark);
    draw_roundrect_ext(
        _bar_x1,
        _bar_y1,
        _bar_x2,
        _bar_y2,
        2,
        2,
        true
    );


    // ═══════════════════════════════════════════════════════════
    // 6. ТЕКСТ ВНУТРИ ШКАЛЫ
    // ═══════════════════════════════════════════════════════════

    if (font_exists(fnt_main)) {
        draw_set_font(fnt_main);
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(50, 38, 28));

    draw_text_transformed(
        (_bar_x1 + _bar_x2) * 0.5,
        (_bar_y1 + _bar_y2) * 0.5,
        "ОЖИДАНИЕ",
        0.42,
        0.48,
        0
    );
}



// ═══════════════════════════════════════════════════════════════
// 7. СБРОС DRAW
// ═══════════════════════════════════════════════════════════════

draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
gpu_set_blendmode(bm_normal);
