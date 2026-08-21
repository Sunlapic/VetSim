/// staff_hiring_search_system.gml
/// @description Фильтр профессий будущих кандидатов и страница поиска сотрудников.


// ═══════════════════════════════════════════════════════════════
// 1. ДАННЫЕ ФИЛЬТРА
// ═══════════════════════════════════════════════════════════════

function staff_hiring_search_init() {
    if (!variable_global_exists("staff_hiring_role_filter")) {
        global.staff_hiring_role_filter = {
            doctor : true,
            admin : true,
            assistant : true
        };
    }

    var _filter = global.staff_hiring_role_filter;

    if (!variable_struct_exists(_filter, "doctor")) {
        _filter.doctor = true;
    }
    if (!variable_struct_exists(_filter, "admin")) {
        _filter.admin = true;
    }
    if (!variable_struct_exists(_filter, "assistant")) {
        _filter.assistant = true;
    }

    global.staff_hiring_role_filter = _filter;
    return _filter;
}

function staff_hiring_search_role_enabled(_role) {
    var _filter = staff_hiring_search_init();
    var _key = string(_role);

    return variable_struct_exists(_filter, _key)
        && variable_struct_get(_filter, _key);
}

function staff_hiring_search_get_allowed_roles() {
    var _filter = staff_hiring_search_init();
    var _roles = [];

    if (_filter.doctor) array_push(_roles, "doctor");
    if (_filter.admin) array_push(_roles, "admin");
    if (_filter.assistant) array_push(_roles, "assistant");

    // Страховка от старого повреждённого сохранения.
    if (array_length(_roles) <= 0) {
        _filter.doctor = true;
        _filter.admin = true;
        _filter.assistant = true;
        global.staff_hiring_role_filter = _filter;
        _roles = ["doctor", "admin", "assistant"];
    }

    return _roles;
}

function staff_hiring_search_pick_role() {
    var _roles = staff_hiring_search_get_allowed_roles();
    return _roles[irandom(array_length(_roles) - 1)];
}

function staff_hiring_search_toggle(_role) {
    var _filter = staff_hiring_search_init();
    var _key = string(_role);

    if (!variable_struct_exists(_filter, _key)) return false;

    var _enabled_count = 0;
    if (_filter.doctor) _enabled_count += 1;
    if (_filter.admin) _enabled_count += 1;
    if (_filter.assistant) _enabled_count += 1;

    var _currently_enabled = variable_struct_get(_filter, _key);

    // Хотя бы одна профессия всегда должна оставаться включённой.
    if (_currently_enabled && _enabled_count <= 1) {
        return false;
    }

    variable_struct_set(_filter, _key, !_currently_enabled);
    global.staff_hiring_role_filter = _filter;
    return true;
}

function staff_hiring_search_role_name(_role) {
    switch (string(_role)) {
        case "doctor": return "ВРАЧИ";
        case "admin": return "АДМИНИСТРАТОРЫ";
        case "assistant": return "АССИСТЕНТЫ";
    }

    return "СОТРУДНИКИ";
}

function staff_hiring_search_filter_text() {
    var _roles = staff_hiring_search_get_allowed_roles();
    var _result = "";

    for (var _index = 0; _index < array_length(_roles); _index++) {
        if (_result != "") _result += ", ";
        _result += staff_hiring_search_role_name(_roles[_index]);
    }

    return _result;
}


// ═══════════════════════════════════════════════════════════════
// 2. ВКЛАДКИ ПАНЕЛИ ПЕРСОНАЛА
// ═══════════════════════════════════════════════════════════════

function staff_hiring_search_draw_tab(
    _x1,
    _y1,
    _x2,
    _y2,
    _text,
    _selected,
    _hovered
) {
    var _fill = _selected
        ? make_color_rgb(205, 224, 193)
        : (_hovered
            ? make_color_rgb(224, 238, 248)
            : make_color_rgb(225, 216, 199));
    var _line = _selected
        ? make_color_rgb(104, 137, 91)
        : make_color_rgb(104, 135, 160);

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, false);
    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text((_x1 + _x2) * 0.5, (_y1 + _y2) * 0.5, _text);
}

function staff_hiring_search_draw_tabs(
    _hud,
    _x1,
    _y1,
    _x2,
    _y2,
    _mouse_x,
    _mouse_y
) {
    if (!variable_instance_exists(_hud, "staff_manage_tab")) {
        _hud.staff_manage_tab = "staff";
    }

    var _gap = 10;
    var _available_w = _x2 - _x1 - _gap;
    var _tab_w = min(250, _available_w * 0.5);
    var _staff_x1 = _x1;
    var _staff_x2 = _staff_x1 + _tab_w;
    var _search_x1 = _staff_x2 + _gap;
    var _search_x2 = _search_x1 + _tab_w;
    var _staff_hover = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _staff_x1,
        _y1,
        _staff_x2,
        _y2
    );
    var _search_hover = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _search_x1,
        _y1,
        _search_x2,
        _y2
    );

    staff_hiring_search_draw_tab(
        _staff_x1,
        _y1,
        _staff_x2,
        _y2,
        "ШТАТ КЛИНИКИ",
        _hud.staff_manage_tab == "staff",
        _staff_hover
    );
    staff_hiring_search_draw_tab(
        _search_x1,
        _y1,
        _search_x2,
        _y2,
        "ПОИСК СОТРУДНИКОВ",
        _hud.staff_manage_tab == "search",
        _search_hover
    );

    if (
        !_hud.staff_manage_fire_confirm
        && hud_staff_manage_pointer_pressed()
    ) {
        if (_staff_hover) {
            _hud.staff_manage_tab = "staff";
        }
        else if (_search_hover) {
            _hud.staff_manage_tab = "search";

            if (variable_instance_exists(_hud, "staff_workplace_menu_open")) {
                _hud.staff_workplace_menu_open = false;
                _hud.staff_workplace_menu_target = noone;
            }
        }
    }

    return _hud.staff_manage_tab;
}


// ═══════════════════════════════════════════════════════════════
// 3. КНОПКА ПРОФЕССИИ
// ═══════════════════════════════════════════════════════════════

function staff_hiring_search_role_colors(_role) {
    switch (string(_role)) {
        case "doctor":
            return {
                fill : make_color_rgb(232, 240, 248),
                line : make_color_rgb(104, 135, 160)
            };

        case "admin":
            return {
                fill : make_color_rgb(248, 235, 240),
                line : make_color_rgb(158, 108, 128)
            };

        case "assistant":
            return {
                fill : make_color_rgb(235, 246, 234),
                line : make_color_rgb(95, 140, 96)
            };
    }

    return {
        fill : make_color_rgb(242, 232, 214),
        line : make_color_rgb(180, 160, 140)
    };
}

function staff_hiring_search_draw_role_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _role,
    _enabled,
    _hovered
) {
    var _colors = staff_hiring_search_role_colors(_role);
    var _fill = _enabled
        ? _colors.fill
        : make_color_rgb(215, 211, 203);

    if (_hovered) {
        _fill = merge_color(_fill, c_white, 0.34);
    }

    draw_set_alpha(0.12);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 3, _y1 + 4, _x2 + 3, _y2 + 4, 12, 12, false);
    draw_set_alpha(1);
    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
    draw_set_color(_enabled ? _colors.line : make_color_rgb(140, 135, 128));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text(_x1 + 22, (_y1 + _y2) * 0.5, staff_hiring_search_role_name(_role));

    var _mark_size = min(30, max(18, _y2 - _y1 - 12));
    var _mark_x2 = _x2 - 18;
    var _mark_x1 = _mark_x2 - _mark_size;
    var _mark_y1 = (_y1 + _y2 - _mark_size) * 0.5;
    var _mark_y2 = _mark_y1 + _mark_size;

    draw_set_color(_enabled ? _colors.line : make_color_rgb(180, 175, 166));
    draw_roundrect_ext(_mark_x1, _mark_y1, _mark_x2, _mark_y2, 7, 7, false);
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(
        (_mark_x1 + _mark_x2) * 0.5,
        (_mark_y1 + _mark_y2) * 0.5,
        _enabled ? "ДА" : "—"
    );
}


// ═══════════════════════════════════════════════════════════════
// 4. СТРАНИЦА «ПОИСК СОТРУДНИКОВ»
// ═══════════════════════════════════════════════════════════════

function staff_hiring_search_draw_page(
    _hud,
    _x1,
    _y1,
    _x2,
    _y2,
    _mouse_x,
    _mouse_y
) {
    staff_hiring_search_init();

    var _paper = make_color_rgb(252, 250, 246);
    var _panel = make_color_rgb(248, 240, 224);
    var _line = make_color_rgb(180, 160, 140);
    var _wood_dark = make_color_rgb(74, 49, 31);
    var _text_dark = make_color_rgb(50, 38, 28);
    var _text_soft = make_color_rgb(84, 68, 54);
    var _blue = make_color_rgb(72, 112, 145);
    var _green = make_color_rgb(62, 112, 74);

    draw_set_color(_paper);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_wood_dark);
    draw_text_transformed(
        _x1 + 26,
        _y1 + 24,
        "КОГО ИЩЕТ КЛИНИКА?",
        1.20,
        1.20,
        0
    );
    draw_set_color(_text_soft);
    draw_text_ext(
        _x1 + 26,
        _y1 + 60,
        "Включите одну или несколько профессий. Выбор сохраняется и применяется ко всем следующим кандидатам, пока вы сами его не измените.",
        19,
        _x2 - _x1 - 52
    );

    var _roles = ["doctor", "admin", "assistant"];
    var _page_h = _y2 - _y1;
    var _header_h = clamp(_page_h * 0.20, 70, 118);
    var _status_h = clamp(_page_h * 0.23, 78, 158);
    var _button_gap = clamp(_page_h * 0.02, 6, 14);
    var _button_area_h = max(
        84,
        _page_h - _header_h - _status_h - 24 - _button_gap * 2
    );
    var _button_x1 = _x1 + 26;
    var _button_x2 = _x2 - 26;
    var _button_y = _y1 + _header_h;
    var _button_h = clamp(_button_area_h / 3, 28, 70);
    var _pressed = hud_staff_manage_pointer_pressed();

    for (var _index = 0; _index < array_length(_roles); _index++) {
        var _role = _roles[_index];
        var _role_y1 = _button_y + _index * (_button_h + _button_gap);
        var _role_y2 = _role_y1 + _button_h;
        var _enabled = staff_hiring_search_role_enabled(_role);
        var _hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _button_x1,
            _role_y1,
            _button_x2,
            _role_y2
        );

        staff_hiring_search_draw_role_button(
            _button_x1,
            _role_y1,
            _button_x2,
            _role_y2,
            _role,
            _enabled,
            _hovered
        );

        if (_pressed && _hovered) {
            var _changed = staff_hiring_search_toggle(_role);

            if (!_changed && instance_exists(obj_UI_HUD)) {
                var _fps = max(1, game_get_speed(gamespeed_fps));
                _hud.show_notice(
                    "ПОИСК СОТРУДНИКОВ",
                    "Нельзя отключить все профессии",
                    _fps * 2
                );
            }
        }
    }

    var _status_y1 = _button_y
        + 3 * _button_h
        + 2 * _button_gap
        + 12;
    var _status_y2 = _y2 - 24;

    draw_set_color(_panel);
    draw_roundrect_ext(
        _x1 + 26,
        _status_y1,
        _x2 - 26,
        _status_y2,
        10,
        10,
        false
    );
    draw_set_color(_line);
    draw_roundrect_ext(
        _x1 + 26,
        _status_y1,
        _x2 - 26,
        _status_y2,
        10,
        10,
        true
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_text_dark);
    draw_text(_x1 + 44, _status_y1 + 16, "СЕЙЧАС ИЩЕМ:");
    draw_set_color(_green);
    draw_text_ext(
        _x1 + 44,
        _status_y1 + 42,
        staff_hiring_search_filter_text(),
        18,
        _x2 - _x1 - 88
    );

    var _next_day = variable_global_exists("next_candidate_day")
        ? global.next_candidate_day
        : global.game_day;
    var _next_minute = variable_global_exists("next_candidate_minute")
        ? global.next_candidate_minute
        : 0;
    var _next_hour = floor(_next_minute / 60);
    var _next_minute_part = _next_minute mod 60;
    var _next_time = (_next_hour < 10 ? "0" : "")
        + string(_next_hour)
        + ":"
        + (_next_minute_part < 10 ? "0" : "")
        + string(_next_minute_part);

    draw_set_color(_text_dark);
    draw_text(
        _x1 + 44,
        _status_y1 + 78,
        "СЛЕДУЮЩИЙ КАНДИДАТ: ДЕНЬ "
            + string(_next_day)
            + ", "
            + _next_time
    );

    if (instance_exists(global.current_candidate)) {
        var _current = global.current_candidate;
        var _current_role = variable_instance_exists(_current, "role")
            ? staff_hiring_search_role_name(_current.role)
            : "СОТРУДНИК";

        draw_set_color(_blue);
        draw_text_ext(
            _x1 + 44,
            _status_y1 + 108,
            "Текущий кандидат уже выбран: "
                + string_upper(string(_current.char_name))
                + " — "
                + _current_role
                + ". Новые настройки применятся к следующему.",
            18,
            _x2 - _x1 - 88
        );
    }
    else {
        draw_set_color(_text_soft);
        draw_text(
            _x1 + 44,
            _status_y1 + 108,
            "Фильтр применится при создании следующего кандидата."
        );
    }

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
