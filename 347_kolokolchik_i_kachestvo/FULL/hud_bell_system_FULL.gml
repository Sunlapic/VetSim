/// hud_bell_system.gml
/// @description ПАКЕТ №347. Кнопка-колокольчик и панель просьб.
///
/// ── Зачем ──
///
/// Просьбы о прибавке зарплаты считались с пакета №320, но ни один
/// интерфейс их не показывал — игрок никогда их не видел. Теперь
/// рядом с шестерёнкой висит колокольчик того же размера:
///
///   • красный кружок — есть непрочитанные просьбы;
///   • тап по колокольчику — панель со всеми просьбами;
///   • у каждой просьбы «ДА» (поднять зарплату) и «НЕТ» (отказать);
///   • на решение 3 дня, потом просьба отклоняется сама
///     (staff_requests_expire в staff_salary_system).
///
/// Просьбы приходят и из активной клиники (инстансы), и из
/// неактивных (снимки штата) — очередь общая.
///
/// ── Рисование ──
///
/// Только надёжные примитивы: fill-rectangle, fill-circle,
/// draw_roundrect_ext. Никаких draw_primitive_* и draw_arc —
/// на телефоне они не рисуются.


// ═══════════════════════════════════════════════════════════
// 1. СОСТОЯНИЕ И РАСКЛАДКА
// ═══════════════════════════════════════════════════════════

/// @function hud_bell_step(_hud)
/// @description Вызывается из Step_1 obj_UI_HUD после раскладки
///              шестерёнки: считает координаты колокольчика,
///              наведение и раскладку панели.
function hud_bell_step(_hud, _mx, _my) {

    if (!instance_exists(_hud)) return;

    with (_hud) {

        // ── Ленивая инициализация (первый кадр). ──
        if (!variable_instance_exists(id, "bell_panel_open")) {
            bell_panel_open = false;
        }
        if (!variable_instance_exists(id, "bell_x1")) {
            bell_x1 = 0; bell_y1 = 0; bell_x2 = 0; bell_y2 = 0;
        }
        if (!variable_instance_exists(id, "bell_panel_x1")) {
            bell_panel_x1 = 0; bell_panel_y1 = 0;
            bell_panel_x2 = 0; bell_panel_y2 = 0;
        }
        if (!variable_instance_exists(id, "bell_rows")) {
            bell_rows = [];
        }

        // ── Кнопка: слева от шестерёнки, того же размера. ──
        var _w = gear_x2 - gear_x1;
        var _h = gear_y2 - gear_y1;

        bell_x1 = gear_x1 - btn_gap - _w;
        bell_y1 = gear_y1;
        bell_x2 = bell_x1 + _w;
        bell_y2 = bell_y1 + _h;

        hover_bell = point_in_rectangle(_mx, _my,
            bell_x1, bell_y1, bell_x2, bell_y2);

        // ── Панель: центр экрана, высота по числу просьб. ──
        staff_requests_init();

        var _count = array_length(global.staff_requests);
        var _gw = display_get_gui_width();
        var _gh = display_get_gui_height();

        var _panel_w = min(_gw - 60, 640);
        var _panel_h = min(_gh - 80, 150 + _count * 136);

        bell_panel_x1 = round((_gw - _panel_w) * 0.5);
        bell_panel_y1 = round((_gh - _panel_h) * 0.5);
        bell_panel_x2 = bell_panel_x1 + _panel_w;
        bell_panel_y2 = bell_panel_y1 + _panel_h;

        // Строки просьб: прямоугольники кнопок ДА / НЕТ.
        bell_rows = [];

        var _row_y = bell_panel_y1 + 96;

        for (var _i = 0; _i < _count; _i++) {
            var _yes_x1 = bell_panel_x2 - 232;
            var _yes_x2 = bell_panel_x2 - 128;
            var _no_x1  = bell_panel_x2 - 116;
            var _no_x2  = bell_panel_x2 - 24;
            var _btn_y1 = _row_y + 30;
            var _btn_y2 = _row_y + 92;

            array_push(bell_rows, {
                req_id: global.staff_requests[_i].id,
                yes_x1: _yes_x1, yes_y1: _btn_y1,
                yes_x2: _yes_x2, yes_y2: _btn_y2,
                no_x1: _no_x1, no_y1: _btn_y1,
                no_x2: _no_x2, no_y2: _btn_y2
            });

            _row_y += 136;
        }

        // ── Наведение внутри панели. ──
        hover_bell_close = false;
        hover_bell_yes = -1;
        hover_bell_no = -1;

        if (bell_panel_open) {
            hover_bell_close = point_in_rectangle(_mx, _my,
                bell_panel_x2 - 64, bell_panel_y1 + 16,
                bell_panel_x2 - 16, bell_panel_y1 + 64);

            for (var _r = 0; _r < array_length(bell_rows); _r++) {
                var _row = bell_rows[_r];

                if (point_in_rectangle(_mx, _my,
                    _row.yes_x1, _row.yes_y1, _row.yes_x2, _row.yes_y2
                )) {
                    hover_bell_yes = _r;
                }

                if (point_in_rectangle(_mx, _my,
                    _row.no_x1, _row.no_y1, _row.no_x2, _row.no_y2
                )) {
                    hover_bell_no = _r;
                }
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════
// 2. КЛИКИ
// ═══════════════════════════════════════════════════════════

/// @function hud_bell_click(_hud, _mx, _my)
/// @description Вызывается из общей цепочки кликов obj_UI_HUD,
///              когда тап пришёлся на колокольчик или на панель.
function hud_bell_click(_hud, _mx, _my) {

    if (!instance_exists(_hud)) return;

    staff_requests_init();

    with (_hud) {

        // ── Кнопка-колокольчик: открыть / закрыть. ──
        if (point_in_rectangle(_mx, _my, bell_x1, bell_y1, bell_x2, bell_y2)) {
            bell_panel_open = !bell_panel_open;

            // Открыли — всё прочитано, красный кружок гаснет.
            if (bell_panel_open) {
                for (var _i = 0; _i < array_length(global.staff_requests);
                    _i++
                ) {
                    global.staff_requests[_i].read = true;
                }
                global.staff_requests_unread = false;
            }

            return;
        }

        if (!bell_panel_open) return;

        // ── Крестик. ──
        if (point_in_rectangle(_mx, _my,
            bell_panel_x2 - 64, bell_panel_y1 + 16,
            bell_panel_x2 - 16, bell_panel_y1 + 64
        )) {
            bell_panel_open = false;
            return;
        }

        // ── ДА / НЕТ по строкам. ──
        for (var _r = 0; _r < array_length(bell_rows); _r++) {
            var _row = bell_rows[_r];

            if (point_in_rectangle(_mx, _my,
                _row.yes_x1, _row.yes_y1, _row.yes_x2, _row.yes_y2
            )) {
                staff_request_resolve(_row.req_id, true);
                return;
            }

            if (point_in_rectangle(_mx, _my,
                _row.no_x1, _row.no_y1, _row.no_x2, _row.no_y2
            )) {
                staff_request_resolve(_row.req_id, false);
                return;
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════
// 3. РИСОВАНИЕ
// ═══════════════════════════════════════════════════════════

/// Иконка колокольчика: купол-круг, юбка-трапеция из прямоугольников
/// и язычок. Только fill-примитивы.
function hud_draw_bell_icon(_cx, _cy, _r, _color) {

    draw_set_color(_color);

    // Купол.
    draw_circle(_cx, _cy - _r * 0.18, _r * 0.62, false);

    // Юбка: три горизонтальные полосы, расширяющиеся вниз —
    // силуэт колокола без draw_primitive.
    draw_rectangle(
        _cx - _r * 0.62, _cy + _r * 0.20,
        _cx + _r * 0.62, _cy + _r * 0.38, false
    );
    draw_rectangle(
        _cx - _r * 0.78, _cy + _r * 0.38,
        _cx + _r * 0.78, _cy + _r * 0.56, false
    );

    // Язычок.
    draw_circle(_cx, _cy + _r * 0.72, _r * 0.18, false);

    // Петелька сверху.
    draw_rectangle(
        _cx - _r * 0.08, _cy - _r * 0.92,
        _cx + _r * 0.08, _cy - _r * 0.62, false
    );
}


/// Кнопка-колокольчик в верхней панели + красный кружок непрочитанных.
function hud_draw_bell_button(_hud) {

    with (_hud) {

        var _unread = 0;
        staff_requests_init();

        for (var _i = 0; _i < array_length(global.staff_requests); _i++) {
            if (!global.staff_requests[_i].read) _unread++;
        }

        var _fill = bell_panel_open
            ? make_color_rgb(198, 168, 108)
            : (hover_bell
                ? make_color_rgb(248, 238, 220)
                : make_color_rgb(242, 232, 214));

        // Тень — как у шестерёнки.
        draw_set_alpha(0.25);
        draw_set_color(c_black);
        draw_roundrect_ext(bell_x1 + 2, bell_y1 + 3,
            bell_x2 + 2, bell_y2 + 3, 12, 12, false);
        draw_set_alpha(1);

        draw_set_color(_fill);
        draw_roundrect_ext(bell_x1, bell_y1, bell_x2, bell_y2,
            12, 12, false);

        draw_set_color(make_color_rgb(58, 39, 24));
        draw_roundrect_ext(bell_x1, bell_y1, bell_x2, bell_y2,
            12, 12, true);

        var _cx = (bell_x1 + bell_x2) * 0.5;
        var _cy = (bell_y1 + bell_y2) * 0.5;
        var _r = min(bell_x2 - bell_x1, bell_y2 - bell_y1) * 0.40;

        hud_draw_bell_icon(_cx, _cy, _r, make_color_rgb(58, 39, 24));

        // ── Красный кружок: сколько просьб не прочитано. ──
        if (_unread > 0) {
            var _bx = bell_x2 - 10;
            var _by = bell_y1 + 10;
            var _br = 15;

            draw_set_color(make_color_rgb(196, 42, 38));
            draw_circle(_bx, _by, _br, false);

            draw_set_color(c_white);
            ui_text_fit_center(_bx, _by,
                (_unread > 9) ? "9+" : string(_unread),
                _br * 2 - 6, UI_FS_SMALL);
        }

        draw_set_color(c_white);
        draw_set_alpha(1);

        // ── Панель просьб. ──
        if (!bell_panel_open) return;

        hud_menu_draw_shade();
        hud_menu_draw_frame(bell_panel_x1, bell_panel_y1,
            bell_panel_x2, bell_panel_y2, "ПРОСЬБЫ СОТРУДНИКОВ");

        // Крестик закрытия.
        draw_set_color(hover_bell_close
            ? make_color_rgb(226, 210, 184)
            : make_color_rgb(242, 232, 214));
        draw_roundrect_ext(bell_panel_x2 - 64, bell_panel_y1 + 16,
            bell_panel_x2 - 16, bell_panel_y1 + 64, 10, 10, false);
        draw_set_color(make_color_rgb(58, 39, 24));
        draw_roundrect_ext(bell_panel_x2 - 64, bell_panel_y1 + 16,
            bell_panel_x2 - 16, bell_panel_y1 + 64, 10, 10, true);
        ui_text_fit_center(
            (bell_panel_x2 - 40), bell_panel_y1 + 40, "X",
            40, UI_FS_BUTTON);

        var _count = array_length(global.staff_requests);

        // Пусто.
        if (_count <= 0) {
            draw_set_color(make_color_rgb(120, 96, 70));
            ui_text_fit_center(
                (bell_panel_x1 + bell_panel_x2) * 0.5,
                (bell_panel_y1 + bell_panel_y2) * 0.5,
                "Просьб нет. Сотрудники пока всем довольны.",
                (bell_panel_x2 - bell_panel_x1) - 80, UI_FS_ROW);
            return;
        }

        var _active_id = script_exists(asset_get_index("clinic_current_id"))
            ? clinic_current_id()
            : -999;

        var _text_x = bell_panel_x1 + 28;
        var _text_w = (bell_panel_x2 - 232) - _text_x - 12;

        for (var _i = 0; _i < _count; _i++) {
            var _req = global.staff_requests[_i];
            var _row_y = bell_panel_y1 + 96 + _i * 136;

            // Подложка строки.
            draw_set_color(make_color_rgb(234, 222, 198));
            draw_roundrect_ext(_text_x - 8, _row_y + 8,
                bell_panel_x2 - 16, _row_y + 120, 10, 10, false);

            // Клиника, если просьба не из текущей.
            var _where = "";
            if (_req.clinic_id != _active_id
                && variable_global_exists("clinics")
            ) {
                for (var _c = 0; _c < array_length(global.clinics);
                    _c++
                ) {
                    if (global.clinics[_c].id == _req.clinic_id) {
                        _where = " · " + string(global.clinics[_c].name);
                        break;
                    }
                }
            }

            // Кто и что просит.
            draw_set_color(make_color_rgb(50, 38, 28));
            ui_text_fit_center(
                (_text_x + bell_panel_x2 - 240) * 0.5, _row_y + 30,
                string(_req.staff_name) + _where
                    + " поднял навык «" + string(_req.skill_name)
                    + "» с " + string(_req.from_lvl)
                    + " по " + string(_req.to_lvl) + " лвл",
                _text_w + 100, UI_FS_ROW);

            ui_text_fit_center(
                (_text_x + bell_panel_x2 - 240) * 0.5, _row_y + 62,
                "просит поднять зарплату с " + string(_req.old_salary)
                    + " до " + string(_req.old_salary + _req.amount),
                _text_w + 100, UI_FS_ROW);

            // Сколько дней осталось на ответ.
            var _left = max(0, 3 - (real(global.game_day) - _req.day));
            draw_set_color(make_color_rgb(140, 110, 80));
            ui_text_fit_center(
                (_text_x + bell_panel_x2 - 240) * 0.5, _row_y + 92,
                "на ответ " + string(_left) + " дн.",
                _text_w + 100, UI_FS_SMALL);

            // ДА / НЕТ.
            var _row = bell_rows[_i];

            hud_menu_draw_button(_row.yes_x1, _row.yes_y1,
                _row.yes_x2, _row.yes_y2, "ДА",
                hover_bell_yes == _i, true);

            hud_menu_draw_button(_row.no_x1, _row.no_y1,
                _row.no_x2, _row.no_y2, "НЕТ",
                hover_bell_no == _i, true);
        }

        draw_set_color(c_white);
    }
}
