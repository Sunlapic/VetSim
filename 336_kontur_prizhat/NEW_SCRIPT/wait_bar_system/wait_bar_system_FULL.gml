/// wait_bar_system.gml
/// @description Пакет №330: шкалы ожидания над головой — 6 вариантов
///              оформления и свой цвет на каждый тип ожидания.
///
/// ═══════════════════════════════════════════════════════════════
/// ЧТО ЭТО
///
/// Одна функция draw_wait_bar() рисует шкалу поверх головы
/// персонажа. Внешний вид выбирается макросом WAIT_BAR_STYLE (1–6),
/// поэтому переключить оформление на всю игру — поменять одну цифру.
///
/// В игре клавиша V (режим отладки) показывает все шесть вариантов
/// сразу над главным героем, с подписями. Выбрал номер — вписал его
/// в WAIT_BAR_STYLE.
///
/// ═══════════════════════════════════════════════════════════════
/// КУДА ВСТАЁТ ПОЛОСКА
///
/// Раньше смещение было зашито: −142 для стоящего и −82 для
/// сидящего. Замер по спрайтам показал, откуда проблема:
///
///   spr_human_FR_walk  — макушка на y − 116  (полоска на −142: верно)
///   spr_human_FR_sit   — макушка на y − 95   (полоска на −82:  на 13
///                                             пикселей НИЖЕ макушки,
///                                             то есть на глазах)
///
/// Спрайт 400x400, origin (200, 300), скейл 0.5: фигура стоя
/// начинается со строки 68 кадра → y + (68 − 300) × 0.5 = y − 116;
/// сидя — со строки 111 → y − 95 (у сидящего ещё _fy = +21 в
/// par_visitors → y − 73).
///
/// Теперь оба значения — макросы ниже, и у полоски всегда один и тот
/// же зазор над макушкой: WAIT_BAR_GAP.
///
/// ПАКЕТ №331: полоска стала УЖЕ (высота 6) и без серой дорожки
/// внутри. Рисуются только цветная заливка и тонкая чёрная обводка,
/// и обводка обнимает саму заливку — полоска выглядит как цветная
/// капсула, а не как «прогресс-бар с фоном».
///
/// ПАКЕТ №333: обводка снова НЕ меняется при убыли — это постоянная
/// капсула со скруглёнными краями, которая ПОСТЕПЕННО ПУСТЕЕТ:
/// цвет внутри укорачивается, пустая часть прозрачная.
///
/// ПАКЕТ №334: торцы капсулы рисуются ЯВНЫМИ кругами (draw_circle),
/// а не скруглённым прямоугольником: на скриншоте из игры видно,
/// что draw_roundrect_ext с маленьким радиусом даёт «квадратные»
/// углы. Круг остаётся кругом в любой версии GameMaker.
/// ═══════════════════════════════════════════════════════════════

// Выбранный вариант оформления: 1–6. ПАКЕТ №332: выбрано
// «СТЕКЛО» по решению пользователя.
#macro WAIT_BAR_STYLE 2

// Зазор между макушкой и полоской, пикселей.
#macro WAIT_BAR_GAP 10

// Макушка стоящего/идущего относительно y (по спрайту walk/idle).
#macro WAIT_BAR_HEAD_STAND -116

// Макушка сидящего относительно y (по спрайту sit с поправкой +21).
#macro WAIT_BAR_HEAD_SIT -73

// Размер полоски.
#macro WAIT_BAR_WIDTH 56
#macro WAIT_BAR_HEIGHT 6

// Смещение сидящего по горизонтали (фигура в кадре sit сдвинута).
#macro WAIT_BAR_SIT_DX -30

// Меньше этого остатка терпения — полоска краснеет.
#macro WAIT_BAR_LOW_RATIO 0.25


// ═══════════════════════════════════════════════════════════════
// 1. ЦВЕТА ПО ТИПУ ОЖИДАНИЯ
//
// Каждый тип — свой цвет, все различимы на маленьком размере.
// ═══════════════════════════════════════════════════════════════

/// @function wait_bar_color_payment()
/// @description Ждёт оплаты — янтарный.
function wait_bar_color_payment() {
    return make_color_rgb(240, 168, 32);
}


/// @function wait_bar_color_reception()
/// @description Очередь в регистратуру — голубой.
function wait_bar_color_reception() {
    return make_color_rgb(64, 184, 232);
}


/// @function wait_bar_color_exam()
/// @description Ждёт приёма врача — зелёный.
function wait_bar_color_exam() {
    return make_color_rgb(92, 204, 116);
}


/// @function wait_bar_color_procedure()
/// @description Ждёт манипуляций — фиолетовый.
function wait_bar_color_procedure() {
    return make_color_rgb(170, 122, 232);
}


/// @function wait_bar_color_inpatient()
/// @description Стационар — розовый.
function wait_bar_color_inpatient() {
    return make_color_rgb(242, 122, 164);
}


/// @function wait_bar_color_low()
/// @description Терпение на исходе — красный.
function wait_bar_color_low() {
    return make_color_rgb(232, 64, 64);
}


/// @function wait_bar_color_default()
/// @description Запасной цвет, если тип не распознан.
function wait_bar_color_default() {
    return make_color_rgb(176, 186, 196);
}


/// @function wait_bar_reason_ru(_owner)
/// @description Причина ожидания словами — для отладки и превью.
function wait_bar_reason_ru(_owner) {

    if (!instance_exists(_owner)) return "";

    var _is_payment = (
        variable_instance_exists(_owner, "queue_purpose")
        && string(_owner.queue_purpose) == "payment"
    );

    if (_is_payment) return "ОПЛАТА";

    // Ещё не оформлен — значит, ждёт регистратуру. Поле registered
    // ставится в true после оформления (obj_player/Create_0:922 и
    // obj_staff_doctor/Step_0:723), хранится в сейве.
    var _registered = variable_instance_exists(_owner, "registered")
        ? _owner.registered
        : false;

    if (!_registered) return "РЕГИСТРАТУРА";

    var _queue_type = variable_instance_exists(_owner, "service_queue_type")
        ? string(_owner.service_queue_type)
        : "doctor";

    if (_queue_type == "procedure") return "МАНИПУЛЯЦИИ";
    if (_queue_type == "inpatient") return "СТАЦИОНАР";

    return "ПРИЁМ";
}


/// @function wait_bar_is_payment(_owner)
/// @description Клиент пришёл платить (очередь на оплату).
function wait_bar_is_payment(_owner) {
    return (
        variable_instance_exists(_owner, "queue_purpose")
        && string(_owner.queue_purpose) == "payment"
    );
}


/// @function wait_bar_owner_color(_owner, _ratio)
/// @description Цвет шкалы владельца: свой на каждый тип ожидания.
function wait_bar_owner_color(_owner, _ratio) {

    var _base = wait_bar_color_default();

    if (instance_exists(_owner)) {
        if (wait_bar_is_payment(_owner)) {
            _base = wait_bar_color_payment();
        }
        else {
            // Ещё не оформлен — ждёт регистратуру. Поле registered
            // переключается после оформления и переживает сейв.
            var _registered = variable_instance_exists(_owner, "registered")
                ? _owner.registered
                : false;

            if (!_registered) {
                _base = wait_bar_color_reception();
            }
            else {
                var _queue_type = variable_instance_exists(_owner, "service_queue_type")
                    ? string(_owner.service_queue_type)
                    : "doctor";

                if (_queue_type == "procedure") {
                    _base = wait_bar_color_procedure();
                }
                else if (_queue_type == "inpatient") {
                    _base = wait_bar_color_inpatient();
                }
                else {
                    _base = wait_bar_color_exam();
                }
            }
        }
    }

    // Терпение на исходе — важнее типа ожидания.
    if (_ratio >= 0 && _ratio < WAIT_BAR_LOW_RATIO) {
        return wait_bar_color_low();
    }

    return _base;
}


// ═══════════════════════════════════════════════════════════════
// 2. КУДА РИСОВАТЬ
// ═══════════════════════════════════════════════════════════════

/// @function wait_bar_head_offset_y()
/// @description Макушка текущего спрайта относительно y.
function wait_bar_head_offset_y() {

    var _is_sitting = (
        variable_instance_exists(id, "_owner_sitting")
        && _owner_sitting
    );

    if (_is_sitting) return WAIT_BAR_HEAD_SIT;

    var _offset = WAIT_BAR_HEAD_STAND;

    // par_visitors поднимает фигуру на _draw_offset_y.
    if (variable_instance_exists(id, "_draw_offset_y")) {
        _offset -= _draw_offset_y;
    }

    return _offset;
}


/// @function wait_bar_position()
/// @description Центр и размеры полоски над головой.
/// @return Структура { x1, y1, x2, y2, cx, cy, w, h, sitting }
function wait_bar_position() {

    var _w = WAIT_BAR_WIDTH;
    var _h = WAIT_BAR_HEIGHT;

    var _is_sitting = (
        variable_instance_exists(id, "_owner_sitting")
        && _owner_sitting
    );

    var _dx = _is_sitting ? WAIT_BAR_SIT_DX : 0;
    var _cx = x + _dx;
    var _cy = y + wait_bar_head_offset_y() - WAIT_BAR_GAP - _h * 0.5;

    return {
        x1 : _cx - _w * 0.5,
        y1 : _cy - _h * 0.5,
        x2 : _cx + _w * 0.5,
        y2 : _cy + _h * 0.5,
        cx : _cx,
        cy : _cy,
        w : _w,
        h : _h,
        sitting : _is_sitting
    };
}


// ═══════════════════════════════════════════════════════════════
// 3. МЕЛОЧИ ДЛЯ ОТРИСОВКИ
// ═══════════════════════════════════════════════════════════════

/// @function wait_bar_lighter(_color, _amount)
/// @description Светлее на _amount (0..255).
function wait_bar_lighter(_color, _amount) {
    return make_color_rgb(
        min(255, color_get_red(_color) + _amount),
        min(255, color_get_green(_color) + _amount),
        min(255, color_get_blue(_color) + _amount)
    );
}


/// @function wait_bar_darker(_color, _amount)
/// @description Темнее на _amount (0..255).
function wait_bar_darker(_color, _amount) {
    return make_color_rgb(
        max(0, color_get_red(_color) - _amount),
        max(0, color_get_green(_color) - _amount),
        max(0, color_get_blue(_color) - _amount)
    );
}


/// @function wait_bar_fill_rect(_pos, _ratio)
/// @description Цветная заливка внутри постоянной капсулы:
///              отступ 1 px от контура, длина по остатку терпения.
/// @return Структура { x1, y1, x2, y2, w } или noone.
function wait_bar_fill_rect(_pos, _ratio) {

    if (_ratio <= 0.015) return noone;

    var _x1 = _pos.x1 + 1;
    var _inner_w = (_pos.x2 - 1) - _x1;
    var _fill_w = _inner_w * clamp(_ratio, 0, 1);

    // Минимальная «капелька», пока терпение ещё не кончилось.
    if (_fill_w < 2) _fill_w = 2;

    return {
        x1 : _x1,
        y1 : _pos.y1 + 1,
        x2 : _x1 + _fill_w,
        y2 : _pos.y2 - 1,
        w : _fill_w
    };
}


// ═══════════════════════════════════════════════════════════════
// ПАКЕТ №334: КАПСУЛА ИЗ ЯВНЫХ КРУГОВ
//
// На скриншоте из игры видно: draw_roundrect_ext с маленьким
// радиусом рисует углы «квадратными» (радиус съедается). Поэтому
// капсула больше не полагается на скруглённый прямоугольник:
// торцы рисуются функцией draw_circle — круг есть круг в любой
// версии GameMaker, — а между ними прямой участок.
// ═══════════════════════════════════════════════════════════════

/// @function wait_bar_capsule_fill(_x1, _y1, _x2, _y2, _color, _alpha)
/// @description Залитая капсула: круг слева + прямоугольник + круг
///              справа. Радиус — половина высоты: торцы полностью
///              круглые всегда.
function wait_bar_capsule_fill(_x1, _y1, _x2, _y2, _color, _alpha) {

    var _h = _y2 - _y1;
    var _r = _h * 0.5;
    var _cy = (_y1 + _y2) * 0.5;

    // Если капсула короче диаметра — просто круг.
    var _lx = _x1 + _r;
    var _rx = _x2 - _r;

    if (_rx < _lx) {
        var _mx = (_x1 + _x2) * 0.5;

        draw_set_alpha(_alpha);
        draw_set_color(_color);
        draw_circle(_mx, _cy, _r, false);

        return true;
    }

    draw_set_alpha(_alpha);
    draw_set_color(_color);

    draw_circle(_lx, _cy, _r, false);
    draw_circle(_rx, _cy, _r, false);
    draw_rectangle(_lx, _y1, _rx, _y2, false);

    return true;
}


/// @function wait_bar_arc(_cx, _cy, _r, _a1, _a2)
/// @description Полуокружность ломаной из коротких отрезков.
///
/// ПАКЕТ №335: в №334 торцы рисовались функцией draw_arc, но она
/// есть только в новых версиях GameMaker — у пользователя игра
/// упала с «Variable draw_arc not set». draw_line и lengthdir_*
/// существуют во всех версиях, поэтому дуга собирается из 12
/// отрезков: на радиусе 4 пикселя они сливаются в гладкую дугу.
///
/// Углы как в lengthdir: 0 — вправо, 90 — вверх, по кругу.
function wait_bar_arc(_cx, _cy, _r, _a1, _a2) {

    var _steps = 12;

    var _prev_x = _cx + lengthdir_x(_r, _a1);
    var _prev_y = _cy + lengthdir_y(_r, _a1);

    for (var _i = 1; _i <= _steps; _i++) {
        var _a = _a1 + (_a2 - _a1) * _i / _steps;

        var _x = _cx + lengthdir_x(_r, _a);
        var _y = _cy + lengthdir_y(_r, _a);

        draw_line(_prev_x, _prev_y, _x, _y);

        _prev_x = _x;
        _prev_y = _y;
    }

    return true;
}


/// @function wait_bar_capsule_outline(_x1, _y1, _x2, _y2, _t)
/// @description Чёрный контур капсулы: полуокружности на торцах и
///              линии сверху/снизу. ПАКЕТ №336: контур РИСУЕТСЯ ПО
///              ПЕРЕДАННОМУ БОКСУ (стилями передаётся бокс заливки)
///              и прижат к цвету — пустой капсулы больше нет.
///              Толщина _t: штрихи со смещениями 1.._t сливаются в
///              ленту, обнимающую заливку. Дуги — ломаные (№335).
function wait_bar_capsule_outline(_x1, _y1, _x2, _y2, _t) {

    var _h0 = _y2 - _y1;
    var _cy = (_y1 + _y2) * 0.5;

    var _lx = _x1 + _h0 * 0.5;
    var _rx = _x2 - _h0 * 0.5;

    if (_rx < _lx) _rx = _lx;

    draw_set_alpha(1);
    draw_set_color(make_color_rgb(18, 16, 14));

    // Только ВНЕШНИЕ полуокружности: 90..270 — левая половина,
    // 270..450 — правая.
    for (var _off = 1; _off <= _t; _off++) {
        wait_bar_arc(_lx, _cy, _h0 * 0.5 + _off, 90, 270);
        wait_bar_arc(_rx, _cy, _h0 * 0.5 + _off, 270, 450);

        draw_set_alpha(1);
        draw_line(_lx, _y1 - _off, _rx, _y1 - _off);
        draw_line(_lx, _y2 + _off, _rx, _y2 + _off);
    }

    return true;
}


/// @function wait_bar_fill_shaded(_fill, _color)
/// @description Заливка с вертикальным градиентом. Силуэт (база)
///              рисуется капсулой из кругов — торцы круглые
///              гарантированно; светлая и тёмная полосы кладутся
///              поверх и могут быть чуть угловатее — они внутри
///              цвета и на торцах не видны.
function wait_bar_fill_shaded(_fill, _color) {

    var _h = _fill.y2 - _fill.y1;
    var _r = _h * 0.5;

    // База — капсула из кругов.
    wait_bar_capsule_fill(
        _fill.x1, _fill.y1, _fill.x2, _fill.y2,
        _color, 1
    );

    // Светлый верх.
    var _top_y2 = _fill.y1 + _h * 0.5;

    wait_bar_capsule_fill(
        _fill.x1 + _r * 0.3, _fill.y1, _fill.x2 - _r * 0.3, _top_y2,
        wait_bar_lighter(_color, 70), 0.45
    );

    // Тёмный низ.
    var _bot_y1 = _fill.y2 - _h * 0.34;

    wait_bar_capsule_fill(
        _fill.x1 + _r * 0.3, _bot_y1, _fill.x2 - _r * 0.3, _fill.y2,
        wait_bar_darker(_color, 70), 0.35
    );

    draw_set_alpha(1);
}


// ═══════════════════════════════════════════════════════════════
// 4. ВАРИАНТЫ ОФОРМЛЕНИЯ (№336: контур прижат к заливке, толщина 2)
// ═══════════════════════════════════════════════════════════════

/// Вариант 1 — «Капсула»: градиент + блик, обводка постоянная.
function wait_bar_style_capsule(_pos, _ratio, _color) {

    var _fill = wait_bar_fill_rect(_pos, _ratio);

    if (_fill != noone) {
        wait_bar_fill_shaded(_fill, _color);

        draw_set_alpha(0.32);
        draw_set_color(c_white);
        draw_line(_fill.x1 + 2, _fill.y1 + 1, _fill.x2 - 2, _fill.y1 + 1);
        draw_set_alpha(1);

        // №336: контур обнимает заливку, толщина 2.
        wait_bar_capsule_outline(_fill.x1, _fill.y1, _fill.x2, _fill.y2, 2);
    }

    return true;
}


/// Вариант 2 — «Стекло»: блик-овал, как капля.
function wait_bar_style_glass(_pos, _ratio, _color) {

    var _fill = wait_bar_fill_rect(_pos, _ratio);

    if (_fill != noone) {
        wait_bar_fill_shaded(_fill, _color);

        // Длинный узкий блик по верху — «стекло».
        draw_set_alpha(0.42);
        draw_set_color(c_white);
        draw_ellipse(
            _fill.x1 + 2, _fill.y1 + 0.5,
            _fill.x2 - 2, _fill.y1 + (_fill.y2 - _fill.y1) * 0.55,
            false
        );
        draw_set_alpha(1);

        // №336: контур обнимает заливку, толщина 2.
        wait_bar_capsule_outline(_fill.x1, _fill.y1, _fill.x2, _fill.y2, 2);
    }

    return true;
}


/// Вариант 3 — «Сегменты»: капсула с чёрными рисками на 10 делений.
function wait_bar_style_segmented(_pos, _ratio, _color) {

    var _fill = wait_bar_fill_rect(_pos, _ratio);

    if (_fill != noone) {
        wait_bar_fill_shaded(_fill, _color);

        var _full_w = _pos.x2 - _pos.x1;

        draw_set_alpha(0.75);
        draw_set_color(make_color_rgb(18, 16, 14));

        for (var _index = 1; _index <= 9; _index++) {
            var _lx = _pos.x1 + _full_w * _index * 0.1;

            if (_lx > _fill.x1 + 2 && _lx < _fill.x2 - 2) {
                draw_rectangle(
                    _lx, _fill.y1 + 1, _lx + 1, _fill.y2 - 1,
                    false
                );
            }
        }

        draw_set_alpha(1);

        // №336: контур обнимает заливку, толщина 2.
        wait_bar_capsule_outline(_fill.x1, _fill.y1, _fill.x2, _fill.y2, 2);
    }

    return true;
}


/// Вариант 4 — «Неон»: цвет со свечением и яркой сердцевиной.
function wait_bar_style_neon(_pos, _ratio, _color) {

    var _fill = wait_bar_fill_rect(_pos, _ratio);

    if (_fill != noone) {
        var _h = _fill.y2 - _fill.y1;
        var _r = _h * 0.5;

        wait_bar_capsule_fill(
            _fill.x1, _fill.y1, _fill.x2, _fill.y2,
            _color, 1
        );

        // Свечение вокруг цвета.
        gpu_set_blendmode(bm_add);

        draw_set_alpha(0.3);
        draw_set_color(_color);
        wait_bar_capsule_outline_glow(_fill, 2);

        draw_set_alpha(0.16);
        wait_bar_capsule_outline_glow(_fill, 4);

        draw_set_alpha(1);
        gpu_set_blendmode(bm_normal);

        // Яркая сердцевина.
        wait_bar_capsule_fill(
            _fill.x1 + 1, _fill.y1 + 1.5, _fill.x2 - 1, _fill.y2 - 1.5,
            c_white, 0.5
        );

        draw_set_alpha(1);

        // №336: контур обнимает заливку, толщина 2.
        wait_bar_capsule_outline(_fill.x1, _fill.y1, _fill.x2, _fill.y2, 2);
    }

    return true;
}


/// @function wait_bar_capsule_outline_glow(_fill, _grow)
/// @description Увеличенный контур капсулы — для свечения неона.
function wait_bar_capsule_outline_glow(_fill, _grow) {

    var _h = _fill.y2 - _fill.y1;
    var _r = _h * 0.5 + _grow;
    var _cy = (_fill.y1 + _fill.y2) * 0.5;

    var _lx = _fill.x1 + _h * 0.5;
    var _rx = _fill.x2 - _h * 0.5;

    if (_rx < _lx) _rx = _lx;

    wait_bar_arc(_lx, _cy, _r, 90, 270);
    wait_bar_arc(_rx, _cy, _r, 270, 450);
    draw_line(_lx, _fill.y1 - _grow, _rx, _fill.y1 - _grow);
    draw_line(_lx, _fill.y2 + _grow, _rx, _fill.y2 + _grow);

    return true;
}


/// Вариант 5 — «Металл»: плоский цвет со светлой и тёмной кромками.
function wait_bar_style_metal(_pos, _ratio, _color) {

    var _fill = wait_bar_fill_rect(_pos, _ratio);

    if (_fill != noone) {
        var _h = _fill.y2 - _fill.y1;
        var _r = _h * 0.5;

        wait_bar_capsule_fill(
            _fill.x1, _fill.y1, _fill.x2, _fill.y2,
            _color, 1
        );

        draw_set_alpha(0.6);
        draw_set_color(wait_bar_lighter(_color, 90));
        draw_line(_fill.x1 + _r * 0.5, _fill.y1 + 1, _fill.x2 - _r * 0.5, _fill.y1 + 1);

        draw_set_alpha(0.5);
        draw_set_color(wait_bar_darker(_color, 80));
        draw_line(_fill.x1 + _r * 0.5, _fill.y2 - 1, _fill.x2 - _r * 0.5, _fill.y2 - 1);

        draw_set_alpha(1);

        // №336: контур обнимает заливку, толщина 2.
        wait_bar_capsule_outline(_fill.x1, _fill.y1, _fill.x2, _fill.y2, 2);
    }

    return true;
}


/// Вариант 6 — «Линия»: самая тонкая, цвет + обводка + белая метка.
function wait_bar_style_line(_pos, _ratio, _color) {

    var _cy = _pos.cy;

    var _thin = {
        x1 : _pos.x1,
        y1 : _cy - 1.5,
        x2 : _pos.x2,
        y2 : _cy + 1.5,
        cx : _pos.cx,
        cy : _cy,
        w : _pos.w,
        h : 3,
        sitting : _pos.sitting
    };

    var _fill = wait_bar_fill_rect(_thin, _ratio);

    if (_fill != noone) {
        wait_bar_capsule_fill(
            _fill.x1, _fill.y1, _fill.x2, _fill.y2,
            _color, 1
        );

        if (_ratio > 0.02 && _ratio < 0.99) {
            draw_set_alpha(0.85);
            draw_set_color(c_white);
            draw_rectangle(
                _fill.x2 - 0.5, _thin.y1 - 1,
                _fill.x2 + 0.5, _thin.y2 + 1,
                false
            );
            draw_set_alpha(1);
        }

        // №336: контур обнимает заливку, толщина 2.
        wait_bar_capsule_outline(_fill.x1, _fill.y1, _fill.x2, _fill.y2, 2);
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 5. ГЛАВНАЯ ФУНКЦИЯ
// ═══════════════════════════════════════════════════════════════

/// @function draw_wait_bar(_x1, _y1, _x2, _y2, _ratio, _color, _style)
/// @description Рисует шкалу ожидания. _style = -1 — брать макрос.
function draw_wait_bar(_x1, _y1, _x2, _y2, _ratio, _color, _style = -1) {

    var _pos = {
        x1 : _x1,
        y1 : _y1,
        x2 : _x2,
        y2 : _y2,
        cx : (_x1 + _x2) * 0.5,
        cy : (_y1 + _y2) * 0.5,
        w : _x2 - _x1,
        h : _y2 - _y1,
        sitting : false
    };

    if (_pos.w < 4 || _pos.h < 2) return false;

    draw_set_circle_precision(64);

    var _use_style = (_style >= 1 && _style <= 6) ? _style : WAIT_BAR_STYLE;
    var _clamped = clamp(_ratio, 0, 1);

    switch (_use_style) {
        case 1: wait_bar_style_capsule(_pos, _clamped, _color);   break;
        case 2: wait_bar_style_glass(_pos, _clamped, _color);     break;
        case 3: wait_bar_style_segmented(_pos, _clamped, _color); break;
        case 4: wait_bar_style_neon(_pos, _clamped, _color);      break;
        case 5: wait_bar_style_metal(_pos, _clamped, _color);     break;
        case 6: wait_bar_style_line(_pos, _clamped, _color);      break;
        default: wait_bar_style_capsule(_pos, _clamped, _color);  break;
    }

    // Возвращаем состояние отрисовки — за нами рисуют другие объекты.
    draw_set_color(c_white);
    draw_set_alpha(1);
    gpu_set_blendmode(bm_normal);

    return true;
}


/// @function wait_bar_names()
/// @description Названия вариантов — для превью.
function wait_bar_names() {
    return [
        "1. КАПСУЛА",
        "2. СТЕКЛО",
        "3. СЕГМЕНТЫ",
        "4. НЕОН",
        "5. МЕТАЛЛ",
        "6. ЛИНИЯ"
    ];
}


/// @function draw_wait_bar_preview()
/// @description Все шесть вариантов над головой — клавиша V в отладке.
function draw_wait_bar_preview() {

    var _names = wait_bar_names();
    var _base_y = y + wait_bar_head_offset_y() - WAIT_BAR_GAP - WAIT_BAR_HEIGHT;

    // Цвета по типам ожидания, чтобы заодно видеть палитру.
    var _colors = [
        wait_bar_color_exam(),
        wait_bar_color_reception(),
        wait_bar_color_payment(),
        wait_bar_color_procedure(),
        wait_bar_color_inpatient(),
        wait_bar_color_low()
    ];

    for (var _index = 0; _index < 6; _index++) {
        var _style = _index + 1;
        var _row_y = _base_y - _index * 22;

        var _pos = {
            x1 : x - WAIT_BAR_WIDTH * 0.5,
            y1 : _row_y - WAIT_BAR_HEIGHT,
            x2 : x + WAIT_BAR_WIDTH * 0.5,
            y2 : _row_y,
            cx : x,
            cy : _row_y - WAIT_BAR_HEIGHT * 0.5,
            w : WAIT_BAR_WIDTH,
            h : WAIT_BAR_HEIGHT,
            sitting : false
        };

        draw_wait_bar(
            _pos.x1, _pos.y1, _pos.x2, _pos.y2,
            1 - _index * 0.16,
            _colors[_index],
            _style
        );

        // Подпись: белая обводка, тёмный текст — читается на любом фоне.
        var _label = _names[_index] + "  "
            + string(floor((1 - _index * 0.16) * 100)) + "%";

        var _text_x = _pos.x2 + 8;
        var _text_y = _row_y - WAIT_BAR_HEIGHT - 2;

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

        draw_set_color(c_white);
        draw_text(_text_x - 1, _text_y, _label);
        draw_text(_text_x + 1, _text_y, _label);
        draw_text(_text_x, _text_y - 1, _label);
        draw_text(_text_x, _text_y + 1, _label);

        draw_set_color(make_color_rgb(30, 26, 22));
        draw_text(_text_x, _text_y, _label);

        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
}
