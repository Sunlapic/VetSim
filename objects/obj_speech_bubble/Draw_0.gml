// ═══════════════════════════════════════════════════════════════════════
// ИСПРАВЛЕННЫЙ DRAW obj_speech_bubble (с переносом длинного текста)
// ═══════════════════════════════════════════════════════════════════════
//
// Замени ВЕСЬ Draw obj_speech_bubble на этот.
// Текст рисуется через draw_text_ext_transformed — сам переносится на новую
// строку если не влезает, и вертикально центрируется.
// ───────────────────────────────────────────────────────────────────────

if (!instance_exists(target)) exit;
if (bubble_text == "") exit;

// ── ГАРАНТИРОВАННОЕ СЛЕЖЕНИЕ ПРЯМО В DRAW ──
x = target.x;
y = target.y + b_y_off - (0.10 * life);
draw_set_alpha(image_alpha);

var _bx = x - b_width/2;
var _by = y - b_height;

// ТЕНЬ
draw_set_color(c_black);
draw_set_alpha(0.25 * image_alpha);
draw_roundrect_ext(_bx + 3, _by + 3, _bx + 3 + b_width, _by + 3 + b_height, 10, 10, false);
draw_set_alpha(image_alpha);

// ФОН (бумага)
draw_set_color(make_color_rgb(248, 238, 220));
draw_roundrect_ext(_bx, _by, _bx + b_width, _by + b_height, 10, 10, false);

// РАМКА двойная
draw_set_color(make_color_rgb(150, 107, 73));
draw_roundrect_ext(_bx + 1, _by + 1, _bx + b_width - 1, _by + b_height - 1, 9, 9, true);
draw_set_color(make_color_rgb(74, 49, 31));
draw_roundrect_ext(_bx, _by, _bx + b_width, _by + b_height, 10, 10, true);

// ХВОСТИК
var _tail_cx   = x;
var _tail_top  = _by + b_height;
var _tail_bot  = _tail_top + 12;
var _tail_half = 9;
draw_set_color(make_color_rgb(248, 238, 220));
draw_triangle(
    _tail_cx - _tail_half, _tail_top,
    _tail_cx + _tail_half, _tail_top,
    _tail_cx,              _tail_bot,
    false
);
draw_set_color(make_color_rgb(74, 49, 31));
draw_line(_tail_cx - _tail_half, _tail_top, _tail_cx, _tail_bot);
draw_line(_tail_cx + _tail_half, _tail_top, _tail_cx, _tail_bot);
draw_line(_tail_cx - _tail_half + 1, _tail_top, _tail_cx + _tail_half - 1, _tail_top);

// ── ТЕКСТ (с авто-переносом по ширине облачка) ──
draw_set_color(make_color_rgb(50, 38, 28));
draw_set_font(fnt_main);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _text_pad = 14;
draw_text_ext_transformed(
    x, _by + b_height/2 + 1,
    bubble_text,
    20,
    b_width - _text_pad,
    0.85, 0.95, 0
);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);
draw_set_alpha(1);
