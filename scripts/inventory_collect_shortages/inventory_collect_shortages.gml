function inventory_collect_shortages() {
    var _need_map = {};
    var _result = [];

    // 1. Уже активные пациенты на процедурах
    for (var i = 0; i < instance_number(obj_owner); i++) {
        var _o = instance_find(obj_owner, i);
        if (!instance_exists(_o)) continue;

        if (!variable_instance_exists(_o, "service_queue_type")) continue;
        if (_o.service_queue_type != "procedure") continue;

        if (!variable_instance_exists(_o, "my_pet")) continue;
        if (!instance_exists(_o.my_pet)) continue;
        if (!variable_instance_exists(_o.my_pet, "current_case")) continue;
        if (!is_struct(_o.my_pet.current_case)) continue;

        var _case = _o.my_pet.current_case;

        if (!variable_struct_exists(_case, "pending_procedure_actions")) continue;

        for (var a = 0; a < array_length(_case.pending_procedure_actions); a++) {
            var _action_id = _case.pending_procedure_actions[a];
            var _reqs = treatment_get_required_items(_action_id);

            for (var r = 0; r < array_length(_reqs); r++) {
                var _item_id = _reqs[r].item_id;
                var _amount = _reqs[r].amount;

                var _old = 0;
                if (variable_struct_exists(_need_map, _item_id)) {
                    _old = variable_struct_get(_need_map, _item_id);
                }

                variable_struct_set(_need_map, _item_id, _old + _amount);
            }
        }
    }

    // 2. Запланированные процедурные визиты
    if (variable_global_exists("scheduled_visits")) {
        for (var s = 0; s < array_length(global.scheduled_visits); s++) {
            var _sv = global.scheduled_visits[s];

            if (_sv.status != "pending" && _sv.status != "spawned") continue;
            if (!variable_struct_exists(_sv, "visit_type_id")) continue;
            if (_sv.visit_type_id != "procedure_visit") continue;
            if (!variable_struct_exists(_sv, "pending_procedure_actions")) continue;

            for (var p = 0; p < array_length(_sv.pending_procedure_actions); p++) {
                var _action_id2 = _sv.pending_procedure_actions[p];
                var _reqs2 = treatment_get_required_items(_action_id2);

                for (var rr = 0; rr < array_length(_reqs2); rr++) {
                    var _item_id2 = _reqs2[rr].item_id;
                    var _amount2 = _reqs2[rr].amount;

                    var _old2 = 0;
                    if (variable_struct_exists(_need_map, _item_id2)) {
                        _old2 = variable_struct_get(_need_map, _item_id2);
                    }

                    variable_struct_set(_need_map, _item_id2, _old2 + _amount2);
                }
            }
        }
    }

    // 3. Формируем итоговый список дефицита
    if (variable_global_exists("item_ids")) {
        for (var q = 0; q < array_length(global.item_ids); q++) {
            var _item_id3 = global.item_ids[q];
            var _need_total = 0;

            if (variable_struct_exists(_need_map, _item_id3)) {
                _need_total = variable_struct_get(_need_map, _item_id3);
            }

            var _have_total = inventory_get_total_item_amount(_item_id3);
            var _shortage = max(0, _need_total - _have_total);

            if (_shortage > 0) {
                array_push(_result, {
                    item_id : _item_id3,
                    item_name_ru : item_get_name(_item_id3),
                    need_total : _need_total,
                    have_total : _have_total,
                    shortage : _shortage
                });
            }
        }
    }

    return _result;
}