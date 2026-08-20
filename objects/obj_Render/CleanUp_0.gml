/// Cleanup obj_Render
/// @description Освобождает динамическую навигационную сетку комнаты.

if (
    variable_global_exists("ai_grid")
    && global.ai_grid != -1
) {
    mp_grid_destroy(global.ai_grid);
    global.ai_grid = -1;
}

// Старые ссылки на объекты комнаты не должны переходить в следующую комнату.
if (variable_global_exists("hover_target")) {
    global.hover_target = noone;
}

if (variable_global_exists("current_candidate")) {
    global.current_candidate = noone;
}

if (variable_global_exists("selected_candidate")) {
    global.selected_candidate = noone;
}

if (variable_global_exists("restock_jobs")) {
    global.restock_jobs = [];
}
