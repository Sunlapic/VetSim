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

        // ═══════════════════════════════════════════════════════════
        // ПАКЕТ 275: ПЕРЕНОС ПРЕПАРАТОВ ИГРОКОМ УБРАН
        //
        // Здесь строились пункты «взять» (у главного склада) и
        // «ПОЛОЖИТЬ …» (у шкафа), плюс заглушки «- руки заняты -» и
        // «- нечего класть -». Механика убрана по просьбе: препараты
        // по кабинетам разносят только ассистенты через restock.
        //
        // Пункт «открыть» остаётся — смотреть содержимое склада и
        // шкафов по-прежнему нужно.
        //
        // global.player_carry_item / player_carry_qty намеренно НЕ
        // удалены из obj_Render -> Create: на них смотрят
        // par_staff -> Draw (спрайт с коробкой) и obj_player -> Step.
        // Переменные просто всегда пустые, и те ветки не срабатывают.
        // ═══════════════════════════════════════════════════════════

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

                    // ПАКЕТ №313: уведомление «Открыт склад» убрано.
                    //
                    // Оно ничего не сообщало: игрок сам только что нажал
                    // «открыть», и панель склада тут же появляется перед
                    // ним. Зато карточка падала в левый угол при каждом
                    // открытии и мешала.
                    //
                    // Сам выбор области склада остался — он нужен панели,
                    // чтобы понимать, главный это склад или шкаф.
                    if (_is_cabinet) {
                        storage_scope_selected = "cab_" + string(_target);
                        storage_scope_selected_inst = _target;
                    }
                    else {
                        storage_scope_selected = "main";
                        storage_scope_selected_inst = noone;
                    }
                break;

                // ПАКЕТ 275: ветки "take" и "put" удалены вместе с
                // пунктами меню — игрок больше не переносит препараты
                // руками. Разносят только ассистенты (система restock).
                //
                // Заодно ушло начисление опыта ассистента игроку за
                // «положил в шкаф»: такого действия больше нет.
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
