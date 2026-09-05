/// Draw obj_staff_doctor
/// @description Сидящий врач рисуется точно по ветке сидения par_visitors.
/// Пакет №163: сидение на стуле операционной (or_seated + operating_idle)
/// рисуется той же веткой, что и стул стационара. Раньше условие проверяло
/// только "inpatient_at_chair", поэтому в операционной врач уходил в
/// par_staff → Draw и лицо рисовалось по стоячим смещениям — «висело в воздухе».

if (!variable_instance_exists(id, "or_seated")) or_seated = false;

// ПАКЕТ 272: условие приведено к тому же виду, что у владельцев.
//
// В par_visitors -> Draw, где лицо сидящего всегда на месте, проверка
// ровно одна:
//     var _visitor_sitting = (variable_instance_exists(id, "_owner_sitting")
//                             && _owner_sitting);
//
// Здесь же к флагу были дописаны ещё и состояния. Тело при этом
// садится в End Step по ДРУГОМУ условию, без _owner_sitting. Стоило
// состояниям разойтись с флагом хотя бы на кадр — тело уже сидит,
// а лицо считается по стоячим смещениям и «висит в воздухе».
//
// Убираем лишние проверки состояний. Флаг _owner_sitting ставит
// End Step врача, и он же ставит позу — теперь оба идут вместе.
var _doctor_sitting = (
    variable_instance_exists(id, "_owner_sitting")
    && _owner_sitting
);

// Стояние, ходьба и работа полностью остаются у par_staff.
if (!_doctor_sitting) {
    event_inherited();
    exit;
}


// ═══════════════════════════════════════════════════════════════
// 0. БАЗОВЫЕ ВЕЛИЧИНЫ — КАК У par_visitors
// ═══════════════════════════════════════════════════════════════

var _person_scale = variable_instance_exists(id, "_height_scale")
    ? clamp(abs(_height_scale), 0.85, 1.15)
    : 1;

// Сидящий врач использует тот же единый коэффициент по обеим осям.
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
// 1. ТЕНЬ — ТЕ ЖЕ ФИКСИРОВАННЫЕ РАЗМЕРЫ
// ═══════════════════════════════════════════════════════════════

draw_soft_oval_shadow(
    _draw_x,
    _shadow_cy,
    _shadow_rx,
    _shadow_ry,
    1
);


// ═══════════════════════════════════════════════════════════════
// 2. ПОДСВЕТКА — КАК У ВЛАДЕЛЬЦЕВ
// ═══════════════════════════════════════════════════════════════

if (is_hovered && sprite_exists(sprite_index)) {
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
// 3a. ХАЛАТ ВРАЧА — СИДЯ (Пакет 225 v3: М/Ж, через шейдер — руки не красятся)
//     Прямая ссылка на спрайт: надёжнее поиска по имени.
// ═══════════════════════════════════════════════════════════════

var _outfit_sex = "M";
if (variable_instance_exists(id, "is_female") && is_female) _outfit_sex = "F";

// Пакет 229: КРОКСЫ сидя (под штаны)
var _crs_spr = -1;
_crs_spr = spr_human_FR_sit_Crocs;

if (sprite_exists(_crs_spr)) {
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
    var _crs_frame = image_index % sprite_get_number(_crs_spr);
    var _crsuvs = sprite_get_uvs(_crs_spr, _crs_frame);
    var _crsu0 = 0; var _crsv0 = 0; var _crsu1 = 0; var _crsv1 = 0;
    if (array_length(_crsuvs) >= 8 && max(_crsuvs[4], _crsuvs[5], _crsuvs[6], _crsuvs[7]) <= 2.0) {
        _crsu0 = _crsuvs[4]; _crsv0 = _crsuvs[5]; _crsu1 = _crsuvs[6]; _crsv1 = _crsuvs[7];
    } else {
        _crsu0 = _crsuvs[0]; _crsv0 = _crsuvs[1]; _crsu1 = _crsuvs[2]; _crsv1 = _crsuvs[3];
    }
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _crsu0, _crsv0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
        abs(_crsu1 - _crsu0), abs(_crsv1 - _crsv0));
    draw_sprite_ext(_crs_spr, _crs_frame,
            _draw_x, _draw_y,
            _face_dir * _draw_sx, _draw_sy,
            0, c_white, 1);
    shader_reset();
}

// Пакет 228: ШТАНЫ под халатом (сидя) — тот же крой/цвет, что стоя
if (!variable_instance_exists(id, "pants_style")) {
    if (variable_instance_exists(id, "is_female") && is_female) {
        pants_style = choose(1, 1, 0);
    } else {
        pants_style = choose(0, 0, 1);
    }
}
var _dp_sit_spr = (pants_style == 1)
    ? spr_human_FR_sit_Pants_Slim
    : spr_human_FR_sit_Pants;

if (sprite_exists(_dp_sit_spr)) {
    if (!variable_instance_exists(id, "pants_color")) {
        pants_color = staff_random_doctor_pants_color();
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
        color_get_red(pants_color) / 255,
        color_get_green(pants_color) / 255,
        color_get_blue(pants_color) / 255);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
    var _dp_sit_frame = image_index % sprite_get_number(_dp_sit_spr);
    var _dpsuvs = sprite_get_uvs(_dp_sit_spr, _dp_sit_frame);
    var _dpsu0 = 0; var _dpsv0 = 0; var _dpsu1 = 0; var _dpsv1 = 0;
    if (array_length(_dpsuvs) >= 8 && max(_dpsuvs[4], _dpsuvs[5], _dpsuvs[6], _dpsuvs[7]) <= 2.0) {
        _dpsu0 = _dpsuvs[4]; _dpsv0 = _dpsuvs[5]; _dpsu1 = _dpsuvs[6]; _dpsv1 = _dpsuvs[7];
    } else {
        _dpsu0 = _dpsuvs[0]; _dpsv0 = _dpsuvs[1]; _dpsu1 = _dpsuvs[2]; _dpsv1 = _dpsuvs[3];
    }
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _dpsu0, _dpsv0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
        abs(_dpsu1 - _dpsu0), abs(_dpsv1 - _dpsv0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_dp_sit_spr, _dp_sit_frame,
        _draw_x, _draw_y,
        _face_dir * _draw_sx, _draw_sy,
        0, c_white, 1);
    shader_reset();
}

var _robe_sit_spr = (_outfit_sex == "F")
    ? spr_human_FR_sit_Robe_Woman
    : spr_human_FR_sit_Robe_Man;

if (sprite_exists(_robe_sit_spr)) {
    var _robe_color = c_white;
    if (variable_instance_exists(id, "robe_color")) _robe_color = robe_color;
    // Пакет 243: как у стоящего врача (239) — лёгкий оттенок ПЕРЕМНОЖЕНИЕМ,
    // без шейдера: кисть остаётся арт-цветом, утечка режимов невозможна
    draw_sprite_ext(_robe_sit_spr,
        image_index % sprite_get_number(_robe_sit_spr),
        _draw_x, _draw_y,
        _face_dir * _draw_sx, _draw_sy,
        0, _robe_color, 1);
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
