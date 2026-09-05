// ═══════════════════════════════════════════════════════════════
// obj_float_text → DRAW
//
// Текст с тёмной обводкой. Плашки нет намеренно: надпись должна
// читаться, но не загораживать происходящее в клинике.
// ═══════════════════════════════════════════════════════════════

if (float_text == "") exit;

var _old_font  = draw_get_font();
var _old_halign = draw_get_halign();
var _old_valign = draw_get_valign();

draw_set_font(fnt_main);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

// ── МАСШТАБ С УЧЁТОМ «ПОДСКОКА» ──
var _scale = text_scale;

if (life < pop_frames && pop_frames > 0) {
    // Полусинус: 0 → максимум → 0. Короткое увеличение в начале.
    var _pop_phase = life / pop_frames;
    _scale += pop_extra * sin(_pop_phase * pi);
}

// ── ОБВОДКА ──
// Рисуем текст восемь раз со сдвигом. Приём простой, но именно он
// даёт читаемость на пёстром фоне: без обводки жёлтая надпись
// теряется на светлом полу, а зелёная — на растениях.
var _outline_offset = 2;

draw_set_color(outline_color);
draw_set_alpha(image_alpha);

for (var _ox = -1; _ox <= 1; _ox++) {
    for (var _oy = -1; _oy <= 1; _oy++) {
        
        if (_ox == 0 && _oy == 0) continue;
        
        draw_text_transformed(
            x + _ox * _outline_offset,
            y + _oy * _outline_offset,
            float_text,
            _scale,
            _scale,
            0
        );
    }
}

// ── САМ ТЕКСТ ──
draw_set_color(text_color);

draw_text_transformed(
    x,
    y,
    float_text,
    _scale,
    _scale,
    0
);

// ── ВОЗВРАТ НАСТРОЕК ──
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_font(_old_font);
draw_set_halign(_old_halign);
draw_set_valign(_old_valign);
