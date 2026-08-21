function active_visitors_live_count() {

    var _count = 0;

    for (var i = array_length(global.active_visitors) - 1; i >= 0; i--) {
        var _inst = global.active_visitors[i];

        if (!instance_exists(_inst)) {
            array_delete(global.active_visitors, i, 1);
        } else {
            _count += 1;
        }
    }

    return _count;
}