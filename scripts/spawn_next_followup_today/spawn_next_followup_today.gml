function spawn_next_followup_today() {
    var _now_minute = global.game_hour * 60 + global.game_minute;

    var _best_index = -1;
    var _best_minute = 999999;

    for (var i = 0; i < array_length(global.scheduled_visits); i++) {
        var _sv = global.scheduled_visits[i];

        if (_sv.status != "pending") continue;
        if (_sv.scheduled_day != global.game_day) continue;
        if (_sv.scheduled_minute > _now_minute) continue;

        if (_sv.scheduled_minute < _best_minute) {
            _best_minute = _sv.scheduled_minute;
            _best_index = i;
        }
    }

    if (_best_index == -1) return noone;

    var _pick = global.scheduled_visits[_best_index];
    var _spawned = spawn_owner_from_record(_pick.owner_id, _pick.pet_id, _pick);

    if (instance_exists(_spawned)) {
        global.scheduled_visits[_best_index].status = "spawned";
        return _spawned;
    }

    return noone;
}