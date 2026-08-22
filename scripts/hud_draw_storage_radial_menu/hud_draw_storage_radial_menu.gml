/// hud_draw_storage_radial_menu.gml
/// @description Компактное меню склада/шкафа и ручной перенос препаратов.
/// Пакет №120: меню на матовом стекле (дерево только рамкой).

function hud_draw_storage_radial_menu(_hud) {
    if (!instance_exists(_hud)) return;
    if (!variable_global_exists("radial_open") || !global.radial_open) return;
    if (!instance_exists(global.radial_target)) return;

    with (_hud) {
        var _target = global.radial_target;
        var _mouse_x = device_mouse_x_to_gui(0);
        var _mouse_y = device_mouse_y_to_gui(0);
        var _fps = hud_ui_fps();
        var _wood_dark = make_color_rgb(74, 49, 31);
        var _wood_light = make_color_rgb(150, 107, 73);
        var _paper = make_color_rgb(242, 232, 214);
        var _paper_hover = make_color_rgb(252, 244, 226);
        var _paper_disabled = make_color_rgb(220, 210, 190);
        var _line_dark = make_color_rgb(58, 39, 24);
        var _text_dark = make_color_rgb(50, 38, 28);
        var _text_soft = make_color_rgb(130, 110, 85);
        var _green = make_color_rgb(62, 112, 74);
        var _is_cabinet = _target.object_index == obj_storage_cabinet
            || object_is_ancestor(_target.object_index, obj_storage_cabinet);
        var _open_label = _is_cabinet ? "ОТКРЫТЬ ШКАФ" : "ОТКРЫТЬ СКЛАД";
        var _camera = view_camera[0];
        var _view_w = camera_get_view_width(_camera);
        var _view_h = camera_get_view_height(_camera);
        var _view_x = camera_get_view_x(_camera);
        var _view_y = camera_get_view_y(_camera);
        var _gui_w = max(1, display_get_gui_width());
        var _gui_h = max(1, display_get_gui_height());
        var _anchor_x = (_target.x - _view_x) * (_gui_w / _view_w);
        var _anchor_y = (_target.y - 110 - _view_y) * (_gui_h / _view_h);

        if (!variable_global_exists("menu_scroll_offset")) {
            global.menu_scroll_offset = 0;
        }

        var _all_items = [];
        array_push(_all_items, {
            label : _open_label,
            action : "open",
            enabled : true,
            quantity : 0,
            item_id : ""
        });

        if (!_is_cabinet) {
            var _hands_compatible = global.player_carry_item == "";
            var _shown = 0;

            for (var _item_index = 0; _item_index < array_length(global.item_ids); _item_index++) {
                var _item_id = global.item_ids[_item_index];
                var _available = inventory_get_amount(global.inventory_main, _item_id);
                if (_available <= 0) continue;

                var _item_name = variable_struct_get(global.item_db, _item_id).name_ru;
                var _can_take = _hands_compatible
                    || global.player_carry_item == _item_id;

                array_push(_all_items, {
                    label : _item_name,
                    action : "take",
                    item_id : _item_id,
                    enabled : _can_take,
                    quantity : _available
                });
                _shown += 1;
            }

            if (!_hands_compatible && _shown == 0) {
                array_push(_all_items, {
                    label : "- руки заняты -",
                    action : "none",
                    enabled : false,
                    quantity : 0,
                    item_id : ""
                });
            }
        }
        else if (
            global.player_carry_item != ""
            && global.player_carry_qty > 0
        ) {
            var _carried_name = variable_struct_exists(global.item_db, global.player_carry_item)
                ? variable_struct_get(global.item_db, global.player_carry_item).name_ru
                : "препарат";

            array_push(_all_items, {
                label : "ПОЛОЖИТЬ "
                    + _carried_name
                    + " "
                    + string(global.player_carry_qty)
                    + " шт.",
                action : "put",
                enabled : true,
                quantity : global.player_carry_qty,
                item_id : global.player_carry_item
            });
        }
        else {
            array_push(_all_items, {
                label : "- нечего класть -",
                action : "none",
                enabled : false,
                quantity : 0,
                item_id : ""
            });
        }

        var _max_visible = 4;
        var _scrollable_count = max(0, array_length(_all_items) - 1);
        var _needs_scroll = _scrollable_count > _max_visible;
        var _max_offset = max(0, _scrollable_count - _max_visible);
        global.menu_scroll_offset = clamp(global.menu_scroll_offset, 0, _max_offset);

        var _visible_items = [_all_items[0]];
        var _start_index = _needs_scroll
            ? 1 + global.menu_scroll_offset
            : 1;
        var _end_index = _needs_scroll
            ? min(array_length(_all_items), _start_index + _max_visible)
            : array_length(_all_items);

        for (var _visible_index = _start_index; _visible_index < _end_index; _visible_index++) {
            array_push(_visible_items, _all_items[_visible_index]);
        }

        var _padding = 10;
        var _button_height = 40;
        var _button_gap = 8;
        var _inner_width = 240;
        var _scroll_height = _needs_scroll ? 34 : 0;
        var _button_count = array_length(_visible_items);
        var _panel_width = _inner_width + _padding * 2;
        var _panel_height = _button_count * _button_height
            + (_button_count - 1) * _button_gap
            + _scroll_height
            + _padding * 2;
        var _panel_x = clamp(
            _anchor_x - _panel_width * 0.5,
            10,
            _gui_w - _panel_width - 10
        );
        var _panel_y = clamp(
            _anchor_y - _panel_height,
            10,
            _gui_h - _panel_height - 30
        );

        global.radial_panel_x1 = _panel_x;
        global.radial_panel_y1 = _panel_y;
        global.radial_panel_x2 = _panel_x + _panel_width;
        global.radial_panel_y2 = _panel_y + _panel_height;
        global.radial_x = _anchor_x;
        global.radial_y = _anchor_y;

        // Пакет №120: матовое стекло + деревянная рамка по краю.
        hud_draw_frosted_panel(
            _panel_x,
            _panel_y,
            _panel_x + _panel_width,
            _panel_y + _panel_height,
            8
        );

        var _hovered_index = -1;

        for (var _button_index = 0; _button_index < _button_count; _button_index++) {
            var _menu_item = _visible_items[_button_index];
            var _button_x1 = _panel_x + _padding;
            var _button_y1 = _panel_y + _padding + _button_index * (_button_height + _button_gap);
            var _button_x2 = _button_x1 + _inner_width;
            var _button_y2 = _button_y1 + _button_height;
            var _hovered = _menu_item.enabled
                && point_in_rectangle(_mouse_x, _mouse_y, _button_x1, _button_y1, _button_x2, _button_y2);

            if (_hovered) _hovered_index = _button_index;

            draw_set_color(
                _menu_item.enabled
                    ? (_hovered ? _paper_hover : _paper)
                    : _paper_disabled
            );
            draw_roundrect_ext(_button_x1, _button_y1, _button_x2, _button_y2, 8, 8, false);
            draw_set_color(_line_dark);
            draw_roundrect_ext(_button_x1, _button_y1, _button_x2, _button_y2, 8, 8, true);
            draw_set_halign(fa_left);
            draw_set_valign(fa_middle);
            draw_set_color(_menu_item.enabled ? _text_dark : _text_soft);
            // Пакет №175: название и количество крупно, каждое в своей зоне.
            var _label_w = (_button_x2 - _button_x1) * 0.62 - 20;
            ui_text_fit_middle(
                _button_x1 + 12,
                (_button_y1 + _button_y2) * 0.5 + 1,
                _menu_item.label,
                _label_w,
                UI_FS_ROW
            );

            if (_menu_item.quantity > 0) {
                draw_set_halign(fa_right);
                draw_set_color(_menu_item.enabled ? _green : _text_soft);
                ui_text_fit_right(
                    _button_x2 - 12,
                    (_button_y1 + _button_y2) * 0.5 + 1,
                    string(_menu_item.quantity) + " шт.",
                    (_button_x2 - _button_x1) * 0.34,
                    UI_FS_VALUE
                );
            }
        }

        var _up_hovered = false;
        var _down_hovered = false;

        if (_needs_scroll) {
            var _arrow_y1 = _panel_y + _padding + _button_count * (_button_height + _button_gap) - _button_gap;
            var _arrow_gap = 8;
            var _arrow_width = (_inner_width - _arrow_gap) * 0.5;
            var _arrow_y2 = _arrow_y1 + _scroll_height - 4;
            var _up_x1 = _panel_x + _padding;
            var _up_x2 = _up_x1 + _arrow_width;
            var _down_x1 = _up_x2 + _arrow_gap;
            var _down_x2 = _down_x1 + _arrow_width;
            var _can_up = global.menu_scroll_offset > 0;
            var _can_down = global.menu_scroll_offset < _max_offset;

            _up_hovered = _can_up && point_in_rectangle(_mouse_x, _mouse_y, _up_x1, _arrow_y1, _up_x2, _arrow_y2);
            _down_hovered = _can_down && point_in_rectangle(_mouse_x, _mouse_y, _down_x1, _arrow_y1, _down_x2, _arrow_y2);

            hud_draw_button(_up_x1, _arrow_y1, _up_x2, _arrow_y2, "ВВЕРХ", false, _up_hovered, _paper, _paper_hover, _paper_hover, _line_dark, _can_up ? _text_dark : _text_soft);
            hud_draw_button(_down_x1, _arrow_y1, _down_x2, _arrow_y2, "ВНИЗ", false, _down_hovered, _paper, _paper_hover, _paper_hover, _line_dark, _can_down ? _text_dark : _text_soft);
        }

        if (tablet_click_lock > 0 || !mouse_check_button_pressed(mb_left)) return;

        var _inside_panel = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _panel_x,
            _panel_y,
            _panel_x + _panel_width,
            _panel_y + _panel_height
        );

        if (_needs_scroll && _up_hovered) {
            tablet_click_lock = 5;
            global.menu_scroll_offset -= 1;
            return;
        }

        if (_needs_scroll && _down_hovered) {
            tablet_click_lock = 5;
            global.menu_scroll_offset += 1;
            return;
        }

        var _action_completed = false;

        if (_hovered_index >= 0) {
            var _selected = _visible_items[_hovered_index];
            tablet_click_lock = 5;
            _action_completed = true;

            switch (_selected.action) {
                case "open":
                    clinic_panel_open = true;
                    clients_panel_open = false;
                    staff_panel_open = false;
                    finance_panel_open = false;
                    clinic_subtab = "storage";

                    if (_is_cabinet) {
                        storage_scope_selected = "cab_" + string(_target);
                        storage_scope_selected_inst = _target;
                        show_notice("СКЛАД", "Открыт " + (variable_instance_exists(_target, "storage_name_ru") ? _target.storage_name_ru : "шкаф"), _fps);
                    }
                    else {
                        storage_scope_selected = "main";
                        storage_scope_selected_inst = noone;
                        show_notice("СКЛАД", "Открыт склад", _fps);
                    }
                break;

                case "take":
                    if (
                        global.player_carry_item != ""
                        && global.player_carry_item != _selected.item_id
                    ) {
                        show_notice("ЗАНЯТО", "Сначала положи то, что несёшь", _fps * 2);
                        break;
                    }

                    var _available_now = inventory_get_amount(global.inventory_main, _selected.item_id);
                    var _space = global.PLAYER_CARRY_MAX
                        - ((global.player_carry_item == _selected.item_id) ? global.player_carry_qty : 0);
                    var _take_amount = min(_space, _available_now);

                    if (_take_amount <= 0) {
                        show_notice("РУКИ ПОЛНЫЕ", "Уже несёшь максимум", _fps * 2);
                        break;
                    }

                    inventory_remove_amount(global.inventory_main, _selected.item_id, _take_amount);
                    global.player_carry_item = _selected.item_id;
                    global.player_carry_qty += _take_amount;
                    show_notice("В РУКАХ", item_get_name(_selected.item_id) + " " + string(global.player_carry_qty) + " шт.", _fps * 2);
                    global.menu_scroll_offset = 0;
                break;

                case "put":
                    if (!_is_cabinet) break;
                    if (global.player_carry_item == "" || global.player_carry_qty <= 0) break;

                    if (
                        !variable_instance_exists(_target, "storage_inventory")
                        || !is_struct(_target.storage_inventory)
                    ) {
                        _target.storage_inventory = {};
                    }

                    var _put_id = global.player_carry_item;
                    var _cabinet_space = global.RESTOCK_MAX
                        - inventory_get_amount(_target.storage_inventory, _put_id);
                    var _put_amount = min(global.player_carry_qty, max(0, _cabinet_space));

                    if (_put_amount <= 0) {
                        show_notice("ШКАФ ПОЛОН", "Препарат больше не помещается", _fps * 2);
                        break;
                    }

                    inventory_add_amount(_target.storage_inventory, _put_id, _put_amount);
                    global.player_carry_qty -= _put_amount;

                    if (instance_exists(obj_player)) {
                        var _player = instance_find(obj_player, 0);
                        player_add_assistant_skill_xp(_player, 1, 2, true);

                        with (_player) {
                            add_xp_log("+2 ПОПОЛНЕНИЕ");
                        }
                    }

                    if (global.player_carry_qty <= 0) {
                        global.player_carry_item = "";
                        global.player_carry_qty = 0;
                    }

                    show_notice("ПОЛОЖИЛ", item_get_name(_put_id) + " +" + string(_put_amount) + " шт.", _fps * 2);
                break;
            }
        }

        if (_action_completed || !_inside_panel) {
            tablet_click_lock = 5;
            global.radial_open = false;
            global.radial_target = noone;
            global.ui_block_world_click = false;
            if (!_inside_panel) global.menu_scroll_offset = 0;
        }
    }
}
