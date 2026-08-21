function animal_apply_case(_animal_id, _case) {
    if (!instance_exists(_animal_id)) exit;
    if (!is_struct(_case)) exit;

    var _brief_problem = case_get_brief_complaint(_case);

    with (_animal_id) {
        current_case = _case;
        current_case_id = _case.case_id;
        hidden_disease_id = _case.hidden_disease_id;

        visible_symptoms = _case.visible_symptoms;
        reveal_level = _case.reveal_level;
        diagnosis_confirmed = _case.confirmed;

        condition = _case.condition;
        problem = _brief_problem;

        severity_level = variable_struct_exists(_case, "severity_level") ? _case.severity_level : 0;
        severity_name_ru = variable_struct_exists(_case, "severity_name_ru") ? _case.severity_name_ru : "";

        planned_treatment = variable_struct_exists(_case, "planned_treatment") ? _case.planned_treatment : [];
        visit_diagnostics_done = variable_struct_exists(_case, "visit_diagnostics_done") ? _case.visit_diagnostics_done : [];
        visit_treatments_done = variable_struct_exists(_case, "visit_treatments_done") ? _case.visit_treatments_done : [];
        visit_procedure_log = variable_struct_exists(_case, "visit_procedure_log") ? _case.visit_procedure_log : [];
    }
}