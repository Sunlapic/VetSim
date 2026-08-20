///Begin Step obj_Render

global.hover_target = noone;

hover_best = noone;
hover_best_dist = 1000000;
hover_best_y = -1000000;

// ─────────────────────────────────────────────
// 1. ПЕРСОНАЛ
// ─────────────────────────────────────────────
with (par_staff) {
    is_hovered = false;

    var _hw = 30;
    var _hh = 130;

    if (mouse_x > x - _hw && mouse_x < x + _hw
    &&  mouse_y > y - _hh && mouse_y < y) {

        // Центр "тела" для выбора курсором
        var _cx = x;
        var _cy = y - 72;

        var _dist = point_distance(mouse_x, mouse_y, _cx, _cy);

        if (_dist < other.hover_best_dist - 0.5
        || (abs(_dist - other.hover_best_dist) <= 0.5 && y > other.hover_best_y)) {
            other.hover_best = id;
            other.hover_best_dist = _dist;
            other.hover_best_y = y;
        }
    }
}

// ─────────────────────────────────────────────
// 2. ПОСЕТИТЕЛИ / ВЛАДЕЛЬЦЫ
// ─────────────────────────────────────────────
with (par_visitors) {
    is_hovered = false;

    var _hw = 30;
    var _hh = 130;

    if (mouse_x > x - _hw && mouse_x < x + _hw
    &&  mouse_y > y - _hh && mouse_y < y) {

        // Центр "тела" для выбора курсором
        var _cx = x;
        var _cy = y - 72;

        var _dist = point_distance(mouse_x, mouse_y, _cx, _cy);

        if (_dist < other.hover_best_dist - 0.5
        || (abs(_dist - other.hover_best_dist) <= 0.5 && y > other.hover_best_y)) {
            other.hover_best = id;
            other.hover_best_dist = _dist;
            other.hover_best_y = y;
        }
    }
}

// ─────────────────────────────────────────────
// 3. ЖИВОТНЫЕ
// ─────────────────────────────────────────────
with (par_animals) {
    is_hovered = false;

    var _sw = sprite_get_width(sprite_index) * abs(image_xscale);
    var _sh = sprite_get_height(sprite_index) * abs(image_yscale);

    var _x1 = x - (_sw * 0.5);
    var _x2 = x + (_sw * 0.5);
    var _y1 = y - _sh;
    var _y2 = y;

    if (mouse_x > _x1 && mouse_x < _x2
    &&  mouse_y > _y1 && mouse_y < _y2) {

        var _cx = x;
        var _cy = y - (_sh * 0.5);

        var _dist = point_distance(mouse_x, mouse_y, _cx, _cy);

        if (_dist < other.hover_best_dist - 0.5
        || (abs(_dist - other.hover_best_dist) <= 0.5 && y > other.hover_best_y)) {
            other.hover_best = id;
            other.hover_best_dist = _dist;
            other.hover_best_y = y;
        }
    }
}

// ─────────────────────────────────────────────
// 4. НАЗНАЧАЕМ ТОЛЬКО ОДИН HOVER TARGET
// ─────────────────────────────────────────────
if (instance_exists(hover_best)) {
    global.hover_target = hover_best;

    with (hover_best) {
        is_hovered = true;
    }
}