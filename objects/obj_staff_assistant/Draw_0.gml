/// Draw obj_staff_assistant
/// @description НОВОЕ СОБЫТИЕ (пакет №163).
/// Сидящий ассистент рисуется той же веткой сидения, что врач и владельцы:
/// фиксированный скейл 0.5 и подобранные вручную смещения лица _fx=-27, _fy=21.
/// Без этого события ассистент всегда рисовался родителем par_staff по стоячим
/// смещениям, и на стуле операционной его лицо «висело в воздухе».
///
/// Стояние, ходьба, процедуры и перенос коробок полностью остаются у par_staff.

if (!variable_instance_exists(id, "or_seated")) or_seated = false;

var _assistant_sitting = (
    variable_instance_exists(id, "_owner_sitting")
    && _owner_sitting
    && or_seated
    && assistant_state == "operating_idle"
);

if (!_assistant_sitting) {
    event_inherited();
    exit;
}


// ═══════════════════════════════════════════════════════════════
// 0. БАЗОВЫЕ ВЕЛИЧИНЫ — КАК У par_visitors
// ═══════════════════════════════════════════════════════════════

var _person_scale = variable_instance_exists(id, "_height_scale")
    ? clamp(abs(_height_scale), 0.85, 1.15)
    : 1;

var _s = 0.5 * _person_scale;
var _fx = -27 * _person_scale;
var _fy = 21 * _person_scale;
var _face_frame = 0;
var _draw_sx = _s;
var _draw_sy = _s;
var _draw_x = x;
var _draw_y = y;
var _shadow_cy = y + 6 * _person_scale;
var _shadow_rx = 21 * _person_scale;
var _shadow_ry = 8 * _person_scale;
var _hair_color = variable_instance_exists(id, "hair_color")
    ? hair_color
    : c_white;
var _face_dir = 1;

if (variable_instance_exists(id, "pFacing")) {
    _face_dir = pFacing;
}

_fx *= _face_dir;

var _head_x = _draw_x + _fx;
var _head_y = _draw_y + _fy;


// ═══════════════════════════════════════════════════════════════
// 1. ТЕНЬ
// ═══════════════════════════════════════════════════════════════

draw_soft_oval_shadow(
    _draw_x,
    _shadow_cy,
    _shadow_rx,
    _shadow_ry,
    1
);


// ═══════════════════════════════════════════════════════════════
// 2. ПОДСВЕТКА
// ═══════════════════════════════════════════════════════════════

if (
    variable_instance_exists(id, "is_hovered")
    && is_hovered
    && sprite_exists(sprite_index)
) {
    gpu_set_blendmode(bm_add);

    var _bold = 2.5 * _person_scale;
    var _alpha = 0.6;
    var _highlight_xscale = _face_dir * _draw_sx;

    draw_sprite_ext(sprite_index, image_index, _draw_x + _bold, _draw_y, _highlight_xscale, _draw_sy, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x - _bold, _draw_y, _highlight_xscale, _draw_sy, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x, _draw_y + _bold, _highlight_xscale, _draw_sy, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x, _draw_y - _bold, _highlight_xscale, _draw_sy, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x + _bold, _draw_y + _bold, _highlight_xscale, _draw_sy, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x - _bold, _draw_y - _bold, _highlight_xscale, _draw_sy, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x + _bold, _draw_y - _bold, _highlight_xscale, _draw_sy, 0, c_lime, _alpha);
    draw_sprite_ext(sprite_index, image_index, _draw_x - _bold, _draw_y + _bold, _highlight_xscale, _draw_sy, 0, c_lime, _alpha);

    gpu_set_blendmode(bm_normal);
}


// ═══════════════════════════════════════════════════════════════
// 3. ТЕЛО
// ═══════════════════════════════════════════════════════════════

if (sprite_exists(sprite_index)) {
    draw_sprite_ext(
        sprite_index,
        image_index,
        _draw_x,
        _draw_y,
        _face_dir * _draw_sx,
        _draw_sy,
        0,
        c_white,
        1
    );
}


// ═══════════════════════════════════════════════════════════════
// 4. СЛОИ ЛИЦА — _fx=-27, _fy=21, face_frame=0
// ═══════════════════════════════════════════════════════════════

if (variable_instance_exists(id, "my_nose") && sprite_exists(my_nose)) {
    draw_sprite_ext(my_nose, _face_frame, _head_x, _head_y, _face_dir * _draw_sx, _draw_sy, 0, c_white, 1);
}

if (variable_instance_exists(id, "my_eyes") && sprite_exists(my_eyes)) {
    draw_sprite_ext(my_eyes, _face_frame, _head_x, _head_y, _face_dir * _draw_sx, _draw_sy, 0, c_white, 1);
}

if (variable_instance_exists(id, "my_mouth") && sprite_exists(my_mouth)) {
    draw_sprite_ext(my_mouth, _face_frame, _head_x, _head_y, _face_dir * _draw_sx, _draw_sy, 0, c_white, 1);
}

if (variable_instance_exists(id, "my_hair") && sprite_exists(my_hair)) {
    draw_sprite_ext(my_hair, _face_frame, _head_x, _head_y, _face_dir * _draw_sx, _draw_sy, 0, _hair_color, 1);
}


// ═══════════════════════════════════════════════════════════════
// 5. СБРОС
// ═══════════════════════════════════════════════════════════════

draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
gpu_set_blendmode(bm_normal);
