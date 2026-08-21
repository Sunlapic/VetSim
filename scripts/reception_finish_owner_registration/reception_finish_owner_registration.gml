function reception_finish_owner_registration(_owner_inst, _by_player) {

    if (!instance_exists(_owner_inst)) return false;

    var _wait_index = reception_find_free_wait_spot();
    if (_wait_index == -1) return false;

    var _desk = noone;
    if (variable_instance_exists(_owner_inst, "assigned_desk") && instance_exists(_owner_inst.assigned_desk)) {
        _desk = _owner_inst.assigned_desk;
    } else if (instance_exists(obj_reception_desk)) {
        _desk = instance_find(obj_reception_desk, 0);
    }

    // Убираем клиента из очереди у стойки
    if (instance_exists(_desk) && variable_instance_exists(_desk, "queue_list")) {
        var _idx = ds_list_find_index(_desk.queue_list, _owner_inst);
        if (_idx != -1) {
            ds_list_delete(_desk.queue_list, _idx);
        }
        _desk.alarm[0] = 1;
    }

    // Если админ уже занимался этим клиентом — сбрасываем его
    for (var a = 0; a < instance_number(obj_staff_admin); a++) {
        var _adm = instance_find(obj_staff_admin, a);
        if (!instance_exists(_adm)) continue;
        if (variable_instance_exists(_adm, "reception_client")) {
            if (_adm.reception_client == _owner_inst) {
                _adm.reception_client = noone;
                if (_adm.reception_state == "going_to_register_spot" || _adm.reception_state == "registering") {
                    _adm.reception_state = "returning";
                    _adm.reception_timer = 0;
                }
            }
        }
    }

    global.wait_spots[_wait_index].occupied_by = _owner_inst;

    // Монитор
    if (instance_exists(obj_monitor)) {
        var _line_name = _owner_inst.char_name;
        if (variable_instance_exists(_owner_inst, "my_pet") && instance_exists(_owner_inst.my_pet)) {
            if (variable_instance_exists(_owner_inst.my_pet, "char_name")) {
                _line_name += " + " + _owner_inst.my_pet.char_name;
            }
        }
        with (instance_find(obj_monitor, 0)) {
            add_to_monitor(_line_name, "ОЖИДАНИЕ");
        }
    }

    with (_owner_inst) {

        registered = true;
        queue_slot = -1;
        wait_spot_index = _wait_index;
        registration_in_progress = false;
        registration_timer = 0;
        registration_timer_max = 0;
        registration_actor_name = "";
        state = "going_to_waiting";

        var _spot = global.wait_spots[wait_spot_index];
        path_end();
        is_walking = false;

        // ── Ищем достижимую точку рядом с креслом ──
        var _tx = _spot.x;
        var _ty = _spot.y;
        var _built = false;

        if (mp_grid_path(global.ai_grid, my_path, x, y, _tx, _ty, true)) {
            _built = true;
        } else {
            var _offs = [-32, -24, -16, 0, 16, 24, 32];
            for (var _ox = 0; _ox < array_length(_offs); _ox++) {
                for (var _oy = 0; _oy < array_length(_offs); _oy++) {
                    if (_ox == 3 && _oy == 3) continue;
                    var _ax = _spot.x + _offs[_ox];
                    var _ay = _spot.y + _offs[_oy];
                    if (mp_grid_path(global.ai_grid, my_path, x, y, _ax, _ay, true)) {
                        _tx = _ax;
                        _ty = _ay;
                        _built = true;
                        break;
                    }
                }
                if (_built) break;
            }
        }

        if (_built) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
        } else {
            // В крайнем случае идём по прямой, НЕ ТЕЛЕПОРТИРУЕМ
            is_walking = true;
            move_towards_point(_spot.x, _spot.y, p_move_speed);
        }
    }

    return true;
}
