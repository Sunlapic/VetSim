/// hud_ui_common.gml
/// @description Общие функции HUD без привязки к одному Draw-событию.

function hud_ui_fps() {
    return max(1, game_get_speed(gamespeed_fps));
}

function hud_ui_debug_enabled() {
    return variable_global_exists("vetsim_debug_mode")
        && global.vetsim_debug_mode;
}

function hud_measure_box(
    _title,
    _text,
    _min_w,
    _max_w,
    _pad_left,
    _pad_right,
    _pad_top,
    _pad_bottom,
    _line_gap
) {
    var _title_draw = string(_title);
    var _text_draw = string(_text);
    var _text_sep = 20;
    var _title_h = (_title_draw != "")
        ? string_height(_title_draw)
        : 0;
    var _raw_w = max(
        (_title_draw != "") ? string_width(_title_draw) : 0,
        (_text_draw != "") ? string_width(_text_draw) : 0
    );
    var _w = clamp(
        _raw_w + _pad_left + _pad_right + 14,
        _min_w,
        _max_w
    );
    var _wrap_w = _w - _pad_left - _pad_right;
    var _text_h = (_text_draw != "")
        ? string_height_ext(_text_draw, _text_sep, _wrap_w)
        : 0;
    var _gap = (
        _title_draw != ""
        && _text_draw != ""
    ) ? _line_gap : 0;

    return {
        w : _w,
        h : _pad_top + _title_h + _gap + _text_h + _pad_bottom + 10,
        wrap_w : _wrap_w,
        title_h : _title_h,
        text_h : _text_h,
        text_sep : _text_sep
    };
}

function hud_draw_wood_panel(
    _x1,
    _y1,
    _x2,
    _y2,
    _wood_dark,
    _wood_mid,
    _wood_light,
    _line_dark
) {
    draw_set_alpha(0.16);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 4, _y1 + 5, _x2 + 4, _y2 + 5, 18, 18, false);
    draw_set_alpha(1);
    draw_set_color(_wood_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, false);
    draw_set_color(_wood_mid);
    draw_roundrect_ext(_x1 + 3, _y1 + 3, _x2 - 3, _y2 - 3, 16, 16, false);
    draw_set_color(_wood_light);
    draw_roundrect_ext(_x1 + 8, _y1 + 8, _x2 - 8, _y2 - 8, 14, 14, false);
    draw_set_color(_line_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, true);
}

function hud_draw_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _text,
    _active,
    _hover,
    _fill,
    _hover_fill,
    _active_fill,
    _line_dark,
    _text_color
) {
    draw_set_color(
        _active
            ? _active_fill
            : (_hover ? _hover_fill : _fill)
    );
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
    draw_set_color(_line_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);
    // Пакет №174: текст кнопки крупный, но сам ужимается под её ширину —
    // раньше все кнопки в игре рисовались базовым мелким шрифтом.
    draw_set_color(_text_color);
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5 + 1,
        _text,
        (_x2 - _x1) - 20,
        UI_FS_BUTTON
    );
}

function hud_get_visit_status_ru(_status_id) {
    switch (string(_status_id)) {
        case "pending": return "Запланирован";
        case "spawned": return "Прибыл в клинику";
        case "completed": return "Завершён";
    }
    return "Неизвестно";
}

function hud_get_disease_name(_disease_id) {
    if (!variable_global_exists("med_db")) return "Неизвестно";
    if (!is_struct(global.med_db)) return "Неизвестно";
    if (!variable_struct_exists(global.med_db, "diseases")) return "Неизвестно";
    if (!variable_struct_exists(global.med_db.diseases, _disease_id)) return "Неизвестно";

    var _disease = variable_struct_get(
        global.med_db.diseases,
        _disease_id
    );

    return variable_struct_exists(_disease, "name_ru")
        ? string(_disease.name_ru)
        : "Неизвестно";
}

function hud_bool_text(_value) {
    return _value ? "ДА" : "НЕТ";
}

function hud_clock_text(_hour, _minute) {
    var _hh = (_hour < 10 ? "0" : "") + string(_hour);
    var _mm = (_minute < 10 ? "0" : "") + string(_minute);
    return _hh + ":" + _mm;
}

function hud_minute_to_clock(_minute) {
    var _hour = floor(_minute / 60);
    var _minute_part = _minute mod 60;
    return (_hour < 10 ? "0" : "")
        + string(_hour)
        + ":"
        + (_minute_part < 10 ? "0" : "")
        + string(_minute_part);
}

function hud_get_severity_name(_level, _name_ru) {
    if (string(_name_ru) != "") return string(_name_ru);

    switch (_level) {
        case 1: return "Лёгкое";
        case 2: return "Среднее";
        case 3: return "Тяжёлое";
        case 4: return "Критическое";
    }

    return "Неизвестно";
}

function hud_count_value_in_array(_array, _value) {
    var _count = 0;

    for (var _index = 0; _index < array_length(_array); _index++) {
        if (_array[_index] == _value) _count += 1;
    }

    return _count;
}

function hud_visit_build_proc_lines(_visit) {
    var _lines = [];
    if (!is_struct(_visit)) return _lines;

    if (
        variable_struct_exists(_visit, "procedure_log")
        && array_length(_visit.procedure_log) > 0
    ) {
        for (var _index = 0; _index < array_length(_visit.procedure_log); _index++) {
            var _procedure = _visit.procedure_log[_index];
            var _type = variable_struct_exists(_procedure, "proc_type")
                ? string(_procedure.proc_type)
                : "";
            var _id = variable_struct_exists(_procedure, "proc_id")
                ? string(_procedure.proc_id)
                : "";
            var _name = variable_struct_exists(_procedure, "proc_name_ru")
                ? string(_procedure.proc_name_ru)
                : "";

            if (_name == "") {
                _name = (_type == "diagnostic")
                    ? db_get_diagnostic_name(_id)
                    : db_get_treatment_action_name(_id);
            }

            array_push(
                _lines,
                ((_type == "diagnostic") ? "Диагностика: " : "Лечение: ")
                    + _name
            );
        }

        return _lines;
    }

    if (variable_struct_exists(_visit, "diagnostics_this_visit")) {
        for (var _diag = 0; _diag < array_length(_visit.diagnostics_this_visit); _diag++) {
            array_push(
                _lines,
                "Диагностика: "
                    + db_get_diagnostic_name(_visit.diagnostics_this_visit[_diag])
            );
        }
    }

    if (variable_struct_exists(_visit, "treatments_this_visit")) {
        for (var _treat = 0; _treat < array_length(_visit.treatments_this_visit); _treat++) {
            array_push(
                _lines,
                "Лечение: "
                    + db_get_treatment_action_name(_visit.treatments_this_visit[_treat])
            );
        }
    }

    return _lines;
}

function hud_visit_build_plan_lines(_visit) {
    var _lines = [];
    if (!is_struct(_visit)) return _lines;
    if (!variable_struct_exists(_visit, "planned_treatment")) return _lines;

    var _progress = variable_struct_exists(_visit, "treatment_progress")
        ? _visit.treatment_progress
        : [];

    for (var _index = 0; _index < array_length(_visit.planned_treatment); _index++) {
        var _plan = _visit.planned_treatment[_index];
        var _action_id = variable_struct_exists(_plan, "action_id")
            ? string(_plan.action_id)
            : "";
        var _required = variable_struct_exists(_plan, "count")
            ? _plan.count
            : 0;
        var _done = hud_count_value_in_array(_progress, _action_id);

        array_push(
            _lines,
            db_get_treatment_action_name(_action_id)
                + ": "
                + string(_done)
                + "/"
                + string(_required)
        );
    }

    return _lines;
}

function hud_draw_string_list(
    _lines,
    _x,
    _y,
    _line_height,
    _limit,
    _max_width,
    _text_color,
    _soft_color
) {
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var _draw_count = min(array_length(_lines), _limit);

    // Пакет №174: строки списка крупнее, масштаб ограничен и по ширине,
    // и по высоте строки — соседние строки не слипаются.
    for (var _index = 0; _index < _draw_count; _index++) {
        var _line = "• " + string(_lines[_index]);
        var _scale = ui_fit_scale_box(_line, _max_width, _line_height - 4, UI_FS_ROW);

        draw_set_color(_text_color);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_text_transformed(
            _x,
            _y + _index * _line_height,
            _line,
            _scale,
            _scale,
            0
        );
    }

    if (array_length(_lines) > _limit) {
        var _more = "... ещё " + string(array_length(_lines) - _limit);
        var _more_scale = ui_fit_scale_box(_more, _max_width, _line_height - 4, UI_FS_ROW);

        draw_set_color(_soft_color);
        draw_text_transformed(
            _x,
            _y + _draw_count * _line_height,
            _more,
            _more_scale,
            _more_scale,
            0
        );
    }
}
