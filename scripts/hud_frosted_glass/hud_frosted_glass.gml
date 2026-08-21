/// hud_frosted_glass.gml
/// @description Общие функции «матового стекла» для всех панелей (пакет №119).
/// Имитация без шейдера: полупрозрачная холодная заливка поверх мира + блик.
/// Дерево рисуется только рамкой по краю, чтобы мир реально просвечивал.


// Заливка «матового стекла» + мягкий белый блик сверху.
// _alpha — плотность стекла (меньше = прозрачнее), _glow — яркость блика.
function hud_frosted_fill(_x1, _y1, _x2, _y2, _radius, _alpha = 0.55, _glow = 0.30) {
    draw_set_alpha(_alpha);
    draw_set_color(make_color_rgb(243, 246, 250));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, _radius, _radius, false);

    if (_glow > 0) {
        draw_set_alpha(_glow);
        draw_set_color(c_white);

        var _glow_h = max(6, min(26, (_y2 - _y1) * 0.25));
        draw_roundrect_ext(
            _x1 + 3, _y1 + 3,
            _x2 - 3, _y1 + 3 + _glow_h,
            _radius, _radius, false
        );
    }

    draw_set_alpha(1);
}

// Полная панель: тень + стекло в центре + деревянная рамка только по краю.
// _th — толщина деревянной рамки (px).
function hud_draw_frosted_panel(_x1, _y1, _x2, _y2, _th = 12) {
    // Мягкая тень.
    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(
        _x1 + 4, _y1 + 6,
        _x2 + 4, _y2 + 6,
        18, 18, false
    );
    draw_set_alpha(1);

    // Стекло ПОВЕРХ мира (центр прозрачный, дерева под ним нет).
    hud_frosted_fill(
        _x1 + _th, _y1 + _th,
        _x2 - _th, _y2 - _th,
        12
    );

    // Деревянная рамка только по краю: углы-круги + полосы по сторонам.
    var _wd = make_color_rgb(74, 49, 31);
    var _wm = make_color_rgb(114, 77, 50);
    var _wl = make_color_rgb(150, 107, 73);

    draw_set_color(_wm);

    draw_circle(_x1 + _th, _y1 + _th, _th, false);
    draw_circle(_x2 - _th, _y1 + _th, _th, false);
    draw_circle(_x1 + _th, _y2 - _th, _th, false);
    draw_circle(_x2 - _th, _y2 - _th, _th, false);

    draw_rectangle(_x1 + _th, _y1, _x2 - _th, _y1 + _th, false);
    draw_rectangle(_x1 + _th, _y2 - _th, _x2 - _th, _y2, false);
    draw_rectangle(_x1, _y1 + _th, _x1 + _th, _y2 - _th, false);
    draw_rectangle(_x2 - _th, _y1 + _th, _x2, _y2 - _th, false);

    // Тёмная внешняя кромка.
    draw_set_color(_wd);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, true);

    // Светлая полоска по внутреннему краю рамки.
    draw_set_color(_wl);
    draw_roundrect_ext(
        _x1 + _th, _y1 + _th,
        _x2 - _th, _y2 - _th,
        _th, _th, true
    );
}
