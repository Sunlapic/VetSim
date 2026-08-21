/// runtime_resource_cleanup.gml
/// @description Централизованная очистка ссылок, массивов и tracking-map.


// ═══════════════════════════════════════════════════════════════
// 1. УДАЛЕНИЕ INSTANCE ИЗ ГЛОБАЛЬНОГО МАССИВА
// ═══════════════════════════════════════════════════════════════

function runtime_cleanup_remove_from_global_array(_array_name, _actor) {
    if (!variable_global_exists(_array_name)) return 0;

    var _array = variable_global_get(_array_name);
    if (!is_array(_array)) return 0;

    var _removed = 0;

    for (var _index = array_length(_array) - 1; _index >= 0; _index--) {
        if (_array[_index] == _actor) {
            array_delete(_array, _index, 1);
            _removed += 1;
        }
    }

    variable_global_set(_array_name, _array);
    return _removed;
}

function runtime_cleanup_prune_global_instance_array(_array_name) {
    if (!variable_global_exists(_array_name)) return 0;

    var _array = variable_global_get(_array_name);
    if (!is_array(_array)) return 0;

    var _removed = 0;

    for (var _index = array_length(_array) - 1; _index >= 0; _index--) {
        if (!instance_exists(_array[_index])) {
            array_delete(_array, _index, 1);
            _removed += 1;
        }
    }

    variable_global_set(_array_name, _array);
    return _removed;
}


// ═══════════════════════════════════════════════════════════════
// 2. КАРТА ТРАФИКА СИСТЕМЫ ЧИСТОТЫ
// ═══════════════════════════════════════════════════════════════

function runtime_cleanup_remove_actor_tracking(_actor) {
    if (!instance_exists(obj_cleanliness_controller)) return false;

    var _controller = instance_find(obj_cleanliness_controller, 0);
    if (!instance_exists(_controller)) return false;
    if (!variable_instance_exists(_controller, "actor_position_map")) return false;
    if (!ds_exists(_controller.actor_position_map, ds_type_map)) return false;

    var _key = string(_actor);

    if (ds_map_exists(_controller.actor_position_map, _key)) {
        ds_map_delete(_controller.actor_position_map, _key);
        return true;
    }

    return false;
}

function runtime_cleanup_collect_keys(_keys, _object_type) {
    for (var _index = 0; _index < instance_number(_object_type); _index++) {
        var _actor = instance_find(_object_type, _index);

        if (instance_exists(_actor)) {
            array_push(_keys, string(_actor));
        }
    }

    return _keys;
}

function runtime_cleanup_key_is_live(_key, _live_keys) {
    for (var _index = 0; _index < array_length(_live_keys); _index++) {
        if (_live_keys[_index] == _key) return true;
    }

    return false;
}

function runtime_cleanup_prune_tracking_map(_controller) {
    if (!instance_exists(_controller)) return 0;
    if (!variable_instance_exists(_controller, "actor_position_map")) return 0;
    if (!ds_exists(_controller.actor_position_map, ds_type_map)) return 0;

    var _live_keys = [];
    _live_keys = runtime_cleanup_collect_keys(_live_keys, obj_player);
    _live_keys = runtime_cleanup_collect_keys(_live_keys, obj_staff_doctor);
    _live_keys = runtime_cleanup_collect_keys(_live_keys, obj_staff_assistant);
    _live_keys = runtime_cleanup_collect_keys(_live_keys, obj_staff_admin);
    _live_keys = runtime_cleanup_collect_keys(_live_keys, obj_owner);

    var _removed = 0;
    var _key = ds_map_find_first(_controller.actor_position_map);

    while (!is_undefined(_key)) {
        var _next_key = ds_map_find_next(
            _controller.actor_position_map,
            _key
        );

        if (!runtime_cleanup_key_is_live(_key, _live_keys)) {
            ds_map_delete(_controller.actor_position_map, _key);
            _removed += 1;
        }

        _key = _next_key;
    }

    return _removed;
}


// ═══════════════════════════════════════════════════════════════
// 3. ОБЩИЕ ВНЕШНИЕ ССЫЛКИ НА ПЕРСОНАЖА
// ═══════════════════════════════════════════════════════════════

function runtime_cleanup_destroy_speech_bubbles(_actor) {
    if (!instance_exists(obj_speech_bubble)) return 0;

    var _removed = 0;

    with (obj_speech_bubble) {
        if (
            variable_instance_exists(id, "target")
            && target == _actor
        ) {
            _removed += 1;
            instance_destroy();
        }
    }

    return _removed;
}

function runtime_cleanup_actor_references(_actor) {
    runtime_cleanup_remove_actor_tracking(_actor);
    runtime_cleanup_remove_from_global_array("city_citizens", _actor);
    runtime_cleanup_remove_from_global_array("city_pet_owners", _actor);
    runtime_cleanup_remove_from_global_array("active_visitors", _actor);
    runtime_cleanup_destroy_speech_bubbles(_actor);

    if (
        variable_global_exists("hover_target")
        && global.hover_target == _actor
    ) {
        global.hover_target = noone;
    }

    if (instance_exists(obj_UI_Tablet)) {
        var _tablet = instance_find(obj_UI_Tablet, 0);

        if (
            instance_exists(_tablet)
            && variable_instance_exists(_tablet, "target_id")
            && _tablet.target_id == _actor
        ) {
            _tablet.visible = false;
            _tablet.target_id = noone;
        }
    }

    if (instance_exists(obj_UI_CandidateCard)) {
        var _candidate_card = instance_find(obj_UI_CandidateCard, 0);

        if (
            instance_exists(_candidate_card)
            && variable_instance_exists(_candidate_card, "target_candidate")
            && _candidate_card.target_candidate == _actor
        ) {
            _candidate_card.visible = false;
            _candidate_card.target_candidate = noone;
        }
    }

    if (instance_exists(obj_inpatient_controller)) {
        var _ward = instance_find(obj_inpatient_controller, 0);

        if (instance_exists(_ward)) {
            if (
                variable_instance_exists(_ward, "departing_owner")
                && _ward.departing_owner == _actor
            ) {
                _ward.departing_owner = noone;
            }

            if (
                variable_instance_exists(_ward, "returning_owner")
                && _ward.returning_owner == _actor
            ) {
                _ward.returning_owner = noone;
            }
        }
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 4. ОТВЯЗКА УВОЛЕННОГО СОТРУДНИКА
// ═══════════════════════════════════════════════════════════════

function runtime_cleanup_detach_staff(_staff) {
    if (instance_exists(obj_owner)) {
        with (obj_owner) {
            if (
                variable_instance_exists(id, "assigned_doctor")
                && assigned_doctor == _staff
            ) {
                assigned_doctor = noone;
            }
        }
    }

    if (instance_exists(obj_table)) {
        with (obj_table) {
            if (
                variable_instance_exists(id, "assigned_doctor")
                && assigned_doctor == _staff
            ) {
                assigned_doctor = noone;
                assigned_owner = noone;
                assigned_pet = noone;
                table_busy = false;
            }
        }
    }

    if (instance_exists(obj_table_1)) {
        with (obj_table_1) {
            if (
                variable_instance_exists(id, "assigned_doctor")
                && assigned_doctor == _staff
            ) {
                assigned_doctor = noone;
                assigned_owner = noone;
                assigned_pet = noone;
                table_busy = false;
            }
        }
    }

    if (instance_exists(obj_inpatient_controller)) {
        var _ward = instance_find(obj_inpatient_controller, 0);

        if (instance_exists(_ward)) {
            if (
                variable_instance_exists(_ward, "escort_doctor")
                && _ward.escort_doctor == _staff
            ) {
                _ward.escort_doctor = noone;
            }

            if (
                variable_instance_exists(_ward, "ward_doctor")
                && _ward.ward_doctor == _staff
            ) {
                _ward.ward_doctor = noone;
            }

            if (
                variable_instance_exists(_ward, "ward_assistant")
                && _ward.ward_assistant == _staff
            ) {
                _ward.ward_assistant = noone;
            }
        }
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 5. РЕДКАЯ СТРАХОВОЧНАЯ ОЧИСТКА
// ═══════════════════════════════════════════════════════════════

function runtime_cleanup_prune_stale_references(_controller) {
    if (!instance_exists(_controller)) return;

    if (!variable_instance_exists(_controller, "resource_prune_timer")) {
        _controller.resource_prune_timer = room_speed * 5;
    }

    _controller.resource_prune_timer -= 1;
    if (_controller.resource_prune_timer > 0) return;

    _controller.resource_prune_timer = max(1, room_speed * 5);

    runtime_cleanup_prune_tracking_map(_controller);
    runtime_cleanup_prune_global_instance_array("city_citizens");
    runtime_cleanup_prune_global_instance_array("city_pet_owners");
    runtime_cleanup_prune_global_instance_array("active_visitors");
}
