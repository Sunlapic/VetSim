// ═══════════════════════════════════════════════════════════════
// par_staff → Draw  (отрисовка персонала с вариативным телосложением)
// Разделы с номерами 1–9 — чтобы легко находить и менять по частям.
// ═══════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────
// 0. БАЗОВЫЕ ВЕЛИЧИНЫ И ПРОВЕРКИ
// ───────────────────────────────────────────────────────────────
var _s = 0.5;

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
    draw_sprite_ext(sprite_index, image_index,
                    _draw_x, _draw_y,
                    _face_dir * _draw_sx, _draw_sy,
                    0, c_white, 1);
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
    // Верхняя граница спрайта персонажа
var _sprite_top_y =
    _draw_y
    - sprite_get_yoffset(sprite_index) * _draw_sy;

// Табличка целиком располагается над головой
var _label_gap = 18;
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