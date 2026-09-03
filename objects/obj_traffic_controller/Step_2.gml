/// End Step obj_traffic_controller
/// @description Обход людей стороной. Пакет 260.
///
/// End Step: к этому моменту движок уже передвинул всех по путям,
/// поэтому мы видим настоящие итоговые позиции.

if (!variable_global_exists("traffic_enabled")) exit;
if (!global.traffic_enabled) exit;

if (variable_global_exists("time_paused")) {
    if (global.time_paused) exit;
}

// Номер шага: сетка обходов пересобирается один раз за шаг.
global.traffic_frame += 1;

people_traffic_step();
