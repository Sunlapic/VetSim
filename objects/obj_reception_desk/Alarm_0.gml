/// Alarm 0 obj_reception_desk
/// @description Перестроение очереди

// На всякий случай обновляем координаты из объектов-точек
if (
    variable_instance_exists(id, "reception_refresh_points")
) {
    reception_refresh_points();
}

for (
    var _queue_i = 0;
    _queue_i < ds_list_size(queue_list);
    _queue_i++
) {
    var _client = queue_list[| _queue_i];

    if (!instance_exists(_client)) continue;

    var _target_x =
        queue_start_x + (_queue_i * queue_step_x);

    var _target_y =
        queue_start_y + (_queue_i * queue_step_y);

    with (_client) {

        queue_slot = _queue_i;

        queue_target_x = _target_x;
        queue_target_y = _target_y;

        // Не двигаем клиента, если он уже обслуживается,
        // ждёт, ушёл или направляется в waiting area.
        var _can_reposition =
            state != "registering"
            && state != "going_to_waiting"
            && state != "waiting"
            && state != "leaving_clinic";

        if (_can_reposition) {

            state = "going_to_queue";

            path_end();
            is_walking = false;

            if (mp_grid_path(
                global.ai_grid,
                my_path,
                x,
                y,
                _target_x,
                _target_y,
                true
            )) {
                path_set_kind(my_path, 1);

                path_start(
                    my_path,
                    p_move_speed,
                    path_action_stop,
                    true
                );

                is_walking = true;
            }
        }
    }
}