function case_assign_treatment_action(_animal_id, _action_id) {
    if (!instance_exists(_animal_id)) exit;

    with (_animal_id) {
        if (!is_struct(current_case)) exit;

        if (!variable_struct_exists(current_case, "prescribed_treatment_ids")) {
            current_case.prescribed_treatment_ids = [];
        }

        if (!variable_struct_exists(current_case, "visit_prescribed_actions")) {
            current_case.visit_prescribed_actions = [];
        }

        if (!variable_struct_exists(current_case, "visit_treatment_feedback_ok_ids")) {
            current_case.visit_treatment_feedback_ok_ids = [];
        }

        if (!variable_struct_exists(current_case, "visit_treatment_feedback_bad_ids")) {
            current_case.visit_treatment_feedback_bad_ids = [];
        }

        if (!variable_struct_exists(current_case, "visit_procedure_log")) {
            current_case.visit_procedure_log = [];
        }

        // Уже выбрали на этом визите?
        for (var i = 0; i < array_length(current_case.visit_treatment_feedback_ok_ids); i++) {
            if (current_case.visit_treatment_feedback_ok_ids[i] == _action_id) exit;
        }

        for (var j = 0; j < array_length(current_case.visit_treatment_feedback_bad_ids); j++) {
            if (current_case.visit_treatment_feedback_bad_ids[j] == _action_id) exit;
        }

        // Отмечаем визуально как правильное назначение
        array_push(current_case.visit_treatment_feedback_ok_ids, _action_id);

        // Добавляем в назначения, если ещё нет
        var _already_prescribed = false;
        for (var p = 0; p < array_length(current_case.prescribed_treatment_ids); p++) {
            if (current_case.prescribed_treatment_ids[p] == _action_id) {
                _already_prescribed = true;
                break;
            }
        }

        if (!_already_prescribed) {
            array_push(current_case.prescribed_treatment_ids, _action_id);
        }

        array_push(current_case.visit_prescribed_actions, _action_id);

        array_push(current_case.visit_procedure_log, {
            proc_type : "prescription",
            proc_id : _action_id,
            proc_name_ru : db_get_treatment_action_name(_action_id)
        });

        // ═══════════════════════════════════════════════════════════
        // НАЗНАЧЕНИЕ БОЛЬШЕ НЕ ЛЕЧИТ
        //
        // Здесь стояло condition + 5 с комментарием «назначение врача
        // немного улучшает состояние». Логически это неверно: врач
        // ещё ничего не сделал, он только выписал лечение. Лечит
        // процедура, а не запись в карте.
        //
        // На практике это и было второй половиной проблемы. Врач за
        // один приём назначает СРАЗУ ВСЕ подходящие пункты (цикл в
        // obj_staff_doctor -> Step), то есть два назначения давали
        // +10 состояния не приходя в сознание. Лёгкий случай на 92%
        // добирал до 100% прямо на столе, и ассистент оставался не у
        // дел.
        //
        // Состояние теперь меняют только фактически выполненные
        // действия — case_apply_treatment_action.
        // ═══════════════════════════════════════════════════════════

        // Статус переводим в «лечение назначено». Проверку на 100%
        // оставляем: состояние могло достичь сотни раньше, на
        // выполненных процедурах, и терять этот статус нельзя.
        if (current_case.condition >= 100) {
            current_case.case_status = "recovered";
        } else {
            current_case.case_status = "treatment_assigned";
        }

        animal_apply_case(id, current_case);
    }
}