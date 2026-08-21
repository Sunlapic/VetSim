function case_build_next_procedure_assignments(_case) {
    var _result = [];
    if (!is_struct(_case)) return _result;

    if (!variable_struct_exists(_case, "prescribed_treatment_ids")) {
        _case.prescribed_treatment_ids = [];
    }

    if (!variable_struct_exists(_case, "visit_prescribed_actions")) {
        _case.visit_prescribed_actions = [];
    }

    var _plans = [];

    if (variable_struct_exists(_case, "planned_treatment") && array_length(_case.planned_treatment) > 0) {
        _plans = _case.planned_treatment;
    } else {
        for (var i = 0; i < array_length(global.med_db.disease_treatment); i++) {
            var _step = global.med_db.disease_treatment[i];

            if (_step.disease_id == _case.hidden_disease_id) {
                array_push(_plans, _step);
            }
        }
    }

    function _is_prescribed(_arr, _action_id) {
        for (var i = 0; i < array_length(_arr); i++) {
            if (_arr[i] == _action_id) return true;
        }
        return false;
    }

    // Фолбэк: если по старой логике назначения лежат только в visit_prescribed_actions
    if (array_length(_case.prescribed_treatment_ids) <= 0 && array_length(_case.visit_prescribed_actions) > 0) {
        for (var vp = 0; vp < array_length(_case.visit_prescribed_actions); vp++) {
            var _vp_action = _case.visit_prescribed_actions[vp];

            if (!_is_prescribed(_case.prescribed_treatment_ids, _vp_action)) {
                array_push(_case.prescribed_treatment_ids, _vp_action);
            }
        }
    }

    for (var p = 0; p < array_length(_plans); p++) {
        var _plan = _plans[p];
        var _action_id = _plan.action_id;

        if (!_is_prescribed(_case.prescribed_treatment_ids, _action_id)) continue;

        var _repeat_until_recovered = variable_struct_exists(_plan, "repeat_until_recovered") ? _plan.repeat_until_recovered : false;
        var _need_count = variable_struct_exists(_plan, "count") ? _plan.count : 1;
        var _done_count = case_count_treatment_done(_case, _action_id);

        // Совместимость со старыми кейсами
        if (_action_id == "treat_iv_drip" || _action_id == "treat_painkiller") {
            _repeat_until_recovered = true;
        }

        if (_repeat_until_recovered) {
            if (_case.condition < 100) {
                array_push(_result, _action_id);
            }
        } else {
            if (_done_count < _need_count) {
                array_push(_result, _action_id);
            }
        }
    }

    return _result;
}