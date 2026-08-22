/// hud_draw_main_bars.gml
/// @description Верхняя панель, время, ресурсы, скорость и нижнее меню.
/// Пакет №155: вариант B — окошки из матового стекла в деревянной панели.
/// Пакет №156: подпись и цифра сведены вплотную (зазор -12).
/// Пакет №157: кнопки времени — плоские «бумажные» (как в макете B), без толстой обводки.
/// Пропорции/размеры прежние (5 равных окошек, подписи 1.9, цифры 3.2,
/// время 3.4, высота панели 106, сдвиг надписей вниз 6).

// Кнопка времени — плоская «бумажная», как в макете (вариант B):
// светлая заливка, тонкая рамка, лёгкая тень, без толстой деревянной обводки.
function hud_draw_time_button(_x1, _y1, _x2, _y2, _text, _active, _hover) {
    // Лёгкая тень.
    draw_set_alpha(0.20);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 1, _y1 + 2, _x2 + 1, _y2 + 2, 8, 8, false);
    draw_set_alpha(1);

    // Заливка.
    var _fill;
    if (_active) {
        _fill = make_color_rgb(220, 202, 172);
    } else if (_hover) {
        _fill = make_color_rgb(248, 238, 220);
    } else {
        _fill = make_color_rgb(242, 232, 214);
    }
    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, false);

    // Тонкая рамка.
    draw_set_color(make_color_rgb(168, 150, 126));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, true);

    // Текст по центру. Пакет №175: крупно, с автоподгонкой под ширину.
    draw_set_color(make_color_rgb(50, 38, 28));
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5 + 1,
        _text,
        (_x2 - _x1) - 16,
        UI_FS_BUTTON
    );
}

// Окошко верхней панели: матовое стекло + тонкая светлая окантовка.
function hud_draw_top_card(_x1, _y1, _x2, _y2) {
    draw_set_alpha(0.15);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 2, _y1 + 3, _x2 + 2, _y2 + 3, 10, 10, false);
    draw_set_alpha(1);

    // Стекло (полупрозрачная заливка + блик сверху) — общая функция панелей.
    hud_frosted_fill(_x1, _y1, _x2, _y2, 10, 0.30, 0.22);

    // Тонкая светлая окантовка.
    draw_set_alpha(0.5);
    draw_set_color(make_color_rgb(255, 252, 242));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);
    draw_set_alpha(1);
}

// Пара «подпись + значение» по центру колонки (_cx) по вертикали и горизонтали.
// Значение сжимается только по горизонтали (высота всегда одинаковая).
// _gap — зазор между подписью и значением (может быть отрицательным).
function hud_draw_top_value(_cx, _y1, _y2, _label, _value, _value_color, _label_color, _label_scale, _value_scale, _fit_w, _shift_down, _gap) {
    var _ls = _label_scale;
    if (string_width(_label) * _ls > _fit_w) {
        _ls = max(0.4, _fit_w / max(1, string_width(_label)));
    }

    var _vs = _value_scale;
    if (string_width(_value) * _vs > _fit_w) {
        _vs = max(0.4, _fit_w / max(1, string_width(_value)));
    }

    var _lh = string_height(_label) * _ls;
    var _vh = string_height(_value) * _value_scale;
    var _block = _lh + _gap + _vh;
    var _ty = _y1 + ((_y2 - _y1) - _block) * 0.5 + _shift_down;

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    draw_set_color(_label_color);
    draw_text_transformed(_cx, _ty, _label, _ls, _ls, 0);

    draw_set_color(_value_color);
    draw_text_transformed(_cx, _ty + _lh + _gap, _value, _vs, _value_scale, 0);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function hud_draw_main_bars(_hud) {
    if (!instance_exists(_hud)) return;

    with (_hud) {
        var _wood_dark = make_color_rgb(74, 49, 31);
        var _wood_mid = make_color_rgb(114, 77, 50);
        var _wood_light = make_color_rgb(150, 107, 73);
        var _paper = make_color_rgb(242, 232, 214);
        var _paper_hover = make_color_rgb(248, 238, 220);
        var _paper_active = make_color_rgb(220, 202, 172);
        var _line_dark = make_color_rgb(58, 39, 24);
        var _text_dark = make_color_rgb(50, 38, 28);

        // Пакет №155: светлые цвета для стекла (читаются на прозрачном фоне).
        var _label_light = make_color_rgb(232, 223, 204);
        var _time_col = make_color_rgb(250, 246, 238);
        var _accent_green = make_color_rgb(111, 212, 138);
        var _accent_gold = make_color_rgb(238, 193, 79);
        var _accent_blue = make_color_rgb(143, 183, 224);

        var _label_scale = 1.9;
        var _value_scale = 3.2;
        var _time_scale = 3.4;
        var _date_scale = 1.0;
        var _shift_down = 6;
        var _value_gap = -12;   // пакет №156: зазор подпись<->цифра (отрицательный = вплотную)

        var _week_names = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"];
        var _time_text = hud_clock_text(global.game_hour, global.game_minute);
        var _date_text = _week_names[global.week_day_index]
            + "  "
            + (global.calendar_day < 10 ? "0" : "")
            + string(global.calendar_day)
            + "."
            + (global.calendar_month < 10 ? "0" : "")
            + string(global.calendar_month)
            + "."
            + string(global.calendar_year);

        var _clean_value = variable_global_exists("clinic_cleanliness")
            ? round(global.clinic_cleanliness)
            : 100;
        var _clean_col = merge_color(
            make_color_rgb(235, 120, 105),
            make_color_rgb(111, 212, 138),
            clamp(_clean_value / 100, 0, 1)
        );

        hud_draw_wood_panel(
            topbar_x1,
            topbar_y1,
            topbar_x2,
            topbar_y2,
            _wood_dark,
            _wood_mid,
            _wood_light,
            _line_dark
        );

        // ── Шесть окошек одинаковой ширины (пакет №196: добавлен ШТАТ) ──
        var _y1 = topbar_y1 + 8;
        var _y2 = topbar_y2 - 8;
        var _gap = 10;
        var _left = topbar_x1 + 14;
        var _right = pause_x1 - 12;

        var _pad = 30;
        var _box_w = string_width("РЕПУТАЦИЯ") * _label_scale + _pad;

        var _avail = (_right - _left) - _gap * 5;
        if (6 * _box_w > _avail) {
            _box_w = floor(_avail / 6);
        }

        var _fit_w = _box_w - 16;
        var _x = _left;

        // 1) ВРЕМЯ.
        hud_draw_top_card(_x, _y1, _x + _box_w, _y2);
        hud_draw_top_value(
            _x + _box_w * 0.5, _y1, _y2,
            _date_text, _time_text,
            _time_col, _label_light,
            _date_scale, _time_scale, _fit_w, 0, 0
        );
        _x += _box_w + _gap;

        // 2) РЕПУТАЦИЯ.
        hud_draw_top_card(_x, _y1, _x + _box_w, _y2);
        hud_draw_top_value(
            _x + _box_w * 0.5, _y1, _y2,
            "РЕПУТАЦИЯ", string(global.clinic_reputation),
            _accent_blue, _label_light,
            _label_scale, _value_scale, _fit_w, _shift_down, _value_gap
        );
        _x += _box_w + _gap;

        // 3) ЧИСТОТА.
        hud_draw_top_card(_x, _y1, _x + _box_w, _y2);
        hud_draw_top_value(
            _x + _box_w * 0.5, _y1, _y2,
            "ЧИСТОТА", string(_clean_value) + "%",
            _clean_col, _label_light,
            _label_scale, _value_scale, _fit_w, _shift_down, _value_gap
        );
        _x += _box_w + _gap;

        // 4) ДЕНЬГИ.
        hud_draw_top_card(_x, _y1, _x + _box_w, _y2);
        hud_draw_top_value(
            _x + _box_w * 0.5, _y1, _y2,
            "ДЕНЬГИ", "$ " + string(global.clinic_money),
            _accent_green, _label_light,
            _label_scale, _value_scale, _fit_w, _shift_down, _value_gap
        );
        _x += _box_w + _gap;

        // 5) БАЛЛЫ.
        hud_draw_top_card(_x, _y1, _x + _box_w, _y2);
        hud_draw_top_value(
            _x + _box_w * 0.5, _y1, _y2,
            "БАЛЛЫ", string(clinic_get_points()),
            _accent_gold, _label_light,
            _label_scale, _value_scale, _fit_w, _shift_down, _value_gap
        );
        _x += _box_w + _gap;

        // 6) ШТАТ (пакет №196): сколько сотрудников нанято и сколько
        // всего слотов найма. Главный игрок не считается — слоты всегда
        // считались без него, как и в дереве развития.
        var _staff_hired = instance_number(obj_staff_doctor)
            + instance_number(obj_staff_admin)
            + instance_number(obj_staff_assistant);
        var _staff_slots = clinic_get_hire_slots();
        var _staff_col = (_staff_hired >= _staff_slots)
            ? make_color_rgb(235, 120, 105)
            : _accent_green;

        hud_draw_top_card(_x, _y1, _x + _box_w, _y2);
        hud_draw_top_value(
            _x + _box_w * 0.5, _y1, _y2,
            "ШТАТ", string(_staff_hired) + "/" + string(_staff_slots),
            _staff_col, _label_light,
            _label_scale, _value_scale, _fit_w, _shift_down, _value_gap
        );

        // ── Кнопки времени (плоские, как в макете) ──
        var _pause_active = global.time_paused;

        hud_draw_time_button(pause_x1, pause_y1, pause_x2, pause_y2, "II", _pause_active, hover_pause);
        hud_draw_time_button(speed1_x1, speed1_y1, speed1_x2, speed1_y2, "1x", !global.time_paused && global.time_speed == 1, hover_1x);
        hud_draw_time_button(speed2_x1, speed2_y1, speed2_x2, speed2_y2, "2x", !global.time_paused && global.time_speed == 2, hover_2x);
        hud_draw_time_button(speed4_x1, speed4_y1, speed4_x2, speed4_y2, "4x", !global.time_paused && global.time_speed == 4, hover_4x);

        // ── Нижнее меню (без изменений) ──
        hud_draw_wood_panel(
            bottombar_x1,
            bottombar_y1,
            bottombar_x2,
            bottombar_y2,
            _wood_dark,
            _wood_mid,
            _wood_light,
            _line_dark
        );

        var _staff_active = variable_instance_exists(id, "staff_manage_panel_open")
            ? staff_manage_panel_open
            : staff_panel_open;
        var _finance_active = variable_instance_exists(id, "finance_manage_panel_open")
            ? finance_manage_panel_open
            : finance_panel_open;

        // Пакет №69: пятая кнопка «СПРАВОЧНИК» в нижнем меню.
        var _handbook_active = variable_instance_exists(id, "handbook_open")
            && handbook_open;
        var _hover_handbook = variable_instance_exists(id, "hover_handbook")
            && hover_handbook;
        var _handbook_btn_x1 = variable_instance_exists(id, "handbook_x1")
            ? handbook_x1
            : finance_x2 + 14;
        var _handbook_btn_y1 = variable_instance_exists(id, "handbook_y1")
            ? handbook_y1
            : clinic_y1;
        var _handbook_btn_x2 = variable_instance_exists(id, "handbook_x2")
            ? handbook_x2
            : _handbook_btn_x1 + 180;
        var _handbook_btn_y2 = variable_instance_exists(id, "handbook_y2")
            ? handbook_y2
            : clinic_y2;

        hud_draw_button(clinic_x1, clinic_y1, clinic_x2, clinic_y2, "КЛИНИКА", clinic_panel_open, hover_clinic, _paper, _paper_hover, _paper_active, _line_dark, _text_dark);
        hud_draw_button(clients_x1, clients_y1, clients_x2, clients_y2, "КЛИЕНТЫ", clients_panel_open, hover_clients, _paper, _paper_hover, _paper_active, _line_dark, _text_dark);
        hud_draw_button(staff_x1, staff_y1, staff_x2, staff_y2, "ПЕРСОНАЛ", _staff_active, hover_staff, _paper, _paper_hover, _paper_active, _line_dark, _text_dark);
        hud_draw_button(finance_x1, finance_y1, finance_x2, finance_y2, "ФИНАНСЫ", _finance_active, hover_finance, _paper, _paper_hover, _paper_active, _line_dark, _text_dark);
        hud_draw_button(_handbook_btn_x1, _handbook_btn_y1, _handbook_btn_x2, _handbook_btn_y2, "СПРАВОЧНИК", _handbook_active, _hover_handbook, _paper, _paper_hover, _paper_active, _line_dark, _text_dark);
    }
}
