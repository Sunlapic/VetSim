function doctor_therapy_level_from_xp(_xp) {
    _xp = max(0, floor(_xp));

    var _level = 1;
    var _rest = _xp;

    while (_level < 10) {
        var _need = doctor_therapy_xp_needed(_level);

        if (_rest >= _need) {
            _rest -= _need;
            _level += 1;
        } else {
            break;
        }
    }

    return _level;
}