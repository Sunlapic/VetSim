/// clinic_upgrade_system.gml
/// @description Баллы клиники и дерево развития: слоты найма, библиотека, спортзал, аптека.
/// Пакет №71. Пакет №121: колонки РАЗВИТИЯ на матовом стекле.
/// Пакет №122: подложка-кнопка под счётчиком баллов.


// ═══════════════════════════════════════════════════════════════
// 1. ИНИЦИАЛИЗАЦИЯ И БАЛЛЫ
// Баллы начисляются за полное выздоровление пациента (100% состояния).
// ═══════════════════════════════════════════════════════════════

function clinic_upgrade_init() {
    if (!variable_global_exists("clinic_points")) {
        global.clinic_points = 0;
    }

    if (!variable_global_exists("clinic_upgrades")) {
        global.clinic_upgrades = {};
    }

    var _upgrade_keys = ["hire_slot", "library", "gym", "pharmacy"];

    for (var _index = 0; _index < array_length(_upgrade_keys); _index++) {
        if (!variable_struct_exists(global.clinic_upgrades, _upgrade_keys[_index])) {
            variable_struct_set(
                global.clinic_upgrades,
                _upgrade_keys[_index],
                0
            );
        }
    }
}

function clinic_upgrade_max_level() {
    return 5;
}

// Пакет №71 (правка): у каждого улучшения свой потолок.
// «Слот найма» прокачивается до 9 уровня (1 + 9 = 10 сотрудников максимум).
function clinic_upgrade_max_level_for(_upgrade_id) {
    if (string(_upgrade_id) == "hire_slot") return 9;

    return clinic_upgrade_max_level();
}

function clinic_get_points() {
    clinic_upgrade_init();
    return max(0, round(global.clinic_points));
}

function clinic_points_add(_amount) {
    clinic_upgrade_init();

    var _add = max(0, round(_amount));

    if (_add <= 0) return;

    global.clinic_points += _add;

    if (instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);

        if (
            instance_exists(_hud)
            && variable_instance_exists(_hud, "show_notice")
        ) {
            with (_hud) {
                show_notice(
                    "БАЛЛЫ +" + string(_add),
                    "Полное выздоровление! Всего баллов: "
                        + string(global.clinic_points),
                    max(1, game_get_speed(gamespeed_fps)) * 2
                );
            }
        }
    }
}

function clinic_points_spend(_amount) {
    clinic_upgrade_init();

    var _spend = max(0, round(_amount));

    if (global.clinic_points < _spend) return false;

    global.clinic_points -= _spend;
    return true;
}


// ═══════════════════════════════════════════════════════════════
// 2. УРОВНИ И ЦЕНЫ УЛУЧШЕНИЙ
// ═══════════════════════════════════════════════════════════════

function clinic_upgrade_level(_upgrade_id) {
    clinic_upgrade_init();

    var _key = string(_upgrade_id);

    if (variable_struct_exists(global.clinic_upgrades, _key)) {
        return clamp(
            round(variable_struct_get(global.clinic_upgrades, _key)),
            0,
            clinic_upgrade_max_level_for(_key)
        );
    }

    return 0;
}

function clinic_upgrade_is_maxed(_upgrade_id) {
    return clinic_upgrade_level(_upgrade_id)
        >= clinic_upgrade_max_level_for(_upgrade_id);
}

function clinic_upgrade_cost(_upgrade_id) {
    // Цена перехода на следующий уровень.
    var _next = clinic_upgrade_level(_upgrade_id) + 1;

    switch (string(_upgrade_id)) {
        case "hire_slot":
            switch (_next) {
                case 1: return 5;
                case 2: return 8;
                case 3: return 12;
                case 4: return 18;
                case 5: return 26;
                case 6: return 34;
                case 7: return 44;
                case 8: return 56;
                case 9: return 70;
            }
        break;

        case "library":
            switch (_next) {
                case 1: return 4;
                case 2: return 8;
                case 3: return 14;
                case 4: return 22;
                case 5: return 32;
            }
        break;

        case "gym":
            switch (_next) {
                case 1: return 4;
                case 2: return 8;
                case 3: return 14;
                case 4: return 22;
                case 5: return 32;
            }
        break;

        case "pharmacy":
            switch (_next) {
                case 1: return 3;
                case 2: return 6;
                case 3: return 10;
                case 4: return 16;
                case 5: return 24;
            }
        break;
    }

    return 99999;
}

function clinic_upgrade_apply(_upgrade_id) {
    clinic_upgrade_init();

    if (clinic_upgrade_is_maxed(_upgrade_id)) return false;

    var _cost = clinic_upgrade_cost(_upgrade_id);

    if (!clinic_points_spend(_cost)) {
        if (instance_exists(obj_UI_HUD)) {
            var _hud = instance_find(obj_UI_HUD, 0);

            if (
                instance_exists(_hud)
                && variable_instance_exists(_hud, "show_notice")
            ) {
                with (_hud) {
                    show_notice(
                        "МАЛО БАЛЛОВ",
                        "Нужно " + string(_cost) + " баллов.",
                        max(1, game_get_speed(gamespeed_fps)) * 2
                    );
                }
            }
        }

        return false;
    }

    var _key = string(_upgrade_id);
    var _new_level = clinic_upgrade_level(_key) + 1;

    variable_struct_set(global.clinic_upgrades, _key, _new_level);

    if (instance_exists(obj_UI_HUD)) {
        var _hud_ok = instance_find(obj_UI_HUD, 0);

        if (
            instance_exists(_hud_ok)
            && variable_instance_exists(_hud_ok, "show_notice")
        ) {
            with (_hud_ok) {
                show_notice(
                    clinic_upgrade_name(_key),
                    "Уровень " + string(_new_level)
                        + " из " + string(clinic_upgrade_max_level()),
                    max(1, game_get_speed(gamespeed_fps)) * 2
                );
            }
        }
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. ЭФФЕКТЫ УЛУЧШЕНИЙ
// ═══════════════════════════════════════════════════════════════

function clinic_get_hire_slots() {
    // Стартовый лимит — 1 сотрудник (не считая главного игрока).
    // Максимум: 1 + 9 = 10 сотрудников.
    return 1 + clinic_upgrade_level("hire_slot");
}

function clinic_get_library_bonus() {
    // +1 Терапия всем врачам (влияет на ручной приём игрока:
    // меньше ложных вариантов в карточке).
    return clinic_upgrade_level("library");
}

function clinic_get_gym_bonus_percent() {
    // +10% к скорости ходьбы персонала за уровень.
    return clinic_upgrade_level("gym") * 10;
}

function clinic_get_pharmacy_discount_percent() {
    // −5% на закупку препаратов за уровень.
    return clinic_upgrade_level("pharmacy") * 5;
}

function clinic_staff_count_for_slots() {
    return instance_number(obj_staff_doctor)
        + instance_number(obj_staff_admin)
        + instance_number(obj_staff_assistant);
}

function clinic_hire_slot_available() {
    return clinic_staff_count_for_slots() < clinic_get_hire_slots();
}


// ═══════════════════════════════════════════════════════════════
// 4. ТЕКСТЫ ДЛЯ ПАНЕЛИ
// ═══════════════════════════════════════════════════════════════

function clinic_upgrade_name(_upgrade_id) {
    switch (string(_upgrade_id)) {
        case "hire_slot": return "Слот найма";
        case "library": return "Библиотека";
        case "gym": return "Спортзал";
        case "pharmacy": return "Аптека";
    }

    return "Улучшение";
}

function clinic_upgrade_effect_now(_upgrade_id) {
    switch (string(_upgrade_id)) {
        case "hire_slot":
            return "Слотов для сотрудников: " + string(clinic_get_hire_slots());
        case "library":
            return "+" + string(clinic_get_library_bonus())
                + " Терапия всем врачам";
        case "gym":
            return "+" + string(clinic_get_gym_bonus_percent())
                + "% к скорости персонала";
        case "pharmacy":
            return "Скидка на закупку: -"
                + string(clinic_get_pharmacy_discount_percent())
                + "%";
    }

    return "";
}

function clinic_upgrade_effect_next(_upgrade_id) {
    if (clinic_upgrade_is_maxed(_upgrade_id)) {
        return "Максимальный уровень";
    }

    var _cost = clinic_upgrade_cost(_upgrade_id);

    switch (string(_upgrade_id)) {
        case "hire_slot":
            return "След.: " + string(clinic_get_hire_slots() + 1)
                + " слотов за " + string(_cost) + " баллов";
        case "library":
            return "След.: +" + string(clinic_get_library_bonus() + 1)
                + " Терапия за " + string(_cost) + " баллов";
        case "gym":
            return "След.: +" + string(clinic_get_gym_bonus_percent() + 10)
                + "% за " + string(_cost) + " баллов";
        case "pharmacy":
            return "След.: -" + string(clinic_get_pharmacy_discount_percent() + 5)
                + "% за " + string(_cost) + " баллов";
    }

    return "";
}


// ═══════════════════════════════════════════════════════════════
// 5. ПАНЕЛЬ «РАЗВИТИЕ» (вкладка КЛИНИКА → РАЗВИТИЕ)
// ═══════════════════════════════════════════════════════════════

function hud_draw_clinic_upgrades(_hud) {
    if (!instance_exists(_hud)) return;

    with (_hud) {
        // Состояние прокрутки (переживает кадры на инстансе HUD).
        if (!variable_instance_exists(id, "upgrade_scroll")) upgrade_scroll = 0;
        if (!variable_instance_exists(id, "upgrade_touch_active")) upgrade_touch_active = false;
        if (!variable_instance_exists(id, "upgrade_touch_last_y")) upgrade_touch_last_y = 0;
        if (!variable_instance_exists(id, "upgrade_touch_accum")) upgrade_touch_accum = 0;

        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);

        var _wood_light = make_color_rgb(150, 107, 73);
        var _paper_2 = make_color_rgb(232, 220, 198);
        var _line_dark = make_color_rgb(58, 39, 24);
        var _text_dark = make_color_rgb(50, 38, 28);
        var _text_soft = make_color_rgb(84, 68, 54);
        var _accent_green = make_color_rgb(62, 112, 74);
        var _gold = make_color_rgb(212, 160, 40);

        var _panel_x1 = main_panel_x1 + 24;
        var _panel_y1 = main_panel_y1 + 60;
        var _panel_x2 = main_panel_x2 - 24;
        var _panel_y2 = main_panel_y2 - 18;

        // ── Счётчик баллов (заголовок не рисуем: надпись уже есть на кнопке «РАЗВИТИЕ»)
        // Пакет №122: подложка-кнопка, чтобы золотые баллы читались на стекле.
        var _pts_label = "БАЛЛЫ  " + string(clinic_get_points());
        var _pts_scale = 1.3;
        var _pts_pad = 14;
        var _pts_w = string_width(_pts_label) * _pts_scale;
        var _pts_x2 = _panel_x2;
        var _pts_x1 = _pts_x2 - _pts_w - _pts_pad * 2;
        var _pts_y1 = main_panel_y1 + 17;
        var _pts_y2 = _pts_y1 + 30;

        draw_set_alpha(0.16);
        draw_set_color(c_black);
        draw_roundrect_ext(
            _pts_x1 + 2, _pts_y1 + 3,
            _pts_x2 + 2, _pts_y2 + 3,
            9, 9, false
        );
        draw_set_alpha(1);

        draw_set_color(make_color_rgb(74, 49, 31));
        draw_roundrect_ext(_pts_x1, _pts_y1, _pts_x2, _pts_y2, 9, 9, false);
        draw_set_color(make_color_rgb(150, 107, 73));
        draw_roundrect_ext(
            _pts_x1 + 2, _pts_y1 + 2,
            _pts_x2 - 2, _pts_y2 - 2,
            7, 7, false
        );
        draw_set_color(_gold);
        draw_roundrect_ext(_pts_x1, _pts_y1, _pts_x2, _pts_y2, 9, 9, true);

        draw_set_halign(fa_right);
        draw_set_valign(fa_middle);
        draw_set_color(_gold);
        draw_text_transformed(
            _pts_x2 - _pts_pad,
            (_pts_y1 + _pts_y2) * 0.5 + 1,
            _pts_label,
            _pts_scale,
            _pts_scale,
            0
        );
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

        // ── Две РАВНЫЕ колонки: слева деньги, справа баллы ──
        var _left_x1 = _panel_x1;
        var _left_x2 = _left_x1 + ((_panel_x2 - _panel_x1) - 16) * 0.5;
        var _right_x1 = _left_x2 + 16;
        var _right_x2 = _panel_x2;

        // Пакет №121: колонки РАЗВИТИЯ на матовом стекле (было — непрозрачная бумага).
        hud_frosted_fill(_left_x1, _panel_y1, _left_x2, _panel_y2, 10);
        hud_frosted_fill(_right_x1, _panel_y1, _right_x2, _panel_y2, 10);
        draw_set_color(_paper_2);
        draw_roundrect_ext(_left_x1, _panel_y1, _left_x2, _panel_y2, 10, 10, true);
        draw_roundrect_ext(_right_x1, _panel_y1, _right_x2, _panel_y2, 10, 10, true);

        // ── Левая колонка: ПОМЕЩЕНИЯ (деньги) — пакет №72 ──
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_text_dark);
        draw_text_transformed(_left_x1 + 12, _panel_y1 + 10, "ПОМЕЩЕНИЯ (деньги)", 1.3, 1.3, 0);

        // Пакет №72: карточки кабинетов с покупкой за деньги.
        hud_draw_rooms_column(id, _left_x1, _panel_y1, _left_x2, _panel_y2, _mx, _my);

        // ── Правая колонка: УЛУЧШЕНИЯ (баллы) ──
        draw_set_color(_text_dark);
        draw_text_transformed(_right_x1 + 12, _panel_y1 + 10, "УЛУЧШЕНИЯ (баллы)", 1.3, 1.3, 0);

        var _upg_ids = ["hire_slot", "library", "gym", "pharmacy"];
        var _row_h = 184;
        var _list_y1 = _panel_y1 + 46;
        var _list_y2 = _panel_y2 - 8;
        var _visible = max(1, floor((_list_y2 - _list_y1) / _row_h));
        var _max_scroll = max(0, array_length(_upg_ids) - _visible);
        upgrade_scroll = clamp(upgrade_scroll, 0, _max_scroll);

        // Прокрутка: колесо + touch.
        var _in_rect = point_in_rectangle(
            _mx, _my,
            _right_x1, _panel_y1,
            _right_x2, _panel_y2
        );

        if (_in_rect) {
            if (mouse_wheel_down()) {
                upgrade_scroll = min(_max_scroll, upgrade_scroll + 1);
            }
            if (mouse_wheel_up()) {
                upgrade_scroll = max(0, upgrade_scroll - 1);
            }
        }

        var _pressed = mouse_check_button_pressed(mb_left)
            || device_mouse_check_button_pressed(0, mb_left);
        var _down = mouse_check_button(mb_left)
            || device_mouse_check_button(0, mb_left);
        var _released = mouse_check_button_released(mb_left)
            || device_mouse_check_button_released(0, mb_left);

        if (_pressed && _in_rect) {
            upgrade_touch_active = true;
            upgrade_touch_last_y = _my;
            upgrade_touch_accum = 0;
        }

        if (upgrade_touch_active) {
            if (_down) {
                var _delta = _my - upgrade_touch_last_y;
                upgrade_touch_accum += _delta;

                while (upgrade_touch_accum <= -30) {
                    upgrade_scroll = min(_max_scroll, upgrade_scroll + 1);
                    upgrade_touch_accum += 30;
                }

                while (upgrade_touch_accum >= 30) {
                    upgrade_scroll = max(0, upgrade_scroll - 1);
                    upgrade_touch_accum -= 30;
                }

                upgrade_touch_last_y = _my;
            }

            if (_released || !_down) {
                upgrade_touch_active = false;
                upgrade_touch_accum = 0;
            }
        }

        // ── Карточки улучшений ──
        for (var _vi = 0; _vi < _visible; _vi++) {
            var _idx = upgrade_scroll + _vi;
            if (_idx >= array_length(_upg_ids)) break;

            var _upg_id = _upg_ids[_idx];
            var _level = clinic_upgrade_level(_upg_id);
            var _maxed = clinic_upgrade_is_maxed(_upg_id);
            var _cost = _maxed ? 0 : clinic_upgrade_cost(_upg_id);
            var _can_afford = !_maxed
                && clinic_get_points() >= _cost;

            var _cy1 = _list_y1 + _vi * _row_h;
            var _cy2 = _cy1 + (_row_h - 8);
            var _cx1 = _right_x1 + 10;
            var _cx2 = _right_x2 - 10;

            draw_set_color(make_color_rgb(246, 240, 228));
            draw_roundrect_ext(_cx1, _cy1, _cx2, _cy2, 8, 8, false);
            draw_set_color(make_color_rgb(200, 188, 170));
            draw_roundrect_ext(_cx1, _cy1, _cx2, _cy2, 8, 8, true);

            // Название.
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_set_color(_text_dark);
            draw_text_transformed(
                _cx1 + 12,
                _cy1 + 10,
                clinic_upgrade_name(_upg_id),
                1.35,
                1.35,
                0
            );

            // Точки уровня ●●●○○ (у «Слота найма» их 9).
            var _dots_x = _cx1 + 14;
            var _dots_y = _cy1 + 46;
            var _max_level = clinic_upgrade_max_level_for(_upg_id);
            var _dot_gap = (_max_level > 5) ? 20 : 26;
            var _dot_r = (_max_level > 5) ? 6 : 7;

            for (var _dot = 0; _dot < _max_level; _dot++) {
                var _dot_x = _dots_x + _dot * _dot_gap + _dot_r;

                if (_dot < _level) {
                    draw_set_color(_accent_green);
                    draw_circle(_dot_x, _dots_y, _dot_r, false);
                } else {
                    draw_set_color(make_color_rgb(190, 178, 160));
                    draw_circle(_dot_x, _dots_y, _dot_r, true);
                }
            }

            // Текущий и следующий эффект.
            draw_set_color(_text_soft);
            draw_text_transformed(_cx1 + 12, _cy1 + 66, clinic_upgrade_effect_now(_upg_id), 1.15, 1.15, 0);
            draw_set_color(_text_soft);
            draw_text_transformed(_cx1 + 12, _cy1 + 90, clinic_upgrade_effect_next(_upg_id), 1.15, 1.15, 0);

            // Кнопка (слева, внизу карточки).
            var _btn_w = 260;
            var _btn_h = 52;
            var _btn_x1 = _cx1 + 12;
            var _btn_x2 = _btn_x1 + _btn_w;
            var _btn_y1 = _cy1 + 116;
            var _btn_y2 = _btn_y1 + _btn_h;
            var _btn_hover = point_in_rectangle(
                _mx, _my,
                _btn_x1, _btn_y1,
                _btn_x2, _btn_y2
            );

            var _btn_label = _maxed
                ? "МАКС"
                : ("УЛУЧШИТЬ: " + string(_cost) + " БАЛ.");
            var _btn_fill = _maxed
                ? make_color_rgb(205, 201, 194)
                : (_can_afford
                    ? (_btn_hover
                        ? make_color_rgb(220, 235, 208)
                        : make_color_rgb(205, 224, 193))
                    : (_btn_hover
                        ? make_color_rgb(236, 226, 214)
                        : make_color_rgb(226, 216, 199)));
            var _btn_line = _maxed
                ? make_color_rgb(125, 125, 118)
                : (_can_afford
                    ? make_color_rgb(104, 137, 91)
                    : make_color_rgb(150, 132, 112));
            var _btn_text = _maxed
                ? make_color_rgb(115, 112, 108)
                : (_can_afford
                    ? make_color_rgb(45, 60, 40)
                    : make_color_rgb(148, 74, 64));

            draw_set_color(_btn_fill);
            draw_roundrect_ext(_btn_x1, _btn_y1, _btn_x2, _btn_y2, 7, 7, false);
            draw_set_color(_btn_line);
            draw_roundrect_ext(_btn_x1, _btn_y1, _btn_x2, _btn_y2, 7, 7, true);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(_btn_text);
            draw_text_transformed(
                (_btn_x1 + _btn_x2) * 0.5,
                (_btn_y1 + _btn_y2) * 0.5,
                _btn_label,
                1.3,
                1.3,
                0
            );
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);

            if (
                _btn_hover
                && tablet_click_lock <= 0
                && mouse_check_button_pressed(mb_left)
            ) {
                tablet_click_lock = 5;
                clinic_upgrade_apply(_upg_id);
            }
        }

        // ── Бегунок списка улучшений ──
        if (_max_scroll > 0) {
            var _track_x = _right_x2 - 8;
            var _track_h = max(1, _list_y2 - _list_y1);
            var _thumb_h = max(
                24,
                _track_h * (_visible / array_length(_upg_ids))
            );
            var _travel = max(1, _track_h - _thumb_h);
            var _thumb_y = _list_y1 + _travel * (upgrade_scroll / _max_scroll);

            draw_set_color(make_color_rgb(212, 200, 182));
            draw_roundrect_ext(_track_x, _list_y1, _track_x + 6, _list_y2, 3, 3, false);
            draw_set_color(_wood_light);
            draw_roundrect_ext(_track_x, _thumb_y, _track_x + 6, _thumb_y + _thumb_h, 3, 3, false);
            draw_set_color(_line_dark);
            draw_roundrect_ext(_track_x, _thumb_y, _track_x + 6, _thumb_y + _thumb_h, 3, 3, true);
        }
    }
}
