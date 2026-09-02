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
    // Пакет 247: ВОЗВРАЩАЕМ СЕРЫЕ РУКИ КАК БЫЛО — тело рисуется БЕЗ
    // шейдера (серые руки-манекены + кожаные кисти, как до 241).
    // Никаких юниформов у тела — нечему течь и нечего фильтровать.
    draw_sprite_ext(sprite_index, image_index,
                    _draw_x, _draw_y,
                    _face_dir * _draw_sx, _draw_sy,
                    0, c_white, 1);
}

// ───────────────────────────────────────────────────────────────
// 4a. ОБУВЬ + ШТАНЫ ПОСЕТИТЕЛЕЙ/ВЛАДЕЛЬЦЕВ (Пакет 229)
//     Рисуются после тела, до слоёв головы. Свой цвет pants_color
//     из повседневной палитры выдаётся при первом кадре.
//     Через шейдер (без узора) — вдруг в спрайт попадут кисти рук.
// ───────────────────────────────────────────────────────────────
// ── Пакет 229: БОТИНКИ посетителям/владельцам, под штаны.
//    Два вида: низкие унисекс (_Boots) и высокие со шнуровкой
//    (_Boots_High) — вид выпадает посетителю случайно 50/50 ──
if (!variable_instance_exists(id, "boots_style")) {
    boots_style = irandom(1);
}
var _bt_spr = -1;
var _bt_high = (boots_style == 1);
if (sprite_index == spr_human_FR_walk) {
    _bt_spr = _bt_high ? spr_human_FR_walk_Boots_High : spr_human_FR_walk_Boots;
} else if (sprite_index == spr_human_B_walk) {
    _bt_spr = _bt_high ? spr_human_B_walk_Boots_High : spr_human_B_walk_Boots;
} else if (sprite_index == spr_human_FR_idle) {
    _bt_spr = _bt_high ? spr_human_FR_idle_Boots_High : spr_human_FR_idle_Boots;
} else if (sprite_index == spr_human_FR_sit) {
    _bt_spr = _bt_high ? spr_human_FR_sit_Boots_High : spr_human_FR_sit_Boots;
}

if (_bt_spr != -1 && sprite_exists(_bt_spr)) {
    if (!variable_instance_exists(id, "boots_color")) {
        boots_color = staff_random_boots_color();
    }
        shader_set(sh_scrub_pattern);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_base"),
            color_get_red(boots_color) / 255,
            color_get_green(boots_color) / 255,
            color_get_blue(boots_color) / 255);
    // Пакет 229: обуви — простое окрашивание, без фильтров (u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
        var _bt_frame = image_index % sprite_get_number(_bt_spr);
        var _btuvs = sprite_get_uvs(_bt_spr, _bt_frame);
        var _btu0 = 0; var _btv0 = 0; var _btu1 = 0; var _btv1 = 0;
        if (array_length(_btuvs) >= 8 && max(_btuvs[4], _btuvs[5], _btuvs[6], _btuvs[7]) <= 2.0) {
            _btu0 = _btuvs[4]; _btv0 = _btuvs[5]; _btu1 = _btuvs[6]; _btv1 = _btuvs[7];
        } else {
            _btu0 = _btuvs[0]; _btv0 = _btuvs[1]; _btu1 = _btuvs[2]; _btv1 = _btuvs[3];
        }
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _btu0, _btv0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
            abs(_btu1 - _btu0), abs(_btv1 - _btv0));
        draw_sprite_ext(_bt_spr, _bt_frame,
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
        shader_reset();
}

// два кроя: прямые (_Pants) и узкие (_Pants_Slim);
// женщинам чаще узкие, мужчинам чаще прямые
if (!variable_instance_exists(id, "pants_style")) {
    if (variable_instance_exists(id, "is_female") && is_female) {
        pants_style = choose(1, 1, 0);
    } else {
        pants_style = choose(0, 0, 1);
    }
}
var _vp_spr = -1;
var _vp_slim = (pants_style == 1);
if (sprite_index == spr_human_FR_walk) {
    _vp_spr = _vp_slim ? spr_human_FR_walk_Pants_Slim : spr_human_FR_walk_Pants;
} else if (sprite_index == spr_human_B_walk) {
    _vp_spr = _vp_slim ? spr_human_B_walk_Pants_Slim : spr_human_B_walk_Pants;
} else if (sprite_index == spr_human_FR_idle) {
    _vp_spr = _vp_slim ? spr_human_FR_idle_Pants_Slim : spr_human_FR_idle_Pants;
} else if (sprite_index == spr_human_FR_sit) {
    _vp_spr = _vp_slim ? spr_human_FR_sit_Pants_Slim : spr_human_FR_sit_Pants;
}

if (_vp_spr != -1 && sprite_exists(_vp_spr)) {
    if (!variable_instance_exists(id, "pants_color")) {
        pants_color = staff_random_pants_color();
    }
    shader_set(sh_scrub_pattern);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_base"),
        color_get_red(pants_color) / 255,
        color_get_green(pants_color) / 255,
        color_get_blue(pants_color) / 255);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
    var _vp_frame = image_index % sprite_get_number(_vp_spr);
    var _vpuvs = sprite_get_uvs(_vp_spr, _vp_frame);
    var _vpu0 = 0; var _vpv0 = 0; var _vpu1 = 0; var _vpv1 = 0;
    if (array_length(_vpuvs) >= 8 && max(_vpuvs[4], _vpuvs[5], _vpuvs[6], _vpuvs[7]) <= 2.0) {
        _vpu0 = _vpuvs[4]; _vpv0 = _vpuvs[5]; _vpu1 = _vpuvs[6]; _vpv1 = _vpuvs[7];
    } else {
        _vpu0 = _vpuvs[0]; _vpv0 = _vpuvs[1]; _vpu1 = _vpuvs[2]; _vpv1 = _vpuvs[3];
    }
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _vpu0, _vpv0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
        abs(_vpu1 - _vpu0), abs(_vpv1 - _vpv0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_vp_spr, _vp_frame,
                    _draw_x, _draw_y,
                    _face_dir * _draw_sx, _draw_sy,
                    0, c_white, 1);
    shader_reset();
}

// ───────────────────────────────────────────────────────────────
// 4b. ВЕРХ ПОСЕТИТЕЛЕЙ — роба-скраб (Пакет 240)
//     Та же роба, что у ассистентов (Scrub / Scrub_Woman), спина —
//     общий спрайт. НО цвета ПРИГЛУШЁННЫЕ: спокойная «уличная»
//     палитра вместо яркой рабочей. Узоров нет. Кисти в спрайте
//     робы шейдер красит кожей (как у ассистентов).
// ───────────────────────────────────────────────────────────────
var _vt_spr = -1;
var _vt_w = (variable_instance_exists(id, "is_female") && is_female);

if (sprite_index == spr_human_FR_walk) {
    _vt_spr = _vt_w ? spr_human_FR_walk_Scrub_Woman : spr_human_FR_walk_Scrub;
} else if (sprite_index == spr_human_B_walk) {
    _vt_spr = spr_human_B_walk_Scrub;
} else if (sprite_index == spr_human_FR_idle) {
    _vt_spr = _vt_w ? spr_human_FR_idle_Scrub_Woman : spr_human_FR_idle_Scrub;
} else if (sprite_index == spr_human_FR_sit) {
    _vt_spr = _vt_w ? spr_human_FR_sit_Scrub_Woman : spr_human_FR_sit_Scrub;
}

if (_vt_spr != -1 && sprite_exists(_vt_spr)) {
    if (!variable_instance_exists(id, "visit_top_color")) {
        // Пакет 240: приглушённая палитра посетителей — не ярче штанов
        visit_top_color = choose(
            make_color_rgb(150, 170, 186),   // серо-голубой
            make_color_rgb(158, 178, 158),   // шалфей
            make_color_rgb(192, 160, 164),   // пыльная роза
            make_color_rgb(168, 164, 186),   // серая лаванда
            make_color_rgb(196, 182, 158),   // песочно-бежевый
            make_color_rgb(188, 148, 128),   // приглушённая терракота
            make_color_rgb(178, 178, 182),   // светло-серый
            make_color_rgb(144, 176, 172)    // серо-бирюзовый
        );
    }
    shader_set(sh_scrub_pattern);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_base"),
        color_get_red(visit_top_color) / 255,
        color_get_green(visit_top_color) / 255,
        color_get_blue(visit_top_color) / 255);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
    var _vt_frame = image_index % sprite_get_number(_vt_spr);
    var _vtuvs = sprite_get_uvs(_vt_spr, _vt_frame);
    var _vtu0 = 0; var _vtv0 = 0; var _vtu1 = 0; var _vtv1 = 0;
    if (array_length(_vtuvs) >= 8 && max(_vtuvs[4], _vtuvs[5], _vtuvs[6], _vtuvs[7]) <= 2.0) {
        _vtu0 = _vtuvs[4]; _vtv0 = _vtuvs[5]; _vtu1 = _vtuvs[6]; _vtv1 = _vtuvs[7];
    } else {
        _vtu0 = _vtuvs[0]; _vtv0 = _vtuvs[1]; _vtu1 = _vtuvs[2]; _vtv1 = _vtuvs[3];
    }
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _vtu0, _vtv0);
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
        abs(_vtu1 - _vtu0), abs(_vtv1 - _vtv0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_vt_spr, _vt_frame,
                    _draw_x, _draw_y,
                    _face_dir * _draw_sx, _draw_sy,
                    0, c_white, 1);
    shader_reset();
}

// ───────────────────────────────────────────────────────────────
// 4c. РУКА ПОВЕРХ РОБЫ ПОСЕТИТЕЛЕЙ (Пакет 249)
//     Готовые ArmTop-спрайты ассистента (231): серое предплечье +
//     кожаная кисть ПОВЕРХ робы, БЕЗ шейдера. Перекрывает впечённую
//     в спрайт робы руку (которая красится цветом). Посетители носят
//     ту же робу — слой садится точно. Поз посетителей всего 4,
//     все покрыты. Владельцы (наследники) — тоже.
// ───────────────────────────────────────────────────────────────
var _va_spr = -1;
if (sprite_index == spr_human_FR_walk) {
    _va_spr = spr_human_FR_walk_ArmTop;
} else if (sprite_index == spr_human_B_walk) {
    _va_spr = spr_human_B_walk_ArmTop;
} else if (sprite_index == spr_human_FR_idle) {
    _va_spr = spr_human_FR_idle_ArmTop;
} else if (sprite_index == spr_human_FR_sit) {
    _va_spr = spr_human_FR_sit_ArmTop;
}

if (_va_spr != -1 && sprite_exists(_va_spr)) {
    draw_sprite_ext(_va_spr, image_index % sprite_get_number(_va_spr),
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