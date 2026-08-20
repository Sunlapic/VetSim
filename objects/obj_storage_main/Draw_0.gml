/// Draw obj_storage_main
/// Пакет №83: вместо спрайта шкафа рисуем стеллаж с полками и коробочками.
/// Пакет №125: стеллаж рисуется в ПОВЕРХНОСТЬ один раз и блиттится каждый кадр.
/// Перерисовка — только когда меняется запас на складе. Это убирает лаг
/// от ежекадровой отрисовки сотен коробочек и линий.
/// Пакет №132: счётчик перерисовок для диагностики (global.debug_shelf_redraws).

// ── Размеры и точка привязки стеллажа ──
var _uw = storage_shelf_unit_width();
var _uh = storage_shelf_unit_height();
var _ud = storage_shelf_depth();
var _sw = _uw + _ud;
var _sh = _uh + _ud;
var _origin_x = x - _uw * 0.5;
var _origin_y = y - _uh - _ud;

// ── Подпись текущего запаса (дешёвый хэш по всем препаратам) ──
var _sig = 0;

if (variable_global_exists("item_ids") && is_array(global.item_ids)) {
    for (var _si = 0; _si < array_length(global.item_ids); _si++) {
        var _amt = inventory_get_amount(
            global.inventory_main,
            global.item_ids[_si]
        );
        _sig = (_sig * 31 + _amt) mod 2147483647;
    }
}

// ── Поверхность: создать при первом кадре / потере / смене размера ──
if (!variable_instance_exists(id, "shelf_surface")) {
    shelf_surface = -1;
    shelf_surface_w = 0;
    shelf_surface_h = 0;
    shelf_signature = -1;
}

var _need_render = false;

if (
    shelf_surface == -1
    || !surface_exists(shelf_surface)
) {
    shelf_surface = surface_create(_sw, _sh);
    shelf_surface_w = _sw;
    shelf_surface_h = _sh;
    shelf_signature = -1;
    _need_render = true;
}
else if (shelf_surface_w != _sw || shelf_surface_h != _sh) {
    surface_free(shelf_surface);
    shelf_surface = surface_create(_sw, _sh);
    shelf_surface_w = _sw;
    shelf_surface_h = _sh;
    shelf_signature = -1;
    _need_render = true;
}

if (shelf_signature != _sig) {
    _need_render = true;
}

// ── Перерисовка стеллажа в поверхность (только при изменении) ──
if (_need_render && shelf_surface != -1 && surface_exists(shelf_surface)) {
    var _orig_x = x;
    var _orig_y = y;

    // Временно ставим объект так, чтобы стеллаж нарисовался в локальных
    // координатах поверхности (0,0) — без правок самой функции отрисовки.
    x = _uw * 0.5;
    y = _uh + _ud;

    surface_set_target(shelf_surface);
    draw_clear_alpha(c_black, 0);
    storage_draw_main_shelf_unit(id);
    surface_reset_target();

    x = _orig_x;
    y = _orig_y;

    shelf_signature = _sig;

    // Пакет №132: счётчик перерисовок (для диагностики). Рост каждый кадр
    // без изменения запаса = склад перерисовывается зря.
    if (!variable_global_exists("debug_shelf_redraws")) {
        global.debug_shelf_redraws = 0;
    }
    global.debug_shelf_redraws += 1;
}

// ── Мягкая тень под стеллажом (дёшево, каждый кадр) ──
draw_set_color(c_black);
draw_set_alpha(0.10);
draw_ellipse(
    x - _uw * 0.42,
    y - 8,
    x + _uw * 0.42,
    y + 8,
    false
);
draw_set_alpha(0.05);
draw_ellipse(
    x - _uw * 0.50,
    y - 3,
    x + _uw * 0.50,
    y + 3,
    false
);
draw_set_alpha(1);

// ── Готовая картинка стеллажа из поверхности ──
if (shelf_surface != -1 && surface_exists(shelf_surface)) {
    draw_surface(shelf_surface, _origin_x, _origin_y);
}

// ── Зелёная обводка при наведении (hover считается в Step по всей площади) ──
if (variable_instance_exists(id, "is_hovered") && is_hovered) {
    var _r = storage_shelf_unit_rect(id);

    draw_set_alpha(0.65);
    draw_set_color(c_lime);
    draw_roundrect_ext(
        _r.x1 - 3, _r.y1 - 3,
        _r.x2 + 3, _r.y2 + 3,
        13, 13, true
    );
    draw_set_alpha(1);
    draw_set_color(c_white);
}
