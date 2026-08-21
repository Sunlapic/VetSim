function case_evaluate_outcome(_case) {
    if (!is_struct(_case)) {
        return {
            outcome_id : "outcome_generic",
            outcome_name_ru : "Приём завершён",
            trust_delta : 0,
            payout_mult : 0.50,
            condition_after : 80,
            needs_followup : false,
            followup_days : 0,
            followup_reason : ""
        };
    }

    var _cond = clamp(_case.condition, 0, 100);
    var _confirmed = variable_struct_exists(_case, "confirmed") ? _case.confirmed : false;
    var _required_complete = case_is_required_treatment_complete(_case);

    var _diag_count = variable_struct_exists(_case, "completed_diagnostics") ? array_length(_case.completed_diagnostics) : 0;
    var _treat_count = variable_struct_exists(_case, "treatment_progress") ? array_length(_case.treatment_progress) : 0;

    var _result = {
        outcome_id : "outcome_followup",
        outcome_name_ru : "Пациент записан на повторный приём",
        trust_delta : 2,
        payout_mult : 0.85,
        condition_after : _cond,
        needs_followup : true,
        followup_days : 1,
        followup_reason : "Продолжение курса лечения"
    };

    // Полное выздоровление
    if (_confirmed && _required_complete && _cond >= 100) {
        _result.outcome_id = "outcome_recovered";
        _result.outcome_name_ru = "Выздоровел";
        _result.trust_delta = 10;
        _result.payout_mult = 1.00;
        _result.condition_after = 100;
        _result.needs_followup = false;
        _result.followup_days = 0;
        _result.followup_reason = "";
        return _result;
    }

    // Очень плохое состояние
    if (_cond < 20) {
        _result.outcome_id = "outcome_worsened";
        _result.outcome_name_ru = "Состояние ухудшилось";
        _result.trust_delta = -10;
        _result.payout_mult = 0.35;
        _result.condition_after = _cond;
        _result.needs_followup = true;
        _result.followup_days = 1;
        _result.followup_reason = "Срочный повторный приём";
        return _result;
    }

    // Диагноз подтверждён, но курс ещё не закончен
    if (_confirmed) {
        _result.outcome_id = "outcome_followup";
        _result.outcome_name_ru = "Пациент записан на повторный приём";
        _result.trust_delta = 4;
        _result.payout_mult = 0.90;
        _result.condition_after = _cond;
        _result.needs_followup = (_cond < 100);
        _result.followup_days = (_cond < 100) ? 1 : 0;
        _result.followup_reason = (_cond < 100) ? "Продолжение курса лечения" : "";
        return _result;
    }

    // Были действия, но диагноз ещё не подтверждён
    if (_diag_count > 0 || _treat_count > 0) {
        _result.outcome_id = "outcome_unresolved";
        _result.outcome_name_ru = "Пациент записан на повторный приём";
        _result.trust_delta = -1;
        _result.payout_mult = 0.65;
        _result.condition_after = _cond;
        _result.needs_followup = true;
        _result.followup_days = 1;
        _result.followup_reason = "Повторный визит для продолжения лечения";
        return _result;
    }

    return _result;
}