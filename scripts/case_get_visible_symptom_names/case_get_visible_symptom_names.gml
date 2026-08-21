function case_get_visible_symptom_names(_case) {

    var _names = [];

    for (var i = 0; i < array_length(_case.visible_symptoms); i++) {
        var _sym_id = _case.visible_symptoms[i];
        array_push(_names, case_get_symptom_name(_sym_id));
    }

    return _names;
}