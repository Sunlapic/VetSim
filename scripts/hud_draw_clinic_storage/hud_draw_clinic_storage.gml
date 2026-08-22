/// hud_draw_clinic_storage.gml
/// @description Панель клиники, список складов, закупка и дефицит.
/// Пакет №70: увеличен шрифт препаратов, добавлена прокрутка обеих колонок,
/// а также видимые бегунки (скроллбары) по правому краю каждой колонки.
/// Пакет №119: панель на матовом стекле (дерево только рамкой).

function storage_draw_scrollbar(
    _track_x,
    _y1,
    _y2,
    _scroll,
    _max_scroll,
    _visible_count,
    _total_count
) {
    if (_max_scroll <= 0) return;
    if (_total_count <= 0) return;

    var _track_w = 6;
    var _track_h = max(1, _y2 - _y1);
    var _thumb_h = max(
        24,
        _track_h * (_visible_count / _total_count)
    );
    var _travel = max(1, _track_h - _thumb_h);
    var _thumb_y = _y1 + _travel * (_scroll / _max_scroll);

    // Дорожка.
    draw_set_color(make_color_rgb(212, 200, 182));
    draw_roundrect_ext(
        _track_x, _y1,
        _track_x + _track_w, _y2,
        3, 3, false
    );

    // Бегунок.
    draw_set_color(make_color_rgb(150, 107, 73));
    draw_roundrect_ext(
        _track_x, _thumb_y,
        _track_x + _track_w, _thumb_y + _thumb_h,
        3, 3, false
    );
    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(
        _track_x, _thumb_y,
        _track_x + _track_w, _thumb_y + _thumb_h,
        3, 3, true
    );
}

function hud_draw_clinic_storage(_hud) {
    if (!instance_exists(_hud)) return;
    if (!_hud.clinic_panel_open) return;

    with (_hud) {
        var _mouse_x = device_mouse_x_to_gui(0);
        var _mouse_y = device_mouse_y_to_gui(0);
        var _fps = hud_ui_fps();
        var _wood_dark = make_color_rgb(74, 49, 31);
        var _wood_mid = make_color_rgb(114, 77, 50);
        var _wood_light = make_color_rgb(150, 107, 73);
        var _paper = make_color_rgb(242, 232, 214);
        var _paper_2 = make_color_rgb(232, 220, 198);
        var _paper_hover = make_color_rgb(248, 238, 220);
        var _paper_active = make_color_rgb(220, 202, 172);
        var _line_dark = make_color_rgb(58, 39, 24);
        var _text_dark = make_color_rgb(50, 38, 28);
        var _text_soft = make_color_rgb(84, 68, 54);
        var _accent_blue = make_color_rgb(72, 112, 145);
        var _accent_red = make_color_rgb(148, 74, 64);

        hud_draw_frosted_panel(
            main_panel_x1,
            main_panel_y1,
            main_panel_x2,
            main_panel_y2
        );

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_text_dark);
        draw_text_transformed(main_panel_x1 + 28, main_panel_y1 + 96, "КЛИНИКА", 1.4, 1.4, 0);

        // Пакет №173: крупные вкладки с увеличенным шрифтом.
        hud_draw_button_big(
            clinic_tab_clinic_x1,
            clinic_tab_clinic_y1,
            clinic_tab_clinic_x2,
            clinic_tab_clinic_y2,
            "РАЗВИТИЕ",
            clinic_subtab == "clinic",
            hover_clinic_tab_clinic,
            _paper,
            _paper_hover,
            _paper_active,
            _line_dark,
            _text_dark
        );
        hud_draw_button_big(
            clinic_tab_storage_x1,
            clinic_tab_storage_y1,
            clinic_tab_storage_x2,
            clinic_tab_storage_y2,
            "СКЛАД",
            clinic_subtab == "storage",
            hover_clinic_tab_storage,
            _paper,
            _paper_hover,
            _paper_active,
            _line_dark,
            _text_dark
        );

        if (clinic_subtab == "clinic") {
            // Пакет №71: дерево развития клиники.
            hud_draw_clinic_upgrades(id);
            return;
        }

        if (clinic_subtab != "storage") return;

        // ─────────────────────────────────────────────
        // ПАКЕТ №70: СОСТОЯНИЕ ПРОКРУТКИ
        // Хранится на инстансе HUD и переживает кадры.
        // ─────────────────────────────────────────────
        if (!variable_instance_exists(id, "storage_scope_scroll")) storage_scope_scroll = 0;
        if (!variable_instance_exists(id, "storage_items_scroll")) storage_items_scroll = 0;
        if (!variable_instance_exists(id, "storage_scope_touch_active")) storage_scope_touch_active = false;
        if (!variable_instance_exists(id, "storage_scope_touch_last_y")) storage_scope_touch_last_y = 0;
        if (!variable_instance_exists(id, "storage_scope_touch_accum")) storage_scope_touch_accum = 0;
        if (!variable_instance_exists(id, "storage_items_touch_active")) storage_items_touch_active = false;
        if (!variable_instance_exists(id, "storage_items_touch_last_y")) storage_items_touch_last_y = 0;
        if (!variable_instance_exists(id, "storage_items_touch_accum")) storage_items_touch_accum = 0;

        storage_scope_row_hover = -1;
        stock_buy_hover_index = -1;
        stock_buy_buttons = [];

        if (!variable_instance_exists(id, "storage_scope_selected")) {
            storage_scope_selected = "main";
        }
        if (!variable_instance_exists(id, "storage_scope_selected_inst")) {
            storage_scope_selected_inst = noone;
        }

        if (storage_scope_selected == "cab") {
            if (instance_exists(storage_scope_selected_inst)) {
                storage_scope_selected = "cab_"
                    + string(storage_scope_selected_inst);
            }
            else {
                storage_scope_selected = "main";
                storage_scope_selected_inst = noone;
            }
        }

        storage_scope_entries = [];
        var _main_storage = instance_exists(obj_storage_main)
            ? instance_find(obj_storage_main, 0)
            : noone;

        array_push(storage_scope_entries, {
            scope_id : "main",
            label_ru : "СКЛАД",
            cabinet_id : _main_storage,
            slot_id : 0
        });

        var _cabinets = [];

        for (
            var _cabinet_index = 0;
            _cabinet_index < instance_number(obj_storage_cabinet);
            _cabinet_index++
        ) {
            var _cabinet = instance_find(obj_storage_cabinet, _cabinet_index);

            if (
                instance_exists(_cabinet)
                && variable_instance_exists(_cabinet, "exam_slot_id")
                && _cabinet.exam_slot_id > 0
                // Пакет №72: шкафы закрытых кабинетов не показываем.
                && clinic_room_is_open(_cabinet.exam_slot_id)
            ) {
                array_push(_cabinets, {
                    inst : _cabinet,
                    slot : _cabinet.exam_slot_id
                });
            }
        }

        for (var _sort_a = 0; _sort_a < array_length(_cabinets); _sort_a++) {
            for (var _sort_b = _sort_a + 1; _sort_b < array_length(_cabinets); _sort_b++) {
                if (_cabinets[_sort_b].slot < _cabinets[_sort_a].slot) {
                    var _swap = _cabinets[_sort_a];
                    _cabinets[_sort_a] = _cabinets[_sort_b];
                    _cabinets[_sort_b] = _swap;
                }
            }
        }

        var _used_slots = [];

        for (var _cabinet_row = 0; _cabinet_row < array_length(_cabinets); _cabinet_row++) {
            var _cabinet_inst = _cabinets[_cabinet_row].inst;
            var _slot = _cabinets[_cabinet_row].slot;
            var _label = "Шкаф кабинета " + string(_slot);

            if (
                instance_exists(_cabinet_inst)
                && variable_instance_exists(_cabinet_inst, "storage_name_ru")
                && _cabinet_inst.storage_name_ru != ""
            ) {
                _label = _cabinet_inst.storage_name_ru;
            }

            var _duplicate = false;

            for (var _slot_index = 0; _slot_index < array_length(_used_slots); _slot_index++) {
                if (_used_slots[_slot_index] == _slot) {
                    _duplicate = true;
                    break;
                }
            }

            if (_duplicate) {
                if (hud_ui_debug_enabled()) {
                    show_debug_message(
                        "[CABINET WARNING] Два шкафа имеют exam_slot_id = "
                        + string(_slot)
                    );
                }
                _label = "[ДУБЛЬ] " + _label;
            }

            array_push(_used_slots, _slot);
            array_push(storage_scope_entries, {
                scope_id : "cab_" + string(_cabinet_inst),
                label_ru : _label,
                cabinet_id : _cabinet_inst,
                slot_id : _slot
            });
        }

        var _panel_x1 = main_panel_x1 + 24;
        var _panel_y1 = main_panel_y1 + 100;
        var _panel_x2 = main_panel_x2 - 24;
        var _panel_y2 = main_panel_y2 - 18;
        var _left_x1 = _panel_x1;
        var _left_y1 = _panel_y1;
        var _left_x2 = _left_x1 + 230;
        var _left_y2 = _panel_y2;
        var _right_x1 = _left_x2 + 18;
        var _right_y1 = _panel_y1;
        var _right_x2 = _panel_x2;
        var _right_y2 = _panel_y2;

        // Пакет №119: колонки на матовом стекле (было — непрозрачная бумага).
        hud_frosted_fill(_left_x1, _left_y1, _left_x2, _left_y2, 10);
        hud_frosted_fill(_right_x1, _right_y1, _right_x2, _right_y2, 10);
        draw_set_color(_paper_2);
        draw_roundrect_ext(_left_x1, _left_y1, _left_x2, _left_y2, 10, 10, true);
        draw_roundrect_ext(_right_x1, _right_y1, _right_x2, _right_y2, 10, 10, true);

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_text_dark);
        draw_text(_left_x1 + 10, _left_y1 + 14, "ХРАНИЛИЩА");

        var _selected_label = "СКЛАД";
        var _selected_inventory = global.inventory_main;
        var _selected_cabinet = noone;
        var _selection_found = false;

        for (var _select_index = 0; _select_index < array_length(storage_scope_entries); _select_index++) {
            var _select_entry = storage_scope_entries[_select_index];

            if (_select_entry.scope_id != storage_scope_selected) continue;

            _selection_found = true;
            _selected_label = _select_entry.label_ru;

            if (_select_entry.scope_id == "main") {
                storage_scope_selected_inst = noone;
            }
            else if (
                instance_exists(_select_entry.cabinet_id)
                && variable_instance_exists(_select_entry.cabinet_id, "storage_inventory")
                && is_struct(_select_entry.cabinet_id.storage_inventory)
            ) {
                _selected_inventory = _select_entry.cabinet_id.storage_inventory;
                _selected_cabinet = _select_entry.cabinet_id;
                storage_scope_selected_inst = _select_entry.cabinet_id;
            }
            else {
                storage_scope_selected = "main";
                storage_scope_selected_inst = noone;
                _selected_label = "СКЛАД";
                _selected_inventory = global.inventory_main;
            }
            break;
        }

        if (!_selection_found) {
            storage_scope_selected = "main";
            storage_scope_selected_inst = noone;
        }

        var _is_main_storage = storage_scope_selected == "main";

        // ─────────────────────────────────────────────
        // ПАКЕТ №70: ПРОКРУТКА СПИСКА ХРАНИЛИЩ (левая колонка)
        // ─────────────────────────────────────────────
        var _scope_row_height = 36;
        var _scope_start_y = _left_y1 + 36;
        var _scope_view_bottom = _left_y2 - 8;
        var _scope_visible_count = max(
            1,
            floor((_scope_view_bottom - _scope_start_y) / _scope_row_height)
        );
        var _scope_max_scroll = max(
            0,
            array_length(storage_scope_entries) - _scope_visible_count
        );
        storage_scope_scroll = clamp(storage_scope_scroll, 0, _scope_max_scroll);

        var _scope_in_rect = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _left_x1,
            _left_y1,
            _left_x2,
            _left_y2
        );

        if (_scope_in_rect) {
            if (mouse_wheel_down()) {
                storage_scope_scroll = min(_scope_max_scroll, storage_scope_scroll + 1);
            }
            if (mouse_wheel_up()) {
                storage_scope_scroll = max(0, storage_scope_scroll - 1);
            }
        }

        var _pointer_pressed = mouse_check_button_pressed(mb_left)
            || device_mouse_check_button_pressed(0, mb_left);
        var _pointer_down = mouse_check_button(mb_left)
            || device_mouse_check_button(0, mb_left);
        var _pointer_released = mouse_check_button_released(mb_left)
            || device_mouse_check_button_released(0, mb_left);

        if (_pointer_pressed && _scope_in_rect) {
            storage_scope_touch_active = true;
            storage_scope_touch_last_y = _mouse_y;
            storage_scope_touch_accum = 0;
        }

        if (storage_scope_touch_active) {
            if (_pointer_down) {
                var _scope_delta = _mouse_y - storage_scope_touch_last_y;
                storage_scope_touch_accum += _scope_delta;

                while (storage_scope_touch_accum <= -30) {
                    storage_scope_scroll = min(_scope_max_scroll, storage_scope_scroll + 1);
                    storage_scope_touch_accum += 30;
                }

                while (storage_scope_touch_accum >= 30) {
                    storage_scope_scroll = max(0, storage_scope_scroll - 1);
                    storage_scope_touch_accum -= 30;
                }

                storage_scope_touch_last_y = _mouse_y;
            }

            if (_pointer_released || !_pointer_down) {
                storage_scope_touch_active = false;
                storage_scope_touch_accum = 0;
            }
        }

        for (var _scope_vis = 0; _scope_vis < _scope_visible_count; _scope_vis++) {
            var _scope_index = storage_scope_scroll + _scope_vis;
            if (_scope_index >= array_length(storage_scope_entries)) break;

            var _scope_entry = storage_scope_entries[_scope_index];
            var _scope_y1 = _scope_start_y + _scope_vis * _scope_row_height;
            var _scope_y2 = _scope_y1 + 28;
            var _scope_x1 = _left_x1 + 8;
            var _scope_x2 = _left_x2 - 8;

            var _scope_selected = storage_scope_selected == _scope_entry.scope_id;
            var _scope_hovered = point_in_rectangle(
                _mouse_x,
                _mouse_y,
                _scope_x1,
                _scope_y1,
                _scope_x2,
                _scope_y2
            );

            if (_scope_hovered) storage_scope_row_hover = _scope_index;

            draw_set_color(
                _scope_selected
                    ? _paper_active
                    : (_scope_hovered ? _paper_hover : _paper)
            );
            draw_roundrect_ext(_scope_x1, _scope_y1, _scope_x2, _scope_y2, 8, 8, false);
            draw_set_color(_line_dark);
            draw_roundrect_ext(_scope_x1, _scope_y1, _scope_x2, _scope_y2, 8, 8, true);
            draw_set_color(_text_dark);
            draw_text(_scope_x1 + 8, _scope_y1 + 6, _scope_entry.label_ru);

            if (
                _scope_hovered
                && tablet_click_lock <= 0
                && mouse_check_button_pressed(mb_left)
            ) {
                tablet_click_lock = 5;
                storage_scope_selected = _scope_entry.scope_id;
                storage_scope_selected_inst = (_scope_entry.scope_id == "main")
                    ? noone
                    : _scope_entry.cabinet_id;
            }
        }

        // Пакет №70: бегунок списка хранилищ.
        storage_draw_scrollbar(
            _left_x2 - 8,
            _scope_start_y,
            _scope_view_bottom,
            storage_scope_scroll,
            _scope_max_scroll,
            _scope_visible_count,
            array_length(storage_scope_entries)
        );

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_text_dark);
        draw_text(_right_x1 + 10, _right_y1 + 8, _selected_label);
        draw_set_color(_text_soft);

        if (_is_main_storage) {
            draw_text_ext(
                _right_x1 + 10,
                _right_y1 + 28,
                "Здесь можно закупить препараты. Кабинетные шкафы автоматически пополняются ассистентом.",
                18,
                _right_x2 - _right_x1 - 20
            );
        }
        else {
            draw_text_ext(
                _right_x1 + 10,
                _right_y1 + 28,
                "Это кабинетный шкаф. Препараты сюда приносит ассистент.\nКупить препараты можно на СКЛАДЕ.",
                18,
                _right_x2 - _right_x1 - 20
            );

            var _link_text = "► Перейти к СКЛАДУ для закупки";
            var _link_x1 = _right_x1 + 10;
            var _link_y1 = _right_y1 + 64;
            var _link_x2 = _link_x1 + string_width(_link_text) + 6;
            var _link_y2 = _link_y1 + string_height(_link_text);
            var _link_hover = point_in_rectangle(
                _mouse_x,
                _mouse_y,
                _link_x1,
                _link_y1,
                _link_x2,
                _link_y2
            );

            draw_set_color(
                _link_hover
                    ? _accent_blue
                    : make_color_rgb(50, 90, 140)
            );
            draw_text(_link_x1, _link_y1, _link_text);

            if (
                _link_hover
                && tablet_click_lock <= 0
                && mouse_check_button_pressed(mb_left)
            ) {
                tablet_click_lock = 5;
                storage_scope_selected = "main";
                storage_scope_selected_inst = noone;
            }
        }

        // Пакет №70: нижняя граница списка препаратов (над блоком «НУЖНО ДОКУПИТЬ»).
        var _shortage_y = _right_y2 - 140;

        if (array_length(global.item_ids) > 0) {
            // Пакет №71: скидка аптеки на закупку препаратов.
            var _pharmacy_discount = clinic_get_pharmacy_discount_percent();
            var _list_top_y = _right_y1 + 100;
            var _column_start = _right_x1 + 14;
            var _column_gap = 10;
            var _font_scale = 1.3;
            var _max_name_width = 0;

            for (var _measure_index = 0; _measure_index < array_length(global.item_ids); _measure_index++) {
                var _measure_id = global.item_ids[_measure_index];
                var _measure_data = variable_struct_get(global.item_db, _measure_id);
                _max_name_width = max(
                    _max_name_width,
                    string_width(_measure_data.name_ru) * _font_scale
                );
            }

            _max_name_width += 4;

            var _name_x = _column_start;
            var _quantity_x = _name_x + _max_name_width + _column_gap;
            var _price_x = _quantity_x + string_width("999 шт.") * _font_scale + _column_gap;
            var _buy_button_x1 = _price_x + string_width("$ 999") * _font_scale + _column_gap;
            var _buy_button_w = (string_width("КУПИТЬ") + 24) * _font_scale;
            var _buy_button_x2 = _buy_button_x1 + _buy_button_w;
            var _buy_button_h = (string_height("КУПИТЬ") + 10) * _font_scale;

            draw_set_color(_text_dark);
            draw_text_transformed(_name_x, _list_top_y, "ПРЕПАРАТ", 1.1, 1.1, 0);
            draw_text_transformed(_quantity_x, _list_top_y, "ОСТАТОК", 1.1, 1.1, 0);
            draw_text_transformed(_price_x, _list_top_y, "ЦЕНА", 1.1, 1.1, 0);
            draw_set_color(_paper_2);
            draw_line(_right_x1 + 10, _list_top_y + 20, _right_x2 - 10, _list_top_y + 20);

            // ─────────────────────────────────────────────
            // ПАКЕТ №70: ПРОКРУТКА СПИСКА ПРЕПАРАТОВ (правая колонка)
            // ─────────────────────────────────────────────
            var _item_row_height = 44;
            var _items_view_top = _list_top_y + 26;
            var _items_view_bottom = _shortage_y - 8;
            var _items_visible = max(
                1,
                floor((_items_view_bottom - _items_view_top) / _item_row_height)
            );
            var _items_max_scroll = max(
                0,
                array_length(global.item_ids) - _items_visible
            );
            storage_items_scroll = clamp(storage_items_scroll, 0, _items_max_scroll);

            var _items_in_rect = point_in_rectangle(
                _mouse_x,
                _mouse_y,
                _right_x1,
                _items_view_top,
                _right_x2,
                _items_view_bottom
            );

            if (_items_in_rect) {
                if (mouse_wheel_down()) {
                    storage_items_scroll = min(_items_max_scroll, storage_items_scroll + 1);
                }
                if (mouse_wheel_up()) {
                    storage_items_scroll = max(0, storage_items_scroll - 1);
                }
            }

            if (_pointer_pressed && _items_in_rect) {
                storage_items_touch_active = true;
                storage_items_touch_last_y = _mouse_y;
                storage_items_touch_accum = 0;
            }

            if (storage_items_touch_active) {
                if (_pointer_down) {
                    var _items_delta = _mouse_y - storage_items_touch_last_y;
                    storage_items_touch_accum += _items_delta;

                    while (storage_items_touch_accum <= -30) {
                        storage_items_scroll = min(_items_max_scroll, storage_items_scroll + 1);
                        storage_items_touch_accum += 30;
                    }

                    while (storage_items_touch_accum >= 30) {
                        storage_items_scroll = max(0, storage_items_scroll - 1);
                        storage_items_touch_accum -= 30;
                    }

                    storage_items_touch_last_y = _mouse_y;
                }

                if (_pointer_released || !_pointer_down) {
                    storage_items_touch_active = false;
                    storage_items_touch_accum = 0;
                }
            }

            for (var _item_vis = 0; _item_vis < _items_visible; _item_vis++) {
                var _item_index = storage_items_scroll + _item_vis;
                if (_item_index >= array_length(global.item_ids)) break;

                var _item_id = global.item_ids[_item_index];
                var _item_data = variable_struct_get(global.item_db, _item_id);
                var _item_y = _items_view_top + _item_vis * _item_row_height;
                var _quantity = inventory_get_amount(_selected_inventory, _item_id);
                var _purchase_price = _item_data.buy_price;
                var _effective_price = max(
                    1,
                    round(_purchase_price * (100 - _pharmacy_discount) / 100)
                );
                var _item_row_y1 = _item_y - 3;
                var _item_row_y2 = _item_y + _item_row_height - 5;

                draw_set_color(
                    (_item_index mod 2 == 0)
                        ? make_color_rgb(246, 240, 228)
                        : make_color_rgb(238, 230, 215)
                );
                draw_roundrect_ext(_right_x1 + 8, _item_row_y1, _right_x2 - 8, _item_row_y2, 6, 6, false);
                draw_set_color(make_color_rgb(200, 188, 170));
                draw_line(_right_x1 + 8, _item_row_y2, _right_x2 - 8, _item_row_y2);

                draw_set_halign(fa_left);
                draw_set_valign(fa_top);
                draw_set_color(_text_dark);
                draw_text_transformed(_name_x, _item_y, _item_data.name_ru, _font_scale, _font_scale, 0);
                draw_set_color(_text_soft);
                draw_text_transformed(_quantity_x, _item_y, string(_quantity) + " шт.", _font_scale, _font_scale, 0);
                draw_set_color(_pharmacy_discount > 0
                    ? make_color_rgb(62, 112, 74)
                    : _text_soft);
                draw_text_transformed(_price_x, _item_y, "$ " + string(_effective_price), _font_scale, _font_scale, 0);

                if (_is_main_storage) {
                    var _buy_y1 = _item_y - 4;
                    var _buy_y2 = _buy_y1 + _buy_button_h;
                    var _buy_hover = point_in_rectangle(
                        _mouse_x,
                        _mouse_y,
                        _buy_button_x1,
                        _buy_y1,
                        _buy_button_x2,
                        _buy_y2
                    );

                    array_push(stock_buy_buttons, {
                        item_id : _item_id,
                        x1 : _buy_button_x1,
                        y1 : _buy_y1,
                        x2 : _buy_button_x2,
                        y2 : _buy_y2
                    });

                    if (_buy_hover) stock_buy_hover_index = _item_index;

                    draw_set_color(_wood_dark);
                    draw_roundrect_ext(_buy_button_x1, _buy_y1, _buy_button_x2, _buy_y2, 8, 8, false);
                    draw_set_color(_wood_light);
                    draw_roundrect_ext(_buy_button_x1 + 2, _buy_y1 + 2, _buy_button_x2 - 2, _buy_y2 - 2, 6, 6, false);
                    draw_set_color(_buy_hover ? _paper_hover : _paper);
                    draw_roundrect_ext(_buy_button_x1 + 5, _buy_y1 + 5, _buy_button_x2 - 5, _buy_y2 - 5, 5, 5, false);
                    draw_set_color(_line_dark);
                    draw_roundrect_ext(_buy_button_x1, _buy_y1, _buy_button_x2, _buy_y2, 8, 8, true);
                    draw_set_halign(fa_center);
                    draw_set_valign(fa_middle);
                    draw_set_color(_text_dark);
                    draw_text_transformed(
                        (_buy_button_x1 + _buy_button_x2) * 0.5,
                        (_buy_y1 + _buy_y2) * 0.5,
                        "КУПИТЬ",
                        _font_scale,
                        _font_scale,
                        0
                    );

                    if (
                        _buy_hover
                        && tablet_click_lock <= 0
                        && mouse_check_button_pressed(mb_left)
                    ) {
                        tablet_click_lock = 5;
                        var _buy_quantity = global.storage_buy_batch;
                        var _cost = _effective_price * _buy_quantity;

                        // Пакет №84: ограничение закупки по ёмкости полки.
                        // Одна коробочка = 1 единица; ёмкость = максимум коробочек.
                        var _shelf_capacity = storage_shelf_box_max();
                        var _shelf_current = inventory_get_amount(
                            global.inventory_main,
                            _item_id
                        );
                        var _shelf_free = _shelf_capacity - _shelf_current;

                        if (_shelf_free < _buy_quantity) {
                            show_notice(
                                "СКЛАД ПОЛОН",
                                _item_data.name_ru
                                    + ": нет места ("
                                    + string(_shelf_capacity)
                                    + " макс.)",
                                _fps * 2
                            );
                        }
                        else if (global.clinic_money >= _cost) {
                            global.clinic_money -= _cost;

                            if (variable_global_exists("daily_stats")) {
                                global.daily_stats.spent_money += _cost;
                            }

                            inventory_add_amount(
                                global.inventory_main,
                                _item_id,
                                _buy_quantity
                            );
                            show_notice(
                                "ЗАКУПКА",
                                _item_data.name_ru + " +" + string(_buy_quantity),
                                _fps * 2
                            );
                        }
                        else {
                            show_notice(
                                "НЕ ХВАТАЕТ ДЕНЕГ",
                                _item_data.name_ru,
                                _fps * 2
                            );
                        }
                    }
                }
            }

            // Пакет №70: бегунок списка препаратов.
            storage_draw_scrollbar(
                _right_x2 - 8,
                _items_view_top,
                _items_view_bottom,
                storage_items_scroll,
                _items_max_scroll,
                _items_visible,
                array_length(global.item_ids)
            );
        }

        var _shortages = inventory_collect_shortages();
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_paper_2);
        draw_line(_right_x1 + 10, _shortage_y - 8, _right_x2 - 10, _shortage_y - 8);
        draw_set_color(_text_dark);
        draw_text(_right_x1 + 10, _shortage_y, "НУЖНО ДОКУПИТЬ");

        if (array_length(_shortages) <= 0) {
            draw_set_color(_text_soft);
            draw_text_ext(
                _right_x1 + 10,
                _shortage_y + 24,
                "Все текущие назначения обеспечены препаратами.",
                18,
                _right_x2 - _right_x1 - 20
            );
        }
        else {
            for (var _shortage_index = 0; _shortage_index < array_length(_shortages); _shortage_index++) {
                var _shortage = _shortages[_shortage_index];
                var _shortage_row_y = _shortage_y + 24 + _shortage_index * 20;
                draw_set_color(_text_dark);
                draw_text(_right_x1 + 10, _shortage_row_y, _shortage.item_name_ru);
                draw_set_color(_accent_red);
                draw_text(_right_x1 + 230, _shortage_row_y, "Не хватает: " + string(_shortage.shortage));
            }
        }
    }
}
