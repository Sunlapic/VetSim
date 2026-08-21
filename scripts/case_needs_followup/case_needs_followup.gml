function case_needs_followup(_outcome) {

    if (!is_struct(_outcome)) return false;
    if (!variable_struct_exists(_outcome, "needs_followup")) return false;

    return _outcome.needs_followup;
}