function case_reveal_hidden_symptoms(_case, _count) {

    if (!is_struct(_case)) return _case;

    var _revealed = 0;

    for (var i = 0; i < array_length(global.med_db.disease_symptoms); i++) {

        var _link = global.med_db.disease_symptoms[i];

        if (_link.disease_id != _case.hidden_disease_id) continue;

        // Уже виден?
        var _already_visible = false;

        for (var j = 0; j < array_length(_case.visible_symptoms); j++) {
            if (_case.visible_symptoms[j] == _link.symptom_id) {
                _already_visible = true;
                break;
            }
        }

        if (_already_visible) continue;

        array_push(_case.visible_symptoms, _link.symptom_id);
        _revealed += 1;

        if (_revealed >= _count) {
            break;
        }
    }

    return _case;
}