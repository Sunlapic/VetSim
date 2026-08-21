function animal_perform_physical_exam(_animal_id) {

    if (!instance_exists(_animal_id)) exit;

    with (_animal_id) {

        if (!is_struct(current_case)) exit;

        if (case_has_diagnostic(current_case, "diag_physical_exam")) exit;

        current_case = case_add_diagnostic(current_case, "diag_physical_exam");
        current_case = case_reveal_hidden_symptoms(current_case, 1);

        animal_apply_case(id, current_case);
    }
}