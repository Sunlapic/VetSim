// ═══════════════════════════════════════════════════════════════
// par_staff → Draw  (отрисовка персонала с вариативным телосложением)
// Разделы с номерами 1–9 — чтобы легко находить и менять по частям.
// ═══════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────
// 0. БАЗОВЫЕ ВЕЛИЧИНЫ И ПРОВЕРКИ
// ───────────────────────────────────────────────────────────────
var _s = 0.5;

// Пакет 255: единый белый для формы администратора.
// ВАЖНО: обычная var, НЕ #macro. Директива #macro внутри события
// объекта в GameMaker недопустима — из-за неё в 253/254 весь
// par_staff -> Draw не компилировался, и админ оставался голым.
// В проекте макросы объявляются только в scripts/macros.
// Значение 245, а не 255: чистый белый съедает светотень.
var _admin_white = make_color_rgb(245, 245, 245);

// Страховка на случай если у какого-то инстанса переменных ещё нет
if (!variable_instance_exists(id, "_height_scale"))   _height_scale   = 1.0;
if (!variable_instance_exists(id, "_width_scale"))    _width_scale    = 1.0;
if (!variable_instance_exists(id, "_draw_offset_y"))  _draw_offset_y  = 0;
if (!variable_instance_exists(id, "_face_frame"))     _face_frame     = 0;

var _draw_sx   = _s * _width_scale;
var _draw_sy   = _s * _height_scale;
var _face_dir  = 1;
if (variable_instance_exists(id, "pFacing")) _face_dir = pFacing;

var _is_back_view = false;
if (sprite_exists(sprite_index)) {
    _is_back_view = (string_pos("_B_", sprite_get_name(sprite_index)) > 0);
}

var _hair_color = c_white;
if (variable_instance_exists(id, "hair_color")) _hair_color = hair_color;

// ───────────────────────────────────────────────────────────────
// 1. ОПРЕДЕЛЕНИЕ ПОЗЫ И КАДРА ЛИЦА
// ───────────────────────────────────────────────────────────────
var _fx = 0;
var _fy = 0;
var _person_really_walking_flag = (variable_instance_exists(id, "_person_really_walking") && _person_really_walking);
var _person_sitting = (sprite_index == spr_human_FR_sit);
var _person_working = (sprite_index == spr_human_FR_work);
var _person_carrying = (sprite_index == spr_human_FR_carry || sprite_index == spr_human_B_carry);

if (_person_sitting) {
    _fy = 0;
    _fx = 0;
    _face_frame = 0;
} else if (_person_working) {
    _face_frame = 0;
} else if (!_person_really_walking_flag && !_person_carrying) {
    _face_frame = 0;
} else {
    _face_frame = floor(image_index);
}

// масштабируем смещение головы под общий скейл персонажа
_fx = _fx * _s * _width_scale * _face_dir;
_fy = _fy * _s * _height_scale;

// Общая Y-точка рисования ВСЕХ ЧАСТЕЙ — одинаковая для тела, головы и подсветки
var _draw_y = y - _draw_offset_y;
var _draw_x = x;

// ───────────────────────────────────────────────────────────────
// 2. МЯГКАЯ ОВАЛЬНАЯ ТЕНЬ ПОД СТУПНЯМИ
// ───────────────────────────────────────────────────────────────

if (sprite_exists(sprite_index)) {

    var _sp_yoff = sprite_get_yoffset(sprite_index);
    var _sp_feet = 327;

    var _feet_world_y =
        _draw_y
        + (_sp_feet - _sp_yoff)
        * _draw_sy;

    var _shadow_cx = _draw_x;
    var _shadow_cy = _feet_world_y - 2;

    var _shadow_half_w = 42 * _width_scale;
    var _shadow_half_h = 10;

    draw_soft_oval_shadow(
        _shadow_cx,
        _shadow_cy,
        _shadow_half_w,
        _shadow_half_h,
        1
    );
}
// ───────────────────────────────────────────────────────────────
// 3. ПОДСВЕТКА ПРИ НАВЕДЕНИИ
// ───────────────────────────────────────────────────────────────
if (variable_instance_exists(id, "is_hovered") && is_hovered && sprite_exists(sprite_index)) {
    gpu_set_blendmode(bm_add);
    var _bold  = 2.5;
    var _alpha = 0.6;
    var _h_x = _face_dir * _draw_sx;
    var _h_y = _draw_sy;
    // восемь смещений вокруг фигуры — все в той же _draw_y точке
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
    // Пакет 252: тело ПЕРСОНАЛА рисуется БЕЗ шейдера — серые руки
    // стандартные, как было до 251. Покраска тела в кожу оставлена
    // ТОЛЬКО владельцам и посетителям (par_visitors).
    draw_sprite_ext(sprite_index, image_index,
                    _draw_x, _draw_y,
                    _face_dir * _draw_sx, _draw_sy,
                    0, c_white, 1);
}

// ───────────────────────────────────────────────────────────────
// 4a. ОДЕЖДА ПОВЕРХ ТЕЛА (Пакет 229: кроксы → штаны → роба/халат)
//     Халат врача во всех позах (ходьба FR/B, стойка, работа, сидение),
//     ОТДЕЛЬНО для мужчин и женщин: Robe_Man / Robe_Woman.
//     Вид сзади (B_walk) — общий: мужской спрайт для обоих полов.
//     ВСЕ спрайты — ПРЯМЫЕ ссылки, имена должны совпадать точно.
//     Для компиляции нужны 9 спрайтов (5 Man + 4 Woman).
// ───────────────────────────────────────────────────────────────
var _outfit_sex = "M";
if (variable_instance_exists(id, "is_female") && is_female) _outfit_sex = "F";

if (role == "doctor") {

    // ── Пакет 229: КРОКСЫ сотрудникам (под штаны) ──
    var _cr_spr = -1;
    if (sprite_index == spr_human_FR_walk) {
        _cr_spr = spr_human_FR_walk_Crocs;
    } else if (sprite_index == spr_human_B_walk) {
        _cr_spr = spr_human_B_walk_Crocs;
    } else if (sprite_index == spr_human_FR_idle) {
        _cr_spr = spr_human_FR_idle_Crocs;
    } else if (sprite_index == spr_human_FR_work) {
        _cr_spr = spr_human_FR_work_Crocs;
    } else if (sprite_index == spr_human_FR_sit) {
        _cr_spr = spr_human_FR_sit_Crocs;
    } else if (sprite_index == spr_human_FR_carry) {
        _cr_spr = spr_human_FR_carry_Crocs;
    } else if (sprite_index == spr_human_B_carry) {
        _cr_spr = spr_human_B_carry_Crocs;
    }

    if (_cr_spr != -1 && sprite_exists(_cr_spr)) {
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
        var _cr_frame = image_index % sprite_get_number(_cr_spr);
        var _cruvs = sprite_get_uvs(_cr_spr, _cr_frame);
        var _cru0 = 0; var _crv0 = 0; var _cru1 = 0; var _crv1 = 0;
        if (array_length(_cruvs) >= 8 && max(_cruvs[4], _cruvs[5], _cruvs[6], _cruvs[7]) <= 2.0) {
            _cru0 = _cruvs[4]; _crv0 = _cruvs[5]; _cru1 = _cruvs[6]; _crv1 = _cruvs[7];
        } else {
            _cru0 = _cruvs[0]; _crv0 = _cruvs[1]; _cru1 = _cruvs[2]; _crv1 = _cruvs[3];
        }
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _cru0, _crv0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
            abs(_cru1 - _cru0), abs(_crv1 - _crv0));
        draw_sprite_ext(_cr_spr, _cr_frame,
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
        shader_reset();
    }

    // ── Пакет 228: ШТАНЫ под халатом врача (закрывают серые ноги).
    //    Крой по pants_style (Ж чаще узкие, М чаще прямые),
    //    цвет — тёмная «врачева» палитра. Рисуются ДО халата. ──
    if (!variable_instance_exists(id, "pants_style")) {
        if (variable_instance_exists(id, "is_female") && is_female) {
            pants_style = choose(1, 1, 0);
        } else {
            pants_style = choose(0, 0, 1);
        }
    }
    var _dp_spr = -1;
    var _dp_slim = (pants_style == 1);
    if (sprite_index == spr_human_FR_walk) {
        _dp_spr = _dp_slim ? spr_human_FR_walk_Pants_Slim : spr_human_FR_walk_Pants;
    } else if (sprite_index == spr_human_B_walk) {
        _dp_spr = _dp_slim ? spr_human_B_walk_Pants_Slim : spr_human_B_walk_Pants;
    } else if (sprite_index == spr_human_FR_idle) {
        _dp_spr = _dp_slim ? spr_human_FR_idle_Pants_Slim : spr_human_FR_idle_Pants;
    } else if (sprite_index == spr_human_FR_work) {
        _dp_spr = _dp_slim ? spr_human_FR_work_Pants_Slim : spr_human_FR_work_Pants;
    } else if (sprite_index == spr_human_FR_sit) {
        _dp_spr = _dp_slim ? spr_human_FR_sit_Pants_Slim : spr_human_FR_sit_Pants;
    }

    if (_dp_spr != -1 && sprite_exists(_dp_spr)) {
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
        var _dp_frame = image_index % sprite_get_number(_dp_spr);
        var _dpuvs = sprite_get_uvs(_dp_spr, _dp_frame);
        var _dpu0 = 0; var _dpv0 = 0; var _dpu1 = 0; var _dpv1 = 0;
        if (array_length(_dpuvs) >= 8 && max(_dpuvs[4], _dpuvs[5], _dpuvs[6], _dpuvs[7]) <= 2.0) {
            _dpu0 = _dpuvs[4]; _dpv0 = _dpuvs[5]; _dpu1 = _dpuvs[6]; _dpv1 = _dpuvs[7];
        } else {
            _dpu0 = _dpuvs[0]; _dpv0 = _dpuvs[1]; _dpu1 = _dpuvs[2]; _dpv1 = _dpuvs[3];
        }
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _dpu0, _dpv0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
            abs(_dpu1 - _dpu0), abs(_dpv1 - _dpv0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_dp_spr, _dp_frame,
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
        shader_reset();
    }

    var _robe_spr = -1;
    var _robe_w = (_outfit_sex == "F");

    if (sprite_index == spr_human_FR_walk) {
        _robe_spr = _robe_w ? spr_human_FR_walk_Robe_Woman : spr_human_FR_walk_Robe_Man;
    } else if (sprite_index == spr_human_B_walk) {
        // вид сзади у халата унисекс: и М, и Ж используют мужской спрайт
        _robe_spr = spr_human_B_walk_Robe_Man;
    } else if (sprite_index == spr_human_FR_idle) {
        _robe_spr = _robe_w ? spr_human_FR_idle_Robe_Woman : spr_human_FR_idle_Robe_Man;
    } else if (sprite_index == spr_human_FR_work) {
        _robe_spr = _robe_w ? spr_human_FR_work_Robe_Woman : spr_human_FR_work_Robe_Man;
    } else if (sprite_index == spr_human_FR_sit) {
        _robe_spr = _robe_w ? spr_human_FR_sit_Robe_Woman : spr_human_FR_sit_Robe_Man;
    }

    if (_robe_spr != -1 && sprite_exists(_robe_spr)) {
        // оттенок халата: генерируется при найме; для игрока (нет
        // staff_generate_appearance) — мягкий пастельный при первом кадре
        if (!variable_instance_exists(id, "robe_color")) {
            robe_color = staff_random_robe_color();
        }
        // Пакет 239, ступень 2: ЛЁГКИЕ ОТТЕНКИ БЕЗ ШЕЙДЕРА.
        // robe_color передаётся в draw_sprite_ext как цвет смешения —
        // GameMaker ПЕРЕМНОЖАЕТ его со спрайтом: пастельный цвет ×
        // белый халат = мягкий оттенок, кисть чуть тонизируется
        // (так же слабо, как раньше). Никаких фильтров и порогов —
        // сломаться нечему. Палитра — прежние пастели из
        // staff_random_robe_color() (245..248 — оттенок деликатный).
        draw_sprite_ext(_robe_spr, image_index % sprite_get_number(_robe_spr),
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, robe_color, 1);
    }
}

// ── роба ассистента (скраб-верх, Пакет 224) ──
// спереди М/Ж (у женской обозначена грудь), спина общая;
// ассистенты носят коробки — carry-позы тоже покрыты
else if (role == "assistant") {

    // ── Пакет 229: КРОКСЫ сотрудникам (под штаны) ──
    var _cr_spr = -1;
    if (sprite_index == spr_human_FR_walk) {
        _cr_spr = spr_human_FR_walk_Crocs;
    } else if (sprite_index == spr_human_B_walk) {
        _cr_spr = spr_human_B_walk_Crocs;
    } else if (sprite_index == spr_human_FR_idle) {
        _cr_spr = spr_human_FR_idle_Crocs;
    } else if (sprite_index == spr_human_FR_work) {
        _cr_spr = spr_human_FR_work_Crocs;
    } else if (sprite_index == spr_human_FR_sit) {
        _cr_spr = spr_human_FR_sit_Crocs;
    } else if (sprite_index == spr_human_FR_carry) {
        _cr_spr = spr_human_FR_carry_Crocs;
    } else if (sprite_index == spr_human_B_carry) {
        _cr_spr = spr_human_B_carry_Crocs;
    }

    if (_cr_spr != -1 && sprite_exists(_cr_spr)) {
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
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
        var _cr_frame = image_index % sprite_get_number(_cr_spr);
        var _cruvs = sprite_get_uvs(_cr_spr, _cr_frame);
        var _cru0 = 0; var _crv0 = 0; var _cru1 = 0; var _crv1 = 0;
        if (array_length(_cruvs) >= 8 && max(_cruvs[4], _cruvs[5], _cruvs[6], _cruvs[7]) <= 2.0) {
            _cru0 = _cruvs[4]; _crv0 = _cruvs[5]; _cru1 = _cruvs[6]; _crv1 = _cruvs[7];
        } else {
            _cru0 = _cruvs[0]; _crv0 = _cruvs[1]; _cru1 = _cruvs[2]; _crv1 = _cruvs[3];
        }
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _cru0, _crv0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
            abs(_cru1 - _cru0), abs(_crv1 - _crv0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_cr_spr, _cr_frame,
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
        shader_reset();
    }

    // ── Пакет 228: ШТАНЫ под робой (унисекс), рисуются ДО робы.
    //    Два кроя: прямые (_Pants) и узкие (_Pants_Slim) — стиль
    //    выдаётся персонажу один раз (pants_style 0/1) ──
    if (!variable_instance_exists(id, "pants_style")) {
        if (variable_instance_exists(id, "is_female") && is_female) {
            pants_style = choose(1, 1, 0);   // женщины чаще узкие
        } else {
            pants_style = choose(0, 0, 1);   // мужчины чаще прямые
        }
    }
    var _pants_spr = -1;
    var _pants_slim = (pants_style == 1);
    if (sprite_index == spr_human_FR_walk) {
        _pants_spr = _pants_slim ? spr_human_FR_walk_Pants_Slim : spr_human_FR_walk_Pants;
    } else if (sprite_index == spr_human_B_walk) {
        _pants_spr = _pants_slim ? spr_human_B_walk_Pants_Slim : spr_human_B_walk_Pants;
    } else if (sprite_index == spr_human_FR_idle) {
        _pants_spr = _pants_slim ? spr_human_FR_idle_Pants_Slim : spr_human_FR_idle_Pants;
    } else if (sprite_index == spr_human_FR_work) {
        _pants_spr = _pants_slim ? spr_human_FR_work_Pants_Slim : spr_human_FR_work_Pants;
    } else if (sprite_index == spr_human_FR_sit) {
        _pants_spr = _pants_slim ? spr_human_FR_sit_Pants_Slim : spr_human_FR_sit_Pants;
    } else if (sprite_index == spr_human_FR_carry) {
        _pants_spr = _pants_slim ? spr_human_FR_carry_Pants_Slim : spr_human_FR_carry_Pants;
    } else if (sprite_index == spr_human_B_carry) {
        _pants_spr = _pants_slim ? spr_human_B_carry_Pants_Slim : spr_human_B_carry_Pants;
    }

    if (_pants_spr != -1 && sprite_exists(_pants_spr)) {
        if (!variable_instance_exists(id, "robe_color")) {
            robe_color = staff_random_scrub_color();
        }
        // штаны — затемнённый цвет робы: выглядит комплектом
        var _pants_c = make_color_rgb(
            round(color_get_red(robe_color)   * 0.72),
            round(color_get_green(robe_color) * 0.72),
            round(color_get_blue(robe_color)  * 0.72));
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
            color_get_red(_pants_c) / 255,
            color_get_green(_pants_c) / 255,
            color_get_blue(_pants_c) / 255);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
        var _pants_frame = image_index % sprite_get_number(_pants_spr);
        var _puvs = sprite_get_uvs(_pants_spr, _pants_frame);
        var _pu0 = 0; var _pv0 = 0; var _pu1 = 0; var _pv1 = 0;
        if (array_length(_puvs) >= 8 && max(_puvs[4], _puvs[5], _puvs[6], _puvs[7]) <= 2.0) {
            _pu0 = _puvs[4]; _pv0 = _puvs[5]; _pu1 = _puvs[6]; _pv1 = _puvs[7];
        } else {
            _pu0 = _puvs[0]; _pv0 = _puvs[1]; _pu1 = _puvs[2]; _pv1 = _puvs[3];
        }
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _pu0, _pv0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
            abs(_pu1 - _pu0), abs(_pv1 - _pv0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_pants_spr, _pants_frame,
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
        shader_reset();
    }

    var _scrub_spr = -1;
    // роба: спереди — М/Ж (у женской обозначена грудь), спина — общая
    var _scrub_w = (_outfit_sex == "F");

    if (sprite_index == spr_human_FR_walk) {
        _scrub_spr = _scrub_w ? spr_human_FR_walk_Scrub_Woman : spr_human_FR_walk_Scrub;
    } else if (sprite_index == spr_human_B_walk) {
        _scrub_spr = spr_human_B_walk_Scrub;
    } else if (sprite_index == spr_human_FR_idle) {
        _scrub_spr = _scrub_w ? spr_human_FR_idle_Scrub_Woman : spr_human_FR_idle_Scrub;
    } else if (sprite_index == spr_human_FR_work) {
        _scrub_spr = _scrub_w ? spr_human_FR_work_Scrub_Woman : spr_human_FR_work_Scrub;
    } else if (sprite_index == spr_human_FR_sit) {
        _scrub_spr = _scrub_w ? spr_human_FR_sit_Scrub_Woman : spr_human_FR_sit_Scrub;
    } else if (sprite_index == spr_human_FR_carry) {
        _scrub_spr = _scrub_w ? spr_human_FR_carry_Scrub_Woman : spr_human_FR_carry_Scrub;
    } else if (sprite_index == spr_human_B_carry) {
        _scrub_spr = spr_human_B_carry_Scrub;
    }

    if (_scrub_spr != -1 && sprite_exists(_scrub_spr)) {
        // Пакет 225: яркий цвет + узор (полоски/клетка) через шейдер.
        // Цвет и узор выдаются ЗДЕСЬ при первом кадре — Draw всегда
        // имеет контекст инстанса, и role к этому моменту уже назначена.
        if (!variable_instance_exists(id, "robe_color")) {
            robe_color = staff_random_scrub_color();
        }
        // Пакет 226: дикий рандомайзер — тип узора (0..4: гладь, полоски,
        // клетка, КРУЖКИ, РОМБИКИ) + размер + фазовый сдвиг.
        // Комбинация почти не повторяется у двух сотрудников.
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
        var _scrub_frame = image_index % sprite_get_number(_scrub_spr);
        var _uvs = sprite_get_uvs(_scrub_spr, _scrub_frame);
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
    draw_sprite_ext(_scrub_spr, _scrub_frame,
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
        shader_reset();
    }
}


// ═══════════════════════════════════════════════════════════════
// 4a-adm. ФОРМА АДМИНИСТРАТОРА (Пакет 253)
//   Белый комплект: кроксы + штаны + роба ассистента, все ЧИСТО БЕЛЫЕ,
//   одинаково у ВСЕХ админов (цвет фиксированный, узора нет).
//   До 253 у роли "admin" ветки одежды не было вообще — в par_staff
//   обрабатывались только doctor и assistant, поэтому админ ходил голым.
//   Набор спрайтов тот же, что у ассистента, поэтому слой руки
//   "4b. РУКА ПОВЕРХ РОБЫ" ниже теперь охватывает и админа.
// ═══════════════════════════════════════════════════════════════
else if (role == "admin") {


    // ── Пакет 229: КРОКСЫ сотрудникам (под штаны) ──
    var _cr_spr = -1;
    if (sprite_index == spr_human_FR_walk) {
        _cr_spr = spr_human_FR_walk_Crocs;
    } else if (sprite_index == spr_human_B_walk) {
        _cr_spr = spr_human_B_walk_Crocs;
    } else if (sprite_index == spr_human_FR_idle) {
        _cr_spr = spr_human_FR_idle_Crocs;
    } else if (sprite_index == spr_human_FR_work) {
        _cr_spr = spr_human_FR_work_Crocs;
    } else if (sprite_index == spr_human_FR_sit) {
        _cr_spr = spr_human_FR_sit_Crocs;
    } else if (sprite_index == spr_human_FR_carry) {
        _cr_spr = spr_human_FR_carry_Crocs;
    } else if (sprite_index == spr_human_B_carry) {
        _cr_spr = spr_human_B_carry_Crocs;
    }

    if (_cr_spr != -1 && sprite_exists(_cr_spr)) {
        // Пакет 255: БЕЗУСЛОВНО, а не "если переменной ещё нет".
        // Иначе у админа, нанятого до установки пакета, остались бы
        // старые случайные цвета из общей генерации внешности.
        crocs_color = _admin_white;
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
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
        var _cr_frame = image_index % sprite_get_number(_cr_spr);
        var _cruvs = sprite_get_uvs(_cr_spr, _cr_frame);
        var _cru0 = 0; var _crv0 = 0; var _cru1 = 0; var _crv1 = 0;
        if (array_length(_cruvs) >= 8 && max(_cruvs[4], _cruvs[5], _cruvs[6], _cruvs[7]) <= 2.0) {
            _cru0 = _cruvs[4]; _crv0 = _cruvs[5]; _cru1 = _cruvs[6]; _crv1 = _cruvs[7];
        } else {
            _cru0 = _cruvs[0]; _crv0 = _cruvs[1]; _cru1 = _cruvs[2]; _crv1 = _cruvs[3];
        }
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _cru0, _crv0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
            abs(_cru1 - _cru0), abs(_crv1 - _crv0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_cr_spr, _cr_frame,
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
        shader_reset();
    }

    // ── Пакет 228: ШТАНЫ под робой (унисекс), рисуются ДО робы.
    //    Два кроя: прямые (_Pants) и узкие (_Pants_Slim) — стиль
    //    выдаётся персонажу один раз (pants_style 0/1) ──
    if (!variable_instance_exists(id, "pants_style")) {
        if (variable_instance_exists(id, "is_female") && is_female) {
            pants_style = choose(1, 1, 0);   // женщины чаще узкие
        } else {
            pants_style = choose(0, 0, 1);   // мужчины чаще прямые
        }
    }
    var _pants_spr = -1;
    var _pants_slim = (pants_style == 1);
    if (sprite_index == spr_human_FR_walk) {
        _pants_spr = _pants_slim ? spr_human_FR_walk_Pants_Slim : spr_human_FR_walk_Pants;
    } else if (sprite_index == spr_human_B_walk) {
        _pants_spr = _pants_slim ? spr_human_B_walk_Pants_Slim : spr_human_B_walk_Pants;
    } else if (sprite_index == spr_human_FR_idle) {
        _pants_spr = _pants_slim ? spr_human_FR_idle_Pants_Slim : spr_human_FR_idle_Pants;
    } else if (sprite_index == spr_human_FR_work) {
        _pants_spr = _pants_slim ? spr_human_FR_work_Pants_Slim : spr_human_FR_work_Pants;
    } else if (sprite_index == spr_human_FR_sit) {
        _pants_spr = _pants_slim ? spr_human_FR_sit_Pants_Slim : spr_human_FR_sit_Pants;
    } else if (sprite_index == spr_human_FR_carry) {
        _pants_spr = _pants_slim ? spr_human_FR_carry_Pants_Slim : spr_human_FR_carry_Pants;
    } else if (sprite_index == spr_human_B_carry) {
        _pants_spr = _pants_slim ? spr_human_B_carry_Pants_Slim : spr_human_B_carry_Pants;
    }

    if (_pants_spr != -1 && sprite_exists(_pants_spr)) {
        robe_color = _admin_white;   // Пакет 255: безусловно белая
        // Пакет 253: у админа штаны БЕЛЫЕ, а не затемнённые под робу
        // (у ассистента здесь robe_color * 0.72 — комплект в тон).
        var _pants_c = _admin_white;
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
            color_get_red(_pants_c) / 255,
            color_get_green(_pants_c) / 255,
            color_get_blue(_pants_c) / 255);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pattern"), 0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_psize"), 1.0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"), 0.0);
        var _pants_frame = image_index % sprite_get_number(_pants_spr);
        var _puvs = sprite_get_uvs(_pants_spr, _pants_frame);
        var _pu0 = 0; var _pv0 = 0; var _pu1 = 0; var _pv1 = 0;
        if (array_length(_puvs) >= 8 && max(_puvs[4], _puvs[5], _puvs[6], _puvs[7]) <= 2.0) {
            _pu0 = _puvs[4]; _pv0 = _puvs[5]; _pu1 = _puvs[6]; _pv1 = _puvs[7];
        } else {
            _pu0 = _puvs[0]; _pv0 = _puvs[1]; _pu1 = _puvs[2]; _pv1 = _puvs[3];
        }
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uv0"), _pu0, _pv0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_uvspan"),
            abs(_pu1 - _pu0), abs(_pv1 - _pv0));
    // Пакет 243: режим явно: обувь=плоско, остальное=обычно (утечка u_simple)
    shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_simple"), 1);
    draw_sprite_ext(_pants_spr, _pants_frame,
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
        shader_reset();
    }

    var _scrub_spr = -1;
    // роба: спереди — М/Ж (у женской обозначена грудь), спина — общая
    var _scrub_w = (_outfit_sex == "F");

    if (sprite_index == spr_human_FR_walk) {
        _scrub_spr = _scrub_w ? spr_human_FR_walk_Scrub_Woman : spr_human_FR_walk_Scrub;
    } else if (sprite_index == spr_human_B_walk) {
        _scrub_spr = spr_human_B_walk_Scrub;
    } else if (sprite_index == spr_human_FR_idle) {
        _scrub_spr = _scrub_w ? spr_human_FR_idle_Scrub_Woman : spr_human_FR_idle_Scrub;
    } else if (sprite_index == spr_human_FR_work) {
        _scrub_spr = _scrub_w ? spr_human_FR_work_Scrub_Woman : spr_human_FR_work_Scrub;
    } else if (sprite_index == spr_human_FR_sit) {
        _scrub_spr = _scrub_w ? spr_human_FR_sit_Scrub_Woman : spr_human_FR_sit_Scrub;
    } else if (sprite_index == spr_human_FR_carry) {
        _scrub_spr = _scrub_w ? spr_human_FR_carry_Scrub_Woman : spr_human_FR_carry_Scrub;
    } else if (sprite_index == spr_human_B_carry) {
        _scrub_spr = spr_human_B_carry_Scrub;
    }

    if (_scrub_spr != -1 && sprite_exists(_scrub_spr)) {
        // Пакет 225: яркий цвет + узор (полоски/клетка) через шейдер.
        // Цвет и узор выдаются ЗДЕСЬ при первом кадре — Draw всегда
        // имеет контекст инстанса, и role к этому моменту уже назначена.
        robe_color = _admin_white;   // Пакет 255: безусловно белая
        // Пакет 226: дикий рандомайзер — тип узора (0..4: гладь, полоски,
        // клетка, КРУЖКИ, РОМБИКИ) + размер + фазовый сдвиг.
        // Комбинация почти не повторяется у двух сотрудников.
        scrub_pattern  = 0;    // Пакет 255: роба админа гладкая, без узора
        scrub_pat_size = 1.0;
        scrub_pat_phase = 0.0;
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
            1.0);
        shader_set_uniform_f(shader_get_uniform(sh_scrub_pattern, "u_pphase"),
            0.0);
        // Пакет 225 v5: границы текущего кадра для узора (без прыжков
        // между кадрами). sprite_get_uvs может вернуть 8 значений
        // [x,y,x,y,u0,v0,u1,v1] или 4 [u0,v0,u1,v1] — разбираем оба.
        var _scrub_frame = image_index % sprite_get_number(_scrub_spr);
        var _uvs = sprite_get_uvs(_scrub_spr, _scrub_frame);
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
    draw_sprite_ext(_scrub_spr, _scrub_frame,
                        _draw_x, _draw_y,
                        _face_dir * _draw_sx, _draw_sy,
                        0, c_white, 1);
        shader_reset();
    }
}




// ───────────────────────────────────────────────────────────────
// 4b. РУКА ПОВЕРХ РОБЫ АССИСТЕНТА И АДМИНА (Пакет 231, расширено в 253)
// Врачам НЕ рисуется: рукав халата впечен в халат и красится с ним.
// Пакет 253: админ носит ту же робу, что ассистент, — значит впечённую
// в неё руку тоже надо перекрыть, иначе она останется цветом робы.
// ───────────────────────────────────────────────────────────────
if (role == "assistant" || role == "admin") {
// ── Пакет 231: РУКА ПОВЕРХ РОБЫ (отдельный слой, без шейдера).
// Спрайт содержит руку БЕЗ части плеча, скрытой под рукавом робы:
// серое предплечье + кожаная кисть. Никогда не красится.
var _arm_spr = -1;
if (sprite_index == spr_human_FR_walk) {
    _arm_spr = spr_human_FR_walk_ArmTop;
} else if (sprite_index == spr_human_B_walk) {
    _arm_spr = spr_human_B_walk_ArmTop;
} else if (sprite_index == spr_human_FR_idle) {
    _arm_spr = spr_human_FR_idle_ArmTop;
} else if (sprite_index == spr_human_FR_work) {
    _arm_spr = spr_human_FR_work_ArmTop;
} else if (sprite_index == spr_human_FR_sit) {
    _arm_spr = spr_human_FR_sit_ArmTop;
} else if (sprite_index == spr_human_FR_carry) {
    _arm_spr = spr_human_FR_carry_ArmTop;
} else if (sprite_index == spr_human_B_carry) {
    _arm_spr = spr_human_B_carry_ArmTop;
}

if (_arm_spr != -1 && sprite_exists(_arm_spr)) {
    draw_sprite_ext(_arm_spr, image_index % sprite_get_number(_arm_spr),
                    _draw_x, _draw_y,
                    _face_dir * _draw_sx, _draw_sy,
                    0, c_white, 1);
}
}

// ───────────────────────────────────────────────────────────────
// 5. СЛОИ ГОЛОВЫ (волосы/нос/глаза/рот)
//    — в той же точке что и тело, с тем же скейлом, с тем же смещением
//    — смещение _fx/_fy накидывается сверху (для особых поз e.g. сидение)
// ───────────────────────────────────────────────────────────────
var _head_x = _draw_x + _fx;
var _head_y = _draw_y + _fy;

if (_is_back_view) {
    // СЗАДИ: только волосы
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
    // АНФАС: нос, глаза, рот, потом волосы поверх
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
// 6. ШКАЛА ПРОГРЕССА ДЕЙСТВИЯ
// ───────────────────────────────────────────────────────────────
if (script_exists(actor_draw_action_progress)) {
    actor_draw_action_progress();
}

// ───────────────────────────────────────────────────────────────
// 7. ТАБЛИЧКА "ЧТО НЕСУ"
// ───────────────────────────────────────────────────────────────
if (font_exists(fnt_main)) draw_set_font(fnt_main);

var _carry_item = "";
var _carry_qty  = 0;

if (object_index == obj_player) {
    _carry_item = global.player_carry_item;
    _carry_qty  = global.player_carry_qty;

    // пульсация шкафов, если игрок несёт препарат
    if (_carry_item != "" && _carry_qty > 0) {
        var _pulse = 0.35 + 0.25 * sin(current_time * 0.006);
        with (obj_storage_cabinet) {
            if (!instance_exists(id)) continue;
            var _cnt = is_struct(storage_inventory) ? inventory_get_amount(storage_inventory, _carry_item) : 0;
            if (_cnt >= global.RESTOCK_MAX) continue;
            gpu_set_blendmode(bm_add);
            draw_set_color(make_color_rgb(120, 220, 120));
            draw_set_alpha(_pulse);
            draw_ellipse(x - 42, y - 28, x + 42, y + 10, false);
            draw_set_alpha(1);
            gpu_set_blendmode(bm_normal);
        }
    }
} else if (object_index == obj_staff_assistant) {
    if (variable_instance_exists(id, "assistant_state")
    && (assistant_state == "restock_picking_up"
        || assistant_state == "restock_going_to_cabinet"
        || assistant_state == "restock_putting_in")) {
        if (variable_instance_exists(id, "restock_item_id") && restock_item_id != ""
        && variable_instance_exists(id, "restock_qty") && restock_qty > 0) {
            _carry_item = restock_item_id;
            _carry_qty  = restock_qty;
        }
    }
}

if (_carry_item != "" && _carry_qty > 0) {
    var _carry_nm = "ПРЕПАРАТ";
    if (is_struct(global.item_db) && variable_struct_exists(global.item_db, _carry_item)) {
        _carry_nm = variable_struct_get(global.item_db, _carry_item).name_ru;
    }

    var _label = _carry_nm + "  " + string(_carry_qty) + " шт.";

    var _wood_dark  = make_color_rgb(74, 49, 31);
    var _wood_light = make_color_rgb(150, 107, 73);
    var _paper      = make_color_rgb(242, 232, 214);
    var _line_dark  = make_color_rgb(58, 39, 24);
    var _text_dark  = make_color_rgb(50, 38, 28);

    var _pad_x = 14;
    var _pad_y = 7;
    var _text_w = string_width(_label);
    var _text_h = string_height(_label);
    var _tw = _text_w + _pad_x * 2;
    var _th = _text_h + _pad_y * 2;
    var _bx1 = x - _tw * 0.5;
    // ═══════════════════════════════════════════════════════
    // ПАКЕТ 284: ТАБЛИЧКА ОПУЩЕНА К ГОЛОВЕ
    //
    // Раньше высота считалась от границы ХОЛСТА спрайта:
    // sprite_get_yoffset() = 300 при высоте холста 400. Но сама
    // фигура начинается только с y ≈ 63–69 — выше неё лежит
    // около 63 px пустоты. При масштабе 0.5 это лишние ~32 px,
    // и табличка висела заметно выше головы.
    //
    // Теперь пустой запас вычитается, и табличка стоит над
    // реальной макушкой. Запас одинаков у всех поз (холст
    // 400×400, yorigin 300), поэтому константа безопасна.
    // Масштабируется тем же _draw_sy, что и сам спрайт, поэтому
    // работает и для высоких, и для низких персонажей.
    // ═══════════════════════════════════════════════════════

    // Пустое место над макушкой внутри холста спрайта.
    var _sprite_empty_top = 60;

    var _sprite_top_y =
        _draw_y
        - (sprite_get_yoffset(sprite_index) - _sprite_empty_top) * _draw_sy;

    // Зазор между головой и табличкой.
    var _label_gap = 10;
    var _by1 = _sprite_top_y - _th - _label_gap;
    var _bx2 = _bx1 + _tw;
    var _by2 = _by1 + _th;

    // Тень таблички
    draw_set_alpha(0.22);
    draw_set_color(c_black);
    draw_roundrect_ext(_bx1 + 2, _by1 + 3, _bx2 + 2, _by2 + 3, 8, 8, false);
    draw_set_alpha(1);

    // Рамка двойная
    draw_set_color(_wood_dark);
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, false);
    draw_set_color(_wood_light);
    draw_roundrect_ext(_bx1 + 2, _by1 + 2, _bx2 - 2, _by2 - 2, 6, 6, false);

    // Бумага
    draw_set_color(_paper);
    draw_roundrect_ext(_bx1 + 5, _by1 + 5, _bx2 - 5, _by2 - 5, 5, 5, false);

    // Контур
    draw_set_color(_line_dark);
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, true);

    // Текст строго по центру
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_text_dark);
    draw_text((_bx1 + _bx2) * 0.5, (_by1 + _by2) * 0.5 + 1, _label);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ───────────────────────────────────────────────────────────────
// 9. ФИНАЛЬНЫЙ СБРОС
// ───────────────────────────────────────────────────────────────
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
gpu_set_blendmode(bm_normal);