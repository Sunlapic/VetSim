function doctor_therapy_xp_needed(_current_level) {
    _current_level = clamp(round(_current_level), 1, 10);

    if (_current_level >= 10) return 0;

    return 30 + ((_current_level - 1) * 20);
}