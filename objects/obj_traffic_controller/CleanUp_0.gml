/// Clean Up obj_traffic_controller
/// @description Освобождаем сетку обходов, иначе утечка памяти.

// Функции mp_grid_exists в GML нет — проверяем свой флаг.
if (variable_global_exists("traffic_grid_ready")) {
    if (global.traffic_grid_ready) {

        mp_grid_destroy(global.traffic_grid);

        global.traffic_grid_ready = false;
    }
}
