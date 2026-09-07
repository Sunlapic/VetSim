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
        // Пакет №173 (правка): заголовок справа от вкладок — под ними теперь
        // сразу начинается содержимое, налезать нечему.
        draw_set_valign(fa_middle);
        draw_text_transformed(
            clinic_tab_storage_x2 + 26,
            (clinic_tab_clinic_y1 + clinic_tab_clinic_y2) * 0.5,
            "КЛИНИКА",
            1.5,
            1.5,
            0
        );
        draw_set_valign(fa_top);

        // Пакет №173: крупные вкладки с увеличенным шрифтом.
        ui_draw_tab(
            clinic_tab_clinic_x1,
            clinic_tab_clinic_y1,
            clinic_tab_clinic_x2,
            clinic_tab_clinic_y2,
            "РАЗВИТИЕ",
            clinic_subtab == "clinic",
            hover_clinic_tab_clinic
        );
        ui_draw_tab(
            clinic_tab_storage_x1,
            clinic_tab_storage_y1,
            clinic_tab_storage_x2,
            clinic_tab_storage_y2,
            "СКЛАД",
            clinic_subtab == "storage",
            hover_clinic_tab_storage
        );

        // Пакет №194: крестик закрытия — такой же, как в окне ПЕРСОНАЛ.
        var _clinic_close_hover = ui_draw_panel_close(
            main_panel_x1,
            main_panel_y1,
            main_panel_x2,
            main_panel_y2,
            _mouse_x,
            _mouse_y
        );

        if (_clinic_close_hover && hud_staff_manage_pointer_pressed()) {
            clinic_panel_open = false;
            return;
        }

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

        // Пакет №203: левая колонка ровно такая же, как список клиентов и
        // список персонала: отступ 28, ширина 470, верх +122, низ -32.
        // При переключении между окнами ничего не прыгает.
        var _panel_x1 = main_panel_x1 + 28;
        var _panel_y1 = main_panel_y1 + 122;
        var _panel_x2 = main_panel_x2 - 28;
        var _panel_y2 = main_panel_y2 - 32;
        var _left_x1 = _panel_x1;
        var _left_y1 = _panel_y1;
        var _left_x2 = _left_x1 + 470;
        var _left_y2 = _panel_y2;
        var _right_x1 = _left_x2 + 20;
        var _right_y1 = _panel_y1;
        var _right_x2 = _panel_x2;
        var _right_y2 = _panel_y2;

        // Пакет №119: колонки на матовом стекле (было — непрозрачная бумага).
        hud_frosted_fill(_left_x1, _left_y1, _left_x2, _left_y2, 10);
        hud_frosted_fill(_right_x1, _right_y1, _right_x2, _right_y2, 10);
        draw_set_color(_paper_2);
        draw_roundrect_ext(_left_x1, _left_y1, _left_x2, _left_y2, 10, 10, true);
        draw_roundrect_ext(_right_x1, _right_y1, _right_x2, _right_y2, 10, 10, true);

        // Пакет №204: подпись «ХРАНИЛИЩА» убрана — список начинается сразу
        // от верха колонки и занимает её целиком.
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

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
        // Пакет №175: строки выше — крупный шрифт помещается целиком.
        // Пакет №203: строка хранилища крупная, как карточка клиента.
        var _scope_row_height = 84;
        var _scope_start_y = _left_y1 + 12;
        var _scope_view_bottom = _left_y2 - 10;
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

        // Пакет №209: списки обрезаются по своей области.
        ui_clip_begin(_left_x1, _scope_start_y - 4, _left_x2, _scope_view_bottom);

        for (var _scope_vis = 0; _scope_vis < _scope_visible_count + 1; _scope_vis++) {
            var _scope_index = storage_scope_scroll + _scope_vis;
            if (_scope_index >= array_length(storage_scope_entries)) break;

            var _scope_entry = storage_scope_entries[_scope_index];
            var _scope_y1 = _scope_start_y + _scope_vis * _scope_row_height;
            var _scope_y2 = _scope_y1 + _scope_row_height - 12;
            var _scope_x1 = _left_x1 + 10;
            var _scope_x2 = _left_x2 - 24;

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
            // Выбранное хранилище отмечено полосой слева — как у клиентов.
            if (_scope_selected) {
                draw_set_color(make_color_rgb(180, 140, 64));
                draw_roundrect_ext(_scope_x1, _scope_y1, _scope_x1 + 7, _scope_y2, 4, 4, false);
            }

            draw_set_color(_text_dark);
            ui_text_row(
                _scope_x1 + 18,
                _scope_y1,
                _scope_y2 - _scope_y1,
                _scope_entry.label_ru,
                (_scope_x2 - _scope_x1) - 34,
                UI_FS_HEADER
            );

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

        ui_clip_end();

        // Пакет №70: бегунок списка хранилищ.
        storage_draw_scrollbar(
            _left_x2 - 16,
            _scope_start_y,
            _scope_view_bottom,
            storage_scope_scroll,
            _scope_max_scroll,
            _scope_visible_count,
            array_length(storage_scope_entries)
        );

        // Пакет №204: справа теперь только таблица — ни заголовка, ни
        // пояснений, ни ссылки. Что за хранилище открыто, видно по
        // подсвеченной строке в списке слева. Освободившееся место
        // отдано списку препаратов.
        //
        // Клик по ссылке «Перейти к СКЛАДУ» больше не нужен: склад
        // выбирается первой строкой списка слева.

        // Пакет №70: нижняя граница списка препаратов (над блоком «НУЖНО ДОКУПИТЬ»).
        // Пакет №204: блока «НУЖНО ДОКУПИТЬ» больше нет, список идёт
        // до самого низа колонки.
        var _shortage_y = _right_y2 - 6;

        // ПАКЕТ №311: в закупке показываем только те препараты, что
        // нужны этой клинике. Без операционной наркоз, хирургический
        // набор и паста для УЗ-чистки не предлагаются — покупать их
        // некуда и незачем.
        if (array_length(storage_purchase_item_ids()) > 0) {
            // Пакет №71: скидка аптеки на закупку препаратов.
            var _pharmacy_discount = clinic_get_pharmacy_discount_percent();
            // ═══════════════════════════════════════════════════
            // Пакет №203: КОЛОНКИ РАЗНЕСЕНЫ ПО ШИРИНЕ
            //
            // Раньше «ОСТАТОК» и «ЦЕНА» ставились впритык друг к другу:
            // ширина считалась по самому длинному названию препарата плюс
            // 10 пикселей. Стоило названию быть длинным — и колонки
            // налезали одна на другую.
            //
            // Теперь у каждой колонки своя доля ширины окна, а места
            // справа хватает с запасом — оно всё равно пустовало.
            // ═══════════════════════════════════════════════════

            var _list_top_y = _right_y1 + 14;
            var _right_w = _right_x2 - _right_x1;
            var _font_scale = 1.45;

            var _name_x = _right_x1 + 20;
            var _quantity_x = _right_x1 + _right_w * 0.46;
            var _price_x = _right_x1 + _right_w * 0.64;

            var _buy_button_w = min(220, _right_w * 0.20);
            var _buy_button_x2 = _right_x2 - 20;
            var _buy_button_x1 = _buy_button_x2 - _buy_button_w;
            var _buy_button_h = 56;

            // Название не залезает на «ОСТАТОК» — при необходимости ужмётся.
            var _name_w = (_quantity_x - _name_x) - 16;

            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_set_color(_text_dark);
            draw_text_transformed(_name_x, _list_top_y, "ПРЕПАРАТ", UI_FS_HEADER, UI_FS_HEADER, 0);
            draw_text_transformed(_quantity_x, _list_top_y, "ОСТАТОК", UI_FS_HEADER, UI_FS_HEADER, 0);
            draw_text_transformed(_price_x, _list_top_y, "ЦЕНА", UI_FS_HEADER, UI_FS_HEADER, 0);
            draw_set_color(_paper_2);
            draw_line(_right_x1 + 14, _list_top_y + 34, _right_x2 - 14, _list_top_y + 34);

            // ─────────────────────────────────────────────
            // ПАКЕТ №70: ПРОКРУТКА СПИСКА ПРЕПАРАТОВ (правая колонка)
            // ─────────────────────────────────────────────
            var _item_row_height = 74;
            var _items_view_top = _list_top_y + 46;
            var _items_view_bottom = _shortage_y - 8;
            var _items_visible = max(
                1,
                floor((_items_view_bottom - _items_view_top) / _item_row_height)
            );
            var _items_max_scroll = max(
                0,
                array_length(storage_purchase_item_ids()) - _items_visible
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

            ui_clip_begin(_right_x1, _items_view_top - 4, _right_x2, _items_view_bottom);

            for (var _item_vis = 0; _item_vis < _items_visible + 1; _item_vis++) {
                var _item_index = storage_items_scroll + _item_vis;
                if (_item_index >= array_length(storage_purchase_item_ids())) break;

                var _item_id = storage_purchase_item_ids()[_item_index];
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

                // Каждая надпись — по центру своей строки, так они не
                // расползаются при разной высоте текста.
                var _row_center_y = (_item_row_y1 + _item_row_y2) * 0.5;
                var _name_scale = ui_fit_scale(_item_data.name_ru, _name_w, _font_scale);

                draw_set_halign(fa_left);
                draw_set_valign(fa_middle);
                draw_set_color(_text_dark);
                draw_text_transformed(_name_x, _row_center_y, _item_data.name_ru, _name_scale, _name_scale, 0);

                draw_set_color(_text_soft);
                draw_text_transformed(_quantity_x, _row_center_y, string(_quantity) + " шт.", _font_scale, _font_scale, 0);

                draw_set_color(_pharmacy_discount > 0
                    ? make_color_rgb(62, 112, 74)
                    : _text_soft);
                draw_text_transformed(_price_x, _row_center_y, "$ " + string(_effective_price), _font_scale, _font_scale, 0);

                draw_set_valign(fa_top);

                if (_is_main_storage) {
                    var _buy_y1 = (_item_row_y1 + _item_row_y2) * 0.5 - _buy_button_h * 0.5;
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
                    ui_text_fit_center(
                        (_buy_button_x1 + _buy_button_x2) * 0.5,
                        (_buy_y1 + _buy_y2) * 0.5,
                        "КУПИТЬ",
                        _buy_button_w - 24,
                        UI_FS_BUTTON
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

            ui_clip_end();

            // Пакет №70: бегунок списка препаратов.
            storage_draw_scrollbar(
                _right_x2 - 8,
                _items_view_top,
                _items_view_bottom,
                storage_items_scroll,
                _items_max_scroll,
                _items_visible,
                array_length(storage_purchase_item_ids())
            );
        }

        // Пакет №204: блок «НУЖНО ДОКУПИТЬ» убран со склада.
        // Нехватка препаратов и так видна: в списке стоит остаток, а при
        // попытке лечения без препарата приходит уведомление.
    }
}
