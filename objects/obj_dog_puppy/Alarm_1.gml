///Alarm 1 obj_dog_puppy

// Если щенок привязан к владельцу или участвует в приеме — не блуждаем
if (instance_exists(my_owner) || state != "follow_owner") {
    alarm[1] = room_speed * irandom_range(7, 15);
    exit;
}

var _tx = x + irandom_range(-200, 200);
var _ty = y + irandom_range(-200, 200);

if (mp_grid_path(global.ai_grid, my_path, x, y, _tx, _ty, true)) {
    path_set_kind(my_path, 1);
    path_start(my_path, p_move_speed, path_action_stop, true);
    is_walking = true;
}

alarm[1] = room_speed * irandom_range(7, 15);