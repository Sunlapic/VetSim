function ui_spawn_flying_plus(_start_x, _start_y, _end_x, _end_y, _text, _color) {
    var _fx = instance_create_layer(0, 0, "Instances", obj_ui_flying_plus);

    with (_fx) {
        gui_start_x = _start_x;
        gui_start_y = _start_y;

        gui_end_x = _end_x;
        gui_end_y = _end_y;

        gui_control_x = lerp(_start_x, _end_x, 0.5);
        gui_control_y = min(_start_y, _end_y) - 70;

        fly_text = _text;
        fly_color = _color;
        fly_shadow_color = c_black;

        fly_timer = 0;
        fly_timer_max = max(1, round(room_speed * 0.45));

        scale_start = 1.05;
        scale_end = 0.82;

        notify_condition_flash = true;
        notify_flash_color = _color;
    }

    return _fx;
}