function case_build_visible_symptoms(_disease_id) {

    var _result = [];

    for (var i = 0; i < array_length(global.med_db.disease_symptoms); i++) {

        var _link = global.med_db.disease_symptoms[i];

        if (_link.disease_id == _disease_id && _link.visible_on_start) {
            array_push(_result, _link.symptom_id);
        }
    }

    return _result;
}