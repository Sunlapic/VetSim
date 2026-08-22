/// hud_draw_clients_database.gml
/// @description База клиентов, история визитов и повторные приёмы.
/// Пакет №120: панель на матовом стекле (дерево только рамкой).
/// Пакет №189: ОДНА общая раскладка для рисования и для кликов
/// (hud_clients_layout), крупный список слева, правая часть разложена
/// на логические блоки вместо сплошного списка строк.


// ═══════════════════════════════════════════════════════════════
// 0. ЕДИНАЯ РАСКЛАДКА ОКНА
//
// Раньше координаты списка были записаны ДВА раза: в отрисовке
// (ширина 470, высота строки 104) и в obj_UI_HUD -> Begin Step
// (ширина 380, высота строки 68). Из-за этого клик по третьей карточке
// попадал в первую. Теперь и рисование, и клики берут числа отсюда.
// ═══════════════════════════════════════════════════════════════

function hud_clients_layout(_hud) {
    var _panel_x1 = _hud.clients_panel_x1;
    var _panel_y1 = _hud.clients_panel_y1;
    var _panel_x2 = _hud.clients_panel_x2;
    var _panel_y2 = _hud.clients_panel_y2;

    var _content_x1 = _panel_x1 + 14;
    var _content_y1 = _panel_y1 + 14;
    var _content_x2 = _panel_x2 - 14;
    var _content_y2 = _panel_y2 - 14;

    var _list_x1 = _content_x1 + 14;
    var _list_y1 = _content_y1 + 108;
    var _list_x2 = _list_x1 + 470;
    var _list_y2 = _content_y2 - 18;

    var _detail_x1 = _list_x2 + 20;
    var _detail_y1 = _list_y1;
    var _detail_x2 = _content_x2 - 14;
    var _detail_y2 = _content_y2 - 18;

    // Высота карточки клиента: три строки крупным шрифтом.
    var _row_h = 118;
    var _row_top = _list_y1 + 56;

    // История визитов — нижняя полоса правой части.
    var _hist_h = min(300, max(180, (_detail_y2 - _detail_y1) * 0.32));
    var _hist_x1 = _detail_x1 + 10;
    var _hist_x2 = _detail_x2 - 10;
    var _hist_y2 = _detail_y2 - 10;
    var _hist_y1 = _hist_y2 - _hist_h;
    var _hist_row_h = 74;
    var _hist_row_top = _hist_y1 + 58;

    return {
        content_x1 : _content_x1,
        content_y1 : _content_y1,
        content_x2 : _content_x2,
        content_y2 : _content_y2,

        list_x1 : _list_x1,
        list_y1 : _list_y1,
        list_x2 : _list_x2,
        list_y2 : _list_y2,
        row_h : _row_h,
        row_top : _row_top,
        row_visible : max(1, floor((_list_y2 - _row_top) / _row_h)),

        detail_x1 : _detail_x1,
        detail_y1 : _detail_y1,
        detail_x2 : _detail_x2,
        detail_y2 : _detail_y2,

        hist_x1 : _hist_x1,
        hist_y1 : _hist_y1,
        hist_x2 : _hist_x2,
        hist_y2 : _hist_y2,
        hist_row_h : _hist_row_h,
        hist_row_top : _hist_row_top,
        hist_visible : max(1, floor((_hist_y2 - _hist_row_top - 8) / _hist_row_h))
    };
}


// ═══════════════════════════════════════════════════════════════
// 0.1 БЛОК С ЗАГОЛОВКОМ
// Каждая логическая группа сведений — своя рамка со своим названием.
// Возвращает Y, с которого начинается содержимое блока.
// ═══════════════════════════════════════════════════════════════

function hud_clients_block(_x1, _y1, _x2, _y2, _title, _title_color) {
    hud_frosted_fill(_x1, _y1, _x2, _y2, 8);
    draw_set_color(make_color_rgb(232, 220, 198));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, true);

    draw_set_color(_title_color);
    ui_text_row(_x1 + 14, _y1 + 6, 40, _title, (_x2 - _x1) - 28, UI_FS_HEADER);

    draw_set_color(make_color_rgb(232, 220, 198));
    draw_line(_x1 + 14, _y1 + 48, _x2 - 14, _y1 + 48);

    return _y1 + 56;
}

/// Строка «ПОДПИСЬ: значение» внутри блока.
function hud_clients_block_row(_x, _y, _w, _row_h, _text, _color) {
    draw_set_color(_color);
    ui_text_row(_x, _y, _row_h, _text, _w, UI_FS_ROW);

    return _y + _row_h;
}

/// Полоска прокрутки справа внутри списка (показывает, где мы находимся).
function hud_clients_scroll_hint(_x2, _y1, _y2, _scroll, _visible, _total) {
    if (_total <= _visible) return;

    var _track_x2 = _x2 - 6;
    var _track_x1 = _track_x2 - 8;
    var _track_y1 = _y1;
    var _track_y2 = _y2;
    var _track_h = _track_y2 - _track_y1;

    draw_set_color(make_color_rgb(232, 220, 198));
    draw_roundrect_ext(_track_x1, _track_y1, _track_x2, _track_y2, 4, 4, false);

    var _bar_h = max(40, _track_h * (_visible / _total));
    var _max_scroll = max(1, _total - _visible);
    var _bar_y1 = _track_y1 + (_track_h - _bar_h) * (clamp(_scroll, 0, _max_scroll) / _max_scroll);

    draw_set_color(make_color_rgb(150, 107, 73));
    draw_roundrect_ext(_track_x1, _bar_y1, _track_x2, _bar_y1 + _bar_h, 4, 4, false);
}

function hud_draw_clients_database(_hud) {
    if (!instance_exists(_hud)) return;
    if (!_hud.clients_panel_open) return;

    with (_hud) {
        var _paper = make_color_rgb(242, 232, 214);
        var _paper_2 = make_color_rgb(232, 220, 198);
        var _paper_hover = make_color_rgb(248, 238, 220);
        var _paper_active = make_color_rgb(220, 202, 172);
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

        var _lay = hud_clients_layout(_hud);

        var _content_x1 = _lay.content_x1;
        var _content_y1 = _lay.content_y1;
        var _content_x2 = _lay.content_x2;
        var _content_y2 = _lay.content_y2;

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(_text_dark);
        ui_text_fit_left(_content_x1 + 16, _content_y1 + 8, "БАЗА КЛИЕНТОВ", 520, UI_FS_TITLE);

        ui_draw_tab(
            clients_tab_all_x1,
            clients_tab_all_y1,
            clients_tab_all_x2,
            clients_tab_all_y2,
            "ВСЕ",
            clients_subtab == "all",
            hover_clients_tab_all
        );
        ui_draw_tab(
            clients_tab_followup_x1,
            clients_tab_followup_y1,
            clients_tab_followup_x2,
            clients_tab_followup_y2,
            "ПОВТОРНЫЕ",
            clients_subtab == "followup",
            hover_clients_tab_followup
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

        var _list_x1 = _lay.list_x1;
        var _list_y1 = _lay.list_y1;
        var _list_x2 = _lay.list_x2;
        var _list_y2 = _lay.list_y2;
        var _detail_x1 = _lay.detail_x1;
        var _detail_y1 = _lay.detail_y1;
        var _detail_x2 = _lay.detail_x2;
        var _detail_y2 = _lay.detail_y2;

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
            // ═══════════════════════════════════════════════════
            // СПИСОК КЛИЕНТОВ (пакет №189: крупный шрифт)
            // Имя — как заголовок, кличка — крупно, порода — помельче.
            // ═══════════════════════════════════════════════════

            var _client_row_height = _lay.row_h;
            var _client_row_top = _lay.row_top;
            var _client_visible = _lay.row_visible;

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
                    var _row_y2 = _row_y1 + _client_row_height - 8;
                    var _selected = _entry.owner_id == selected_client_owner_id
                        && _entry.pet_id == selected_client_pet_id;
                    var _hovered = _entry_index == client_row_hover;

                    draw_set_color(_selected ? _paper_active : (_hovered ? _paper_hover : _paper));
                    draw_roundrect_ext(_list_x1 + 8, _row_y1, _list_x2 - 8, _row_y2, 8, 8, false);
                    draw_set_color(_line_dark);
                    draw_roundrect_ext(_list_x1 + 8, _row_y1, _list_x2 - 8, _row_y2, 8, 8, true);

                    // Выбранная карточка отмечена полосой слева.
                    if (_selected) {
                        draw_set_color(_accent_gold);
                        draw_roundrect_ext(_list_x1 + 8, _row_y1, _list_x1 + 15, _row_y2, 4, 4, false);
                    }

                    var _cell_w = (_list_x2 - _list_x1) - 52;
                    var _cell_x = _list_x1 + 22;
                    var _cell_y = _row_y1 + 6;

                    draw_set_color(_text_dark);
                    ui_text_row(_cell_x, _cell_y, 38, string_upper(_owner_name), _cell_w, UI_FS_HEADER);
                    _cell_y += 38;

                    draw_set_color(_accent_blue);
                    ui_text_row(_cell_x, _cell_y, 34, _pet_name, _cell_w, UI_FS_VALUE);
                    _cell_y += 34;

                    draw_set_color(_text_soft);
                    ui_text_row(_cell_x, _cell_y, 30, _pet_breed, _cell_w, UI_FS_ROW);
                }
            }

            hud_clients_scroll_hint(
                _list_x2,
                _client_row_top,
                _list_y2 - 8,
                client_scroll,
                _client_visible,
                array_length(client_entries)
            );

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

            // ═══════════════════════════════════════════════════
            // ПРАВАЯ ЧАСТЬ: ЛОГИЧЕСКИЕ БЛОКИ (пакет №189)
            //
            //  ИМЯ КЛИЕНТА
            //  ┌ ВЛАДЕЛЕЦ ──────┐ ┌ ВЫБРАННЫЙ ВИЗИТ ──┐
            //  └────────────────┘ │                   │
            //  ┌ ПАЦИЕНТ ───────┐ │                   │
            //  └────────────────┘ └───────────────────┘
            //  ┌ ПРОЦЕДУРЫ ВИЗИТА │ КУРС ЛЕЧЕНИЯ ─────┐
            //  └──────────────────────────────────────┘
            //  ┌ ИСТОРИЯ ВИЗИТОВ ─────────────────────┐
            //  └──────────────────────────────────────┘
            //
            // Узкое окно (мало места по ширине) — те же блоки, но
            // в одну колонку друг под другом.
            // ═══════════════════════════════════════════════════

            var _det_pad = 12;
            var _blk_x1 = _detail_x1 + 10;
            var _blk_x2 = _detail_x2 - 10;
            var _blk_w = _blk_x2 - _blk_x1;
            var _two_cols = (_blk_w >= 820);
            var _col_gap = 14;
            var _col_w = _two_cols ? (_blk_w - _col_gap) * 0.5 : _blk_w;

            var _top_y = _detail_y1 + 52;

            draw_set_color(_text_dark);
            ui_text_row(_blk_x1 + 4, _top_y, 50, string_upper(_owner_name_detail), _blk_w - 8, UI_FS_TITLE);
            _top_y += 56;

            var _row_h = 40;

            // ── Блок ВЛАДЕЛЕЦ ──
            var _owner_block_h = 56 + _row_h * 3 + 10;
            var _left_x1 = _blk_x1;
            var _left_x2 = _blk_x1 + _col_w;
            var _left_y = _top_y;

            var _owner_y = hud_clients_block(
                _left_x1,
                _left_y,
                _left_x2,
                _left_y + _owner_block_h,
                "ВЛАДЕЛЕЦ",
                _accent_blue
            );

            var _owner_col_w = (_col_w - 28) * 0.5;

            draw_set_color(_text_soft);
            ui_text_row(_left_x1 + 14, _owner_y, _row_h, "ВОЗРАСТ: " + string(variable_struct_exists(_owner_data, "age") ? _owner_data.age : 0), _owner_col_w - 8, UI_FS_ROW);
            ui_text_row(_left_x1 + 14 + _owner_col_w, _owner_y, _row_h, "ДОВЕРИЕ: " + string(variable_struct_exists(_owner_data, "trust") ? _owner_data.trust : 0), _owner_col_w - 8, UI_FS_ROW);
            _owner_y += _row_h;

            ui_text_row(_left_x1 + 14, _owner_y, _row_h, "ДЕНЬГИ: $ " + string(variable_struct_exists(_owner_data, "money") ? _owner_data.money : 0), _owner_col_w - 8, UI_FS_ROW);
            ui_text_row(_left_x1 + 14 + _owner_col_w, _owner_y, _row_h, "ТЕРПЕНИЕ: " + string(variable_struct_exists(_owner_data, "patience") ? _owner_data.patience : 0), _owner_col_w - 8, UI_FS_ROW);
            _owner_y += _row_h;

            ui_text_row(_left_x1 + 14, _owner_y, _row_h, "ВСЕГО ВИЗИТОВ: " + string(variable_struct_exists(_owner_data, "visits_total") ? _owner_data.visits_total : 0), _col_w - 28, UI_FS_ROW);

            _left_y += _owner_block_h + _det_pad;

            // ── Блок ПАЦИЕНТ ──
            var _pet_block_h = 56 + _row_h * 2 + 10;
            var _pet_y = hud_clients_block(
                _left_x1,
                _left_y,
                _left_x2,
                _left_y + _pet_block_h,
                "ПАЦИЕНТ",
                _accent_green
            );

            draw_set_color(_text_soft);

            if (is_struct(_pet_data)) {
                ui_text_row(_left_x1 + 14, _pet_y, _row_h, "КЛИЧКА: " + string(variable_struct_exists(_pet_data, "name") ? _pet_data.name : ""), _owner_col_w - 8, UI_FS_ROW);
                ui_text_row(_left_x1 + 14 + _owner_col_w, _pet_y, _row_h, "ПОРОДА: " + string(variable_struct_exists(_pet_data, "breed") ? _pet_data.breed : ""), _owner_col_w - 8, UI_FS_ROW);
                _pet_y += _row_h;

                ui_text_row(_left_x1 + 14, _pet_y, _row_h, "СОСТОЯНИЕ: " + string(round(variable_struct_exists(_pet_data, "condition") ? _pet_data.condition : 0)) + "%", _col_w - 28, UI_FS_ROW);
            }
            else {
                ui_text_row(_left_x1 + 14, _pet_y, _row_h, "У клиента нет привязанного питомца.", _col_w - 28, UI_FS_ROW);
            }

            _left_y += _pet_block_h + _det_pad;

            // ── Блок ВЫБРАННЫЙ ВИЗИТ ──
            var _visit_x1 = _two_cols ? (_blk_x1 + _col_w + _col_gap) : _blk_x1;
            var _visit_x2 = _blk_x2;
            var _visit_y1 = _two_cols ? _top_y : _left_y;
            var _visit_block_h = 56 + _row_h * 7 + 10;
            var _visit_y = hud_clients_block(
                _visit_x1,
                _visit_y1,
                _visit_x2,
                _visit_y1 + _visit_block_h,
                "ВЫБРАННЫЙ ВИЗИТ",
                _accent_gold
            );

            var _visit_w = (_visit_x2 - _visit_x1) - 28;

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

            var _procedure_lines = [];
            var _plan_lines = [];

            if (!is_struct(_selected_visit)) {
                draw_set_color(_text_soft);
                ui_text_row(_visit_x1 + 14, _visit_y, _row_h, "История визитов пока пуста.", _visit_w, UI_FS_ROW);
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

                _procedure_lines = hud_visit_build_proc_lines(_selected_visit);
                _plan_lines = hud_visit_build_plan_lines(_selected_visit);

                _visit_y = hud_clients_block_row(_visit_x1 + 14, _visit_y, _visit_w, _row_h, "ТИП: " + _visit_type, _text_dark);
                _visit_y = hud_clients_block_row(_visit_x1 + 14, _visit_y, _visit_w, _row_h, "ДАТА: ДЕНЬ " + string(_visit_day) + " - " + hud_clock_text(_visit_hour, _visit_minute), _text_dark);
                _visit_y = hud_clients_block_row(_visit_x1 + 14, _visit_y, _visit_w, _row_h, "БОЛЕЗНЬ: " + ((_disease_id != "") ? hud_get_disease_name(_disease_id) : "Не указано"), _text_dark);
                _visit_y = hud_clients_block_row(_visit_x1 + 14, _visit_y, _visit_w, _row_h, "СТЕПЕНЬ: " + hud_get_severity_name(_severity_level, _severity_name), _text_dark);
                _visit_y = hud_clients_block_row(_visit_x1 + 14, _visit_y, _visit_w, _row_h, "СТАТУС: " + _case_status + "   ПОДТВЕРЖДЁН: " + hud_bool_text(_confirmed), _text_soft);
                _visit_y = hud_clients_block_row(_visit_x1 + 14, _visit_y, _visit_w, _row_h, "СОСТОЯНИЕ: " + string(round(_condition_before)) + "% -> " + string(round(_condition_after)) + "%   КУРС: " + hud_bool_text(_course_done), _text_soft);
                _visit_y = hud_clients_block_row(_visit_x1 + 14, _visit_y, _visit_w, _row_h, "ИТОГ: " + _outcome, _accent_green);
            }

            // ── Блок ПРОЦЕДУРЫ / КУРС ЛЕЧЕНИЯ ──
            var _proc_y1 = _two_cols
                ? max(_left_y, _visit_y1 + _visit_block_h + _det_pad)
                : (_visit_y1 + _visit_block_h + _det_pad);
            var _proc_y2 = _lay.hist_y1 - _det_pad;

            if (_proc_y2 > _proc_y1 + 90) {
                hud_frosted_fill(_blk_x1, _proc_y1, _blk_x2, _proc_y2, 8);
                draw_set_color(_paper_2);
                draw_roundrect_ext(_blk_x1, _proc_y1, _blk_x2, _proc_y2, 8, 8, true);

                var _middle_x = floor((_blk_x1 + _blk_x2) * 0.5);
                draw_line(_middle_x, _proc_y1 + 8, _middle_x, _proc_y2 - 8);

                draw_set_color(_text_dark);
                ui_text_row(_blk_x1 + 14, _proc_y1 + 6, 40, "ПРОЦЕДУРЫ ВИЗИТА", _middle_x - _blk_x1 - 32, UI_FS_HEADER);
                ui_text_row(_middle_x + 14, _proc_y1 + 6, 40, "КУРС ЛЕЧЕНИЯ", _blk_x2 - _middle_x - 32, UI_FS_HEADER);

                draw_set_color(_paper_2);
                draw_line(_blk_x1 + 14, _proc_y1 + 48, _blk_x2 - 14, _proc_y1 + 48);

                var _proc_limit = max(1, floor((_proc_y2 - _proc_y1 - 56) / 34));

                hud_draw_string_list(_procedure_lines, _blk_x1 + 14, _proc_y1 + 56, 34, _proc_limit, _middle_x - _blk_x1 - 32, _text_dark, _text_soft);
                hud_draw_string_list(_plan_lines, _middle_x + 14, _proc_y1 + 56, 34, _proc_limit, _blk_x2 - _middle_x - 32, _text_dark, _text_soft);
            }

            // ── Блок ИСТОРИЯ ВИЗИТОВ ──
            client_history_x1 = _lay.hist_x1;
            client_history_y1 = _lay.hist_y1;
            client_history_x2 = _lay.hist_x2;
            client_history_y2 = _lay.hist_y2;

            hud_clients_block(
                client_history_x1,
                client_history_y1,
                client_history_x2,
                client_history_y2,
                "ИСТОРИЯ ВИЗИТОВ",
                _text_dark
            );

            var _history_row_height = _lay.hist_row_h;
            var _history_top = _lay.hist_row_top;
            var _history_visible = _lay.hist_visible;

            if (array_length(client_visit_entries) <= 0) {
                draw_set_color(_text_soft);
                ui_text_row(client_history_x1 + 14, _history_top, 36, "Визитов пока не было.", (client_history_x2 - client_history_x1) - 28, UI_FS_ROW);
            }

            hud_clients_scroll_hint(
                client_history_x2 - 2,
                _history_top,
                client_history_y2 - 8,
                client_visit_scroll,
                _history_visible,
                array_length(client_visit_entries)
            );

            for (var _history_row = 0; _history_row < _history_visible; _history_row++) {
                var _history_index = client_visit_scroll + _history_row;
                if (_history_index >= array_length(client_visit_entries)) break;

                var _visit_id = client_visit_entries[_history_index].visit_id;
                if (!variable_struct_exists(global.visit_db, _visit_id)) continue;

                var _visit_record = variable_struct_get(global.visit_db, _visit_id);
                var _history_y1 = _history_top + _history_row * _history_row_height;
                var _history_y2 = _history_y1 + _history_row_height - 8;
                var _history_selected = _visit_id == selected_client_visit_id;
                var _history_hovered = _history_index == client_visit_row_hover;

                draw_set_color(_history_selected ? _paper_active : (_history_hovered ? _paper_hover : _paper));
                draw_roundrect_ext(client_history_x1 + 10, _history_y1, client_history_x2 - 10, _history_y2, 8, 8, false);
                draw_set_color(_line_dark);
                draw_roundrect_ext(client_history_x1 + 10, _history_y1, client_history_x2 - 10, _history_y2, 8, 8, true);

                var _hist_w = (client_history_x2 - client_history_x1) - 52;

                draw_set_color(_text_dark);
                ui_text_row(client_history_x1 + 24, _history_y1 + 4, 34, "ДЕНЬ " + string(variable_struct_exists(_visit_record, "visit_day") ? _visit_record.visit_day : 0) + " - " + (variable_struct_exists(_visit_record, "visit_type_name_ru") ? string(_visit_record.visit_type_name_ru) : "Приём"), _hist_w, UI_FS_ROW);
                draw_set_color(_text_soft);
                ui_text_row(client_history_x1 + 24, _history_y1 + 36, 30, variable_struct_exists(_visit_record, "outcome_name_ru") ? string(_visit_record.outcome_name_ru) : "Приём завершён", _hist_w, UI_FS_ROW);
            }

            return;
        }

        // ═══════════════════════════════════════════════════════
        // ВКЛАДКА «ПОВТОРНЫЕ»
        // ═══════════════════════════════════════════════════════

        var _follow_row_height = _lay.row_h;
        var _follow_top = _lay.row_top;
        var _follow_visible = _lay.row_visible;

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
                var _follow_y2 = _follow_y1 + _follow_row_height - 8;
                var _follow_selected = _follow_entry.scheduled_visit_id == selected_followup_id;
                var _follow_hovered = _follow_index == followup_row_hover;

                draw_set_color(_follow_selected ? _paper_active : (_follow_hovered ? _paper_hover : _paper));
                draw_roundrect_ext(_list_x1 + 8, _follow_y1, _list_x2 - 8, _follow_y2, 8, 8, false);
                draw_set_color(_line_dark);
                draw_roundrect_ext(_list_x1 + 8, _follow_y1, _list_x2 - 8, _follow_y2, 8, 8, true);

                if (_follow_selected) {
                    draw_set_color(_accent_gold);
                    draw_roundrect_ext(_list_x1 + 8, _follow_y1, _list_x1 + 15, _follow_y2, 4, 4, false);
                }

                var _fcell_w = (_list_x2 - _list_x1) - 52;
                var _fcell_x = _list_x1 + 22;
                var _fcell_y = _follow_y1 + 6;

                draw_set_color(_text_dark);
                ui_text_row(_fcell_x, _fcell_y, 38, string_upper(string(_follow_owner.full_name)), _fcell_w, UI_FS_HEADER);
                _fcell_y += 38;

                draw_set_color(_accent_blue);
                ui_text_row(_fcell_x, _fcell_y, 34, string(_follow_pet.name) + " - " + string(_follow_pet.breed), _fcell_w, UI_FS_VALUE);
                _fcell_y += 34;

                draw_set_color(_text_soft);

                if (is_struct(_scheduled)) {
                    ui_text_row(_fcell_x, _fcell_y, 30, "ДЕНЬ " + string(_scheduled.scheduled_day) + " - " + hud_minute_to_clock(_scheduled.scheduled_minute), _fcell_w, UI_FS_ROW);
                }
            }
        }

        hud_clients_scroll_hint(
            _list_x2,
            _follow_top,
            _list_y2 - 8,
            followup_scroll,
            _follow_visible,
            array_length(followup_entries)
        );

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

        // Те же логические блоки, что и в карточке клиента.
        var _fblk_x1 = _detail_x1 + 10;
        var _fblk_x2 = _detail_x2 - 10;
        var _fblk_w = _fblk_x2 - _fblk_x1;
        var _fd_row = 40;
        var _fd_y = _detail_y1 + 52;

        draw_set_color(_text_dark);
        ui_text_row(_fblk_x1 + 4, _fd_y, 50, string_upper(string(_scheduled_owner.full_name)), _fblk_w - 8, UI_FS_TITLE);
        _fd_y += 56;

        var _fpet_h = 56 + _fd_row * 2 + 10;
        var _fpet_y = hud_clients_block(_fblk_x1, _fd_y, _fblk_x2, _fd_y + _fpet_h, "ПАЦИЕНТ", _accent_green);

        _fpet_y = hud_clients_block_row(_fblk_x1 + 14, _fpet_y, _fblk_w - 28, _fd_row, "ПИТОМЕЦ: " + string(_scheduled_pet.name), _accent_blue);
        _fpet_y = hud_clients_block_row(_fblk_x1 + 14, _fpet_y, _fblk_w - 28, _fd_row, "ПОРОДА: " + string(_scheduled_pet.breed), _text_soft);

        _fd_y += _fpet_h + 12;

        var _fvisit_h = 56 + _fd_row * 7 + 10;
        var _fvisit_y = hud_clients_block(_fblk_x1, _fd_y, _fblk_x2, _fd_y + _fvisit_h, "НАЗНАЧЕННЫЙ ВИЗИТ", _accent_gold);

        var _fd_lines = [
            "ТИП ВИЗИТА: " + string(_selected_schedule.visit_type_name_ru),
            "ДЕНЬ: " + string(_selected_schedule.scheduled_day) + "   ВРЕМЯ: " + hud_minute_to_clock(_selected_schedule.scheduled_minute),
            "ПРИЧИНА: " + string(_selected_schedule.reason),
            "БОЛЕЗНЬ: " + hud_get_disease_name(_selected_schedule.disease_id),
            "СТЕПЕНЬ: " + hud_get_severity_name(
                variable_struct_exists(_selected_schedule, "severity_level") ? _selected_schedule.severity_level : 0,
                variable_struct_exists(_selected_schedule, "severity_name_ru") ? string(_selected_schedule.severity_name_ru) : ""
            ),
            "ПОДТВЕРЖДЁН: " + hud_bool_text(_selected_schedule.confirmed)
                + "   СОСТОЯНИЕ: " + string(round(_selected_schedule.start_condition)) + "%",
            "СТАТУС: " + hud_get_visit_status_ru(_selected_schedule.status)
        ];

        for (var _fd_i = 0; _fd_i < array_length(_fd_lines); _fd_i++) {
            _fvisit_y = hud_clients_block_row(_fblk_x1 + 14, _fvisit_y, _fblk_w - 28, _fd_row, _fd_lines[_fd_i], _text_soft);
        }

        _fd_y += _fvisit_h + 12;

        var _follow_plan_lines = hud_visit_build_plan_lines(_selected_schedule);

        if (array_length(_follow_plan_lines) > 0) {
            var _plan_y2 = min(_detail_y2 - 10, _fd_y + 56 + 6 * 34);

            if (_plan_y2 > _fd_y + 90) {
                var _plan_content_y = hud_clients_block(_fblk_x1, _fd_y, _fblk_x2, _plan_y2, "ПЛАН ЛЕЧЕНИЯ", _text_dark);
                var _plan_limit = max(1, floor((_plan_y2 - _plan_content_y) / 34));

                hud_draw_string_list(_follow_plan_lines, _fblk_x1 + 14, _plan_content_y, 34, _plan_limit, _fblk_w - 28, _text_dark, _text_soft);
            }
        }
    }
}
