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
        draw_text(_content_x1 + 14, _content_y1 + 10, "БАЗА КЛИЕНТОВ");

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

        if (client_search_text == "") {
            draw_set_color(_text_soft);
            draw_text(client_search_x1 + 12, (client_search_y1 + client_search_y2) * 0.5 + 1, "Поиск по фамилии или кличке...");
        }
        else {
            draw_set_color(_text_dark);
            draw_text(client_search_x1 + 12, (client_search_y1 + client_search_y2) * 0.5 + 1, client_search_text);

            if (client_search_active && client_search_caret_visible) {
                var _caret_x = client_search_x1 + 14 + string_width(client_search_text);
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
        draw_text((client_clear_x1 + client_clear_x2) * 0.5, (client_clear_y1 + client_clear_y2) * 0.5 + 1, "X");

        var _list_x1 = _content_x1 + 14;
        var _list_y1 = _content_y1 + 108;
        var _list_x2 = _list_x1 + 380;
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
        draw_text(_list_x1 + 10, _list_y1 + 8, clients_subtab == "all" ? "КЛИЕНТЫ" : "ПОВТОРНЫЕ ПРИЁМЫ");
        draw_text(_detail_x1 + 10, _detail_y1 + 8, clients_subtab == "all" ? "КАРТОЧКА КЛИЕНТА" : "НАЗНАЧЕННЫЙ ВИЗИТ");

        if (clients_subtab == "all") {
            var _client_row_height = 68;
            var _client_row_top = _list_y1 + 30;
            var _client_visible = max(1, floor((_list_y2 - _client_row_top) / _client_row_height));

            if (array_length(client_entries) <= 0) {
                draw_set_color(_text_soft);
                draw_text_ext(_list_x1 + 10, _list_y1 + 36, "В базе пока нет клиентов.", 20, 280);
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
                    draw_set_color(_text_dark);
                    draw_text_ext(_list_x1 + 18, _row_y1 + 6, string_upper(_owner_name), 18, 270);
                    draw_set_color(_accent_blue);
                    draw_text_ext(_list_x1 + 18, _row_y1 + 24, _pet_name, 18, 270);
                    draw_set_color(_text_soft);
                    draw_text_ext(_list_x1 + 18, _row_y1 + 42, _pet_breed, 18, 270);
                }
            }

            if (
                selected_client_owner_id == ""
                || !variable_struct_exists(global.owner_db, selected_client_owner_id)
            ) {
                draw_set_color(_text_soft);
                draw_text_ext(_detail_x1 + 10, _detail_y1 + 36, "Выбери клиента в списке слева.", 20, _detail_x2 - _detail_x1 - 20);
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

            draw_set_color(_text_dark);
            draw_text_ext(_detail_x1 + 10, _detail_y1 + 36, string_upper(_owner_name_detail), 20, _detail_x2 - _detail_x1 - 20);
            draw_set_color(_text_soft);
            draw_text(_detail_x1 + 10, _detail_y1 + 72, "ВОЗРАСТ: " + string(variable_struct_exists(_owner_data, "age") ? _owner_data.age : 0));
            draw_text(_detail_x1 + 190, _detail_y1 + 72, "ДОВЕРИЕ: " + string(variable_struct_exists(_owner_data, "trust") ? _owner_data.trust : 0));
            draw_text(_detail_x1 + 10, _detail_y1 + 96, "ДЕНЬГИ: $ " + string(variable_struct_exists(_owner_data, "money") ? _owner_data.money : 0));
            draw_text(_detail_x1 + 190, _detail_y1 + 96, "ТЕРПЕНИЕ: " + string(variable_struct_exists(_owner_data, "patience") ? _owner_data.patience : 0));
            draw_text(_detail_x1 + 10, _detail_y1 + 120, "ВСЕГО ВИЗИТОВ: " + string(variable_struct_exists(_owner_data, "visits_total") ? _owner_data.visits_total : 0));

            draw_set_color(_accent_blue);
            draw_text(_detail_x1 + 10, _detail_y1 + 154, "ПАЦИЕНТ");
            draw_set_color(_text_soft);

            if (is_struct(_pet_data)) {
                draw_text(_detail_x1 + 10, _detail_y1 + 178, "КЛИЧКА: " + string(variable_struct_exists(_pet_data, "name") ? _pet_data.name : ""));
                draw_text(_detail_x1 + 190, _detail_y1 + 178, "ПОРОДА: " + string(variable_struct_exists(_pet_data, "breed") ? _pet_data.breed : ""));
                draw_text(_detail_x1 + 10, _detail_y1 + 202, "СОСТОЯНИЕ: " + string(round(variable_struct_exists(_pet_data, "condition") ? _pet_data.condition : 0)) + "%");
            }
            else {
                draw_text(_detail_x1 + 10, _detail_y1 + 178, "У клиента нет привязанного питомца.");
            }

            draw_set_color(_paper_2);
            draw_line(_detail_x1 + 10, _detail_y1 + 232, _detail_x2 - 10, _detail_y1 + 232);
            draw_set_color(_accent_gold);
            draw_text(_detail_x1 + 10, _detail_y1 + 242, "ВЫБРАННЫЙ ВИЗИТ");

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
                draw_text_ext(_detail_x1 + 10, _detail_y1 + 268, "История визитов пока пуста.", 20, _detail_x2 - _detail_x1 - 20);
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
                draw_text(_detail_x1 + 10, _detail_y1 + 268, "ТИП: " + _visit_type);
                draw_text(_detail_x1 + 10, _detail_y1 + 290, "ДАТА: ДЕНЬ " + string(_visit_day) + " • " + hud_clock_text(_visit_hour, _visit_minute));
                draw_text(_detail_x1 + 10, _detail_y1 + 312, "БОЛЕЗНЬ: " + ((_disease_id != "") ? hud_get_disease_name(_disease_id) : "Не указано"));
                draw_text(_detail_x1 + 10, _detail_y1 + 334, "СТЕПЕНЬ: " + hud_get_severity_name(_severity_level, _severity_name) + " • СТАТУС: " + _case_status);
                draw_set_color(_accent_green);
                draw_text(_detail_x1 + 10, _detail_y1 + 356, "ИТОГ: " + _outcome);
                draw_set_color(_text_soft);
                draw_text(_detail_x1 + 10, _detail_y1 + 378, "СОСТОЯНИЕ: " + string(round(_condition_before)) + "% → " + string(round(_condition_after)) + "%");
                draw_text(_detail_x1 + 10, _detail_y1 + 400, "ПОДТВЕРЖДЁН: " + hud_bool_text(_confirmed) + " • КУРС ЗАВЕРШЁН: " + hud_bool_text(_course_done));

                var _procedure_box_y1 = _detail_y1 + 432;
                var _procedure_box_y2 = client_history_y1 - 10;

                if (_procedure_box_y2 > _procedure_box_y1 + 50) {
                    hud_frosted_fill(_detail_x1 + 10, _procedure_box_y1, _detail_x2 - 10, _procedure_box_y2, 8);
                    draw_set_color(_paper_2);
                    draw_roundrect_ext(_detail_x1 + 10, _procedure_box_y1, _detail_x2 - 10, _procedure_box_y2, 8, 8, true);
                    var _middle_x = floor((_detail_x1 + _detail_x2) * 0.5);
                    draw_line(_middle_x, _procedure_box_y1 + 8, _middle_x, _procedure_box_y2 - 8);
                    draw_set_color(_text_dark);
                    draw_text(_detail_x1 + 20, _procedure_box_y1 + 6, "ПРОЦЕДУРЫ ВИЗИТА");
                    draw_text(_middle_x + 10, _procedure_box_y1 + 6, "КУРС ЛЕЧЕНИЯ");
                    hud_draw_string_list(_procedure_lines, _detail_x1 + 20, _procedure_box_y1 + 28, 20, client_proc_preview_limit, _middle_x - _detail_x1 - 34, _text_dark, _text_soft);
                    hud_draw_string_list(_plan_lines, _middle_x + 10, _procedure_box_y1 + 28, 20, client_plan_preview_limit, _detail_x2 - _middle_x - 30, _text_dark, _text_soft);
                }
            }

            hud_frosted_fill(client_history_x1, client_history_y1, client_history_x2, client_history_y2, 8);
            draw_set_color(_paper_2);
            draw_roundrect_ext(client_history_x1, client_history_y1, client_history_x2, client_history_y2, 8, 8, true);
            draw_set_color(_text_dark);
            draw_text(client_history_x1 + 10, client_history_y1 + 6, "ИСТОРИЯ ВИЗИТОВ");

            var _history_row_height = 54;
            var _history_top = client_history_y1 + 28;
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
                draw_set_color(_text_dark);
                draw_text_ext(client_history_x1 + 18, _history_y1 + 6, "ДЕНЬ " + string(variable_struct_exists(_visit_record, "visit_day") ? _visit_record.visit_day : 0) + " • " + (variable_struct_exists(_visit_record, "visit_type_name_ru") ? string(_visit_record.visit_type_name_ru) : "Приём"), 18, client_history_x2 - client_history_x1 - 40);
                draw_set_color(_text_soft);
                draw_text_ext(client_history_x1 + 18, _history_y1 + 28, variable_struct_exists(_visit_record, "outcome_name_ru") ? string(_visit_record.outcome_name_ru) : "Приём завершён", 18, client_history_x2 - client_history_x1 - 40);
            }

            return;
        }

        // Повторные приёмы.
        var _follow_row_height = 68;
        var _follow_top = _list_y1 + 30;
        var _follow_visible = max(1, floor((_list_y2 - _follow_top) / _follow_row_height));

        if (array_length(followup_entries) <= 0) {
            draw_set_color(_text_soft);
            draw_text_ext(_list_x1 + 10, _list_y1 + 36, "Нет клиентов с назначенным повторным приёмом.", 20, 300);
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
                draw_set_color(_text_dark);
                draw_text_ext(_list_x1 + 18, _follow_y1 + 6, string_upper(string(_follow_owner.full_name)), 18, 270);
                draw_set_color(_accent_blue);
                draw_text_ext(_list_x1 + 18, _follow_y1 + 24, string(_follow_pet.name) + " • " + string(_follow_pet.breed), 18, 270);
                draw_set_color(_text_soft);

                if (is_struct(_scheduled)) {
                    draw_text_ext(_list_x1 + 18, _follow_y1 + 42, "ДЕНЬ " + string(_scheduled.scheduled_day) + " • " + hud_minute_to_clock(_scheduled.scheduled_minute), 18, 270);
                }
            }
        }

        if (selected_followup_id == "") {
            draw_set_color(_text_soft);
            draw_text_ext(_detail_x1 + 10, _detail_y1 + 36, "Выбери повторный приём в списке слева.", 20, _detail_x2 - _detail_x1 - 20);
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
            draw_text_ext(_detail_x1 + 10, _detail_y1 + 36, "Запись повторного приёма уже неактуальна.", 20, _detail_x2 - _detail_x1 - 20);
            return;
        }

        var _scheduled_owner = variable_struct_get(global.owner_db, _selected_schedule.owner_id);
        var _scheduled_pet = variable_struct_get(global.pet_db, _selected_schedule.pet_id);

        draw_set_color(_text_dark);
        draw_text_ext(_detail_x1 + 10, _detail_y1 + 36, string_upper(string(_scheduled_owner.full_name)), 20, _detail_x2 - _detail_x1 - 20);
        draw_set_color(_accent_blue);
        draw_text(_detail_x1 + 10, _detail_y1 + 74, "ПИТОМЕЦ: " + string(_scheduled_pet.name));
        draw_set_color(_text_soft);
        draw_text(_detail_x1 + 10, _detail_y1 + 100, "ПОРОДА: " + string(_scheduled_pet.breed));
        draw_text(_detail_x1 + 10, _detail_y1 + 126, "ТИП ВИЗИТА: " + string(_selected_schedule.visit_type_name_ru));
        draw_text(_detail_x1 + 10, _detail_y1 + 152, "ДЕНЬ: " + string(_selected_schedule.scheduled_day));
        draw_text(_detail_x1 + 10, _detail_y1 + 178, "ВРЕМЯ: " + hud_minute_to_clock(_selected_schedule.scheduled_minute));
        draw_text(_detail_x1 + 10, _detail_y1 + 204, "ПРИЧИНА: " + string(_selected_schedule.reason));
        draw_text(_detail_x1 + 10, _detail_y1 + 230, "БОЛЕЗНЬ: " + hud_get_disease_name(_selected_schedule.disease_id));
        draw_text(_detail_x1 + 10, _detail_y1 + 256, "СТЕПЕНЬ: " + hud_get_severity_name(variable_struct_exists(_selected_schedule, "severity_level") ? _selected_schedule.severity_level : 0, variable_struct_exists(_selected_schedule, "severity_name_ru") ? string(_selected_schedule.severity_name_ru) : ""));
        draw_text(_detail_x1 + 10, _detail_y1 + 282, "ПОДТВЕРЖДЁН: " + hud_bool_text(_selected_schedule.confirmed));
        draw_text(_detail_x1 + 10, _detail_y1 + 308, "СТАРТОВОЕ СОСТОЯНИЕ: " + string(round(_selected_schedule.start_condition)) + "%");
        draw_text(_detail_x1 + 10, _detail_y1 + 334, "СТАТУС: " + hud_get_visit_status_ru(_selected_schedule.status));

        var _follow_plan_lines = hud_visit_build_plan_lines(_selected_schedule);

        if (array_length(_follow_plan_lines) > 0) {
            hud_frosted_fill(_detail_x1 + 10, _detail_y1 + 364, _detail_x2 - 10, _detail_y1 + 492, 8);
            draw_set_color(_paper_2);
            draw_roundrect_ext(_detail_x1 + 10, _detail_y1 + 364, _detail_x2 - 10, _detail_y1 + 492, 8, 8, true);
            draw_set_color(_text_dark);
            draw_text(_detail_x1 + 20, _detail_y1 + 370, "ПЛАН ЛЕЧЕНИЯ");
            hud_draw_string_list(_follow_plan_lines, _detail_x1 + 20, _detail_y1 + 392, 20, 5, _detail_x2 - _detail_x1 - 40, _text_dark, _text_soft);
        }
    }
}
