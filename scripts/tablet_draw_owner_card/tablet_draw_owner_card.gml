/// tablet_draw_owner_card.gml
/// @description Отдельная карточка владельца. Не затрагивает UI животных и персонала.


// ═══════════════════════════════════════════════════════════════
// 1. СОСТОЯНИЕ ПИТОМЦА ИЗВЕСТНО ПОСЛЕ ФИЗИКАЛЬНОГО ОСМОТРА
// ═══════════════════════════════════════════════════════════════

function tablet_owner_condition_known(_pet) {
    if (!instance_exists(_pet)) return false;
    if (!variable_instance_exists(_pet, "current_case")) return false;
    if (!is_struct(_pet.current_case)) return false;
    if (!variable_struct_exists(_pet.current_case, "completed_diagnostics")) return false;

    var _diagnostics = _pet.current_case.completed_diagnostics;

    for (var _index = 0; _index < array_length(_diagnostics); _index++) {
        if (_diagnostics[_index] == "diag_physical_exam") {
            return true;
        }
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 2. ПОНЯТНЫЙ СТАТУС ВЛАДЕЛЬЦА
// ═══════════════════════════════════════════════════════════════

function tablet_owner_get_status(_owner) {
    if (!instance_exists(_owner)) return "НЕИЗВЕСТНО";

    var _state = variable_instance_exists(_owner, "state")
        ? string(_owner.state)
        : "";

    var _queue_type = variable_instance_exists(_owner, "service_queue_type")
        ? string(_owner.service_queue_type)
        : "doctor";

    var _queue_purpose = variable_instance_exists(_owner, "queue_purpose")
        ? string(_owner.queue_purpose)
        : "registration";

    switch (_state) {
        case "spawned":
            return "ПРИБЫЛ В КЛИНИКУ";

        case "going_to_queue":
            return (_queue_purpose == "payment")
                ? "ИДЁТ НА ОПЛАТУ"
                : "ИДЁТ К РЕГИСТРАТУРЕ";

        case "in_queue":
            return (_queue_purpose == "payment")
                ? "ОЖИДАЕТ ОПЛАТЫ"
                : "ЖДЁТ РЕГИСТРАЦИИ";

        case "registering":
            return (_queue_purpose == "payment")
                ? "ОПЛАЧИВАЕТ"
                : "ОФОРМЛЯЕТСЯ";

        case "going_to_waiting":
            return "ИДЁТ В ЗОНУ ОЖИДАНИЯ";

        case "waiting":
            return (_queue_type == "procedure")
                ? "ЖДЁТ ПРОЦЕДУРЫ"
                : "ЖДЁТ ПРИЁМА";

        case "going_to_exam":
            return (_queue_type == "procedure")
                ? "ИДЁТ НА ПРОЦЕДУРУ"
                : "ИДЁТ НА ПРИЁМ";

        case "in_exam":
            return (_queue_type == "procedure")
                ? "НА ПРОЦЕДУРЕ"
                : "НА ПРИЁМЕ";

        case "leaving_clinic":
            return "УХОДИТ ИЗ КЛИНИКИ";
    }

    return "НЕИЗВЕСТНО";
}


// ═══════════════════════════════════════════════════════════════
// 3. ПРИЧИНЫ ОБРАЩЕНИЯ В ВИДЕ СПИСКА
// Пример: «Температура, Вялость» → «- Температура\n- Вялость».
// ═══════════════════════════════════════════════════════════════

function tablet_owner_format_reasons(_reason_text) {
    var _result = string(_reason_text);

    if (_result == "") {
        return "- Причина не указана";
    }

    _result = string_replace_all(_result, ", ", "\n");
    _result = string_replace_all(_result, ",", "\n");
    _result = string_replace_all(_result, "; ", "\n");
    _result = string_replace_all(_result, ";", "\n");

    return "- " + string_replace_all(_result, "\n", "\n- ");
}

// Собирает все видимые симптомы питомца, а не только краткую жалобу.
function tablet_owner_get_reason_list(_pet, _fallback_text) {
    if (
        instance_exists(_pet)
        && variable_instance_exists(_pet, "visible_symptoms")
        && is_array(_pet.visible_symptoms)
        && array_length(_pet.visible_symptoms) > 0
    ) {
        var _result = "";
        var _symptom_ids = _pet.visible_symptoms;

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

            if (_result != "") {
                _result += "\n";
            }

            _result += "- " + _symptom_name;
        }

        return _result;
    }

    return tablet_owner_format_reasons(_fallback_text);
}


// ═══════════════════════════════════════════════════════════════
// 4. ШКАЛА ХАРАКТЕРИСТИКИ
// ═══════════════════════════════════════════════════════════════

function tablet_owner_draw_stat_bar(
    _x,
    _y,
    _label,
    _level,
    _progress,
    _ui_scale,
    _bar_color
) {
    var _level_clamped = clamp(round(_level), 1, 10);
    var _progress_clamped = clamp(round(_progress), 0, 4);

    var _bar_x = _x + 150 * _ui_scale;
    var _bar_w = 70 * _ui_scale;
    var _bar_h = 11 * _ui_scale;
    var _progress_ratio = _progress_clamped / 5;
    var _font_ui = _ui_scale * 1.30;

    // Название и сразу после него цифра текущего уровня.
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text_transformed(
        _x,
        _y,
        _label + "  " + string(_level_clamped),
        0.58 * _font_ui,
        0.62 * _font_ui,
        0
    );

    // Фон шкалы прогресса до следующего уровня.
    draw_set_color(make_color_rgb(220, 212, 198));
    draw_roundrect_ext(
        _bar_x,
        _y + 1,
        _bar_x + _bar_w,
        _y + 1 + _bar_h,
        7,
        7,
        false
    );

    if (_progress_clamped > 0 && _level_clamped < 10) {
        draw_set_color(_bar_color);
        draw_roundrect_ext(
            _bar_x,
            _y + 1,
            _bar_x + _bar_w * _progress_ratio,
            _y + 1 + _bar_h,
            7,
            7,
            false
        );
    }

    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(
        _bar_x,
        _y + 1,
        _bar_x + _bar_w,
        _y + 1 + _bar_h,
        7,
        7,
        true
    );

    // Число прогресса рисуется прямо внутри шкалы, как XP у врачей.
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(
        _bar_x + _bar_w * 0.5,
        _y + 1 + _bar_h * 0.5,
        (_level_clamped >= 10)
            ? "МАКС"
            : string(_progress_clamped) + "/5",
        0.34 * _font_ui,
        0.40 * _font_ui,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// Статичная характеристика без XP и прокачки.
function tablet_owner_draw_static_stat(
    _x,
    _y,
    _label,
    _level,
    _percent,
    _ui_scale
) {
    var _font_ui = _ui_scale * 1.30;
    // Те же координаты и размеры, что у шкал Терпения и Лояльности.
    var _value_x = _x + 150 * _ui_scale;
    var _value_w = 70 * _ui_scale;
    var _value_h = 11 * _ui_scale;

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text_transformed(
        _x,
        _y,
        _label + "  " + string(_level),
        0.58 * _font_ui,
        0.62 * _font_ui,
        0
    );

    // Такой же фон и такая же форма, как у двух шкал выше.
    draw_set_color(make_color_rgb(220, 212, 198));
    draw_roundrect_ext(
        _value_x,
        _y + 1,
        _value_x + _value_w,
        _y + 1 + _value_h,
        7,
        7,
        false
    );

    // Статичная синяя заливка показывает итоговую скорость, а не XP.
    draw_set_color(make_color_rgb(190, 214, 230));
    draw_roundrect_ext(
        _value_x,
        _y + 1,
        _value_x + _value_w,
        _y + 1 + _value_h,
        7,
        7,
        false
    );

    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(
        _value_x,
        _y + 1,
        _value_x + _value_w,
        _y + 1 + _value_h,
        7,
        7,
        true
    );

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text_transformed(
        _value_x + _value_w * 0.5,
        _y + 1 + _value_h * 0.5,
        string(_percent) + "%",
        0.34 * _font_ui,
        0.40 * _font_ui,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ═══════════════════════════════════════════════════════════════
// 5. ВЫПУКЛЫЙ БУМАЖНЫЙ ПРЯМОУГОЛЬНИК С ТОНКОЙ ОБВОДКОЙ
// ═══════════════════════════════════════════════════════════════

function tablet_owner_draw_panel(_x1, _y1, _x2, _y2) {
    var _panel_fill = make_color_rgb(242, 232, 214);
    var _panel_line = make_color_rgb(180, 160, 140);
    var _panel_highlight = make_color_rgb(255, 250, 238);

    // Многослойная мягкая тень вокруг панели.
    // Нижняя и правая стороны чуть темнее — панель кажется выпуклой.
    draw_set_color(c_black);

    draw_set_alpha(0.025);
    draw_roundrect_ext(_x1 - 5, _y1 - 3, _x2 + 7, _y2 + 9, 12, 12, false);

    draw_set_alpha(0.040);
    draw_roundrect_ext(_x1 - 3, _y1 - 2, _x2 + 5, _y2 + 7, 11, 11, false);

    draw_set_alpha(0.065);
    draw_roundrect_ext(_x1 - 1, _y1, _x2 + 3, _y2 + 5, 10, 10, false);

    draw_set_alpha(1);

    // Более тёмная бумага внутри и одна тонкая обводка, как у карточки животного.
    draw_set_color(_panel_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);

    draw_set_color(_panel_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    // Тонкий светлый блик сверху усиливает эффект выпуклости.
    draw_set_alpha(0.65);
    draw_set_color(_panel_highlight);
    draw_line(
        _x1 + 10,
        _y1 + 2,
        _x2 - 10,
        _y1 + 2
    );

    draw_set_alpha(1);
    draw_set_color(c_white);
}


// ═══════════════════════════════════════════════════════════════
// 6. ЗЕЛЕНОВАТАЯ КНОПКА ДЕЙСТВИЯ
// ═══════════════════════════════════════════════════════════════

function tablet_owner_draw_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _label,
    _hovered,
    _ui_scale
) {
    var _wood_dark = make_color_rgb(74, 49, 31);
    var _green_border = make_color_rgb(104, 137, 91);
    var _green_fill = _hovered
        ? make_color_rgb(220, 235, 208)
        : make_color_rgb(205, 224, 193);
    var _text_dark = make_color_rgb(45, 60, 40);

    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 3, _y1 + 4, _x2 + 3, _y2 + 4, 10, 10, false);
    draw_set_alpha(1);

    draw_set_color(_wood_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);

    draw_set_color(_green_border);
    draw_roundrect_ext(_x1 + 2, _y1 + 2, _x2 - 2, _y2 - 2, 8, 8, false);

    draw_set_color(_green_fill);
    draw_roundrect_ext(_x1 + 5, _y1 + 5, _x2 - 5, _y2 - 5, 6, 6, false);

    draw_set_color(_wood_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    draw_set_color(_text_dark);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5,
        _label,
        0.76 * _ui_scale,
        0.82 * _ui_scale,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ═══════════════════════════════════════════════════════════════
// 7. ОСНОВНАЯ КАРТОЧКА ВЛАДЕЛЬЦА
// Портрет уже нарисован основным Draw GUI планшета.
// ═══════════════════════════════════════════════════════════════

function tablet_draw_owner_card(
    _tablet,
    _owner,
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
    if (!instance_exists(_owner)) return false;

    var _wood_dark = make_color_rgb(74, 49, 31);
    var _text = make_color_rgb(50, 38, 28);
    var _text_soft = make_color_rgb(84, 68, 54);
    var _blue = make_color_rgb(72, 112, 145);
    var _green = make_color_rgb(62, 112, 74);
    var _gold = make_color_rgb(180, 140, 64);


    // ═══════════════════════════════════════════════════════════
    // 7.1 ОБЩАЯ СЕТКА КАРТОЧКИ
    // Все расстояния между блоками управляются одной переменной.
    // ═══════════════════════════════════════════════════════════

    var _font_ui = _ui_scale * 1.30;
    var _panel_gap = 7 * _ui_scale;
    var _padding = 9 * _ui_scale;

    // Прямоугольники начинаются ниже заголовка.
    var _content_top = _frame_y + 34 * _ui_scale;

    // Нижняя линия левого блока и области двух будущих кнопок.
    // Если потребуется поднять/опустить весь низ, меняется только 350.
    var _content_bottom = _frame_y + 350 * _ui_scale;

    var _left_x1 = _frame_x;
    var _left_x2 = _center_x - _panel_gap * 0.5;
    var _right_x1 = _center_x + _panel_gap * 0.5;
    var _right_x2 = _center_x + 260 * _ui_scale;

    // Закрываем старый полароид, который основной Draw GUI успел нарисовать.
    // Общий фон остаётся очень светлым; темнее будут только отдельные панели.
    draw_set_color(make_color_rgb(252, 250, 246));
    draw_rectangle(
        _left_x1 - 8 * _ui_scale,
        _frame_y - 12 * _ui_scale,
        _right_x2 + 8 * _ui_scale,
        _content_bottom + 8 * _ui_scale,
        false
    );

    // Две вкладки: обычная карточка и детализированная стоимость приёма.
    var _invoice_tab_open = finance_owner_card_draw_tabs(
        _tablet,
        _owner,
        _center_x,
        _frame_x,
        _frame_y,
        _ui_scale,
        _mouse_x,
        _mouse_y
    );

    if (_invoice_tab_open) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_set_color(_wood_dark);
        draw_text_transformed(
            (_left_x1 + _left_x2) * 0.5,
            _frame_y - 5 * _ui_scale,
            "СТОИМОСТЬ ПРИЁМА",
            0.82 * _font_ui,
            0.88 * _font_ui,
            0
        );

        finance_owner_card_draw_invoice(
            _tablet,
            _owner,
            _left_x1,
            _content_top,
            _right_x2,
            _content_bottom,
            _ui_scale,
            _mouse_x,
            _mouse_y
        );

        draw_set_color(c_white);
        draw_set_alpha(1);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        gpu_set_blendmode(bm_normal);
        return false;
    }


    // ═══════════════════════════════════════════════════════════
    // 7.2 ЗАГОЛОВОК КАРТОЧКИ
    // По центру планшета, но немного смещён влево.
    // ═══════════════════════════════════════════════════════════

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(_wood_dark);
    draw_text_transformed(
        (_left_x1 + _left_x2) * 0.5,
        _frame_y - 5 * _ui_scale,
        "КАРТОЧКА ВЛАДЕЛЬЦА",
        0.82 * _font_ui,
        0.88 * _font_ui,
        0
    );

    draw_set_halign(fa_left);


    // ═══════════════════════════════════════════════════════════
    // 7.3 ПРЯМОУГОЛЬНИК 1: ФОТО, ДАННЫЕ И СТАТУС
    // ═══════════════════════════════════════════════════════════

    var _owner_panel_x1 = _left_x1;
    var _owner_panel_y1 = _content_top;
    var _owner_panel_x2 = _left_x2;
    var _owner_panel_y2 = _owner_panel_y1 + 118 * _ui_scale;

    tablet_owner_draw_panel(
        _owner_panel_x1,
        _owner_panel_y1,
        _owner_panel_x2,
        _owner_panel_y2
    );

    // Полароид внутри первого прямоугольника.
    // Пропорции полностью повторяют старую карточку персонала.
    var _portrait_frame_x = _owner_panel_x1 + _padding;
    var _portrait_frame_y = _owner_panel_y1 + 13 * _ui_scale;
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

    // Сам снимок занимает верхнюю часть полароида.
    // Высота строится от ширины, поэтому лицо больше не вытягивается.
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
        variable_instance_exists(_owner, "my_baked_portrait")
        && _owner.my_baked_portrait != -1
        && sprite_exists(_owner.my_baked_portrait)
    ) {
        draw_sprite_stretched(
            _owner.my_baked_portrait,
            0,
            _portrait_inner_x,
            _portrait_inner_y,
            _portrait_inner_w,
            _portrait_inner_h
        );
    }
    else if (sprite_exists(_owner.sprite_index)) {
        draw_sprite_stretched(
            _owner.sprite_index,
            0,
            _portrait_inner_x,
            _portrait_inner_y,
            _portrait_inner_w,
            _portrait_inner_h
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

    // Пластырь владельца — голубой, как в старом полароиде.
    draw_set_color(c_aqua);
    draw_set_alpha(0.75);
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

    var _owner_text_x = _portrait_frame_x2 + 11 * _ui_scale;
    var _owner_text_w = _owner_panel_x2 - _owner_text_x - _padding;

    var _owner_name = variable_instance_exists(_owner, "char_name")
        ? string(_owner.char_name)
        : "Неизвестный владелец";

    var _owner_age = variable_instance_exists(_owner, "age")
        ? string(_owner.age)
        : "?";

    var _feature_name = variable_instance_exists(_owner, "owner_feature_name_ru")
        ? string(_owner.owner_feature_name_ru)
        : "Нет особенности";

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    draw_set_color(_blue);
    draw_text_ext_transformed(
        _owner_text_x,
        _owner_panel_y1 + 10 * _ui_scale,
        string_upper(_owner_name),
        16 * _ui_scale,
        _owner_text_w,
        0.68 * _font_ui,
        0.72 * _font_ui,
        0
    );

    draw_set_color(_text);
    draw_text_transformed(
        _owner_text_x,
        _owner_panel_y1 + 42 * _ui_scale,
        "Возраст: " + _owner_age,
        0.52 * _font_ui,
        0.56 * _font_ui,
        0
    );

    draw_set_color(_text_soft);
    draw_text_ext_transformed(
        _owner_text_x,
        _owner_panel_y1 + 62 * _ui_scale,
        "Особенность: " + _feature_name,
        13 * _ui_scale,
        _owner_text_w,
        0.48 * _font_ui,
        0.52 * _font_ui,
        0
    );

    draw_set_color(_blue);
    draw_text_ext_transformed(
        _owner_text_x,
        _owner_panel_y1 + 88 * _ui_scale,
        "СТАТУС: " + tablet_owner_get_status(_owner),
        13 * _ui_scale,
        _owner_text_w,
        0.46 * _font_ui,
        0.50 * _font_ui,
        0
    );


    // ═══════════════════════════════════════════════════════════
    // 7.4 ПРЯМОУГОЛЬНИК 2: ХАРАКТЕРИСТИКИ ДО САМОГО НИЗА
    // ═══════════════════════════════════════════════════════════

    var _stats_panel_x1 = _left_x1;
    var _stats_panel_y1 = _owner_panel_y2 + _panel_gap;
    var _stats_panel_x2 = _left_x2;
    var _stats_panel_y2 = _content_bottom;

    tablet_owner_draw_panel(
        _stats_panel_x1,
        _stats_panel_y1,
        _stats_panel_x2,
        _stats_panel_y2
    );

    draw_set_color(_wood_dark);
    draw_text_transformed(
        _stats_panel_x1 + _padding,
        _stats_panel_y1 + 10 * _ui_scale,
        "ХАРАКТЕРИСТИКИ:",
        0.62 * _font_ui,
        0.66 * _font_ui,
        0
    );

    var _patience_level = variable_instance_exists(_owner, "patience_level")
        ? clamp(round(_owner.patience_level), 1, 10)
        : (
            variable_instance_exists(_owner, "stat_patience")
            ? clamp(ceil(_owner.stat_patience / 10), 1, 10)
            : 5
        );

    var _patience_progress = variable_instance_exists(_owner, "patience_success_progress")
        ? clamp(round(_owner.patience_success_progress), 0, 4)
        : 0;

    var _loyalty_level = variable_instance_exists(_owner, "loyalty_level")
        ? clamp(round(_owner.loyalty_level), 1, 10)
        : 5;

    var _loyalty_progress = variable_instance_exists(_owner, "loyalty_success_progress")
        ? clamp(round(_owner.loyalty_success_progress), 0, 4)
        : 0;

    var _walk_speed_level = variable_instance_exists(_owner, "owner_walk_speed_level")
        ? clamp(round(_owner.owner_walk_speed_level), 1, 10)
        : owner_roll_walk_speed_level(_owner.age);

    var _walk_speed_percent = 100 + (_walk_speed_level - 1) * 10;

    tablet_owner_draw_stat_bar(
        _stats_panel_x1 + _padding,
        _stats_panel_y1 + 50 * _ui_scale,
        "Терпение",
        _patience_level,
        _patience_progress,
        _ui_scale,
        _green
    );

    tablet_owner_draw_stat_bar(
        _stats_panel_x1 + _padding,
        _stats_panel_y1 + 84 * _ui_scale,
        "Лояльность",
        _loyalty_level,
        _loyalty_progress,
        _ui_scale,
        _gold
    );

    tablet_owner_draw_static_stat(
        _stats_panel_x1 + _padding,
        _stats_panel_y1 + 118 * _ui_scale,
        "Скорость ходьбы",
        _walk_speed_level,
        _walk_speed_percent,
        _ui_scale
    );


    // ═══════════════════════════════════════════════════════════
    // 7.5 ДАННЫЕ ПИТОМЦА
    // ═══════════════════════════════════════════════════════════

    var _pet = variable_instance_exists(_owner, "my_pet")
        ? _owner.my_pet
        : noone;

    var _species_name = "Неизвестно";
    var _pet_name = "Нет питомца";
    var _pet_age = "Неизвестно";
    var _pet_problem = "Причина не указана";
    var _pet_condition = "Неизвестно";

    if (instance_exists(_pet)) {
        var _species_id = variable_instance_exists(_pet, "species_id")
            ? string(_pet.species_id)
            : "";

        switch (_species_id) {
            case "dog": _species_name = "Собака"; break;
            case "cat": _species_name = "Кошка"; break;
            default:
                if (_species_id != "") _species_name = string_upper(_species_id);
            break;
        }

        if (variable_instance_exists(_pet, "char_name")) {
            _pet_name = string(_pet.char_name);
        }

        if (variable_instance_exists(_pet, "age")) {
            _pet_age = string(_pet.age);
        }
        else if (variable_instance_exists(_pet, "pet_age_days")) {
            var _months = max(1, floor(_pet.pet_age_days / 30));
            _pet_age = string(_months) + " мес.";
        }

        if (variable_instance_exists(_pet, "problem")) {
            _pet_problem = string(_pet.problem);
        }
        else if (variable_instance_exists(_owner, "visit_reason_ru")) {
            _pet_problem = string(_owner.visit_reason_ru);
        }

        if (tablet_owner_condition_known(_pet)) {
            var _condition_value = variable_instance_exists(_pet, "condition")
                ? round(_pet.condition)
                : 100;

            _pet_condition = string(_condition_value) + "%";
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 7.6 ПРЯМОУГОЛЬНИК 3: ПИТОМЦЫ
    // ═══════════════════════════════════════════════════════════

    var _pet_panel_x1 = _right_x1;
    var _pet_panel_y1 = _content_top;
    var _pet_panel_x2 = _right_x2;
    var _pet_panel_y2 = _pet_panel_y1 + 100 * _ui_scale;

    tablet_owner_draw_panel(
        _pet_panel_x1,
        _pet_panel_y1,
        _pet_panel_x2,
        _pet_panel_y2
    );

    var _pet_text_x = _pet_panel_x1 + _padding;
    var _pet_value_x = _pet_text_x + 70 * _ui_scale;

    draw_set_color(_wood_dark);
    draw_text_transformed(
        _pet_text_x,
        _pet_panel_y1 + 8 * _ui_scale,
        "ПИТОМЦЫ:",
        0.62 * _font_ui,
        0.66 * _font_ui,
        0
    );

    draw_set_color(_text_soft);
    draw_text_transformed(_pet_text_x, _pet_panel_y1 + 23 * _ui_scale, "Вид:", 0.48 * _font_ui, 0.52 * _font_ui, 0);
    draw_set_color(_text);
    draw_text_transformed(_pet_value_x, _pet_panel_y1 + 23 * _ui_scale, _species_name, 0.52 * _font_ui, 0.56 * _font_ui, 0);

    draw_set_color(_text_soft);
    draw_text_transformed(_pet_text_x, _pet_panel_y1 + 45 * _ui_scale, "Кличка:", 0.48 * _font_ui, 0.52 * _font_ui, 0);
    draw_set_color(_blue);
    draw_text_transformed(_pet_value_x, _pet_panel_y1 + 45 * _ui_scale, _pet_name, 0.54 * _font_ui, 0.58 * _font_ui, 0);

    draw_set_color(_text_soft);
    draw_text_transformed(_pet_text_x, _pet_panel_y1 + 67 * _ui_scale, "Возраст:", 0.48 * _font_ui, 0.52 * _font_ui, 0);
    draw_set_color(_text);
    draw_text_transformed(_pet_value_x, _pet_panel_y1 + 67 * _ui_scale, _pet_age, 0.52 * _font_ui, 0.56 * _font_ui, 0);


    // ═══════════════════════════════════════════════════════════
    // 7.7 ПРЯМОУГОЛЬНИК 4: ОБРАЩЕНИЕ И СОСТОЯНИЕ
    // Внизу оставлена область ровно под две кнопки.
    // ═══════════════════════════════════════════════════════════

    var _button_height = 30 * _ui_scale;
    var _button_area_height = _button_height * 2 + _panel_gap;

    var _case_panel_x1 = _right_x1;
    var _case_panel_y1 = _pet_panel_y2 + _panel_gap;
    var _case_panel_x2 = _right_x2;
    var _case_panel_y2 = _content_bottom - _panel_gap - _button_area_height;
    var _case_text_w = _case_panel_x2 - _case_panel_x1 - _padding * 2;

    tablet_owner_draw_panel(
        _case_panel_x1,
        _case_panel_y1,
        _case_panel_x2,
        _case_panel_y2
    );

    draw_set_color(_wood_dark);
    draw_text_transformed(
        _case_panel_x1 + _padding,
        _case_panel_y1 + 9 * _ui_scale,
        "ПРИЧИНА ОБРАЩЕНИЯ:",
        0.54 * _font_ui,
        0.58 * _font_ui,
        0
    );

    draw_set_color(_text_soft);
    draw_text_ext_transformed(
        _case_panel_x1 + _padding,
        _case_panel_y1 + 19 * _ui_scale,
        tablet_owner_get_reason_list(_pet, _pet_problem),
        7 * _ui_scale,
        _case_text_w,
        0.58 * _font_ui,
        0.62 * _font_ui,
        0
    );

    // Состояние всегда прижато к нижней части четвёртого прямоугольника.
    var _condition_y = _case_panel_y2 - 28 * _ui_scale;

    draw_set_color(_wood_dark);
    draw_text_transformed(
        _case_panel_x1 + _padding,
        _condition_y,
        "СОСТОЯНИЕ:",
        0.52 * _font_ui,
        0.56 * _font_ui,
        0
    );

    draw_set_color(_blue);
    draw_text_transformed(
        _case_panel_x1 + _padding + 100 * _ui_scale,
        _condition_y,
        _pet_condition,
        0.52 * _font_ui,
        0.56 * _font_ui,
        0
    );


    // ═══════════════════════════════════════════════════════════
    // 7.8 ДОСТУПНОЕ ДЕЙСТВИЕ С ВЛАДЕЛЬЦЕМ
    // ═══════════════════════════════════════════════════════════

    var _player = instance_exists(obj_player)
        ? instance_find(obj_player, 0)
        : noone;

    var _player_idle = instance_exists(_player)
        && variable_instance_exists(_player, "doctor_state")
        && _player.doctor_state == "idle";

    var _owner_state = variable_instance_exists(_owner, "state")
        ? _owner.state
        : "";

    var _queue_type = variable_instance_exists(_owner, "service_queue_type")
        ? _owner.service_queue_type
        : "doctor";

    var _queue_purpose = variable_instance_exists(_owner, "queue_purpose")
        ? _owner.queue_purpose
        : "registration";

    var _has_free_wait = reception_find_free_wait_spot() != -1;

    var _at_registration_front = (
        _owner_state == "in_queue"
        && variable_instance_exists(_owner, "queue_slot")
        && _owner.queue_slot == 0
    );

    var _can_register = (
        _player_idle
        && _has_free_wait
        && _at_registration_front
        && _queue_purpose != "payment"
        && variable_instance_exists(_owner, "registered")
        && !_owner.registered
    );

    var _can_take_payment = (
        _player_idle
        && _owner_state == "in_queue"
        && _queue_purpose == "payment"
        && variable_instance_exists(_owner, "queue_slot")
        && _owner.queue_slot == 0
    );

    var _owner_unassigned = variable_instance_exists(_owner, "assigned_doctor")
        && _owner.assigned_doctor == noone;

    var _can_take_doctor = (
        _player_idle
        && _owner_state == "waiting"
        && _queue_type == "doctor"
        && _owner_unassigned
    );

    var _can_take_procedure = (
        _player_idle
        && _owner_state == "waiting"
        && _queue_type == "procedure"
        && _owner_unassigned
    );

    var _button_label = "";
    var _button_action = "";

    if (_can_register) {
        _button_label = "ЗАРЕГИСТРИРОВАТЬ";
        _button_action = "registration";
    }
    else if (_can_take_payment) {
        _button_label = "ПРИНЯТЬ ОПЛАТУ";
        _button_action = "payment";
    }
    else if (_can_take_doctor) {
        _button_label = "ВЗЯТЬ НА ПРИЁМ";
        _button_action = "doctor";
    }
    else if (_can_take_procedure) {
        _button_label = "НА ПРОЦЕДУРЫ";
        _button_action = "procedure";
    }

    // Сейчас одновременно актуально одно действие. Второй слот оставлен
    // свободным под будущую дополнительную кнопку владельца.
    if (_button_label != "") {
        var _button_x1 = _right_x1;
        var _button_y1 = _case_panel_y2 + _panel_gap;
        var _button_x2 = _right_x2;
        var _button_y2 = _button_y1 + _button_height;

        var _button_hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _button_x1,
            _button_y1,
            _button_x2,
            _button_y2
        );

        tablet_owner_draw_button(
            _button_x1,
            _button_y1,
            _button_x2,
            _button_y2,
            _button_label,
            _button_hovered,
            _ui_scale
        );

        if (
            _button_hovered
            && _tablet.tablet_click_lock <= 0
            && mouse_check_button_pressed(mb_left)
        ) {
            _tablet.tablet_click_lock = 5;

            if (instance_exists(_player)) {
                switch (_button_action) {
                    case "registration":
                        with (_player) {
                            player_begin_registration(_owner);
                        }
                    break;

                    case "payment":
                        with (_player) {
                            player_begin_payment(_owner);
                        }
                    break;

                    case "doctor":
                        with (_player) {
                            player_begin_exam(_owner);
                        }
                    break;

                    case "procedure":
                        with (_player) {
                            player_begin_procedure_visit(_owner);
                        }
                    break;
                }
            }

            _tablet.visible = false;
            _tablet.target_id = noone;
            return true;
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 7.9 СБРОС DRAW
    // ═══════════════════════════════════════════════════════════

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);

    return false;
}
