/// handbook_system.gml
/// @description Справочник болезней: записи открываются за идеальный ручной приём игрока.
/// Пакет №119: панель справочника на матовом стекле (дерево только рамкой).


// ═══════════════════════════════════════════════════════════════
// 1. ХРАНИЛИЩЕ ОТКРЫТЫХ БОЛЕЗНЕЙ
// Живёт в global-переменной текущей сессии, как цены и фильтр найма.
// ═══════════════════════════════════════════════════════════════

function handbook_init() {
    if (!variable_global_exists("handbook_unlocked")) {
        global.handbook_unlocked = {};
    }
}

function handbook_is_unlocked(_disease_id) {
    handbook_init();

    var _key = string(_disease_id);

    return variable_struct_exists(global.handbook_unlocked, _key)
        && variable_struct_get(global.handbook_unlocked, _key);
}

function handbook_unlock(_disease_id) {
    handbook_init();

    var _key = string(_disease_id);

    if (_key == "") return false;
    if (handbook_is_unlocked(_key)) return false;

    variable_struct_set(global.handbook_unlocked, _key, true);

    var _name = handbook_get_disease_name(_key);

    if (instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);

        if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
            with (_hud) {
                show_notice(
                    "СПРАВОЧНИК ОТКРЫТ",
                    "Болезнь \"" + _name + "\" теперь в справочнике.",
                    max(1, game_get_speed(gamespeed_fps)) * 3
                );
            }
        }
    }

    show_debug_message("[HANDBOOK] Открыта болезнь: " + _key + " (" + _name + ")");

    return true;
}

function handbook_get_unlocked_count() {
    handbook_init();

    var _count = 0;

    if (
        !variable_global_exists("med_db")
        || !is_struct(global.med_db)
        || !variable_struct_exists(global.med_db, "disease_ids")
    ) {
        return 0;
    }

    for (var _i = 0; _i < array_length(global.med_db.disease_ids); _i++) {
        if (handbook_is_unlocked(global.med_db.disease_ids[_i])) {
            _count += 1;
        }
    }

    return _count;
}


// ═══════════════════════════════════════════════════════════════
// 2. ДАННЫЕ БОЛЕЗНИ ИЗ МЕДИЦИНСКОЙ БАЗЫ
// ═══════════════════════════════════════════════════════════════

function handbook_get_disease(_disease_id) {
    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "diseases")
        && variable_struct_exists(global.med_db.diseases, _disease_id)
    ) {
        return variable_struct_get(global.med_db.diseases, _disease_id);
    }

    return undefined;
}

function handbook_get_disease_name(_disease_id) {
    var _disease = handbook_get_disease(_disease_id);

    if (is_struct(_disease) && variable_struct_exists(_disease, "name_ru")) {
        return string(_disease.name_ru);
    }

    return "Неизвестная болезнь";
}

function handbook_get_disease_description(_disease_id) {
    var _disease = handbook_get_disease(_disease_id);

    if (is_struct(_disease) && variable_struct_exists(_disease, "description")) {
        return string(_disease.description);
    }

    return "Описание отсутствует.";
}

function handbook_get_disease_difficulty(_disease_id) {
    var _disease = handbook_get_disease(_disease_id);

    if (is_struct(_disease) && variable_struct_exists(_disease, "difficulty")) {
        return clamp(round(_disease.difficulty), 1, 10);
    }

    return 1;
}

function handbook_get_symptom_name(_symptom_id) {
    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "symptoms")
        && variable_struct_exists(global.med_db.symptoms, _symptom_id)
    ) {
        var _symptom = variable_struct_get(global.med_db.symptoms, _symptom_id);

        if (variable_struct_exists(_symptom, "name_ru")) {
            return string(_symptom.name_ru);
        }
    }

    return "Неизвестный симптом";
}

function handbook_get_disease_symptoms(_disease_id) {
    var _result = [];
    var _seen = {};

    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "disease_symptoms")
    ) {
        for (var _i = 0; _i < array_length(global.med_db.disease_symptoms); _i++) {
            var _link = global.med_db.disease_symptoms[_i];

            if (_link.disease_id != _disease_id) continue;

            var _symptom_id = string(_link.symptom_id);

            if (variable_struct_exists(_seen, _symptom_id)) continue;

            variable_struct_set(_seen, _symptom_id, true);
            array_push(_result, {
                id : _symptom_id,
                name : handbook_get_symptom_name(_symptom_id)
            });
        }
    }

    return _result;
}

function handbook_get_disease_diagnostics(_disease_id) {
    var _result = [];
    var _seen = {};

    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "disease_diagnostics")
    ) {
        for (var _i = 0; _i < array_length(global.med_db.disease_diagnostics); _i++) {
            var _link = global.med_db.disease_diagnostics[_i];

            if (_link.disease_id != _disease_id) continue;

            var _diagnostic_id = string(_link.diagnostic_id);

            if (variable_struct_exists(_seen, _diagnostic_id)) continue;

            variable_struct_set(_seen, _diagnostic_id, true);
            array_push(_result, {
                id : _diagnostic_id,
                name : db_get_diagnostic_name(_diagnostic_id),
                required_to_confirm : variable_struct_exists(_link, "required_to_confirm")
                    ? _link.required_to_confirm
                    : false
            });
        }
    }

    return _result;
}

function handbook_get_disease_treatments(_disease_id) {
    var _result = [];
    var _seen = {};

    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "disease_treatment")
    ) {
        for (var _i = 0; _i < array_length(global.med_db.disease_treatment); _i++) {
            var _step = global.med_db.disease_treatment[_i];

            if (_step.disease_id != _disease_id) continue;

            var _action_id = string(_step.action_id);

            if (variable_struct_exists(_seen, _action_id)) continue;

            variable_struct_set(_seen, _action_id, true);
            array_push(_result, {
                id : _action_id,
                name : db_get_treatment_action_name(_action_id),
                required : variable_struct_exists(_step, "required")
                    ? _step.required
                    : false
            });
        }
    }

    return _result;
}


// ═══════════════════════════════════════════════════════════════
// 3. ПРОВЕРКА ИДЕАЛЬНОГО РУЧНОГО ПРИЁМА
// Возвращает id болезни, если приём игрока был идеальным, иначе "".
// Условия:
//   1. диагноз подтверждён;
//   2. ни одного лишнего обследования;
//   3. ни одной ошибки в назначениях;
//   4. все обязательные назначения этой болезни назначены игроком.
// ═══════════════════════════════════════════════════════════════

function handbook_check_perfect_exam(_pet) {
    if (!instance_exists(_pet)) return "";
    if (!variable_instance_exists(_pet, "current_case")) return "";
    if (!is_struct(_pet.current_case)) return "";

    var _case = _pet.current_case;

    var _disease_id = "";

    if (variable_struct_exists(_case, "hidden_disease_id")) {
        _disease_id = string(_case.hidden_disease_id);
    }

    if (_disease_id == "" && variable_struct_exists(_case, "selected_disease_id")) {
        _disease_id = string(_case.selected_disease_id);
    }

    if (_disease_id == "") return "";

    // 1. Диагноз подтверждён.
    if (!(variable_struct_exists(_case, "confirmed") && _case.confirmed)) {
        return "";
    }

    // 2. Нет лишних обследований.
    if (
        variable_struct_exists(_case, "visit_wrong_diagnostics_done")
        && array_length(_case.visit_wrong_diagnostics_done) > 0
    ) {
        return "";
    }

    if (
        variable_struct_exists(_case, "visit_diagnostic_feedback_bad_ids")
        && array_length(_case.visit_diagnostic_feedback_bad_ids) > 0
    ) {
        return "";
    }

    // 3. Нет ошибочных назначений.
    if (
        variable_struct_exists(_case, "visit_treatment_feedback_bad_ids")
        && array_length(_case.visit_treatment_feedback_bad_ids) > 0
    ) {
        return "";
    }

    // 4. Все обязательные назначения этой болезни назначены игроком.
    var _prescribed = (
        variable_struct_exists(_case, "prescribed_treatment_ids")
        && is_array(_case.prescribed_treatment_ids)
    ) ? _case.prescribed_treatment_ids : [];

    var _steps = [];

    if (
        variable_struct_exists(_case, "planned_treatment")
        && array_length(_case.planned_treatment) > 0
    ) {
        _steps = _case.planned_treatment;
    }
    else {
        for (var _i = 0; _i < array_length(global.med_db.disease_treatment); _i++) {
            var _step = global.med_db.disease_treatment[_i];

            if (_step.disease_id == _disease_id) {
                array_push(_steps, _step);
            }
        }
    }

    var _reveal = variable_struct_exists(_case, "reveal_level")
        ? _case.reveal_level
        : 0;

    for (var _s = 0; _s < array_length(_steps); _s++) {
        var _step = _steps[_s];

        if (!(variable_struct_exists(_step, "required") && _step.required)) {
            continue;
        }

        // Назначение, которое ещё не раскрыто, игрок физически не мог сделать.
        var _req_reveal = variable_struct_exists(_step, "reveal_level")
            ? _step.reveal_level
            : 0;

        if (_req_reveal > _reveal) continue;

        var _action_id = string(_step.action_id);
        var _found = false;

        for (var _p = 0; _p < array_length(_prescribed); _p++) {
            if (_prescribed[_p] == _action_id) {
                _found = true;
                break;
            }
        }

        if (!_found) return "";
    }

    return _disease_id;
}


// ═══════════════════════════════════════════════════════════════
// 4. ПАНЕЛЬ СПРАВОЧНИКА
// Пакет №69 hotfix: шрифты увеличены для удобного чтения на телефоне.
// ═══════════════════════════════════════════════════════════════

function hud_draw_handbook_panel(_hud) {
    if (!instance_exists(_hud)) return;
    if (!variable_instance_exists(_hud, "handbook_open")) return;
    if (!_hud.handbook_open) return;

    handbook_init();

    if (
        !variable_global_exists("med_db")
        || !is_struct(global.med_db)
        || !variable_struct_exists(global.med_db, "disease_ids")
    ) {
        return;
    }

    var _wood_dark  = make_color_rgb(74, 49, 31);
    var _wood_mid   = make_color_rgb(114, 77, 50);
    var _wood_light = make_color_rgb(150, 107, 73);
    var _paper      = make_color_rgb(242, 232, 214);
    var _line_dark  = make_color_rgb(58, 39, 24);
    var _text_dark  = make_color_rgb(50, 38, 28);
    var _text_soft  = make_color_rgb(84, 68, 54);
    var _green      = make_color_rgb(62, 112, 74);
    var _blue       = make_color_rgb(72, 112, 145);
    var _red        = make_color_rgb(148, 74, 64);

    var _x1 = _hud.handbook_panel_x1;
    var _y1 = _hud.handbook_panel_y1;
    var _x2 = _hud.handbook_panel_x2;
    var _y2 = _hud.handbook_panel_y2;

    var _ids = global.med_db.disease_ids;

    hud_draw_frosted_panel(_x1, _y1, _x2, _y2);

    // ── Заголовок ──
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_wood_dark);
    draw_text_transformed(_x1 + 24, _y1 + 18, "СПРАВОЧНИК БОЛЕЗНЕЙ", 1.45, 1.45, 0);

    draw_set_halign(fa_right);
    draw_set_color(_text_soft);
    draw_text_transformed(
        _x2 - 58,
        _y1 + 26,
        "ОТКРЫТО " + string(handbook_get_unlocked_count())
            + " / " + string(array_length(_ids)),
        0.95,
        0.95,
        0
    );

    // Кнопка закрытия (клик обрабатывается в Begin Step).
    hud_draw_button(
        _hud.handbook_close_x1,
        _hud.handbook_close_y1,
        _hud.handbook_close_x2,
        _hud.handbook_close_y2,
        "X",
        false,
        _hud.hover_handbook_close,
        _paper,
        make_color_rgb(248, 238, 220),
        make_color_rgb(229, 194, 185),
        _line_dark,
        _text_dark
    );

    // ── Левая колонка: список болезней ──
    var _list_x1 = _x1 + 20;
    var _list_y1 = _y1 + 62;
    var _list_x2 = _list_x1 + 360;
    var _list_y2 = _y2 - 20;

    // ── Правая колонка: детали ──
    var _detail_x1 = _list_x2 + 18;
    var _detail_y1 = _list_y1;
    var _detail_x2 = _x2 - 20;
    var _detail_y2 = _list_y2;

    // Пакет №119: колонки на матовом стекле (было — непрозрачная бумага).
    hud_frosted_fill(
        _list_x1 - 10, _list_y1 - 10,
        _list_x2 + 10, _list_y2 + 10,
        10
    );
    hud_frosted_fill(
        _detail_x1 - 10, _detail_y1 - 10,
        _detail_x2 + 10, _detail_y2 + 10,
        10
    );

    draw_set_color(_line_dark);
    draw_roundrect_ext(
        _list_x1 - 10, _list_y1 - 10,
        _list_x2 + 10, _list_y2 + 10,
        10, 10, true
    );
    draw_roundrect_ext(
        _detail_x1 - 10, _detail_y1 - 10,
        _detail_x2 + 10, _detail_y2 + 10,
        10, 10, true
    );

    // ── Строки списка ──
    var _row_h = 46;
    var _visible_rows = max(1, floor((_list_y2 - _list_y1) / _row_h));
    var _max_scroll = max(0, array_length(_ids) - _visible_rows);

    _hud.handbook_scroll = clamp(_hud.handbook_scroll, 0, _max_scroll);

    for (var _j = 0; _j < _visible_rows; _j++) {
        var _idx = _hud.handbook_scroll + _j;
        if (_idx >= array_length(_ids)) break;

        var _disease_id = _ids[_idx];
        var _unlocked = handbook_is_unlocked(_disease_id);

        var _row_y1 = _list_y1 + _j * _row_h;
        var _row_y2 = _row_y1 + (_row_h - 4);

        var _selected = (_hud.selected_handbook_disease == _disease_id);
        var _hovered = (_hud.handbook_row_hover == _idx);

        var _fill = _selected
            ? make_color_rgb(205, 224, 193)
            : (_hovered
                ? make_color_rgb(240, 232, 216)
                : make_color_rgb(246, 240, 228));

        draw_set_color(_fill);
        draw_roundrect_ext(_list_x1, _row_y1, _list_x2, _row_y2, 6, 6, false);

        if (_selected) {
            draw_set_color(make_color_rgb(104, 137, 91));
            draw_roundrect_ext(_list_x1, _row_y1, _list_x2, _row_y2, 6, 6, true);
        }

        var _label = _unlocked
            ? handbook_get_disease_name(_disease_id)
            : "???";

        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(_unlocked
            ? _text_dark
            : make_color_rgb(132, 122, 110));
        draw_text_transformed(
            _list_x1 + 12,
            (_row_y1 + _row_y2) * 0.5,
            _label,
            1.0,
            1.0,
            0
        );

        if (_unlocked) {
            draw_set_color(make_color_rgb(96, 168, 94));
            draw_circle(_list_x2 - 16, (_row_y1 + _row_y2) * 0.5, 5, false);
        }
    }

    // ── Детали выбранной болезни ──
    var _sel = _hud.selected_handbook_disease;

    if (_sel == "") {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(120, 110, 95));
        draw_text_transformed(
            (_detail_x1 + _detail_x2) * 0.5,
            (_detail_y1 + _detail_y2) * 0.5,
            "Выберите болезнь слева",
            1.2,
            1.2,
            0
        );
    }
    else if (!handbook_is_unlocked(_sel)) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_set_color(make_color_rgb(120, 110, 95));
        draw_text_transformed(
            (_detail_x1 + _detail_x2) * 0.5,
            (_detail_y1 + _detail_y2) * 0.5 - 70,
            "???",
            2.4,
            2.4,
            0
        );

        draw_set_color(_text_soft);
        draw_text_ext_transformed(
            (_detail_x1 + _detail_x2) * 0.5,
            (_detail_y1 + _detail_y2) * 0.5 - 20,
            "Эта болезнь ещё не открыта.\n\nПроведите идеальный приём: подтвердите диагноз, назначьте все обязательные процедуры и не допустите ни одной ошибки.",
            26,
            (_detail_x2 - _detail_x1) - 80,
            0.9,
            0.9,
            0
        );
    }
    else {
        var _dx = _detail_x1 + 12;
        var _dy = _detail_y1 + 8;
        var _detail_w = _detail_x2 - _detail_x1 - 24;

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_wood_dark);
        draw_text_transformed(
            _dx,
            _dy,
            handbook_get_disease_name(_sel),
            1.3,
            1.3,
            0
        );
        _dy += 38;

        var _difficulty = handbook_get_disease_difficulty(_sel);
        var _diff_color = make_color_rgb(62, 112, 74);

        if (_difficulty >= 7) {
            _diff_color = make_color_rgb(148, 74, 64);
        }
        else if (_difficulty >= 4) {
            _diff_color = make_color_rgb(190, 130, 50);
        }

        draw_set_color(_diff_color);
        draw_text_transformed(
            _dx,
            _dy,
            "СЛОЖНОСТЬ: " + string(_difficulty) + "/10",
            0.8,
            0.8,
            0
        );
        _dy += 30;

        var _desc = handbook_get_disease_description(_sel);

        draw_set_color(_text_dark);
        draw_text_ext_transformed(_dx, _dy, _desc, 26, _detail_w, 0.9, 0.9, 0);
        _dy += string_height_ext(_desc, 26, _detail_w) * 0.9 + 18;

        // Симптомы
        draw_set_color(_green);
        draw_text_transformed(_dx, _dy, "СИМПТОМЫ:", 0.95, 0.95, 0);
        _dy += 30;

        var _symptoms = handbook_get_disease_symptoms(_sel);

        if (array_length(_symptoms) <= 0) {
            draw_set_color(_text_soft);
            draw_text_transformed(_dx, _dy, "— нет данных", 0.9, 0.9, 0);
            _dy += 26;
        }
        else {
            for (var _si = 0; _si < array_length(_symptoms); _si++) {
                draw_set_color(_text_soft);
                draw_text_transformed(_dx, _dy, "• " + string(_symptoms[_si].name), 0.9, 0.9, 0);
                _dy += 26;
            }
        }
        _dy += 8;

        // Обследования
        draw_set_color(_blue);
        draw_text_transformed(_dx, _dy, "ОБСЛЕДОВАНИЯ:", 0.95, 0.95, 0);
        _dy += 30;

        var _diagnostics = handbook_get_disease_diagnostics(_sel);

        if (array_length(_diagnostics) <= 0) {
            draw_set_color(_text_soft);
            draw_text_transformed(_dx, _dy, "— нет данных", 0.9, 0.9, 0);
            _dy += 26;
        }
        else {
            for (var _di = 0; _di < array_length(_diagnostics); _di++) {
                var _diag_line = "• " + string(_diagnostics[_di].name);

                if (_diagnostics[_di].required_to_confirm) {
                    _diag_line += "  (подтверждает диагноз)";
                }

                draw_set_color(_text_soft);
                draw_text_transformed(_dx, _dy, _diag_line, 0.9, 0.9, 0);
                _dy += 26;
            }
        }
        _dy += 8;

        // Лечение
        draw_set_color(_red);
        draw_text_transformed(_dx, _dy, "ЛЕЧЕНИЕ:", 0.95, 0.95, 0);
        _dy += 30;

        var _treatments = handbook_get_disease_treatments(_sel);

        if (array_length(_treatments) <= 0) {
            draw_set_color(_text_soft);
            draw_text_transformed(_dx, _dy, "— нет данных", 0.9, 0.9, 0);
            _dy += 26;
        }
        else {
            for (var _ti = 0; _ti < array_length(_treatments); _ti++) {
                var _treat_line = "• " + string(_treatments[_ti].name);

                if (_treatments[_ti].required) {
                    _treat_line += "  (обязательно)";
                }
                else {
                    _treat_line += "  (дополнительно)";
                }

                draw_set_color(_text_soft);
                draw_text_transformed(_dx, _dy, _treat_line, 0.9, 0.9, 0);
                _dy += 26;
            }
        }
    }

    // Сброс состояния рисования.
    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
