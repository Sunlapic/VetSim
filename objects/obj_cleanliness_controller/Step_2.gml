/// End Step obj_cleanliness_controller

if (
    variable_global_exists("clean_menu_open")
    && global.clean_menu_open
) {
    global.ui_block_world_click = true;
}
