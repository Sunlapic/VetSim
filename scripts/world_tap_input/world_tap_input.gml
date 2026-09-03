/// world_tap_input.gml
/// @description Единая проверка «был ли настоящий тап по миру».
///              Пакет №264.
///
/// ── Зачем ──
///
/// На телефоне при перетягивании камеры одним пальцем открывалась
/// карточка персонажа, если палец в начале жеста попал на человека.
///
/// Причина: карточки открывались по mouse_check_button_pressed(),
/// то есть в момент КАСАНИЯ экрана — когда ещё неизвестно, тап это
/// или начало перетягивания камеры.
///
/// В проекте уже есть правильный механизм (пакет №141):
/// obj_Render выставляет global.touch_tap_confirmed только когда
/// палец ПОДНЯЛСЯ, не сдвинувшись больше чем на 12 пикселей.
/// Им пользуется obj_player — поэтому герой при панорамировании
/// никуда не идёт. А карточки этот механизм не использовали.
///
/// ── Про «не потреблять флаг» ──
///
/// global.touch_tap_confirmed одноразовый: obj_player читает его и
/// тут же сбрасывает в false. При этом obj_player первой строкой
/// вызывает event_inherited(), то есть par_staff → Step выполняется
/// ВНУТРИ шага игрока, ещё до чтения флага.
///
/// Поэтому карточкам нельзя сбрасывать флаг: игрок перестал бы
/// получать команды движения. Функция ниже только ЧИТАЕТ его.
/// Открытие карточки само по себе заблокирует мир (планшет —
/// модальное окно), и клик до игрока уже не дойдёт.


/// @function world_tap_happened()
/// @description true — по миру произошёл настоящий клик или тап.
///
///              На телефоне: только подтверждённый тап (палец
///              поднялся без движения). Перетягивание камеры и
///              щипок тапом не считаются.
///
///              На компьютере: обычное нажатие левой кнопки.
///
///              Флаг тапа НЕ сбрасывается — см. пояснение выше.
function world_tap_happened() {

    // ── Телефон ──
    if (variable_global_exists("touch_tap_confirmed")) {
        if (global.touch_tap_confirmed) return true;
    }

    // ── Компьютер ──
    // Нажатие мышью, но не то, которое пришло с сенсора: на телефоне
    // device_mouse_check_button_pressed дублируется в mouse_check_*,
    // и без этой проверки касание снова засчиталось бы сразу.
    if (
        mouse_check_button_pressed(mb_left)
        && !device_mouse_check_button_pressed(0, mb_left)
    ) {
        return true;
    }

    return false;
}


/// @function world_tap_x()
/// @description Мировая координата X места тапа.
///              На телефоне берётся точка, где палец поднялся.
function world_tap_x() {

    if (variable_global_exists("touch_tap_confirmed")
        && global.touch_tap_confirmed
        && variable_global_exists("touch_tap_wx")) {
        return global.touch_tap_wx;
    }

    return mouse_x;
}


/// @function world_tap_y()
function world_tap_y() {

    if (variable_global_exists("touch_tap_confirmed")
        && global.touch_tap_confirmed
        && variable_global_exists("touch_tap_wy")) {
        return global.touch_tap_wy;
    }

    return mouse_y;
}


/// @function world_tap_on_me()
/// @description true — настоящий тап пришёлся по этому экземпляру.
///
///              Проверяет не только наведение, но и попадание точки
///              тапа в спрайт. На телефоне это важно: палец мог
///              начать жест на персонаже, увести камеру и подняться
///              совсем в другом месте.
function world_tap_on_me() {

    if (!world_tap_happened()) return false;

    // Наведение считает obj_Render — оно уже учитывает приоритеты
    // и перекрытия, поэтому доверяем ему как основному признаку.
    var _hovered = false;

    if (variable_global_exists("hover_target")) {
        _hovered = (global.hover_target == id);
    }

    if (!_hovered) return false;

    // Дополнительно на телефоне сверяем точку отпускания пальца:
    // наведение считалось по позиции касания, а палец мог подняться
    // уже в стороне — тогда карточку открывать не надо.
    //
    // Проверяем прямоугольником вокруг спрайта, ровно как это делает
    // obj_Render → Begin Step при вычислении наведения. Маски здесь
    // не используются: в проекте нет ни одного place_meeting или
    // position_meeting, наведение везде считается габаритами.
    if (variable_global_exists("touch_tap_confirmed")
        && global.touch_tap_confirmed) {

        var _tx = world_tap_x();
        var _ty = world_tap_y();

        if (!sprite_exists(sprite_index)) return true;

        var _sw = sprite_get_width(sprite_index) * abs(image_xscale);
        var _sh = sprite_get_height(sprite_index) * abs(image_yscale);

        // Небольшой запас: палец толще пикселя, а спрайт мог чуть
        // сдвинуться за время жеста.
        var _pad = 8;

        var _x1 = x - (_sw * 0.5) - _pad;
        var _x2 = x + (_sw * 0.5) + _pad;
        var _y1 = y - _sh - _pad;
        var _y2 = y + _pad;

        if (_tx < _x1 || _tx > _x2) return false;
        if (_ty < _y1 || _ty > _y2) return false;
    }

    return true;
}
