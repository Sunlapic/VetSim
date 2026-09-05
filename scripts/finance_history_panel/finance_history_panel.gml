/// finance_history_panel.gml
/// @description Пакет №287. Вкладка «ИСТОРИЯ» в окне ФИНАНСЫ.
///
/// Раскладка сверху вниз:
///   1. Три карточки итогов за период (доход / расход / прибыль).
///   2. Столбиковый график по дням: доход вверх, расход вниз.
///   3. Таблица по дням с прокруткой: приём, стационар, операционная,
///      зарплата, закупки, итог, баланс на конец дня.
///
/// Первая строка таблицы — сегодняшний, ещё не закрытый день. Он
/// помечен и отделён, чтобы не путать с завершёнными сутками.


// ═══════════════════════════════════════════════════════════════
// 1. ВСПОМОГАТЕЛЬНОЕ
// ═══════════════════════════════════════════════════════════════

/// Компактная запись денег: 12500 -> "12.5k", чтобы влезало в колонку.
function finance_history_money_short(_value) {
    var _abs = abs(_value);

    if (_abs >= 10000) {
        return string(round(_value / 100) / 10) + "k";
    }

    return string(round(_value));
}

/// Число со знаком: прибыль всегда читается однозначно.
function finance_history_signed(_value) {
    var _rounded = round(_value);

    if (_rounded > 0) return "+" + string(_rounded);

    return string(_rounded);
}


// ═══════════════════════════════════════════════════════════════
// 2. ГРАФИК
// ═══════════════════════════════════════════════════════════════

/// Столбики дохода и расхода по дням вокруг нулевой линии.
function finance_history_draw_chart(_records, _x1, _y1, _x2, _y2) {
    var _paper = make_color_rgb(248, 240, 224);
    var _line = make_color_rgb(180, 160, 140);
    var _ink = make_color_rgb(84, 68, 54);
    var _green = make_color_rgb(62, 112, 74);
    var _red = make_color_rgb(148, 74, 64);

    draw_set_color(_paper);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);
    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    var _count = array_length(_records);

    if (_count <= 0) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(_ink);
        ui_text_fit_center(
            (_x1 + _x2) * 0.5,
            (_y1 + _y2) * 0.5,
            "Пока нет закрытых дней",
            _x2 - _x1 - 40,
            UI_FS_ROW
        );
        return;
    }

    // Подпись слева съедает место, поэтому поле графика чуть уже.
    var _pad_x = 16;
    var _pad_top = 26;
    var _pad_bottom = 30;

    var _field_x1 = _x1 + _pad_x;
    var _field_x2 = _x2 - _pad_x;
    var _field_y1 = _y1 + _pad_top;
    var _field_y2 = _y2 - _pad_bottom;

    // Нулевая линия по центру: вверх доход, вниз расход.
    var _zero_y = (_field_y1 + _field_y2) * 0.5;
    var _half_h = (_field_y2 - _field_y1) * 0.5;

    var _peak = finance_history_peak(_records);

    draw_set_color(_line);
    draw_line(_field_x1, _zero_y, _field_x2, _zero_y);

    var _slot_w = (_field_x2 - _field_x1) / _count;
    var _bar_w = max(4, _slot_w * 0.30);
    var _bar_gap = max(2, _slot_w * 0.08);

    for (var _i = 0; _i < _count; _i++) {
        var _rec = _records[_i];

        if (!is_struct(_rec)) continue;

        var _center = _field_x1 + _slot_w * (_i + 0.5);

        var _income_h = _half_h * (_rec.income / _peak);
        var _expense_h = _half_h * (_rec.expense / _peak);

        // Доход — вверх от нуля.
        if (_income_h > 0.5) {
            draw_set_color(_green);
            draw_roundrect_ext(
                _center - _bar_w - _bar_gap * 0.5,
                _zero_y - _income_h,
                _center - _bar_gap * 0.5,
                _zero_y,
                3,
                3,
                false
            );
        }

        // Расход — вниз от нуля.
        if (_expense_h > 0.5) {
            draw_set_color(_red);
            draw_roundrect_ext(
                _center + _bar_gap * 0.5,
                _zero_y,
                _center + _bar_w + _bar_gap * 0.5,
                _zero_y + _expense_h,
                3,
                3,
                false
            );
        }

        // Номер дня подписываем не у каждого столбика, иначе каша.
        var _label_step = max(1, ceil(_count / 10));

        if (_i mod _label_step == 0 || _i == _count - 1) {
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            draw_set_color(_ink);
            ui_text_fit_center(
                _center,
                _field_y2 + 6,
                string(_rec.day),
                _slot_w * 1.6,
                UI_FS_SMALL
            );
        }
    }

    // Легенда и масштаб.
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_green);
    ui_text_fit_left(_x1 + 16, _y1 + 6, "ДОХОД", 200, UI_FS_SMALL);

    draw_set_color(_red);
    ui_text_fit_left(_x1 + 16 + 110, _y1 + 6, "РАСХОД", 200, UI_FS_SMALL);

    draw_set_halign(fa_right);
    draw_set_color(_ink);
    ui_text_fit_right(
        _x2 - 16,
        _y1 + 6,
        "макс $" + finance_history_money_short(_peak),
        260,
        UI_FS_SMALL
    );
}


// ═══════════════════════════════════════════════════════════════
// 3. ВКЛАДКА ЦЕЛИКОМ
// ═══════════════════════════════════════════════════════════════

function finance_ui_draw_history(_hud, _x1, _y1, _x2, _y2, _mouse_x, _mouse_y) {
    var _ink = make_color_rgb(84, 68, 54);
    var _text_dark = make_color_rgb(50, 38, 28);
    var _green = make_color_rgb(62, 112, 74);
    var _red = make_color_rgb(148, 74, 64);
    var _line = make_color_rgb(180, 160, 140);

    var _history = finance_history_get();
    var _today = finance_history_today_record();

    // ── 1. Карточки итогов за период ──
    var _totals = finance_history_totals(FINANCE_HISTORY_MAX_DAYS);
    var _days_closed = array_length(_history);

    var _card_h = 96;
    var _card_gap = 14;
    var _card_w = (_x2 - _x1 - _card_gap * 2) / 3;

    var _card_titles = ["ДОХОД ЗА ПЕРИОД", "РАСХОД ЗА ПЕРИОД", "ПРИБЫЛЬ"];
    var _card_values = [_totals.income, _totals.expense, _totals.profit];
    var _card_colors = [_green, _red, (_totals.profit >= 0) ? _green : _red];

    for (var _c = 0; _c < 3; _c++) {
        var _cx1 = _x1 + _c * (_card_w + _card_gap);
        var _cx2 = _cx1 + _card_w;

        draw_set_color(make_color_rgb(248, 240, 224));
        draw_roundrect_ext(_cx1, _y1, _cx2, _y1 + _card_h, 10, 10, false);
        draw_set_color(_line);
        draw_roundrect_ext(_cx1, _y1, _cx2, _y1 + _card_h, 10, 10, true);

        draw_set_color(_ink);
        ui_text_fit_center(
            (_cx1 + _cx2) * 0.5,
            _y1 + 14,
            _card_titles[_c],
            _card_w - 20,
            UI_FS_ROW
        );

        draw_set_color(_card_colors[_c]);
        ui_text_fit_center(
            (_cx1 + _cx2) * 0.5,
            _y1 + 48,
            (_c == 2)
                ? ("$ " + finance_history_signed(_card_values[_c]))
                : ("$ " + string(round(_card_values[_c]))),
            _card_w - 20,
            UI_FS_VALUE
        );
    }

    // Подпись: за сколько дней посчитано.
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_ink);
    ui_text_fit_left(
        _x1,
        _y1 + _card_h + 6,
        (_days_closed > 0)
            ? ("Закрытых дней в истории: " + string(_days_closed)
                + " (хранится до " + string(FINANCE_HISTORY_MAX_DAYS) + ")")
            : "История пуста: ни одного дня ещё не закрыто.",
        _x2 - _x1,
        UI_FS_SMALL
    );

    // ── 2. График ──
    var _chart_y1 = _y1 + _card_h + 30;
    var _chart_h = 190;
    var _chart_y2 = _chart_y1 + _chart_h;

    finance_history_draw_chart(_history, _x1, _chart_y1, _x2, _chart_y2);

    // ── 3. Таблица по дням ──
    var _table_y1 = _chart_y2 + 16;
    var _header_h = 34;
    var _row_h = 52;

    // Строки таблицы: сегодня + закрытые дни, новые сверху.
    var _rows = [];
    array_push(_rows, { rec : _today, is_today : true });

    for (var _i = array_length(_history) - 1; _i >= 0; _i--) {
        array_push(_rows, { rec : _history[_i], is_today : false });
    }

    var _rows_y1 = _table_y1 + _header_h;
    var _visible_rows = max(1, floor((_y2 - _rows_y1) / _row_h));

    finance_ui_prepare_scroll(
        _hud,
        array_length(_rows),
        _visible_rows,
        _x1,
        _rows_y1,
        _x2 - 22,
        _y2,
        _mouse_x,
        _mouse_y
    );

    // Колонки. Ширины подобраны так, чтобы влезали пятизначные суммы.
    var _table_w = _x2 - _x1 - 26;
    var _col_day = _x1 + 4;
    var _col_w_day = _table_w * 0.13;
    var _col_w_money = _table_w * 0.1235;

    var _headers = [
        "ДЕНЬ",
        "ПРИЁМ",
        "СТАЦ.",
        "ОПЕР.",
        "З/П",
        "ЗАКУПКИ",
        "ИТОГ",
        "БАЛАНС"
    ];

    // Шапка таблицы.
    draw_set_valign(fa_middle);
    draw_set_color(_ink);

    for (var _h = 0; _h < array_length(_headers); _h++) {
        var _hx = (_h == 0)
            ? _col_day
            : (_col_day + _col_w_day + (_h - 1) * _col_w_money);
        var _hw = (_h == 0) ? _col_w_day : _col_w_money;

        if (_h == 0) {
            draw_set_halign(fa_left);
            ui_text_fit_left(
                _hx + 8,
                _table_y1 + _header_h * 0.5,
                _headers[_h],
                _hw - 10,
                UI_FS_SMALL
            );
        } else {
            draw_set_halign(fa_right);
            ui_text_fit_right(
                _hx + _hw - 8,
                _table_y1 + _header_h * 0.5,
                _headers[_h],
                _hw - 10,
                UI_FS_SMALL
            );
        }
    }

    draw_set_color(_line);
    draw_line(_x1, _rows_y1 - 2, _x2 - 22, _rows_y1 - 2);

    // Строки.
    var _last = min(
        array_length(_rows),
        _hud.finance_price_scroll + _visible_rows
    );

    ui_clip_begin(_x1, _rows_y1, _x2, _y2);

    var _draw_y = _rows_y1;

    for (var _r = _hud.finance_price_scroll; _r < _last; _r++) {
        var _entry = _rows[_r];
        var _rec = _entry.rec;

        var _row_y1 = _draw_y + 2;
        var _row_y2 = _draw_y + _row_h - 4;

        var _hover = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _x1,
            _row_y1,
            _x2 - 22,
            _row_y2
        );

        ui_draw_row_bg(_x1, _row_y1, _x2 - 22, _row_y2, (_r mod 2 == 0), _hover);

        var _mid_y = (_row_y1 + _row_y2) * 0.5;

        // Колонка дня. Сегодняшний помечаем отдельно.
        draw_set_color(_entry.is_today ? _green : _text_dark);
        ui_text_fit_left(
            _col_day + 8,
            _mid_y,
            _entry.is_today
                ? ("День " + string(_rec.day) + " •")
                : ("День " + string(_rec.day)),
            _col_w_day - 10,
            UI_FS_ROW
        );

        // Денежные колонки.
        var _values = [
            _rec.reception,
            _rec.inpatient,
            _rec.operating,
            _rec.salary,
            _rec.purchases,
            _rec.profit,
            _rec.balance_end
        ];

        for (var _v = 0; _v < array_length(_values); _v++) {
            var _vx = _col_day + _col_w_day + _v * _col_w_money;
            var _value = _values[_v];

            // Зарплата и закупки — расход, поэтому красным.
            // Итог дня — по знаку. Остальное обычным цветом.
            var _color = _text_dark;

            if (_v == 3 || _v == 4) {
                _color = (_value > 0) ? _red : _text_dark;
            }
            else if (_v == 5) {
                _color = (_value > 0) ? _green : ((_value < 0) ? _red : _text_dark);
            }

            draw_set_color(_color);

            var _text = (_v == 5)
                ? finance_history_signed(_value)
                : string(round(_value));

            ui_text_fit_right(
                _vx + _col_w_money - 8,
                _mid_y,
                _text,
                _col_w_money - 10,
                UI_FS_ROW
            );
        }

        _draw_y += _row_h;
    }

    ui_clip_end();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
