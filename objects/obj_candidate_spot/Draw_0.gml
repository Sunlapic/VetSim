///Draw obj_candidate_spot

if (variable_global_exists("debug_mode") && global.debug_mode) {
    draw_set_color(make_color_rgb(70, 120, 180));
    draw_circle(x, y, marker_radius, false);

    draw_set_alpha(0.2);
    draw_circle(x, y, marker_radius + 6, false);
    draw_set_alpha(1);

    draw_set_color(c_white);
    draw_text(x + 16, y - 8, "CANDIDATE");
}