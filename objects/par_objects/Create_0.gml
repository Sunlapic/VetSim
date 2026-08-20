///Create par_objects @description База для всех предметов клиники
is_hovered = false; 
can_hover = true;  // Если false - предмет не светится (для стен)
has_shadow = true; // Если false - под предметом нет тени (для стен)

// Точка, куда должен подойти персонаж (перед предметом)
interact_x = x;
interact_y = y + 40; 
is_busy = false;

// ВАЖНО: вместо того чтобы вешать Step-страховку на obj_table/obj_table_1,
// сделаем это единоразово в Create par_objects (или в Create самого шкафа).
//
// ДОБАВЬ ЭТО В КОНЕЦ Create-события par_objects.
// Оно инициализирует storage_inventory у ЛЮБОГО объекта-шкафа/стола,
// у которого после Create ещё нет storage_inventory (страховка от забытых инициализаций).
//
// Это безопасно — у obj_storage_main storage_inventory уже задан = global.inventory_main
// (он не перетрётся, потому что проверка if(!variable_instance_exists)).

if (variable_instance_exists(id, "exam_slot_id")) {
    // Это стол осмотра — инициализируем шкаф
    if (!variable_instance_exists(id, "storage_inventory") || !is_struct(storage_inventory)) {
        storage_inventory = {};
        // стартовый запас (3 шт каждого) — только при первом создании
        inventory_add_amount(storage_inventory, "item_painkiller",     3);
        inventory_add_amount(storage_inventory, "item_iv_solution",   3);
        inventory_add_amount(storage_inventory, "item_antiprotozoal", 3);
        inventory_add_amount(storage_inventory, "item_fixation_set",  3);
    }
    if (!variable_instance_exists(id, "storage_name_ru") || storage_name_ru == "") {
        storage_name_ru = "Шкаф стола " + string(exam_slot_id);
    }
}


depth = -y;