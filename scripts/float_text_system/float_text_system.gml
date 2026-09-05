// ═══════════════════════════════════════════════════════════════════
// float_text_system
//
// Всплывающие надписи над персонажами: полученный опыт и доход.
//
// Зачем: прогресс персонала до сих пор был виден только в карточке
// сотрудника, а сообщение показывалось лишь при повышении уровня.
// Из-за этого нельзя было понять, что именно качается в конкретный
// момент и качается ли вообще. Теперь каждое начисление видно сразу.
//
// Все функции безопасны: если объект надписи ещё не создан в проекте
// или цель исчезла, вызов просто ничего не делает.
// ═══════════════════════════════════════════════════════════════════


// ── ЦВЕТА ──
// Вынесены в функции, а не в макросы: макрос с make_color_rgb
// вычисляется в момент компиляции и в GML это делать не принято.

function float_text_color_xp() {
    // Тёплый жёлтый — опыт.
    return make_color_rgb(255, 226, 120);
}

function float_text_color_money() {
    // Зелёный — доход. Просили именно зелёный.
    return make_color_rgb(120, 235, 130);
}

function float_text_color_spend() {
    // Красноватый — трата. Пока не используется, оставлено на будущее.
    return make_color_rgb(240, 120, 110);
}


/// float_text_spawn(_target, _text, _color, _scale)
/// @description Создаёт всплывающую надпись над персонажем.
/// @param _target  инстанс, за которым летит надпись
/// @param _text    что написать
/// @param _color   цвет текста
/// @param _scale   размер (по умолчанию 1.7 — крупный, читаемый)
function float_text_spawn(_target, _text, _color, _scale = 1.70) {

    // ВАЖНО ПРИ УСТАНОВКЕ: объект obj_float_text должен быть создан
    // в IDE ДО того, как вы вставите этот скрипт, иначе проект не
    // скомпилируется — имя ресурса будет неизвестно компилятору.
    // Порядок установки описан в README.
    if (!instance_exists(_target)) return noone;
    if (string(_text) == "") return noone;

    var _spawn_x = _target.x;
    var _spawn_y = _target.y;

    var _bubble = instance_create_depth(
        _spawn_x,
        _spawn_y,
        -12000,
        obj_float_text
    );

    if (!instance_exists(_bubble)) return noone;

    with (_bubble) {
        target     = _target;
        float_text = string(_text);
        text_color = _color;
        text_scale = _scale;

        anchor_x = _spawn_x;
        anchor_y = _spawn_y;
    }

    // ── РАЗВОДИМ НАДПИСИ, ЧТОБЫ НЕ СЛИПАЛИСЬ ──
    // За один приём врач получает опыт дважды: базовая терапия и
    // профильный навык. Без разведения обе надписи легли бы одна на
    // другую и превратились в кашу.
    //
    // Считаем, сколько надписей уже висит над этим же персонажем, и
    // каждую следующую поднимаем выше и сдвигаем вбок.
    var _stack_index = 0;

    for (var _i = 0; _i < instance_number(obj_float_text); _i++) {
        var _other_text = instance_find(obj_float_text, _i);

        if (
            instance_exists(_other_text)
            && _other_text != _bubble
            && _other_text.target == _target
        ) {
            _stack_index += 1;
        }
    }

    if (_stack_index > 0) {
        with (_bubble) {
            // Каждая следующая надпись стартует выше предыдущей.
            y_offset -= _stack_index * 34;

            // И чуть в сторону, попеременно влево-вправо.
            x_offset = ((_stack_index mod 2) == 1) ? 22 : -22;
        }
    }

    return _bubble;
}


/// float_text_skill_xp(_actor, _skill_name, _amount)
/// @description Надпись о полученном опыте: «Терапия +2».
function float_text_skill_xp(_actor, _skill_name, _amount) {

    if (!instance_exists(_actor)) return noone;

    // Нулевые и отрицательные начисления не показываем: навык мог
    // упереться в десятый уровень, и надпись «+0» только мешала бы.
    var _value = floor(_amount);

    if (_value <= 0) return noone;

    // ── ИМЯ НАВЫКА В ЧИТАЕМОМ ВИДЕ ──
    // В коде названия хранятся заглавными («ТЕРАПИЯ»), а в надписи
    // такой текст выглядит криком и хуже читается. Приводим к виду
    // «Терапия»: первая буква заглавная, остальные строчные.
    var _name = string(_skill_name);

    if (string_length(_name) > 1) {
        _name = string_upper(string_char_at(_name, 1))
              + string_lower(string_copy(_name, 2, string_length(_name) - 1));
    }

    return float_text_spawn(
        _actor,
        _name + " +" + string(_value),
        float_text_color_xp(),
        1.70
    );
}


/// float_text_money(_target, _amount)
/// @description Зелёная надпись о доходе: «+25$».
function float_text_money(_target, _amount) {

    if (!instance_exists(_target)) return noone;

    var _value = round(_amount);

    if (_value <= 0) return noone;

    // Деньги — главное событие для игрока, поэтому чуть крупнее опыта.
    return float_text_spawn(
        _target,
        "+" + string(_value) + "$",
        float_text_color_money(),
        1.95
    );
}


/// float_text_money_at(_x, _y, _amount)
/// @description Доход в конкретной точке, без привязки к персонажу.
///              Нужно для кассы: клиент уходит сразу после оплаты,
///              и надпись должна остаться у стойки, а не улететь с ним.
function float_text_money_at(_x, _y, _amount) {

    var _value = round(_amount);

    if (_value <= 0) return noone;

    var _bubble = instance_create_depth(_x, _y, -12000, obj_float_text);

    if (!instance_exists(_bubble)) return noone;

    with (_bubble) {
        target     = noone;
        float_text = "+" + string(_value) + "$";
        text_color = float_text_color_money();
        text_scale = 1.95;

        anchor_x = _x;
        anchor_y = _y;

        // Точка передаётся уже готовой (верх стойки), поэтому
        // дополнительный подъём над головой здесь не нужен.
        y_offset = -40;
    }

    return _bubble;
}
