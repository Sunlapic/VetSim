function doctor_recalc_therapy_progress(_actor) {
    if (!instance_exists(_actor)) return;

    if (!variable_instance_exists(_actor, "therapy_xp")) {
        _actor.therapy_xp = 0;
    }

    _actor.therapy_xp = max(0, floor(_actor.therapy_xp));
    _actor.therapy_level = doctor_therapy_level_from_xp(_actor.therapy_xp);

    var _spent = 0;
    for (var _lvl = 1; _lvl < _actor.therapy_level; _lvl++) {
        _spent += doctor_therapy_xp_needed(_lvl);
    }

    _actor.therapy_xp_into_level = _actor.therapy_xp - _spent;
    _actor.therapy_xp_next_level = (_actor.therapy_level < 10) ? doctor_therapy_xp_needed(_actor.therapy_level) : 0;
    _actor.therapy_error_chance = doctor_get_therapy_error_chance(_actor.therapy_level);
    _actor.therapy_exam_duration_frames = doctor_get_exam_duration_frames(_actor.therapy_level);
}