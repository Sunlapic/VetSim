/// tablet_draw_candidate_card.gml
/// @description Точная копия карточки сотрудника с двумя открытыми навыками и кнопками найма.
/// Пакет №79: специализация показывается только у врачей, у ассистентов — нет.
/// Пакет №159: специализация врача считается по самому прокачанному навыку.

// Вспомогательные функции портрета и панелей берутся из установленного
// Script Asset tablet_draw_staff_card, поэтому размеры и стиль не расходятся.
// doctor_get_specialty_title тоже живёт в tablet_draw_staff_card.

function tablet_draw_candidate_card(
    _tablet,
    _target,
    _center_x,
    _center_y,
    _ui_scale,
    _frame_x,
    _frame_y,
    _photo_w,
    _photo_h
) {
    if (!instance_exists(_tablet)) return false;
    if (!instance_exists(_target)) return false;

    var _wood_dark = make_color_rgb(74, 49, 31);
    var _text = make_color_rgb(50, 38, 28);
    var _text_soft = make_color_rgb(84, 68, 54);
    var _blue = make_color_rgb(72, 112, 145);
    var _green = make_color_rgb(62, 112, 74);
    var _red = make_color_rgb(148, 74, 64);
    var _gold = make_color_rgb(180, 140, 64);


    // ═══════════════════════════════════════════════════════════
    // 3.1 СЕТКА: 1/3 ДАННЫЕ, 2/3 НАВЫКИ
    // ═══════════════════════════════════════════════════════════

    var _font_ui = _ui_scale * 1.16;
    var _gap = 7 * _ui_scale;
    var _padding = 8 * _ui_scale;

    // Верхние панели стоят на том же отступе от заголовка,
    // что и остальные панели друг от друга.
    var _content_top = _frame_y + 22 * _ui_scale;
    var _content_bottom = _frame_y + 304 * _ui_scale;

    // Подсказка остаётся внутри светлого листа.
    var _help_y1 = _content_bottom + _gap;
    var _help_y2 = _help_y1 + 65 * _ui_scale;

    var _card_x1 = _frame_x;
    var _card_x2 = _center_x + 260 * _ui_scale;
    var _total_width = _card_x2 - _card_x1;

    var _left_x1 = _card_x1;
    var _left_x2 = _card_x1 + _total_width * 0.34;
    var _right_x1 = _left_x2 + _gap;
    var _right_x2 = _card_x2;

    // Закрываем старую универсальную разметку планшета.
    draw_set_color(make_color_rgb(252, 250, 246));
    draw_rectangle(
        _card_x1 - 8 * _ui_scale,
        _frame_y - 12 * _ui_scale,
        _card_x2 + 8 * _ui_scale,
        _help_y2 + 8 * _ui_scale,
        false
    );


    // ═══════════════════════════════════════════════════════════
    // 3.2 ЗАГОЛОВОК
    // ═══════════════════════════════════════════════════════════

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(_wood_dark);
    draw_text_transformed(
        _center_x,
        _frame_y - 6 * _ui_scale,
        "КАРТОЧКА КАНДИДАТА",
        0.78 * _font_ui,
        0.84 * _font_ui,
        0
    );

    draw_set_halign(fa_left);


    // ═══════════════════════════════════════════════════════════
    // 3.3 ЛЕВАЯ ВЕРХНЯЯ ПАНЕЛЬ: ФОТО И ДАННЫЕ
    // ═══════════════════════════════════════════════════════════

    var _info_x1 = _left_x1;
    var _info_y1 = _content_top;
    var _info_x2 = _left_x2;
    var _info_y2 = _info_y1 + 182 * _ui_scale;

    tablet_staff_draw_panel(_info_x1, _info_y1, _info_x2, _info_y2);

    // Полароид.
    var _portrait_x = _info_x1 + _padding;
    var _portrait_y = _info_y1 + 13 * _ui_scale;
    var _portrait_w = _photo_w;
    var _portrait_h = _photo_h;

    draw_set_color(make_color_rgb(255, 252, 210));
    draw_rectangle(
        _portrait_x,
        _portrait_y,
        _portrait_x + _portrait_w,
        _portrait_y + _portrait_h,
        false
    );

    draw_set_color(_wood_dark);
    draw_rectangle(
        _portrait_x,
        _portrait_y,
        _portrait_x + _portrait_w,
        _portrait_y + _portrait_h,
        true
    );

    var _portrait_inner_x = _portrait_x + 5 * _ui_scale;
    var _portrait_inner_y = _portrait_y + 5 * _ui_scale;
    var _portrait_inner_w = _portrait_w - 10 * _ui_scale;
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
        variable_instance_exists(_target, "my_baked_portrait")
        && _target.my_baked_portrait != -1
        && sprite_exists(_target.my_baked_portrait)
    ) {
        draw_sprite_stretched(
            _target.my_baked_portrait,
            0,
            _portrait_inner_x,
            _portrait_inner_y,
            _portrait_inner_w,
            _portrait_inner_h
        );
    } else {
        // Главный игрок может не иметь baked portrait — рисуем его слоями.
        var _portrait_zoom = variable_instance_exists(_target, "portrait_zoom")
            ? _target.portrait_zoom
            : 1;
        var _portrait_source_x = variable_instance_exists(_target, "portrait_x")
            ? _target.portrait_x
            : 150;
        var _portrait_source_y = variable_instance_exists(_target, "portrait_y")
            ? _target.portrait_y
            : 50;

        tablet_staff_draw_portrait_part(
            spr_human_FR_walk,
            _portrait_inner_x,
            _portrait_inner_y,
            _portrait_inner_w,
            _portrait_inner_h,
            _portrait_zoom,
            _portrait_source_x,
            _portrait_source_y,
            c_white
        );

        if (variable_instance_exists(_target, "my_nose")) {
            tablet_staff_draw_portrait_part(_target.my_nose, _portrait_inner_x, _portrait_inner_y, _portrait_inner_w, _portrait_inner_h, _portrait_zoom, _portrait_source_x, _portrait_source_y, c_white);
        }

        if (variable_instance_exists(_target, "my_eyes")) {
            tablet_staff_draw_portrait_part(_target.my_eyes, _portrait_inner_x, _portrait_inner_y, _portrait_inner_w, _portrait_inner_h, _portrait_zoom, _portrait_source_x, _portrait_source_y, c_white);
        }

        if (variable_instance_exists(_target, "my_mouth")) {
            tablet_staff_draw_portrait_part(_target.my_mouth, _portrait_inner_x, _portrait_inner_y, _portrait_inner_w, _portrait_inner_h, _portrait_zoom, _portrait_source_x, _portrait_source_y, c_white);
        }

        if (variable_instance_exists(_target, "my_hair")) {
            var _portrait_hair_color = variable_instance_exists(_target, "hair_color")
                ? _target.hair_color
                : c_white;

            tablet_staff_draw_portrait_part(_target.my_hair, _portrait_inner_x, _portrait_inner_y, _portrait_inner_w, _portrait_inner_h, _portrait_zoom, _portrait_source_x, _portrait_source_y, _portrait_hair_color);
        }
    }

    draw_set_color(_wood_dark);
    draw_rectangle(
        _portrait_inner_x,
        _portrait_inner_y,
        _portrait_inner_x + _portrait_inner_w,
        _portrait_inner_y + _portrait_inner_h,
        true
    );

    var _tape_color = c_blue;
    var _role = variable_instance_exists(_target, "role") ? _target.role : "";

    if (_role == "assistant") _tape_color = make_color_rgb(110, 170, 110);
    if (_role == "admin") _tape_color = c_fuchsia;

    draw_set_color(_tape_color);
    draw_set_alpha(0.75);
    draw_line_width(
        _portrait_x - 3,
        _portrait_y + 8 * _ui_scale,
        _portrait_x + 15 * _ui_scale,
        _portrait_y - 3,
        4 * _ui_scale
    );
    draw_line_width(
        _portrait_x + _portrait_w - 15 * _ui_scale,
        _portrait_y + _portrait_h + 3,
        _portrait_x + _portrait_w + 3,
        _portrait_y + _portrait_h - 8 * _ui_scale,
        4 * _ui_scale
    );
    draw_set_alpha(1);

    // Текст справа от фотографии.
    var _data_x = _portrait_x + _portrait_w + 9 * _ui_scale;
    var _data_w = _info_x2 - _data_x - _padding;

    var _name = variable_instance_exists(_target, "char_name")
        ? string(_target.char_name)
        : "Сотрудник";
    var _age = variable_instance_exists(_target, "age")
        ? string(_target.age)
        : "?";
    var _role_name = tablet_staff_get_role_name(_target);
    var _specialty = doctor_get_specialty_title(_target);
    var _trait = tablet_staff_get_trait_name(_target);

    _target.specialty_title = _specialty;

    draw_set_color(_blue);
    draw_text_ext_transformed(
        _data_x,
        _info_y1 + 12 * _ui_scale,
        string_upper(_name),
        14 * _ui_scale,
        _data_w,
        0.58 * _font_ui,
        0.64 * _font_ui,
        0
    );

    draw_set_color(_text);
    draw_text_transformed(_data_x, _info_y1 + 42 * _ui_scale, "Возраст: " + _age, 0.46 * _font_ui, 0.51 * _font_ui, 0);

    draw_set_color(_text_soft);
    draw_text_ext_transformed(
        _data_x,
        _info_y1 + 62 * _ui_scale,
        "Роль: " + _role_name,
        12 * _ui_scale,
        _data_w,
        0.44 * _font_ui,
        0.49 * _font_ui,
        0
    );

    // Пакет №79: специализация есть только у врачей.
    // У администраторов и ассистентов строку полностью пропускаем.
    var _trait_y = _info_y1 + 107 * _ui_scale;

    if (_role == "doctor") {
        draw_text_ext_transformed(
            _data_x,
            _info_y1 + 83 * _ui_scale,
            (_specialty != "" ? "Специализация: " + _specialty : ""),
            12 * _ui_scale,
            _data_w,
            0.41 * _font_ui,
            0.46 * _font_ui,
            0
        );
    } else {
        // Освободившееся место занимает строка характера.
        _trait_y = _info_y1 + 83 * _ui_scale;
    }

    draw_text_ext_transformed(
        _data_x,
        _trait_y,
        "Характер: " + _trait,
        12 * _ui_scale,
        _data_w,
        0.41 * _font_ui,
        0.46 * _font_ui,
        0
    );


    // ═══════════════════════════════════════════════════════════
    // 3.4 ЭНЕРГИЯ, ЗАРПЛАТА И ЛОЯЛЬНОСТЬ
    // ═══════════════════════════════════════════════════════════

    var _energy_current = variable_instance_exists(_target, "stat_energy")
        ? _target.stat_energy
        : 100;
    var _energy_max = variable_instance_exists(_target, "energy_max")
        ? max(1, _target.energy_max)
        : 100;
    var _energy_ratio = clamp(_energy_current / _energy_max, 0, 1);

    var _energy_y = _info_y1 + 132 * _ui_scale;
    var _energy_x1 = _info_x1 + _padding;
    var _energy_x2 = _info_x2 - _padding;
    var _energy_color = _green;

    if (_energy_ratio <= 0.10) _energy_color = _red;
    else if (_energy_ratio <= 0.30) _energy_color = _gold;

    draw_set_color(_text_soft);
    draw_text_transformed(
        _energy_x1,
        _energy_y,
        "ЭНЕРГИЯ " + string(floor(_energy_current)) + "/" + string(round(_energy_max)),
        0.42 * _font_ui,
        0.47 * _font_ui,
        0
    );

    var _energy_bar_y = _energy_y + 16 * _ui_scale;

    draw_set_color(make_color_rgb(220, 216, 207));
    draw_roundrect_ext(_energy_x1, _energy_bar_y, _energy_x2, _energy_bar_y + 7 * _ui_scale, 7, 7, false);

    draw_set_color(_energy_color);
    draw_roundrect_ext(
        _energy_x1,
        _energy_bar_y,
        _energy_x1 + (_energy_x2 - _energy_x1) * _energy_ratio,
        _energy_bar_y + 7 * _ui_scale,
        7,
        7,
        false
    );

    draw_set_color(_wood_dark);
    draw_roundrect_ext(_energy_x1, _energy_bar_y, _energy_x2, _energy_bar_y + 7 * _ui_scale, 7, 7, true);

    var _salary = variable_instance_exists(_target, "salary_expected")
        ? _target.salary_expected
        : (
            variable_instance_exists(_target, "salary")
            ? _target.salary
            : 0
        );

    // Строка занимает то же место и использует тот же шрифт,
    // что зарплата и лояльность в обычной карточке сотрудника.
    draw_set_color(_text);
    draw_text_transformed(
        _energy_x1,
        _info_y1 + 165 * _ui_scale,
        "Ожидаемая з/п/день: $ " + string(_salary),
        0.40 * _font_ui,
        0.45 * _font_ui,
        0
    );

    draw_text_transformed(
        _energy_x1 + 112 * _ui_scale,
        _info_y1 + 165 * _ui_scale,
        "Кандидат",
        0.40 * _font_ui,
        0.45 * _font_ui,
        0
    );


    // ═══════════════════════════════════════════════════════════
    // 3.5 ЛЕВАЯ НИЖНЯЯ ПАНЕЛЬ: ПОСЛЕДНИЕ НАВЫКИ
    // ═══════════════════════════════════════════════════════════

    var _log_x1 = _left_x1;
    var _log_y1 = _info_y2 + _gap;
    var _log_x2 = _left_x2;
    var _log_y2 = _content_bottom;

    tablet_staff_draw_panel(_log_x1, _log_y1, _log_x2, _log_y2);

    draw_set_color(_wood_dark);
    draw_text_transformed(
        _log_x1 + _padding,
        _log_y1 + 8 * _ui_scale,
        "ПОСЛЕДНИЕ НАВЫКИ:",
        0.47 * _font_ui,
        0.52 * _font_ui,
        0
    );

    var _log_entries = variable_instance_exists(_target, "xp_log")
        ? _target.xp_log
        : [];

    if (array_length(_log_entries) <= 0) {
        draw_set_color(make_color_rgb(120, 110, 95));
        draw_text_transformed(
            _log_x1 + _padding,
            _log_y1 + 34 * _ui_scale,
            "Нет записей",
            0.42 * _font_ui,
            0.47 * _font_ui,
            0
        );
    } else {
        for (var _log_index = 0; _log_index < min(5, array_length(_log_entries)); _log_index++) {
            var _entry = _log_entries[_log_index];
            var _entry_text = "";

            if (is_struct(_entry) && variable_struct_exists(_entry, "txt")) {
                _entry_text = string(_entry.txt);
            } else {
                _entry_text = string(_entry);
            }

            if (_entry_text == "") continue;

            draw_set_alpha(1 - _log_index * 0.12);
            draw_set_color(make_color_rgb(40, 110, 50));
            draw_text_ext_transformed(
                _log_x1 + _padding,
                _log_y1 + (30 + _log_index * 13) * _ui_scale,
                _entry_text,
                12 * _ui_scale,
                _log_x2 - _log_x1 - _padding * 2,
                0.42 * _font_ui,
                0.47 * _font_ui,
                0
            );
        }
    }

    draw_set_alpha(1);


    // ═══════════════════════════════════════════════════════════
    // 3.6 ПРАВАЯ ПАНЕЛЬ: ВСЕ НАВЫКИ
    // ═══════════════════════════════════════════════════════════

    tablet_staff_draw_panel(
        _right_x1,
        _content_top,
        _right_x2,
        _content_bottom
    );

    tablet_draw_candidate_skills(
        _target,
        _right_x1 + _padding,
        _content_top + _padding,
        _right_x2 - _right_x1 - _padding * 2,
        _ui_scale
    );


    // ═══════════════════════════════════════════════════════════
    // 3.7 НИЖНЯЯ ПАНЕЛЬ: ОТКАЗАТЬ И НАНЯТЬ
    // Размер панели полностью совпадает с подсказкой карточки сотрудника.
    // ═══════════════════════════════════════════════════════════

    tablet_staff_draw_panel(
        _card_x1,
        _help_y1,
        _card_x2,
        _help_y2
    );

    var _button_padding = 8 * _ui_scale;
    var _button_gap = 10 * _ui_scale;
    var _button_y1 = _help_y1 + _button_padding;
    var _button_y2 = _help_y2 - _button_padding;
    var _button_w = (
        _card_x2 - _card_x1 - _button_padding * 2 - _button_gap
    ) * 0.5;

    _tablet.reject_x1 = _card_x1 + _button_padding;
    _tablet.reject_y1 = _button_y1;
    _tablet.reject_x2 = _tablet.reject_x1 + _button_w;
    _tablet.reject_y2 = _button_y2;

    _tablet.hire_x1 = _tablet.reject_x2 + _button_gap;
    _tablet.hire_y1 = _button_y1;
    _tablet.hire_x2 = _card_x2 - _button_padding;
    _tablet.hire_y2 = _button_y2;

    var _candidate_mouse_x = device_mouse_x_to_gui(0);
    var _candidate_mouse_y = device_mouse_y_to_gui(0);
    var _reject_hover = point_in_rectangle(
        _candidate_mouse_x,
        _candidate_mouse_y,
        _tablet.reject_x1,
        _tablet.reject_y1,
        _tablet.reject_x2,
        _tablet.reject_y2
    );
    var _hire_hover = point_in_rectangle(
        _candidate_mouse_x,
        _candidate_mouse_y,
        _tablet.hire_x1,
        _tablet.hire_y1,
        _tablet.hire_x2,
        _tablet.hire_y2
    );

    // Кнопка отказа.
    draw_set_color(_wood_dark);
    draw_roundrect_ext(
        _tablet.reject_x1,
        _tablet.reject_y1,
        _tablet.reject_x2,
        _tablet.reject_y2,
        9,
        9,
        false
    );

    draw_set_color(make_color_rgb(148, 82, 72));
    draw_roundrect_ext(
        _tablet.reject_x1 + 2 * _ui_scale,
        _tablet.reject_y1 + 2 * _ui_scale,
        _tablet.reject_x2 - 2 * _ui_scale,
        _tablet.reject_y2 - 2 * _ui_scale,
        7,
        7,
        false
    );

    draw_set_color(
        _reject_hover
            ? make_color_rgb(242, 211, 203)
            : make_color_rgb(229, 194, 185)
    );
    draw_roundrect_ext(
        _tablet.reject_x1 + 5 * _ui_scale,
        _tablet.reject_y1 + 5 * _ui_scale,
        _tablet.reject_x2 - 5 * _ui_scale,
        _tablet.reject_y2 - 5 * _ui_scale,
        5,
        5,
        false
    );

    // Кнопка найма.
    draw_set_color(_wood_dark);
    draw_roundrect_ext(
        _tablet.hire_x1,
        _tablet.hire_y1,
        _tablet.hire_x2,
        _tablet.hire_y2,
        9,
        9,
        false
    );

    draw_set_color(make_color_rgb(104, 137, 91));
    draw_roundrect_ext(
        _tablet.hire_x1 + 2 * _ui_scale,
        _tablet.hire_y1 + 2 * _ui_scale,
        _tablet.hire_x2 - 2 * _ui_scale,
        _tablet.hire_y2 - 2 * _ui_scale,
        7,
        7,
        false
    );

    draw_set_color(
        _hire_hover
            ? make_color_rgb(220, 235, 208)
            : make_color_rgb(205, 224, 193)
    );
    draw_roundrect_ext(
        _tablet.hire_x1 + 5 * _ui_scale,
        _tablet.hire_y1 + 5 * _ui_scale,
        _tablet.hire_x2 - 5 * _ui_scale,
        _tablet.hire_y2 - 5 * _ui_scale,
        5,
        5,
        false
    );

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_red);
    draw_text_transformed(
        (_tablet.reject_x1 + _tablet.reject_x2) * 0.5,
        (_tablet.reject_y1 + _tablet.reject_y2) * 0.5,
        "ОТКАЗАТЬ",
        0.58 * _font_ui,
        0.64 * _font_ui,
        0
    );

    draw_set_color(_green);
    draw_text_transformed(
        (_tablet.hire_x1 + _tablet.hire_x2) * 0.5,
        (_tablet.hire_y1 + _tablet.hire_y2) * 0.5,
        "НАНЯТЬ",
        0.58 * _font_ui,
        0.64 * _font_ui,
        0
    );


    // ═══════════════════════════════════════════════════════════
    // 3.8 СБРОС DRAW
    // ═══════════════════════════════════════════════════════════

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);

    return true;
}
