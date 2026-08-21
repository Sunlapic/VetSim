function case_add_diagnostic(_case, _diag_id) {
    if (!is_struct(_case)) return _case;

    if (!variable_struct_exists(_case, "completed_diagnostics")) _case.completed_diagnostics = [];
    if (!variable_struct_exists(_case, "visit_diagnostics_done")) _case.visit_diagnostics_done = [];
    if (!variable_struct_exists(_case, "visit_procedure_log")) _case.visit_procedure_log = [];

    // ЛОГ ЭТОГО ВИЗИТА:
    // даже если такая диагностика уже была в прошлом визите,
    // в журнал текущего визита её всё равно пишем один раз
    var _already_logged_this_visit = false;

    for (var a = 0; a < array_length(_case.visit_diagnostics_done); a++) {
        if (_case.visit_diagnostics_done[a] == _diag_id) {
            _already_logged_this_visit = true;
            break;
        }
    }

    if (!_already_logged_this_visit) {
        array_push(_case.visit_diagnostics_done, _diag_id);

        array_push(_case.visit_procedure_log, {
            proc_type : "diagnostic",
            proc_id : _diag_id,
            proc_name_ru : db_get_diagnostic_name(_diag_id)
        });
    }

    // Если уже открывали эту диагностику раньше по кейсу — просто выходим
    for (var i = 0; i < array_length(_case.completed_diagnostics); i++) {
        if (_case.completed_diagnostics[i] == _diag_id) {
            return _case;
        }
    }

    var _old_reveal = variable_struct_exists(_case, "reveal_level") ? _case.reveal_level : 0;

    array_push(_case.completed_diagnostics, _diag_id);

    // Повышаем reveal_level / подтверждаем диагноз
    for (var j = 0; j < array_length(global.med_db.disease_diagnostics); j++) {
        var _link = global.med_db.disease_diagnostics[j];

        if (_link.disease_id == _case.hidden_disease_id && _link.diagnostic_id == _diag_id) {
            _case.reveal_level = max(_case.reveal_level, _link.unlocks_reveal_level);

            if (_link.required_to_confirm) {
                _case.confirmed = true;
            }
        }
    }

    var _reveal_gain = max(0, _case.reveal_level - _old_reveal);

    if (_reveal_gain > 0) {
        _case = case_reveal_hidden_symptoms(_case, _reveal_gain);
    }

    return _case;
}