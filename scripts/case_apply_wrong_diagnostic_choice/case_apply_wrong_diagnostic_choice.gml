/// case_apply_wrong_diagnostic_choice(_animal_id, _diagnostic_id)
/// @description Регистрирует лишнее обследование без ухудшения состояния питомца.

function case_apply_wrong_diagnostic_choice(_animal_id, _diagnostic_id) {
    if (!instance_exists(_animal_id)) return false;
    if (!variable_instance_exists(_animal_id, "current_case")) return false;
    if (!is_struct(_animal_id.current_case)) return false;

    var _case = _animal_id.current_case;


    // ═══════════════════════════════════════════════════════════
    // 1. ИНИЦИАЛИЗАЦИЯ ДАННЫХ ВИЗИТА
    // ═══════════════════════════════════════════════════════════

    if (!variable_struct_exists(_case, "visit_diagnostic_feedback_ok_ids")) {
        _case.visit_diagnostic_feedback_ok_ids = [];
    }

    if (!variable_struct_exists(_case, "visit_diagnostic_feedback_bad_ids")) {
        _case.visit_diagnostic_feedback_bad_ids = [];
    }

    if (!variable_struct_exists(_case, "visit_wrong_diagnostics_done")) {
        _case.visit_wrong_diagnostics_done = [];
    }

    if (!variable_struct_exists(_case, "visit_procedure_log")) {
        _case.visit_procedure_log = [];
    }

    if (!variable_struct_exists(_case, "visit_extra_diagnostic_cost")) {
        _case.visit_extra_diagnostic_cost = 0;
    }

    if (!variable_struct_exists(_case, "visit_extra_diagnostic_time_min")) {
        _case.visit_extra_diagnostic_time_min = 0;
    }


    // ═══════════════════════════════════════════════════════════
    // 2. ЗАЩИТА ОТ ПОВТОРНОГО НАЖАТИЯ
    // ═══════════════════════════════════════════════════════════

    for (var _ok_index = 0; _ok_index < array_length(_case.visit_diagnostic_feedback_ok_ids); _ok_index++) {
        if (_case.visit_diagnostic_feedback_ok_ids[_ok_index] == _diagnostic_id) {
            return false;
        }
    }

    for (var _bad_index = 0; _bad_index < array_length(_case.visit_diagnostic_feedback_bad_ids); _bad_index++) {
        if (_case.visit_diagnostic_feedback_bad_ids[_bad_index] == _diagnostic_id) {
            return false;
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 3. СТОИМОСТЬ И ВРЕМЯ ЛИШНЕГО ОБСЛЕДОВАНИЯ
    // ═══════════════════════════════════════════════════════════

    var _diagnostic_price = 0;
    var _diagnostic_time = 0;

    if (variable_struct_exists(global.med_db.diagnostics, _diagnostic_id)) {
        var _diagnostic = variable_struct_get(global.med_db.diagnostics, _diagnostic_id);

        if (variable_struct_exists(_diagnostic, "price")) {
            _diagnostic_price = max(0, _diagnostic.price);
        }

        if (variable_struct_exists(_diagnostic, "time_min")) {
            _diagnostic_time = max(0, _diagnostic.time_min);
        }
    }

    array_push(_case.visit_diagnostic_feedback_bad_ids, _diagnostic_id);
    array_push(_case.visit_wrong_diagnostics_done, _diagnostic_id);

    _case.visit_extra_diagnostic_cost += _diagnostic_price;
    _case.visit_extra_diagnostic_time_min += _diagnostic_time;

    array_push(_case.visit_procedure_log, {
        proc_type : "diagnostic_wrong",
        proc_id : _diagnostic_id,
        proc_name_ru : db_get_diagnostic_name(_diagnostic_id) + " (лишнее обследование)",
        proc_cost : _diagnostic_price,
        proc_time_min : _diagnostic_time
    });


    // ═══════════════════════════════════════════════════════════
    // 4. ДОБАВЛЕНИЕ ЛИШНЕЙ СТОИМОСТИ В БУДУЩУЮ ОПЛАТУ
    // Состояние питомца намеренно не меняется.
    // ═══════════════════════════════════════════════════════════

    if (variable_instance_exists(_animal_id, "my_owner") && instance_exists(_animal_id.my_owner)) {
        var _owner = _animal_id.my_owner;

        if (!variable_instance_exists(_owner, "pending_payment_total")) {
            _owner.pending_payment_total = 0;
        }

        _owner.pending_payment_total += _diagnostic_price;
    }

    _animal_id.current_case = _case;
    animal_apply_case(_animal_id, _case);

    return true;
}
