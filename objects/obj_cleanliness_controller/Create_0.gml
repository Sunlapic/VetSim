/// Create obj_cleanliness_controller
/// @description Трафик, появление грязи, меню уборки и показатель чистоты.

// Должен быть visible=true, иначе GameMaker не вызовет Draw GUI.
visible = true;
persistent = false;

// Маленькая depth нужна, чтобы Draw GUI выполнялся поверх основного HUD.
depth = -100000;

if (!variable_global_exists("clinic_cleanliness")) {
    global.clinic_cleanliness = 100;
}

if (!variable_global_exists("clean_menu_open")) {
    global.clean_menu_open = false;
    global.clean_menu_target = noone;
}

traffic_map = ds_map_create();
actor_position_map = ds_map_create();
traffic_cell_size = 64;
traffic_sample_interval = 4;
traffic_sample_timer = traffic_sample_interval;

// Проверка свободных ассистентов для автоматической уборки.
assistant_clean_scan_interval = room_speed;
assistant_clean_scan_timer = assistant_clean_scan_interval;

// Грязь появляется только в рабочее дневное окно 10:00–00:00.
// Точный следующий момент рассчитывается в игровых минутах.
spawn_min_game_minutes = 60;
spawn_max_game_minutes = 180;
dirt_spawn_timer = -1; // старое поле оставлено только для совместимости
next_dirt_spawn_absolute_minute = -1;
first_dirt_spawned = false;
spawn_attempts = 0;

min_traffic_for_dirt = 8;
minimum_dirt_spacing = 54;
max_dirt_count = 28;
