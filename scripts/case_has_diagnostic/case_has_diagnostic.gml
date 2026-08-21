function case_has_diagnostic(_case, _diag_id) {

    if (!is_struct(_case)) return false;

    for (var i = 0; i < array_length(_case.completed_diagnostics); i++) {
        if (_case.completed_diagnostics[i] == _diag_id) {
            return true;
        }
    }

    return false;
}