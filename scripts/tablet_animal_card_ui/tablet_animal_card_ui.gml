/// tablet_animal_card_ui
/// @description Пакет №288. Помощники карточки питомца: крупные кнопки,
///              страницы правой колонки и эффект переворота листа.


// ═══════════════════════════════════════════════════════════════
// 1. МАСШТАБ ШРИФТА
//
// Старая карточка задавала размеры множителями 0.44…0.62 от базового
// _font_ui. Это давало примерно вдвое более мелкий текст, чем во всех
// остальных окнах игры, — читать было тяжело.
//
// Здесь собраны единые ступени. Все они заметно крупнее прежних, но
// сохраняют прежнюю иерархию: заголовок больше подписи, значение
// больше ярлыка.
// ═══════════════════════════════════════════════════════════════

#macro CARD_FS_TITLE     1.05
#macro CARD_FS_HEADER    0.86
#macro CARD_FS_LABEL     0.68
#macro CARD_FS_VALUE     0.76
#macro CARD_FS_BUTTON    0.96
#macro CARD_FS_SMALL     0.62
#macro CARD_FS_DIAGNOSIS 0.92

// ── ПАКЕТ №294: две ступени, добавленные для карточки владельца ──
//
// Обе подобраны так, чтобы В ПИКСЕЛЯХ совпасть с тем, что уже стоит
// в карточке владельца и что пользователь просил НЕ трогать:
// имя владельца и заголовок «ХАРАКТЕРИСТИКИ». Раньше эта карточка
// считала шрифт от множителя 1.30, а стандарт рассчитан на 1.22,
// поэтому прежние числа пересчитаны: 0.68*1.30/1.22 = 0.725
// и 0.62*1.30/1.22 = 0.66. Размер на экране остался прежним.
#macro CARD_FS_OWNER_NAME 0.725
#macro CARD_FS_SECTION    0.66


// ═══════════════════════════════════════════════════════════════
// 2. СТРАНИЦЫ ПРАВОЙ КОЛОНКИ
//
// Раньше справа всегда висели ДВЕ панели: «Обследования» сверху и
// «Лечение» снизу. Каждая получала половину высоты, кнопки в них были
// по 14–18 пикселей — на телефоне в такую не попасть пальцем.
//
// Теперь панель ОДНА и занимает всю высоту колонки, а внутри неё
// сменяются страницы. Кнопок столько же, но каждая почти вдвое выше.
// ═══════════════════════════════════════════════════════════════

#macro CARD_PAGE_DIAGNOSTICS 0
#macro CARD_PAGE_TREATMENT   1


// ═══════════════════════════════════════════════════════════════
// 3. КРУПНАЯ КНОПКА СПИСКА
//
// Отличия от старой tablet_animal_draw_treatment_button:
//   — высота задаётся вызывающим и теперь много больше;
//   — текст крупнее и переносится по словам;
//   — при наведении кнопка чуть светлеет и получает подсветку слева,
//     чтобы палец видел, что именно нажмётся;
//   — зелёная и красная заливка результата стали насыщеннее.
//
// _feedback_state: >0 верный выбор, <0 ошибочный, 0 ещё не нажимали.
// ═══════════════════════════════════════════════════════════════

function tablet_card_draw_list_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _label,
    _hovered,
    _enabled,
    _feedback_state,
    _font_ui
) {
    var _fill = make_color_rgb(240, 232, 214);
    var _line = make_color_rgb(58, 39, 24);
    var _text_color = make_color_rgb(50, 38, 28);
    var _accent = make_color_rgb(150, 130, 105);

    if (_feedback_state > 0) {
        _fill = make_color_rgb(198, 230, 190);
        _line = make_color_rgb(52, 108, 58);
        _accent = make_color_rgb(62, 132, 70);
        _text_color = make_color_rgb(30, 62, 34);
    }
    else if (_feedback_state < 0) {
        _fill = make_color_rgb(238, 200, 192);
        _line = make_color_rgb(136, 58, 52);
        _accent = make_color_rgb(160, 66, 58);
        _text_color = make_color_rgb(78, 28, 24);
    }
    else if (!_enabled) {
        _fill = make_color_rgb(208, 204, 197);
        _text_color = make_color_rgb(118, 115, 111);
        _accent = make_color_rgb(170, 167, 162);
    }
    else if (_hovered) {
        _fill = make_color_rgb(252, 246, 230);
        _accent = make_color_rgb(96, 140, 96);
    }

    // Лёгкая тень даёт кнопке объём и отделяет её от фона панели.
    draw_set_alpha(0.13);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 2, _y1 + 3, _x2 + 2, _y2 + 3, 8, 8, false);
    draw_set_alpha(1);

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, false);

    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, true);

    // Цветная полоска слева — метка состояния, видна боковым зрением.
    draw_set_color(_accent);
    draw_roundrect_ext(_x1 + 3, _y1 + 4, _x1 + 7, _y2 - 4, 2, 2, false);

    var _text_left = _x1 + 14;
    var _text_width = (_x2 - _x1) - 22;

    draw_set_color(_text_color);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(
        _text_left,
        (_y1 + _y2) * 0.5,
        _label,
        15,
        _text_width,
        CARD_FS_BUTTON * _font_ui,
        CARD_FS_BUTTON * _font_ui,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ═══════════════════════════════════════════════════════════════
// 4. ВЫСОТА КНОПКИ ПОД ЧИСЛО СТРОК
//
// Кнопки должны быть крупными, но список не должен вылезать за
// панель. Функция делит доступную высоту на количество строк и
// зажимает результат в разумные пределы.
//
// Нижняя граница 30 — даже при шести вариантах лечения кнопка
// остаётся вдвое выше прежних восемнадцати пикселей.
// ═══════════════════════════════════════════════════════════════

function tablet_card_button_height(_available_h, _count, _gap, _ui_scale) {
    if (_count <= 0) return 0;

    var _raw = (_available_h - (_count - 1) * _gap) / _count;

    // Потолок держит кнопку от раздувания, когда вариант всего один.
    _raw = min(_raw, 52 * _ui_scale);

    // Нижняя граница удобства — около 30 пунктов сетки. Но если
    // вариантов много (у лечения их бывает шесть), жёсткий минимум
    // выталкивает последнюю кнопку за край панели — расчёт давал
    // переполнение на шести вариантах. Лучше чуть ниже кнопка,
    // чем невидимая и ненажимаемая. Поэтому минимум уступает
    // реально доступному месту.
    var _floor_h = min(30 * _ui_scale, _raw);

    return max(_floor_h, min(_raw, 52 * _ui_scale));
}


// ═══════════════════════════════════════════════════════════════
// 5. ЗАКЛАДКИ СТРАНИЦ
//
// Две маленькие вкладки в шапке правой панели. Показывают, какая
// страница открыта, и позволяют вернуться к обследованиям после
// автоматического перехода на лечение.
//
// Возвращает индекс страницы, по которой кликнули, или -1.
// ═══════════════════════════════════════════════════════════════

function tablet_card_draw_page_tabs(
    _x1,
    _y1,
    _x2,
    _y2,
    _active_page,
    _treatment_unlocked,
    _mouse_x,
    _mouse_y,
    _font_ui
) {
    var _clicked_page = -1;
    var _gap = 6;
    var _half = ((_x2 - _x1) - _gap) * 0.5;

    var _titles = ["ОБСЛЕДОВАНИЯ", "ЛЕЧЕНИЕ"];

    for (var _page = 0; _page < 2; _page++) {
        var _tab_x1 = _x1 + _page * (_half + _gap);
        var _tab_x2 = _tab_x1 + _half;

        // Страница лечения закрыта, пока диагноз не подтверждён.
        var _page_enabled = (_page == CARD_PAGE_DIAGNOSTICS)
            || _treatment_unlocked;

        var _is_active = (_page == _active_page);
        var _hovered = _page_enabled
            && point_in_rectangle(_mouse_x, _mouse_y, _tab_x1, _y1, _tab_x2, _y2);

        var _fill = make_color_rgb(214, 202, 182);
        var _text_color = make_color_rgb(112, 96, 78);

        if (!_page_enabled) {
            _fill = make_color_rgb(206, 202, 195);
            _text_color = make_color_rgb(150, 146, 140);
        }
        else if (_is_active) {
            _fill = make_color_rgb(252, 246, 230);
            _text_color = make_color_rgb(50, 38, 28);
        }
        else if (_hovered) {
            _fill = make_color_rgb(238, 228, 208);
            _text_color = make_color_rgb(72, 58, 44);
        }

        draw_set_color(_fill);
        draw_roundrect_ext(_tab_x1, _y1, _tab_x2, _y2, 7, 7, false);

        draw_set_color(make_color_rgb(150, 130, 108));
        draw_roundrect_ext(_tab_x1, _y1, _tab_x2, _y2, 7, 7, true);

        // Активная закладка подчёркнута снизу — как язычок папки.
        if (_is_active) {
            draw_set_color(make_color_rgb(74, 49, 31));
            draw_rectangle(_tab_x1 + 6, _y2 - 3, _tab_x2 - 6, _y2 - 1, false);
        }

        draw_set_color(_text_color);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_ext_transformed(
            (_tab_x1 + _tab_x2) * 0.5,
            (_y1 + _y2) * 0.5,
            _titles[_page],
            13,
            (_tab_x2 - _tab_x1) - 10,
            CARD_FS_SMALL * _font_ui,
            CARD_FS_SMALL * _font_ui,
            0
        );

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

        if (_hovered && mouse_check_button_pressed(mb_left)) {
            _clicked_page = _page;
        }
    }

    return _clicked_page;
}


// ═══════════════════════════════════════════════════════════════
// 6. ЭФФЕКТ ПЕРЕВОРОТА ЛИСТА
//
// Когда диагноз подтверждён, правая страница переворачивается с
// обследований на лечение — как страница в бумажной карте.
//
// Как это устроено. Настоящего трёхмерного поворота в 2D-проекции
// нет, поэтому лист имитируется сжатием по ширине: первая половина
// анимации схлопывает страницу к правому краю, вторая раскрывает
// новую от того же края. В середине рисуется светлая полоса — ребро
// листа, ловящее блик.
//
// Функция возвращает множитель ширины 0…1. Вызывающий код рисует
// содержимое, сжатое к правому краю на эту долю. При таймере 0
// возвращает 1 — обычная неискажённая страница.
// ═══════════════════════════════════════════════════════════════

function tablet_card_flip_width_factor(_timer, _timer_max) {
    if (_timer <= 0) return 1;

    var _t = 1 - (_timer / max(1, _timer_max));

    // 0…0.5 — лист складывается, 0.5…1 — раскрывается обратно.
    if (_t < 0.5) {
        return max(0.02, 1 - _t * 2);
    }

    return max(0.02, (_t - 0.5) * 2);
}

// До середины анимации ещё видна старая страница, после — новая.
function tablet_card_flip_shows_new_page(_timer, _timer_max) {
    if (_timer <= 0) return true;

    var _t = 1 - (_timer / max(1, _timer_max));

    return (_t >= 0.5);
}

// Блик на ребре листа: ярче всего ровно в середине переворота.
function tablet_card_draw_flip_edge(
    _x1,
    _y1,
    _x2,
    _y2,
    _timer,
    _timer_max
) {
    if (_timer <= 0) exit;

    var _t = 1 - (_timer / max(1, _timer_max));
    var _edge_strength = 1 - abs(_t - 0.5) * 2;

    if (_edge_strength <= 0) exit;

    var _edge_x = _x2 - (_x2 - _x1) * 0.04;

    draw_set_alpha(0.55 * _edge_strength);
    draw_set_color(make_color_rgb(255, 250, 235));
    draw_rectangle(_edge_x - 5, _y1, _edge_x + 5, _y2, false);

    draw_set_alpha(0.30 * _edge_strength);
    draw_set_color(make_color_rgb(120, 96, 70));
    draw_rectangle(_edge_x + 5, _y1, _edge_x + 9, _y2, false);

    draw_set_alpha(1);
    draw_set_color(c_white);
}


// ═══════════════════════════════════════════════════════════════
// 7. ВСПЫШКА ДИАГНОЗА
//
// Момент, ради которого игрок и выбирал обследования. Раньше диагноз
// просто менял текст в углу — это легко пропустить.
//
// Теперь строка диагноза на секунду разгорается: расходящееся кольцо,
// тёплая заливка под текстом и пульсация самого текста. Затухание
// плавное, чтобы вспышка не выглядела как мигание ошибки.
//
// Возвращает множитель масштаба текста, чтобы вызывающий применил
// его к draw_text_transformed.
// ═══════════════════════════════════════════════════════════════

function tablet_card_draw_diagnosis_flash(
    _x1,
    _y1,
    _x2,
    _y2,
    _timer,
    _timer_max
) {
    if (_timer <= 0) return 1;

    var _t = _timer / max(1, _timer_max);
    var _grow = 1 - _t;

    // Расходящееся кольцо: радиус растёт, прозрачность падает.
    var _ring_pad = 4 + 26 * _grow;

    draw_set_alpha(0.42 * _t);
    draw_set_color(make_color_rgb(255, 214, 120));
    draw_roundrect_ext(
        _x1 - _ring_pad,
        _y1 - _ring_pad,
        _x2 + _ring_pad,
        _y2 + _ring_pad,
        12,
        12,
        true
    );

    draw_set_alpha(0.22 * _t);
    draw_roundrect_ext(
        _x1 - _ring_pad * 0.5,
        _y1 - _ring_pad * 0.5,
        _x2 + _ring_pad * 0.5,
        _y2 + _ring_pad * 0.5,
        10,
        10,
        true
    );

    // Тёплая подложка под самой строкой.
    draw_set_alpha(0.34 * _t);
    draw_set_color(make_color_rgb(255, 236, 176));
    draw_roundrect_ext(_x1 - 6, _y1 - 4, _x2 + 6, _y2 + 4, 8, 8, false);

    draw_set_alpha(1);
    draw_set_color(c_white);

    // Текст в начале вспышки крупнее на четверть, затем оседает.
    return 1 + 0.25 * _t;
}
