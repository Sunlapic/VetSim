/// Draw GUI obj_UI_Tablet

if (!visible || target_id == noone || !instance_exists(target_id)) {
    visible = false;
    target_id = noone;
    exit;
}

if (font_exists(fnt_main)) {
    draw_set_font(fnt_main);
}
// Если планшет только что открыли — блокируем клик на этот кадр/секунду
if (!tablet_was_open || tablet_last_target_id != target_id) {
    tablet_was_open = true;
    tablet_last_target_id = target_id;
    tablet_click_lock = max(tablet_click_lock, tablet_open_delay_frames);
}

// ─────────────────────────────────────────────
// ЛОКАЛЬНЫЕ ФУНКЦИИ
// ─────────────────────────────────────────────

function tablet_draw_xp_bar(_x, _y, _w, _h, _value, _max_value) {
    var _ratio = 0;

    if (_max_value > 0) {
        _ratio = clamp(_value / _max_value, 0, 1);
    }

    draw_set_color(make_color_rgb(210, 198, 180));
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 8, 8, false);

    draw_set_color(make_color_rgb(80, 140, 220));
    draw_roundrect_ext(_x, _y, _x + (_w * _ratio), _y + _h, 8, 8, false);

    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 8, 8, true);
}
function tablet_draw_star(_x, _y, _r, _col) {
    draw_set_color(_col);

    var _p = 5;
    var _a = 360 / _p;

    draw_primitive_begin(pr_trianglefan);
    draw_vertex(_x, _y);

    for (var i = 0; i <= _p; i++) {
        var _r1 = degtorad(i * _a - 90);
        draw_vertex(_x + cos(_r1) * _r, _y + sin(_r1) * _r);

        var _r2 = degtorad(i * _a + _a * 0.5 - 90);
        draw_vertex(_x + cos(_r2) * (_r * 0.45), _y + sin(_r2) * (_r * 0.45));
    }

    draw_primitive_end();
}

function tablet_draw_portrait_part(_spr, _x, _y, _w, _h, _zoom, _src_x, _src_y, _col) {
    if (_spr == -1) return;
    if (!sprite_exists(_spr)) return;

    var _scale = _zoom;
    var _sw = _w / _scale;
    var _sh = _h / _scale;

    draw_sprite_general(
        _spr, 0,
        _src_x, _src_y, _sw, _sh,
        _x, _y, _scale, _scale, 0,
        _col, _col, _col, _col, 1
    );
}

function tablet_get_skill_value(_inst, _role, _index) {

    switch (_role) {

        case "owner":

            switch (_index) {

                case 0:
                    if (variable_instance_exists(_inst, "stat_money")) {
                        return clamp(round(_inst.stat_money / 50), 1, 10);
                    }
                    return 5;

                case 1:
                    if (variable_instance_exists(_inst, "free_time")) {
                        return clamp(_inst.free_time, 1, 10);
                    }
                    return 5;

                case 2:
                    if (variable_instance_exists(_inst, "stat_patience")) {
                        return clamp(ceil(_inst.stat_patience / 10), 1, 10);
                    }
                    return 5;
            }

        break;

        case "doctor":
            if (variable_instance_exists(_inst, "skills")) {
                if (_index < array_length(_inst.skills)) {
                    return clamp(_inst.skills[_index], 1, 10);
                }
            }
            return 1;
        break;

        default:

            if (variable_instance_exists(_inst, "skills")) {
                if (_index < array_length(_inst.skills)) {
                    return clamp(_inst.skills[_index], 0, 10);
                }
            }

            return 0;

    }

    return 0;
}

function tablet_get_disease_name(_disease_id) {
    if (!variable_global_exists("med_db")) return "Неизвестно";
    if (!is_struct(global.med_db)) return "Неизвестно";
    if (!variable_struct_exists(global.med_db, "diseases")) return "Неизвестно";
    if (!variable_struct_exists(global.med_db.diseases, _disease_id)) return "Неизвестно";

    var _d = variable_struct_get(global.med_db.diseases, _disease_id);

    if (variable_struct_exists(_d, "name_ru")) {
        return string(_d.name_ru);
    }

    return "Неизвестно";
}

function tablet_get_visible_symptom_text(_inst) {
    var _result = "";

    if (!variable_instance_exists(_inst, "visible_symptoms")) {
        return "Нет данных";
    }

    var _arr = _inst.visible_symptoms;

    if (!is_array(_arr) || array_length(_arr) <= 0) {
        return "Нет данных";
    }

    for (var i = 0; i < array_length(_arr); i++) {
        var _sym_id = _arr[i];
        var _sym_name = "Неизвестный симптом";

        if (variable_global_exists("med_db") && is_struct(global.med_db)) {
            if (variable_struct_exists(global.med_db, "symptoms")) {
                if (variable_struct_exists(global.med_db.symptoms, _sym_id)) {
                    var _sym = variable_struct_get(global.med_db.symptoms, _sym_id);

                    if (variable_struct_exists(_sym, "name_ru")) {
                        _sym_name = string(_sym.name_ru);
                    }
                }
            }
        }

        if (i > 0) _result += "\n";
        _result += "- " + _sym_name;
    }

    return _result;
}

function tablet_case_has_action_done_this_visit(_case, _action_id) {
    if (!is_struct(_case)) return false;
    if (!variable_struct_exists(_case, "visit_treatments_done")) return false;

    for (var i = 0; i < array_length(_case.visit_treatments_done); i++) {
        if (_case.visit_treatments_done[i] == _action_id) {
            return true;
        }
    }

    return false;
}

function tablet_get_treatment_feedback_state(_case, _action_id) {
    if (!is_struct(_case)) return 0;

    if (variable_struct_exists(_case, "visit_treatment_feedback_bad_ids")) {
        for (var i = 0; i < array_length(_case.visit_treatment_feedback_bad_ids); i++) {
            if (_case.visit_treatment_feedback_bad_ids[i] == _action_id) {
                return -1;
            }
        }
    }

    if (variable_struct_exists(_case, "visit_treatment_feedback_ok_ids")) {
        for (var j = 0; j < array_length(_case.visit_treatment_feedback_ok_ids); j++) {
            if (_case.visit_treatment_feedback_ok_ids[j] == _action_id) {
                return 1;
            }
        }
    }

    return 0;
}

function tablet_is_condition_known(_animal) {
    if (!instance_exists(_animal)) return false;
    if (!variable_instance_exists(_animal, "current_case")) return false;
    if (!is_struct(_animal.current_case)) return false;
    if (!variable_struct_exists(_animal.current_case, "completed_diagnostics")) return false;

    var _arr = _animal.current_case.completed_diagnostics;

    for (var i = 0; i < array_length(_arr); i++) {
        if (_arr[i] == "diag_physical_exam") {
            return true;
        }
    }

    return false;
}
function tablet_apply_wrong_treatment(_animal_id, _action_id) {
    if (!instance_exists(_animal_id)) return false;
    if (!variable_instance_exists(_animal_id, "current_case")) return false;
    if (!is_struct(_animal_id.current_case)) return false;

    var _case = _animal_id.current_case;

    if (!variable_struct_exists(_case, "visit_treatments_done")) {
        _case.visit_treatments_done = [];
    }

    if (!variable_struct_exists(_case, "visit_procedure_log")) {
        _case.visit_procedure_log = [];
    }

    if (!variable_struct_exists(_case, "visit_treatment_feedback_ok_ids")) {
        _case.visit_treatment_feedback_ok_ids = [];
    }

    if (!variable_struct_exists(_case, "visit_treatment_feedback_bad_ids")) {
        _case.visit_treatment_feedback_bad_ids = [];
    }

    // Нельзя жать одну и ту же неправильную процедуру дважды за визит
    for (var i = 0; i < array_length(_case.visit_treatments_done); i++) {
        if (_case.visit_treatments_done[i] == _action_id) {
            return false;
        }
    }

    array_push(_case.visit_treatments_done, _action_id);

    array_push(_case.visit_procedure_log, {
        proc_type : "treatment_wrong",
        proc_id : _action_id,
        proc_name_ru : db_get_treatment_action_name(_action_id) + " (ошибка)"
    });

    var _already_bad = false;
    for (var j = 0; j < array_length(_case.visit_treatment_feedback_bad_ids); j++) {
        if (_case.visit_treatment_feedback_bad_ids[j] == _action_id) {
            _already_bad = true;
            break;
        }
    }

    if (!_already_bad) {
        array_push(_case.visit_treatment_feedback_bad_ids, _action_id);
    }

    var _damage = 8;
    _case.condition = clamp(_case.condition - _damage, 0, 100);

    if (_case.condition <= 0) {
        _case.case_status = "critical";
    } else {
        _case.case_status = "worsened";
    }

    _animal_id.current_case = _case;
    _animal_id.condition = _case.condition;

    animal_apply_case(_animal_id, _case);
    return true;
}

function tablet_draw_action_button(_x1, _y1, _x2, _y2, _label, _hovered, _enabled) {
    var _fill = make_color_rgb(240, 232, 214);

    if (!_enabled) {
        _fill = make_color_rgb(190, 185, 176);
    } else if (_hovered) {
        _fill = make_color_rgb(248, 238, 220);
    }

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);

    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    draw_set_color(_enabled ? make_color_rgb(50, 38, 28) : make_color_rgb(110, 110, 110));
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    draw_text_ext_transformed(
        _x1 + 8,
        _y1 + 4,
        _label,
        16,
        (_x2 - _x1) - 16,
        1,
        1,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function tablet_draw_treatment_button(_x1, _y1, _x2, _y2, _label, _hovered, _enabled, _feedback_state) {
    var _fill = make_color_rgb(240, 232, 214);
    var _line = make_color_rgb(58, 39, 24);
    var _text_col = make_color_rgb(50, 38, 28);

    if (_feedback_state > 0) {
        _fill = make_color_rgb(206, 232, 198);
        _line = make_color_rgb(58, 110, 62);
    }
    else if (_feedback_state < 0) {
        _fill = make_color_rgb(238, 206, 198);
        _line = make_color_rgb(140, 62, 56);
    }
    else if (!_enabled) {
        _fill = make_color_rgb(190, 185, 176);
        _text_col = make_color_rgb(110, 110, 110);
    }
    else if (_hovered) {
        _fill = make_color_rgb(248, 238, 220);
    }

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);

    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    draw_set_color(_text_col);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    draw_text_ext_transformed(
        _x1 + 8,
        _y1 + 4,
        _label,
        16,
        (_x2 - _x1) - 16,
        1,
        1,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
function tablet_add_fly_effect(_start_x, _start_y, _end_x, _end_y, _symbol, _color) {
    array_push(fly_effects, {
        start_x : _start_x,
        start_y : _start_y,
        end_x : _end_x,
        end_y : _end_y,

        control_x : lerp(_start_x, _end_x, 0.5),
        control_y : min(_start_y, _end_y) - 70,

        symbol : _symbol,
        color : _color,

        timer : 0,
        timer_max : max(1, round(room_speed * 0.65)),

        scale_start : 1.0,
        scale_end : 0.82,

        flash_done : false
    });
}
// ─────────────────────────────────────────────
// ЛЕЙАУТ
// ─────────────────────────────────────────────

var _ui_scale = ui_scale;

var _photo_x_off = -265;
var _photo_y_off = -190;
var _photo_w = 65;
var _photo_h = 90;

var _en_bar_y_off = 15;

var _text_x_off = -190;
var _text_y_off = -185;
var _text_scale = 1.2;

var _star_x_shift = 65;
var _star_y_off = 35;

var _skills_y_off = 115;
var _skills_step = 18;
var _bar_offset = 100;

var _soc_x_off = 30;
var _soc_y_off = -165;

var _px_cam = variable_instance_exists(target_id, "portrait_x") ? target_id.portrait_x : 0;
var _py_cam = variable_instance_exists(target_id, "portrait_y") ? target_id.portrait_y : 50;
var _pz_cam = variable_instance_exists(target_id, "portrait_zoom") ? target_id.portrait_zoom : 0.7;

var _cx = display_get_gui_width() * 0.5;
var _cy = display_get_gui_height() * 0.5;

// ─────────────────────────────────────────────
// 1. ПЛАНШЕТ
// ─────────────────────────────────────────────
draw_sprite_ext(my_sprite, 0, _cx, _cy, _ui_scale, _ui_scale, 0, c_white, 1);

// ─────────────────────────────────────────────
// 2. КНОПКА ЗАКРЫТИЯ
// ─────────────────────────────────────────────
var _btnX = _cx + (285 * _ui_scale);
var _btnY = _cy - (205 * _ui_scale);
var _bS = 10 * _ui_scale;

var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

var _hvr = point_distance(_mx, _my, _btnX, _btnY) <= (_bS * 1.5);

draw_set_color(_hvr ? c_gray : c_dkgray);
draw_rectangle(_btnX - _bS, _btnY - _bS, _btnX + _bS, _btnY + _bS, false);

draw_set_color(c_red);
draw_line_width(_btnX - 6, _btnY - 6, _btnX + 6, _btnY + 6, 2 * _ui_scale);
draw_line_width(_btnX + 6, _btnY - 6, _btnX - 6, _btnY + 6, 2 * _ui_scale);

if (_hvr && tablet_click_lock <= 0 && mouse_check_button_pressed(mb_left)) {
    tablet_click_lock = 5;
    visible = false;
    target_id = noone;
    exit;
}

// ─────────────────────────────────────────────
// 3. РОЛЬ / ЦВЕТ СКОТЧА / НАЗВАНИЯ НАВЫКОВ
// ─────────────────────────────────────────────
var _role_rus = "СОТРУДНИК";
var _tape_c = c_white;
var _tape_a = 0.8;
var _skill_names = [];

switch (target_id.role) {
    case "doctor":
        _role_rus = "ВРАЧ";
        _tape_c = c_blue;
        _skill_names = [
            "Терапия", "Процедуры", "Хирургия", "Офтальмология", "Отоларингология",
            "Дерматология", "Инфекции/токсик.", "Анестезиология", "Лаборатория", "Стоматология"
        ];
    break;

    case "admin":
        _role_rus = "АДМИН";
        _tape_c = c_fuchsia;
        _skill_names = [
             "Регистрация", "Касса", "Скор.ходьбы",
            "Общение", "Расписание", "Документы",
           "Продажи", "Конфликты", "Внимание", "Стрессоуст."
         ];
    break;

    case "assistant":
        _role_rus = "АССИСТЕНТ";
        _tape_c = c_white;
        _skill_names = [
            "Помощь-Тер.", "Процедуры", "Помощь-Лаб.", "Стационар", "Анестезия"
        ];
    break;

    case "animal":
        _role_rus = "ПАЦИЕНТ";
        _tape_c = c_white;
        _tape_a = 0.1;
        _skill_names = [
            "Здоровье", "Сытость", "Настроение"
        ];
    break;

    case "owner":
        _role_rus = "ВЛАДЕЛЕЦ";
        _tape_c = c_aqua;
        _tape_a = 0.8;
        _skill_names = [
            "Деньги", "Время", "Терпение"
        ];
    break;
}

// ─────────────────────────────────────────────
// 4. ПОЛАРОИД
// ─────────────────────────────────────────────
var _frameX = _cx + (_photo_x_off * _ui_scale);
var _frameY = _cy + (_photo_y_off * _ui_scale);

var _pw = _photo_w * _ui_scale;
var _ph = _photo_h * _ui_scale;

draw_set_color(make_color_rgb(255, 252, 210));
draw_rectangle(_frameX, _frameY, _frameX + _pw, _frameY + _ph, false);

draw_set_color(make_color_rgb(60, 40, 20));
draw_line_width(_frameX, _frameY, _frameX + _pw, _frameY, 3);
draw_line_width(_frameX, _frameY + _ph, _frameX + _pw, _frameY + _ph, 3);
draw_line_width(_frameX, _frameY, _frameX, _frameY + _ph, 3);
draw_line_width(_frameX + _pw, _frameY, _frameX + _pw, _frameY + _ph, 3);

var _ix = _frameX + (5 * _ui_scale);
var _iy = _frameY + (5 * _ui_scale);
var _iw = _pw - (10 * _ui_scale);
var _ih = _iw * 1.15;

draw_set_color(make_color_rgb(180, 180, 180));
draw_rectangle(_ix, _iy, _ix + _iw, _iy + _ih, false);

draw_set_color(c_black);
draw_rectangle(_ix, _iy, _ix + _iw, _iy + _ih, true);

// ─────────────────────────────────────────────
// 5. ФОТО
// ─────────────────────────────────────────────
if (variable_instance_exists(target_id, "my_baked_portrait")
&& target_id.my_baked_portrait != -1
&& sprite_exists(target_id.my_baked_portrait)) {
    draw_sprite_stretched(target_id.my_baked_portrait, 0, _ix, _iy, _iw, _ih);
} else {
    if (target_id.role == "animal") {
        if (sprite_exists(target_id.sprite_index)) {
            tablet_draw_portrait_part(target_id.sprite_index, _ix, _iy, _iw, _ih, _pz_cam, _px_cam, _py_cam, c_white);
        }
    } else {
        tablet_draw_portrait_part(spr_human_FR_walk, _ix, _iy, _iw, _ih, _pz_cam, _px_cam, _py_cam, c_white);

        if (variable_instance_exists(target_id, "my_nose") && sprite_exists(target_id.my_nose)) {
            tablet_draw_portrait_part(target_id.my_nose, _ix, _iy, _iw, _ih, _pz_cam, _px_cam, _py_cam, c_white);
        }

        if (variable_instance_exists(target_id, "my_eyes") && sprite_exists(target_id.my_eyes)) {
            tablet_draw_portrait_part(target_id.my_eyes, _ix, _iy, _iw, _ih, _pz_cam, _px_cam, _py_cam, c_white);
        }

        if (variable_instance_exists(target_id, "my_mouth") && sprite_exists(target_id.my_mouth)) {
            tablet_draw_portrait_part(target_id.my_mouth, _ix, _iy, _iw, _ih, _pz_cam, _px_cam, _py_cam, c_white);
        }

        if (variable_instance_exists(target_id, "my_hair") && sprite_exists(target_id.my_hair)) {
            var _hair_c = c_white;

            if (variable_instance_exists(target_id, "hair_color")) {
                _hair_c = target_id.hair_color;
            }

            tablet_draw_portrait_part(target_id.my_hair, _ix, _iy, _iw, _ih, _pz_cam, _px_cam, _py_cam, _hair_c);
        }
    }
}

// Скотч
draw_set_color(_tape_c);
draw_set_alpha(_tape_a);
draw_line_width(_frameX - 3, _frameY + 8, _frameX + 15, _frameY - 3, 6 * _ui_scale);
draw_line_width(_frameX + _pw - 15, _frameY + _ph + 3, _frameX + _pw + 3, _frameY + _ph - 8, 6 * _ui_scale);
draw_set_alpha(1.0);

// ─────────────────────────────────────────────

// 6. ЭНЕРГИЯ (только для персонала; у владельцев и питомцев не показываем)

// ─────────────────────────────────────────────
var _is_staff_role = false;
if (variable_instance_exists(target_id, "role")) {
    var _r = target_id.role;
    _is_staff_role = (_r == "doctor" || _r == "assistant" || _r == "admin");
}

// Кандидат — тоже пропускаем
var _cand_ind = asset_get_index("obj_staff_candidate");
if (_cand_ind >= 0 && object_exists(_cand_ind)) {
    if (target_id.object_index == _cand_ind) {
        _is_staff_role = false;
    }
}

if (_is_staff_role
&& variable_instance_exists(target_id, "stat_energy")
&& variable_instance_exists(target_id, "energy_max")) {

    var _eby = _frameY + _ph + (_en_bar_y_off * _ui_scale);

    var _ene_cur = target_id.stat_energy;
    var _ene_max = target_id.energy_max;
    if (_ene_max <= 0) _ene_max = 100;
    _ene_cur = clamp(_ene_cur, 0, _ene_max);
    var _ene_ratio = _ene_cur / _ene_max;

    // Цвет по состоянию
    var _is_t = (variable_instance_exists(target_id, "is_tired") && target_id.is_tired);
    var _is_e = (variable_instance_exists(target_id, "is_exhausted") && target_id.is_exhausted);
    var _bar_color = make_color_rgb(62, 112, 74);
    var _txt_color = make_color_rgb(62, 112, 74);
    if (_is_e) {
        _bar_color = make_color_rgb(148, 74, 64);
        _txt_color = make_color_rgb(148, 74, 64);
    } else if (_is_t) {
        _bar_color = make_color_rgb(180, 140, 64);
        _txt_color = make_color_rgb(180, 140, 64);
    }

    // Фон полоски
    draw_set_color(make_color_rgb(220, 220, 220));
    draw_roundrect_ext(_frameX, _eby, _frameX + _pw, _eby + 8 * _ui_scale, 8, 8, false);

    // Заполненная часть
    draw_set_color(_bar_color);
    draw_roundrect_ext(_frameX, _eby, _frameX + (_pw * _ene_ratio), _eby + 8 * _ui_scale, 8, 8, false);

    // Рамка
    draw_set_color(c_black);
    draw_roundrect_ext(_frameX, _eby, _frameX + _pw, _eby + 8 * _ui_scale, 8, 8, true);

    // Подпись "ЭНЕРГИЯ" (используем текущий шрифт и выравнивание — не переключаем!)
    draw_set_color(c_dkgray);
    var _ene_label_x = _frameX;
    draw_text_transformed(
        _ene_label_x, _eby - (12 * _ui_scale),
        "ЭНЕРГИЯ",
        0.5 * _ui_scale, 0.5 * _ui_scale, 0
    );
    // Цифры " 42/120" цветом справа (ширина "ЭНЕРГИЯ" в масштабе 0.5 ~ 7*6*0.5 = 21px)
    var _label_w = 42 * _ui_scale; // подобрано под "ЭНЕРГИЯ" с запасом
    draw_set_color(_txt_color);
    draw_text_transformed(
        _ene_label_x + _label_w, _eby - (12 * _ui_scale),
        string(floor(_ene_cur)) + "/" + string(round(_ene_max)),
        0.5 * _ui_scale, 0.5 * _ui_scale, 0
    );
}

// ═══════════════════════════════════════════════════════════════
// 2. ОТДЕЛЬНАЯ КАРТОЧКА ВЛАДЕЛЬЦА
// ═══════════════════════════════════════════════════════════════

if (
    variable_instance_exists(target_id, "role")
    && target_id.role == "owner"
) {
    tablet_draw_owner_card(
        id,
        target_id,
        _cx,
        _cy,
        _ui_scale,
        _frameX,
        _frameY,
        _pw,
        _ph,
        _mx,
        _my
    );

    // Не даём старым универсальным блокам ниже снова нарисовать
    // «НАВЫКИ», деньги, время и прежнюю правую колонку владельца.
    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);
    exit;
}

// ═══════════════════════════════════════════════════════════════
// 2. ОТДЕЛЬНАЯ КАРТОЧКА ПИТОМЦА
// ═══════════════════════════════════════════════════════════════

if (
    variable_instance_exists(target_id, "role")
    && target_id.role == "animal"
) {
    tablet_draw_animal_card(
        id,
        target_id,
        _cx,
        _cy,
        _ui_scale,
        _frameX,
        _frameY,
        _pw,
        _ph,
        _mx,
        _my
    );

    // Старый блок животного ниже больше не должен рисоваться повторно.
    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);
    exit;
}
// ═══════════════════════════════════════════════════════════════
// 2. ОТДЕЛЬНАЯ КАРТОЧКА СОТРУДНИКА
// ═══════════════════════════════════════════════════════════════

var _is_staff_card = false;

if (variable_instance_exists(target_id, "role")) {
    _is_staff_card = (
        target_id.role == "doctor"
        || target_id.role == "assistant"
        || target_id.role == "admin"
    );
}

// Кандидаты продолжают использовать интерфейс найма.
if (target_id.object_index == obj_staff_candidate) {
    _is_staff_card = false;
}

if (_is_staff_card) {
    tablet_draw_staff_card(
        id,
        target_id,
        _cx,
        _cy,
        _ui_scale,
        _frameX,
        _frameY,
        _pw,
        _ph
    );

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);
    exit;
}

// ─────────────────────────────────────────────
// 7. ТЕКСТ СЛЕВА
// ─────────────────────────────────────────────
draw_set_color(c_black);
draw_set_halign(fa_left);

var _tx = _cx + (_text_x_off * _ui_scale);
var _ty = _cy + (_text_y_off * _ui_scale);
var _tsc = _text_scale * _ui_scale;

var _name_str = "НЕИЗВЕСТНО";
if (variable_instance_exists(target_id, "char_name")) {
    _name_str = string_upper(string(target_id.char_name));
}
// ─────────────────────────────────────────────
// 8. НАВЫКИ (в скрипте tablet_draw_staff_skills)
// ─────────────────────────────────────────────
var _skills_x = _tx - 60 * _ui_scale;
var _skills_y = _cy + (_text_y_off + _skills_y_off) * _ui_scale;
var _skills_width = 280 * _ui_scale;

tablet_draw_staff_skills(
    target_id,
    _skills_x,
    _skills_y,
    _skills_width,
    _ui_scale
);
// ─────────────────────────────────────────────
// 9. СОЦИАЛЬНЫЙ/ПРАВЫЙ БЛОК
// ─────────────────────────────────────────────
var _rx = _cx + (_soc_x_off * _ui_scale);
var _rs = _cy + (_soc_y_off * _ui_scale);

draw_set_color(make_color_rgb(180, 160, 140));
draw_line(_rx, _rs, _rx + 220 * _ui_scale, _rs);

draw_set_color(c_black);

var _soc_title = (target_id.role == "animal") ? "КАРТА ПАЦИЕНТА:" : "ЛИЧНЫЕ ОСОБЕННОСТИ:";
draw_text_transformed(_rx, _rs - 40, _soc_title, 0.7 * _ui_scale, 0.7 * _ui_scale, 0);

// ─────────────────────────────────────────────
// 10. ЖИВОТНОЕ — ОТДЕЛЬНЫЙ КРУПНЫЙ ЛЕЙАУТ
// ─────────────────────────────────────────────

if (target_id.role == "animal") {

    var _age_str_an = "?";

if (variable_instance_exists(target_id, "age")) {
    _age_str_an = string(target_id.age);
}

     // Левая часть: 2 прямоугольника
    var _breed_str = variable_instance_exists(target_id, "breed") ? string(target_id.breed) : "?";
    var _problem_str = variable_instance_exists(target_id, "problem") ? string(target_id.problem) : "?";
    var _cond = variable_instance_exists(target_id, "condition") ? round(target_id.condition) : 100;
    var _reveal = variable_instance_exists(target_id, "reveal_level") ? target_id.reveal_level : 0;
    var _confirmed = variable_instance_exists(target_id, "diagnosis_confirmed") ? target_id.diagnosis_confirmed : false;

    var _disease_name = "Неизвестно";
    if (_confirmed && variable_instance_exists(target_id, "hidden_disease_id")) {
        _disease_name = tablet_get_disease_name(target_id.hidden_disease_id);
    }

    var _symptoms_text = tablet_get_visible_symptom_text(target_id);

    var _cond_known = tablet_is_condition_known(target_id);
    var _cond_text = _cond_known ? (string(_cond) + "%") : "Неизвестно";

    var _reveal_text = "Необследован";

switch (_reveal) {
    case 0: _reveal_text = "Необследован"; break;
    case 1: _reveal_text = "В стадии обследования"; break;
    case 2: _reveal_text = "Диагноз под вопросом"; break;
    default: _reveal_text = "Обследован"; break;
}


    var _diagnosis_line = _confirmed ? _disease_name : "Не подтверждён";

    // Верхний маленький прямоугольник
    var _info_x1 = _tx;
    var _info_y1 = _ty + 8;
    var _info_w  = 202 * _ui_scale;
    var _info_h  = 68 * _ui_scale;
    var _info_x2 = _info_x1 + _info_w;
    var _info_y2 = _info_y1 + _info_h;

    draw_set_color(make_color_rgb(248, 240, 224));
    draw_roundrect_ext(_info_x1, _info_y1, _info_x2, _info_y2, 12, 12, false);

    draw_set_color(make_color_rgb(180, 160, 140));
    draw_roundrect_ext(_info_x1, _info_y1, _info_x2, _info_y2, 12, 12, true);

    draw_set_color(c_black);
    draw_text_transformed(_info_x1 + 10, _info_y1 + 10, "КЛИЧКА: " + string(target_id.char_name), 0.62 * _ui_scale, 0.62 * _ui_scale, 0);
    draw_text_transformed(_info_x1 + 10, _info_y1 + 30, "ВОЗРАСТ: " + _age_str_an, 0.62 * _ui_scale, 0.62 * _ui_scale, 0);
    draw_text_transformed(_info_x1 + 10, _info_y1 + 50, "ПОРОДА: " + _breed_str, 0.62 * _ui_scale, 0.62 * _ui_scale, 0);

    // Нижний большой прямоугольник
    var _case_x1 = _tx;
    var _case_y1 = _info_y2 + 10;
    var _case_w  = 202 * _ui_scale;
    var _case_h  = 170 * _ui_scale;
    var _case_x2 = _case_x1 + _case_w;
    var _case_y2 = _case_y1 + _case_h;

    draw_set_color(make_color_rgb(248, 240, 224));
    draw_roundrect_ext(_case_x1, _case_y1, _case_x2, _case_y2, 12, 12, false);

    draw_set_color(make_color_rgb(180, 160, 140));
    draw_roundrect_ext(_case_x1, _case_y1, _case_x2, _case_y2, 12, 12, true);

    draw_set_color(make_color_rgb(40, 80, 140));
    draw_text_ext_transformed(
        _case_x1 + 10,
        _case_y1 + 10,
        "ОБСЛЕДОВАНИЕ: " + _reveal_text,
        12,
        _case_w - 20,
        0.58 * _ui_scale,
        0.58 * _ui_scale,
        0
    );

   draw_set_color(c_black);
draw_text_transformed(_case_x1 + 10, _case_y1 + 44, "СИМПТОМЫ:", 0.62 * _ui_scale, 0.62 * _ui_scale, 0);

var _symptoms_text_y = _case_y1 + 62;
var _symptom_line_h = 14 * _ui_scale;
var _symptom_lines_reserved = 7;
var _symptom_block_h = _symptom_line_h * _symptom_lines_reserved;

draw_set_color(c_dkgray);
draw_text_ext_transformed(
    _case_x1 + 10,
    _symptoms_text_y,
    _symptoms_text,
    _symptom_line_h,
    _case_w - 20,
    0.56 * _ui_scale,
    0.56 * _ui_scale,
    0
);

var _diag_y = _symptoms_text_y + _symptom_block_h + 6;
var _state_y = _diag_y + 28;

// Куда прилетают плюсики/минусы
var _cond_target_x = _case_x1 + 120 * _ui_scale;
var _cond_target_y = _state_y + 8 * _ui_scale;

draw_set_color(make_color_rgb(130, 30, 30));
draw_text_ext_transformed(
    _case_x1 + 10,
    _diag_y,
    "ДИАГНОЗ: " + _diagnosis_line,
    12,
    _case_w - 20,
    0.58 * _ui_scale,
    0.58 * _ui_scale,
    0
);

var _cond_col = make_color_rgb(90, 90, 90);

if (_cond_known) {
    var _cond_t = clamp(_cond, 0, 100) / 100;
    _cond_col = merge_color(make_color_rgb(180, 40, 40), make_color_rgb(40, 160, 60), _cond_t);
}

var _cond_line = "СОСТОЯНИЕ: " + _cond_text;
var _cond_draw_x = _case_x1 + 10;
var _cond_draw_y = _state_y;
var _cond_scale = 0.62 * _ui_scale;

if (condition_flash_timer > 0) {
    var _flash_t = condition_flash_timer / max(1, condition_flash_timer_max);
    var _shake_x = sin((1 - _flash_t) * 18) * 2 * _flash_t;
    var _shake_y = cos((1 - _flash_t) * 14) * 1 * _flash_t;
    var _pulse_scale = 1 + 0.10 * _flash_t;

    draw_set_alpha(0.22 * _flash_t);
    draw_set_color(condition_flash_color);
    draw_roundrect_ext(
        _cond_draw_x - 4,
        _cond_draw_y - 2,
        _cond_draw_x + 135 * _ui_scale,
        _cond_draw_y + 14 * _ui_scale,
        6, 6, false
    );

    draw_set_alpha(0.45 * _flash_t);
    draw_set_color(condition_flash_color);
    draw_line_width(
        _cond_draw_x,
        _cond_draw_y + 13 * _ui_scale,
        _cond_draw_x + 120 * _ui_scale,
        _cond_draw_y + 13 * _ui_scale,
        2 + 2 * _flash_t
    );

    draw_set_alpha(1);
    draw_set_color(_cond_col);
    draw_text_transformed(
        _cond_draw_x + _shake_x,
        _cond_draw_y + _shake_y,
        _cond_line,
        _cond_scale * _pulse_scale,
        _cond_scale * _pulse_scale,
        0
    );
} else {
    draw_set_color(_cond_col);
    draw_text_transformed(
        _cond_draw_x,
        _cond_draw_y,
        _cond_line,
        _cond_scale,
        _cond_scale,
        0
    );
}

    // Правая панель действий
    var _right_x1 = _rx;
    var _right_y1 = _rs + 28;
    var _right_w  = 155 * _ui_scale;
    var _right_h  = 270 * _ui_scale;
    var _right_x2 = _right_x1 + _right_w;
    var _right_y2 = _right_y1 + _right_h;

    draw_set_color(make_color_rgb(248, 240, 224));
    draw_roundrect_ext(_right_x1, _right_y1, _right_x2, _right_y2, 12, 12, false);

    draw_set_color(make_color_rgb(180, 160, 140));
    draw_roundrect_ext(_right_x1, _right_y1, _right_x2, _right_y2, 12, 12, true);

    var _player = noone;

    if (instance_exists(obj_player)) {
        _player = instance_find(obj_player, 0);
    }

    var _doctor_assign_mode = false;
    var _procedure_exec_mode = false;

    if (instance_exists(_player)) {
        if (variable_instance_exists(target_id, "assigned_doctor")) {
            if (target_id.assigned_doctor == _player.id) {
                if (_player.doctor_state == "manual_exam") {
                    _doctor_assign_mode = true;
                }

                if (_player.doctor_state == "manual_procedure") {
                    _procedure_exec_mode = true;
                }
            }
        }
    }

    var _btn_w = _right_w - 20;
    var _btn_h = 24;
    var _btn_gap = 4;

    // ─────────────────────────────────────────
    // ДИАГНОСТИКА — только в режиме врача
    // ─────────────────────────────────────────
    draw_set_color(c_black);
    draw_text_transformed(_right_x1 + 10, _right_y1 + 10, "ОБСЛЕДОВАНИЯ", 0.68 * _ui_scale, 0.68 * _ui_scale, 0);

    var _diag_y = _right_y1 + 38;
    var _diag_list = [];

    if (variable_instance_exists(target_id, "current_case") && is_struct(target_id.current_case)) {
        _diag_list = case_get_available_diagnostics(target_id.current_case);
    }

    for (var d = 0; d < array_length(_diag_list); d++) {
        var _diag_id = _diag_list[d];
        var _diag_name = db_get_diagnostic_name(_diag_id);

        var _bx1 = _right_x1 + 10;
        var _by1 = _diag_y + d * (_btn_h + _btn_gap);
        var _bx2 = _bx1 + _btn_w;
        var _by2 = _by1 + _btn_h;

        var _hover_diag = point_in_rectangle(_mx, _my, _bx1, _by1, _bx2, _by2);

        tablet_draw_action_button(_bx1, _by1, _bx2, _by2, _diag_name, _hover_diag, _doctor_assign_mode);

        if (_doctor_assign_mode && tablet_click_lock <= 0 && _hover_diag && mouse_check_button_pressed(mb_left)) {
            tablet_click_lock = 5;

            animal_perform_diagnostic(target_id, _diag_id);

            var _hud_inst = instance_exists(obj_UI_HUD) ? instance_find(obj_UI_HUD, 0) : noone;
            if (instance_exists(_hud_inst)) {
                _hud_inst.show_notice("ДИАГНОСТИКА", db_get_diagnostic_name(_diag_id), room_speed * 2);
            }

            exit;
        }
    }

    // ─────────────────────────────────────────
    // НАЗНАЧЕНИЯ / ПРОЦЕДУРЫ
    // ─────────────────────────────────────────
    var _treat_title_y = _diag_y + max(1, array_length(_diag_list)) * (_btn_h + _btn_gap) + 12;

    draw_set_color(c_black);

    if (_doctor_assign_mode) {
        draw_text_transformed(_right_x1 + 10, _treat_title_y, "НАЗНАЧЕНИЯ", 0.68 * _ui_scale, 0.68 * _ui_scale, 0);
    } else if (_procedure_exec_mode) {
        draw_text_transformed(_right_x1 + 10, _treat_title_y, "ПРОЦЕДУРЫ", 0.68 * _ui_scale, 0.68 * _ui_scale, 0);
    } else {
        draw_text_transformed(_right_x1 + 10, _treat_title_y, "ЛЕЧЕНИЕ", 0.68 * _ui_scale, 0.68 * _ui_scale, 0);
    }

    var _treat_y = _treat_title_y + 25;

    // ─────────────────────────────────────────
    // РЕЖИМ ВРАЧА: выбор назначений
    // ─────────────────────────────────────────
if (_doctor_assign_mode) {
    var _choice_list = [];
    var _therapy_level = 1;

    if (instance_exists(_player)) {
        if (variable_instance_exists(_player, "therapy_level")) {
            _therapy_level = _player.therapy_level;
        }
    }

    if (variable_instance_exists(target_id, "current_case") && is_struct(target_id.current_case)) {
        _choice_list = case_get_visible_treatment(target_id.current_case, _therapy_level);

        if (!variable_struct_exists(target_id.current_case, "visit_treatment_feedback_ok_ids")) {
            target_id.current_case.visit_treatment_feedback_ok_ids = [];
        }

        if (!variable_struct_exists(target_id.current_case, "visit_treatment_feedback_bad_ids")) {
            target_id.current_case.visit_treatment_feedback_bad_ids = [];
        }

        if (!variable_struct_exists(target_id.current_case, "prescribed_treatment_ids")) {
            target_id.current_case.prescribed_treatment_ids = [];
        }

        if (!variable_struct_exists(target_id.current_case, "visit_prescribed_actions")) {
            target_id.current_case.visit_prescribed_actions = [];
        }
    }

    draw_set_color(make_color_rgb(60, 90, 140));
    draw_text_transformed(_right_x1 + 10, _treat_title_y - 16, "ТЕРАПИЯ: " + string(_therapy_level) + " УР.", 0.52 * _ui_scale, 0.52 * _ui_scale, 0);

    for (var t = 0; t < array_length(_choice_list); t++) {
        var _choice = _choice_list[t];

        var _action_id = _choice.action_id;
        var _is_correct = variable_struct_exists(_choice, "is_correct") ? _choice.is_correct : true;
        var _label = db_get_treatment_action_name(_action_id);

        var _tx1b = _right_x1 + 10;
        var _ty1b = _treat_y + t * (_btn_h + _btn_gap);
        var _tx2b = _tx1b + _btn_w;
        var _ty2b = _ty1b + _btn_h;

        var _hover_treat = point_in_rectangle(_mx, _my, _tx1b, _ty1b, _tx2b, _ty2b);
        var _feedback_state = 0;

        if (is_struct(target_id.current_case)) {
            _feedback_state = tablet_get_treatment_feedback_state(target_id.current_case, _action_id);
        }

        var _can_press = (_feedback_state == 0);

        tablet_draw_treatment_button(_tx1b, _ty1b, _tx2b, _ty2b, _label, _hover_treat, _can_press, _feedback_state);

        if (_can_press && tablet_click_lock <= 0 && _hover_treat && mouse_check_button_pressed(mb_left)) {
            tablet_click_lock = 5;

            if (_is_correct) {
                case_assign_treatment_action(target_id, _action_id);

                tablet_add_fly_effect(
                    (_tx1b + _tx2b) * 0.5,
                    (_ty1b + _ty2b) * 0.5,
                    _cond_target_x,
                    _cond_target_y,
                    "+",
                    make_color_rgb(70, 210, 90)
                );

                if (instance_exists(_player)) {
                    doctor_add_therapy_xp(_player, 10, true);
                }

                var _hud_ok = instance_exists(obj_UI_HUD) ? instance_find(obj_UI_HUD, 0) : noone;
                if (instance_exists(_hud_ok)) {
                    _hud_ok.show_notice("НАЗНАЧЕНО", db_get_treatment_action_name(_action_id), room_speed * 2);
                }
            } else {
                case_apply_wrong_prescription_choice(target_id, _action_id);

                tablet_add_fly_effect(
                    (_tx1b + _tx2b) * 0.5,
                    (_ty1b + _ty2b) * 0.5,
                    _cond_target_x,
                    _cond_target_y,
                    "-",
                    make_color_rgb(220, 70, 70)
                );

                var _hud_bad = instance_exists(obj_UI_HUD) ? instance_find(obj_UI_HUD, 0) : noone;
                if (instance_exists(_hud_bad)) {
                    _hud_bad.show_notice("ОШИБКА НАЗНАЧЕНИЯ", db_get_treatment_action_name(_action_id), room_speed * 2);
                }
            }

            exit;
        }
    }

    var _finish_y = _right_y2 - 34;
    var _finish_x1 = _right_x1 + 10;
    var _finish_x2 = _finish_x1 + _btn_w;
    var _finish_y2 = _finish_y + _btn_h;

    var _hover_finish = point_in_rectangle(_mx, _my, _finish_x1, _finish_y, _finish_x2, _finish_y2);

    tablet_draw_action_button(_finish_x1, _finish_y, _finish_x2, _finish_y2, "НАЗНАЧИТЬ ЛЕЧЕНИЕ", _hover_finish, true);

    if (tablet_click_lock <= 0 && _hover_finish && mouse_check_button_pressed(mb_left)) {
        tablet_click_lock = 5;

        if (instance_exists(_player)) {
            with (_player) {
                player_finish_exam(true);
            }
        }

        visible = false;
        target_id = noone;
        exit;
    }
}
    // ─────────────────────────────────────────
    // РЕЖИМ ПРОЦЕДУР: выполнение назначений
    // ─────────────────────────────────────────
    if (_procedure_exec_mode) {
        var _pending_actions = [];

        if (variable_instance_exists(target_id, "current_case") && is_struct(target_id.current_case)) {
            if (variable_struct_exists(target_id.current_case, "pending_procedure_actions")) {
                _pending_actions = target_id.current_case.pending_procedure_actions;
            }
        }

        for (var p = 0; p < array_length(_pending_actions); p++) {
            var _proc_action_id = _pending_actions[p];
            var _proc_label = db_get_treatment_action_name(_proc_action_id);

            var _px1b = _right_x1 + 10;
            var _py1b = _treat_y + p * (_btn_h + _btn_gap);
            var _px2b = _px1b + _btn_w;
            var _py2b = _py1b + _btn_h;

            var _hover_proc = point_in_rectangle(_mx, _my, _px1b, _py1b, _px2b, _py2b);

            var _already_done = false;
            if (is_struct(target_id.current_case)) {
                _already_done = tablet_case_has_action_done_this_visit(target_id.current_case, _proc_action_id);
            }

            var _feedback_state2 = 0;
            if (is_struct(target_id.current_case)) {
                _feedback_state2 = tablet_get_treatment_feedback_state(target_id.current_case, _proc_action_id);
            }

            var _can_do_proc = !_already_done;

            tablet_draw_treatment_button(_px1b, _py1b, _px2b, _py2b, _proc_label, _hover_proc, _can_do_proc, _feedback_state2);

            if (_can_do_proc && tablet_click_lock <= 0 && _hover_proc && mouse_check_button_pressed(mb_left)) {
    tablet_click_lock = 5;

    var _gain = treatment_get_condition_delta(_proc_action_id);

    case_apply_treatment_action(target_id, _proc_action_id);

    if (_gain > 0) {
    tablet_add_fly_effect(
    (_px1b + _px2b) * 0.5,
    (_py1b + _py2b) * 0.5,
    _cond_target_x,
    _cond_target_y,
    "+",
    make_color_rgb(70, 210, 90)
);
}

    var _hud_proc = instance_exists(obj_UI_HUD) ? instance_find(obj_UI_HUD, 0) : noone;
    if (instance_exists(_hud_proc)) {
        _hud_proc.show_notice("ПРОЦЕДУРА", db_get_treatment_action_name(_proc_action_id), room_speed * 2);
    }

    exit;
}
        }

        var _finish_y_proc = _right_y2 - 34;
        var _finish_x1_proc = _right_x1 + 10;
        var _finish_x2_proc = _finish_x1_proc + _btn_w;
        var _finish_y2_proc = _finish_y_proc + _btn_h;

        var _hover_finish2 = point_in_rectangle(_mx, _my, _finish_x1_proc, _finish_y_proc, _finish_x2_proc, _finish_y2_proc);

        tablet_draw_action_button(_finish_x1_proc, _finish_y_proc, _finish_x2_proc, _finish_y2_proc, "ЗАВЕРШИТЬ ПРОЦЕДУРЫ", _hover_finish2, true);

        if (tablet_click_lock <= 0 && _hover_finish2 && mouse_check_button_pressed(mb_left)) {
            tablet_click_lock = 5;

            if (instance_exists(_player)) {
                with (_player) {
                    player_finish_procedure_visit();
                }
            }

            visible = false;
            target_id = noone;
            exit;
        }
    }
}

// ───── ВЛАДЕЛЕЦ

if (target_id.role == "owner") {

    var _owner_state = variable_instance_exists(target_id, "state") ? string(target_id.state) : "";
    var _queue_type = variable_instance_exists(target_id, "service_queue_type") ? string(target_id.service_queue_type) : "doctor";
    var _queue_purpose = variable_instance_exists(target_id, "queue_purpose") ? string(target_id.queue_purpose) : "registration";

    var _has_pet = (variable_instance_exists(target_id, "my_pet") && instance_exists(target_id.my_pet));

    var _pet_name = "?";
    var _pet_breed = "?";
    var _pet_problem = "?";
    var _pet_cond = "100";

    if (_has_pet) {
        var _pet = target_id.my_pet;

        if (variable_instance_exists(_pet, "char_name")) _pet_name = string(_pet.char_name);
        if (variable_instance_exists(_pet, "breed")) _pet_breed = string(_pet.breed);
        if (variable_instance_exists(_pet, "problem")) _pet_problem = string(_pet.problem);

        if (variable_instance_exists(_pet, "condition")) {
            if (tablet_is_condition_known(_pet)) {
                _pet_cond = string(round(_pet.condition)) + "%";
            } else {
                _pet_cond = "?";
            }
        }
    }

    draw_set_color(c_black);
    draw_text_transformed(_rx, _rs + 30 * _ui_scale, "ПИТОМЕЦ:", 0.8 * _ui_scale, 0.8 * _ui_scale, 0);

    draw_set_color(c_blue);
    draw_text_transformed(_rx, _rs + 55 * _ui_scale, "> " + _pet_name, 0.9 * _ui_scale, 0.9 * _ui_scale, 0);

    draw_set_color(c_dkgray);
    draw_text_transformed(_rx, _rs + 80 * _ui_scale, _pet_breed, 0.7 * _ui_scale, 0.7 * _ui_scale, 0);
    draw_text_transformed(_rx, _rs + 100 * _ui_scale, "ПРИЧИНА: " + _pet_problem, 0.7 * _ui_scale, 0.7 * _ui_scale, 0);
    draw_text_transformed(_rx, _rs + 120 * _ui_scale, "СОСТОЯНИЕ: " + _pet_cond, 0.7 * _ui_scale, 0.7 * _ui_scale, 0);

    var _visit_status = "НЕИЗВЕСТНО";

    switch (_owner_state) {
    case "going_to_queue":
        if (_queue_purpose == "payment") _visit_status = "ИДЁТ НА ОПЛАТУ";
        else _visit_status = "ИДЁТ К СТОЙКЕ";
    break;

    case "in_queue":
        if (_queue_purpose == "payment") _visit_status = "ОЖИДАЕТ ОПЛАТЫ";
        else _visit_status = "У СТОЙКИ";
    break;

    case "registering":
        if (_queue_purpose == "payment") _visit_status = "ОПЛАЧИВАЕТ";
        else _visit_status = "РЕГИСТРАЦИЯ";
    break;

    case "going_to_waiting":
        _visit_status = "ИДЁТ В ОЖИДАНИЕ";
    break;

    case "waiting":
        if (_queue_type == "procedure") _visit_status = "ЖДЁТ ПРОЦЕДУРЫ";
        else _visit_status = "ЖДЁТ ВРАЧА";
    break;

    case "going_to_exam":
        _visit_status = "НАПРАВЛЕН В КАБИНЕТ";
    break;

    case "in_exam":
        if (_queue_type == "procedure") _visit_status = "НА ПРОЦЕДУРЕ";
        else _visit_status = "НА ПРИЁМЕ";
    break;

    case "leaving_clinic":
        _visit_status = "ПОКИДАЕТ КЛИНИКУ";
    break;
}

    draw_set_color(make_color_rgb(0, 0, 150));
    draw_text_transformed(_rx, _rs + 146 * _ui_scale, "СТАТУС: " + _visit_status, 0.75 * _ui_scale, 0.75 * _ui_scale, 0);

    var _player_owner = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
    var _player_idle = instance_exists(_player_owner) && (_player_owner.doctor_state == "idle");

    var _free_wait_spot = reception_find_free_wait_spot();
    var _has_free_wait = (_free_wait_spot != -1);

    var _at_front_for_registration = false;

    if (_owner_state == "in_queue" && !target_id.registered) {
        if (target_id.queue_slot == 0) {
            _at_front_for_registration = true;
        } else if (variable_instance_exists(target_id, "assigned_desk") && instance_exists(target_id.assigned_desk)) {
            var _desk_ref = target_id.assigned_desk;

            if (point_distance(target_id.x, target_id.y, _desk_ref.queue_start_x, _desk_ref.queue_start_y) <= 16) {
                _at_front_for_registration = true;
            }
        }
    }

    var _can_register =
        _player_idle
        && _has_free_wait
        && (_owner_state == "in_queue")
        && (_queue_purpose != "payment")
        && !target_id.registered
        && _at_front_for_registration;

    var _can_take_doctor =
        _player_idle
        && (_owner_state == "waiting")
        && (_queue_type == "doctor")
        && variable_instance_exists(target_id, "assigned_doctor")
        && (target_id.assigned_doctor == noone);

    var _can_take_procedure =
        _player_idle
        && (_owner_state == "waiting")
        && (_queue_type == "procedure")
        && variable_instance_exists(target_id, "assigned_doctor")
        && (target_id.assigned_doctor == noone);

    var _can_take_payment =
        _player_idle
        && (_owner_state == "in_queue")
        && (_queue_purpose == "payment")
        && variable_instance_exists(target_id, "queue_slot")
        && (target_id.queue_slot == 0);

    var _btn_y = _rs + 178 * _ui_scale;
    var _btn_x1 = _rx;
    var _btn_x2 = _btn_x1 + 180 * _ui_scale;
    var _btn_h2 = 26 * _ui_scale;
    var _btn_gap2 = 8 * _ui_scale;

    // 1. ПОСТАВИТЬ В ОЧЕРЕДЬ
    if (_can_register) {
        var _reg_y1 = _btn_y;
        var _reg_y2 = _reg_y1 + _btn_h2;

        var _hover_register = point_in_rectangle(_mx, _my, _btn_x1, _reg_y1, _btn_x2, _reg_y2);

        tablet_draw_action_button(_btn_x1, _reg_y1, _btn_x2, _reg_y2, "ПОСТАВИТЬ В ОЧЕРЕДЬ", _hover_register, true);

        if (_hover_register && tablet_click_lock <= 0 && mouse_check_button_pressed(mb_left)) {
            tablet_click_lock = 5;

            var _player_reg = instance_find(obj_player, 0);

            if (instance_exists(_player_reg)) {
                with (_player_reg) {
                    player_begin_registration(other.target_id);
                }
            }

            visible = false;
            target_id = noone;
            exit;
        }

        _btn_y += _btn_h2 + _btn_gap2;
    }

    // 2. ПРИНЯТЬ ОПЛАТУ
    if (_can_take_payment) {
        var _pay_y1 = _btn_y;
        var _pay_y2 = _pay_y1 + _btn_h2;

        var _hover_pay = point_in_rectangle(_mx, _my, _btn_x1, _pay_y1, _btn_x2, _pay_y2);

        tablet_draw_action_button(_btn_x1, _pay_y1, _btn_x2, _pay_y2, "ПРИНЯТЬ ОПЛАТУ", _hover_pay, true);

        if (_hover_pay && tablet_click_lock <= 0 && mouse_check_button_pressed(mb_left)) {
    tablet_click_lock = 5;

    var _player_pay = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;

    if (instance_exists(_player_pay)) {
        with (_player_pay) {
            player_begin_payment(other.target_id);
        }
    }

    visible = false;
    target_id = noone;
    exit;
}

        _btn_y += _btn_h2 + _btn_gap2;
    }

    // 3. ВЗЯТЬ НА ПРИЁМ
    if (_can_take_doctor) {
        var _take_y1 = _btn_y;
        var _take_y2 = _take_y1 + _btn_h2;

        var _hover_take = point_in_rectangle(_mx, _my, _btn_x1, _take_y1, _btn_x2, _take_y2);

        tablet_draw_action_button(_btn_x1, _take_y1, _btn_x2, _take_y2, "ВЗЯТЬ НА ПРИЁМ", _hover_take, true);

        if (_hover_take && tablet_click_lock <= 0 && mouse_check_button_pressed(mb_left)) {
            tablet_click_lock = 5;

            var _player2 = instance_find(obj_player, 0);

            if (instance_exists(_player2)) {
                with (_player2) {
                    player_begin_exam(other.target_id);
                }
            }

            visible = false;
            target_id = noone;
            exit;
        }
    }

    // 4. НА ПРОЦЕДУРЫ
    if (_can_take_procedure) {
        var _proc_y1 = _btn_y;
        var _proc_y2 = _proc_y1 + _btn_h2;

        var _hover_proc = point_in_rectangle(_mx, _my, _btn_x1, _proc_y1, _btn_x2, _proc_y2);

        tablet_draw_action_button(_btn_x1, _proc_y1, _btn_x2, _proc_y2, "НА ПРОЦЕДУРЫ", _hover_proc, true);

        if (_hover_proc && tablet_click_lock <= 0 && mouse_check_button_pressed(mb_left)) {
            tablet_click_lock = 5;

            var _player3 = instance_find(obj_player, 0);

            if (instance_exists(_player3)) {
                with (_player3) {
                    player_begin_procedure_visit(other.target_id);
                }
            }

            visible = false;
            target_id = noone;
            exit;
        }
    }
}
// ───── ПЕРСОНАЛ
if (target_id.role != "animal" && target_id.role != "owner") {
    var _traits = [
    "Спокойный", "Амбициозный", "Наставник", "Перфекционист",
    "Конфликтный", "Добрый", "Стрессоустойчивый", "Хаотичный",
    "Командный", "Замкнутый", "Карьерист", "Уставший"
];

var _trait_idx = variable_instance_exists(target_id, "character_trait") ? target_id.character_trait : 0;
_trait_idx = clamp(_trait_idx, 0, array_length(_traits) - 1);

var _salary = 0;

if (variable_instance_exists(target_id, "salary")) {
    _salary = target_id.salary;
} else if (variable_instance_exists(target_id, "skills_sum")) {
    _salary = target_id.skills_sum * 10;
}

var _loyalty = variable_instance_exists(target_id, "loyalty") ? target_id.loyalty : 75;

draw_set_color(make_color_rgb(0, 0, 150));
draw_text_transformed(_rx, _rs + 30 * _ui_scale, "ХАРАКТЕР: " + string_upper(_traits[_trait_idx]), 0.9 * _ui_scale, 0.9 * _ui_scale, 0);

draw_set_color(c_black);
draw_text_transformed(_rx, _rs + 60 * _ui_scale, "ЗАРПЛАТА: $ " + string(_salary), 0.8 * _ui_scale, 0.8 * _ui_scale, 0);
draw_text_transformed(_rx, _rs + 85 * _ui_scale, "ЛОЯЛЬНОСТЬ: " + string(_loyalty) + "/100", 0.8 * _ui_scale, 0.8 * _ui_scale, 0);
}


// ─────────────────────────────────────────────
// ЛЕТЯЩИЕ ПЛЮСИКИ / МИНУСИКИ
// ─────────────────────────────────────────────
for (var _fx_i = 0; _fx_i < array_length(fly_effects); _fx_i++) {
    var _fx = fly_effects[_fx_i];

    var _t = clamp(_fx.timer / max(1, _fx.timer_max), 0, 1);
    var _omt = 1 - _t;

    var _fx_x =
        (_omt * _omt * _fx.start_x)
        + (2 * _omt * _t * _fx.control_x)
        + (_t * _t * _fx.end_x);

    var _fx_y =
        (_omt * _omt * _fx.start_y)
        + (2 * _omt * _t * _fx.control_y)
        + (_t * _t * _fx.end_y);

    var _fx_alpha = 1;
    if (_t > 0.68) {
        _fx_alpha = 1 - ((_t - 0.68) / 0.32);
    }
    _fx_alpha = clamp(_fx_alpha, 0, 1);

   var _size = lerp(24, 15, _t);
var _thick = lerp(3, 1.5, _t);

    draw_set_alpha(_fx_alpha);

    // мягкое свечение
    draw_set_color(merge_color(_fx.color, c_white, 0.55));
    draw_circle(_fx_x, _fx_y, _size * 0.7, false);

    // тень
    draw_set_color(c_black);

    // горизонтальная линия
    draw_line_width(
        _fx_x - _size * 0.5 + 1,
        _fx_y + 1,
        _fx_x + _size * 0.5 + 1,
        _fx_y + 1,
        _thick + 1
    );

    // вертикальная линия только для плюса
    if (_fx.symbol == "+") {
        draw_line_width(
            _fx_x + 1,
            _fx_y - _size * 0.5 + 1,
            _fx_x + 1,
            _fx_y + _size * 0.5 + 1,
            _thick + 1
        );
    }

    // цветной знак
    draw_set_color(_fx.color);

    draw_line_width(
        _fx_x - _size * 0.5,
        _fx_y,
        _fx_x + _size * 0.5,
        _fx_y,
        _thick
    );

    if (_fx.symbol == "+") {
        draw_line_width(
            _fx_x,
            _fx_y - _size * 0.5,
            _fx_x,
            _fx_y + _size * 0.5,
            _thick
        );
    }
}
// Сброс
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// ── БЛОК "ПОСЛЕДНИЕ НАВЫКИ" (все сотрудники: врач/игрок/ассистент/админ) ──
var _target_role = "";
var _is_player_target = false;
if (instance_exists(target_id)) {
    if (variable_instance_exists(target_id, "role")) _target_role = target_id.role;
    _is_player_target = (target_id.object_index == obj_player);
    if (_is_player_target) _target_role = "player";
}
var _show_log = false;
if (instance_exists(target_id) && variable_instance_exists(target_id, "xp_log")) {
    if (_target_role == "doctor" || _target_role == "player"
    ||  _target_role == "assistant" || _target_role == "admin") {
        _show_log = true;
    }
}

if (visible && target_id != noone && _show_log) {
    var _usc = 1;
    if (variable_instance_exists(id, "_ui_scale")) _usc = _ui_scale;
    else if (variable_instance_exists(id, "ui_scale")) _usc = ui_scale;

    var _cx = display_get_gui_width() * 0.5;
    var _cy = display_get_gui_height() * 0.5;

    var _soc_x = _cx + (30 * _usc);
    var _soc_y = _cy + (-165 * _usc);

    var _log_x1 = _soc_x;
    var _log_y1 = _soc_y + 145 * _usc;
    var _log_x2 = _soc_x + 220 * _usc;
    var _log_h = 105 * _usc;
    var _log_y2 = _log_y1 + _log_h;

    // Бумажный фон
    draw_set_color(make_color_rgb(248, 240, 224));
    draw_roundrect_ext(_log_x1, _log_y1, _log_x2, _log_y2, 10, 10, false);
    draw_set_color(make_color_rgb(180, 160, 140));
    draw_roundrect_ext(_log_x1, _log_y1, _log_x2, _log_y2, 10, 10, true);

    // Заголовок
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text_transformed(_log_x1 + 8, _log_y1 + 4, "ПОСЛЕДНИЕ НАВЫКИ:", 0.55 * _usc, 0.6 * _usc, 0);

    // Строчки лога
    if (array_length(target_id.xp_log) > 0) {
        for (var _ri = 0; _ri < min(5, array_length(target_id.xp_log)); _ri++) {
            var _entry = target_id.xp_log[_ri];
            var _alpha = 1.0 - (_ri * 0.12);
            draw_set_alpha(_alpha);
            draw_set_color(make_color_rgb(40, 110, 50));
            draw_text_transformed(
                _log_x1 + 10,
                _log_y1 + 22 + _ri * 15 * _usc,
                _entry.txt,
                0.52 * _usc,
                0.56 * _usc,
                0
            );
        }
    } else {
        draw_set_alpha(1);
        draw_set_color(make_color_rgb(120, 110, 95));
        draw_text_transformed(_log_x1 + 10, _log_y1 + 25, "Нет записей", 0.5 * _usc, 0.55 * _usc, 0);
    }

    // Восстановление
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}