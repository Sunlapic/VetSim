/// tablet_draw_animal_card.gml
/// @description Модульная карточка питомца с медицинскими действиями.
/// Пакет №113: операция стартует автоматически при назначении.


// ═══════════════════════════════════════════════════════════════
// 1. МЕДИЦИНСКИЕ ТЕКСТЫ
// ═══════════════════════════════════════════════════════════════

function tablet_animal_get_disease_name(_disease_id) {
    if (!variable_global_exists("med_db")) return "Неизвестно";
    if (!is_struct(global.med_db)) return "Неизвестно";
    if (!variable_struct_exists(global.med_db, "diseases")) return "Неизвестно";
    if (!variable_struct_exists(global.med_db.diseases, _disease_id)) return "Неизвестно";

    var _disease = variable_struct_get(global.med_db.diseases, _disease_id);

    return variable_struct_exists(_disease, "name_ru")
        ? string(_disease.name_ru)
        : "Неизвестно";
}

function tablet_animal_get_symptom_text(_animal) {
    if (!instance_exists(_animal)) return "- Нет данных";
    if (!variable_instance_exists(_animal, "visible_symptoms")) return "- Нет данных";
    if (!is_array(_animal.visible_symptoms)) return "- Нет данных";
    if (array_length(_animal.visible_symptoms) <= 0) return "- Нет данных";

    var _result = "";
    var _symptom_ids = _animal.visible_symptoms;

    for (var _index = 0; _index < array_length(_symptom_ids); _index++) {
        var _symptom_id = _symptom_ids[_index];
        var _symptom_name = "Неизвестный симптом";

        if (
            variable_global_exists("med_db")
            && is_struct(global.med_db)
            && variable_struct_exists(global.med_db, "symptoms")
            && variable_struct_exists(global.med_db.symptoms, _symptom_id)
        ) {
            var _symptom = variable_struct_get(global.med_db.symptoms, _symptom_id);

            if (variable_struct_exists(_symptom, "name_ru")) {
                _symptom_name = string(_symptom.name_ru);
            }
        }

        if (_result != "") _result += "\n";
        _result += "- " + _symptom_name;
    }

    return _result;
}

function tablet_animal_get_species_name(_animal) {
    if (!instance_exists(_animal)) return "Неизвестно";

    var _species_id = variable_instance_exists(_animal, "species_id")
        ? string(_animal.species_id)
        : "";

    switch (_species_id) {
        case "dog": return "Собака";
        case "cat": return "Кошка";
    }

    return (_species_id == "") ? "Неизвестно" : string_upper(_species_id);
}

function tablet_animal_get_reveal_text(_reveal_level) {
    switch (_reveal_level) {
        case 0: return "Необследован";
        case 1: return "В стадии обследования";
        case 2: return "Диагноз под вопросом";
    }

    return "Обследован";
}


// ═══════════════════════════════════════════════════════════════
// 2. ПРОВЕРКИ МЕДИЦИНСКОГО СОСТОЯНИЯ
// ═══════════════════════════════════════════════════════════════

function tablet_animal_condition_known(_animal) {
    if (!instance_exists(_animal)) return false;
    if (!variable_instance_exists(_animal, "current_case")) return false;
    if (!is_struct(_animal.current_case)) return false;
    if (!variable_struct_exists(_animal.current_case, "completed_diagnostics")) return false;

    var _diagnostics = _animal.current_case.completed_diagnostics;

    for (var _index = 0; _index < array_length(_diagnostics); _index++) {
        if (_diagnostics[_index] == "diag_physical_exam") {
            return true;
        }
    }

    return false;
}

function tablet_animal_action_done_this_visit(_case, _action_id) {
    if (!is_struct(_case)) return false;
    if (!variable_struct_exists(_case, "visit_treatments_done")) return false;

    for (var _index = 0; _index < array_length(_case.visit_treatments_done); _index++) {
        if (_case.visit_treatments_done[_index] == _action_id) {
            return true;
        }
    }

    return false;
}

function tablet_animal_feedback_state(_case, _action_id) {
    if (!is_struct(_case)) return 0;

    if (variable_struct_exists(_case, "visit_treatment_feedback_bad_ids")) {
        for (var _bad_index = 0; _bad_index < array_length(_case.visit_treatment_feedback_bad_ids); _bad_index++) {
            if (_case.visit_treatment_feedback_bad_ids[_bad_index] == _action_id) {
                return -1;
            }
        }
    }

    if (variable_struct_exists(_case, "visit_treatment_feedback_ok_ids")) {
        for (var _ok_index = 0; _ok_index < array_length(_case.visit_treatment_feedback_ok_ids); _ok_index++) {
            if (_case.visit_treatment_feedback_ok_ids[_ok_index] == _action_id) {
                return 1;
            }
        }
    }

    return 0;
}

function tablet_animal_diagnostic_feedback_state(_case, _diagnostic_id) {
    if (!is_struct(_case)) return 0;

    if (variable_struct_exists(_case, "visit_diagnostic_feedback_bad_ids")) {
        for (var _bad_index = 0; _bad_index < array_length(_case.visit_diagnostic_feedback_bad_ids); _bad_index++) {
            if (_case.visit_diagnostic_feedback_bad_ids[_bad_index] == _diagnostic_id) {
                return -1;
            }
        }
    }

    if (variable_struct_exists(_case, "visit_diagnostic_feedback_ok_ids")) {
        for (var _ok_index = 0; _ok_index < array_length(_case.visit_diagnostic_feedback_ok_ids); _ok_index++) {
            if (_case.visit_diagnostic_feedback_ok_ids[_ok_index] == _diagnostic_id) {
                return 1;
            }
        }
    }

    return 0;
}


// ═══════════════════════════════════════════════════════════════
// 3. ВЫПУКЛАЯ ПАНЕЛЬ С ТОНКОЙ ОБВОДКОЙ
// ═══════════════════════════════════════════════════════════════

function tablet_animal_draw_panel(_x1, _y1, _x2, _y2) {
    var _panel_fill = make_color_rgb(242, 232, 214);
    var _panel_line = make_color_rgb(180, 160, 140);
    var _panel_highlight = make_color_rgb(255, 250, 238);

    draw_set_color(c_black);

    draw_set_alpha(0.025);
    draw_roundrect_ext(_x1 - 5, _y1 - 3, _x2 + 7, _y2 + 9, 12, 12, false);

    draw_set_alpha(0.040);
    draw_roundrect_ext(_x1 - 3, _y1 - 2, _x2 + 5, _y2 + 7, 11, 11, false);

    draw_set_alpha(0.065);
    draw_roundrect_ext(_x1 - 1, _y1, _x2 + 3, _y2 + 5, 10, 10, false);

    draw_set_alpha(1);
    draw_set_color(_panel_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);

    draw_set_color(_panel_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    draw_set_alpha(0.65);
    draw_set_color(_panel_highlight);
    draw_line(_x1 + 10, _y1 + 2, _x2 - 10, _y1 + 2);

    draw_set_alpha(1);
    draw_set_color(c_white);
}


// ═══════════════════════════════════════════════════════════════
// 4. КНОПКИ ОБСЛЕДОВАНИЙ И ЛЕЧЕНИЯ
// ═══════════════════════════════════════════════════════════════

function tablet_animal_draw_action_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _label,
    _hovered,
    _enabled,
    _font_ui
) {
    var _fill = make_color_rgb(240, 232, 214);
    var _line = make_color_rgb(58, 39, 24);
    var _text_color = make_color_rgb(50, 38, 28);

    if (!_enabled) {
        _fill = make_color_rgb(205, 201, 194);
        _text_color = make_color_rgb(115, 112, 108);
    }
    else if (_hovered) {
        _fill = make_color_rgb(250, 242, 224);
    }

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 7, 7, false);

    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 7, 7, true);

    draw_set_color(_text_color);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(
        _x1 + 7,
        (_y1 + _y2) * 0.5,
        _label,
        11,
        ((_x2 - _x1) - 14) / max(0.01, CARD_FS_LABEL * _font_ui),
        CARD_FS_LABEL * _font_ui,
        CARD_FS_LABEL * _font_ui,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function tablet_animal_draw_treatment_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _label,
    _hovered,
    _enabled,
    _feedback_state,
    _font_ui
) {
    var _fill = make_color_rgb(240, 232, 214);
    var _line = make_color_rgb(58, 39, 24);
    var _text_color = make_color_rgb(50, 38, 28);

    if (_feedback_state > 0) {
        _fill = make_color_rgb(206, 232, 198);
        _line = make_color_rgb(58, 110, 62);
    }
    else if (_feedback_state < 0) {
        _fill = make_color_rgb(238, 206, 198);
        _line = make_color_rgb(140, 62, 56);
    }
    else if (!_enabled) {
        _fill = make_color_rgb(205, 201, 194);
        _text_color = make_color_rgb(115, 112, 108);
    }
    else if (_hovered) {
        _fill = make_color_rgb(250, 242, 224);
    }

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 7, 7, false);

    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 7, 7, true);

    draw_set_color(_text_color);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(
        _x1 + 7,
        (_y1 + _y2) * 0.5,
        _label,
        11,
        ((_x2 - _x1) - 14) / max(0.01, CARD_FS_LABEL * _font_ui),
        CARD_FS_LABEL * _font_ui,
        CARD_FS_LABEL * _font_ui,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// Отдельная крупная кнопка под колонкой в стиле «Кандидат».
// _style: "green", "red" или "gray".
function tablet_animal_draw_candidate_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _label,
    _hovered,
    _enabled,
    _style,
    _font_ui
) {
    var _wood_dark = make_color_rgb(74, 49, 31);
    var _inner_border = make_color_rgb(125, 125, 118);
    var _fill = make_color_rgb(210, 207, 199);
    var _text_color = make_color_rgb(105, 102, 98);

    if (_enabled && _style == "green") {
        _inner_border = make_color_rgb(104, 137, 91);
        _fill = _hovered
            ? make_color_rgb(220, 235, 208)
            : make_color_rgb(205, 224, 193);
        _text_color = make_color_rgb(45, 60, 40);
    }
    else if (_enabled && _style == "red") {
        _inner_border = make_color_rgb(148, 82, 72);
        _fill = _hovered
            ? make_color_rgb(242, 211, 203)
            : make_color_rgb(229, 194, 185);
        _text_color = make_color_rgb(105, 42, 38);
    }

    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 3, _y1 + 4, _x2 + 3, _y2 + 4, 10, 10, false);
    draw_set_alpha(1);

    draw_set_color(_wood_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);

    draw_set_color(_inner_border);
    draw_roundrect_ext(_x1 + 2, _y1 + 2, _x2 - 2, _y2 - 2, 8, 8, false);

    draw_set_color(_fill);
    draw_roundrect_ext(_x1 + 5, _y1 + 5, _x2 - 5, _y2 - 5, 6, 6, false);

    draw_set_color(_wood_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    // ПАКЕТ №290. Надпись на кнопке заметно крупнее.
    //
    // Попутно исправлена давняя мелочь: по горизонтали текст брал
    // CARD_FS_HEADER, а по вертикали CARD_FS_BUTTON — то есть буквы
    // были растянуты в ширину. Теперь оба масштаба одинаковые.
    //
    // Кегль общий и крупный, но длинные надписи вроде «СНАЧАЛА
    // ПОДТВЕРДИТЕ ДИАГНОЗ» шире кнопки не станут: если строка не
    // помещается, масштаб ужимается ровно под неё. Короткие надписи
    // («ОТМЕНА», «В СТАЦИОНАР») от этого не страдают и остаются
    // крупными.
    var _button_text_scale = CARD_FS_BUTTON * _font_ui;
    var _button_text_room = (_x2 - _x1) - 24;
    var _button_text_need = string_width(_label) * _button_text_scale;

    if (_button_text_need > _button_text_room && _button_text_need > 0) {
        _button_text_scale *= (_button_text_room / _button_text_need);
    }

    draw_set_color(_text_color);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5,
        _label,
        _button_text_scale,
        _button_text_scale,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ═══════════════════════════════════════════════════════════════
// 5. ЛЕТЯЩИЕ ПЛЮСЫ И МИНУСЫ
// ═══════════════════════════════════════════════════════════════

function tablet_animal_add_fly_effect(
    _tablet,
    _start_x,
    _start_y,
    _end_x,
    _end_y,
    _symbol,
    _color
) {
    if (!instance_exists(_tablet)) return;

    array_push(_tablet.fly_effects, {
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

function tablet_animal_draw_fly_effects(_tablet) {
    if (!instance_exists(_tablet)) return;

    for (var _effect_index = 0; _effect_index < array_length(_tablet.fly_effects); _effect_index++) {
        var _effect = _tablet.fly_effects[_effect_index];
        var _t = clamp(_effect.timer / max(1, _effect.timer_max), 0, 1);
        var _one_minus_t = 1 - _t;

        var _effect_x =
            (_one_minus_t * _one_minus_t * _effect.start_x)
            + (2 * _one_minus_t * _t * _effect.control_x)
            + (_t * _t * _effect.end_x);

        var _effect_y =
            (_one_minus_t * _one_minus_t * _effect.start_y)
            + (2 * _one_minus_t * _t * _effect.control_y)
            + (_t * _t * _effect.end_y);

        var _effect_alpha = 1;

        if (_t > 0.68) {
            _effect_alpha = 1 - ((_t - 0.68) / 0.32);
        }

        _effect_alpha = clamp(_effect_alpha, 0, 1);

        var _size = lerp(24, 15, _t);
        var _thickness = lerp(3, 1.5, _t);

        draw_set_alpha(_effect_alpha);

        draw_set_color(merge_color(_effect.color, c_white, 0.55));
        draw_circle(_effect_x, _effect_y, _size * 0.70, false);

        draw_set_color(c_black);
        draw_line_width(
            _effect_x - _size * 0.5 + 1,
            _effect_y + 1,
            _effect_x + _size * 0.5 + 1,
            _effect_y + 1,
            _thickness + 1
        );

        if (_effect.symbol == "+") {
            draw_line_width(
                _effect_x + 1,
                _effect_y - _size * 0.5 + 1,
                _effect_x + 1,
                _effect_y + _size * 0.5 + 1,
                _thickness + 1
            );
        }

        draw_set_color(_effect.color);
        draw_line_width(
            _effect_x - _size * 0.5,
            _effect_y,
            _effect_x + _size * 0.5,
            _effect_y,
            _thickness
        );

        if (_effect.symbol == "+") {
            draw_line_width(
                _effect_x,
                _effect_y - _size * 0.5,
                _effect_x,
                _effect_y + _size * 0.5,
                _thickness
            );
        }
    }

    draw_set_alpha(1);
}


// ═══════════════════════════════════════════════════════════════
// 6. ОСНОВНАЯ КАРТОЧКА ПИТОМЦА
// ═══════════════════════════════════════════════════════════════

function tablet_draw_animal_card(
    _tablet,
    _animal,
    _center_x,
    _center_y,
    _ui_scale,
    _frame_x,
    _frame_y,
    _photo_w,
    _photo_h,
    _mouse_x,
    _mouse_y
) {
    if (!instance_exists(_tablet)) return false;
    if (!instance_exists(_animal)) return false;

    var _wood_dark = make_color_rgb(74, 49, 31);
    var _text = make_color_rgb(50, 38, 28);
    var _text_soft = make_color_rgb(84, 68, 54);
    var _blue = make_color_rgb(72, 112, 145);
    var _green = make_color_rgb(62, 112, 74);
    var _red = make_color_rgb(148, 74, 64);


    // ═══════════════════════════════════════════════════════════
    // 6.1 СЕТКА И ОБЩИЙ ФОН
    // ═══════════════════════════════════════════════════════════

    var _font_ui = _ui_scale * 1.22;
    var _panel_gap = 7 * _ui_scale;
    var _padding = 9 * _ui_scale;

    var _column_title_y = _frame_y + 30 * _ui_scale;
    var _content_top = _frame_y + 54 * _ui_scale;
    // ПАКЕТ №290. Кнопки стали заметно выше.
    //
    // Под ними на планшете простаивало место: белый лист спрайта
    // кончается на 199 пунктах от центра, а кнопки заканчивались на
    // 170. Эти свободные пункты и отданы кнопкам, поэтому нижняя
    // граница контента опущена с 360 до 383.
    //
    // Панель с симптомами при этом не пострадала: она заканчивается
    // там же, где и раньше, и даже стала чуть выше.
    var _content_bottom = _frame_y + 383 * _ui_scale;

    // Обе колонки заканчиваются на одной линии, ниже остаётся место кнопкам.
    var _bottom_button_height = 44 * _ui_scale;
    var _panels_bottom = _content_bottom - _panel_gap - _bottom_button_height;

    var _left_x1 = _frame_x;
    var _left_x2 = _center_x - _panel_gap * 0.5;
    var _right_x1 = _center_x + _panel_gap * 0.5;
    var _right_x2 = _center_x + 260 * _ui_scale;

    // Перекрываем старый универсальный полароид и сохраняем светлый фон.
    draw_set_color(make_color_rgb(252, 250, 246));
    draw_rectangle(
        _left_x1 - 8 * _ui_scale,
        _frame_y - 12 * _ui_scale,
        _right_x2 + 8 * _ui_scale,
        _content_bottom + 8 * _ui_scale,
        false
    );


    // ═══════════════════════════════════════════════════════════
    // 6.2 ЗАГОЛОВКИ
    // ═══════════════════════════════════════════════════════════

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(_wood_dark);
    draw_text_transformed(
        _center_x,
        _frame_y - 6 * _ui_scale,
        "КАРТОЧКА ПИТОМЦА",
        CARD_FS_TITLE * _font_ui,
        CARD_FS_TITLE * _font_ui,
        0
    );

    draw_set_halign(fa_left);
    draw_text_transformed(
        _left_x1,
        _column_title_y,
        "ДАННЫЕ О ЖИВОТНОМ:",
        CARD_FS_HEADER * _font_ui,
        CARD_FS_HEADER * _font_ui,
        0
    );

    draw_text_transformed(
        _right_x1,
        _column_title_y,
        "КАРТА ПАЦИЕНТА:",
        CARD_FS_HEADER * _font_ui,
        CARD_FS_HEADER * _font_ui,
        0
    );


    // ═══════════════════════════════════════════════════════════
    // 6.3 ДАННЫЕ ПИТОМЦА
    // ═══════════════════════════════════════════════════════════

    var _species_name = tablet_animal_get_species_name(_animal);
    var _breed_name = variable_instance_exists(_animal, "breed")
        ? string(_animal.breed)
        : "Неизвестно";
    var _pet_name = variable_instance_exists(_animal, "char_name")
        ? string(_animal.char_name)
        : "Питомец";
    var _pet_age = variable_instance_exists(_animal, "age")
        ? string(_animal.age)
        : "Неизвестно";
    var _feature_name = variable_instance_exists(_animal, "animal_feature_name_ru")
        ? string(_animal.animal_feature_name_ru)
        : "Нет особенности";

    var _condition_value = variable_instance_exists(_animal, "condition")
        ? round(_animal.condition)
        : 100;
    var _condition_known = tablet_animal_condition_known(_animal);
    var _condition_text = _condition_known
        ? string(_condition_value) + "%"
        : "Неизвестно";


    var _confirmed = variable_instance_exists(_animal, "diagnosis_confirmed")
        ? _animal.diagnosis_confirmed
        : false;
    var _disease_name = "Не подтверждён";

    if (_confirmed && variable_instance_exists(_animal, "hidden_disease_id")) {
        _disease_name = tablet_animal_get_disease_name(_animal.hidden_disease_id);
    }

    var _symptom_text = tablet_animal_get_symptom_text(_animal);


    // ═══════════════════════════════════════════════════════════
    // 6.4 ЛЕВЫЙ ПРЯМОУГОЛЬНИК 1: ФОТО И ОСНОВНЫЕ ДАННЫЕ
    // ═══════════════════════════════════════════════════════════

    var _info_x1 = _left_x1;
    var _info_y1 = _content_top;
    var _info_x2 = _left_x2;
    var _info_y2 = _info_y1 + 118 * _ui_scale;

    tablet_animal_draw_panel(_info_x1, _info_y1, _info_x2, _info_y2);

    // Полароид с зелёным пластырем.
    var _portrait_frame_x = _info_x1 + _padding;
    var _portrait_frame_y = _info_y1 + 13 * _ui_scale;
    var _portrait_frame_w = _photo_w;
    var _portrait_frame_h = _photo_h;
    var _portrait_frame_x2 = _portrait_frame_x + _portrait_frame_w;
    var _portrait_frame_y2 = _portrait_frame_y + _portrait_frame_h;

    draw_set_color(make_color_rgb(255, 252, 210));
    draw_rectangle(
        _portrait_frame_x,
        _portrait_frame_y,
        _portrait_frame_x2,
        _portrait_frame_y2,
        false
    );

    draw_set_color(_wood_dark);
    draw_rectangle(
        _portrait_frame_x,
        _portrait_frame_y,
        _portrait_frame_x2,
        _portrait_frame_y2,
        true
    );

    var _portrait_inner_x = _portrait_frame_x + 5 * _ui_scale;
    var _portrait_inner_y = _portrait_frame_y + 5 * _ui_scale;
    var _portrait_inner_w = _portrait_frame_w - 10 * _ui_scale;
    var _portrait_inner_h = _portrait_inner_w * 1.15;

    draw_set_color(make_color_rgb(180, 180, 180));
    draw_rectangle(
        _portrait_inner_x,
        _portrait_inner_y,
        _portrait_inner_x + _portrait_inner_w,
        _portrait_inner_y + _portrait_inner_h,
        false
    );

    if (
        variable_instance_exists(_animal, "my_baked_portrait")
        && _animal.my_baked_portrait != -1
        && sprite_exists(_animal.my_baked_portrait)
    ) {
        draw_sprite_stretched(
            _animal.my_baked_portrait,
            0,
            _portrait_inner_x,
            _portrait_inner_y,
            _portrait_inner_w,
            _portrait_inner_h
        );
    }
    else if (sprite_exists(_animal.sprite_index)) {
        var _portrait_zoom = variable_instance_exists(_animal, "portrait_zoom")
            ? max(0.01, _animal.portrait_zoom)
            : 0.5;
        var _portrait_source_x = variable_instance_exists(_animal, "portrait_x")
            ? _animal.portrait_x
            : 50;
        var _portrait_source_y = variable_instance_exists(_animal, "portrait_y")
            ? _animal.portrait_y
            : 50;

        var _source_w = _portrait_inner_w / _portrait_zoom;
        var _source_h = _portrait_inner_h / _portrait_zoom;

        draw_sprite_general(
            _animal.sprite_index,
            0,
            _portrait_source_x,
            _portrait_source_y,
            _source_w,
            _source_h,
            _portrait_inner_x,
            _portrait_inner_y,
            _portrait_zoom,
            _portrait_zoom,
            0,
            c_white,
            c_white,
            c_white,
            c_white,
            1
        );
    }

    draw_set_color(_wood_dark);
    draw_rectangle(
        _portrait_inner_x,
        _portrait_inner_y,
        _portrait_inner_x + _portrait_inner_w,
        _portrait_inner_y + _portrait_inner_h,
        true
    );

    draw_set_color(make_color_rgb(106, 166, 104));
    draw_set_alpha(0.78);
    draw_line_width(
        _portrait_frame_x - 3,
        _portrait_frame_y + 8 * _ui_scale,
        _portrait_frame_x + 15 * _ui_scale,
        _portrait_frame_y - 3,
        4 * _ui_scale
    );
    draw_line_width(
        _portrait_frame_x2 - 15 * _ui_scale,
        _portrait_frame_y2 + 3,
        _portrait_frame_x2 + 3,
        _portrait_frame_y2 - 8 * _ui_scale,
        4 * _ui_scale
    );
    draw_set_alpha(1);

    // ═══════════════════════════════════════════════════════════
    // ПАКЕТ №289: ПЯТЬ СТРОК ДАННЫХ, СТРОГО ОДНА ПОД ДРУГОЙ
    //
    // Что было не так. «Возраст» рисовался на +80, а «Особенность»
    // на +101, но в РАЗНЫХ колонках: возраст в колонке значений, а
    // особенность — от левого края панели. При крупном шрифте
    // пакета 288 строки налезли друг на друга, и кличка со словом
    // «щенок» оказались в одном месте.
    //
    // Теперь порядок задан явно массивом и рисуется циклом с
    // постоянным шагом: Кличка, Вид, Порода, Возраст, Особенность.
    // Съезжать нечему: чтобы добавить строку, достаточно добавить
    // пару в массив.
    //
    // Ширина. Ярлык «Особенность:» самый длинный (145 px), а справа
    // от фото всего 302 px — на длинное значение вроде «Йоркширский
    // терьер» места не остаётся. Поэтому значение печатается через
    // ui_text_fit_middle: функция сама ужимает текст под остаток
    // строки, вместо того чтобы вылезать за край панели.
    // ═══════════════════════════════════════════════════════════

    var _info_text_x = _portrait_frame_x2 + 11 * _ui_scale;

    // Колонка значений отступает на ширину самого длинного ярлыка.
    var _info_value_x = _info_text_x + 74 * _ui_scale;

    var _info_rows = [
        ["Кличка:",      _pet_name,      _blue],
        ["Вид:",         _species_name,  _text],
        ["Порода:",      _breed_name,    _text],
        ["Возраст:",     _pet_age,       _text],
        ["Особенность:", _feature_name,  _text]
    ];

    var _info_row_y = _info_y1 + 11 * _ui_scale;
    var _info_row_step = 21 * _ui_scale;
    var _info_value_w = _info_x2 - _info_value_x - _padding;

    for (var _info_index = 0; _info_index < array_length(_info_rows); _info_index++) {
        var _info_row = _info_rows[_info_index];
        var _info_row_cy = _info_row_y + _info_index * _info_row_step;

        // Ярлык мельче значения — так глаз цепляется за данные.
        draw_set_color(_text_soft);
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_text_transformed(
            _info_text_x,
            _info_row_cy,
            _info_row[0],
            CARD_FS_SMALL * _font_ui,
            CARD_FS_SMALL * _font_ui,
            0
        );

        draw_set_color(_info_row[2]);
        ui_text_fit_middle(
            _info_value_x,
            _info_row_cy,
            _info_row[1],
            _info_value_w,
            CARD_FS_VALUE * _font_ui
        );
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);


    // ═══════════════════════════════════════════════════════════
    // 6.5 ЛЕВЫЙ ПРЯМОУГОЛЬНИК 2: СОСТОЯНИЕ, СИМПТОМЫ, ДИАГНОЗ
    //
    // ПАКЕТ №289. Панель переставлена сверху вниз:
    //   1. СОСТОЯНИЕ  — крупно, в самом верху;
    //   2. СИМПТОМЫ   — список, до пяти строк;
    //   3. ДИАГНОЗ    — прибит к низу.
    //
    // Убрана строка «ОБСЛЕДОВАНИЕ: частично» — она занимала место,
    // но по сути дублировала то, что и так видно по симптомам и
    // диагнозу. Убраны и блоки «ПРОВЕДЕНО»/«НАЗНАЧЕНО» из пакета
    // 288: назначенное лечение показывает правое окно на странице
    // «Лечение», а здесь на них уже нет места.
    //
    // СКОЛЬКО СИМПТОМОВ БЫВАЕТ. Проверено по базе болезней: у 43
    // болезней из 50 их три, у шести — четыре, максимум пять (у
    // вирусной инфекции). Скрытые симптомы, которые открывает
    // case_reveal_hidden_symptoms, берутся из того же списка, так
    // что потолок остаётся пять.
    //
    // Самое длинное название — «Повышенное слюнотечение», строка
    // «- ...» шириной 213 px при масштабе 1, то есть 355 px при
    // CARD_FS_VALUE. Панель даёт 438 px, значит переносов нет и
    // каждый симптом занимает ровно одну строку.
    //
    // По высоте: панель 259 px. Состояние, заголовок, пять строк
    // симптомов и диагноз при межстрочном ×1.1 требуют 254 px —
    // помещается с запасом 5 px. Межстрочный ×1.2 уже не влезал бы.
    // ═══════════════════════════════════════════════════════════

    var _case_x1 = _left_x1;
    var _case_y1 = _info_y2 + _panel_gap;
    var _case_x2 = _left_x2;
    var _case_y2 = _panels_bottom;
    var _case_text_w = _case_x2 - _case_x1 - _padding * 2;

    tablet_animal_draw_panel(_case_x1, _case_y1, _case_x2, _case_y2);

    // Якоря нижних строк считаются заранее: список симптомов должен
    // знать, где заканчивается его место.
    //
    // ПАКЕТ №290: ДИАГНОЗ В ДВЕ СТРОКИ.
    //
    // Проверены все 50 диагнозов из базы. Строкой «ДИАГНОЗ: Название»
    // не помещались 13 из них — самый длинный «Вирусная энтеритная
    // инфекция» требовал 622 px при доступных 438.
    //
    // Теперь слово «ДИАГНОЗ:» стоит отдельной строкой сверху мелким
    // шрифтом, а название болезни идёт под ним крупно и во всю ширину
    // панели. После этого не помещается только одно название из
    // пятидесяти (та же вирусная энтеритная инфекция, 461 px), и оно
    // само ужимается на 5% — незаметно на глаз.
    var _condition_y = _case_y2 - 19 * _ui_scale;
    var _diagnosis_name_y = _case_y2 - 18 * _ui_scale;
    var _diagnosis_y = _diagnosis_name_y - 12 * _ui_scale;


    // ── 1. СОСТОЯНИЕ (вверху, крупно) ──

    var _condition_color = make_color_rgb(90, 90, 90);

    if (_condition_known) {
        _condition_color = merge_color(
            make_color_rgb(180, 40, 40),
            make_color_rgb(40, 160, 60),
            clamp(_condition_value, 0, 100) / 100
        );
    }

    var _condition_line = "СОСТОЯНИЕ: " + _condition_text;
    var _condition_top_y = _case_y1 + 10 * _ui_scale;

    // Вспышка от лечения теперь подсвечивает верхнюю строку.
    var _condition_draw_x = _case_x1 + _padding;
    var _condition_target_x = _condition_draw_x + 125 * _ui_scale;
    var _condition_target_y = _condition_top_y + 8 * _ui_scale;
    var _condition_scale = CARD_FS_HEADER * _font_ui;

    if (_tablet.condition_flash_timer > 0) {
        var _flash_t = _tablet.condition_flash_timer
            / max(1, _tablet.condition_flash_timer_max);
        var _shake_x = sin((1 - _flash_t) * 18) * 2 * _flash_t;
        var _shake_y = cos((1 - _flash_t) * 14) * _flash_t;
        var _pulse_scale = 1 + 0.10 * _flash_t;

        draw_set_alpha(0.22 * _flash_t);
        draw_set_color(_tablet.condition_flash_color);
        draw_roundrect_ext(
            _condition_draw_x - 4,
            _condition_top_y - 2,
            _condition_draw_x + 175 * _ui_scale,
            _condition_top_y + 20 * _ui_scale,
            6,
            6,
            false
        );

        draw_set_alpha(1);
        draw_set_color(_condition_color);
        draw_text_transformed(
            _condition_draw_x + _shake_x,
            _condition_top_y + _shake_y,
            _condition_line,
            _condition_scale * _pulse_scale,
            _condition_scale * _pulse_scale,
            0
        );
    } else {
        draw_set_color(_condition_color);
        draw_text_transformed(
            _condition_draw_x,
            _condition_top_y,
            _condition_line,
            _condition_scale,
            _condition_scale,
            0
        );
    }


    // ── 2. СИМПТОМЫ ──

    var _symptoms_title_y = _condition_top_y + 20 * _ui_scale;

    draw_set_color(_wood_dark);
    draw_text_transformed(
        _case_x1 + _padding,
        _symptoms_title_y,
        "СИМПТОМЫ:",
        CARD_FS_LABEL * _font_ui,
        CARD_FS_LABEL * _font_ui,
        0
    );

    var _symptom_list_y = _symptoms_title_y + 14 * _ui_scale;
    var _symptom_space = (_diagnosis_y - 4 * _ui_scale) - _symptom_list_y;

    // Межстрочный интервал ужимается, если симптомов много: пять
    // строк должны поместиться между заголовком и диагнозом.
    var _symptom_count = 0;

    if (
        variable_instance_exists(_animal, "visible_symptoms")
        && is_array(_animal.visible_symptoms)
    ) {
        _symptom_count = array_length(_animal.visible_symptoms);
    }

    // Высота самой строки — кегль; между N строками всего N-1
    // промежутков. Делить всю высоту на N нельзя: последняя
    // строка свешивалась бы на свою высоту вниз — расчёт давал
    // переполнение на пяти симптомах.
    var _symptom_line_h = CARD_FS_VALUE * _font_ui * 12;
    var _symptom_step = _symptom_line_h * 1.10;

    if (_symptom_count > 1) {
        _symptom_step = min(
            _symptom_step,
            (_symptom_space - _symptom_line_h) / (_symptom_count - 1)
        );
    }

    // Страховка на случай, если симптомов когда-нибудь станет
    // больше пяти. Сейчас по базе потолок ровно пять, и при
    // пяти строки идут полным шагом. Если в будущем болезни
    // добавят шестой симптом, шрифт списка чуть уменьшится
    // вместо того, чтобы последняя строка наехала на диагноз.
    var _symptom_scale = CARD_FS_VALUE * _font_ui;

    if (_symptom_count > 1) {
        var _symptom_need = (_symptom_count - 1) * _symptom_step + _symptom_line_h;

        if (_symptom_need > _symptom_space && _symptom_need > 0) {
            _symptom_scale *= (_symptom_space / _symptom_need);
            _symptom_step *= (_symptom_space / _symptom_need);
        }
    }

    draw_set_color(_text_soft);
    draw_text_ext_transformed(
        _case_x1 + _padding,
        _symptom_list_y,
        _symptom_text,
        _symptom_step,
        _case_text_w / max(0.01, _symptom_scale),
        _symptom_scale,
        _symptom_scale,
        0
    );


    // ── 3. ДИАГНОЗ (внизу, со вспышкой пакета 288) ──

    var _diagnosis_scale = CARD_FS_DIAGNOSIS * _font_ui;

    // Вспышка накрывает обе строки сразу.
    var _diagnosis_pulse = tablet_card_draw_diagnosis_flash(
        _case_x1 + _padding,
        _diagnosis_y,
        _case_x2 - _padding,
        _diagnosis_name_y + 16 * _ui_scale,
        _tablet.card_diagnosis_flash_timer,
        _tablet.card_diagnosis_flash_timer_max
    );

    var _diagnosis_color = _confirmed ? _red : make_color_rgb(120, 75, 70);

    // Строка 1: само слово «ДИАГНОЗ:» — мелко, это лишь подпись.
    draw_set_color(_diagnosis_color);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text_transformed(
        _case_x1 + _padding,
        _diagnosis_y,
        "ДИАГНОЗ:",
        CARD_FS_LABEL * _font_ui,
        CARD_FS_LABEL * _font_ui,
        0
    );

    // Строка 2: название болезни — крупно, во всю ширину панели.
    // Единственное название, которое всё же шире панели, ужимается
    // ровно под неё, а не обрезается и не переносится.
    var _diagnosis_name_scale = _diagnosis_scale * _diagnosis_pulse;
    var _diagnosis_name_need = string_width(_disease_name) * _diagnosis_name_scale;

    if (_diagnosis_name_need > _case_text_w && _diagnosis_name_need > 0) {
        _diagnosis_name_scale *= (_case_text_w / _diagnosis_name_need);
    }

    draw_text_transformed(
        _case_x1 + _padding,
        _diagnosis_name_y,
        _disease_name,
        _diagnosis_name_scale,
        _diagnosis_name_scale,
        0
    );


    // ═══════════════════════════════════════════════════════════
    // 6.6 РЕЖИМ РАБОТЫ ИГРОКА
    // ═══════════════════════════════════════════════════════════

    var _player = instance_exists(obj_player)
        ? instance_find(obj_player, 0)
        : noone;

    var _doctor_assign_mode = false;
    var _procedure_exec_mode = false;
    var _inpatient_active = (
        variable_instance_exists(_animal, "inpatient_active")
        && _animal.inpatient_active
    );
    var _inpatient_ward = _inpatient_active
        ? inpatient_get_ward_for_pet(_animal)
        : noone;
    var _inpatient_manual_assign = false;
    var _inpatient_manual_procedure = false;
    var _therapy_level = 1;

    if (instance_exists(_player) && variable_instance_exists(_player, "therapy_level")) {
        _therapy_level = _player.therapy_level;
    }

    if (
        instance_exists(_player)
        && variable_instance_exists(_animal, "assigned_doctor")
        && _animal.assigned_doctor == _player
    ) {
        _inpatient_manual_assign = (
            _inpatient_active
            && variable_instance_exists(_player, "inpatient_manual_task")
            && _player.inpatient_manual_task == "assign"
        );
        _inpatient_manual_procedure = (
            _inpatient_active
            && variable_instance_exists(_player, "inpatient_manual_task")
            && _player.inpatient_manual_task == "treat"
        );

        _doctor_assign_mode = (
            _player.doctor_state == "manual_exam"
            && (!_inpatient_active || _inpatient_manual_assign)
            && doctor_visit_player_ready_for_actions(
                _player,
                _animal
            )
        );
        _procedure_exec_mode = (
            _player.doctor_state == "manual_procedure"
            && (!_inpatient_active || _inpatient_manual_procedure)
        );

        // В стационаре количество ложных вариантов и назначения
        // зависят только от нового навыка Стационар.
        if (_inpatient_manual_assign) {
            _therapy_level = doctor_get_inpatient_level(_player);
        } else {
            // Пакет №71: Библиотека добавляет +N к Терапии игрока —
            // меньше ложных вариантов в карточке пациента.
            _therapy_level = clamp(
                _therapy_level + clinic_get_library_bonus(),
                1,
                10
            );
        }
    }


    // ═══════════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════
    // 6.7 ПРАВАЯ КОЛОНКА: ОДНА ПАНЕЛЬ С ДВУМЯ СТРАНИЦАМИ
    //
    // ПАКЕТ №288. Раньше здесь было две панели по половине высоты:
    // «Обследования» сверху, «Лечение» снизу. Кнопки в них были по
    // 14–18 пикселей — в такую на телефоне не попасть пальцем.
    //
    // Теперь панель одна во всю высоту колонки, а внутри сменяются
    // страницы. Кнопок столько же, но каждая почти вдвое выше.
    //
    // Порядок: сначала считаем данные и решаем, не пора ли листнуть
    // страницу, потом рисуем. Иначе переворот запаздывал бы на кадр.
    // ═══════════════════════════════════════════════════════════

    var _page_x1 = _right_x1;
    var _page_y1 = _content_top;
    var _page_x2 = _right_x2;
    var _page_y2 = _panels_bottom;

    var _case_struct = (
        variable_instance_exists(_animal, "current_case")
        && is_struct(_animal.current_case)
    )
        ? _animal.current_case
        : undefined;


    // ── Списки вариантов ──

    var _diagnostic_choices = [];
    var _choice_list = [];

    if (is_struct(_case_struct)) {
        _diagnostic_choices = case_get_visible_diagnostics(
            _case_struct,
            _therapy_level
        );

        if (_doctor_assign_mode) {
            _choice_list = case_get_visible_treatment(
                _case_struct,
                _therapy_level
            );

            if (!variable_struct_exists(_case_struct, "visit_treatment_feedback_ok_ids")) {
                _case_struct.visit_treatment_feedback_ok_ids = [];
            }

            if (!variable_struct_exists(_case_struct, "visit_treatment_feedback_bad_ids")) {
                _case_struct.visit_treatment_feedback_bad_ids = [];
            }

            if (!variable_struct_exists(_case_struct, "prescribed_treatment_ids")) {
                _case_struct.prescribed_treatment_ids = [];
            }

            if (!variable_struct_exists(_case_struct, "visit_prescribed_actions")) {
                _case_struct.visit_prescribed_actions = [];
            }
        }
    }

    // ── ПАКЕТ №350: диагноз уже подтверждён — на странице
    // «ОБСЛЕДОВАНИЯ» показываем только то, что реально проводили
    // (нужное и лишнее). Полный список кандидатов, включая ложные,
    // нужен, пока диагноз не поставлен; после — он только путает.
    if (_confirmed && is_struct(_case_struct)) {
        var _performed_choices = [];

        for (var _pc = 0; _pc < array_length(_diagnostic_choices); _pc++) {
            if (tablet_animal_diagnostic_feedback_state(
                _case_struct,
                _diagnostic_choices[_pc].diagnostic_id
            ) != 0) {
                array_push(_performed_choices, _diagnostic_choices[_pc]);
            }
        }

        _diagnostic_choices = _performed_choices;
    }

    var _pending_actions = [];

    if (
        _procedure_exec_mode
        && is_struct(_case_struct)
        && variable_struct_exists(_case_struct, "pending_procedure_actions")
    ) {
        _pending_actions = _case_struct.pending_procedure_actions;
    }


    // ═══════════════════════════════════════════════════════════
    // 6.7.1 СМЕНА ПАЦИЕНТА И АВТОМАТИЧЕСКИЙ ПЕРЕВОРОТ ЛИСТА
    //
    // Диагноз подтверждён — правая страница сама переворачивается с
    // обследований на лечение. Ловим именно ПЕРЕХОД false → true,
    // иначе анимация запускалась бы каждый кадр.
    // ═══════════════════════════════════════════════════════════

    if (_tablet.card_page_animal != _animal) {
        _tablet.card_page_animal = _animal;

        // ── ПАКЕТ №350: если у животного уже подтверждён диагноз,
        // карточка открывается сразу на «ЛЕЧЕНИИ» — там назначенное
        // лечение. Проведённые обследования остаются на своей
        // закладке, но без ложных кандидатов (см. ниже).
        _tablet.card_page = _confirmed
            ? CARD_PAGE_TREATMENT
            : CARD_PAGE_DIAGNOSTICS;

        _tablet.card_flip_timer = 0;
        _tablet.card_diagnosis_flash_timer = 0;
        _tablet.card_diagnosis_was_confirmed = _confirmed;
    }

    if (_confirmed && !_tablet.card_diagnosis_was_confirmed) {
        _tablet.card_flip_timer = _tablet.card_flip_timer_max;
        _tablet.card_diagnosis_flash_timer = _tablet.card_diagnosis_flash_timer_max;
        _tablet.card_page = CARD_PAGE_TREATMENT;
    }

    _tablet.card_diagnosis_was_confirmed = _confirmed;

    // В процедурном режиме обследовать уже нечего — сразу лечение.
    if (_procedure_exec_mode) {
        _tablet.card_page = CARD_PAGE_TREATMENT;
    }

    // Страница лечения открыта, когда есть что на ней показать.
    var _treatment_unlocked = (
        _confirmed
        || _procedure_exec_mode
        || array_length(_choice_list) > 0
    );

    if (!_treatment_unlocked) {
        _tablet.card_page = CARD_PAGE_DIAGNOSTICS;
    }


    // ═══════════════════════════════════════════════════════════
    // 6.7.2 ПАНЕЛЬ, ЗАКЛАДКИ И ЭФФЕКТ ПЕРЕВОРОТА
    // ═══════════════════════════════════════════════════════════

    tablet_animal_draw_panel(_page_x1, _page_y1, _page_x2, _page_y2);

    var _tabs_y1 = _page_y1 + 7 * _ui_scale;
    var _tabs_y2 = _tabs_y1 + 26 * _ui_scale;

    var _tab_clicked = tablet_card_draw_page_tabs(
        _page_x1 + _padding,
        _tabs_y1,
        _page_x2 - _padding,
        _tabs_y2,
        _tablet.card_page,
        _treatment_unlocked,
        _mouse_x,
        _mouse_y,
        _font_ui
    );

    if (_tab_clicked >= 0 && _tablet.tablet_click_lock <= 0) {
        _tablet.tablet_click_lock = 5;

        // Ручное перелистывание тоже показываем переворотом листа.
        if (_tab_clicked != _tablet.card_page) {
            _tablet.card_page = _tab_clicked;
            _tablet.card_flip_timer = _tablet.card_flip_timer_max;
        }

        return false;
    }

    // Во время переворота показываем строку уровня терапии только
    // на странице лечения — она к обследованиям не относится.
    if (_doctor_assign_mode && _tablet.card_page == CARD_PAGE_TREATMENT) {
        draw_set_color(_blue);
        draw_set_halign(fa_right);
        draw_text_transformed(
            _page_x2 - _padding,
            _tabs_y2 + 5 * _ui_scale,
            "ТЕРАПИЯ " + string(_therapy_level) + " УР.",
            CARD_FS_SMALL * _font_ui,
            CARD_FS_SMALL * _font_ui,
            0
        );
        draw_set_halign(fa_left);
    }

    var _list_y1 = _tabs_y2 + 22 * _ui_scale;
    var _list_y2 = _page_y2 - 8 * _ui_scale;
    var _list_h = _list_y2 - _list_y1;

    // Множитель ширины: 1 в покое, сжимается к правому краю в анимации.
    var _flip_factor = tablet_card_flip_width_factor(
        _tablet.card_flip_timer,
        _tablet.card_flip_timer_max
    );

    var _flip_full_x1 = _page_x1 + _padding;
    var _flip_full_x2 = _page_x2 - _padding;
    var _flip_full_w = _flip_full_x2 - _flip_full_x1;

    // Лист «складывается» к правому краю панели.
    var _button_x1 = _flip_full_x2 - _flip_full_w * _flip_factor;
    var _button_x2 = _flip_full_x2;

    // На середине переворота содержимое почти невидимо — рисовать
    // кнопки шириной в пару пикселей смысла нет, а клики по ним
    // были бы случайными. Поэтому в этот момент список пропускаем.
    var _flip_running = (_tablet.card_flip_timer > 0);
    var _list_visible = (_flip_factor > 0.25);

    // Пока лист в движении, клики по списку не принимаем.
    var _clicks_allowed = !_flip_running;

    // Какую страницу показывать: до середины ещё старую, после — новую.
    var _draw_page = _tablet.card_page;

    if (
        _flip_running
        && !tablet_card_flip_shows_new_page(
            _tablet.card_flip_timer,
            _tablet.card_flip_timer_max
        )
    ) {
        _draw_page = (_tablet.card_page == CARD_PAGE_TREATMENT)
            ? CARD_PAGE_DIAGNOSTICS
            : CARD_PAGE_TREATMENT;
    }


    // ═══════════════════════════════════════════════════════════
    // 6.7.3 СТРАНИЦА «ОБСЛЕДОВАНИЯ»
    // ═══════════════════════════════════════════════════════════

    if (_draw_page == CARD_PAGE_DIAGNOSTICS && _list_visible) {
        var _diagnostic_count = array_length(_diagnostic_choices);

        if (_diagnostic_count <= 0) {
            var _empty_text = _confirmed
                ? "ОБСЛЕДОВАНИЯ НЕ ПРОВОДИЛИСЬ"
                : "НЕТ ДОСТУПНЫХ ОБСЛЕДОВАНИЙ";

            draw_set_color(_text_soft);
            draw_set_halign(fa_center);
            draw_text_ext_transformed(
                (_button_x1 + _button_x2) * 0.5,
                _list_y1 + 18 * _ui_scale,
                _empty_text,
                15,
                (_button_x2 - _button_x1) / max(0.01, CARD_FS_LABEL * _font_ui),
                CARD_FS_LABEL * _font_ui,
                CARD_FS_LABEL * _font_ui,
                0
            );
            draw_set_halign(fa_left);
        }

        var _diagnostic_gap = 8 * _ui_scale;
        var _diagnostic_button_h = tablet_card_button_height(
            _list_h,
            _diagnostic_count,
            _diagnostic_gap,
            _ui_scale
        );

        for (var _diagnostic_index = 0; _diagnostic_index < _diagnostic_count; _diagnostic_index++) {
            var _diagnostic_choice = _diagnostic_choices[_diagnostic_index];
            var _diagnostic_id = _diagnostic_choice.diagnostic_id;
            var _diagnostic_is_correct = variable_struct_exists(_diagnostic_choice, "is_correct")
                ? _diagnostic_choice.is_correct
                : true;
            var _diagnostic_name = db_get_diagnostic_name(_diagnostic_id);

            var _diagnostic_button_y1 = _list_y1
                + _diagnostic_index * (_diagnostic_button_h + _diagnostic_gap);
            var _diagnostic_button_y2 = _diagnostic_button_y1 + _diagnostic_button_h;

            var _diagnostic_hovered = _clicks_allowed
                && point_in_rectangle(
                    _mouse_x,
                    _mouse_y,
                    _button_x1,
                    _diagnostic_button_y1,
                    _button_x2,
                    _diagnostic_button_y2
                );

            var _diagnostic_feedback = tablet_animal_diagnostic_feedback_state(
                _case_struct,
                _diagnostic_id
            );

            var _diagnostic_can_press = _doctor_assign_mode
                && _diagnostic_feedback == 0;

            tablet_card_draw_list_button(
                _button_x1,
                _diagnostic_button_y1,
                _button_x2,
                _diagnostic_button_y2,
                _diagnostic_name,
                _diagnostic_hovered,
                _diagnostic_can_press,
                _diagnostic_feedback,
                _font_ui
            );

            if (
                _diagnostic_can_press
                && _clicks_allowed
                && _tablet.tablet_click_lock <= 0
                && _diagnostic_hovered
                && mouse_check_button_pressed(mb_left)
            ) {
                _tablet.tablet_click_lock = 5;

                if (_diagnostic_is_correct) {
                    animal_perform_diagnostic(_animal, _diagnostic_id);

                    if (instance_exists(obj_UI_HUD)) {
                        var _hud_diagnostic_ok = instance_find(obj_UI_HUD, 0);

                        if (instance_exists(_hud_diagnostic_ok)) {
                            with (_hud_diagnostic_ok) {
                                show_notice(
                                    "ДИАГНОСТИКА",
                                    db_get_diagnostic_name(_diagnostic_id),
                                    room_speed * 2
                                );
                            }
                        }
                    }
                } else {
                    case_apply_wrong_diagnostic_choice(_animal, _diagnostic_id);

                    if (instance_exists(obj_UI_HUD)) {
                        var _hud_diagnostic_bad = instance_find(obj_UI_HUD, 0);

                        if (instance_exists(_hud_diagnostic_bad)) {
                            with (_hud_diagnostic_bad) {
                                show_notice(
                                    "ЛИШНЕЕ ОБСЛЕДОВАНИЕ",
                                    db_get_diagnostic_name(_diagnostic_id),
                                    room_speed * 2
                                );
                            }
                        }
                    }
                }

                return false;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 6.7.4 СТРАНИЦА «ЛЕЧЕНИЕ»: ВРАЧ НАЗНАЧАЕТ
    // ═══════════════════════════════════════════════════════════

    if (
        _draw_page == CARD_PAGE_TREATMENT
        && _list_visible
        && _doctor_assign_mode
    ) {
        var _choice_count = array_length(_choice_list);

        if (_choice_count <= 0) {
            draw_set_color(_text_soft);
            draw_set_halign(fa_center);
            draw_text_ext_transformed(
                (_button_x1 + _button_x2) * 0.5,
                _list_y1 + 18 * _ui_scale,
                "СНАЧАЛА ПОДТВЕРДИТЕ ДИАГНОЗ",
                15,
                (_button_x2 - _button_x1) / max(0.01, CARD_FS_LABEL * _font_ui),
                CARD_FS_LABEL * _font_ui,
                CARD_FS_LABEL * _font_ui,
                0
            );
            draw_set_halign(fa_left);
        }

        var _choice_gap = 7 * _ui_scale;
        var _choice_button_h = tablet_card_button_height(
            _list_h,
            _choice_count,
            _choice_gap,
            _ui_scale
        );

        for (var _choice_index = 0; _choice_index < _choice_count; _choice_index++) {
            var _choice = _choice_list[_choice_index];
            var _action_id = _choice.action_id;
            var _is_correct = variable_struct_exists(_choice, "is_correct")
                ? _choice.is_correct
                : true;
            var _action_name = db_get_treatment_action_name(_action_id);

            var _choice_y1 = _list_y1
                + _choice_index * (_choice_button_h + _choice_gap);
            var _choice_y2 = _choice_y1 + _choice_button_h;

            var _choice_hovered = _clicks_allowed
                && point_in_rectangle(
                    _mouse_x,
                    _mouse_y,
                    _button_x1,
                    _choice_y1,
                    _button_x2,
                    _choice_y2
                );

            var _feedback_state = tablet_animal_feedback_state(
                _case_struct,
                _action_id
            );

            var _can_press = (_feedback_state == 0);

            tablet_card_draw_list_button(
                _button_x1,
                _choice_y1,
                _button_x2,
                _choice_y2,
                _action_name,
                _choice_hovered,
                _can_press,
                _feedback_state,
                _font_ui
            );

            if (
                _can_press
                && _clicks_allowed
                && _tablet.tablet_click_lock <= 0
                && _choice_hovered
                && mouse_check_button_pressed(mb_left)
            ) {
                _tablet.tablet_click_lock = 5;

                if (_is_correct) {
                    case_assign_treatment_action(_animal, _action_id);

                    // Пакет №113: операция стартует автоматически при назначении
                    // (бригада сама готовится и оперирует).
                    if (operating_action_is_surgery(_action_id)) {
                        operating_request(_animal, _action_id);
                    }

                    tablet_animal_add_fly_effect(
                        _tablet,
                        (_button_x1 + _button_x2) * 0.5,
                        (_choice_y1 + _choice_y2) * 0.5,
                        _condition_target_x,
                        _condition_target_y,
                        "+",
                        make_color_rgb(70, 210, 90)
                    );

                    if (
                        instance_exists(_player)
                        && !_inpatient_active
                    ) {
                        doctor_visit_award_manual_outpatient_xp(
                            _player,
                            _animal
                        );
                    }

                    if (instance_exists(obj_UI_HUD)) {
                        var _hud_ok = instance_find(obj_UI_HUD, 0);

                        if (instance_exists(_hud_ok)) {
                            with (_hud_ok) {
                                show_notice(
                                    "НАЗНАЧЕНО",
                                    db_get_treatment_action_name(_action_id),
                                    room_speed * 2
                                );
                            }
                        }
                    }
                } else {
                    case_apply_wrong_prescription_choice(_animal, _action_id);

                    tablet_animal_add_fly_effect(
                        _tablet,
                        (_button_x1 + _button_x2) * 0.5,
                        (_choice_y1 + _choice_y2) * 0.5,
                        _condition_target_x,
                        _condition_target_y,
                        "-",
                        make_color_rgb(220, 70, 70)
                    );

                    if (instance_exists(obj_UI_HUD)) {
                        var _hud_bad = instance_find(obj_UI_HUD, 0);

                        if (instance_exists(_hud_bad)) {
                            with (_hud_bad) {
                                show_notice(
                                    "ОШИБКА НАЗНАЧЕНИЯ",
                                    db_get_treatment_action_name(_action_id),
                                    room_speed * 2
                                );
                            }
                        }
                    }
                }

                return false;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 6.7.5 СТРАНИЦА «ЛЕЧЕНИЕ»: ИГРОК ВЫПОЛНЯЕТ ПРОЦЕДУРЫ
    // ═══════════════════════════════════════════════════════════

    if (
        _draw_page == CARD_PAGE_TREATMENT
        && _list_visible
        && _procedure_exec_mode
    ) {
        var _procedure_count = array_length(_pending_actions);
        var _procedure_gap = 7 * _ui_scale;
        var _procedure_button_h = tablet_card_button_height(
            _list_h,
            _procedure_count,
            _procedure_gap,
            _ui_scale
        );

        for (var _procedure_index = 0; _procedure_index < _procedure_count; _procedure_index++) {
            var _procedure_action_id = _pending_actions[_procedure_index];
            var _procedure_name = db_get_treatment_action_name(_procedure_action_id);
            var _procedure_stock_status = {
                ok : true,
                missing_item_id : "",
                missing_item_name : ""
            };

            if (
                _inpatient_manual_procedure
                && instance_exists(_inpatient_ward)
            ) {
                _procedure_stock_status = inpatient_get_action_stock_status(
                    _inpatient_ward,
                    _procedure_action_id
                );

                if (!_procedure_stock_status.ok) {
                    _procedure_name += " (НЕТ В ШКАФУ)";
                }
            }

            var _procedure_y1 = _list_y1
                + _procedure_index * (_procedure_button_h + _procedure_gap);
            var _procedure_y2 = _procedure_y1 + _procedure_button_h;

            var _procedure_hovered = _clicks_allowed
                && point_in_rectangle(
                    _mouse_x,
                    _mouse_y,
                    _button_x1,
                    _procedure_y1,
                    _button_x2,
                    _procedure_y2
                );

            var _already_done = tablet_animal_action_done_this_visit(
                _case_struct,
                _procedure_action_id
            );

            var _procedure_feedback = tablet_animal_feedback_state(
                _case_struct,
                _procedure_action_id
            );

            tablet_card_draw_list_button(
                _button_x1,
                _procedure_y1,
                _button_x2,
                _procedure_y2,
                _procedure_name,
                _procedure_hovered,
                !_already_done,
                _procedure_feedback,
                _font_ui
            );

            if (
                !_already_done
                && _clicks_allowed
                && _tablet.tablet_click_lock <= 0
                && _procedure_hovered
                && mouse_check_button_pressed(mb_left)
            ) {
                _tablet.tablet_click_lock = 5;

                var _condition_gain = treatment_get_condition_delta(_procedure_action_id);
                var _procedure_applied = false;

                if (
                    _inpatient_manual_procedure
                    && instance_exists(_inpatient_ward)
                ) {
                    var _inpatient_result = inpatient_apply_treatment_action(
                        _inpatient_ward,
                        _procedure_action_id
                    );
                    _procedure_applied = _inpatient_result.ok;
                } else {
                    _procedure_applied = case_apply_treatment_action(
                        _animal,
                        _procedure_action_id
                    );
                }

                if (_procedure_applied && instance_exists(_player)) {
                    player_add_assistant_skill_xp(_player, 0, 5, true);

                    with (_player) {
                        add_xp_log("+5 ПРОЦЕДУРЫ");
                    }
                }

                if (_procedure_applied && _condition_gain > 0) {
                    tablet_animal_add_fly_effect(
                        _tablet,
                        (_button_x1 + _button_x2) * 0.5,
                        (_procedure_y1 + _procedure_y2) * 0.5,
                        _condition_target_x,
                        _condition_target_y,
                        "+",
                        make_color_rgb(70, 210, 90)
                    );
                }

                if (_procedure_applied && instance_exists(obj_UI_HUD)) {
                    var _hud_procedure = instance_find(obj_UI_HUD, 0);

                    if (instance_exists(_hud_procedure)) {
                        with (_hud_procedure) {
                            show_notice(
                                "ПРОЦЕДУРА",
                                db_get_treatment_action_name(_procedure_action_id),
                                room_speed * 2
                            );
                        }
                    }
                }

                return false;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 6.7.6 СТРАНИЦА «ЛЕЧЕНИЕ» БЕЗ ПРАВА ПРАВКИ
    //
    // Карточка открыта простым тапом, не на приёме. Кнопок нет —
    // показываем, что уже назначено. Раньше здесь было пусто.
    // ═══════════════════════════════════════════════════════════

    if (
        _draw_page == CARD_PAGE_TREATMENT
        && _list_visible
        && !_doctor_assign_mode
        && !_procedure_exec_mode
    ) {
        var _passive_ids = [];

        if (
            is_struct(_case_struct)
            && variable_struct_exists(_case_struct, "prescribed_treatment_ids")
        ) {
            _passive_ids = _case_struct.prescribed_treatment_ids;
        }

        var _passive_count = array_length(_passive_ids);

        if (_passive_count <= 0) {
            draw_set_color(_text_soft);
            draw_set_halign(fa_center);
            draw_text_ext_transformed(
                (_button_x1 + _button_x2) * 0.5,
                _list_y1 + 18 * _ui_scale,
                "ЛЕЧЕНИЕ ЕЩЁ НЕ НАЗНАЧЕНО",
                15,
                (_button_x2 - _button_x1) / max(0.01, CARD_FS_LABEL * _font_ui),
                CARD_FS_LABEL * _font_ui,
                CARD_FS_LABEL * _font_ui,
                0
            );
            draw_set_halign(fa_left);
        }

        var _passive_gap = 7 * _ui_scale;
        var _passive_h = tablet_card_button_height(
            _list_h,
            _passive_count,
            _passive_gap,
            _ui_scale
        );

        for (var _passive_index = 0; _passive_index < _passive_count; _passive_index++) {
            var _passive_id = _passive_ids[_passive_index];
            var _passive_y1 = _list_y1
                + _passive_index * (_passive_h + _passive_gap);
            var _passive_y2 = _passive_y1 + _passive_h;

            // Наведения и нажатия нет: это справка, а не пульт.
            tablet_card_draw_list_button(
                _button_x1,
                _passive_y1,
                _button_x2,
                _passive_y2,
                db_get_treatment_action_name(_passive_id),
                false,
                false,
                1,
                _font_ui
            );
        }
    }


    // Блик на ребре листа поверх содержимого страницы.
    tablet_card_draw_flip_edge(
        _flip_full_x1,
        _list_y1,
        _flip_full_x2,
        _list_y2,
        _tablet.card_flip_timer,
        _tablet.card_flip_timer_max
    );


    // ═══════════════════════════════════════════════════════════
    // 6.9 НИЖНИЕ КНОПКИ ДЕЙСТВИЙ
    // Слева — отказ от приёма, справа — подтверждение назначений.
    // ═══════════════════════════════════════════════════════════

    var _bottom_button_y1 = _panels_bottom + _panel_gap;
    var _bottom_button_y2 = _bottom_button_y1 + _bottom_button_height;

    if (_doctor_assign_mode) {
        var _has_any_assignment = false;
        var _animal_condition_for_ward = variable_instance_exists(_animal, "condition")
            ? _animal.condition
            : 100;

        if (
            variable_instance_exists(_animal, "current_case")
            && is_struct(_animal.current_case)
            && variable_struct_exists(_animal.current_case, "condition")
        ) {
            _animal_condition_for_ward = _animal.current_case.condition;
        }

        var _can_send_to_inpatient = (
            _animal_condition_for_ward < 50
            && inpatient_can_admit(_animal)
        );

        if (variable_instance_exists(_animal, "current_case") && is_struct(_animal.current_case)) {
            var _active_case = _animal.current_case;

            if (
                variable_struct_exists(_active_case, "visit_prescribed_actions")
                && array_length(_active_case.visit_prescribed_actions) > 0
            ) {
                _has_any_assignment = true;
            }

            if (
                variable_struct_exists(_active_case, "visit_treatment_feedback_ok_ids")
                && array_length(_active_case.visit_treatment_feedback_ok_ids) > 0
            ) {
                _has_any_assignment = true;
            }

            if (
                variable_struct_exists(_active_case, "visit_treatment_feedback_bad_ids")
                && array_length(_active_case.visit_treatment_feedback_bad_ids) > 0
            ) {
                _has_any_assignment = true;
            }
        }

        var _assign_hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _right_x1,
            _bottom_button_y1,
            _right_x2,
            _bottom_button_y2
        );

        var _assign_button_enabled = _has_any_assignment || _can_send_to_inpatient;
        var _assign_button_label = _can_send_to_inpatient
            ? "В СТАЦИОНАР"
            : "НАЗНАЧИТЬ ЛЕЧЕНИЕ";

        tablet_animal_draw_candidate_button(
            _right_x1,
            _bottom_button_y1,
            _right_x2,
            _bottom_button_y2,
            _assign_button_label,
            _assign_hovered,
            _assign_button_enabled,
            _assign_button_enabled ? "green" : "gray",
            _font_ui
        );

        if (
            _assign_button_enabled
            && _tablet.tablet_click_lock <= 0
            && _assign_hovered
            && mouse_check_button_pressed(mb_left)
        ) {
            _tablet.tablet_click_lock = 5;

            var _ward_owner = variable_instance_exists(_animal, "my_owner")
                ? _animal.my_owner
                : noone;
            var _ward_player = _player;

            if (
                _inpatient_manual_assign
                && instance_exists(_player)
            ) {
                inpatient_player_finish_assignments(
                    _player,
                    _animal
                );
            } else {
                if (instance_exists(_player)) {
                    with (_player) {
                        player_finish_exam(true);
                    }
                }

                if (
                    _can_send_to_inpatient
                    && instance_exists(_ward_owner)
                    && instance_exists(_ward_player)
                ) {
                    inpatient_start_admission(
                        _ward_owner,
                        _animal,
                        _ward_player
                    );
                }
            }

            _tablet.visible = false;
            _tablet.target_id = noone;
            return true;
        }

        var _cancel_hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _left_x1,
            _bottom_button_y1,
            _left_x2,
            _bottom_button_y2
        );

        tablet_animal_draw_candidate_button(
            _left_x1,
            _bottom_button_y1,
            _left_x2,
            _bottom_button_y2,
            "ОТМЕНА",
            _cancel_hovered,
            true,
            "red",
            _font_ui
        );

        if (
            _tablet.tablet_click_lock <= 0
            && _cancel_hovered
            && mouse_check_button_pressed(mb_left)
        ) {
            _tablet.tablet_click_lock = 5;

            if (_inpatient_manual_assign && instance_exists(_player)) {
                inpatient_player_cancel_task(_player);
            }
            else if (instance_exists(_player)) {
                with (_player) {
                    player_finish_exam(false);
                }
            }

            _tablet.visible = false;
            _tablet.target_id = noone;
            return true;
        }
    }
    else if (_procedure_exec_mode) {
        // Как и при назначении, в процедурном режиме используются две кнопки.
        var _has_completed_procedure = false;
        var _stock_blocked = false;

        if (variable_instance_exists(_animal, "current_case") && is_struct(_animal.current_case)) {
            var _procedure_case = _animal.current_case;

            if (
                variable_struct_exists(_procedure_case, "visit_treatments_done")
                && array_length(_procedure_case.visit_treatments_done) > 0
            ) {
                _has_completed_procedure = true;
            }

            _stock_blocked = variable_struct_exists(_procedure_case, "stock_blocked")
                && _procedure_case.stock_blocked;
        }

        // Слева: досрочно закончить текущий процедурный приём.
        var _procedure_cancel_hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _left_x1,
            _bottom_button_y1,
            _left_x2,
            _bottom_button_y2
        );

        tablet_animal_draw_candidate_button(
            _left_x1,
            _bottom_button_y1,
            _left_x2,
            _bottom_button_y2,
            "ОТМЕНА",
            _procedure_cancel_hovered,
            true,
            "red",
            _font_ui
        );

        if (
            _tablet.tablet_click_lock <= 0
            && _procedure_cancel_hovered
            && mouse_check_button_pressed(mb_left)
        ) {
            _tablet.tablet_click_lock = 5;

            if (_inpatient_manual_procedure && instance_exists(_player)) {
                inpatient_player_cancel_task(_player);
            }
            else if (instance_exists(_player)) {
                with (_player) {
                    player_finish_procedure_visit();
                }
            }

            _tablet.visible = false;
            _tablet.target_id = noone;
            return true;
        }

        // Справа: подтверждение выполненных процедур.
        // Пока ни одна процедура не выполнена, кнопка серая и заблокирована.
        var _procedure_finish_hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _right_x1,
            _bottom_button_y1,
            _right_x2,
            _bottom_button_y2
        );

        var _right_action_enabled = _stock_blocked || _has_completed_procedure;
        var _right_action_label = _stock_blocked
            ? "ПОПОЛНИТЬ ШКАФ"
            : "ВЫПОЛНИТЬ ЛЕЧЕНИЕ";

        if (
            _inpatient_manual_procedure
            && instance_exists(_inpatient_ward)
        ) {
            _right_action_enabled = _stock_blocked
                || inpatient_player_all_actions_done(_inpatient_ward);
            _right_action_label = _stock_blocked
                ? "ПОПОЛНИТЬ ШКАФ"
                : "ВЫПОЛНИТЬ НАЗНАЧЕНИЯ";
        }

        tablet_animal_draw_candidate_button(
            _right_x1,
            _bottom_button_y1,
            _right_x2,
            _bottom_button_y2,
            _right_action_label,
            _procedure_finish_hovered,
            _right_action_enabled,
            _right_action_enabled ? "green" : "gray",
            _font_ui
        );

        if (
            _right_action_enabled
            && _tablet.tablet_click_lock <= 0
            && _procedure_finish_hovered
            && mouse_check_button_pressed(mb_left)
        ) {
            _tablet.tablet_click_lock = 5;

            if (_stock_blocked) {
                if (_inpatient_manual_procedure && instance_exists(_player)) {
                    // Стационарный пациент остаётся на койке. Игрок освобождается
                    // и может обычным способом пополнить шкаф стационара.
                    inpatient_player_cancel_task(_player);
                }
                // Обычный процедурный приём сохраняет прежний режим пополнения.
                else if (instance_exists(_player)) {
                    with (_player) {
                        doctor_state = "manual_procedure_restock";
                        path_end();
                        is_walking = false;
                    }
                }
            }
            else if (_inpatient_manual_procedure && instance_exists(_player)) {
                inpatient_player_finish_treatment(_player, _animal);
            }
            else if (instance_exists(_player)) {
                with (_player) {
                    player_finish_procedure_visit();
                }
            }

            _tablet.visible = false;
            _tablet.target_id = noone;
            return true;
        }
    }
    else if (_inpatient_active && instance_exists(_inpatient_ward)) {
        // Пассивная карточка стационарного пациента позволяет главному игроку
        // вручную занять место отсутствующего врача или ассистента.
        var _player_free_for_ward = (
            instance_exists(_player)
            && _player.doctor_state == "idle"
        );

        // Пакет №219: состояние здоровья пациента койки. При 100%
        // назначать и выполнять лечение нельзя — пациент ждёт владельца.
        var _ward_condition_now = 0;

        if (
            variable_instance_exists(_animal, "current_case")
            && is_struct(_animal.current_case)
            && variable_struct_exists(_animal.current_case, "condition")
        ) {
            _ward_condition_now = _animal.current_case.condition;
        }
        else if (variable_instance_exists(_animal, "condition")) {
            _ward_condition_now = _animal.condition;
        }

        var _ward_full_health = (
            _ward_condition_now >= 100
            && !(
                variable_instance_exists(_animal, "or_waiting_surgery")
                && _animal.or_waiting_surgery
            )
        );

        var _can_player_assign = (
            _player_free_for_ward
            && !_ward_full_health
            && _inpatient_ward.phase == "waiting_doctor"
            && !instance_exists(_inpatient_ward.ward_doctor)
        );
        var _can_player_treat = (
            _player_free_for_ward
            && !_ward_full_health
            && _inpatient_ward.phase == "waiting_cycle"
            && inpatient_now_absolute_minute()
                >= _inpatient_ward.next_treatment_minute
            && array_length(_inpatient_ward.treatment_actions) > 0
            && !instance_exists(_inpatient_ward.ward_assistant)
        );

        var _ward_action_label = "ПАЦИЕНТ В СТАЦИОНАРЕ";
        var _ward_action_enabled = false;
        var _ward_task = "";

        if (_can_player_assign) {
            _ward_action_label = "НАЗНАЧИТЬ ЛЕЧЕНИЕ";
            _ward_action_enabled = true;
            _ward_task = "assign";
        }
        else if (_can_player_treat) {
            _ward_action_label = "ВЫПОЛНИТЬ НАЗНАЧЕНИЯ";
            _ward_action_enabled = true;
            _ward_task = "treat";
        }
        else if (_ward_full_health) {
            _ward_action_label = "ВЫЗДОРОВЕЛ: ЖДЁТ ВЛАДЕЛЬЦА";
        }
        else if (
            _inpatient_ward.phase == "waiting_cycle"
            && _inpatient_ward.next_treatment_minute
                > inpatient_now_absolute_minute()
        ) {
            var _minutes_left = _inpatient_ward.next_treatment_minute
                - inpatient_now_absolute_minute();
            _ward_action_label = "СЛЕДУЮЩИЕ НАЗНАЧЕНИЯ: "
                + string(_minutes_left)
                + " МИН.";
        }
        else if (
            _inpatient_ward.phase == "player_assigning"
            || _inpatient_ward.phase == "player_treating"
            || _inpatient_ward.phase == "player_going_assign"
            || _inpatient_ward.phase == "player_going_treat"
        ) {
            _ward_action_label = "ИГРОК РАБОТАЕТ";
        }
        else if (
            instance_exists(_inpatient_ward.ward_doctor)
            || instance_exists(_inpatient_ward.ward_assistant)
        ) {
            _ward_action_label = "ПЕРСОНАЛ РАБОТАЕТ";
        }

        var _ward_action_hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _right_x1,
            _bottom_button_y1,
            _right_x2,
            _bottom_button_y2
        );

        tablet_animal_draw_candidate_button(
            _right_x1,
            _bottom_button_y1,
            _right_x2,
            _bottom_button_y2,
            _ward_action_label,
            _ward_action_hovered,
            _ward_action_enabled,
            _ward_action_enabled ? "green" : "gray",
            _font_ui
        );

        if (
            _ward_action_enabled
            && _tablet.tablet_click_lock <= 0
            && _ward_action_hovered
            && mouse_check_button_pressed(mb_left)
        ) {
            _tablet.tablet_click_lock = 5;

            if (inpatient_player_request_task(_animal, _ward_task)) {
                _tablet.visible = false;
                _tablet.target_id = noone;
                return true;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 6.10 ЛЕТЯЩИЕ ЭФФЕКТЫ И СБРОС DRAW
    // ═══════════════════════════════════════════════════════════

    tablet_animal_draw_fly_effects(_tablet);

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);

    return false;
}
