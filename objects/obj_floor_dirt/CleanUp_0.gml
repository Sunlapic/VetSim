/// Cleanup obj_floor_dirt

if (targeted_by_player || cleaning_active) {
    dirt_release_player(id);
}

if (targeted_by_assistant || assistant_cleaning_active) {
    dirt_release_assistant(id);
}

if (
    variable_global_exists("clean_menu_target")
    && global.clean_menu_target == id
) {
    global.clean_menu_open = false;
    global.clean_menu_target = noone;
    global.ui_block_world_click = false;
}
