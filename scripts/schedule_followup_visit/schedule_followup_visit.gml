function schedule_followup_visit(_owner_id, _pet_id, _case, _days_delay, _reason) {
    if (_owner_id == "" || _pet_id == "") return "";
    if (!is_struct(_case)) return "";

    // Не создаём дубликат активного повторного визита
    for (var i = 0; i < array_length(global.scheduled_visits); i++) {
        var _sv = global.scheduled_visits[i];

        if ((_sv.status == "pending" || _sv.status == "spawned")
        && _sv.owner_id == _owner_id
        && _sv.pet_id == _pet_id) {
            return _sv.scheduled_visit_id;
        }
    }

    var _target_day = global.game_day + _days_delay;
    var _same_day_count = 0;

    for (var j = 0; j < array_length(global.scheduled_visits); j++) {
        var _sv2 = global.scheduled_visits[j];

        if (_sv2.status != "pending") continue;
        if (_sv2.scheduled_day != _target_day) continue;

        _same_day_count += 1;
    }

    var _scheduled_minute = global.followup_morning_start + (_same_day_count * global.followup_spacing_minutes);

    if (_scheduled_minute >= global.clinic_day_end_minute) {
        _scheduled_minute = global.clinic_day_end_minute - 1;
    }

    if (_reason == "") {
        _reason = "Контрольный осмотр";
    }

    var _completed_diagnostics = variable_struct_exists(_case, "completed_diagnostics") ? _case.completed_diagnostics : [];
    var _treatment_progress = variable_struct_exists(_case, "treatment_progress") ? _case.treatment_progress : [];
    var _visible_symptoms = variable_struct_exists(_case, "visible_symptoms") ? _case.visible_symptoms : [];
    var _planned_treatment = variable_struct_exists(_case, "planned_treatment") ? _case.planned_treatment : [];

    var _scheduled = {
        scheduled_visit_id : db_next_scheduled_visit_id(),

        owner_id : _owner_id,
        pet_id : _pet_id,

        scheduled_day : _target_day,
        scheduled_minute : _scheduled_minute,
        reason : _reason,
        status : "pending",

        visit_type_id : "followup",
        visit_type_name_ru : "Повторный приём",

        case_id : variable_struct_exists(_case, "case_id") ? _case.case_id : "",
        disease_id : _case.hidden_disease_id,

        severity_level : variable_struct_exists(_case, "severity_level") ? _case.severity_level : 0,
        severity_name_ru : variable_struct_exists(_case, "severity_name_ru") ? _case.severity_name_ru : "",

        start_reveal_level : max(1, _case.reveal_level),
        confirmed : _case.confirmed,
        start_condition : clamp(_case.condition, 20, 100),

        completed_diagnostics : _completed_diagnostics,
        treatment_progress : _treatment_progress,
        visible_symptoms : _visible_symptoms,
        planned_treatment : _planned_treatment,

        case_status : variable_struct_exists(_case, "case_status") ? _case.case_status : "followup"
    };

    array_push(global.scheduled_visits, _scheduled);

    return _scheduled.scheduled_visit_id;
}