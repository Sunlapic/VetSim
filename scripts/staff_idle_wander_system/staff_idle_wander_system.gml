/// staff_idle_wander_system.gml
/// @description Свободное гуляние ассистентов внутри прямоугольников появления грязи.


// ═══════════════════════════════════════════════════════════════
// 1. ПРЯМОУГОЛЬНИКИ КЛИНИКИ
// ═══════════════════════════════════════════════════════════════

function staff_idle_add_zone_pair(
    _zones,
    _start_object,
    _end_object,
    _margin = 30
) {
    if (!instance_exists(_start_object)) return _zones;
    if (!instance_exists(_end_object)) return _zones;

    var _start = instance_find(_start_object, 0);
    var _end = instance_find(_end_object, 0);
    var _x1 = min(_start.x, _end.x) + _margin;
    var _y1 = min(_start.y, _end.y) + _margin;
    var _x2 = max(_start.x, _end.x) - _margin;
    var _y2 = max(_start.y, _end.y) - _margin;

    if (_x2 - _x1 < 32 || _y2 - _y1 < 32) {
        return _zones;
    }

    array_push(_zones, {
        x1 : _x1,
        y1 : _y1,
        x2 : _x2,
        y2 : _y2,
        area : (_x2 - _x1) * (_y2 - _y1)
    });

    return _zones;
}

function staff_idle_get_clinic_zones() {
    var _zones = [];

    _zones = staff_idle_add_zone_pair(
        _zones,
        obj_cleanliness_area_start,
        obj_cleanliness_area_end,
        30
    );

    _zones = staff_idle_add_zone_pair(
        _zones,
        obj_cleanliness_area_start_2,
        obj_cleanliness_area_end_2,
        30
    );

    return _zones;
}

function staff_idle_pick_zone_by_area(_zones) {
    if (!is_array(_zones)) return -1;
    if (array_length(_zones) <= 0) return -1;

    var _total_area = 0;

    for (var _index = 0; _index < array_length(_zones); _index++) {
        _total_area += max(1, _zones[_index].area);
    }

    var _roll = random(_total_area);
    var _sum = 0;

    for (var _zone_index = 0; _zone_index < array_length(_zones); _zone_index++) {
        _sum += max(1, _zones[_zone_index].area);

        if (_roll <= _sum) return _zone_index;
    }

    return array_length(_zones) - 1;
}


// ═══════════════════════════════════════════════════════════════
// 2. РАЗДЕЛЕНИЕ АССИСТЕНТОВ
// ═══════════════════════════════════════════════════════════════

function staff_idle_point_is_spread(
    _staff,
    _target_x,
    _target_y,
    _minimum_distance = 72
) {
    for (
        var _index = 0;
        _index < instance_number(obj_staff_assistant);
        _index++
    ) {
        var _other_staff = instance_find(obj_staff_assistant, _index);

        if (!instance_exists(_other_staff)) continue;
        if (_other_staff == _staff) continue;

        var _other_x = _other_staff.x;
        var _other_y = _other_staff.y;

        if (
            variable_instance_exists(_other_staff, "idle_wander_target_valid")
            && _other_staff.idle_wander_target_valid
        ) {
            _other_x = _other_staff.idle_wander_target_x;
            _other_y = _other_staff.idle_wander_target_y;
        }
        else if (
            variable_instance_exists(_other_staff, "idle_zone_home_ready")
            && _other_staff.idle_zone_home_ready
        ) {
            _other_x = _other_staff.home_x;
            _other_y = _other_staff.home_y;
        }

        if (
            point_distance(
                _target_x,
                _target_y,
                _other_x,
                _other_y
            ) < _minimum_distance
        ) {
            return false;
        }
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. ВЫБОР БЕЗОПАСНОЙ ТОЧКИ
// ═══════════════════════════════════════════════════════════════

function staff_idle_pick_indoor_point(_staff) {
    var _zones = staff_idle_get_clinic_zones();

    if (array_length(_zones) <= 0) {
        return { ok : false, x : _staff.x, y : _staff.y };
    }

    // Сначала ищем просторную точку, затем разрешаем более близкую,
    // если клиника маленькая и ассистентов много.
    for (var _pass = 0; _pass < 2; _pass++) {
        var _minimum_distance = (_pass == 0) ? 72 : 36;

        for (var _attempt = 0; _attempt < 28; _attempt++) {
            var _zone_index = staff_idle_pick_zone_by_area(_zones);
            if (_zone_index < 0) break;

            var _zone = _zones[_zone_index];
            var _target_x = random_range(_zone.x1, _zone.x2);
            var _target_y = random_range(_zone.y1, _zone.y2);

            if (!cleanliness_position_inside_clinic(_target_x, _target_y)) {
                continue;
            }

            if (!cleanliness_position_is_valid_floor(_target_x, _target_y)) {
                continue;
            }

            if (!staff_idle_point_is_spread(
                _staff,
                _target_x,
                _target_y,
                _minimum_distance
            )) {
                continue;
            }

            return {
                ok : true,
                x : _target_x,
                y : _target_y
            };
        }
    }

    return { ok : false, x : _staff.x, y : _staff.y };
}

function staff_idle_assign_indoor_home(_staff) {
    if (!instance_exists(_staff)) return false;

    var _point = staff_idle_pick_indoor_point(_staff);

    if (!_point.ok) return false;

    _staff.home_x = _point.x;
    _staff.home_y = _point.y;
    _staff.idle_zone_home_ready = true;
    return true;
}

function staff_idle_home_is_valid(_staff) {
    if (!instance_exists(_staff)) return false;
    if (!variable_instance_exists(_staff, "home_x")) return false;
    if (!variable_instance_exists(_staff, "home_y")) return false;

    return cleanliness_position_inside_clinic(
        _staff.home_x,
        _staff.home_y
    ) && cleanliness_position_is_valid_floor(
        _staff.home_x,
        _staff.home_y
    );
}


// ═══════════════════════════════════════════════════════════════
// 4. ЗАПУСК СЛУЧАЙНОГО МАРШРУТА
// ═══════════════════════════════════════════════════════════════

function staff_idle_start_indoor_wander(_staff) {
    if (!instance_exists(_staff)) return false;
    if (!variable_instance_exists(_staff, "my_path")) return false;
    if (!path_exists(_staff.my_path)) return false;

    for (var _attempt = 0; _attempt < 6; _attempt++) {
        var _point = staff_idle_pick_indoor_point(_staff);
        if (!_point.ok) continue;

        var _path_built = mp_grid_path(
            global.ai_grid,
            _staff.my_path,
            _staff.x,
            _staff.y,
            _point.x,
            _point.y,
            true
        );

        if (!_path_built) continue;

        _staff.idle_wander_target_x = _point.x;
        _staff.idle_wander_target_y = _point.y;
        _staff.idle_wander_target_valid = true;

        with (_staff) {
            path_set_kind(my_path, 1);
            path_start(
                my_path,
                p_move_speed,
                path_action_stop,
                true
            );
            is_walking = true;
            wander_walking = true;
            image_speed = 1;
        }

        return true;
    }

    _staff.idle_wander_target_valid = false;
    return false;
}
