/// staff_hiring_search_system.gml
/// @description Фильтр профессий будущих кандидатов и страница поиска сотрудников.
/// Пакет №190: поиск можно ОСТАНОВИТЬ полностью — тогда кандидаты не приходят
/// вообще. Страница переделана: крупный шрифт, карточки профессий, большой
/// переключатель и понятная строка состояния.


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

    // Пакет №190: пустой список — это нормально. Значит поиск остановлен
    // и новые кандидаты в клинику не приходят.
    return _roles;
}

/// Поиск полностью остановлен: ни одной профессии не выбрано.
function staff_hiring_search_is_paused() {
    return array_length(staff_hiring_search_get_allowed_roles()) <= 0;
}

/// Включить или выключить сразу все профессии.
function staff_hiring_search_set_all(_enabled) {
    var _filter = staff_hiring_search_init();

    _filter.doctor = _enabled;
    _filter.admin = _enabled;
    _filter.assistant = _enabled;
    global.staff_hiring_role_filter = _filter;

    return _enabled;
}

function staff_hiring_search_pick_role() {
    var _roles = staff_hiring_search_get_allowed_roles();

    // Защита: сюда не должны попадать при остановленном поиске,
    // но если кандидат всё же создаётся (отладочная клавиша N) — врач.
    if (array_length(_roles) <= 0) return "doctor";

    return _roles[irandom(array_length(_roles) - 1)];
}

function staff_hiring_search_toggle(_role) {
    var _filter = staff_hiring_search_init();
    var _key = string(_role);

    if (!variable_struct_exists(_filter, _key)) return false;

    var _currently_enabled = variable_struct_get(_filter, _key);

    // Пакет №190: снимать можно все — это осознанная остановка найма.
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

    if (array_length(_roles) <= 0) return "НИКОГО";

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
    // Пакет №180: единый стиль вкладок из UI-кита.
    ui_draw_tab(_x1, _y1, _x2, _y2, _text, _selected, _hovered);
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

    // Пакет №180: размер вкладок — общий для всей игры.
    var _gap = UI_TAB_GAP;
    var _available_w = _x2 - _x1 - _gap;
    var _tab_w = min(UI_TAB_W, _available_w * 0.5);
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
        "ШТАТ",
        _hud.staff_manage_tab == "staff",
        _staff_hover
    );
    staff_hiring_search_draw_tab(
        _search_x1,
        _y1,
        _search_x2,
        _y2,
        "ПОИСК",
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
    // Пакет №190: карточка профессии — крупная, с большим переключателем
    // справа и цветной полосой слева. Текст рисуется с автоподгонкой,
    // поэтому «АДМИНИСТРАТОРЫ» влезает целиком при любом размере окна.
    var _colors = staff_hiring_search_role_colors(_role);
    var _fill = _enabled
        ? _colors.fill
        : make_color_rgb(224, 220, 212);

    if (_hovered) {
        _fill = merge_color(_fill, c_white, 0.34);
    }

    draw_set_alpha(0.12);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 3, _y1 + 4, _x2 + 3, _y2 + 4, 14, 14, false);
    draw_set_alpha(1);

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, false);
    draw_set_color(_enabled ? _colors.line : make_color_rgb(150, 145, 138));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, true);

    // Цветная метка профессии слева.
    draw_set_color(_enabled ? _colors.line : make_color_rgb(178, 173, 165));
    draw_roundrect_ext(_x1 + 8, _y1 + 10, _x1 + 18, _y2 - 10, 5, 5, false);

    // Переключатель справа.
    var _sw_h = min(46, max(30, (_y2 - _y1) - 18));
    var _sw_w = _sw_h * 2.1;
    var _sw_x2 = _x2 - 18;
    var _sw_x1 = _sw_x2 - _sw_w;
    var _sw_y1 = (_y1 + _y2 - _sw_h) * 0.5;
    var _sw_y2 = _sw_y1 + _sw_h;

    draw_set_color(_enabled
        ? make_color_rgb(62, 112, 74)
        : make_color_rgb(168, 162, 152));
    draw_roundrect_ext(_sw_x1, _sw_y1, _sw_x2, _sw_y2, _sw_h * 0.5, _sw_h * 0.5, false);

    var _knob_r = _sw_h * 0.5 - 4;
    var _knob_x = _enabled
        ? (_sw_x2 - _knob_r - 5)
        : (_sw_x1 + _knob_r + 5);

    draw_set_color(c_white);
    draw_circle(_knob_x, (_sw_y1 + _sw_y2) * 0.5, _knob_r, false);

    draw_set_color(_enabled
        ? make_color_rgb(62, 112, 74)
        : make_color_rgb(120, 114, 106));
    ui_text_fit_center(
        _enabled ? (_sw_x1 + _knob_r + 6) : (_sw_x2 - _knob_r - 6),
        (_sw_y1 + _sw_y2) * 0.5,
        _enabled ? "ДА" : "НЕТ",
        _sw_w - _knob_r * 2 - 12,
        UI_FS_SMALL
    );

    // Название профессии.
    draw_set_color(_enabled
        ? make_color_rgb(50, 38, 28)
        : make_color_rgb(120, 114, 106));
    ui_text_fit_middle(
        _x1 + 30,
        (_y1 + _y2) * 0.5,
        staff_hiring_search_role_name(_role),
        (_sw_x1 - _x1) - 46,
        UI_FS_BUTTON
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ═══════════════════════════════════════════════════════════════
// 3.1 БОЛЬШОЙ ПЕРЕКЛЮЧАТЕЛЬ «ИЩЕМ / НЕ ИЩЕМ» (пакет №190)
// ═══════════════════════════════════════════════════════════════

function staff_hiring_search_draw_master_button(_x1, _y1, _x2, _y2, _paused, _hovered) {
    var _fill = _paused
        ? make_color_rgb(240, 222, 218)
        : make_color_rgb(226, 240, 226);
    var _line = _paused
        ? make_color_rgb(148, 74, 64)
        : make_color_rgb(62, 112, 74);

    if (_hovered) _fill = merge_color(_fill, c_white, 0.32);

    draw_set_alpha(0.12);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 3, _y1 + 4, _x2 + 3, _y2 + 4, 14, 14, false);
    draw_set_alpha(1);

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, false);
    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, true);

    draw_set_color(_line);
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5,
        _paused ? "ВОЗОБНОВИТЬ ПОИСК" : "ОСТАНОВИТЬ ПОИСК",
        (_x2 - _x1) - 30,
        UI_FS_BUTTON
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
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
    var _red = make_color_rgb(148, 74, 64);

    var _paused = staff_hiring_search_is_paused();
    var _pressed = hud_staff_manage_pointer_pressed();

    draw_set_color(_paper);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);

    var _pad = 26;
    var _inner_x1 = _x1 + _pad;
    var _inner_x2 = _x2 - _pad;
    var _inner_w = _inner_x2 - _inner_x1;
    var _y = _y1 + 18;

    // ── Заголовок ──
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_wood_dark);
    ui_text_row(_inner_x1, _y, 46, "КОГО ИЩЕТ КЛИНИКА", _inner_w, UI_FS_TITLE);
    _y += 50;

    draw_set_color(_text_soft);
    ui_text_row(
        _inner_x1,
        _y,
        34,
        "Включайте профессии переключателями. Можно снять все - тогда никто не придёт.",
        _inner_w,
        UI_FS_ROW
    );
    _y += 42;

    // ── Большой переключатель всего поиска ──
    var _master_h = 62;
    var _master_y1 = _y;
    var _master_y2 = _master_y1 + _master_h;
    var _master_hover = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _inner_x1,
        _master_y1,
        _inner_x2,
        _master_y2
    );

    staff_hiring_search_draw_master_button(
        _inner_x1,
        _master_y1,
        _inner_x2,
        _master_y2,
        _paused,
        _master_hover
    );

    if (_pressed && _master_hover) {
        staff_hiring_search_set_all(_paused);

        // Возобновили поиск — кандидат приходит в ближайшие 10-60 минут
        // игрового времени, а не ждёт завтрашнего расписания.
        if (_paused) {
            var _resume_minute = global.game_hour * 60
                + global.game_minute
                + irandom_range(10, 60);

            if (_resume_minute <= 18 * 60) {
                global.next_candidate_day = global.game_day;
                global.next_candidate_minute = _resume_minute;
            }
            else {
                global.next_candidate_day = global.game_day + 1;
                global.next_candidate_minute = irandom_range(9 * 60, 16 * 60);
            }
        }

        if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
            var _fps_master = max(1, game_get_speed(gamespeed_fps));

            _hud.show_notice(
                "ПОИСК СОТРУДНИКОВ",
                _paused
                    ? "Поиск возобновлён: ищем всех"
                    : "Поиск остановлен: кандидаты не придут",
                _fps_master * 3
            );
        }

        _paused = !_paused;
    }

    _y = _master_y2 + 16;

    // ── Карточки профессий ──
    var _roles = ["doctor", "admin", "assistant"];
    var _status_h = 168;
    var _cards_area = (_y2 - 20 - _status_h - 14) - _y;
    var _card_gap = 12;
    var _card_h = clamp((_cards_area - _card_gap * 2) / 3, 46, 78);

    for (var _index = 0; _index < array_length(_roles); _index++) {
        var _role = _roles[_index];
        var _role_y1 = _y + _index * (_card_h + _card_gap);
        var _role_y2 = _role_y1 + _card_h;
        var _enabled = staff_hiring_search_role_enabled(_role);
        var _hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _inner_x1,
            _role_y1,
            _inner_x2,
            _role_y2
        );

        staff_hiring_search_draw_role_button(
            _inner_x1,
            _role_y1,
            _inner_x2,
            _role_y2,
            _role,
            _enabled,
            _hovered
        );

        if (_pressed && _hovered && !_master_hover) {
            staff_hiring_search_toggle(_role);
            _paused = staff_hiring_search_is_paused();
        }
    }

    // ── Блок состояния ──
    var _status_y1 = _y2 - 20 - _status_h;
    var _status_y2 = _y2 - 20;

    draw_set_color(_panel);
    draw_roundrect_ext(_inner_x1, _status_y1, _inner_x2, _status_y2, 12, 12, false);
    draw_set_color(_paused ? _red : _line);
    draw_roundrect_ext(_inner_x1, _status_y1, _inner_x2, _status_y2, 12, 12, true);

    var _status_x = _inner_x1 + 20;
    var _status_w = _inner_w - 40;
    var _status_y = _status_y1 + 12;

    draw_set_color(_text_dark);
    ui_text_row(_status_x, _status_y, 38, "СЕЙЧАС ИЩЕМ", _status_w, UI_FS_HEADER);
    _status_y += 40;

    draw_set_color(_paused ? _red : _green);
    ui_text_row(
        _status_x,
        _status_y,
        40,
        _paused ? "НИКОГО - ПОИСК ОСТАНОВЛЕН" : staff_hiring_search_filter_text(),
        _status_w,
        UI_FS_VALUE
    );
    _status_y += 42;

    if (_paused) {
        draw_set_color(_text_soft);
        ui_text_row(
            _status_x,
            _status_y,
            36,
            "Новые кандидаты в клинику приходить не будут.",
            _status_w,
            UI_FS_ROW
        );
        _status_y += 38;
    }
    else {
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
        ui_text_row(
            _status_x,
            _status_y,
            36,
            "СЛЕДУЮЩИЙ КАНДИДАТ: ДЕНЬ " + string(_next_day) + ", " + _next_time,
            _status_w,
            UI_FS_ROW
        );
        _status_y += 38;
    }

    if (instance_exists(global.current_candidate)) {
        var _current = global.current_candidate;
        var _current_role = variable_instance_exists(_current, "role")
            ? staff_hiring_search_role_name(_current.role)
            : "СОТРУДНИК";

        draw_set_color(_blue);
        ui_text_row(
            _status_x,
            _status_y,
            36,
            "УЖЕ ЖДЁТ: " + string_upper(string(_current.char_name)) + " - " + _current_role,
            _status_w,
            UI_FS_ROW
        );
    }
    else if (!_paused) {
        draw_set_color(_text_soft);
        ui_text_row(
            _status_x,
            _status_y,
            36,
            "Настройки применятся к следующему кандидату.",
            _status_w,
            UI_FS_ROW
        );
    }

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
