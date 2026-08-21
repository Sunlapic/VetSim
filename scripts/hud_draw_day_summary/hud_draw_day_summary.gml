/// hud_draw_day_summary.gml
/// @description Итоги дня, закупки, зарплаты и чистая прибыль.
/// Пакет №120: окно итогов на матовом стекле (дерево только рамкой).

function hud_draw_day_summary(_hud) {
    if (!instance_exists(_hud)) return;
    if (!variable_global_exists("day_summary_open")) return;
    if (!global.day_summary_open || !global.day_summary_ready) return;

    with (_hud) {
        var _gui_w = display_get_gui_width();
        var _gui_h = display_get_gui_height();
        var _wood_dark = make_color_rgb(74, 49, 31);
        var _wood_light = make_color_rgb(150, 107, 73);
        var _paper = make_color_rgb(242, 232, 214);
        var _paper_2 = make_color_rgb(232, 220, 198);
        var _line_dark = make_color_rgb(58, 39, 24);
        var _text_dark = make_color_rgb(50, 38, 28);
        var _text_soft = make_color_rgb(90, 70, 50);
        var _green = make_color_rgb(62, 112, 74);
        var _red = make_color_rgb(148, 74, 64);
        var _gold = make_color_rgb(180, 140, 64);
        var _week_names = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"];
        var _earned = global.daily_stats.earned_money;
        var _spent_total = global.daily_stats.spent_money;
        var _salary = variable_struct_exists(global.daily_stats, "salary_expense")
            ? global.daily_stats.salary_expense
            : 0;
        var _purchases = max(0, _spent_total - _salary);
        var _profit = _earned - _spent_total;
        var _reputation_delta = global.daily_stats.reputation_delta;
        var _reputation_text = string(global.clinic_reputation);

        if (_reputation_delta > 0) {
            _reputation_text += " (+" + string(_reputation_delta) + ")";
        }
        else if (_reputation_delta < 0) {
            _reputation_text += " (" + string(_reputation_delta) + ")";
        }

        var _rows = [
            { label : "Заработано:", value : "$" + string(_earned), color : _green },
            { label : "Закупка препаратов:", value : "$" + string(_purchases), color : _red },
            { label : "Зарплата персонала:", value : "$" + string(_salary), color : _red },
            { label : "Расходы всего:", value : "$" + string(_spent_total), color : _red },
            { label : "Принято пациентов:", value : string(global.daily_stats.paid_visits), color : _text_dark },
            { label : "Поставлено диагнозов:", value : string(global.daily_stats.new_diagnosed), color : _text_dark },
            { label : "Процедур выполнено:", value : string(global.daily_stats.procedures_done), color : _text_dark },
            { label : "Записано на повтор:", value : string(global.daily_stats.followups_scheduled), color : _text_dark },
            { label : "Репутация клиники:", value : _reputation_text, color : _gold }
        ];
        var _padding = 22;
        var _row_height = 30;
        var _title_height = 64;
        var _profit_height = 50;
        var _button_height = 60;
        var _button_padding = 14;
        var _title = "ИТОГИ ДНЯ №"
            + string(global.daily_stats.day_num)
            + "  ("
            + _week_names[global.daily_stats.week_day]
            + " "
            + string(global.daily_stats.calendar_day)
            + "."
            + string(global.daily_stats.calendar_month)
            + ")";
        var _label_width = string_width("Зарплата персонала:");
        var _value_width = string_width("$" + string(max(_earned, _spent_total)));
        var _window_width = max(
            string_width(_title) + 40,
            _label_width + _value_width + _padding * 2 + 50
        );
        var _window_height = _title_height
            + array_length(_rows) * _row_height
            + 14
            + _profit_height
            + _button_padding
            + _button_height
            + _padding * 2;
        var _window_x1 = (_gui_w - _window_width) * 0.5;
        var _window_y1 = (_gui_h - _window_height) * 0.5;
        var _window_x2 = _window_x1 + _window_width;
        var _window_y2 = _window_y1 + _window_height;

        draw_set_color(c_black);
        draw_set_alpha(0.65);
        draw_rectangle(0, 0, _gui_w, _gui_h, false);
        draw_set_alpha(0.35);
        draw_roundrect_ext(_window_x1 + 4, _window_y1 + 6, _window_x2 + 4, _window_y2 + 6, 14, 14, false);
        draw_set_alpha(1);

        // Пакет №120: матовое стекло + деревянная рамка по краю.
        hud_draw_frosted_panel(_window_x1, _window_y1, _window_x2, _window_y2, 8);

        var _header_y1 = _window_y1 + 6;
        var _header_y2 = _header_y1 + _title_height - 10;
        draw_set_color(_paper_2);
        draw_roundrect_ext(_window_x1 + 8, _header_y1, _window_x2 - 8, _header_y2, 8, 8, false);
        draw_set_color(_line_dark);
        draw_line(_window_x1 + 14, _header_y2, _window_x2 - 14, _header_y2);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(_text_dark);
        draw_text((_window_x1 + _window_x2) * 0.5, (_header_y1 + _header_y2) * 0.5, _title);

        var _row_x1 = _window_x1 + _padding;
        var _row_x2 = _window_x2 - _padding;
        var _row_start_y = _header_y2 + 18;

        for (var _row_index = 0; _row_index < array_length(_rows); _row_index++) {
            var _row = _rows[_row_index];
            var _row_y = _row_start_y + _row_index * _row_height;
            draw_set_halign(fa_left);
            draw_set_color(_text_soft);
            draw_text(_row_x1, _row_y + 2, _row.label);
            draw_set_halign(fa_right);
            draw_set_color(_row.color);
            draw_text(_row_x2, _row_y + 2, _row.value);
        }

        var _separator_y = _row_start_y + array_length(_rows) * _row_height;
        draw_set_color(_line_dark);
        draw_line(_window_x1 + 20, _separator_y, _window_x2 - 20, _separator_y);
        draw_set_halign(fa_left);
        draw_set_color(_text_dark);
        draw_text(_row_x1, _separator_y + 20, "ЧИСТАЯ ПРИБЫЛЬ:");
        draw_set_halign(fa_right);
        draw_set_color(_profit >= 0 ? _green : _red);
        draw_text_transformed(_row_x2, _separator_y + 20, "$" + string(_profit), 1.15, 1.15, 0);

        var _button_x1 = _window_x1 + _padding;
        var _button_y1 = _window_y2 - _button_height - _padding;
        var _button_x2 = _window_x2 - _padding;
        var _button_y2 = _button_y1 + _button_height;
        var _mouse_x = device_mouse_x_to_gui(0);
        var _mouse_y = device_mouse_y_to_gui(0);
        var _button_hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _button_x1,
            _button_y1,
            _button_x2,
            _button_y2
        );

        draw_set_color(_wood_dark);
        draw_roundrect_ext(_button_x1, _button_y1, _button_x2, _button_y2, 10, 10, false);
        draw_set_color(_wood_light);
        draw_roundrect_ext(_button_x1 + 2, _button_y1 + 2, _button_x2 - 2, _button_y2 - 2, 8, 8, false);
        draw_set_color(_button_hovered ? make_color_rgb(252, 244, 226) : _paper);
        draw_roundrect_ext(_button_x1 + 5, _button_y1 + 5, _button_x2 - 5, _button_y2 - 5, 7, 7, false);
        draw_set_color(_line_dark);
        draw_roundrect_ext(_button_x1, _button_y1, _button_x2, _button_y2, 10, 10, true);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(_text_dark);
        draw_text_transformed((_button_x1 + _button_x2) * 0.5, (_button_y1 + _button_y2) * 0.5 + 1, "НОВЫЙ ДЕНЬ", 1.2, 1.2, 0);

        if (
            _button_hovered
            && tablet_click_lock <= 0
            && mouse_check_button_pressed(mb_left)
        ) {
            tablet_click_lock = 5;
            global.day_summary_open = false;
            global.day_summary_ready = false;
            global.time_paused = false;
        }
    }
}
