// ═══════════════════════════════════════════════════════════════════
// clinics_map_panel
//
// Экран карты: сама карта с четырьмя зданиями и карточка клиники,
// которая открывается по тапу.
//
// ПАКЕТ №325: сеть сокращена до четырёх клиник, а карточка показывает
// потолки развития клиники (кабинеты, койки, склад, штат) и ЕЁ
// собственную репутацию.
//
// Рисуется теми же кирпичиками, что и остальные окна игры —
// hud_draw_frosted_panel, hud_draw_button, ui_draw_close_button,
// макросы масштаба UI_FS_*. Поэтому карта не выбивается из стиля и
// одинаково ведёт себя на телефоне.
// ═══════════════════════════════════════════════════════════════════


/// clinics_map_building_rect(_hud, _index)
/// @description Прямоугольник здания на карте. Считается от размеров
///              панели, а не в абсолютных пикселях: поля map_x/map_y у
///              клиники хранятся долями, поэтому карта одинаково
///              раскладывается на любом экране.
function clinics_map_building_rect(_hud, _index) {

    var _x1 = _hud.map_panel_x1;
    var _y1 = _hud.map_panel_y1;
    var _x2 = _hud.map_panel_x2;
    var _y2 = _hud.map_panel_y2;

    // Поле карты: с отступом сверху под заголовок и снизу под подсказку.
    var _field_x1 = _x1 + 30;
    var _field_y1 = _y1 + 76;
    var _field_x2 = _x2 - 30;
    var _field_y2 = _y2 - 64;

    var _field_w = _field_x2 - _field_x1;
    var _field_h = _field_y2 - _field_y1;

    var _clinic = global.clinics[_index];

    // Размер здания растёт вместе с классом клиники: каморка
    // маленькая, столичный госпиталь заметно крупнее. Это читается
    // быстрее, чем цифры.
    var _size_step = 0;

    if (is_struct(_clinic) && variable_struct_exists(_clinic, "exam_max")) {
        _size_step = clamp(_clinic.exam_max - 1, 0, 5);
    }

    var _bw = 118 + _size_step * 16;
    var _bh = 92 + _size_step * 10;

    var _cx = _field_x1 + _field_w * _clinic.map_x;
    var _cy = _field_y1 + _field_h * _clinic.map_y;

    // Не даём зданию вылезти за поле карты.
    _cx = clamp(_cx, _field_x1 + _bw * 0.5, _field_x2 - _bw * 0.5);
    _cy = clamp(_cy, _field_y1 + _bh * 0.5, _field_y2 - _bh * 0.5);

    return {
        x1 : _cx - _bw * 0.5,
        y1 : _cy - _bh * 0.5,
        x2 : _cx + _bw * 0.5,
        y2 : _cy + _bh * 0.5
    };
}


/// clinics_map_card_rect(_hud)
/// @description Прямоугольник карточки клиники по центру экрана.
function clinics_map_card_rect(_hud) {

    var _gui_w = display_get_gui_width();
    var _gui_h = display_get_gui_height();

    var _w = min(620, _gui_w - 120);

    // ПАКЕТ №325: строк в карточке стало семь (добавились склад и
    // штат), поэтому карточка выше. 620 — с запасом на подпись
    // условия покупки под таблицей.
    var _h = min(620, _gui_h - 120);

    var _cx = _gui_w * 0.5;
    var _cy = _gui_h * 0.5;

    return {
        x1 : _cx - _w * 0.5,
        y1 : _cy - _h * 0.5,
        x2 : _cx + _w * 0.5,
        y2 : _cy + _h * 0.5
    };
}


/// clinics_map_card_buttons(_hud)
/// @description Три кнопки внизу карточки: действие, продажа, закрыть.
///              Высота 64 — палец попадает без промаха.
function clinics_map_card_buttons(_hud) {

    var _card = clinics_map_card_rect(_hud);

    var _pad = 22;
    var _bh = UI_BUTTON_H;
    var _gap = 12;

    var _by2 = _card.y2 - _pad;
    var _by1 = _by2 - _bh;

    // Верхний ряд — одна широкая кнопка (ВОЙТИ или КУПИТЬ).
    var _top_y2 = _by1 - _gap;
    var _top_y1 = _top_y2 - _bh;

    var _half = ((_card.x2 - _pad) - (_card.x1 + _pad) - _gap) * 0.5;

    return {
        main_x1 : _card.x1 + _pad,
        main_y1 : _top_y1,
        main_x2 : _card.x2 - _pad,
        main_y2 : _top_y2,

        sell_x1 : _card.x1 + _pad,
        sell_y1 : _by1,
        sell_x2 : _card.x1 + _pad + _half,
        sell_y2 : _by2,

        close_x1 : _card.x2 - _pad - _half,
        close_y1 : _by1,
        close_x2 : _card.x2 - _pad,
        close_y2 : _by2
    };
}


/// hud_draw_clinics_map(_hud)
/// @description Главная функция отрисовки. Зовётся из obj_UI_HUD -> Draw GUI.
function hud_draw_clinics_map(_hud) {

    if (!instance_exists(_hud)) return;
    if (!variable_instance_exists(_hud, "map_panel_open")) return;
    if (!_hud.map_panel_open) return;

    clinics_init();

    if (!variable_global_exists("clinics") || !is_array(global.clinics)) return;

    // ── ПАЛИТРА (та же, что во всех окнах) ──
    var _paper      = make_color_rgb(242, 232, 214);
    var _line_dark  = make_color_rgb(58, 39, 24);
    var _text_dark  = make_color_rgb(50, 38, 28);
    var _text_soft  = make_color_rgb(84, 68, 54);
    var _wood_dark  = make_color_rgb(74, 49, 31);
    var _green      = make_color_rgb(62, 112, 74);
    var _red        = make_color_rgb(148, 74, 64);
    var _grey       = make_color_rgb(126, 118, 106);

    var _x1 = _hud.map_panel_x1;
    var _y1 = _hud.map_panel_y1;
    var _x2 = _hud.map_panel_x2;
    var _y2 = _hud.map_panel_y2;

    hud_draw_frosted_panel(_x1, _y1, _x2, _y2);

    // ── ЗАГОЛОВОК ──
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_wood_dark);
    draw_text_transformed(_x1 + 24, _y1 + 16, "КАРТА КЛИНИК", UI_FS_TITLE, UI_FS_TITLE, 0);

    // Счётчик и общий кошелёк.
    var _close_rect = ui_close_button_rect(_x1, _y1, _x2, _y2);

    draw_set_halign(fa_right);
    draw_set_color(_text_soft);
    draw_text_transformed(
        _close_rect.x1 - 18,
        _y1 + 34,
        "В СОБСТВЕННОСТИ " + string(clinics_count_owned())
            + " / " + string(array_length(global.clinics)),
        UI_FS_ROW,
        UI_FS_ROW,
        0
    );
    draw_set_halign(fa_left);

    ui_draw_close_button(
        _hud.map_close_x1,
        _hud.map_close_y1,
        _hud.map_close_x2,
        _hud.map_close_y2,
        _hud.hover_map_close
    );

    // ── ПОЛЕ КАРТЫ ──
    // Пока это просто подложка. Дизайн предполагает, что позже сюда
    // ляжет картинка города спрайтом, а здания останутся сверху.
    var _field_x1 = _x1 + 30;
    var _field_y1 = _y1 + 76;
    var _field_x2 = _x2 - 30;
    var _field_y2 = _y2 - 64;

    draw_set_color(make_color_rgb(226, 214, 192));
    draw_rectangle(_field_x1, _field_y1, _field_x2, _field_y2, false);

    // Лёгкая сетка кварталов, чтобы пустое поле не выглядело browser-окном.
    draw_set_alpha(0.20);
    draw_set_color(make_color_rgb(190, 176, 152));

    var _grid = 64;

    for (var _gx = _field_x1 + _grid; _gx < _field_x2; _gx += _grid) {
        draw_line(_gx, _field_y1, _gx, _field_y2);
    }

    for (var _gy = _field_y1 + _grid; _gy < _field_y2; _gy += _grid) {
        draw_line(_field_x1, _gy, _field_x2, _gy);
    }

    draw_set_alpha(1);

    draw_set_color(_line_dark);
    draw_rectangle(_field_x1, _field_y1, _field_x2, _field_y2, true);

    // ── ДОРОГА, СОЕДИНЯЮЩАЯ КЛИНИКИ ──
    // Тонкая линия по порядку номеров: показывает, куда развиваться
    // дальше, и оживляет пустую карту.
    draw_set_alpha(0.35);
    draw_set_color(make_color_rgb(168, 152, 126));

    for (var _r = 0; _r < array_length(global.clinics) - 1; _r++) {
        var _ra = clinics_map_building_rect(_hud, _r);
        var _rb = clinics_map_building_rect(_hud, _r + 1);

        draw_line_width(
            (_ra.x1 + _ra.x2) * 0.5,
            (_ra.y1 + _ra.y2) * 0.5,
            (_rb.x1 + _rb.x2) * 0.5,
            (_rb.y1 + _rb.y2) * 0.5,
            4
        );
    }

    draw_set_alpha(1);

    // ── ЗДАНИЯ ──
    for (var _i = 0; _i < array_length(global.clinics); _i++) {

        var _clinic = global.clinics[_i];

        if (!is_struct(_clinic)) continue;

        var _rect = clinics_map_building_rect(_hud, _i);
        var _hover = (_hud.hover_map_building == _i);
        var _is_active = (_clinic.id == global.active_clinic);

        // Цвет: своя — тёплая бумага, чужая — серая.
        var _fill = _clinic.owned ? _paper : make_color_rgb(206, 200, 190);

        if (_hover) {
            _fill = _clinic.owned
                ? make_color_rgb(252, 244, 228)
                : make_color_rgb(222, 216, 206);
        }

        // Тень.
        draw_set_alpha(0.18);
        draw_set_color(c_black);
        draw_rectangle(_rect.x1 + 4, _rect.y1 + 5, _rect.x2 + 4, _rect.y2 + 5, false);
        draw_set_alpha(1);

        draw_set_color(_fill);
        draw_rectangle(_rect.x1, _rect.y1, _rect.x2, _rect.y2, false);

        // Рамка: у активной клиники толще и темнее — сразу видно, где вы.
        draw_set_color(_is_active ? _green : _line_dark);
        draw_rectangle(_rect.x1, _rect.y1, _rect.x2, _rect.y2, true);

        if (_is_active) {
            draw_rectangle(_rect.x1 + 1, _rect.y1 + 1, _rect.x2 - 1, _rect.y2 - 1, true);
            draw_rectangle(_rect.x1 + 2, _rect.y1 + 2, _rect.x2 - 2, _rect.y2 - 2, true);
        }

        // ── КРЫША ──
        // Простой треугольник: без него прямоугольник не читается
        // как здание.
        draw_set_color(_clinic.owned ? _wood_dark : make_color_rgb(150, 143, 133));
        draw_triangle(
            _rect.x1 - 6, _rect.y1,
            _rect.x2 + 6, _rect.y1,
            (_rect.x1 + _rect.x2) * 0.5, _rect.y1 - 26,
            false
        );

        // ── НАЗВАНИЕ ──
        // ui_text_fit_* сами выставляют выравнивание и возвращают его
        // обратно, поэтому halign/valign здесь задавать не нужно.
        draw_set_color(_clinic.owned ? _text_dark : make_color_rgb(96, 90, 82));

        ui_text_fit_center(
            (_rect.x1 + _rect.x2) * 0.5,
            _rect.y1 + 10,
            _clinic.name,
            (_rect.x2 - _rect.x1) - 12,
            UI_FS_SMALL
        );

        // ── ТАБЛИЧКА ──
        // Своя клиника показывает доход, чужая — цену.
        if (_clinic.owned) {
            draw_set_color(_green);

            ui_text_fit_center(
                (_rect.x1 + _rect.x2) * 0.5,
                _rect.y2 - 22,
                "+$" + string(_clinic.income_per_day) + "/д",
                (_rect.x2 - _rect.x1) - 12,
                UI_FS_ROW
            );
        }
        else {
            var _afford = (global.clinic_money >= _clinic.price);

            draw_set_color(_afford ? _text_dark : _red);

            ui_text_fit_center(
                (_rect.x1 + _rect.x2) * 0.5,
                _rect.y2 - 22,
                "$" + string(_clinic.price),
                (_rect.x2 - _rect.x1) - 12,
                UI_FS_ROW
            );

            // Замок для тех, что ещё не по карману.
            if (!_afford) {
                draw_set_color(_grey);
                ui_text_fit_center(
                    (_rect.x1 + _rect.x2) * 0.5,
                    _rect.y1 + 32,
                    "ЗАКРЫТО",
                    (_rect.x2 - _rect.x1) - 12,
                    UI_FS_SMALL
                );
            }
        }

    }

    // ── ПОДСКАЗКА ВНИЗУ ──
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_text_soft);
    draw_text_transformed(
        _x1 + 30,
        _y2 - 50,
        "Нажмите на клинику, чтобы посмотреть карточку.   Кошелёк сети: $"
            + string(global.clinic_money),
        UI_FS_ROW,
        UI_FS_ROW,
        0
    );

    // ── КАРТОЧКА КЛИНИКИ ПОВЕРХ КАРТЫ ──
    if (_hud.map_card_clinic_id > 0) {
        hud_draw_clinic_card(_hud);
    }
}


/// hud_draw_clinic_card(_hud)
/// @description Карточка выбранной клиники: параметры и кнопки.
function hud_draw_clinic_card(_hud) {

    var _clinic = clinics_get(_hud.map_card_clinic_id);

    if (!is_struct(_clinic)) return;

    var _paper      = make_color_rgb(242, 232, 214);
    var _paper_hi   = make_color_rgb(252, 244, 228);
    var _paper_act  = make_color_rgb(228, 214, 190);
    var _line_dark  = make_color_rgb(58, 39, 24);
    var _text_dark  = make_color_rgb(50, 38, 28);
    var _text_soft  = make_color_rgb(84, 68, 54);
    var _wood_dark  = make_color_rgb(74, 49, 31);
    var _green      = make_color_rgb(62, 112, 74);
    var _red        = make_color_rgb(148, 74, 64);

    var _card = clinics_map_card_rect(_hud);
    var _btn = clinics_map_card_buttons(_hud);

    // Затемняем карту под карточкой, чтобы взгляд не расфокусировался.
    draw_set_alpha(0.45);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);

    hud_draw_frosted_panel(_card.x1, _card.y1, _card.x2, _card.y2);

    // ── ЗАГОЛОВОК ──
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_wood_dark);

    ui_text_fit_left(
        _card.x1 + 24,
        _card.y1 + 18,
        _clinic.name,
        (_card.x2 - _card.x1) - 48,
        UI_FS_TITLE
    );

    // ── СТАТУС ──
    var _status_text = "НЕ КУПЛЕНА";
    var _status_color = _text_soft;

    if (_clinic.owned) {
        if (_clinic.id == global.active_clinic) {
            _status_text = "ВЫ ЗДЕСЬ";
            _status_color = _green;
        }
        else {
            _status_text = "ВАША КЛИНИКА";
            _status_color = _text_dark;
        }
    }

    draw_set_color(_status_color);
    draw_text_transformed(
        _card.x1 + 24,
        _card.y1 + 56,
        _status_text,
        UI_FS_HEADER,
        UI_FS_HEADER,
        0
    );

    // ── СТРОКИ ПАРАМЕТРОВ ──
    var _row_x = _card.x1 + 24;
    var _row_w = (_card.x2 - _card.x1) - 48;
    var _row_y = _card.y1 + 96;
    var _row_h = UI_ROW_H;
    var _row_i = 0;

    // Потолки развития этой клиники. Репутация — ЕЁ собственная, из
    // кармана клиники, а не общая по сети.
    var _storage_names = ["малый", "средний", "большой"];
    var _storage_index = clamp(round(_clinic.storage_size), 0, 2);

    var _rows = [
        ["Кабинеты приёма", "до " + string(_clinic.exam_max)],
        [
            "Койки стационара",
            (_clinic.bed_max > 0) ? ("до " + string(_clinic.bed_max)) : "нет"
        ],
        ["Операционная", _clinic.has_operating ? "есть" : "нет"],
        ["Склад", _storage_names[_storage_index]],
        ["Сотрудники", "до " + string(_clinic.hire_max)],
        ["Доход в день", "$" + string(_clinic.income_per_day)]
    ];

    if (_clinic.owned) {
        array_push(_rows, [
            "Репутация",
            string(
                script_exists(asset_get_index("clinic_reputation_read"))
                    ? clinic_reputation_read(_clinic.id)
                    : 0
            )
        ]);
    }
    else {
        array_push(_rows, ["Цена", "$" + string(_clinic.price)]);
    }

    for (var _r = 0; _r < array_length(_rows); _r++) {

        var _ry1 = _row_y + _row_i * _row_h;
        var _ry2 = _ry1 + _row_h;

        ui_draw_row_bg(_row_x, _ry1, _row_x + _row_w, _ry2, (_row_i mod 2) == 0, false);

        draw_set_color(_text_soft);
        // ui_text_fit_middle, а не _left: в строке таблицы текст надо
        // центрировать по высоте, иначе подпись прилипает к верхнему краю.
        ui_text_fit_middle(_row_x + 12, (_ry1 + _ry2) * 0.5, _rows[_r][0], _row_w * 0.6, UI_FS_ROW);

        draw_set_color(_text_dark);
        ui_text_fit_right(_row_x + _row_w - 12, (_ry1 + _ry2) * 0.5, _rows[_r][1], _row_w * 0.35, UI_FS_VALUE);

        _row_i += 1;
    }

    // ── УСЛОВИЕ ОТКРЫТИЯ ──
    if (!_clinic.owned && string_length(_clinic.unlock_note) > 0) {
        draw_set_color(_text_soft);
        draw_text_transformed(
            _row_x,
            _row_y + _row_i * _row_h + 12,
            _clinic.unlock_note,
            UI_FS_SMALL,
            UI_FS_SMALL,
            0
        );
    }

    // ── ПОДТВЕРЖДЕНИЕ ПРОДАЖИ ──
    // Продажа необратима, поэтому спрашиваем отдельно, как и решили
    // в дизайне.
    if (_hud.map_confirm_sell) {

        draw_set_color(_red);
        draw_set_halign(fa_center);

        var _sell_sum = clinics_sell_price(_clinic);

        ui_text_fit_center(
            (_card.x1 + _card.x2) * 0.5,
            _btn.main_y1 - 34,
            "Продать за $" + string(_sell_sum) + "? Это необратимо.",
            (_card.x2 - _card.x1) - 48,
            UI_FS_ROW
        );

        draw_set_halign(fa_left);

        hud_draw_button(
            _btn.sell_x1, _btn.sell_y1, _btn.sell_x2, _btn.sell_y2,
            "ДА, ПРОДАТЬ", false, _hud.hover_map_sell,
            _paper, _paper_hi, _paper_act, _line_dark, _red
        );

        hud_draw_button(
            _btn.close_x1, _btn.close_y1, _btn.close_x2, _btn.close_y2,
            "ОТМЕНА", false, _hud.hover_map_close_card,
            _paper, _paper_hi, _paper_act, _line_dark, _text_dark
        );

        return;
    }

    // ── ГЛАВНАЯ КНОПКА ──
    if (_clinic.owned) {

        // ═══════════════════════════════════════════════════════
        // ПАКЕТ №303: «ВЫ ЗДЕСЬ» СЧИТАЕТСЯ ПО РЕАЛЬНОЙ КОМНАТЕ
        //
        // Было: _clinic.id == global.active_clinic. Этого мало.
        // active_clinic — «чья клиника ваша сейчас», и у клиники №1
        // он равен 1 всегда, даже когда игрок физически стоит в
        // тестовой комнате room1. Кнопка честно писала «ВЫ УЖЕ
        // ЗДЕСЬ» и не пускала обратно в собственную клинику.
        //
        // Теперь сверяемся с комнатой, в которой игрок находится
        // на самом деле: room. Совпало — значит правда здесь.
        //
        // Заодно снята заглушка «ВОЙТИ (СКОРО)»: переезд появился в
        // пакете 301, комната клиники №1 собрана в 302.
        // ═══════════════════════════════════════════════════════

        var _clinic_room = asset_get_index(string(_clinic.room_name));

        var _is_here = (
            string(_clinic.room_name) != ""
            && _clinic_room != -1
            && room == _clinic_room
        );

        // Комната ещё не построена — войти некуда, и надпись об этом
        // говорит прямо. Так у клиник 2-6 кнопка остаётся честной.
        var _room_ready = (
            string(_clinic.room_name) != ""
            && _clinic_room != -1
            && room_exists(_clinic_room)
        );

        var _main_label = "ВОЙТИ";

        if (_is_here) _main_label = "ВЫ УЖЕ ЗДЕСЬ";
        else if (!_room_ready) _main_label = "ПОМЕЩЕНИЕ НЕ ГОТОВО";

        hud_draw_button(
            _btn.main_x1, _btn.main_y1, _btn.main_x2, _btn.main_y2,
            _main_label,
            false,
            (!_is_here) && _room_ready && _hud.hover_map_main,
            _paper, _paper_hi, _paper_act, _line_dark,
            (_is_here || !_room_ready) ? _text_soft : _text_dark
        );

        var _sell_check = clinics_can_sell(_clinic);

        hud_draw_button(
            _btn.sell_x1, _btn.sell_y1, _btn.sell_x2, _btn.sell_y2,
            "ПРОДАТЬ $" + string(clinics_sell_price(_clinic)),
            false,
            _sell_check.ok && _hud.hover_map_sell,
            _paper, _paper_hi, _paper_act, _line_dark,
            _sell_check.ok ? _red : make_color_rgb(150, 143, 133)
        );

        // Причина, почему продать нельзя, — прямо под кнопкой.
        if (!_sell_check.ok) {
            draw_set_color(_text_soft);
            draw_set_halign(fa_center);
            ui_text_fit_center(
                (_btn.sell_x1 + _btn.sell_x2) * 0.5,
                _btn.sell_y2 + 14,
                _sell_check.reason,
                (_btn.sell_x2 - _btn.sell_x1),
                UI_FS_SMALL
            );
            draw_set_halign(fa_left);
        }
    }
    else {

        var _buy_check = clinics_can_buy(_clinic);

        hud_draw_button(
            _btn.main_x1, _btn.main_y1, _btn.main_x2, _btn.main_y2,
            "КУПИТЬ ЗА $" + string(_clinic.price),
            false,
            _buy_check.ok && _hud.hover_map_main,
            _paper, _paper_hi, _paper_act, _line_dark,
            _buy_check.ok ? _green : make_color_rgb(150, 143, 133)
        );

        if (!_buy_check.ok) {
            draw_set_color(_red);
            draw_set_halign(fa_center);
            ui_text_fit_center(
                (_btn.main_x1 + _btn.main_x2) * 0.5,
                _btn.main_y2 + 14,
                _buy_check.reason,
                (_btn.main_x2 - _btn.main_x1),
                UI_FS_SMALL
            );
            draw_set_halign(fa_left);
        }
    }

    // ── ЗАКРЫТЬ ──
    hud_draw_button(
        _btn.close_x1, _btn.close_y1, _btn.close_x2, _btn.close_y2,
        "ЗАКРЫТЬ", false, _hud.hover_map_close_card,
        _paper, _paper_hi, _paper_act, _line_dark, _text_dark
    );
}
