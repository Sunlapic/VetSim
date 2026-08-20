/// Cleanup obj_owner
/// @description Безопасная очистка владельца, очереди, стола, персонала и питомца.

// Сначала удаляем ссылки из общих массивов и tracking-map.
runtime_cleanup_actor_references(id);


// ═══════════════════════════════════════════════════════════════
// 1. ПУТЬ И ПОРТРЕТ
// ═══════════════════════════════════════════════════════════════

if (variable_instance_exists(id, "my_path") && path_exists(my_path)) {
    path_delete(my_path);
}

if (
    variable_instance_exists(id, "my_baked_portrait")
    && my_baked_portrait != -1
    && sprite_exists(my_baked_portrait)
) {
    sprite_delete(my_baked_portrait);
    my_baked_portrait = -1;
}


// ═══════════════════════════════════════════════════════════════
// 2. МЕСТО В ЗОНЕ ОЖИДАНИЯ
// ═══════════════════════════════════════════════════════════════

if (
    variable_instance_exists(id, "wait_spot_index")
    && wait_spot_index >= 0
    && variable_global_exists("wait_spots")
    && is_array(global.wait_spots)
    && wait_spot_index < array_length(global.wait_spots)
) {
    if (global.wait_spots[wait_spot_index].occupied_by == id) {
        global.wait_spots[wait_spot_index].occupied_by = noone;
    }

    wait_spot_index = -1;
}


// ═══════════════════════════════════════════════════════════════
// 3. ОЧЕРЕДЬ РЕГИСТРАТУРЫ
// ═══════════════════════════════════════════════════════════════

if (
    variable_instance_exists(id, "assigned_desk")
    && instance_exists(assigned_desk)
    && variable_instance_exists(assigned_desk, "queue_list")
    && ds_exists(assigned_desk.queue_list, ds_type_list)
) {
    var _queue_index = ds_list_find_index(
        assigned_desk.queue_list,
        id
    );

    if (_queue_index != -1) {
        ds_list_delete(assigned_desk.queue_list, _queue_index);
        assigned_desk.alarm[0] = 1;
    }
}


// ═══════════════════════════════════════════════════════════════
// 4. СМОТРОВОЙ СТОЛ
// Освобождаем только стол, который действительно принадлежит владельцу.
// ═══════════════════════════════════════════════════════════════

if (
    variable_instance_exists(id, "assigned_table")
    && instance_exists(assigned_table)
) {
    var _table = assigned_table;

    if (
        variable_instance_exists(_table, "assigned_owner")
        && _table.assigned_owner == id
    ) {
        _table.assigned_owner = noone;

        if (variable_instance_exists(_table, "assigned_doctor")) {
            _table.assigned_doctor = noone;
        }

        if (variable_instance_exists(_table, "assigned_pet")) {
            _table.assigned_pet = noone;
        }

        if (variable_instance_exists(_table, "table_busy")) {
            _table.table_busy = false;
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 5. НАЗНАЧЕННЫЙ СОТРУДНИК
// assigned_doctor может быть врачом, игроком или ассистентом.
// ═══════════════════════════════════════════════════════════════

if (
    variable_instance_exists(id, "assigned_doctor")
    && instance_exists(assigned_doctor)
) {
    var _staff = assigned_doctor;
    var _staff_belongs_to_owner = (
        variable_instance_exists(_staff, "assigned_owner")
        && _staff.assigned_owner == id
    );

    if (_staff_belongs_to_owner) {
        _staff.assigned_owner = noone;

        if (variable_instance_exists(_staff, "assigned_table")) {
            _staff.assigned_table = noone;
        }

        if (variable_instance_exists(_staff, "assigned_pet")) {
            _staff.assigned_pet = noone;
        }

        if (variable_instance_exists(_staff, "service_mode")) {
            _staff.service_mode = "";
        }

        if (variable_instance_exists(_staff, "exam_timer")) {
            _staff.exam_timer = 0;
        }

        if (variable_instance_exists(_staff, "exam_timer_max")) {
            _staff.exam_timer_max = 0;
        }

        if (variable_instance_exists(_staff, "procedure_timer")) {
            _staff.procedure_timer = 0;
        }

        if (variable_instance_exists(_staff, "action_progress_active")) {
            _staff.action_progress_active = false;
        }

        if (variable_instance_exists(_staff, "action_progress_timer")) {
            _staff.action_progress_timer = 0;
        }

        if (variable_instance_exists(_staff, "action_progress_timer_max")) {
            _staff.action_progress_timer_max = 0;
        }

        // Врач и главный игрок.
        if (variable_instance_exists(_staff, "doctor_state")) {
            _staff.doctor_state = "idle";
        }

        // Ассистент. doctor_state у него нет, поэтому проверяем отдельно.
        if (variable_instance_exists(_staff, "assistant_state")) {
            _staff.assistant_state = "idle";

            if (variable_instance_exists(_staff, "procedure_was_interrupted_by_restock")) {
                _staff.procedure_was_interrupted_by_restock = false;
            }
        }

        with (_staff) {
            path_end();
            speed = 0;
            is_walking = false;
        }
    }
}

assigned_doctor = noone;
assigned_table = noone;


// ═══════════════════════════════════════════════════════════════
// 6. ПИТОМЕЦ
// ═══════════════════════════════════════════════════════════════

if (variable_instance_exists(id, "my_pet") && instance_exists(my_pet)) {
    var _pet = my_pet;

    _pet.my_owner = noone;

    if (
        !variable_instance_exists(_pet, "state")
        || _pet.state != "leaving_clinic"
    ) {
        with (_pet) {
            instance_destroy();
        }
    }

    my_pet = noone;
}


// ═══════════════════════════════════════════════════════════════
// 7. ГЛОБАЛЬНЫЕ СПИСКИ АКТИВНЫХ ПОСЕТИТЕЛЕЙ
// ═══════════════════════════════════════════════════════════════

if (variable_global_exists("active_visitors") && is_array(global.active_visitors)) {
    for (var _active_index = array_length(global.active_visitors) - 1; _active_index >= 0; _active_index--) {
        if (global.active_visitors[_active_index] == id) {
            array_delete(global.active_visitors, _active_index, 1);
        }
    }
}

if (variable_global_exists("city_pet_owners") && is_array(global.city_pet_owners)) {
    for (var _city_index = array_length(global.city_pet_owners) - 1; _city_index >= 0; _city_index--) {
        if (global.city_pet_owners[_city_index] == id) {
            array_delete(global.city_pet_owners, _city_index, 1);
        }
    }
}
