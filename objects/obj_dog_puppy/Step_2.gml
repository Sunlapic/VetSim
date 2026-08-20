// ─────────────────────────────────────────────
// End Step obj_dog_puppy ФИНАЛ БЕЗ ТЕЛЕПОРТОВ
// ─────────────────────────────────────────────

if (!variable_instance_exists(id, "puppy_pos_x")) {
    puppy_pos_x = x;
    puppy_pos_y = y;
    puppy_vel_x = 0;
    puppy_vel_y = 0;
    puppy_following = false;
    puppy_owner_dir = 270;
    puppy_side_sign = choose(-1, 1);
    puppy_face = 1;
    puppy_wobble = random(360);
    puppy_wobble_speed = random_range(3.5, 6.0);
    puppy_idle_phase = random(360);
    puppy_side_timer = irandom_range(room_speed * 3, room_speed * 6);
    puppy_follow_min_speed = 1.0;
    puppy_follow_max_speed = 4.8;
    puppy_follow_accel = 0.24;
    puppy_follow_drag = 0.72;
    puppy_follow_start_distance = 18;
    puppy_follow_stop_distance = 6;
    puppy_follow_teleport_distance = 260;
    puppy_follow_behind_distance = 42;
    puppy_follow_side_distance = 22;
    puppy_follow_anticipation = 4;
    puppy_personal_space = 24;
    puppy_idle_radius = 4;
}
if (!variable_instance_exists(self, "_breathe_timer")) _breathe_timer = 0;
if (!variable_instance_exists(self, "_sit_ready_timer")) _sit_ready_timer = 0;
if (!variable_instance_exists(self, "_sit_locked")) _sit_locked = false;
if (!variable_instance_exists(self, "_sit_locked_x")) _sit_locked_x = x;
if (!variable_instance_exists(self, "_sit_locked_y")) _sit_locked_y = y;
if (!variable_instance_exists(self, "_sit_locked_face")) _sit_locked_face = 1;

// ── Определяем состояния сидения
var _sit_on_table = (state == "in_exam");
var _owner_waiting = (state == "follow_owner" && instance_exists(my_owner) && my_owner.state == "waiting");
var _sit_on_floor = false;

// ── Владелец в очереди: ждём пока собака полностью остановится рядом, потом садим
if (_owner_waiting && !_sit_locked) begin
    var _target_sit_x = my_owner.x + (28 * puppy_face);
    var _target_sit_y = my_owner.y + 4;
    var _dist_to_sit = point_distance(x, y, _target_sit_x, _target_sit_y);

    if (_dist_to_sit <= 15 && abs(puppy_vel_x) < 0.2 && abs(puppy_vel_y) < 0.2) begin
        // Собака рядом и практически остановилась — ждём 1 секунду и садим
        _sit_ready_timer += 1;
        if (_sit_ready_timer >= room_speed * 1) begin
            // Фиксируем позицию и направление НАВСЕГДА пока не встанем
            _sit_locked = true;
            _sit_locked_x = _target_sit_x;
            _sit_locked_y = _target_sit_y;
            _sit_locked_face = puppy_face;
            puppy_vel_x = 0;
            puppy_vel_y = 0;
            puppy_following = false;
            path_end();
            is_walking = false;
        end
    end else begin
        _sit_ready_timer = 0;
    end
end else if (!_owner_waiting) begin
    // Владелец пошёл — сбрасываем готовность к посадке
    _sit_ready_timer = 0;
    _sit_locked = false;
end

_sit_on_floor = _sit_locked;

// ── На столе — фиксируем позицию когда запрыгнули
if (_sit_on_table && !_sit_locked) begin
    if (point_distance(x, y, exam_table_x, exam_table_y) <= 4) begin
        _sit_locked = true;
        _sit_locked_x = exam_table_x;
        _sit_locked_y = exam_table_y - 8;
        _sit_locked_face = 1;
    end
end else if (!_sit_on_table && !_owner_waiting) begin
    _sit_locked = false;
end

// ── Если сидеть заблокировано — просто стоим на месте, никакой физики
if (_sit_locked) begin
    x = _sit_locked_x;
    y = _sit_locked_y;
    puppy_pos_x = x;
    puppy_pos_y = y;
    puppy_vel_x = 0;
    puppy_vel_y = 0;
    puppy_following = false;
    is_walking = false;
end
// ── Иначе работает обычная логика следования
else if (state == "follow_owner" && instance_exists(my_owner)) {
    var _owner_dx = my_owner.x - my_owner.xprevious;
    var _owner_dy = my_owner.y - my_owner.yprevious;
    var _owner_moving = (point_distance(0, 0, _owner_dx, _owner_dy) > 0.05);
    if (_owner_moving) puppy_owner_dir = point_direction(0, 0, _owner_dx, _owner_dy);

    puppy_side_timer -= 1;
    if (puppy_side_timer <= 0) {
        if (!_owner_moving || point_distance(puppy_pos_x, puppy_pos_y, my_owner.x, my_owner.y) > 52)
            puppy_side_sign = choose(-1, 1);
        puppy_side_timer = irandom_range(room_speed * 3, room_speed * 6);
    }

    puppy_wobble += puppy_wobble_speed;
    if (puppy_wobble >= 360) puppy_wobble -= 360;
    puppy_idle_phase += _owner_moving ? 0.8 : 1.6;
    if (puppy_idle_phase >= 360) puppy_idle_phase -= 360;

    var _side_wave = dsin(puppy_wobble) * 4;
    var _back_wave = dcos(puppy_wobble * 0.7) * 2;
    var _target_x = my_owner.x + lengthdir_x(puppy_follow_behind_distance + _back_wave, puppy_owner_dir + 180);
    var _target_y = my_owner.y + lengthdir_y(puppy_follow_behind_distance + _back_wave, puppy_owner_dir + 180);
    _target_x += lengthdir_x((puppy_follow_side_distance * puppy_side_sign) + _side_wave, puppy_owner_dir + 90);
    _target_y += lengthdir_y((puppy_follow_side_distance * puppy_side_sign) + _side_wave, puppy_owner_dir + 90);

    if (_owner_moving) {
        _target_x += _owner_dx * puppy_follow_anticipation;
        _target_y += _owner_dy * puppy_follow_anticipation;
    }

    var _dist_to_owner = point_distance(_target_x, _target_y, my_owner.x, my_owner.y);
    if (_dist_to_owner < puppy_personal_space) {
        var _push = (_dist_to_owner <= 0.01) ? puppy_owner_dir + 180 : point_direction(my_owner.x, my_owner.y, _target_x, _target_y);
        _target_x = my_owner.x + lengthdir_x(puppy_personal_space, _push);
        _target_y = my_owner.y + lengthdir_y(puppy_personal_space, _push);
    }

    var _dist = point_distance(puppy_pos_x, puppy_pos_y, _target_x, _target_y);
    if (_dist > puppy_follow_teleport_distance) {
        puppy_pos_x = _target_x; puppy_pos_y = _target_y;
        puppy_vel_x = 0; puppy_vel_y = 0; puppy_following = false;
    } else {
        if (!puppy_following && _dist > puppy_follow_start_distance) puppy_following = true;
        if (puppy_following && _dist <= puppy_follow_stop_distance) puppy_following = false;
        var _speed = puppy_following ? min(puppy_follow_max_speed, puppy_follow_min_speed + (_dist * 0.11)) : 0;
        if (!_owner_moving) _speed *= 0.7;
        if (_dist < 24) _speed *= 0.82;
        var _dir = point_direction(puppy_pos_x, puppy_pos_y, _target_x, _target_y);
        var _accel = _owner_moving ? puppy_follow_accel : puppy_follow_accel * 0.75;
        puppy_vel_x = lerp(puppy_vel_x, lengthdir_x(_speed, _dir), _accel);
        puppy_vel_y = lerp(puppy_vel_y, lengthdir_y(_speed, _dir), _accel);
        if (!puppy_following) { puppy_vel_x *= puppy_follow_drag; puppy_vel_y *= puppy_follow_drag; }
        if (abs(puppy_vel_x) < 0.01) puppy_vel_x = 0;
        if (abs(puppy_vel_y) < 0.01) puppy_vel_y = 0;
        puppy_pos_x += puppy_vel_x;
        puppy_pos_y += puppy_vel_y;
    }
    x = puppy_pos_x; y = puppy_pos_y;
} else if (!_sit_locked) {
    puppy_pos_x = x; puppy_pos_y = y;
    puppy_vel_x = 0; puppy_vel_y = 0; puppy_following = false;
}

// ── Анимация и поворот
var _dx = x - xprevious;
var _dy = y - yprevious;
var _base_scale = abs(image_xscale);
var _is_moving = false;

if (!_sit_on_floor && !_sit_on_table) begin
    if (_dx > 0.01) puppy_face = 1;
    if (_dx < -0.01) puppy_face = -1;
    _is_moving = (abs(_dx) > 0.01 || abs(_dy) > 0.01 || puppy_following);
end

if (_sit_on_table) begin
    sprite_index = spr_pappy_FR_sit;
    _breathe_timer += 1;
    image_index = floor(_breathe_timer / 7) mod sprite_get_number(spr_pappy_FR_sit);
    image_speed = 0;
    puppy_face = 1;
end else if (_sit_on_floor) begin
    sprite_index = spr_pappy_B_sit;
    _breathe_timer += 1;
    image_index = floor(_breathe_timer / 7) mod sprite_get_number(spr_pappy_B_sit);
    image_speed = 0;
    puppy_face = _sit_locked_face;
end else if (_is_moving) begin
    _breathe_timer = 0;
    image_speed = 1;
    sprite_index = (abs(_dy) > abs(_dx) && _dy < 0) ? spr_pappy_B_walk : spr_pappy_FR_walk;
end else begin
    _breathe_timer = 0;
    image_speed = 0;
    image_index = 0;
    sprite_index = spr_pappy_FR_walk;
end

image_xscale = _base_scale * puppy_face;
depth = ((state == "jumping_to_table" || state == "in_exam") && instance_exists(assigned_table)) ? assigned_table.depth - 1000 : -y;