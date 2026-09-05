/// Draw obj_staff_assistant
/// @description НОВОЕ СОБЫТИЕ (пакет №163).
/// Сидящий ассистент рисуется той же веткой сидения, что врач и владельцы:
/// фиксированный скейл 0.5 и подобранные вручную смещения лица _fx=-27, _fy=21.
/// Без этого события ассистент всегда рисовался родителем par_staff по стоячим
/// смещениям, и на стуле операционной его лицо «висело в воздухе».
///
/// Стояние, ходьба, процедуры и перенос коробок полностью остаются у par_staff.

if (!variable_instance_exists(id, "or_seated")) or_seated = false;

// ПАКЕТ 272: условие приведено к тому же виду, что у владельцев
// (par_visitors -> Draw): одна проверка флага _owner_sitting, без
// довесков из состояний. Подробное объяснение — в obj_staff_doctor.
var _assistant_sitting = (
    variable_instance_exists(id, "_owner_sitting")
    && _owner_sitting
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
    // Пакет 252: тело ПЕРСОНАЛА без шейдера — серые руки стандартные.
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
// Пакет 229: КРОКСЫ + ШТАНЫ сидящему ассистенту (fix: в 228 сидя был без штанов)
if (sprite_exists(spr_human_FR_sit_Crocs)) {
    if (!variable_instance_exists(id, "crocs_color")) {
        crocs_color = staff_random_crocs_color();
    }
    shader_set(sh_scrub_pattern);
    // Пакет 251: u_armguard — есть ли в этом спрайте впечённая
    // рука-манекен. 1 = роба/халат (руку не красить),
    // 0 = обувь/штаны/кроксы (руки нет, красить весь силуэт;
    // иначе серые пиксели остаются светлыми просветами).
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_armguard"), 0);
    // Пакет 250: u_skin = 0 — серые манекены НЕ красить кожей.
    // Юниформ живёт между draw-вызовами (та же утечка, что у
    // u_simple в 243): без явного нуля рука-манекен на одежде
    // окрасилась бы кожей и дала пятна.
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_skin"), 0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_base"),
        color_get_red(crocs_color) / 255,
        color_get_green(crocs_color) / 255,
        color_get_blue(crocs_color) / 255);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
    var _cs_frame = image_index % sprite_get_number(spr_human_FR_sit_Crocs);
    var _csuvs = sprite_get_uvs(spr_human_FR_sit_Crocs, _cs_frame);
    var _csu0 = 0; var _csv0 = 0; var _csu1 = 0; var _csv1 = 0;
    if (array_length(_csuvs) >= 8 && max(_csuvs[4], _csuvs[5], _csuvs[6], _csuvs[7]) <= 2.0) {
        _csu0 = _csuvs[4]; _csv0 = _csuvs[5]; _csu1 = _csuvs[6]; _csv1 = _csuvs[7];
    } else {
        _csu0 = _csuvs[0]; _csv0 = _csuvs[1]; _csu1 = _csuvs[2]; _csv1 = _csuvs[3];
    }
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _csu0, _csv0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
        abs(_csu1 - _csu0), abs(_csv1 - _csv0));
    draw_sprite_ext(spr_human_FR_sit_Crocs, _cs_frame,
            _draw_x, _draw_y,
            _face_dir * _draw_sx, _draw_sy,
            0, c_white, 1);
    shader_reset();
}

if (!variable_instance_exists(id, "pants_style")) {
    if (variable_instance_exists(id, "is_female") && is_female) {
        pants_style = choose(1, 1, 0);
    } else {
        pants_style = choose(0, 0, 1);
    }
}
var _ps_spr = (pants_style == 1)
    ? spr_human_FR_sit_Pants_Slim
    : spr_human_FR_sit_Pants;

if (sprite_exists(_ps_spr)) {
    if (!variable_instance_exists(id, "robe_color")) {
        robe_color = staff_random_scrub_color();
    }
    var _ps_c = make_color_rgb(
        round(color_get_red(robe_color)   * 0.72),
        round(color_get_green(robe_color) * 0.72),
        round(color_get_blue(robe_color)  * 0.72));
    var _ps_base_save = robe_color;
    robe_color = _ps_c;
    shader_set(sh_scrub_pattern);
    // Пакет 251: u_armguard — есть ли в этом спрайте впечённая
    // рука-манекен. 1 = роба/халат (руку не красить),
    // 0 = обувь/штаны/кроксы (руки нет, красить весь силуэт;
    // иначе серые пиксели остаются светлыми просветами).
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_armguard"), 0);
    // Пакет 250: u_skin = 0 — серые манекены НЕ красить кожей.
    // Юниформ живёт между draw-вызовами (та же утечка, что у
    // u_simple в 243): без явного нуля рука-манекен на одежде
    // окрасилась бы кожей и дала пятна.
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_skin"), 0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_base"),
        color_get_red(robe_color) / 255,
        color_get_green(robe_color) / 255,
        color_get_blue(robe_color) / 255);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
    var _ps_frame = image_index % sprite_get_number(_ps_spr);
    var _psuvs = sprite_get_uvs(_ps_spr, _ps_frame);
    var _psu0 = 0; var _psv0 = 0; var _psu1 = 0; var _psv1 = 0;
    if (array_length(_psuvs) >= 8 && max(_psuvs[4], _psuvs[5], _psuvs[6], _psuvs[7]) <= 2.0) {
        _psu0 = _psuvs[4]; _psv0 = _psuvs[5]; _psu1 = _psuvs[6]; _psv1 = _psuvs[7];
    } else {
        _psu0 = _psuvs[0]; _psv0 = _psuvs[1]; _psu1 = _psuvs[2]; _psv1 = _psuvs[3];
    }
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _psu0, _psv0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
        abs(_psu1 - _psu0), abs(_psv1 - _psv0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_ps_spr, _ps_frame,
            _draw_x, _draw_y,
            _face_dir * _draw_sx, _draw_sy,
            0, c_white, 1);
    shader_reset();
    robe_color = _ps_base_save;
}

// 3a. РОБА АССИСТЕНТА — СИДЯ (Пакет 226: узоры 5 типов × размер × сдвиг)
//     Прямая ссылка; цвет robe_color как у остальной одежды.
// ═══════════════════════════════════════════════════════════════

var _scrub_sit_spr = (variable_instance_exists(id, "is_female") && is_female)
    ? spr_human_FR_sit_Scrub_Woman
    : spr_human_FR_sit_Scrub;

if (sprite_exists(_scrub_sit_spr)) {
    // Пакет 225: яркий цвет + узор и в сидячей позе
    if (!variable_instance_exists(id, "robe_color")) {
        robe_color = staff_random_scrub_color();
    }
    if (!variable_instance_exists(id, "scrub_pattern")) {
        scrub_pattern = irandom(4);
    }
    if (!variable_instance_exists(id, "scrub_pat_size")) {
        scrub_pat_size = random_range(0.6, 1.8);
    }
    if (!variable_instance_exists(id, "scrub_pat_phase")) {
        scrub_pat_phase = random(1.0);
    }
    shader_set(sh_scrub_pattern);
    // Пакет 251: u_armguard — есть ли в этом спрайте впечённая
    // рука-манекен. 1 = роба/халат (руку не красить),
    // 0 = обувь/штаны/кроксы (руки нет, красить весь силуэт;
    // иначе серые пиксели остаются светлыми просветами).
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_armguard"), 1);
    // Пакет 250: u_skin = 0 — серые манекены НЕ красить кожей.
    // Юниформ живёт между draw-вызовами (та же утечка, что у
    // u_simple в 243): без явного нуля рука-манекен на одежде
    // окрасилась бы кожей и дала пятна.
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_skin"), 0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_base"),
        color_get_red(robe_color) / 255,
        color_get_green(robe_color) / 255,
        color_get_blue(robe_color) / 255);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"),
        scrub_pattern);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"),
        variable_instance_exists(id, "scrub_pat_size") ? scrub_pat_size : 1.0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"),
        variable_instance_exists(id, "scrub_pat_phase") ? scrub_pat_phase : 0.0);
    // Пакет 225 v5: границы текущего кадра для узора (без прыжков
    // между кадрами). sprite_get_uvs может вернуть 8 значений
    // [x,y,x,y,u0,v0,u1,v1] или 4 [u0,v0,u1,v1] — разбираем оба.
    var _scrub_frame = image_index % sprite_get_number(_scrub_sit_spr);
    var _uvs = sprite_get_uvs(_scrub_sit_spr, _scrub_frame);
    var _u0 = 0; var _v0 = 0; var _u1 = 0; var _v1 = 0;
    if (array_length(_uvs) >= 8 && max(_uvs[4], _uvs[5], _uvs[6], _uvs[7]) <= 2.0) {
        _u0 = _uvs[4]; _v0 = _uvs[5]; _u1 = _uvs[6]; _v1 = _uvs[7];
    } else {
        _u0 = _uvs[0]; _v0 = _uvs[1]; _u1 = _uvs[2]; _v1 = _uvs[3];
    }
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _u0, _v0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
        abs(_u1 - _u0), abs(_v1 - _v0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_scrub_sit_spr, _scrub_frame,
        _draw_x, _draw_y,
        _face_dir * _draw_sx, _draw_sy,
        0, c_white, 1);
    shader_reset();
}

// ═══════════════════════════════════════════════════════════════
// 3b. РУКА ПОВЕРХ РОБЫ — СИДЯ (Пакет 231, без шейдера)
if (sprite_exists(spr_human_FR_sit_ArmTop)) {
    draw_sprite_ext(spr_human_FR_sit_ArmTop,
        image_index % sprite_get_number(spr_human_FR_sit_ArmTop),
        _draw_x, _draw_y,
        _face_dir * _draw_sx, _draw_sy,
        0, c_white, 1);
}

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
