///Draw obj_exam_point_owner

if (variable_global_exists("debug_mode") && global.debug_mode) {
    draw_set_color(marker_color);
    draw_circle(x, y, 10, false);

    draw_set_alpha(0.2);
    draw_circle(x, y, 16, false);
    draw_set_alpha(1);

    draw_set_color(c_white);
    draw_text(x + 12, y - 8, marker_label + " #" + string(exam_slot_id));
}