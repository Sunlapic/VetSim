function doctor_get_therapy_error_chance(_level) {
    _level = clamp(round(_level), 1, 10);

    switch (_level) {
        case 1:  return 0.45;
        case 2:  return 0.38;
        case 3:  return 0.32;
        case 4:  return 0.26;
        case 5:  return 0.20;
        case 6:  return 0.15;
        case 7:  return 0.10;
        case 8:  return 0.06;
        case 9:  return 0.03;
        case 10: return 0.00;
    }

    return 0.45;
}