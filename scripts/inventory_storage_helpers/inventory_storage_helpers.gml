/// inventory_storage_helpers.gml
/// @description Единственная чистая копия функций инвентаря, склада и заданий пополнения.


// ═══════════════════════════════════════════════════════════════
// 1. БАЗОВЫЕ ФУНКЦИИ ИНВЕНТАРЯ
// ═══════════════════════════════════════════════════════════════

function inventory_get_amount(_inventory, _item_id) {
    if (!is_struct(_inventory)) return 0;
    if (!variable_struct_exists(_inventory, _item_id)) return 0;

    return max(0, variable_struct_get(_inventory, _item_id));
}

function inventory_add_amount(_inventory, _item_id, _amount) {
    if (!is_struct(_inventory)) return 0;

    var _old_amount = inventory_get_amount(_inventory, _item_id);
    var _new_amount = max(0, _old_amount + floor(_amount));

    variable_struct_set(_inventory, _item_id, _new_amount);
    return _new_amount;
}

function inventory_has_amount(_inventory, _item_id, _amount) {
    if (!is_struct(_inventory)) return false;
    if (_amount <= 0) return true;

    return inventory_get_amount(_inventory, _item_id) >= _amount;
}

function inventory_remove_amount(_inventory, _item_id, _amount) {
    return inventory_add_amount(_inventory, _item_id, -_amount);
}

function item_get_name(_item_id) {
    if (!variable_global_exists("item_db")) return "Неизвестно";
    if (!is_struct(global.item_db)) return "Неизвестно";
    if (!variable_struct_exists(global.item_db, _item_id)) return "Неизвестно";

    var _item = variable_struct_get(global.item_db, _item_id);

    return variable_struct_exists(_item, "name_ru")
        ? string(_item.name_ru)
        : string(_item_id);
}


// ═══════════════════════════════════════════════════════════════
// 2. ПОИСК СКЛАДА И ШКАФА
// ═══════════════════════════════════════════════════════════════

function storage_find_main() {
    return instance_exists(obj_storage_main)
        ? instance_find(obj_storage_main, 0)
        : noone;
}

function storage_find_cabinet_by_slot(_slot_id) {
    for (var _index = 0; _index < instance_number(obj_storage_cabinet); _index++) {
        var _cabinet = instance_find(obj_storage_cabinet, _index);

        if (
            instance_exists(_cabinet)
            && variable_instance_exists(_cabinet, "exam_slot_id")
            && _cabinet.exam_slot_id == _slot_id
        ) {
            return _cabinet;
        }
    }

    return noone;
}


// ═══════════════════════════════════════════════════════════════
// 3. СПИСАНИЕ ПРЕПАРАТОВ ДЛЯ ПРОЦЕДУРЫ
// ═══════════════════════════════════════════════════════════════

function storage_prepare_and_consume_items_for_action(_slot_id, _action_id) {
    var _required_items = treatment_get_required_items(_action_id);

    if (array_length(_required_items) <= 0) {
        return {
            ok : true,
            missing_item_name : "",
            missing_item_id : ""
        };
    }

    var _cabinet = storage_find_cabinet_by_slot(_slot_id);

    if (!instance_exists(_cabinet)) {
        if (
            variable_global_exists("vetsim_debug_mode")
            && global.vetsim_debug_mode
        ) {
            show_debug_message(
                "[STOCK] Шкаф слота "
                + string(_slot_id)
                + " не найден для "
                + string(_action_id)
            );
        }

        return {
            ok : false,
            missing_item_name : "шкаф слота " + string(_slot_id) + " не найден",
            missing_item_id : ""
        };
    }

    if (
        !variable_instance_exists(_cabinet, "storage_inventory")
        || !is_struct(_cabinet.storage_inventory)
    ) {
        _cabinet.storage_inventory = {};

        for (var _start_index = 0; _start_index < array_length(global.item_ids); _start_index++) {
            inventory_add_amount(
                _cabinet.storage_inventory,
                global.item_ids[_start_index],
                3
            );
        }
    }

    var _cabinet_inventory = _cabinet.storage_inventory;

    // Сначала проверяем весь список, затем списываем.
    for (var _check_index = 0; _check_index < array_length(_required_items); _check_index++) {
        var _requirement = _required_items[_check_index];

        if (!inventory_has_amount(
            _cabinet_inventory,
            _requirement.item_id,
            _requirement.amount
        )) {
            restock_request_urgent(
                _cabinet,
                _requirement.item_id,
                _requirement.amount
            );

            return {
                ok : false,
                missing_item_name : item_get_name(_requirement.item_id),
                missing_item_id : _requirement.item_id
            };
        }
    }

    for (var _remove_index = 0; _remove_index < array_length(_required_items); _remove_index++) {
        var _remove_requirement = _required_items[_remove_index];

        inventory_remove_amount(
            _cabinet_inventory,
            _remove_requirement.item_id,
            _remove_requirement.amount
        );
    }

    return {
        ok : true,
        missing_item_name : "",
        missing_item_id : ""
    };
}


// ═══════════════════════════════════════════════════════════════
// 4. СРОЧНОЕ ЗАДАНИЕ НА ПОПОЛНЕНИЕ
// ═══════════════════════════════════════════════════════════════

function restock_request_urgent(_cabinet, _item_id, _needed_amount) {
    if (!instance_exists(_cabinet)) return false;
    if (_item_id == "" || _needed_amount <= 0) return false;

    if (!variable_global_exists("restock_jobs")) {
        global.restock_jobs = [];
    }

    // Не создаём дубликат задания в очереди.
    for (var _job_index = 0; _job_index < array_length(global.restock_jobs); _job_index++) {
        var _existing_job = global.restock_jobs[_job_index];

        if (
            _existing_job.target_cabinet == _cabinet
            && _existing_job.item_id == _item_id
        ) {
            return false;
        }
    }

    // Не создаём дубликат, если ассистент уже несёт этот препарат в этот шкаф.
    for (var _assistant_index = 0; _assistant_index < instance_number(obj_staff_assistant); _assistant_index++) {
        var _assistant = instance_find(obj_staff_assistant, _assistant_index);

        if (
            instance_exists(_assistant)
            && _assistant.restock_target_cabinet == _cabinet
            && _assistant.restock_item_id == _item_id
        ) {
            return false;
        }
    }

    var _main_available = inventory_get_amount(global.inventory_main, _item_id);
    var _cabinet_amount = inventory_get_amount(_cabinet.storage_inventory, _item_id);
    var _cabinet_space = global.RESTOCK_MAX - _cabinet_amount;
    var _target_amount = max(
        _needed_amount,
        global.RESTOCK_TARGET - _cabinet_amount
    );
    var _quantity = min(_target_amount, _main_available, _cabinet_space);

    if (_quantity <= 0) return false;

    array_push(global.restock_jobs, {
        item_id : _item_id,
        target_cabinet : _cabinet,
        qty : _quantity,
        priority : 999 + _needed_amount
    });

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 5. ПОИСК ПЛАНОВЫХ ПОТРЕБНОСТЕЙ
// ═══════════════════════════════════════════════════════════════

function restock_scan_needs() {
    if (!variable_global_exists("restock_jobs")) global.restock_jobs = [];
    if (!variable_global_exists("RESTOCK_TARGET")) global.RESTOCK_TARGET = 10;
    if (!variable_global_exists("RESTOCK_MAX")) global.RESTOCK_MAX = 10;

    var _has_procedure_patients = false;

    with (obj_owner) {
        if (
            state == "waiting"
            && assigned_doctor == noone
            && service_queue_type == "procedure"
        ) {
            _has_procedure_patients = true;
            break;
        }
    }

    // Чистим битые и неактуальные плановые задания.
    for (var _clean_index = array_length(global.restock_jobs) - 1; _clean_index >= 0; _clean_index--) {
        var _job = global.restock_jobs[_clean_index];

        if (!instance_exists(_job.target_cabinet)) {
            array_delete(global.restock_jobs, _clean_index, 1);
            continue;
        }

        if (_has_procedure_patients && _job.priority < 1000) {
            array_delete(global.restock_jobs, _clean_index, 1);
        }
    }

    // При ожидающих пациентах новые плановые задания не создаются.
    if (_has_procedure_patients) return;
    if (!instance_exists(storage_find_main())) return;

    for (var _cabinet_index = 0; _cabinet_index < instance_number(obj_storage_cabinet); _cabinet_index++) {
        var _cabinet = instance_find(obj_storage_cabinet, _cabinet_index);

        if (!instance_exists(_cabinet)) continue;
        if (!variable_instance_exists(_cabinet, "storage_inventory")) continue;
        if (!is_struct(_cabinet.storage_inventory)) continue;

        for (var _item_index = 0; _item_index < array_length(global.item_ids); _item_index++) {
            var _item_id = global.item_ids[_item_index];
            var _in_cabinet = inventory_get_amount(_cabinet.storage_inventory, _item_id);
            var _in_main = inventory_get_amount(global.inventory_main, _item_id);

            // Ассистент поддерживает шкаф на целевом уровне, а не ждёт,
            // пока запас упадёт ниже трёх единиц. Поэтому любой шкаф
            // ниже RESTOCK_TARGET создаёт плановое задание пополнения.
            var _planned_restock_threshold = max(1, global.RESTOCK_TARGET);

            if (
                _in_cabinet >= _planned_restock_threshold
                || _in_main <= 0
            ) {
                continue;
            }

            var _needed = global.RESTOCK_TARGET - _in_cabinet;
            var _space = global.RESTOCK_MAX - _in_cabinet;

            if (_needed <= 0 || _space <= 0) continue;

            var _already_exists = false;

            for (var _existing_index = 0; _existing_index < array_length(global.restock_jobs); _existing_index++) {
                var _existing = global.restock_jobs[_existing_index];

                if (
                    _existing.target_cabinet == _cabinet
                    && _existing.item_id == _item_id
                ) {
                    _already_exists = true;
                    break;
                }
            }

            if (!_already_exists) {
                for (var _assistant_index = 0; _assistant_index < instance_number(obj_staff_assistant); _assistant_index++) {
                    var _assistant = instance_find(obj_staff_assistant, _assistant_index);

                    if (
                        instance_exists(_assistant)
                        && _assistant.restock_target_cabinet == _cabinet
                        && _assistant.restock_item_id == _item_id
                    ) {
                        _already_exists = true;
                        break;
                    }
                }
            }

            if (_already_exists) continue;

            // Задание хранит всю потребность. Конкретный ассистент позже
            // ограничит количество собственным уровнем Пополнения.
            var _quantity = min(_space, _in_main, _needed);

            if (_quantity <= 0) continue;

            array_push(global.restock_jobs, {
                item_id : _item_id,
                target_cabinet : _cabinet,
                qty : _quantity,
                priority : (_in_cabinet == 0) ? 1000 : 10
            });
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 6. АССИСТЕНТ БЕРЁТ ЗАДАНИЕ
// ═══════════════════════════════════════════════════════════════

function assistant_try_take_restock_job(_assistant, _only_critical = false) {
    if (!instance_exists(_assistant)) return false;
    if (!variable_instance_exists(_assistant, "assistant_state")) return false;

    var _can_take = (_assistant.assistant_state == "idle");

    if (
        !_can_take
        && _assistant.assistant_state == "performing_procedure"
        && _only_critical
    ) {
        _can_take = true;
    }

    if (!_can_take) return false;

    restock_scan_needs();

    if (!variable_global_exists("restock_jobs")) return false;
    if (array_length(global.restock_jobs) <= 0) return false;

    var _main_storage = storage_find_main();
    if (!instance_exists(_main_storage)) return false;

    var _best_index = -1;
    var _best_priority = -1;

    for (var _job_index = 0; _job_index < array_length(global.restock_jobs); _job_index++) {
        var _candidate_job = global.restock_jobs[_job_index];

        if (!instance_exists(_candidate_job.target_cabinet)) continue;

        if (_candidate_job.priority > _best_priority) {
            _best_priority = _candidate_job.priority;
            _best_index = _job_index;
        }
    }

    if (_best_index < 0) return false;

    var _job = global.restock_jobs[_best_index];
    array_delete(global.restock_jobs, _best_index, 1);

    assistant_extra_skills_init(_assistant);
    assistant_recalc_restock_stats(_assistant);

    var _main_available = inventory_get_amount(
        global.inventory_main,
        _job.item_id
    );

    var _cabinet_space = global.RESTOCK_MAX
        - inventory_get_amount(
            _job.target_cabinet.storage_inventory,
            _job.item_id
        );

    var _real_quantity = min(
        _job.qty,
        _assistant.restock_carry_max,
        _main_available,
        _cabinet_space
    );

    if (_real_quantity <= 0) return false;

    if (_assistant.assistant_state == "performing_procedure") {
        if (instance_exists(_assistant.assigned_table)) {
            _assistant.assigned_table.table_busy = false;
        }

        _assistant.procedure_was_interrupted_by_restock = true;
    } else {
        if (variable_instance_exists(_assistant, "assistant_reset_procedure")) {
            _assistant.assistant_reset_procedure();
        }
    }

    _assistant.restock_item_id = _job.item_id;
    _assistant.restock_target_cabinet = _job.target_cabinet;
    _assistant.restock_qty = _real_quantity;
    _assistant.restock_pickup_inst = _main_storage;
    _assistant.assistant_target_x = _main_storage.interact_x;
    _assistant.assistant_target_y = _main_storage.interact_y;
    _assistant.assistant_state = "restock_going_to_storage";

    path_end();

    if (mp_grid_path(
        global.ai_grid,
        _assistant.my_path,
        _assistant.x,
        _assistant.y,
        _assistant.assistant_target_x,
        _assistant.assistant_target_y,
        true
    )) {
        path_set_kind(_assistant.my_path, 1);
        path_start(
            _assistant.my_path,
            _assistant.p_move_speed,
            path_action_stop,
            true
        );
        _assistant.is_walking = true;
    } else {
        // Не телепортируем: движение напрямую продолжит Step ассистента.
        move_towards_point(
            _assistant.assistant_target_x,
            _assistant.assistant_target_y,
            _assistant.p_move_speed
        );
        _assistant.is_walking = true;
    }

    if (instance_exists(obj_UI_HUD) && _job.priority >= 1000) {
        var _item_name = item_get_name(_job.item_id);

        with (obj_UI_HUD) {
            show_notice(
                "ПОПОЛНЕНИЕ СРОЧНО",
                "В шкафу закончился " + _item_name,
                game_get_speed(gamespeed_fps) * 2
            );
        }
    }

    return true;
}
