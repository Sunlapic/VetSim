function reception_find_free_wait_spot() {
    if (!variable_global_exists("wait_spots")) return -1;

    for (var i = 0; i < array_length(global.wait_spots); i++) {
        var _occ = global.wait_spots[i].occupied_by;

        if (!instance_exists(_occ)) {
            global.wait_spots[i].occupied_by = noone;
            return i;
        }
    }

    return -1;
}