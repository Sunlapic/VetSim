function case_get_symptom_name(_symptom_id) {

    if (variable_struct_exists(global.med_db.symptoms, _symptom_id)) {
        var _s = variable_struct_get(global.med_db.symptoms, _symptom_id);
        return _s.name_ru;
    }

    return "Неизвестный симптом";
}