function case_get_available_diagnostics(_case) {

    var _result = [];

    if (!is_struct(_case)) return _result;

    for (var i = 0; i < array_length(global.med_db.disease_diagnostics); i++) {

        var _link = global.med_db.disease_diagnostics[i];

        if (_link.disease_id != _case.hidden_disease_id) continue;

        if (!case_has_diagnostic(_case, _link.diagnostic_id)) {
            array_push(_result, _link.diagnostic_id);
        }
    }

    return _result;
}