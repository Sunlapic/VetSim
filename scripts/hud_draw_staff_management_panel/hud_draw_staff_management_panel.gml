/// hud_draw_staff_management_panel.gml
/// @description Группированный список персонала и полная карточка сотрудника внутри HUD.
/// Пакет №120: панель и колонки на матовом стекле (дерево только рамкой).


// ═══════════════════════════════════════════════════════════════
// 1. БАЗОВЫЕ ЭЛЕМЕНТЫ
// ═══════════════════════════════════════════════════════════════

function hud_staff_manage_draw_outer_panel(
    _x1,
    _y1,
    _x2,
    _y2
) {
    // Пакет №120: матовое стекло + деревянная рамка по краю.
    hud_draw_frosted_panel(_x1, _y1, _x2, _y2, 12);
}

function hud_staff_manage_draw_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _text,
    _enabled,
    _hovered,
    _style
) {
    var _wood_dark = make_color_rgb(74, 49, 31);
    var _line = make_color_rgb(150, 132, 112);
    var _fill = make_color_rgb(225, 216, 199);
    var _text_color = make_color_rgb(105, 100, 92);

    if (_enabled) {
        switch (_style) {
            case "red":
                _line = make_color_rgb(148, 82, 72);
                _fill = _hovered
                    ? make_color_rgb(242, 211, 203)
                    : make_color_rgb(229, 194, 185);
                _text_color = make_color_rgb(105, 42, 38);
            break;

            case "green":
                _line = make_color_rgb(104, 137, 91);
                _fill = _hovered
                    ? make_color_rgb(220, 235, 208)
                    : make_color_rgb(205, 224, 193);
                _text_color = make_color_rgb(45, 70, 40);
            break;

            default:
                _line = make_color_rgb(104, 135, 160);
                _fill = _hovered
                    ? make_color_rgb(224, 238, 248)
                    : make_color_rgb(210, 228, 242);
                _text_color = make_color_rgb(45, 65, 82);
        }
    }

    draw_set_alpha(0.16);
    draw_set_color(c_black);
    draw_roundrect_ext(
        _x1 + 2,
        _y1 + 3,
        _x2 + 2,
        _y2 + 3,
        9,
        9,
        false
    );
    draw_set_alpha(1);

    draw_set_color(_wood_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 9, 9, false);
    draw_set_color(_line);
    draw_roundrect_ext(
        _x1 + 2,
        _y1 + 2,
        _x2 - 2,
        _y2 - 2,
        7,
        7,
        false
    );
    draw_set_color(_fill);
    draw_roundrect_ext(
        _x1 + 5,
        _y1 + 5,
        _x2 - 5,
        _y2 - 5,
        5,
        5,
        false
    );
    draw_set_color(_wood_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 9, 9, true);

    // Пакет №175: крупный текст с автоподгонкой под ширину кнопки.
    draw_set_color(_text_color);
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5,
        _text,
        (_x2 - _x1) - 20,
        UI_FS_BUTTON
    );
}

function hud_staff_manage_pointer_pressed() {
    return mouse_check_button_pressed(mb_left)
        || device_mouse_check_button_pressed(0, mb_left);
}

function hud_staff_manage_pointer_down() {
    return mouse_check_button(mb_left)
        || device_mouse_check_button(0, mb_left);
}

function hud_staff_manage_pointer_released() {
    return mouse_check_button_released(mb_left)
        || device_mouse_check_button_released(0, mb_left);
}


// ═══════════════════════════════════════════════════════════════
// 2. ДАННЫЕ СТРОК
// ═══════════════════════════════════════════════════════════════

function hud_staff_manage_role_text(_staff) {
    if (!instance_exists(_staff)) return "СОТРУДНИК";
    if (_staff.object_index == obj_player) return "ОСНОВНОЙ ИГРОК";

    switch (string(_staff.role)) {
        case "doctor": return "ВРАЧ";
        case "admin": return "АДМИНИСТРАТОР";
        case "assistant": return "АССИСТЕНТ";
    }

    return "СОТРУДНИК";
}

function hud_staff_manage_status_text(_staff) {
    if (!instance_exists(_staff)) return "";

    if (variable_instance_exists(_staff, "doctor_state")) {
        switch (_staff.doctor_state) {
            case "idle": return "Свободен";
            case "examining": return "Ведёт приём";
            case "manual_exam": return "На приёме";
            case "manual_procedure": return "Выполняет процедуры";
            case "inpatient_at_chair": return "Дежурит в стационаре";
            case "inpatient_prescribing": return "Назначает лечение";
            case "cleaning_dirt": return "Убирает";
        }
    }

    if (variable_instance_exists(_staff, "reception_state")) {
        switch (_staff.reception_state) {
            case "idle": return "Свободен";
            case "registering": return "Оформляет клиента";
            case "returning": return "Возвращается";
        }
    }

    if (variable_instance_exists(_staff, "assistant_state")) {
        switch (_staff.assistant_state) {
            case "idle": return "Свободен";
            case "performing_procedure": return "Выполняет процедуру";
            case "cleaning_dirt": return "Убирает";
            case "inpatient_available": return "Дежурит в стационаре";
            case "inpatient_treating": return "Лечит в стационаре";
        }
    }

    if (
        variable_instance_exists(_staff, "path_index")
        && _staff.path_index != -1
        && _staff.path_position < 1
    ) {
        return "Идёт";
    }

    return "Занят";
}

function hud_staff_manage_row_colors(_staff) {
    if (!instance_exists(_staff)) {
        return {
            fill : make_color_rgb(242, 232, 214),
            line : make_color_rgb(180, 160, 140)
        };
    }

    if (_staff.object_index == obj_player) {
        return {
            fill : make_color_rgb(246, 242, 226),
            line : make_color_rgb(145, 126, 84)
        };
    }

    switch (string(_staff.role)) {
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

function hud_staff_manage_build_entries() {
    var _entries = [];

    if (instance_exists(obj_player)) {
        array_push(_entries, {
            kind : "staff",
            staff : instance_find(obj_player, 0)
        });
    }

    array_push(_entries, { kind : "header", text : "ВРАЧИ:" });

    for (var _doctor_index = 0; _doctor_index < instance_number(obj_staff_doctor); _doctor_index++) {
        array_push(_entries, {
            kind : "staff",
            staff : instance_find(obj_staff_doctor, _doctor_index)
        });
    }

    array_push(_entries, { kind : "header", text : "АДМИНИСТРАТОРЫ:" });

    for (var _admin_index = 0; _admin_index < instance_number(obj_staff_admin); _admin_index++) {
        array_push(_entries, {
            kind : "staff",
            staff : instance_find(obj_staff_admin, _admin_index)
        });
    }

    array_push(_entries, { kind : "header", text : "АССИСТЕНТЫ:" });

    for (var _assistant_index = 0; _assistant_index < instance_number(obj_staff_assistant); _assistant_index++) {
        array_push(_entries, {
            kind : "staff",
            staff : instance_find(obj_staff_assistant, _assistant_index)
        });
    }

    return _entries;
}


// ═══════════════════════════════════════════════════════════════
// 3. ЛЕВАЯ ГРУППИРОВАННАЯ КОЛОНКА
// ═══════════════════════════════════════════════════════════════

function hud_staff_manage_draw_roster(
    _hud,
    _x1,
    _y1,
    _x2,
    _y2,
    _mouse_x,
    _mouse_y
) {
    var _paper = make_color_rgb(248, 240, 224);
    var _line = make_color_rgb(180, 160, 140);
    var _text_dark = make_color_rgb(50, 38, 28);
    var _text_soft = make_color_rgb(84, 68, 54);

    if (!variable_instance_exists(_hud, "staff_manage_scroll_index")) {
        _hud.staff_manage_scroll_index = 0;
    }

    var _entries = hud_staff_manage_build_entries();
    var _entry_count = array_length(_entries);
    var _header_h = 30;
    var _row_h = 78;
    var _row_gap = 7;

    hud_frosted_fill(_x1, _y1, _x2, _y2, 10);
    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_text_dark);
    ui_text_fit_left(_x1 + 16, _y1 + 10, "ПЕРСОНАЛ КЛИНИКИ", (_x2 - _x1) - 40, UI_FS_TITLE);

    var _rows_x1 = _x1 + 12;
    var _rows_x2 = _x2 - 12;
    var _rows_y1 = _y1 + 40;
    var _rows_y2 = _y2 - 28;
    var _inside_list = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _x1,
        _y1,
        _x2,
        _y2
    );
    var _inside_rows = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _rows_x1,
        _rows_y1,
        _rows_x2,
        _rows_y2
    );

    if (!variable_instance_exists(_hud, "staff_manage_touch_active")) {
        _hud.staff_manage_touch_active = false;
        _hud.staff_manage_touch_start_y = 0;
        _hud.staff_manage_touch_last_y = 0;
        _hud.staff_manage_touch_accum = 0;
        _hud.staff_manage_touch_moved = false;
    }

    var _pointer_pressed = hud_staff_manage_pointer_pressed();
    var _pointer_down = hud_staff_manage_pointer_down();
    var _pointer_released = hud_staff_manage_pointer_released();
    var _tap_released = false;

    // Колесо перемещает список по одной целой записи.
    if (_inside_list && !_hud.staff_manage_fire_confirm) {
        if (mouse_wheel_down()) _hud.staff_manage_scroll_index += 1;
        if (mouse_wheel_up()) _hud.staff_manage_scroll_index -= 1;
    }

    // На телефоне список перетягивается одним пальцем.
    // Короткое касание выбирает строку, а движение не считается кликом.
    if (
        _pointer_pressed
        && _inside_rows
        && !_hud.staff_manage_fire_confirm
    ) {
        _hud.staff_manage_touch_active = true;
        _hud.staff_manage_touch_start_y = _mouse_y;
        _hud.staff_manage_touch_last_y = _mouse_y;
        _hud.staff_manage_touch_accum = 0;
        _hud.staff_manage_touch_moved = false;
    }

    if (_hud.staff_manage_touch_active) {
        if (_pointer_down) {
            var _touch_delta_y = _mouse_y
                - _hud.staff_manage_touch_last_y;

            if (
                abs(_mouse_y - _hud.staff_manage_touch_start_y) >= 10
            ) {
                _hud.staff_manage_touch_moved = true;
            }

            if (_hud.staff_manage_touch_moved) {
                _hud.staff_manage_touch_accum += _touch_delta_y;

                while (_hud.staff_manage_touch_accum <= -36) {
                    _hud.staff_manage_scroll_index += 1;
                    _hud.staff_manage_touch_accum += 36;
                }

                while (_hud.staff_manage_touch_accum >= 36) {
                    _hud.staff_manage_scroll_index -= 1;
                    _hud.staff_manage_touch_accum -= 36;
                }
            }

            _hud.staff_manage_touch_last_y = _mouse_y;
        }

        if (_pointer_released) {
            _tap_released = (
                !_hud.staff_manage_touch_moved
                && _inside_rows
            );
            _hud.staff_manage_touch_active = false;
            _hud.staff_manage_touch_accum = 0;
        }
        else if (!_pointer_down && !_pointer_pressed) {
            // Защита от потерянного touch-release при сворачивании приложения.
            _hud.staff_manage_touch_active = false;
            _hud.staff_manage_touch_accum = 0;
        }
    }

    if (_hud.staff_manage_fire_confirm) {
        _hud.staff_manage_touch_active = false;
        _hud.staff_manage_touch_accum = 0;
    }

    _hud.staff_manage_scroll_index = clamp(
        _hud.staff_manage_scroll_index,
        0,
        max(0, _entry_count - 1)
    );

    var _draw_y = _rows_y1;
    var _shown_count = 0;

    for (
        var _entry_index = _hud.staff_manage_scroll_index;
        _entry_index < _entry_count;
        _entry_index++
    ) {
        var _entry = _entries[_entry_index];
        var _entry_h = (_entry.kind == "header")
            ? _header_h
            : _row_h;
        var _entry_y2 = _draw_y + _entry_h;

        // Рисуем только полностью помещающиеся элементы — без GPU-scissor.
        // Это исключает обрезание первой строки и правого края при GUI-scale.
        if (_entry_y2 > _rows_y2) break;

        if (_entry.kind == "header") {
            draw_set_color(make_color_rgb(232, 220, 198));
            draw_roundrect_ext(
                _rows_x1,
                _draw_y + 2,
                _rows_x2,
                _entry_y2 - 3,
                6,
                6,
                false
            );
            draw_set_color(_text_soft);
            ui_text_row(
                _rows_x1 + 10,
                _draw_y,
                _entry_y2 - _draw_y,
                _entry.text,
                (_rows_x2 - _rows_x1) - 24,
                UI_FS_ROW
            );

            _draw_y = _entry_y2;
            _shown_count += 1;
            continue;
        }

        var _staff = _entry.staff;

        if (!instance_exists(_staff)) {
            _draw_y = _entry_y2 + _row_gap;
            continue;
        }

        var _row_x1 = _rows_x1;
        var _row_x2 = _rows_x2;
        var _row_y1 = _draw_y;
        var _row_y2 = _entry_y2;
        var _hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _row_x1,
            _row_y1,
            _row_x2,
            _row_y2
        );
        var _selected = (_hud.selected_staff_id == _staff);
        var _colors = hud_staff_manage_row_colors(_staff);
        var _fill = _colors.fill;

        if (_selected) {
            _fill = merge_color(_fill, _colors.line, 0.20);
        }
        else if (_hovered) {
            _fill = merge_color(_fill, c_white, 0.36);
        }

        draw_set_alpha(0.12);
        draw_set_color(c_black);
        draw_roundrect_ext(
            _row_x1 + 2,
            _row_y1 + 3,
            _row_x2 + 2,
            _row_y2 + 3,
            9,
            9,
            false
        );
        draw_set_alpha(1);

        draw_set_color(_fill);
        draw_roundrect_ext(
            _row_x1,
            _row_y1,
            _row_x2,
            _row_y2,
            9,
            9,
            false
        );
        draw_set_color(_colors.line);
        draw_roundrect_ext(
            _row_x1,
            _row_y1,
            _row_x2,
            _row_y2,
            9,
            9,
            true
        );

        // Каждая надпись занимает ровно одну строку. Длинный текст
        // пропорционально сжимается только по горизонтали.
        var _text_x = _row_x1 + 12;
        var _text_available_w = _row_x2 - _row_x1 - 24;
        var _name_text = string_upper(string(_staff.char_name));
        var _role_text = hud_staff_manage_role_text(_staff);
        var _status_text = hud_staff_manage_status_text(_staff);
        var _name_scale = min(
            1,
            _text_available_w / max(1, string_width(_name_text))
        );
        var _role_scale = min(
            1,
            _text_available_w / max(1, string_width(_role_text))
        );
        var _status_scale = min(
            1,
            _text_available_w / max(1, string_width(_status_text))
        );

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_text_dark);
        draw_text_transformed(
            _text_x,
            _row_y1 + 8,
            _name_text,
            _name_scale,
            1,
            0
        );

        draw_set_color(_colors.line);
        draw_text_transformed(
            _text_x,
            _row_y1 + 32,
            _role_text,
            _role_scale,
            1,
            0
        );

        draw_set_color(_text_soft);
        draw_text_transformed(
            _text_x,
            _row_y1 + 56,
            _status_text,
            _status_scale,
            1,
            0
        );

        if (
            _hovered
            && !_hud.staff_manage_fire_confirm
            && _tap_released
        ) {
            _hud.selected_staff_id = _staff;

            if (variable_instance_exists(_hud, "staff_skill_help_id")) {
                _hud.staff_skill_help_id = "";
            }

            if (variable_instance_exists(_hud, "staff_workplace_menu_open")) {
                _hud.staff_workplace_menu_open = false;
                _hud.staff_workplace_menu_target = noone;
            }
        }

        _draw_y = _row_y2 + _row_gap;
        _shown_count += 1;
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_text_soft);

    var _scroll_hint = "КОЛЕСО / ПЕРЕТЯГИВАНИЕ";

    if (_entry_count > 0) {
        _scroll_hint += "  "
            + string(_hud.staff_manage_scroll_index + 1)
            + "/"
            + string(_entry_count);
    }

    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        _y2 - 18,
        _scroll_hint,
        (_x2 - _x1) - 40,
        UI_FS_ROW
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ═══════════════════════════════════════════════════════════════
// 4. КАРТОЧКА СТАНДАРТНОГО РАЗМЕРА И ПРАВЫЕ КНОПКИ
// ═══════════════════════════════════════════════════════════════

function hud_staff_manage_get_standard_scale() {
    var _scale = 1.8;

    if (instance_exists(obj_UI_Tablet)) {
        var _tablet = instance_find(obj_UI_Tablet, 0);

        if (
            instance_exists(_tablet)
            && variable_instance_exists(_tablet, "ui_scale")
        ) {
            _scale = _tablet.ui_scale;
        }
    }

    return max(0.70, _scale);
}

function hud_staff_manage_draw_card(
    _hud,
    _staff,
    _slot_x,
    _slot_y,
    _scale
) {
    var _card_w = 536 * _scale;
    var _card_h = 396 * _scale;

    if (!instance_exists(_staff)) {
        draw_set_color(make_color_rgb(252, 250, 246));
        draw_roundrect_ext(
            _slot_x,
            _slot_y,
            _slot_x + _card_w,
            _slot_y + _card_h,
            10,
            10,
            false
        );
        draw_set_color(make_color_rgb(180, 160, 140));
        draw_roundrect_ext(
            _slot_x,
            _slot_y,
            _slot_x + _card_w,
            _slot_y + _card_h,
            10,
            10,
            true
        );
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(84, 68, 54));
        ui_text_fit_center(
            _slot_x + _card_w * 0.5,
            _slot_y + _card_h * 0.5,
            "ВЫБЕРИТЕ СОТРУДНИКА",
            _card_w - 40,
            UI_FS_HEADER
        );
        return;
    }

    // Геометрия полностью совпадает с обычным obj_UI_Tablet.
    // При масштабе 1.8 шрифт и все элементы имеют стандартный размер.
    var _frame_x = _slot_x + 8 * _scale;
    var _frame_y = _slot_y + 12 * _scale;
    var _center_x = _frame_x + 260 * _scale;
    var _center_y = _frame_y + 188 * _scale;
    var _photo_w = 68 * _scale;
    var _photo_h = 92 * _scale;

    tablet_draw_staff_card(
        _hud,
        _staff,
        _center_x,
        _center_y,
        _scale,
        _frame_x,
        _frame_y,
        _photo_w,
        _photo_h
    );
}

function hud_staff_manage_draw_actions(
    _hud,
    _staff,
    _x1,
    _y1,
    _x2,
    _y2,
    _mouse_x,
    _mouse_y
) {
    var _paper = make_color_rgb(248, 240, 224);
    var _line = make_color_rgb(180, 160, 140);
    var _text_dark = make_color_rgb(50, 38, 28);
    var _column_h = _y2 - _y1;
    var _button_gap = clamp(_column_h * 0.02, 6, 12);
    var _button_h = min(
        56,
        (_column_h - 59 - _button_gap * 3) * 0.25
    );
    _button_h = max(36, _button_h);

    hud_frosted_fill(_x1, _y1, _x2, _y2, 10);
    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(_text_dark);
    ui_text_fit_center((_x1 + _x2) * 0.5, _y1 + 20, "ДЕЙСТВИЯ", (_x2 - _x1) - 30, UI_FS_HEADER);

    var _button_x1 = _x1 + 12;
    var _button_x2 = _x2 - 12;
    var _button_y = _y1 + 45;
    var _can_fire = (
        instance_exists(_staff)
        && _staff.object_index != obj_player
    );

    for (var _button_index = 0; _button_index < 4; _button_index++) {
        var _button_y1 = _button_y
            + _button_index * (_button_h + _button_gap);
        var _button_y2 = _button_y1 + _button_h;
        var _enabled = (_button_index == 0) && _can_fire;
        var _hovered = (
            _enabled
            && !_hud.staff_manage_fire_confirm
            && point_in_rectangle(
                _mouse_x,
                _mouse_y,
                _button_x1,
                _button_y1,
                _button_x2,
                _button_y2
            )
        );
        var _label = (_button_index == 0)
            ? "УВОЛИТЬ"
            : "—";

        hud_staff_manage_draw_button(
            _button_x1,
            _button_y1,
            _button_x2,
            _button_y2,
            _label,
            _enabled,
            _hovered,
            (_button_index == 0) ? "red" : "gray"
        );

        if (
            _hovered
            && hud_staff_manage_pointer_pressed()
        ) {
            _hud.staff_manage_fire_confirm = true;
            _hud.staff_manage_fire_target = _staff;
        }
    }

    var _note_y = _button_y
        + 4 * _button_h
        + 3 * _button_gap
        + 10;

    if (
        instance_exists(_staff)
        && _staff.object_index == obj_player
        && _note_y + 34 <= _y2
    ) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_set_color(make_color_rgb(105, 100, 92));
        var _note_w = _x2 - _x1 - 28;
        var _note_scale = ui_fit_scale("Главного игрока нельзя уволить", _note_w, UI_FS_ROW);

        draw_text_ext_transformed(
            (_x1 + _x2) * 0.5,
            _note_y,
            "Главного игрока нельзя уволить",
            20,
            _note_w / _note_scale,
            _note_scale,
            _note_scale,
            0
        );
    }
}


// ═══════════════════════════════════════════════════════════════
// 5. ПОДТВЕРЖДЕНИЕ УВОЛЬНЕНИЯ
// ═══════════════════════════════════════════════════════════════

function hud_staff_manage_draw_fire_confirm(
    _hud,
    _mouse_x,
    _mouse_y
) {
    if (!variable_instance_exists(_hud, "staff_manage_fire_confirm")) {
        _hud.staff_manage_fire_confirm = false;
        _hud.staff_manage_fire_target = noone;
    }

    if (!_hud.staff_manage_fire_confirm) return;

    if (!instance_exists(_hud.staff_manage_fire_target)) {
        _hud.staff_manage_fire_confirm = false;
        _hud.staff_manage_fire_target = noone;
        return;
    }

    var _gui_w = display_get_gui_width();
    var _gui_h = display_get_gui_height();
    // Пакет №175: окно подтверждения крупнее под телефон.
    var _panel_w = 660;
    var _panel_h = 260;
    var _x1 = (_gui_w - _panel_w) * 0.5;
    var _y1 = (_gui_h - _panel_h) * 0.5;
    var _x2 = _x1 + _panel_w;
    var _y2 = _y1 + _panel_h;

    draw_set_alpha(0.36);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _gui_w, _gui_h, false);
    draw_set_alpha(1);

    hud_staff_manage_draw_outer_panel(_x1, _y1, _x2, _y2);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(50, 38, 28));
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        _y1 + 60,
        "УВОЛИТЬ "
            + string_upper(
                string(_hud.staff_manage_fire_target.char_name)
            )
            + "?",
        (_x2 - _x1) - 48,
        UI_FS_TITLE
    );

    var _yes_x1 = _x1 + 28;
    var _yes_x2 = (_x1 + _x2) * 0.5 - 7;
    var _no_x1 = (_x1 + _x2) * 0.5 + 7;
    var _no_x2 = _x2 - 28;
    var _button_y1 = _y2 - 96;
    var _button_y2 = _y2 - 32;
    var _yes_hover = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _yes_x1,
        _button_y1,
        _yes_x2,
        _button_y2
    );
    var _no_hover = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _no_x1,
        _button_y1,
        _no_x2,
        _button_y2
    );

    hud_staff_manage_draw_button(
        _yes_x1,
        _button_y1,
        _yes_x2,
        _button_y2,
        "ДА",
        true,
        _yes_hover,
        "red"
    );
    hud_staff_manage_draw_button(
        _no_x1,
        _button_y1,
        _no_x2,
        _button_y2,
        "НЕТ",
        true,
        _no_hover,
        "green"
    );

    if (hud_staff_manage_pointer_pressed()) {
        if (_yes_hover) {
            var _fire_target = _hud.staff_manage_fire_target;

            _hud.staff_manage_fire_confirm = false;
            _hud.staff_manage_fire_target = noone;

            if (_hud.selected_staff_id == _fire_target) {
                _hud.selected_staff_id = instance_exists(obj_player)
                    ? instance_find(obj_player, 0)
                    : noone;
            }

            with (_fire_target) {
                instance_destroy();
            }
        }
        else if (_no_hover) {
            _hud.staff_manage_fire_confirm = false;
            _hud.staff_manage_fire_target = noone;
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 6. ОСНОВНОЙ МОДУЛЬ С ДВУМЯ ВКЛАДКАМИ
// ═══════════════════════════════════════════════════════════════

function hud_draw_staff_management_panel(_hud) {
    if (!instance_exists(_hud)) return;
    if (!_hud.visible) return;

    var _management_open = variable_instance_exists(
        _hud,
        "staff_manage_panel_open"
    )
        ? _hud.staff_manage_panel_open
        : _hud.staff_panel_open;

    if (!_management_open) return;

    if (font_exists(fnt_main)) draw_set_font(fnt_main);

    if (!variable_instance_exists(_hud, "staff_manage_fire_confirm")) {
        _hud.staff_manage_fire_confirm = false;
        _hud.staff_manage_fire_target = noone;
    }

    if (!variable_instance_exists(_hud, "staff_manage_scroll_index")) {
        _hud.staff_manage_scroll_index = 0;
    }

    if (!instance_exists(_hud.selected_staff_id)) {
        _hud.selected_staff_id = instance_exists(obj_player)
            ? instance_find(obj_player, 0)
            : noone;
    }

    staff_hiring_search_init();

    var _mouse_x = device_mouse_x_to_gui(0);
    var _mouse_y = device_mouse_y_to_gui(0);
    var _gui_w = display_get_gui_width();
    var _gui_h = display_get_gui_height();
    var _outer_pad = 18;
    // Пакет №180: полоса под общий размер вкладки + зазор.
    var _tab_area_h = UI_TAB_H + 16;
    var _column_gap = 14;
    var _list_w = clamp(_gui_w * 0.18, 280, 340);
    var _actions_w = clamp(_gui_w * 0.09, 142, 172);
    var _top_limit = 14;
    var _bottom_limit = _gui_h - 14;

    if (variable_instance_exists(_hud, "hud_top_h")) {
        _top_limit = max(_top_limit, _hud.hud_top_h + 10);
    }

    if (
        variable_instance_exists(_hud, "bottombar_y1")
        && _hud.bottombar_y1 > _top_limit + 300
    ) {
        _bottom_limit = min(_bottom_limit, _hud.bottombar_y1 - 10);
    }

    var _available_w = _gui_w - 24;
    var _available_h = max(350, _bottom_limit - _top_limit);
    var _standard_scale = hud_staff_manage_get_standard_scale();
    var _scale_by_width = (
        _available_w
        - _outer_pad * 2
        - _list_w
        - _actions_w
        - _column_gap * 2
    ) / 536;
    var _scale_by_height = (
        _available_h
        - _outer_pad * 2
        - _tab_area_h
    ) / 396;
    var _card_scale = max(
        0.70,
        min(
            _standard_scale,
            _scale_by_width,
            _scale_by_height
        )
    );
    var _card_w = 536 * _card_scale;
    var _card_h = 396 * _card_scale;
    var _content_w = _list_w
        + _column_gap
        + _card_w
        + _column_gap
        + _actions_w;
    var _panel_w = _content_w + _outer_pad * 2;
    var _panel_h = _card_h + _outer_pad * 2 + _tab_area_h;
    var _panel_x1 = (_gui_w - _panel_w) * 0.5;
    var _panel_y1 = _top_limit
        + (_available_h - _panel_h) * 0.5;
    var _panel_x2 = _panel_x1 + _panel_w;
    var _panel_y2 = _panel_y1 + _panel_h;

    hud_staff_manage_draw_outer_panel(
        _panel_x1,
        _panel_y1,
        _panel_x2,
        _panel_y2
    );

    // Пакет №180: полоса вкладок под общий размер UI_TAB_H.
    var _tab_x1 = _panel_x1 + _outer_pad;
    var _tab_y1 = _panel_y1 + 16;
    var _tab_x2 = _panel_x2 - 20 - UI_TAB_H - UI_TAB_GAP;
    var _tab_y2 = _tab_y1 + UI_TAB_H;
    var _current_tab = staff_hiring_search_draw_tabs(
        _hud,
        _tab_x1,
        _tab_y1,
        _tab_x2,
        _tab_y2,
        _mouse_x,
        _mouse_y
    );

    var _content_x1 = _panel_x1 + _outer_pad;
    var _content_y1 = _panel_y1 + _outer_pad + _tab_area_h;
    var _content_y2 = _content_y1 + _card_h;

    if (_current_tab == "search") {
        staff_hiring_search_draw_page(
            _hud,
            _content_x1,
            _content_y1,
            _panel_x2 - _outer_pad,
            _content_y2,
            _mouse_x,
            _mouse_y
        );
    }
    else {
        var _list_x1 = _content_x1;
        var _list_x2 = _list_x1 + _list_w;
        var _card_x = _list_x2 + _column_gap;
        var _actions_x1 = _card_x + _card_w + _column_gap;
        var _actions_x2 = _actions_x1 + _actions_w;

        hud_staff_manage_draw_roster(
            _hud,
            _list_x1,
            _content_y1,
            _list_x2,
            _content_y2,
            _mouse_x,
            _mouse_y
        );

        hud_staff_manage_draw_card(
            _hud,
            _hud.selected_staff_id,
            _card_x,
            _content_y1,
            _card_scale
        );

        hud_staff_manage_draw_actions(
            _hud,
            _hud.selected_staff_id,
            _actions_x1,
            _content_y1,
            _actions_x2,
            _content_y2,
            _mouse_x,
            _mouse_y
        );
    }

    // Общий крестик закрывает обе вкладки панели.
    var _close_x2 = _panel_x2 - 20;
    var _close_x1 = _close_x2 - UI_TAB_H;
    var _close_y1 = _panel_y1 + 16;
    var _close_y2 = _close_y1 + UI_TAB_H;
    var _close_enabled = !_hud.staff_manage_fire_confirm;
    var _close_hovered = _close_enabled
        && point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _close_x1,
            _close_y1,
            _close_x2,
            _close_y2
        );

    ui_draw_close_button(
        _close_x1,
        _close_y1,
        _close_x2,
        _close_y2,
        _close_hovered
    );

    if (
        _close_hovered
        && hud_staff_manage_pointer_pressed()
    ) {
        _hud.staff_panel_open = false;
        _hud.staff_manage_panel_open = false;
        _hud.staff_manage_fire_confirm = false;
        _hud.staff_manage_fire_target = noone;

        if (variable_instance_exists(_hud, "staff_manage_draw_requested")) {
            _hud.staff_manage_draw_requested = false;
        }

        if (variable_instance_exists(_hud, "staff_workplace_menu_open")) {
            _hud.staff_workplace_menu_open = false;
            _hud.staff_workplace_menu_target = noone;
        }
    }

    if (_current_tab == "staff") {
        hud_staff_manage_draw_fire_confirm(
            _hud,
            _mouse_x,
            _mouse_y
        );
    }

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);
}
