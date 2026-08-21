function case_count_treatment_done(_case, _action_id) {

    if (!is_struct(_case)) return 0;

    var _count = 0;

    for (var i = 0; i < array_length(_case.treatment_progress); i++) {
        if (_case.treatment_progress[i] == _action_id) {
            _count += 1;
        }
    }

    return _count;
}