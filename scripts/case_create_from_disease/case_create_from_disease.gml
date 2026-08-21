function case_create_from_disease(_disease_id, _species_id) {
    if (!variable_struct_exists(global.med_db.diseases, _disease_id)) {
        return undefined;
    }

    var _severity_level = irandom_range(1, 4);
    var _severity_name_ru = "Среднее";
    var _base_condition = 70;

    switch (_severity_level) {
        case 1:
            _severity_name_ru = "Лёгкое";
            _base_condition = irandom_range(80, 100);
        break;

        case 2:
            _severity_name_ru = "Среднее";
            _base_condition = irandom_range(60, 79);
        break;

        case 3:
            _severity_name_ru = "Тяжёлое";
            _base_condition = irandom_range(40, 59);
        break;

        case 4:
            _severity_name_ru = "Критическое";
            _base_condition = irandom_range(20, 39);
        break;
    }

    var _visible = case_build_visible_symptoms(_disease_id);

    var _planned_treatment = [];

    for (var i = 0; i < array_length(global.med_db.disease_treatment); i++) {
        var _step = global.med_db.disease_treatment[i];

        if (_step.disease_id != _disease_id) continue;

        array_push(_planned_treatment, {
            action_id : _step.action_id,
            count : variable_struct_exists(_step, "count") ? _step.count : 1,
            days : variable_struct_exists(_step, "days") ? _step.days : 1,
            reveal_level : variable_struct_exists(_step, "reveal_level") ? _step.reveal_level : 0,
            required : variable_struct_exists(_step, "required") ? _step.required : false,
            severity_or_condition : variable_struct_exists(_step, "severity_or_condition") ? _step.severity_or_condition : "any",
            notes : variable_struct_exists(_step, "notes") ? _step.notes : "",
            repeat_until_recovered : variable_struct_exists(_step, "repeat_until_recovered") ? _step.repeat_until_recovered : false,
            per_visit_limit : variable_struct_exists(_step, "per_visit_limit") ? _step.per_visit_limit : 1
        });
    }

    return {
        case_id : db_next_case_id(),
        animal_species : _species_id,
        hidden_disease_id : _disease_id,

        visible_symptoms : _visible,
        reveal_level : 0,
        confirmed : false,

        completed_diagnostics : [],
        treatment_progress : [],
        planned_treatment : _planned_treatment,

        visit_diagnostics_done : [],
        visit_treatments_done : [],
        visit_procedure_log : [],

        visit_treatment_feedback_ok_ids : [],
        visit_treatment_feedback_bad_ids : [],

        severity_level : _severity_level,
        severity_name_ru : _severity_name_ru,

        initial_condition : _base_condition,
        condition : _base_condition,

        owner_trust : 60,
        case_status : "new"
    };
}