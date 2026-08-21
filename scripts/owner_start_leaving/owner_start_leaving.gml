/// owner_start_leaving(_owner_inst)
/// @description Направляет владельца к единой точке выхода без телепортации.

function owner_start_leaving(_owner_inst) {
    if (!instance_exists(_owner_inst)) return false;

    with (_owner_inst) {
        // ═══════════════════════════════════════════════════════
        // 1. ЕДИНАЯ ТОЧКА ВЫХОДА
        // ═══════════════════════════════════════════════════════

        var _exit_x = variable_global_exists("clinic_exit_x")
            ? global.clinic_exit_x
            : 100;

        var _exit_y = variable_global_exists("clinic_exit_y")
            ? global.clinic_exit_y
            : 100;

        leave_target_x = _exit_x;
        leave_target_y = _exit_y;
        leave_stuck_timer = 0;
        state = "leaving_clinic";

        path_end();
        speed = 0;
        is_walking = false;


        // ═══════════════════════════════════════════════════════
        // 2. ПОСТРОЕНИЕ МАРШРУТА
        // ═══════════════════════════════════════════════════════

        var _path_built = mp_grid_path(
            global.ai_grid,
            my_path,
            x,
            y,
            leave_target_x,
            leave_target_y,
            true
        );

        // Если точная точка заблокирована, ищем доступную рядом.
        if (!_path_built) {
            var _offsets = [-64, -48, -32, -16, 0, 16, 32, 48, 64];

            for (var _ox = 0; _ox < array_length(_offsets); _ox++) {
                for (var _oy = 0; _oy < array_length(_offsets); _oy++) {
                    var _target_x = _exit_x + _offsets[_ox];
                    var _target_y = _exit_y + _offsets[_oy];

                    if (mp_grid_path(
                        global.ai_grid,
                        my_path,
                        x,
                        y,
                        _target_x,
                        _target_y,
                        true
                    )) {
                        leave_target_x = _target_x;
                        leave_target_y = _target_y;
                        _path_built = true;
                        break;
                    }
                }

                if (_path_built) break;
            }
        }

        if (_path_built) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
        } else {
            // Последний резерв: движение напрямую, но без телепортации.
            move_towards_point(leave_target_x, leave_target_y, p_move_speed);
            is_walking = true;
        }


        // ═══════════════════════════════════════════════════════
        // 3. ПИТОМЕЦ СЛЕДУЕТ ЗА ВЛАДЕЛЬЦЕМ
        // ═══════════════════════════════════════════════════════

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

    return true;
}
