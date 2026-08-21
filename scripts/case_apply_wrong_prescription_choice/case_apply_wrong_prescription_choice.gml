function case_apply_wrong_prescription_choice(_animal_id, _action_id) {
    if (!instance_exists(_animal_id)) exit;

    with (_animal_id) {
        if (!is_struct(current_case)) exit;

        if (!variable_struct_exists(current_case, "visit_treatment_feedback_ok_ids")) {
            current_case.visit_treatment_feedback_ok_ids = [];
        }

        if (!variable_struct_exists(current_case, "visit_treatment_feedback_bad_ids")) {
            current_case.visit_treatment_feedback_bad_ids = [];
        }

        if (!variable_struct_exists(current_case, "visit_procedure_log")) {
            current_case.visit_procedure_log = [];
        }

        // Уже выбирали на этом визите
        for (var i = 0; i < array_length(current_case.visit_treatment_feedback_ok_ids); i++) {
            if (current_case.visit_treatment_feedback_ok_ids[i] == _action_id) {
                exit;
            }
        }

        for (var j = 0; j < array_length(current_case.visit_treatment_feedback_bad_ids); j++) {
            if (current_case.visit_treatment_feedback_bad_ids[j] == _action_id) {
                exit;
            }
        }

        array_push(current_case.visit_treatment_feedback_bad_ids, _action_id);

        array_push(current_case.visit_procedure_log, {
            proc_type : "prescription_wrong",
            proc_id : _action_id,
            proc_name_ru : db_get_treatment_action_name(_action_id) + " (ошибка назначения)"
        });

        current_case.condition = clamp(current_case.condition - 5, 0, 100);
        condition = current_case.condition;

        if (current_case.condition < 20) {
            current_case.case_status = "worsened";
        }

        animal_apply_case(id, current_case);
    }
}