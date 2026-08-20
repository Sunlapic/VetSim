/// End Step par_visitors
/// @description Стояние, сидение в зоне ожидания и ходьба владельца.


// ═══════════════════════════════════════════════════════════════
// 1. ИНИЦИАЛИЗАЦИЯ ПОЗ
// ═══════════════════════════════════════════════════════════════

var _walk_sprite = sprite_index;
var _idle_sprite = spr_human_FR_idle;
var _sit_sprite = spr_human_FR_sit;

if (!variable_instance_exists(id, "_owner_sprite_cache")) {
    _owner_sprite_cache = _walk_sprite;
}

if (!variable_instance_exists(id, "_owner_sitting")) _owner_sitting = false;
if (!variable_instance_exists(id, "_sit_anim_timer")) _sit_anim_timer = 0;
if (!variable_instance_exists(id, "_idle_anim_timer")) _idle_anim_timer = 0;

var _move_x = x - xprevious;
var _move_y = y - yprevious;

var _owner_moving = (
    is_walking
    && (
        (path_index != -1 && path_position < 1)
        || abs(_move_x) > 0.5
        || abs(_move_y) > 0.5
    )
);

if (abs(_move_x) > 0.01) {
    pFacing = (_move_x > 0) ? 1 : -1;
}


// ═══════════════════════════════════════════════════════════════
// 2. ПОСАДКА В ЗОНЕ ОЖИДАНИЯ
// ═══════════════════════════════════════════════════════════════

if (
    state == "waiting"
    && wait_spot_index >= 0
    && wait_spot_index < array_length(global.wait_spots)
) {
    var _wait_x = global.wait_spots[wait_spot_index].x;
    var _wait_y = global.wait_spots[wait_spot_index].y;

    if (
        point_distance(x, y, _wait_x, _wait_y) <= 25
        && !is_walking
    ) {
        _owner_sitting = true;
        pFacing = 1;
        x = _wait_x;
        y = _wait_y;

        path_end();
        is_walking = false;
    }
}

if (state != "waiting") {
    _owner_sitting = false;
}


// ═══════════════════════════════════════════════════════════════
// 3. ФИНАЛЬНЫЙ ВЫБОР СПРАЙТА
// ═══════════════════════════════════════════════════════════════

if (_owner_sitting && sprite_exists(_sit_sprite)) {
    _sit_anim_timer += 1;

    var _sit_frames = max(1, sprite_get_number(_sit_sprite));

    sprite_index = _sit_sprite;
    image_index = floor(_sit_anim_timer / 12) mod _sit_frames;
    image_speed = 0;

    path_end();
    is_walking = false;
    depth = -y - 500;
    _idle_anim_timer = 0;
}
else if (!_owner_moving && sprite_exists(_idle_sprite)) {
    _idle_anim_timer += 1;

    var _idle_frames = max(1, sprite_get_number(_idle_sprite));

    sprite_index = _idle_sprite;
    image_index = floor(_idle_anim_timer / 10) mod _idle_frames;
    image_speed = 0;
    depth = -y;
    _sit_anim_timer = 0;
}
else if (_owner_moving) {
    sprite_index = _owner_sprite_cache;
    image_speed = 1;
    depth = -y;
    _sit_anim_timer = 0;
    _idle_anim_timer = 0;
}

image_xscale = abs(image_xscale) * pFacing;
