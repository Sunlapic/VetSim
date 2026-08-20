///Create obj_exam_point_owner

visible = true;
if (!variable_instance_exists(id, "exam_slot_id")) {
    exam_slot_id = 1;
}
marker_color = make_color_rgb(90, 220, 120);
marker_label = "OWNER";