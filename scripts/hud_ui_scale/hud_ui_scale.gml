/// hud_ui_scale.gml
/// @description Пакет №174. Общий «UI-кит» для крупного интерфейса.
///
/// Игра телефонная, поэтому правило одно: текст рисуется максимально крупно,
/// но НИКОГДА не вылезает за отведённое место и не налезает на соседнюю строку.
/// Для этого масштаб не задаётся вслепую, а подгоняется под ширину (и при
/// необходимости под высоту строки).
///
/// Пользоваться так:
///     ui_text_fit_left(_x, _y, "Текст", _max_w, UI_FS_ROW);
///     ui_text_fit_center(_cx, _cy, "Текст", _max_w, UI_FS_TITLE);
///     var _s = ui_fit_scale(_text, _max_w, UI_FS_ROW);   // если нужен сам масштаб


// ═══════════════════════════════════════════════════════════════
// 1. СТАНДАРТНЫЕ МАСШТАБЫ
// Меняются в одном месте — меняются во всей игре.
// ═══════════════════════════════════════════════════════════════

#macro UI_FS_TITLE   1.75   // заголовок панели, название карточки
#macro UI_FS_HEADER  1.55   // заголовок секции, шапка таблицы
#macro UI_FS_BUTTON  1.60   // текст на кнопке
#macro UI_FS_ROW     1.25   // строка списка, подпись, подсказка
#macro UI_FS_VALUE   1.45   // цифра, цена, значение
#macro UI_FS_SMALL   1.10   // сноска, служебная мелочь

// Минимальный масштаб: ниже него текст не ужимается, лучше обрезать строку.
#macro UI_FS_MIN     0.72

// Рекомендуемые высоты (чтобы строки не слипались).
#macro UI_ROW_H      44
#macro UI_HEADER_H   56
#macro UI_BUTTON_H   64


// ═══════════════════════════════════════════════════════════════
// 2. ПОДБОР МАСШТАБА
// ═══════════════════════════════════════════════════════════════

/// Масштаб, при котором строка влезает в ширину _max_w.
function ui_fit_scale(_text, _max_w, _base) {
    var _str = string(_text);

    if (_str == "") return _base;
    if (_max_w <= 0) return _base;

    var _w = string_width(_str) * _base;

    if (_w <= _max_w) return _base;

    return max(UI_FS_MIN, _base * (_max_w / _w));
}

/// То же, но дополнительно не выше _max_h — строка не налезет на соседнюю.
function ui_fit_scale_box(_text, _max_w, _max_h, _base) {
    var _scale = ui_fit_scale(_text, _max_w, _base);

    if (_max_h > 0) {
        var _h = string_height(string(_text)) * _scale;

        if (_h > _max_h) {
            _scale = max(UI_FS_MIN, _scale * (_max_h / _h));
        }
    }

    return _scale;
}

/// Обрезать строку многоточием, если даже на минимальном масштабе не влезает.
function ui_text_clip(_text, _max_w, _scale) {
    var _str = string(_text);

    if (string_width(_str) * _scale <= _max_w) return _str;

    while (
        string_length(_str) > 1
        && string_width(_str + "...") * _scale > _max_w
    ) {
        _str = string_copy(_str, 1, string_length(_str) - 1);
    }

    return _str + "...";
}


// ═══════════════════════════════════════════════════════════════
// 3. РИСОВАНИЕ ТЕКСТА
// Выравнивание выставляется внутри и возвращается к fa_left/fa_top.
// ═══════════════════════════════════════════════════════════════

function ui_text_fit_left(_x, _y, _text, _max_w, _base) {
    var _scale = ui_fit_scale(_text, _max_w, _base);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text_transformed(_x, _y, string(_text), _scale, _scale, 0);

    return _scale;
}

function ui_text_fit_middle(_x, _cy, _text, _max_w, _base) {
    var _scale = ui_fit_scale(_text, _max_w, _base);

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text_transformed(_x, _cy, string(_text), _scale, _scale, 0);

    draw_set_valign(fa_top);

    return _scale;
}

function ui_text_fit_center(_cx, _cy, _text, _max_w, _base) {
    var _scale = ui_fit_scale(_text, _max_w, _base);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(_cx, _cy, string(_text), _scale, _scale, 0);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    return _scale;
}

function ui_text_fit_right(_x, _cy, _text, _max_w, _base) {
    var _scale = ui_fit_scale(_text, _max_w, _base);

    draw_set_halign(fa_right);
    draw_set_valign(fa_middle);
    draw_text_transformed(_x, _cy, string(_text), _scale, _scale, 0);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    return _scale;
}

/// Строка в отведённой полосе: не шире _max_w и не выше _row_h.
function ui_text_row(_x, _row_y, _row_h, _text, _max_w, _base) {
    var _scale = ui_fit_scale_box(_text, _max_w, _row_h - 6, _base);

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text_transformed(_x, _row_y + _row_h * 0.5, string(_text), _scale, _scale, 0);
    draw_set_valign(fa_top);

    return _scale;
}


// ═══════════════════════════════════════════════════════════════
// 4. ГОТОВЫЕ ЭЛЕМЕНТЫ
// ═══════════════════════════════════════════════════════════════

/// Заголовок секции: деревянная плашка со светлой надписью.
function ui_draw_section_header(_x1, _y1, _x2, _y2, _text) {
    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 2, _y1 + 3, _x2 + 2, _y2 + 3, 12, 12, false);
    draw_set_alpha(1);

    draw_set_color(make_color_rgb(74, 49, 31));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
    draw_set_color(make_color_rgb(150, 107, 73));
    draw_roundrect_ext(_x1 + 2, _y1 + 2, _x2 - 2, _y2 - 2, 10, 10, true);

    draw_set_color(make_color_rgb(255, 233, 194));
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5,
        _text,
        (_x2 - _x1) - 32,
        UI_FS_HEADER
    );
}

/// Полоска строки списка: чередование фона + рамка при наведении.
function ui_draw_row_bg(_x1, _y1, _x2, _y2, _even, _hover) {
    if (_hover) {
        draw_set_color(make_color_rgb(250, 242, 226));
    } else {
        draw_set_color(
            _even
                ? make_color_rgb(242, 232, 214)
                : make_color_rgb(234, 223, 203)
        );
    }

    draw_roundrect_ext(_x1, _y1, _x2, _y2, 9, 9, false);

    draw_set_color(make_color_rgb(150, 107, 73));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 9, 9, true);

    if (_hover) {
        draw_set_color(make_color_rgb(74, 49, 31));
        draw_roundrect_ext(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, 8, 8, true);
    }
}

/// Значок-бейдж со значением (цена, счётчик, статус).
function ui_draw_badge(_x1, _y1, _x2, _y2, _text, _bg, _border, _ink) {
    draw_set_color(_bg);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 9, 9, false);
    draw_set_color(_border);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 9, 9, true);
    draw_roundrect_ext(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, 8, 8, true);

    draw_set_color(_ink);
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5,
        _text,
        (_x2 - _x1) - 18,
        UI_FS_VALUE
    );
}


// ═══════════════════════════════════════════════════════════════
// 5. ЕДИНЫЙ СТИЛЬ ВКЛАДОК (пакет №180)
//
// Эталон — вкладки «РАЗВИТИЕ» и «СКЛАД» в панели КЛИНИКА.
// Один размер, один шрифт, одна форма во всех окнах игры.
// Меняете макросы — меняются все вкладки разом.
// ═══════════════════════════════════════════════════════════════

#macro UI_TAB_W   230
#macro UI_TAB_H   64
#macro UI_TAB_GAP 14
#macro UI_TAB_RADIUS 14
#macro UI_TAB_FS  1.70

// Позиция вкладки номер _index в ряду, начинающемся с _x1.
function ui_tab_x1(_x1, _index) {
    return _x1 + _index * (UI_TAB_W + UI_TAB_GAP);
}

function ui_tab_x2(_x1, _index) {
    return ui_tab_x1(_x1, _index) + UI_TAB_W;
}

// Ширина ряда из _count вкладок.
function ui_tabs_row_width(_count) {
    return _count * UI_TAB_W + (_count - 1) * UI_TAB_GAP;
}

/// Канонная вкладка: тень, скруглённые углы, двойная рамка, крупный текст.
function ui_draw_tab(_x1, _y1, _x2, _y2, _text, _active, _hover) {
    var _paper = make_color_rgb(242, 232, 214);
    var _paper_hover = make_color_rgb(248, 238, 220);
    var _paper_active = make_color_rgb(220, 202, 172);
    var _line_dark = make_color_rgb(58, 39, 24);
    var _text_dark = make_color_rgb(50, 38, 28);

    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(
        _x1 + 3, _y1 + 4, _x2 + 3, _y2 + 4,
        UI_TAB_RADIUS, UI_TAB_RADIUS, false
    );
    draw_set_alpha(1);

    draw_set_color(_active ? _paper_active : (_hover ? _paper_hover : _paper));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, UI_TAB_RADIUS, UI_TAB_RADIUS, false);

    draw_set_color(_line_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, UI_TAB_RADIUS, UI_TAB_RADIUS, true);
    draw_roundrect_ext(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, UI_TAB_RADIUS - 1, UI_TAB_RADIUS - 1, true);
    draw_roundrect_ext(_x1 + 2, _y1 + 2, _x2 - 2, _y2 - 2, UI_TAB_RADIUS - 2, UI_TAB_RADIUS - 2, true);

    // Активная вкладка подчёркнута снизу.
    if (_active) {
        draw_set_color(make_color_rgb(104, 137, 91));
        draw_roundrect_ext(_x1 + 14, _y2 - 9, _x2 - 14, _y2 - 5, 2, 2, false);
    }

    draw_set_color(_text_dark);
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5 + 1,
        _text,
        (_x2 - _x1) - 24,
        UI_TAB_FS
    );
}

/// Крестик закрытия в том же стиле: квадрат со стороной UI_TAB_H.
function ui_draw_close_button(_x1, _y1, _x2, _y2, _hover) {
    var _paper = make_color_rgb(242, 232, 214);
    var _paper_hover = make_color_rgb(250, 226, 220);
    var _line_dark = make_color_rgb(58, 39, 24);
    var _red = make_color_rgb(148, 74, 64);

    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(
        _x1 + 3, _y1 + 4, _x2 + 3, _y2 + 4,
        UI_TAB_RADIUS, UI_TAB_RADIUS, false
    );
    draw_set_alpha(1);

    draw_set_color(_hover ? _paper_hover : _paper);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, UI_TAB_RADIUS, UI_TAB_RADIUS, false);

    draw_set_color(_line_dark);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, UI_TAB_RADIUS, UI_TAB_RADIUS, true);
    draw_roundrect_ext(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, UI_TAB_RADIUS - 1, UI_TAB_RADIUS - 1, true);

    draw_set_color(_red);
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5 + 1,
        "X",
        (_x2 - _x1) - 16,
        UI_TAB_FS
    );
}
