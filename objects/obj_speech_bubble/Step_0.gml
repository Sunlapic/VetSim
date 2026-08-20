// ═══════════════════════════════════════════════════════════════════════
// ИСПРАВЛЕННЫЙ STEP obj_speech_bubble (точный авторазмер под текст)
// ═══════════════════════════════════════════════════════════════════════
//
// Замени ВЕСЬ Step obj_speech_bubble на этот.
// Ключевая фикс: замер ширины делается ПОСЛЕ установки шрифта и учитывает
// реальный масштаб текста (0.85), запас +30 px.
// ───────────────────────────────────────────────────────────────────────

life++;

if (!instance_exists(target)) {
    instance_destroy();
    exit;
}

// ── АЛЬФА И ЖИЗНЬ ──
if (life < fade_in) {
    image_alpha = life / fade_in;
} else if (life > duration - fade_out) {
    image_alpha = max(0, (duration - life) / fade_out);
} else {
    image_alpha = 1;
}
if (life >= duration) {
    instance_destroy();
}

// ── СЛЕЖЕНИЕ ──
x = target.x;
y = target.y + b_y_off - (0.10 * life);

// ── ТОЧНЫЙ АВТОРАЗМЕР ПОД ТЕКСТ ──
var _text_scale = 0.85;
draw_set_font(fnt_main);
// Замер реальной ширины текста под наш шрифт (в пикселях)
var _real_text_w = string_width(bubble_text);
// После масштабирования текст в _text_scale раз уже
var _text_w = _real_text_w * _text_scale;
// Минимальная ширина 80, максимальная 260, но не уже текста + 40px запаса по бокам
b_width = clamp(ceil(_text_w) + 40, 80, 260);

// Высота: одна строка ~24 px, если текст влезает в ширину — одна строка,
// иначе переносим и добавляем по 22 за строку.
var _max_chars_per_line = floor((b_width - 30) / (_text_scale * 12)); // ~12px на символ
var _lines = max(1, ceil(string_length(bubble_text) / _max_chars_per_line));
b_height = 22 + _lines * 22;
draw_set_font(-1);
