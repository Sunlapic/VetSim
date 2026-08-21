/// reception_recover_orphaned_registration(_owner, _force)
/// @description Возвращает владельца в очередь, если регистрация/оплата осталась без исполнителя.

function reception_recover_orphaned_registration(_owner, _force = false) {
    if (!instance_exists(_owner)) return false;
    if (!variable_instance_exists(_owner, "state")) return false;

    // Восстанавливать нужно только владельца, застрявшего в рабочем состоянии.
    if (_owner.state != "registering" && _owner.state != "paying") {
        if (variable_instance_exists(_owner, "orphan_registration_timer")) {
            _owner.orphan_registration_timer = 0;
        }
        return false;
    }

    if (!variable_instance_exists(_owner, "orphan_registration_timer")) {
        _owner.orphan_registration_timer = 0;
    }


    // ═══════════════════════════════════════════════════════════
    // 1. ПРОВЕРКА NPC-АДМИНИСТРАТОРОВ
    // ═══════════════════════════════════════════════════════════

    var _active_actor_found = false;
    var _admin_count = instance_number(obj_staff_admin);

    for (var _admin_index = 0; _admin_index < _admin_count; _admin_index++) {
        var _admin = instance_find(obj_staff_admin, _admin_index);

        if (!instance_exists(_admin)) continue;
        if (!variable_instance_exists(_admin, "reception_client")) continue;
        if (_admin.reception_client != _owner) continue;

        var _admin_is_working = true;

        if (variable_instance_exists(_admin, "reception_state")) {
            _admin_is_working = (
                _admin.reception_state == "going_to_register_spot"
                || _admin.reception_state == "registering"
            );
        }

        if (_admin_is_working) {
            _active_actor_found = true;
            break;
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 2. ПРОВЕРКА ГЛАВНОГО ИГРОКА
    // ═══════════════════════════════════════════════════════════

    if (!_active_actor_found && instance_exists(obj_player)) {
        var _player = instance_find(obj_player, 0);

        if (
            instance_exists(_player)
            && variable_instance_exists(_player, "registration_target_owner")
            && _player.registration_target_owner == _owner
            && variable_instance_exists(_player, "doctor_state")
        ) {
            _active_actor_found = (
                _player.doctor_state == "going_to_reception"
                || _player.doctor_state == "going_to_payment"
                || _player.doctor_state == "manual_registering"
                || _player.doctor_state == "manual_payment"
            );
        }
    }

    if (_active_actor_found && !_force) {
        _owner.orphan_registration_timer = 0;
        return false;
    }


    // ═══════════════════════════════════════════════════════════
    // 3. НЕБОЛЬШАЯ ЗАДЕРЖКА ДЛЯ АВТОМАТИЧЕСКОЙ ПРОВЕРКИ
    // Принудительный вызов из Cleanup администратора срабатывает сразу.
    // ═══════════════════════════════════════════════════════════

    if (!_force) {
        _owner.orphan_registration_timer += 1;

        if (_owner.orphan_registration_timer < max(2, round(room_speed * 0.35))) {
            return false;
        }
    }

    _owner.orphan_registration_timer = 0;


    // ═══════════════════════════════════════════════════════════
    // 4. ОПРЕДЕЛЕНИЕ СТОЙКИ
    // ═══════════════════════════════════════════════════════════

    var _desk = noone;

    if (
        variable_instance_exists(_owner, "assigned_desk")
        && instance_exists(_owner.assigned_desk)
    ) {
        _desk = _owner.assigned_desk;
    }
    else if (instance_exists(obj_reception_desk)) {
        _desk = instance_find(obj_reception_desk, 0);
        _owner.assigned_desk = _desk;
    }


    // ═══════════════════════════════════════════════════════════
    // 5. ВОЗВРАТ ВЛАДЕЛЬЦА В НАЧАЛО ОЧЕРЕДИ
    // ═══════════════════════════════════════════════════════════

    with (_owner) {
        path_end();
        speed = 0;
        is_walking = false;

        state = "in_queue";
        registration_in_progress = false;
        registration_timer = 0;
        registration_timer_max = 0;
        registration_actor_name = "";

        action_progress_active = false;
        action_progress_timer = 0;
    }

    if (
        instance_exists(_desk)
        && variable_instance_exists(_desk, "queue_list")
        && ds_exists(_desk.queue_list, ds_type_list)
    ) {
        // Удаляем уничтоженные ссылки, которые могли остаться после старой ошибки.
        for (var _clean_index = ds_list_size(_desk.queue_list) - 1; _clean_index >= 0; _clean_index--) {
            var _queued_instance = _desk.queue_list[| _clean_index];

            if (!instance_exists(_queued_instance)) {
                ds_list_delete(_desk.queue_list, _clean_index);
            }
        }

        // Прерванный клиент обслуживался первым, поэтому возвращаем его в начало.
        var _owner_queue_index = ds_list_find_index(_desk.queue_list, _owner);

        if (_owner_queue_index >= 0) {
            ds_list_delete(_desk.queue_list, _owner_queue_index);
        }

        ds_list_insert(_desk.queue_list, 0, _owner);

        // Немедленно восстанавливаем индексы всей очереди.
        for (var _queue_index = 0; _queue_index < ds_list_size(_desk.queue_list); _queue_index++) {
            var _queued_owner = _desk.queue_list[| _queue_index];

            if (!instance_exists(_queued_owner)) continue;

            if (variable_instance_exists(_queued_owner, "queue_slot")) {
                _queued_owner.queue_slot = _queue_index;
            }

            if (
                variable_instance_exists(_desk, "queue_start_x")
                && variable_instance_exists(_desk, "queue_start_y")
                && variable_instance_exists(_desk, "queue_step_x")
            ) {
                _queued_owner.queue_target_x = _desk.queue_start_x
                    + _queue_index * _desk.queue_step_x;
                _queued_owner.queue_target_y = _desk.queue_start_y;
            }
        }

        // Существующая логика стойки перестроит маршруты оставшихся владельцев.
        _desk.alarm[0] = 1;
    }
    else {
        // Даже без списка владелец должен стать кликабельным для ручного оформления.
        _owner.queue_slot = 0;
    }

    return true;
}
