///Alarm 0 obj_staff_candidate

if (instance_exists(obj_candidate_spot)) {

    var _spot = instance_find(obj_candidate_spot, 0);

    candidate_wait_x = _spot.x;
    candidate_wait_y = _spot.y;
    candidate_target_ready = true;

    path_end();

    if (mp_grid_path(global.ai_grid, my_path, x, y, candidate_wait_x, candidate_wait_y, true)) {
        path_set_kind(my_path, 1);
        path_start(my_path, p_move_speed, path_action_stop, true);
        is_walking = true;
    } else {
        x = candidate_wait_x;
        y = candidate_wait_y;
        candidate_state = "waiting_offer";
        is_walking = false;
    }

} else {

    candidate_target_ready = false;
    candidate_state = "waiting_offer";
}