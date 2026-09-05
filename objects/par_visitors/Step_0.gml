/// Step par_visitors
/// @description Наведение, планшет и базовая анимация движения посетителя.


// ═══════════════════════════════════════════════════════════════
// 1. ПРОПОРЦИОНАЛЬНЫЙ РОСТ И НАВЕДЕНИЕ
// ═══════════════════════════════════════════════════════════════

// Исправляет уже сохранённых старых посетителей и не позволяет будущему
// изменению роста снова растянуть тело только по вертикали.
if (!variable_instance_exists(id, "_height_scale")) {
    _height_scale = 1;
}

_height_scale = clamp(abs(_height_scale), 0.85, 1.15);
_width_scale = _height_scale;

is_hovered = (global.hover_target == id);

// Пакет №264: тап вместо момента касания — иначе перетягивание
// камеры одним пальцем открывало карточку владельца.
if (
    world_tap_on_me()
    && !world_clicks_blocked()
) {
    if (instance_exists(obj_UI_Tablet)) {
        obj_UI_Tablet.visible = true;
        obj_UI_Tablet.target_id = id;
    }
}


// ═══════════════════════════════════════════════════════════════
// 2. АНИМАЦИЯ ДВИЖЕНИЯ ПО PATH
// ═══════════════════════════════════════════════════════════════

if (path_index != -1 && path_position < 1) {
    image_speed = 1;

    var _next_x = path_get_x(
        my_path,
        min(path_position + 0.01, 1)
    );
    var _next_y = path_get_y(
        my_path,
        min(path_position + 0.01, 1)
    );

    sprite_index = (_next_y < y)
        ? spr_human_B_walk
        : spr_human_FR_walk;

    if (_next_x > x) {
        pFacing = (sprite_index == spr_human_B_walk) ? -1 : 1;
    }
    else if (_next_x < x) {
        pFacing = (sprite_index == spr_human_B_walk) ? 1 : -1;
    }
}
else if (speed > 0 || abs(x - xprevious) > 0.5 || abs(y - yprevious) > 0.5) {
    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ №291: АНИМАЦИЯ ПРИ ХОДЬБЕ БЕЗ ПУТИ
    //
    // Раньше здесь было одно «иначе»: нет пути — значит, стоим на
    // месте, гасим анимацию. Но посетитель не всегда идёт по пути.
    // Когда сетка не смогла проложить маршрут, в ход идёт запасной
    // move_towards_point — персонаж честно движется, а path_index при
    // этом равен -1.
    //
    // Главное здесь — строка image_index = 0. Она выполнялась
    // КАЖДЫЙ кадр и сбрасывала анимацию в ноль. End Step ниже
    // честно выставлял image_speed = 1, но толку от этого не было:
    // следующий шаг снова возвращал кадр к нулю. Оттого владелец
    // и ехал в одной позе, будто его тянут за верёвочку.
    //
    // Теперь такое движение анимируется точно так же, как ходьба по
    // пути, только направление берётся не из точек маршрута, а из
    // direction. Условие speed > 0 важно: стоящих в очереди и сидящих
    // в зоне ожидания это не задевает — у них скорость нулевая, и они
    // идут прежней веткой ниже.
    // ═══════════════════════════════════════════════════════════════

    image_speed = 1;

    var _move_dx = lengthdir_x(1, direction);
    var _move_dy = lengthdir_y(1, direction);

    sprite_index = (_move_dy < 0)
        ? spr_human_B_walk
        : spr_human_FR_walk;

    if (_move_dx > 0) {
        pFacing = (sprite_index == spr_human_B_walk) ? -1 : 1;
    }
    else if (_move_dx < 0) {
        pFacing = (sprite_index == spr_human_B_walk) ? 1 : -1;
    }
}
else {
    image_speed = 0;
    image_index = 0;
    is_walking = false;
}


depth = -y;
