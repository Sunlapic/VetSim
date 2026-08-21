/// clinic_rooms_system.gml
/// @description Помещения клиники за деньги: открытие кабинетов приёма.
/// Пакет №72. Пакет №104: убран знак «№» (нет в шрифте, рисовался как [ ]).
/// Пакет №109: добавлена операционная (пока открыта всегда, покупка позже).


// ═══════════════════════════════════════════════════════════════
// 1. СОСТОЯНИЕ ПОМЕЩЕНИЙ
// Кабинет 1 открыт всегда. Кабинеты 2 и 3 открываются за деньги.
// ═══════════════════════════════════════════════════════════════

function clinic_rooms_init() {
    if (!variable_global_exists("clinic_rooms_open")) {
        global.clinic_rooms_open = {};

        variable_struct_set(global.clinic_rooms_open, "1", true);
        variable_struct_set(global.clinic_rooms_open, "2", false);
        variable_struct_set(global.clinic_rooms_open, "3", false);
    }
}

// ═══════════════════════════════════════════════════════════════
// Пакет №173: КОЙКИ СТАЦИОНАРА И ОПЕРАЦИОННАЯ ЗА ДЕНЬГИ
//
// Койки 101 и 102 идут в комплекте с палатой, 103 и 104 покупаются.
// Некупленная койка скрыта (par_objects → Draw) и держит table_busy,
// поэтому её не найдёт ни один поиск свободного места.
// ═══════════════════════════════════════════════════════════════

// ВРЕМЕННО: операционная открыта сразу, чтобы не покупать её при каждой
// проверке игры. Перед релизом поставить false — механика покупки готова.
#macro CLINIC_OPERATING_FREE_WHILE_TESTING true

function clinic_bed_price(_slot_id) {
    switch (round(_slot_id)) {
        case 103: return 1600;
        case 104: return 2000;
    }

    return 0;
}

function clinic_bed_is_open(_slot_id) {
    clinic_rooms_init();

    var _slot = round(_slot_id);

    // Первые две койки — часть палаты.
    if (_slot == 101 || _slot == 102) return true;
    if (_slot < 101 || _slot > 104) return true;

    var _key = "bed_" + string(_slot);

    if (variable_struct_exists(global.clinic_rooms_open, _key)) {
        return variable_struct_get(global.clinic_rooms_open, _key);
    }

    return false;
}

function clinic_operating_is_open() {
    clinic_rooms_init();

    if (CLINIC_OPERATING_FREE_WHILE_TESTING) return true;

    if (variable_struct_exists(global.clinic_rooms_open, "operating")) {
        return variable_struct_get(global.clinic_rooms_open, "operating");
    }

    return false;
}

function clinic_room_is_open(_slot_id) {
    clinic_rooms_init();

    // Пакет №173: операционная и её мебель (столы 201/202).
    if (string(_slot_id) == "operating") return clinic_operating_is_open();

    var _slot_num = round(_slot_id);

    if (_slot_num == 201 || _slot_num == 202) return clinic_operating_is_open();

    // Пакет №173: койки стационара 101–104 покупаются по одной.
    if (_slot_num >= 101 && _slot_num <= 104) return clinic_bed_is_open(_slot_num);

    // Шкаф палаты и прочее общее оборудование стационара (слот 100).
    if (_slot_num >= 100) return true;

    // Слот 0 (не настроен) и слот 1 (стартовый кабинет) всегда открыты.
    if (_slot_id <= 1) return true;

    var _key = string(round(_slot_id));

    if (variable_struct_exists(global.clinic_rooms_open, _key)) {
        return variable_struct_get(global.clinic_rooms_open, _key);
    }

    // Неизвестные слоты считаем закрытыми.
    return false;
}


// ═══════════════════════════════════════════════════════════════
// 2. ЦЕНЫ И НАЗВАНИЯ
// ═══════════════════════════════════════════════════════════════

function clinic_room_price(_slot_id) {
    // Пакет №173: операционная продаётся за деньги.
    if (string(_slot_id) == "operating") return 5000;

    var _slot_num = round(_slot_id);

    if (_slot_num >= 101 && _slot_num <= 104) return clinic_bed_price(_slot_num);

    switch (_slot_num) {
        case 2: return 1500;
        case 3: return 3000;
    }

    return 0;
}

function clinic_room_name(_slot_id) {
    if (string(_slot_id) == "operating") return "Операционная";

    var _slot_num = round(_slot_id);

    if (_slot_num >= 101 && _slot_num <= 104) {
        return "Койка " + string(_slot_num - 100);
    }

    return "Кабинет " + string(_slot_num);
}

function clinic_room_description(_slot_id) {
    if (string(_slot_id) == "operating") {
        return "Операционный блок: хирургические операции";
    }

    if (round(_slot_id) <= 1) {
        return "Смотровый кабинет (стартовый)";
    }

    return "Смотровый кабинет: +1 стол осмотра";
}

function clinic_rooms_entries() {
    clinic_rooms_init();

    // Пакет №109: операционная добавлена последней карточкой.
    var _slots = [1, 2, 3, "operating"];
    var _entries = [];

    for (var _index = 0; _index < array_length(_slots); _index++) {
        var _slot = _slots[_index];

        array_push(_entries, {
            slot : _slot,
            name : clinic_room_name(_slot),
            description : clinic_room_description(_slot),
            price : clinic_room_price(_slot),
            open : clinic_room_is_open(_slot)
        });
    }

    return _entries;
}


// ═══════════════════════════════════════════════════════════════
// 3. ПОКУПКА ПОМЕЩЕНИЯ
// ═══════════════════════════════════════════════════════════════

function clinic_room_purchase(_slot_id) {
    clinic_rooms_init();

    // Пакет №173: операционная — отдельный ключ, не числовой слот.
    var _is_operating = (string(_slot_id) == "operating");
    var _slot = _is_operating ? 0 : round(_slot_id);

    if (!_is_operating && clinic_room_is_open(_slot)) return false;
    if (_is_operating && clinic_operating_is_open()) return false;

    var _price = clinic_room_price(_slot_id);

    if (_price <= 0) return false;

    if (global.clinic_money < _price) {
        var _need_message = "Нужно $" + string(_price) + ".";

        if (instance_exists(obj_UI_HUD)) {
            var _hud_need = instance_find(obj_UI_HUD, 0);

            if (
                instance_exists(_hud_need)
                && variable_instance_exists(_hud_need, "show_notice")
            ) {
                with (_hud_need) {
                    show_notice(
                        "НЕ ХВАТАЕТ ДЕНЕГ",
                        _need_message,
                        max(1, game_get_speed(gamespeed_fps)) * 2
                    );
                }
            }
        }

        return false;
    }

    global.clinic_money -= _price;

    // Пакет №173: ключ зависит от типа покупки.
    if (_is_operating) {
        variable_struct_set(global.clinic_rooms_open, "operating", true);
    }
    else if (_slot >= 101 && _slot <= 104) {
        variable_struct_set(global.clinic_rooms_open, "bed_" + string(_slot), true);

        // Освобождаем купленную койку: теперь её найдёт inpatient_find_free_ward.
        for (var _bed_index = 0; _bed_index < instance_number(obj_inpatient_table); _bed_index++) {
            var _bed = instance_find(obj_inpatient_table, _bed_index);

            if (
                instance_exists(_bed)
                && variable_instance_exists(_bed, "exam_slot_id")
                && _bed.exam_slot_id == _slot
            ) {
                _bed.table_busy = false;
                _bed.assigned_owner = noone;
                _bed.assigned_doctor = noone;
                _bed.assigned_pet = noone;
            }
        }
    }
    else {
        variable_struct_set(global.clinic_rooms_open, string(_slot), true);
    }

    // Освобождаем столы открытого кабинета: теперь их найдут
    // игрок, врачи и ассистенты в поиске свободного стола.
    var _table_types = [obj_table, obj_table_1];

    for (var _type_index = 0; _type_index < array_length(_table_types); _type_index++) {
        var _object = _table_types[_type_index];

        for (var _table_index = 0; _table_index < instance_number(_object); _table_index++) {
            var _table = instance_find(_object, _table_index);

            if (
                instance_exists(_table)
                && variable_instance_exists(_table, "exam_slot_id")
                && _table.exam_slot_id == _slot
            ) {
                _table.table_busy = false;
                _table.assigned_owner = noone;
                _table.assigned_doctor = noone;
                _table.assigned_pet = noone;
            }
        }
    }

    var _room_name = clinic_room_name(_is_operating ? "operating" : _slot);

    if (instance_exists(obj_UI_HUD)) {
        var _hud_ok = instance_find(obj_UI_HUD, 0);

        if (
            instance_exists(_hud_ok)
            && variable_instance_exists(_hud_ok, "show_notice")
        ) {
            with (_hud_ok) {
                show_notice(
                    "ПОМЕЩЕНИЕ ОТКРЫТО",
                    _room_name + " теперь работает.",
                    max(1, game_get_speed(gamespeed_fps)) * 3
                );
            }
        }
    }

    show_debug_message("[ROOMS] Открыт " + _room_name + " за $" + string(_price));

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 4. ЛЕВАЯ КОЛОНКА «ПОМЕЩЕНИЯ (деньги)» В ПАНЕЛИ РАЗВИТИЕ
// ═══════════════════════════════════════════════════════════════

function hud_draw_rooms_column(_hud, _x1, _y1, _x2, _y2, _mx, _my) {
    if (!instance_exists(_hud)) return;

    clinic_rooms_init();

    with (_hud) {
        // Состояние прокрутки (переживает кадры на инстансе HUD).
        if (!variable_instance_exists(id, "rooms_scroll")) rooms_scroll = 0;
        if (!variable_instance_exists(id, "rooms_touch_active")) rooms_touch_active = false;
        if (!variable_instance_exists(id, "rooms_touch_last_y")) rooms_touch_last_y = 0;
        if (!variable_instance_exists(id, "rooms_touch_accum")) rooms_touch_accum = 0;

        var _wood_light = make_color_rgb(150, 107, 73);
        var _line_dark  = make_color_rgb(58, 39, 24);
        var _text_dark  = make_color_rgb(50, 38, 28);
        var _text_soft  = make_color_rgb(84, 68, 54);
        var _green      = make_color_rgb(62, 112, 74);

        var _entries = clinic_rooms_entries();
        var _row_h = 150;
        var _list_y1 = _y1 + 40;
        var _list_y2 = _y2 - 8;
        var _visible = max(1, floor((_list_y2 - _list_y1) / _row_h));
        var _max_scroll = max(0, array_length(_entries) - _visible);

        rooms_scroll = clamp(rooms_scroll, 0, _max_scroll);

        // Прокрутка: колесо + touch.
        var _in_rect = point_in_rectangle(_mx, _my, _x1, _y1, _x2, _y2);

        if (_in_rect) {
            if (mouse_wheel_down()) {
                rooms_scroll = min(_max_scroll, rooms_scroll + 1);
            }
            if (mouse_wheel_up()) {
                rooms_scroll = max(0, rooms_scroll - 1);
            }
        }

        var _pressed = mouse_check_button_pressed(mb_left)
            || device_mouse_check_button_pressed(0, mb_left);
        var _down = mouse_check_button(mb_left)
            || device_mouse_check_button(0, mb_left);
        var _released = mouse_check_button_released(mb_left)
            || device_mouse_check_button_released(0, mb_left);

        if (_pressed && _in_rect) {
            rooms_touch_active = true;
            rooms_touch_last_y = _my;
            rooms_touch_accum = 0;
        }

        if (rooms_touch_active) {
            if (_down) {
                var _delta = _my - rooms_touch_last_y;
                rooms_touch_accum += _delta;

                while (rooms_touch_accum <= -30) {
                    rooms_scroll = min(_max_scroll, rooms_scroll + 1);
                    rooms_touch_accum += 30;
                }

                while (rooms_touch_accum >= 30) {
                    rooms_scroll = max(0, rooms_scroll - 1);
                    rooms_touch_accum -= 30;
                }

                rooms_touch_last_y = _my;
            }

            if (_released || !_down) {
                rooms_touch_active = false;
                rooms_touch_accum = 0;
            }
        }

        // ── Карточки помещений ──
        for (var _vi = 0; _vi < _visible; _vi++) {
            var _idx = rooms_scroll + _vi;
            if (_idx >= array_length(_entries)) break;

            var _entry = _entries[_idx];
            var _cy1 = _list_y1 + _vi * _row_h;
            var _cy2 = _cy1 + (_row_h - 8);
            var _cx1 = _x1 + 10;
            var _cx2 = _x2 - 10;

            draw_set_color(make_color_rgb(246, 240, 228));
            draw_roundrect_ext(_cx1, _cy1, _cx2, _cy2, 8, 8, false);
            draw_set_color(make_color_rgb(200, 188, 170));
            draw_roundrect_ext(_cx1, _cy1, _cx2, _cy2, 8, 8, true);

            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_set_color(_text_dark);
            draw_text_transformed(
                _cx1 + 12,
                _cy1 + 8,
                _entry.name,
                1.35,
                1.35,
                0
            );
            draw_set_color(_text_soft);
            draw_text_transformed(
                _cx1 + 12,
                _cy1 + 40,
                _entry.description,
                1.15,
                1.15,
                0
            );

            // Кнопка на всю ширину карточки.
            var _btn_x1 = _cx1 + 12;
            var _btn_x2 = _cx2 - 12;
            var _btn_y1 = _cy1 + 88;
            var _btn_y2 = _btn_y1 + 48;
            var _btn_hover = point_in_rectangle(
                _mx, _my,
                _btn_x1, _btn_y1,
                _btn_x2, _btn_y2
            );

            var _can_afford = (
                !_entry.open
                && global.clinic_money >= _entry.price
            );

            var _label = _entry.open
                ? "ОТКРЫТО"
                : ("ОТКРЫТЬ ЗА $" + string(_entry.price));

            var _fill = _entry.open
                ? make_color_rgb(205, 224, 193)
                : (_can_afford
                    ? (_btn_hover
                        ? make_color_rgb(220, 235, 208)
                        : make_color_rgb(205, 224, 193))
                    : (_btn_hover
                        ? make_color_rgb(236, 226, 214)
                        : make_color_rgb(226, 216, 199)));
            var _line = _entry.open
                ? make_color_rgb(104, 137, 91)
                : (_can_afford
                    ? make_color_rgb(104, 137, 91)
                    : make_color_rgb(150, 132, 112));
            var _tcol = _entry.open
                ? make_color_rgb(45, 60, 40)
                : (_can_afford
                    ? make_color_rgb(45, 60, 40)
                    : make_color_rgb(148, 74, 64));

            draw_set_color(_fill);
            draw_roundrect_ext(_btn_x1, _btn_y1, _btn_x2, _btn_y2, 8, 8, false);
            draw_set_color(_line);
            draw_roundrect_ext(_btn_x1, _btn_y1, _btn_x2, _btn_y2, 8, 8, true);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(_tcol);
            draw_text_transformed(
                (_btn_x1 + _btn_x2) * 0.5,
                (_btn_y1 + _btn_y2) * 0.5,
                _label,
                1.2,
                1.2,
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
                clinic_room_purchase(_entry.slot);
            }
        }

        // ── Бегунок ──
        if (_max_scroll > 0) {
            var _track_x = _x2 - 8;
            var _track_h = max(1, _list_y2 - _list_y1);
            var _thumb_h = max(
                24,
                _track_h * (_visible / array_length(_entries))
            );
            var _travel = max(1, _track_h - _thumb_h);
            var _thumb_y = _list_y1 + _travel * (rooms_scroll / _max_scroll);

            draw_set_color(make_color_rgb(212, 200, 182));
            draw_roundrect_ext(_track_x, _list_y1, _track_x + 6, _list_y2, 3, 3, false);
            draw_set_color(_wood_light);
            draw_roundrect_ext(_track_x, _thumb_y, _track_x + 6, _thumb_y + _thumb_h, 3, 3, false);
            draw_set_color(_line_dark);
            draw_roundrect_ext(_track_x, _thumb_y, _track_x + 6, _thumb_y + _thumb_h, 3, 3, true);
        }
    }
}
