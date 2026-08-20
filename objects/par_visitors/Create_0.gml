/// Create par_visitors
/// @description Базовые данные, внешность и телосложение посетителя.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 1. БАЗОВЫЕ ДАННЫЕ
// ═══════════════════════════════════════════════════════════════

is_hovered = false;
my_baked_portrait = -1;

role = "assistant";
is_female = choose(false, true);
char_name = get_random_name(is_female);

stat_patience = 100;
stat_money = irandom_range(50, 500);


// ═══════════════════════════════════════════════════════════════
// 2. БАЗОВЫЙ МАСШТАБ
// ═══════════════════════════════════════════════════════════════

var _morph = random_range(0.85, 1.15);
image_xscale = _morph;
image_yscale = _morph;


// ═══════════════════════════════════════════════════════════════
// 3. ПРОПОРЦИОНАЛЬНЫЙ РОСТ
// Один коэффициент применяется и к ширине, и к высоте.
// ═══════════════════════════════════════════════════════════════

var _person_scale = random_range(0.85, 1.15);

_height_scale = _person_scale;
_width_scale = _person_scale;

var _base_draw_scale = 0.5;
var _feet_offset_in_sprite = 27;

_draw_offset_y = _feet_offset_in_sprite
    * _base_draw_scale
    * (_person_scale - 1);

_person_really_walking = false;
