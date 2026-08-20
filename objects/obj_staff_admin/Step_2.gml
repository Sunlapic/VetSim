/// End Step obj_staff_admin
/// @description Во время регистрации администратор всегда смотрит на клиента через стойку.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 1. ПРОВЕРКА РАБОЧЕГО СОСТОЯНИЯ
// ═══════════════════════════════════════════════════════════════

if (
    reception_state == "registering"
    && instance_exists(reception_desk)
) {
    if (
        variable_instance_exists(reception_desk, "reception_refresh_points")
    ) {
        with (reception_desk) {
            reception_refresh_points();
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 2. ТОЧКА, НА КОТОРУЮ СМОТРИТ АДМИНИСТРАТОР
    // ═══════════════════════════════════════════════════════════

    var _look_x = reception_desk.x;
    var _look_y = reception_desk.y;

    if (
        variable_instance_exists(reception_desk, "reception_owner_point")
        && instance_exists(reception_desk.reception_owner_point)
    ) {
        _look_x = reception_desk.reception_owner_point.x;
        _look_y = reception_desk.reception_owner_point.y;
    }
    else if (variable_instance_exists(reception_desk, "queue_start_x")) {
        _look_x = reception_desk.queue_start_x;
        _look_y = reception_desk.queue_start_y;
    }

    var _look_dx = _look_x - x;
    var _look_dy = _look_y - y;


    // ═══════════════════════════════════════════════════════════
    // 3. РАБОЧИЙ СПРАЙТ И НАПРАВЛЕНИЕ
    // ═══════════════════════════════════════════════════════════

    var _back_work_sprite = asset_get_index("spr_human_B_work");
    var _has_back_work = (
        _back_work_sprite != -1
        && sprite_exists(_back_work_sprite)
    );

    if (_look_dy < 0) {
        if (_has_back_work) {
            sprite_index = _back_work_sprite;

            var _back_frames = max(1, sprite_get_number(sprite_index));
            image_speed = 0;
            image_index = floor(_work_anim_timer / 6) mod _back_frames;
        } else {
            sprite_index = spr_human_B_walk;
            image_speed = 0;
            image_index = 0;
        }

        // Задний спрайт зеркалится противоположно переднему.
        pFacing = (abs(_look_dx) > 1 && _look_dx > 0) ? -1 : 1;
    } else {
        sprite_index = spr_human_FR_work;

        var _front_frames = max(1, sprite_get_number(sprite_index));
        image_speed = 0;
        image_index = floor(_work_anim_timer / 6) mod _front_frames;

        pFacing = (abs(_look_dx) > 1 && _look_dx < 0) ? -1 : 1;
    }


    // ═══════════════════════════════════════════════════════════
    // 4. ФИКСАЦИЯ У СТОЙКИ И ГЛУБИНА
    // ═══════════════════════════════════════════════════════════

    path_end();
    speed = 0;
    is_walking = false;

    image_xscale = abs(image_xscale) * pFacing;

    // Руки и рабочая анимация рисуются поверх стойки.
    depth = reception_desk.depth - 3;
}
