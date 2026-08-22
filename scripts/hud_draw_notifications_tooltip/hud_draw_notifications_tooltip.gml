/// hud_draw_notifications_tooltip.gml
/// @description Стопка HUD-уведомлений (пакет №102: падают в нижний левый угол) и подсказка.
/// Пакет №119: уведомления на матовом стекле.

function hud_draw_notifications(_hud) {
    if (!instance_exists(_hud)) return;
    if (!variable_instance_exists(_hud, "notice_stack")) return;
    if (!is_array(_hud.notice_stack)) return;
    if (array_length(_hud.notice_stack) == 0) return;

    with (_hud) {
        // Безопасная инициализация настроек (на случай старого Create).
        if (!variable_instance_exists(id, "notice_max")) notice_max = 3;
        if (!variable_instance_exists(id, "notice_gap")) notice_gap = 8;
        if (!variable_instance_exists(id, "notice_fall_speed")) notice_fall_speed = 16;
        if (!variable_instance_exists(id, "notice_fade_frames")) notice_fade_frames = 15;

        var _gui_w = display_get_gui_width();
        var _stack_bottom = bottombar_y1 - 12;   // низ стопки: над нижней панелью (левый нижний угол)

        // ── 1. Таймеры и размеры ──
        var _n = array_length(notice_stack);
        for (var _i = 0; _i < _n; _i++) {
            var _nt = notice_stack[_i];

            if (_nt.state == "falling" || _nt.state == "idle") {
                if (_nt.timer > 0) _nt.timer -= 1;
                if (_nt.timer <= 0) _nt.state = "fading";
            }

            if (_nt.h <= 0) {
                var _title = string_upper(_nt.title);
                _nt.measure = hud_measure_box(
                    _title,
                    _nt.text,
                    280,
                    520,
                    34,
                    18,
                    16,
                    16,
                    6
                );
                _nt.w = _nt.measure.w;
                _nt.h = _nt.measure.h;
            }
        }

        // ── 2. Раскладка: стопка растёт ВВЕРХ от нижнего левого угла ──
        // _live[0] = самое старое → нижний слот (у угла), новое — выше.
        var _live = [];
        for (var _i = 0; _i < _n; _i++) {
            if (notice_stack[_i].state != "fading") {
                array_push(_live, notice_stack[_i]);
            }
        }

        var _lc = array_length(_live);

        // Страховка: лишних живых (самых старых) отправляем в затухание.
        var _overflow = _lc - notice_max;
        if (_overflow < 0) _overflow = 0;
        if (_overflow > 0) {
            for (var _s = 0; _s < _overflow; _s++) {
                _live[_s].state = "fading";
            }
        }

        var _slot_bottom = _stack_bottom;
        for (var _s = _overflow; _s < _lc; _s++) {
            var _lv = _live[_s];
            _lv.target_y = _slot_bottom - (_lv.h > 0 ? _lv.h : 60);
            _slot_bottom = _lv.target_y - notice_gap;
        }

        // ── 3. Падение и затухание ──
        for (var _i = 0; _i < _n; _i++) {
            var _nt = notice_stack[_i];

            if (_nt.state == "falling" || _nt.state == "idle") {
                // Плавное падение вниз с постоянной скоростью (px/кадр).
                if (_nt.y < _nt.target_y) {
                    _nt.y = min(_nt.target_y, _nt.y + notice_fall_speed);
                }
                else if (_nt.y > _nt.target_y) {
                    _nt.y = max(_nt.target_y, _nt.y - notice_fall_speed);
                }
                if (_nt.y == _nt.target_y) {
                    _nt.state = "idle";
                }
            }

            if (_nt.state == "fading") {
                _nt.alpha -= 1 / max(1, notice_fade_frames);
                if (_nt.alpha <= 0) _nt.alpha = 0;
            }
        }

        // ── 4. Удаляем полностью прозрачные ──
        for (var _i = _n - 1; _i >= 0; _i--) {
            if (
                notice_stack[_i].state == "fading"
                && notice_stack[_i].alpha <= 0
            ) {
                array_delete(notice_stack, _i, 1);
            }
        }

        // ── 5. Отрисовка ──
        var _wood_dark   = make_color_rgb(74, 49, 31);
        var _wood_mid    = make_color_rgb(114, 77, 50);
        var _wood_light  = make_color_rgb(150, 107, 73);
        var _paper       = make_color_rgb(242, 232, 214);
        var _line_dark   = make_color_rgb(58, 39, 24);
        var _text_dark   = make_color_rgb(50, 38, 28);
        var _text_soft   = make_color_rgb(84, 68, 54);
        var _accent_blue = make_color_rgb(72, 112, 145);

        var _n2 = array_length(notice_stack);
        for (var _i = 0; _i < _n2; _i++) {
            var _nt = notice_stack[_i];

            var _w = (_nt.w > 0) ? _nt.w : 280;
            var _h = (_nt.h > 0) ? _nt.h : 60;

            var _x1 = hud_margin;
            if (_x1 + _w > _gui_w - 12) {
                _x1 = max(4, _gui_w - 12 - _w);
            }
            var _y1 = _nt.y;
            var _x2 = _x1 + _w;
            var _y2 = _y1 + _h;

            // Хит-зона для клика (обрабатывается в Begin Step).
            _nt.x1 = _x1;
            _nt.y1 = _y1;
            _nt.x2 = _x2;
            _nt.y2 = _y2;

            var _alpha = clamp(_nt.alpha, 0, 1);
            var _title = string_upper(_nt.title);
            var _m = _nt.measure;

            draw_set_alpha(0.18 * _alpha);
            draw_set_color(c_black);
            draw_roundrect_ext(
                _x1 + 4, _y1 + 5,
                _x2 + 4, _y2 + 5,
                14, 14, false
            );
            draw_set_alpha(1);

            // Пакет №119: уведомление — матовое стекло + деревянная кромка
            // (чуть плотнее, чтобы текст оставался читаемым).
            hud_frosted_fill(_x1, _y1, _x2, _y2, 14, 0.62 * _alpha, 0.22 * _alpha);

            draw_set_color(_wood_dark);
            draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, true);
            draw_set_color(_wood_light);
            draw_roundrect_ext(
                _x1 + 3, _y1 + 3,
                _x2 - 3, _y2 - 3,
                11, 11, true
            );

            draw_set_alpha(_alpha);
            draw_set_color(_accent_blue);
            draw_roundrect_ext(
                _x1 + 14, _y1 + 14,
                _x1 + 22, _y2 - 14,
                5, 5, false
            );
            draw_set_alpha(1);

            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            // Пакет №175: заголовок и текст уведомления крупным шрифтом.
            draw_set_color(_text_dark);
            ui_text_fit_left(_x1 + 36, _y1 + 16, _title, _m.wrap_w, UI_FS_HEADER);

            if (is_struct(_m)) {
                draw_set_color(_text_soft);
                draw_text_ext_transformed(
                    _x1 + 36,
                    _y1 + 16 + _m.title_h + 8,
                    _nt.text,
                    _m.text_sep / UI_FS_ROW,
                    _m.wrap_w / UI_FS_ROW,
                    UI_FS_ROW,
                    UI_FS_ROW,
                    0
                );
            }

            draw_set_alpha(1);
        }
    }
}

function hud_draw_hover_tooltip(_hud) {
    if (!instance_exists(_hud)) return;
    if (world_clicks_blocked()) return;
    if (!instance_exists(global.hover_target)) return;
    if (instance_exists(obj_UI_Tablet) && obj_UI_Tablet.visible) return;

    var _target = global.hover_target;
    var _name = variable_instance_exists(_target, "char_name")
        ? string(_target.char_name)
        : (variable_instance_exists(_target, "display_name")
            ? string(_target.display_name)
            : object_get_name(_target.object_index));
    var _subtitle = "";

    if (variable_instance_exists(_target, "is_candidate") && _target.is_candidate) {
        switch (_target.role) {
            case "doctor": _subtitle = "КАНДИДАТ - ВРАЧ"; break;
            case "assistant": _subtitle = "КАНДИДАТ - АССИСТЕНТ"; break;
            case "admin": _subtitle = "КАНДИДАТ - АДМИНИСТРАТОР"; break;
            default: _subtitle = "КАНДИДАТ";
        }
    }
    else if (variable_instance_exists(_target, "role")) {
        switch (_target.role) {
            case "doctor":
                // Пакет №187: на табличке профессия, а не название навыка
                // («АНЕСТЕЗИОЛОГ», а не «АНЕСТЕЗИОЛОГИЯ»).
                _subtitle = variable_instance_exists(_target, "specialty_title")
                    ? doctor_specialty_profession(_target.specialty_title)
                    : "ВРАЧ";
            break;
            case "assistant": _subtitle = "АССИСТЕНТ"; break;
            case "admin": _subtitle = "АДМИНИСТРАТОР"; break;
            case "owner": _subtitle = "ВЛАДЕЛЕЦ"; break;
            case "animal":
                _subtitle = variable_instance_exists(_target, "breed")
                    ? string(_target.breed)
                    : "ПАЦИЕНТ";
            break;
            default: _subtitle = string_upper(string(_target.role));
        }
    }

    var _title = string_upper(_name);
    var _measure = hud_measure_box(_title, _subtitle, 170, 520, 16, 16, 10, 10, 4);
    var _x = device_mouse_x_to_gui(0) + 18;
    var _y = device_mouse_y_to_gui(0) + 20;
    var _gui_w = display_get_gui_width();
    var _gui_h = display_get_gui_height();

    if (_x + _measure.w > _gui_w - 12) _x = _gui_w - 12 - _measure.w;
    if (_y + _measure.h > _gui_h - 12) _y = _gui_h - 12 - _measure.h;

    var _wood_dark = make_color_rgb(74, 49, 31);
    var _wood_light = make_color_rgb(150, 107, 73);
    var _paper = make_color_rgb(242, 232, 214);
    var _line_dark = make_color_rgb(58, 39, 24);

    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(_x + 3, _y + 4, _x + _measure.w + 3, _y + _measure.h + 4, 10, 10, false);
    draw_set_alpha(1);
    draw_set_color(_wood_dark);
    draw_roundrect_ext(_x, _y, _x + _measure.w, _y + _measure.h, 10, 10, false);
    draw_set_color(_wood_light);
    draw_roundrect_ext(_x + 3, _y + 3, _x + _measure.w - 3, _y + _measure.h - 3, 8, 8, false);
    draw_set_color(_paper);
    draw_roundrect_ext(_x + 7, _y + 7, _x + _measure.w - 7, _y + _measure.h - 7, 7, 7, false);
    draw_set_color(_line_dark);
    draw_roundrect_ext(_x, _y, _x + _measure.w, _y + _measure.h, 10, 10, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(50, 38, 28));
    ui_text_fit_left(_x + 16, _y + 10, _title, _measure.wrap_w, UI_FS_HEADER);

    if (_subtitle != "") {
        draw_set_color(make_color_rgb(84, 68, 54));
        draw_text_ext_transformed(
            _x + 16,
            _y + 10 + _measure.title_h + 6,
            _subtitle,
            _measure.text_sep / UI_FS_ROW,
            _measure.wrap_w / UI_FS_ROW,
            UI_FS_ROW,
            UI_FS_ROW,
            0
        );
    }
}
