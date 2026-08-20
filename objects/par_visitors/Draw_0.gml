// ═══════════════════════════════════════════════════════════════
// par_visitors → Draw
// Разделы 0–9.
//
// ПРАВИЛО:
//   • СТОИТ / ИДЁТ / СТОИТ К СТОЛУ — вариативное телосложение, тень по формуле
//   • СИДИТ НА ДИВАНЕ — фиксированный скейл 0.5, как было до системы телосложения,
//     с твоими подобранными вручную _fx=-27, _fy=21 (никаких умножений/смещений)
// ═══════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────
// 0. БАЗОВЫЕ ВЕЛИЧИНЫ
// ───────────────────────────────────────────────────────────────
var _s = 0.5;

if (!variable_instance_exists(id, "_height_scale"))   _height_scale   = 1.0;
if (!variable_instance_exists(id, "_width_scale"))    _width_scale    = 1.0;
if (!variable_instance_exists(id, "_draw_offset_y"))  _draw_offset_y  = 0;
if (!variable_instance_exists(id, "_face_frame"))     _face_frame     = 0;

var _visitor_sitting = (variable_instance_exists(id, "_owner_sitting") && _owner_sitting);
var _visitor_moving  = (!_visitor_sitting) && (is_walking || (path_index != -1 && path_position < 1));
var _is_back_view    = (!_visitor_sitting) && (sprite_index == spr_human_B_walk);
var _hair_color      = c_white;
if (variable_instance_exists(id, "hair_color")) _hair_color = hair_color;

var _face_dir = 1;
if (variable_instance_exists(id, "pFacing")) _face_dir = pFacing;

// ───────────────────────────────────────────────────────────────
// 1. РАСЧЁТ ПОЗИЦИИ РИСОВАНИЯ И СКЕЙЛА
// ───────────────────────────────────────────────────────────────
var _fx, _fy, _draw_sx, _draw_sy, _draw_x, _draw_y;
var _shadow_cy, _shadow_rx, _shadow_ry;
_draw_x = x;

if (_visitor_sitting) {
    // ═══════════════════════════════════════════
    // ВЕТКА СИДЕНИЯ — ровно как у тебя работало
    // ДО системы вариативного телосложения
    // ═══════════════════════════════════════════
    _fx = -27;                        // ТВОИ цифры, без умножения на что бы то ни было
    _fy =  21;
    _face_frame = 0;
    _draw_sx = _s;                    // фиксированный скейл, без _width_scale/_height_scale
    _draw_sy = _s;
    _draw_y  = y;                     // никакого _draw_offset_y
    // Тень под сидячим — маленькая, перед диваном
    _shadow_cy = y + 6;
    _shadow_rx = 21;                  // фиксированный размер
    _shadow_ry = 8;
} else {
    // ═══════════════════════════════════════════
    // ВЕТКА СТОЯНИЯ / ХОДЬБЫ — с вариативным телосложением
    // ═══════════════════════════════════════════
    _fx = 0;
    _fy = 0;
    if (!_visitor_moving) {
        _face_frame = 0;
    } else {
        _face_frame = floor(image_index);
    }
    _draw_sx = _s * _width_scale;
    _draw_sy = _s * _height_scale;
    _draw_y  = y - _draw_offset_y;
    // Тень по точной формуле через ступни
    var _sp_yoff      = sprite_get_yoffset(sprite_index);
    var _sp_feet      = 327;
    var _feet_world_y = _draw_y + (_sp_feet - _sp_yoff) * _draw_sy;
    _shadow_cy = _feet_world_y - 2;
    _shadow_rx = 42 * _width_scale;
    _shadow_ry = 10;
}

// разворот по направлению
_fx = _fx * _face_dir;
var _head_x = _draw_x + _fx;
var _head_y = _draw_y + _fy;

// ───────────────────────────────────────────────────────────────
// 2. МЯГКАЯ ОВАЛЬНАЯ МНОГОСЛОЙНАЯ ТЕНЬ
// ───────────────────────────────────────────────────────────────

draw_soft_oval_shadow(
    _draw_x,
    _shadow_cy,
    _shadow_rx,
    _shadow_ry,
    1
);
// ───────────────────────────────────────────────────────────────
// 3. ПОДСВЕТКА
// ───────────────────────────────────────────────────────────────
if (variable_instance_exists(id, "is_hovered") && is_hovered && sprite_exists(sprite_index)) {
    gpu_set_blendmode(bm_add);
    var _bold  = 2.5;
    var _alpha = 0.6;
    var _h_x   = _face_dir * _draw_sx;
    var _h_y   = _draw_sy;
    draw_sprite_ext(sprite_index, image_index, _draw_x + _bold, _draw_y,        _h_x, _h_y, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x - _bold, _draw_y,        _h_x, _h_y, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x,        _draw_y + _bold, _h_x, _h_y, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x,        _draw_y - _bold, _h_x, _h_y, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x + _bold, _draw_y + _bold, _h_x, _h_y, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x - _bold, _draw_y - _bold, _h_x, _h_y, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x + _bold, _draw_y - _bold, _h_x, _h_y, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x - _bold, _draw_y + _bold, _h_x, _h_y, 0, c_lime, _alpha);
    gpu_set_blendmode(bm_normal);
}

// ───────────────────────────────────────────────────────────────
// 4. ТЕЛО
// ───────────────────────────────────────────────────────────────
if (sprite_exists(sprite_index)) {
    draw_sprite_ext(sprite_index, image_index,
                    _draw_x, _draw_y,
                    _face_dir * _draw_sx, _draw_sy,
                    0, c_white, 1);
}

// ───────────────────────────────────────────────────────────────
// 5. СЛОИ ГОЛОВЫ
//    (для сидячих — ровно как было раньше под фиксированный скейл,
//     для стоячих — с масштабом под телосложение)
// ───────────────────────────────────────────────────────────────
if (_is_back_view) {
    if (variable_instance_exists(id, "my_hair_back") && sprite_exists(my_hair_back)) {
        draw_sprite_ext(my_hair_back, _face_frame,
                        _head_x, _head_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, _hair_color, 1);
    } else if (variable_instance_exists(id, "my_hair") && sprite_exists(my_hair)) {
        draw_sprite_ext(my_hair, _face_frame,
                        _head_x, _head_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, _hair_color, 1);
    }
} else {
    if (variable_instance_exists(id, "my_nose") && sprite_exists(my_nose)) {
        draw_sprite_ext(my_nose, _face_frame,
                        _head_x, _head_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
    }
    if (variable_instance_exists(id, "my_eyes") && sprite_exists(my_eyes)) {
        draw_sprite_ext(my_eyes, _face_frame,
                        _head_x, _head_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
    }
    if (variable_instance_exists(id, "my_mouth") && sprite_exists(my_mouth)) {
        draw_sprite_ext(my_mouth, _face_frame,
                        _head_x, _head_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
    }
    if (variable_instance_exists(id, "my_hair") && sprite_exists(my_hair)) {
        draw_sprite_ext(my_hair, _face_frame,
                        _head_x, _head_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, _hair_color, 1);
    }
}

// ───────────────────────────────────────────────────────────────
// 9. СБРОС
// ───────────────────────────────────────────────────────────────
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
gpu_set_blendmode(bm_normal);