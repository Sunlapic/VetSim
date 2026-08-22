/// hud_draw_clients_database.gml
/// @description База клиентов, история визитов и повторные приёмы.
/// Пакет №120: панель на матовом стекле (дерево только рамкой).

function hud_draw_clients_database(_hud) {
    if (!instance_exists(_hud)) return;
    if (!_hud.clients_panel_open) return;

    with (_hud) {
        var _paper = make_color_rgb(242, 232, 214);
        var _paper_2 = make_color_rgb(232, 220, 198);
        var _paper_hover = make_color_rgb(248, 238, 220);
        var _paper_active = make_color_rgb(220, 202, 172);
        var _wood_dark = make_color_rgb(74, 49, 31);
        var _wood_mid = make_color_rgb(114, 77, 50);
        var _wood_light = make_color_rgb(150, 107, 73);
        var _line_dark = make_color_rgb(58, 39, 24);
        var _text_dark = make_color_rgb(50, 38, 28);
        var _text_soft = make_color_rgb(84, 68, 54);
        var _accent_blue = make_color_rgb(72, 112, 145);
        var _accent_red = make_color_rgb(148, 74, 64);
        var _accent_gold = make_color_rgb(180, 140, 64);
        var _accent_green = make_color_rgb(62, 112, 74);

        hud_draw_frosted_panel(
            clients_panel_x1,
            clients_panel_y1,
            clients_panel_x2,
            clients_panel_y2
        );

        var _content_x1 = clients_panel_x1 + 14;
        var _content_y1 = clients_panel_y1 + 14;
        var _content_x2 = clients_panel_x2 - 14;
        var _content_y2 = clients_panel_y2 - 14;

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_text_dark);
        ui_text_fit_left(_content_x1 + 16, _content_y1 + 8, "БАЗА КЛИЕНТОВ", 520, UI_FS_TITLE);

        hud_draw_button(
            clients_tab_all_x1,
            clients_tab_all_y1,
            clients_tab_all_x2,
            clients_tab_all_y2,
            "ВСЕ",
            clients_subtab == "all",
            hover_clients_tab_all,
            _paper,
            _paper_hover,
            _paper_active,
            _line_dark,
            _text_dark
        );
        hud_draw_button(
            clients_tab_followup_x1,
            clients_tab_followup_y1,
            clients_tab_followup_x2,
            clients_tab_followup_y2,
            "ПОВТОРНЫЙ ПРИЁМ",
            clients_subtab == "followup",
            hover_clients_tab_followup,
            _paper,
            _paper_hover,
            _paper_active,
            _line_dark,
            _text_dark
        );

        draw_set_color(
            (hover_client_search || client_search_active)
                ? _paper_hover
                : _paper
        );
        draw_roundrect_ext(client_search_x1, client_search_y1, client_search_x2, client_search_y2, 10, 10, false);
        draw_set_color(_line_dark);
        draw_roundrect_ext(client_search_x1, client_search_y1, client_search_x2, client_search_y2, 10, 10, true);
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);

        var _search_w = (client_search_x2 - client_search_x1) - 26;

        if (client_search_text == "") {
            draw_set_color(_text_soft);
            ui_text_fit_middle(client_search_x1 + 14, (client_search_y1 + client_search_y2) * 0.5 + 1, "Поиск по фамилии или кличке...", _search_w, UI_FS_ROW);
        }
        else {
            draw_set_color(_text_dark);
            var _search_scale = ui_text_fit_middle(client_search_x1 + 14, (client_search_y1 + client_search_y2) * 0.5 + 1, client_search_text, _search_w, UI_FS_ROW);

            if (client_search_active && client_search_caret_visible) {
                var _caret_x = client_search_x1 + 16 + string_width(client_search_text) * _search_scale;
                draw_line(_caret_x, client_search_y1 + 8, _caret_x, client_search_y2 - 8);
            }
        }

        draw_set_color(hover_client_clear ? _paper_hover : _paper);
        draw_roundrect_ext(client_clear_x1, client_clear_y1, client_clear_x2, client_clear_y2, 8, 8, false);
        draw_set_color(_line_dark);
        draw_roundrect_ext(client_clear_x1, client_clear_y1, client_clear_x2, client_clear_y2, 8, 8, true);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(_accent_red);
        ui_text_fit_center((client_clear_x1 + client_clear_x2) * 0.5, (client_clear_y1 + client_clear_y2) * 0.5 + 1, "X", (client_clear_x2 - client_clear_x1) - 10, UI_FS_TITLE);

        var _list_x1 = _content_x1 + 14;
        var _list_y1 = _content_y1 + 108;
        // Пакет №175: список шире — в него влезает крупный шрифт.
        var _list_x2 = _list_x1 + 470;
        var _list_y2 = _content_y2 - 18;
        var _detail_x1 = _list_x2 + 20;
        var _detail_y1 = _list_y1;
        var _detail_x2 = _content_x2 - 14;
        var _detail_y2 = _content_y2 - 18;

        hud_frosted_fill(_list_x1, _list_y1, _list_x2, _list_y2, 10);
        hud_frosted_fill(_detail_x1, _detail_y1, _detail_x2, _detail_y2, 10);
        draw_set_color(_paper_2);
        draw_roundrect_ext(_list_x1, _list_y1, _list_x2, _list_y2, 10, 10, true);
        draw_roundrect_ext(_detail_x1, _detail_y1, _detail_x2, _detail_y2, 10, 10, true);

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_text_dark);
        ui_text_fit_left(_list_x1 + 12, _list_y1 + 8, clients_subtab == "all" ? "КЛИЕНТЫ" : "ПОВТОРНЫЕ ПРИЁМЫ", (_list_x2 - _list_x1) - 24, UI_FS_HEADER);
        ui_text_fit_left(_detail_x1 + 12, _detail_y1 + 8, clients_subtab == "all" ? "КАРТОЧКА КЛИЕНТА" : "НАЗНАЧЕННЫЙ ВИЗИТ", (_detail_x2 - _detail_x1) - 24, UI_FS_HEADER);

        if (clients_subtab == "all") {
            var _client_row_height = 104;
            var _client_row_top = _list_y1 + 52;
            var _client_visible = max(1, floor((_list_y2 - _client_row_top) / _client_row_height));

            if (array_length(client_entries) <= 0) {
                draw_set_color(_text_soft);
                ui_text_fit_left(_list_x1 + 12, _list_y1 + 58, "В базе пока нет клиентов.", (_list_x2 - _list_x1) - 24, UI_FS_ROW);
            }
            else {
                for (var _row = 0; _row < _client_visible; _row++) {
                    var _entry_index = client_scroll + _row;
                    if (_entry_index >= array_length(client_entries)) break;

                    var _entry = client_entries[_entry_index];
                    if (!variable_struct_exists(global.owner_db, _entry.owner_id)) continue;

                    var _owner_record = variable_struct_get(global.owner_db, _entry.owner_id);
                    var _owner_name = variable_struct_exists(_owner_record, "full_name")
                        ? string(_owner_record.full_name)
                        : "Клиент";
                    var _pet_name = "";
                    var _pet_breed = "";

                    if (
                        _entry.pet_id != ""
                        && variable_struct_exists(global.pet_db, _entry.pet_id)
                    ) {
                        var _pet_record = variable_struct_get(global.pet_db, _entry.pet_id);
                        _pet_name = variable_struct_exists(_pet_record, "name") ? string(_pet_record.name) : "";
                        _pet_breed = variable_struct_exists(_pet_record, "breed") ? string(_pet_record.breed) : "";
                    }

                    var _row_y1 = _client_row_top + _row * _client_row_height;
                    var _row_y2 = _row_y1 + _client_row_height - 6;
                    var _selected = _entry.owner_id == selected_client_owner_id
                        && _entry.pet_id == selected_client_pet_id;
                    var _hovered = _entry_index == client_row_hover;

                    draw_set_color(_selected ? _paper_active : (_hovered ? _paper_hover : _paper));
                    draw_roundrect_ext(_list_x1 + 8, _row_y1, _list_x2 - 8, _row_y2, 8, 8, false);
                    draw_set_color(_line_dark);
                    draw_roundrect_ext(_list_x1 + 8, _row_y1, _list_x2 - 8, _row_y2, 8, 8, true);
                    // Пакет №175: три строки, каждая в своей полосе по 30px.
                    var _cell_w = (_list_x2 - _list_x1) - 48;

                    draw_set_color(_text_dark);
                    ui_text_row(_list_x1 + 20, _row_y1 + 4, 32, string_upper(_owner_name), _cell_w, UI_FS_ROW);
                    draw_set_color(_accent_blue);
                    ui_text_row(_list_x1 + 20, _row_y1 + 34, 30, _pet_name, _cell_w, UI_FS_ROW);
                    draw_set_color(_text_soft);
                    ui_text_row(_list_x1 + 20, _row_y1 + 62, 30, _pet_breed, _cell_w, UI_FS_SMALL);
                }
            }

            if (
                selected_client_owner_id == ""
                || !variable_struct_exists(global.owner_db, selected_client_owner_id)
            ) {
                draw_set_color(_text_soft);
                ui_text_fit_left(_detail_x1 + 12, _detail_y1 + 56, "Выбери клиента в списке слева.", (_detail_x2 - _detail_x1) - 24, UI_FS_ROW);
                return;
            }

            var _owner_data = variable_struct_get(global.owner_db, selected_client_owner_id);
            var _owner_name_detail = variable_struct_exists(_owner_data, "full_name")
                ? string(_owner_data.full_name)
                : "Клиент";
            var _pet_data = undefined;

            if (
                selected_client_pet_id != ""
                && variable_struct_exists(global.pet_db, selected_client_pet_id)
            ) {
                _pet_data = variable_struct_get(global.pet_db, selected_client_pet_id);
            }

            // ═══ Пакет №175: правая колонка на последовательных полосах ═══
            // Раньше все строки стояли на жёстких отступах (+72, +96, +120…)
            // по 22–24 пикселя — при крупном шрифте они бы наложились.
            var _det_x = _detail_x1 + 14;
            var _det_w = (_detail_x2 - _detail_x1) - 28;
            var _det_half = _det_w * 0.5;
            var _row_h = 40;
            var _row_y = _detail_y1 + 48;

            draw_set_color(_text_dark);
            ui_text_row(_det_x, _row_y, 46, string_upper(_owner_name_detail), _det_w, UI_FS_TITLE);
            _row_y += 52;

            draw_set_color(_text_soft);
            ui_text_row(_det_x, _row_y, _row_h, "ВОЗРАСТ: " + string(variable_struct_exists(_owner_data, "age") ? _owner_data.age : 0), _det_half - 12, UI_FS_ROW);
            ui_text_row(_det_x + _det_half, _row_y, _row_h, "ДОВЕРИЕ: " + string(variable_struct_exists(_owner_data, "trust") ? _owner_data.trust : 0), _det_half - 12, UI_FS_ROW);
            _row_y += _row_h;

            ui_text_row(_det_x, _row_y, _row_h, "ДЕНЬГИ: $ " + string(variable_struct_exists(_owner_data, "money") ? _owner_data.money : 0), _det_half - 12, UI_FS_ROW);
            ui_text_row(_det_x + _det_half, _row_y, _row_h, "ТЕРПЕНИЕ: " + string(variable_struct_exists(_owner_data, "patience") ? _owner_data.patience : 0), _det_half - 12, UI_FS_ROW);
            _row_y += _row_h;

            ui_text_row(_det_x, _row_y, _row_h, "ВСЕГО ВИЗИТОВ: " + string(variable_struct_exists(_owner_data, "visits_total") ? _owner_data.visits_total : 0), _det_w, UI_FS_ROW);
            _row_y += _row_h + 10;

            draw_set_color(_accent_blue);
            ui_text_row(_det_x, _row_y, _row_h, "ПАЦИЕНТ", _det_w, UI_FS_HEADER);
            _row_y += _row_h + 4;

            draw_set_color(_text_soft);

            if (is_struct(_pet_data)) {
                ui_text_row(_det_x, _row_y, _row_h, "КЛИЧКА: " + string(variable_struct_exists(_pet_data, "name") ? _pet_data.name : ""), _det_half - 12, UI_FS_ROW);
                ui_text_row(_det_x + _det_half, _row_y, _row_h, "ПОРОДА: " + string(variable_struct_exists(_pet_data, "breed") ? _pet_data.breed : ""), _det_half - 12, UI_FS_ROW);
                _row_y += _row_h;

                ui_text_row(_det_x, _row_y, _row_h, "СОСТОЯНИЕ: " + string(round(variable_struct_exists(_pet_data, "condition") ? _pet_data.condition : 0)) + "%", _det_w, UI_FS_ROW);
                _row_y += _row_h;
            }
            else {
                ui_text_row(_det_x, _row_y, _row_h, "У клиента нет привязанного питомца.", _det_w, UI_FS_ROW);
                _row_y += _row_h;
            }

            _row_y += 12;
            draw_set_color(_paper_2);
            draw_line(_det_x, _row_y, _detail_x2 - 14, _row_y);
            _row_y += 10;

            draw_set_color(_accent_gold);
            ui_text_row(_det_x, _row_y, _row_h, "ВЫБРАННЫЙ ВИЗИТ", _det_w, UI_FS_HEADER);
            _row_y += _row_h + 4;

            var _selected_visit = undefined;

            if (
                selected_client_visit_id != ""
                && variable_struct_exists(global.visit_db, selected_client_visit_id)
            ) {
                _selected_visit = variable_struct_get(global.visit_db, selected_client_visit_id);
            }
            else if (array_length(client_visit_entries) > 0) {
                var _fallback_visit_id = client_visit_entries[0].visit_id;

                if (variable_struct_exists(global.visit_db, _fallback_visit_id)) {
                    _selected_visit = variable_struct_get(global.visit_db, _fallback_visit_id);
                }
            }

            if (!is_struct(_selected_visit)) {
                draw_set_color(_text_soft);
                ui_text_row(_det_x, _row_y, _row_h, "История визитов пока пуста.", _det_w, UI_FS_ROW);
            }
            else {
                var _visit_type = variable_struct_exists(_selected_visit, "visit_type_name_ru") ? string(_selected_visit.visit_type_name_ru) : "Приём";
                var _visit_day = variable_struct_exists(_selected_visit, "visit_day") ? _selected_visit.visit_day : 0;
                var _visit_hour = variable_struct_exists(_selected_visit, "visit_hour") ? _selected_visit.visit_hour : 0;
                var _visit_minute = variable_struct_exists(_selected_visit, "visit_minute") ? _selected_visit.visit_minute : 0;
                var _disease_id = variable_struct_exists(_selected_visit, "disease_id") ? _selected_visit.disease_id : "";
                var _outcome = variable_struct_exists(_selected_visit, "outcome_name_ru") ? string(_selected_visit.outcome_name_ru) : "Приём завершён";
                var _condition_before = variable_struct_exists(_selected_visit, "condition_before") ? _selected_visit.condition_before : 0;
                var _condition_after = variable_struct_exists(_selected_visit, "condition_after") ? _selected_visit.condition_after : 0;
                var _severity_level = variable_struct_exists(_selected_visit, "severity_level") ? _selected_visit.severity_level : 0;
                var _severity_name = variable_struct_exists(_selected_visit, "severity_name_ru") ? string(_selected_visit.severity_name_ru) : "";
                var _case_status = variable_struct_exists(_selected_visit, "case_status") ? string(_selected_visit.case_status) : "";
                var _confirmed = variable_struct_exists(_selected_visit, "case_confirmed") && _selected_visit.case_confirmed;
                var _course_done = variable_struct_exists(_selected_visit, "required_treatment_complete") && _selected_visit.required_treatment_complete;
                var _procedure_lines = hud_visit_build_proc_lines(_selected_visit);
                var _plan_lines = hud_visit_build_plan_lines(_selected_visit);

                draw_set_color(_text_dark);
                ui_text_row(_det_x, _row_y, _row_h, "ТИП: " + _visit_type, _det_w, UI_FS_ROW);
                _row_y += _row_h;

                ui_text_row(_det_x, _row_y, _row_h, "ДАТА: ДЕНЬ " + string(_visit_day) + " • " + hud_clock_text(_visit_hour, _visit_minute), _det_w, UI_FS_ROW);
                _row_y += _row_h;

                ui_text_row(_det_x, _row_y, _row_h, "БОЛЕЗНЬ: " + ((_disease_id != "") ? hud_get_disease_name(_disease_id) : "Не указано"), _det_w, UI_FS_ROW);
                _row_y += _row_h;

                ui_text_row(_det_x, _row_y, _row_h, "СТЕПЕНЬ: " + hud_get_severity_name(_severity_level, _severity_name) + " • СТАТУС: " + _case_status, _det_w, UI_FS_ROW);
                _row_y += _row_h;

                draw_set_color(_accent_green);
                ui_text_row(_det_x, _row_y, _row_h, "ИТОГ: " + _outcome, _det_w, UI_FS_ROW);
                _row_y += _row_h;

                draw_set_color(_text_soft);
                ui_text_row(_det_x, _row_y, _row_h, "СОСТОЯНИЕ: " + string(round(_condition_before)) + "% → " + string(round(_condition_after)) + "%", _det_w, UI_FS_ROW);
                _row_y += _row_h;

                ui_text_row(_det_x, _row_y, _row_h, "ПОДТВЕРЖДЁН: " + hud_bool_text(_confirmed) + " • КУРС: " + hud_bool_text(_course_done), _det_w, UI_FS_ROW);
                _row_y += _row_h + 8;

                var _procedure_box_y1 = _row_y;
                var _procedure_box_y2 = client_history_y1 - 10;

                if (_procedure_box_y2 > _procedure_box_y1 + 50) {
                    hud_frosted_fill(_detail_x1 + 10, _procedure_box_y1, _detail_x2 - 10, _procedure_box_y2, 8);
                    draw_set_color(_paper_2);
                    draw_roundrect_ext(_detail_x1 + 10, _procedure_box_y1, _detail_x2 - 10, _procedure_box_y2, 8, 8, true);
                    var _middle_x = floor((_detail_x1 + _detail_x2) * 0.5);
                    draw_line(_middle_x, _procedure_box_y1 + 8, _middle_x, _procedure_box_y2 - 8);
                    draw_set_color(_text_dark);
                    ui_text_row(_detail_x1 + 20, _procedure_box_y1 + 4, 38, "ПРОЦЕДУРЫ ВИЗИТА", _middle_x - _detail_x1 - 36, UI_FS_HEADER);
                    ui_text_row(_middle_x + 12, _procedure_box_y1 + 4, 38, "КУРС ЛЕЧЕНИЯ", _detail_x2 - _middle_x - 32, UI_FS_HEADER);
                    hud_draw_string_list(_procedure_lines, _detail_x1 + 20, _procedure_box_y1 + 46, 34, client_proc_preview_limit, _middle_x - _detail_x1 - 36, _text_dark, _text_soft);
                    hud_draw_string_list(_plan_lines, _middle_x + 12, _procedure_box_y1 + 46, 34, client_plan_preview_limit, _detail_x2 - _middle_x - 32, _text_dark, _text_soft);
                }
            }

            hud_frosted_fill(client_history_x1, client_history_y1, client_history_x2, client_history_y2, 8);
            draw_set_color(_paper_2);
            draw_roundrect_ext(client_history_x1, client_history_y1, client_history_x2, client_history_y2, 8, 8, true);
            draw_set_color(_text_dark);
            ui_text_row(client_history_x1 + 12, client_history_y1 + 4, 40, "ИСТОРИЯ ВИЗИТОВ", (client_history_x2 - client_history_x1) - 24, UI_FS_HEADER);

            var _history_row_height = 82;
            var _history_top = client_history_y1 + 48;
            var _history_visible = max(1, floor((client_history_y2 - _history_top - 8) / _history_row_height));

            for (var _history_row = 0; _history_row < _history_visible; _history_row++) {
                var _history_index = client_visit_scroll + _history_row;
                if (_history_index >= array_length(client_visit_entries)) break;

                var _visit_id = client_visit_entries[_history_index].visit_id;
                if (!variable_struct_exists(global.visit_db, _visit_id)) continue;

                var _visit_record = variable_struct_get(global.visit_db, _visit_id);
                var _history_y1 = _history_top + _history_row * _history_row_height;
                var _history_y2 = _history_y1 + _history_row_height - 6;
                var _history_selected = _visit_id == selected_client_visit_id;
                var _history_hovered = _history_index == client_visit_row_hover;

                draw_set_color(_history_selected ? _paper_active : (_history_hovered ? _paper_hover : _paper));
                draw_roundrect_ext(client_history_x1 + 8, _history_y1, client_history_x2 - 8, _history_y2, 8, 8, false);
                draw_set_color(_line_dark);
                draw_roundrect_ext(client_history_x1 + 8, _history_y1, client_history_x2 - 8, _history_y2, 8, 8, true);
                var _hist_w = (client_history_x2 - client_history_x1) - 48;

                draw_set_color(_text_dark);
                ui_text_row(client_history_x1 + 20, _history_y1 + 4, 36, "ДЕНЬ " + string(variable_struct_exists(_visit_record, "visit_day") ? _visit_record.visit_day : 0) + " • " + (variable_struct_exists(_visit_record, "visit_type_name_ru") ? string(_visit_record.visit_type_name_ru) : "Приём"), _hist_w, UI_FS_ROW);
                draw_set_color(_text_soft);
                ui_text_row(client_history_x1 + 20, _history_y1 + 38, 34, variable_struct_exists(_visit_record, "outcome_name_ru") ? string(_visit_record.outcome_name_ru) : "Приём завершён", _hist_w, UI_FS_ROW);
            }

            return;
        }

        // Повторные приёмы.
        var _follow_row_height = 104;
        var _follow_top = _list_y1 + 52;
        var _follow_visible = max(1, floor((_list_y2 - _follow_top) / _follow_row_height));

        if (array_length(followup_entries) <= 0) {
            draw_set_color(_text_soft);
            ui_text_fit_left(_list_x1 + 12, _list_y1 + 58, "Нет клиентов с повторным приёмом.", (_list_x2 - _list_x1) - 24, UI_FS_ROW);
        }
        else {
            for (var _follow_row = 0; _follow_row < _follow_visible; _follow_row++) {
                var _follow_index = followup_scroll + _follow_row;
                if (_follow_index >= array_length(followup_entries)) break;

                var _follow_entry = followup_entries[_follow_index];
                if (!variable_struct_exists(global.owner_db, _follow_entry.owner_id)) continue;
                if (!variable_struct_exists(global.pet_db, _follow_entry.pet_id)) continue;

                var _follow_owner = variable_struct_get(global.owner_db, _follow_entry.owner_id);
                var _follow_pet = variable_struct_get(global.pet_db, _follow_entry.pet_id);
                var _scheduled = undefined;

                for (var _schedule_index = 0; _schedule_index < array_length(global.scheduled_visits); _schedule_index++) {
                    if (global.scheduled_visits[_schedule_index].scheduled_visit_id == _follow_entry.scheduled_visit_id) {
                        _scheduled = global.scheduled_visits[_schedule_index];
                        break;
                    }
                }

                var _follow_y1 = _follow_top + _follow_row * _follow_row_height;
                var _follow_y2 = _follow_y1 + _follow_row_height - 6;
                var _follow_selected = _follow_entry.scheduled_visit_id == selected_followup_id;
                var _follow_hovered = _follow_index == followup_row_hover;

                draw_set_color(_follow_selected ? _paper_active : (_follow_hovered ? _paper_hover : _paper));
                draw_roundrect_ext(_list_x1 + 8, _follow_y1, _list_x2 - 8, _follow_y2, 8, 8, false);
                draw_set_color(_line_dark);
                draw_roundrect_ext(_list_x1 + 8, _follow_y1, _list_x2 - 8, _follow_y2, 8, 8, true);
                var _fcell_w = (_list_x2 - _list_x1) - 48;

                draw_set_color(_text_dark);
                ui_text_row(_list_x1 + 20, _follow_y1 + 4, 32, string_upper(string(_follow_owner.full_name)), _fcell_w, UI_FS_ROW);
                draw_set_color(_accent_blue);
                ui_text_row(_list_x1 + 20, _follow_y1 + 34, 30, string(_follow_pet.name) + " • " + string(_follow_pet.breed), _fcell_w, UI_FS_ROW);
                draw_set_color(_text_soft);

                if (is_struct(_scheduled)) {
                    ui_text_row(_list_x1 + 20, _follow_y1 + 62, 30, "ДЕНЬ " + string(_scheduled.scheduled_day) + " • " + hud_minute_to_clock(_scheduled.scheduled_minute), _fcell_w, UI_FS_SMALL);
                }
            }
        }

        if (selected_followup_id == "") {
            draw_set_color(_text_soft);
            ui_text_fit_left(_detail_x1 + 14, _detail_y1 + 56, "Выбери повторный приём в списке слева.", (_detail_x2 - _detail_x1) - 28, UI_FS_ROW);
            return;
        }

        var _selected_schedule = undefined;

        for (var _selected_schedule_index = 0; _selected_schedule_index < array_length(global.scheduled_visits); _selected_schedule_index++) {
            if (global.scheduled_visits[_selected_schedule_index].scheduled_visit_id == selected_followup_id) {
                _selected_schedule = global.scheduled_visits[_selected_schedule_index];
                break;
            }
        }

        if (!is_struct(_selected_schedule)) {
            draw_set_color(_text_soft);
            ui_text_fit_left(_detail_x1 + 14, _detail_y1 + 56, "Запись повторного приёма уже неактуальна.", (_detail_x2 - _detail_x1) - 28, UI_FS_ROW);
            return;
        }

        var _scheduled_owner = variable_struct_get(global.owner_db, _selected_schedule.owner_id);
        var _scheduled_pet = variable_struct_get(global.pet_db, _selected_schedule.pet_id);

        // Пакет №175: те же последовательные полосы, что и в карточке клиента.
        var _fd_x = _detail_x1 + 14;
        var _fd_w = (_detail_x2 - _detail_x1) - 28;
        var _fd_row = 40;
        var _fd_y = _detail_y1 + 48;

        draw_set_color(_text_dark);
        ui_text_row(_fd_x, _fd_y, 46, string_upper(string(_scheduled_owner.full_name)), _fd_w, UI_FS_TITLE);
        _fd_y += 52;

        draw_set_color(_accent_blue);
        ui_text_row(_fd_x, _fd_y, _fd_row, "ПИТОМЕЦ: " + string(_scheduled_pet.name), _fd_w, UI_FS_ROW);
        _fd_y += _fd_row;

        draw_set_color(_text_soft);

        var _fd_lines = [
            "ПОРОДА: " + string(_scheduled_pet.breed),
            "ТИП ВИЗИТА: " + string(_selected_schedule.visit_type_name_ru),
            "ДЕНЬ: " + string(_selected_schedule.scheduled_day),
            "ВРЕМЯ: " + hud_minute_to_clock(_selected_schedule.scheduled_minute),
            "ПРИЧИНА: " + string(_selected_schedule.reason),
            "БОЛЕЗНЬ: " + hud_get_disease_name(_selected_schedule.disease_id),
            "СТЕПЕНЬ: " + hud_get_severity_name(
                variable_struct_exists(_selected_schedule, "severity_level") ? _selected_schedule.severity_level : 0,
                variable_struct_exists(_selected_schedule, "severity_name_ru") ? string(_selected_schedule.severity_name_ru) : ""
            ),
            "ПОДТВЕРЖДЁН: " + hud_bool_text(_selected_schedule.confirmed),
            "СТАРТОВОЕ СОСТОЯНИЕ: " + string(round(_selected_schedule.start_condition)) + "%",
            "СТАТУС: " + hud_get_visit_status_ru(_selected_schedule.status)
        ];

        for (var _fd_i = 0; _fd_i < array_length(_fd_lines); _fd_i++) {
            ui_text_row(_fd_x, _fd_y, _fd_row, _fd_lines[_fd_i], _fd_w, UI_FS_ROW);
            _fd_y += _fd_row;
        }

        var _follow_plan_lines = hud_visit_build_plan_lines(_selected_schedule);

        if (array_length(_follow_plan_lines) > 0) {
            var _plan_y1 = _fd_y + 12;
            var _plan_y2 = min(_detail_y2 - 10, _plan_y1 + 46 + 5 * 34);

            if (_plan_y2 > _plan_y1 + 60) {
                hud_frosted_fill(_fd_x, _plan_y1, _detail_x2 - 14, _plan_y2, 8);
                draw_set_color(_paper_2);
                draw_roundrect_ext(_fd_x, _plan_y1, _detail_x2 - 14, _plan_y2, 8, 8, true);
                draw_set_color(_text_dark);
                ui_text_row(_fd_x + 12, _plan_y1 + 4, 38, "ПЛАН ЛЕЧЕНИЯ", _fd_w - 24, UI_FS_HEADER);
                hud_draw_string_list(_follow_plan_lines, _fd_x + 12, _plan_y1 + 46, 34, 5, _fd_w - 24, _text_dark, _text_soft);
            }
        }
    }
}
