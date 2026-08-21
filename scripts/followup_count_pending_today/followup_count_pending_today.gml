function followup_count_pending_today() {

    var _count = 0;

    for (var i = 0; i < array_length(global.scheduled_visits); i++) {
        var _sv = global.scheduled_visits[i];

        if (_sv.status != "pending") continue;
        if (_sv.scheduled_day != global.game_day) continue;

        _count += 1;
    }

    return _count;
}