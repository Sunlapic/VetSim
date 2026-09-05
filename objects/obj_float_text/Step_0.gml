// ═══════════════════════════════════════════════════════════════
// obj_float_text → STEP
//
// Подъём, прозрачность, самоуничтожение.
// ═══════════════════════════════════════════════════════════════

life += 1;

// ── ПОДЪЁМ ──
// Надпись поднимается с замедлением: сначала бодро, к концу почти
// зависает. Так взгляд успевает её прочитать, а не гонится за ней.
var _progress = life / duration;
var _ease     = 1 - (_progress * _progress);

float_rise += float_speed * max(0.25, _ease);

// ── ПОЗИЦИЯ ──
// Если персонаж жив — летим за ним. Если он исчез (ушёл домой,
// удалён), надпись не пропадает рывком, а доигрывает на месте.
if (instance_exists(target)) {
    anchor_x = target.x;
    anchor_y = target.y;
    
    // Учитываем рост персонажа: у животных спрайт заметно меньше,
    // и надпись на фиксированной высоте висела бы слишком высоко.
    if (variable_instance_exists(target, "image_yscale")) {
        var _target_scale = abs(target.image_yscale);
        
        if (_target_scale > 0 && _target_scale < 0.95) {
            anchor_y = target.y - 20;
        }
    }
}

x = anchor_x + x_offset;
y = anchor_y + y_offset - float_rise;

// ── ПРОЗРАЧНОСТЬ ──
if (life < fade_in) {
    image_alpha = life / fade_in;
}
else if (life > duration - fade_out) {
    image_alpha = max(0, (duration - life) / fade_out);
}
else {
    image_alpha = 1;
}

// ── КОНЕЦ ЖИЗНИ ──
if (life >= duration) {
    instance_destroy();
}
