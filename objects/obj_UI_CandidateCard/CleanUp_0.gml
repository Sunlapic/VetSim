/// Cleanup obj_UI_CandidateCard

if (!instance_exists(obj_UI_Tablet) || !obj_UI_Tablet.visible) {
    global.ui_block_world_click = false;
}
