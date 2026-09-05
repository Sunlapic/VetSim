/// Cleanup obj_cleanliness_controller
///
/// ═══════════════════════════════════════════════════════════════
/// ПАКЕТ №310: ПРОВЕРКА, ЧТО ПЕРЕМЕННЫЕ СОЗДАНЫ
///
/// Та же причина, что у obj_reception_desk. При смене комнаты
/// GameMaker вызывает CleanUp у всех объектов сразу, включая те,
/// чьё событие Create ещё не выполнялось: объекты комнаты
/// создаются по очереди.
///
/// У такого объекта переменных ещё нет, и ds_exists падает —
/// проверить несозданную переменную она не может, ей нужна
/// существующая.
///
/// Здесь ошибка пока не выстрелила, но выстрелит: контроллер
/// чистоты стоит в комнате наравне со стойкой регистрации, и
/// порядок их создания ничем не закреплён. Закрываю сразу, чтобы
/// не ловить то же самое вторым заходом.
/// ═══════════════════════════════════════════════════════════════

if (variable_instance_exists(id, "traffic_map")) {
    if (ds_exists(traffic_map, ds_type_map)) {
        ds_map_destroy(traffic_map);
    }
}

if (variable_instance_exists(id, "actor_position_map")) {
    if (ds_exists(actor_position_map, ds_type_map)) {
        ds_map_destroy(actor_position_map);
    }
}

if (variable_global_exists("clean_menu_open")) {
    global.clean_menu_open = false;
    global.clean_menu_target = noone;
}
