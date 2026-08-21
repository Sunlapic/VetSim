function case_is_required_treatment_complete(_case) {
    if (!is_struct(_case)) return false;

    if (variable_struct_exists(_case, "planned_treatment") && array_length(_case.planned_treatment) > 0) {
        for (var i = 0; i < array_length(_case.planned_treatment); i++) {
            var _plan = _case.planned_treatment[i];

            if (!variable_struct_exists(global.med_db.treatment_actions, _plan.action_id)) {
                continue;
            }

            if (!_plan.required) continue;

            var _repeat_until_recovered = variable_struct_exists(_plan, "repeat_until_recovered") ? _plan.repeat_until_recovered : false;

            // совместимость со старыми кейсами
            if (_plan.action_id == "treat_iv_drip" || _plan.action_id == "treat_painkiller") {
                _repeat_until_recovered = true;
            }

            if (_repeat_until_recovered) {
                if (_case.condition < 100) {
                    return false;
                }
            } else {
                var _done = case_count_treatment_done(_case, _plan.action_id);
                var _need = variable_struct_exists(_plan, "count") ? _plan.count : 1;

                if (_done < _need) {
                    return false;
                }
            }
        }

        return true;
    }

    for (var j = 0; j < array_length(global.med_db.disease_treatment); j++) {
        var _step = global.med_db.disease_treatment[j];

        if (_step.disease_id != _case.hidden_disease_id) continue;
        if (!_step.required) continue;

        var _repeat = variable_struct_exists(_step, "repeat_until_recovered") ? _step.repeat_until_recovered : false;

        if (_step.action_id == "treat_iv_drip" || _step.action_id == "treat_painkiller") {
            _repeat = true;
        }

        if (_repeat) {
            if (_case.condition < 100) {
                return false;
            }
        } else {
            var _done2 = case_count_treatment_done(_case, _step.action_id);
            var _need2 = variable_struct_exists(_step, "count") ? _step.count : 1;

            if (_done2 < _need2) {
                return false;
            }
        }
    }

    return true;
}