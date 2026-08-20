/// Cleanup obj_cleanliness_controller

if (ds_exists(traffic_map, ds_type_map)) {
    ds_map_destroy(traffic_map);
}

if (ds_exists(actor_position_map, ds_type_map)) {
    ds_map_destroy(actor_position_map);
}

if (variable_global_exists("clean_menu_open")) {
    global.clean_menu_open = false;
    global.clean_menu_target = noone;
}
