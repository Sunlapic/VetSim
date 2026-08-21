/// animal_perform_diagnostic(_animal_id, _diagnostic_id)
/// @description Выполняет правильное обследование и сохраняет зелёную обратную связь.

function animal_perform_diagnostic(_animal_id, _diagnostic_id) {
    if (!instance_exists(_animal_id)) return false;
    if (!variable_instance_exists(_animal_id, "current_case")) return false;
    if (!is_struct(_animal_id.current_case)) return false;

    var _case = _animal_id.current_case;


    // ═══════════════════════════════════════════════════════════
    // 1. ИНИЦИАЛИЗАЦИЯ ОБРАТНОЙ СВЯЗИ
    // ═══════════════════════════════════════════════════════════

    if (!variable_struct_exists(_case, "visit_diagnostic_feedback_ok_ids")) {
        _case.visit_diagnostic_feedback_ok_ids = [];
    }

    if (!variable_struct_exists(_case, "visit_diagnostic_feedback_bad_ids")) {
        _case.visit_diagnostic_feedback_bad_ids = [];
    }


    // ═══════════════════════════════════════════════════════════
    // 2. ЗАЩИТА ОТ ПОВТОРНОГО НАЖАТИЯ
    // ═══════════════════════════════════════════════════════════

    for (var _ok_index = 0; _ok_index < array_length(_case.visit_diagnostic_feedback_ok_ids); _ok_index++) {
        if (_case.visit_diagnostic_feedback_ok_ids[_ok_index] == _diagnostic_id) {
            return false;
        }
    }

    for (var _bad_index = 0; _bad_index < array_length(_case.visit_diagnostic_feedback_bad_ids); _bad_index++) {
        if (_case.visit_diagnostic_feedback_bad_ids[_bad_index] == _diagnostic_id) {
            return false;
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 3. ВЫПОЛНЕНИЕ ОБСЛЕДОВАНИЯ
    // ═══════════════════════════════════════════════════════════

    _case = case_add_diagnostic(_case, _diagnostic_id);
    array_push(_case.visit_diagnostic_feedback_ok_ids, _diagnostic_id);

    _animal_id.current_case = _case;
    animal_apply_case(_animal_id, _case);

    return true;
}
