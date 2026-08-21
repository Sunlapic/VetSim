function reception_enqueue_priority_payment(_owner_inst) {
    if (!instance_exists(_owner_inst)) return false;
    var _desk = noone;
    if (variable_instance_exists(_owner_inst, "assigned_desk") && instance_exists(_owner_inst.assigned_desk)) {
        _desk = _owner_inst.assigned_desk;
    } else if (instance_exists(obj_reception_desk)) {
        _desk = instance_find(obj_reception_desk, 0);
    }
    if (!instance_exists(_desk)) return false;

    // Освобождаем место ожидания
    if (variable_instance_exists(_owner_inst, "wait_spot_index")) {
        if (_owner_inst.wait_spot_index >= 0) {
            if (variable_global_exists("wait_spots")) {
                if (_owner_inst.wait_spot_index < array_length(global.wait_spots)) {
                    global.wait_spots[_owner_inst.wait_spot_index].occupied_by = noone;
                }
            }
        }
    }

    if (variable_instance_exists(_desk, "queue_list")) {
        var _old_idx = ds_list_find_index(_desk.queue_list, _owner_inst);
        if (_old_idx != -1) {
            ds_list_delete(_desk.queue_list, _old_idx);
        }
        // ═══════════════════════════════════════
        // ОПЛАТА — ВСЕГДА В НАЧАЛО ОЧЕРЕДИ (ПЕРВЫМ К АДМИНУ)
        // ═══════════════════════════════════════
        ds_list_insert(_desk.queue_list, 0, _owner_inst);
    }

    with (_owner_inst) {
        assigned_desk = _desk;
        queue_purpose = "payment";
        payment_pending = true;
        payment_done = false;
        queue_slot = -1;
        registered = true;
        wait_spot_index = -1;
        assigned_doctor = noone;
        assigned_table = noone;
        registration_in_progress = false;
        registration_timer = 0;
        registration_timer_max = 0;
        registration_actor_name = "";
        state = "going_to_queue";

        // ═══════════════════════════════════════
        // НЕ ОСТАНАВЛИВАЕМ клиента — заставляем идти в начало очереди!
        // ═══════════════════════════════════════
        path_end();
        if (mp_grid_path(global.ai_grid, my_path, x, y, _desk.queue_start_x, _desk.queue_start_y, true)) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
        } else {
            x = _desk.queue_start_x;
            y = _desk.queue_start_y;
            is_walking = false;
            state = "in_queue";
        }

        // Питомец идёт следом
        if (variable_instance_exists(id, "my_pet") && instance_exists(my_pet)) {
            with (my_pet) {
                path_end();
                is_walking = false;
                assigned_doctor = noone;
                assigned_table = noone;
                state = "follow_owner";
                follow_offset_x = 30;
                follow_offset_y = 20;
            }
        }
    }

    // Перестраиваем очередь чтобы сдвинуть всех остальных
    _desk.alarm[0] = 1;
    return true;
}