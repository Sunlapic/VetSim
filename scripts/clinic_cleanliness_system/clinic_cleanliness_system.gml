/// clinic_cleanliness_system.gml
/// @description Процедурная грязь, трафик, уборка игроком и интерфейс чистоты.
/// Пакет №120: меню «ПОЧИСТИТЬ» на матовом стекле.


// ═══════════════════════════════════════════════════════════════
// 1. ГЕОМЕТРИЯ ПРОЦЕДУРНЫХ ПЯТЕН
// ═══════════════════════════════════════════════════════════════

function dirt_rotate_x(_x, _y, _angle) {
    return _x * dcos(_angle) - _y * dsin(_angle);
}

function dirt_rotate_y(_x, _y, _angle) {
    return _x * dsin(_angle) + _y * dcos(_angle);
}

function dirt_draw_rotated_ellipse(
    _x,
    _y,
    _rx,
    _ry,
    _angle,
    _color,
    _alpha,
    _segments = 20
) {
    var _count = max(8, round(_segments));

    draw_primitive_begin(pr_trianglefan);
    draw_vertex_color(_x, _y, _color, _alpha);

    for (var _index = 0; _index <= _count; _index++) {
        var _phase = (_index / _count) * 360;
        var _local_x = dcos(_phase) * _rx;
        var _local_y = dsin(_phase) * _ry;
        var _world_x = _x + dirt_rotate_x(_local_x, _local_y, _angle);
        var _world_y = _y + dirt_rotate_y(_local_x, _local_y, _angle);

        draw_vertex_color(
            _world_x,
            _world_y,
            _color,
            _alpha
        );
    }

    draw_primitive_end();
}

function dirt_draw_rotated_ellipse_outline(
    _x,
    _y,
    _rx,
    _ry,
    _angle,
    _color,
    _alpha,
    _segments = 24
) {
    var _count = max(8, round(_segments));

    draw_primitive_begin(pr_linestrip);

    for (var _index = 0; _index <= _count; _index++) {
        var _phase = (_index / _count) * 360;
        var _local_x = dcos(_phase) * _rx;
        var _local_y = dsin(_phase) * _ry;

        draw_vertex_color(
            _x + dirt_rotate_x(_local_x, _local_y, _angle),
            _y + dirt_rotate_y(_local_x, _local_y, _angle),
            _color,
            _alpha
        );
    }

    draw_primitive_end();
}

function dirt_draw_tread_bar(
    _x,
    _y,
    _length,
    _width,
    _angle,
    _color,
    _alpha
) {
    var _half_l = _length * 0.5;
    var _half_w = _width * 0.5;
    var _points = [
        [-_half_l, -_half_w],
        [ _half_l, -_half_w],
        [ _half_l,  _half_w],
        [-_half_l,  _half_w]
    ];

    draw_primitive_begin(pr_trianglefan);
    draw_vertex_color(_x, _y, _color, _alpha);

    for (var _index = 0; _index <= 4; _index++) {
        var _point = _points[_index mod 4];
        var _px = _x + dirt_rotate_x(_point[0], _point[1], _angle);
        var _py = _y + dirt_rotate_y(_point[0], _point[1], _angle);

        draw_vertex_color(_px, _py, _color, _alpha);
    }

    draw_primitive_end();
}


// ═══════════════════════════════════════════════════════════════
// 2. ГЕНЕРАЦИЯ УНИКАЛЬНОГО ВИДА ПЯТНА
// Данные создаются один раз и не мерцают между кадрами.
// ═══════════════════════════════════════════════════════════════

function dirt_generate_visual(_dirt) {
    if (!instance_exists(_dirt)) return false;

    with (_dirt) {
        dirt_variant = irandom_range(0, 4);
        dirt_rotation = random(360);
        dirt_scale = random_range(0.78, 1.28);
        dirt_value = irandom_range(2, 5);
        hit_radius = 30 * dirt_scale;

        visual_blobs = [];
        visual_specks = [];
        visual_prints = [];
        visual_streaks = [];

        var _base_brown = choose(
            make_color_rgb(92, 67, 45),
            make_color_rgb(112, 82, 55),
            make_color_rgb(74, 64, 52),
            make_color_rgb(128, 101, 70)
        );
        var _dark_brown = merge_color(_base_brown, c_black, 0.38);
        var _light_brown = merge_color(_base_brown, make_color_rgb(195, 168, 125), 0.32);

        dirt_color_base = _base_brown;
        dirt_color_dark = _dark_brown;
        dirt_color_light = _light_brown;

        // Варианты 0–2: многослойная грязь, брызги и растёртые пятна.
        if (dirt_variant <= 2) {
            var _blob_count = irandom_range(6, 12);

            for (var _blob_index = 0; _blob_index < _blob_count; _blob_index++) {
                var _distance = random_range(0, 18) * dirt_scale;
                var _direction = random(360);
                var _large = (_blob_index < 3);

                array_push(visual_blobs, {
                    ox : lengthdir_x(_distance, _direction),
                    oy : lengthdir_y(_distance * 0.55, _direction),
                    rx : (_large ? random_range(10, 22) : random_range(4, 12)) * dirt_scale,
                    ry : (_large ? random_range(5, 12) : random_range(2, 7)) * dirt_scale,
                    angle : dirt_rotation + random_range(-40, 40),
                    alpha : _large ? random_range(0.18, 0.30) : random_range(0.12, 0.23),
                    shade : irandom_range(0, 2)
                });
            }

            var _speck_count = irandom_range(9, 22);

            for (var _speck_index = 0; _speck_index < _speck_count; _speck_index++) {
                var _speck_distance = random_range(14, 38) * dirt_scale;
                var _speck_direction = random(360);

                array_push(visual_specks, {
                    ox : lengthdir_x(_speck_distance, _speck_direction),
                    oy : lengthdir_y(_speck_distance * 0.65, _speck_direction),
                    radius : random_range(0.7, 2.8) * dirt_scale,
                    alpha : random_range(0.15, 0.36),
                    shade : irandom_range(0, 2)
                });
            }
        }

        // Варианты 2–3: следы подошв, иногда поверх размазанной грязи.
        if (dirt_variant == 2 || dirt_variant == 3) {
            var _print_count = irandom_range(2, 5);
            var _step_angle = dirt_rotation + random_range(-18, 18);
            var _side = choose(-1, 1);

            for (var _print_index = 0; _print_index < _print_count; _print_index++) {
                var _forward = (_print_index - (_print_count - 1) * 0.5) * 19 * dirt_scale;
                var _lateral = ((_print_index mod 2 == 0) ? -1 : 1) * 7 * dirt_scale * _side;
                var _ox = lengthdir_x(_forward, _step_angle)
                    + lengthdir_x(_lateral, _step_angle + 90);
                var _oy = lengthdir_y(_forward, _step_angle) * 0.70
                    + lengthdir_y(_lateral, _step_angle + 90) * 0.70;

                array_push(visual_prints, {
                    ox : _ox,
                    oy : _oy,
                    angle : _step_angle + ((_print_index mod 2 == 0) ? -5 : 5),
                    length : random_range(17, 23) * dirt_scale,
                    width : random_range(7, 10) * dirt_scale,
                    alpha : random_range(0.22, 0.38),
                    broken : random(1) < 0.38
                });
            }

            hit_radius = max(hit_radius, (_print_count * 12 + 18) * dirt_scale);
        }

        // Вариант 4: длинные неоднородные потёртости от обуви/тележки.
        if (dirt_variant == 4) {
            var _streak_count = irandom_range(3, 7);

            for (var _streak_index = 0; _streak_index < _streak_count; _streak_index++) {
                array_push(visual_streaks, {
                    ox : random_range(-16, 16) * dirt_scale,
                    oy : random_range(-9, 9) * dirt_scale,
                    length : random_range(22, 48) * dirt_scale,
                    width : random_range(2, 6) * dirt_scale,
                    angle : dirt_rotation + random_range(-14, 14),
                    alpha : random_range(0.10, 0.25)
                });
            }

            var _dust_count = irandom_range(8, 15);

            for (var _dust_index = 0; _dust_index < _dust_count; _dust_index++) {
                array_push(visual_specks, {
                    ox : random_range(-30, 30) * dirt_scale,
                    oy : random_range(-16, 16) * dirt_scale,
                    radius : random_range(0.8, 2.2) * dirt_scale,
                    alpha : random_range(0.08, 0.20),
                    shade : irandom_range(0, 2)
                });
            }

            hit_radius = 42 * dirt_scale;
        }

        visual_ready = true;
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. ОТРИСОВКА СЛЕДА ОБУВИ
// ═══════════════════════════════════════════════════════════════

function dirt_draw_boot_print(_dirt, _print, _highlight) {
    var _x = _dirt.x + _print.ox;
    var _y = _dirt.y + _print.oy;
    var _angle = _print.angle;
    var _length = _print.length;
    var _width = _print.width;
    var _color = _highlight ? c_lime : _dirt.dirt_color_dark;
    var _alpha = _highlight ? 0.20 : _print.alpha;
    var _halo = _highlight ? 2.4 : 0;

    // Носок подошвы.
    var _toe_x = _x + lengthdir_x(_length * 0.28, _angle);
    var _toe_y = _y + lengthdir_y(_length * 0.28, _angle) * 0.72;

    dirt_draw_rotated_ellipse(
        _toe_x,
        _toe_y,
        _width * 0.72 + _halo,
        _length * 0.20 + _halo,
        _angle + 90,
        _color,
        _alpha,
        16
    );

    // Пятка.
    var _heel_x = _x + lengthdir_x(-_length * 0.29, _angle);
    var _heel_y = _y + lengthdir_y(-_length * 0.29, _angle) * 0.72;

    dirt_draw_rotated_ellipse(
        _heel_x,
        _heel_y,
        _width * 0.52 + _halo,
        _length * 0.14 + _halo,
        _angle + 90,
        _color,
        _alpha * 0.95,
        14
    );

    if (!_print.broken || _highlight) {
        // Средняя часть подошвы.
        dirt_draw_rotated_ellipse(
            _x,
            _y,
            _width * 0.40 + _halo,
            _length * 0.20 + _halo,
            _angle + 90,
            _color,
            _alpha * 0.72,
            14
        );
    }

    if (!_highlight) {
        // Тёмные поперечные элементы протектора.
        for (var _bar_index = -2; _bar_index <= 2; _bar_index++) {
            if (_print.broken && (_bar_index == 0 || _bar_index == 1)) continue;

            var _bar_forward = _bar_index * _length * 0.105;
            var _bar_x = _x + lengthdir_x(_bar_forward, _angle);
            var _bar_y = _y + lengthdir_y(_bar_forward, _angle) * 0.72;

            dirt_draw_tread_bar(
                _bar_x,
                _bar_y,
                _width * 0.78,
                max(0.9, _length * 0.035),
                _angle + 90,
                _dirt.dirt_color_dark,
                _alpha * 0.58
            );
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 4. ПОЛНАЯ ОТРИСОВКА ПЯТНА
// ═══════════════════════════════════════════════════════════════

function dirt_draw_instance(_dirt) {
    if (!instance_exists(_dirt)) return;
    if (!_dirt.visual_ready) dirt_generate_visual(_dirt);

    var _highlight = _dirt.is_hovered;

    // Зелёный ореол повторяет не круг, а фактические элементы пятна.
    if (_highlight) {
        draw_set_alpha(1);

        for (var _hb = 0; _hb < array_length(_dirt.visual_blobs); _hb++) {
            var _blob_h = _dirt.visual_blobs[_hb];

            dirt_draw_rotated_ellipse(
                _dirt.x + _blob_h.ox,
                _dirt.y + _blob_h.oy,
                _blob_h.rx + 3.5,
                _blob_h.ry + 3.5,
                _blob_h.angle,
                c_lime,
                0.16,
                20
            );
        }

        for (var _hp = 0; _hp < array_length(_dirt.visual_prints); _hp++) {
            dirt_draw_boot_print(
                _dirt,
                _dirt.visual_prints[_hp],
                true
            );
        }

        for (var _hs = 0; _hs < array_length(_dirt.visual_streaks); _hs++) {
            var _streak_h = _dirt.visual_streaks[_hs];
            var _streak_hx = _dirt.x + _streak_h.ox;
            var _streak_hy = _dirt.y + _streak_h.oy;

            dirt_draw_rotated_ellipse(
                _streak_hx,
                _streak_hy,
                _streak_h.length * 0.5 + 3,
                _streak_h.width + 3,
                _streak_h.angle,
                c_lime,
                0.13,
                20
            );
        }
    }

    // Мягкий нижний слой въевшейся грязи.
    for (var _blob_index = 0; _blob_index < array_length(_dirt.visual_blobs); _blob_index++) {
        var _blob = _dirt.visual_blobs[_blob_index];
        var _blob_color = _dirt.dirt_color_base;

        if (_blob.shade == 0) _blob_color = _dirt.dirt_color_dark;
        if (_blob.shade == 2) _blob_color = _dirt.dirt_color_light;

        dirt_draw_rotated_ellipse(
            _dirt.x + _blob.ox,
            _dirt.y + _blob.oy,
            _blob.rx * 1.16,
            _blob.ry * 1.16,
            _blob.angle,
            _blob_color,
            _blob.alpha * 0.28,
            20
        );

        dirt_draw_rotated_ellipse(
            _dirt.x + _blob.ox,
            _dirt.y + _blob.oy,
            _blob.rx,
            _blob.ry,
            _blob.angle,
            _blob_color,
            _blob.alpha,
            20
        );

        // Неровный более тёмный центр.
        dirt_draw_rotated_ellipse(
            _dirt.x + _blob.ox - _blob.rx * 0.12,
            _dirt.y + _blob.oy + _blob.ry * 0.08,
            _blob.rx * 0.58,
            _blob.ry * 0.54,
            _blob.angle + 7,
            _dirt.dirt_color_dark,
            _blob.alpha * 0.24,
            16
        );
    }

    // Потёртости рисуются несколькими смещёнными слоями.
    for (var _streak_index = 0; _streak_index < array_length(_dirt.visual_streaks); _streak_index++) {
        var _streak = _dirt.visual_streaks[_streak_index];
        var _sx = _dirt.x + _streak.ox;
        var _sy = _dirt.y + _streak.oy;

        dirt_draw_rotated_ellipse(
            _sx,
            _sy,
            _streak.length * 0.5,
            _streak.width,
            _streak.angle,
            _dirt.dirt_color_base,
            _streak.alpha,
            24
        );

        dirt_draw_rotated_ellipse(
            _sx + lengthdir_x(2, _streak.angle + 90),
            _sy + lengthdir_y(2, _streak.angle + 90),
            _streak.length * 0.42,
            max(0.8, _streak.width * 0.38),
            _streak.angle,
            _dirt.dirt_color_light,
            _streak.alpha * 0.45,
            20
        );
    }

    // Следы обуви.
    for (var _print_index = 0; _print_index < array_length(_dirt.visual_prints); _print_index++) {
        dirt_draw_boot_print(
            _dirt,
            _dirt.visual_prints[_print_index],
            false
        );
    }

    // Мелкие капли и песчинки.
    for (var _speck_index = 0; _speck_index < array_length(_dirt.visual_specks); _speck_index++) {
        var _speck = _dirt.visual_specks[_speck_index];
        var _speck_color = _dirt.dirt_color_base;

        if (_speck.shade == 0) _speck_color = _dirt.dirt_color_dark;
        if (_speck.shade == 2) _speck_color = _dirt.dirt_color_light;

        draw_set_alpha(_speck.alpha);
        draw_set_color(_speck_color);
        draw_circle(
            _dirt.x + _speck.ox,
            _dirt.y + _speck.oy,
            _speck.radius,
            false
        );
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
    gpu_set_blendmode(bm_normal);
}


// ═══════════════════════════════════════════════════════════════
// 5. ТРАФИК И ПОЯВЛЕНИЕ ГРЯЗИ
// ═══════════════════════════════════════════════════════════════

function cleanliness_add_traffic(_controller, _x, _y, _angle, _weight) {
    if (!instance_exists(_controller)) return;
    if (!ds_exists(_controller.traffic_map, ds_type_map)) return;

    var _cell_size = _controller.traffic_cell_size;
    var _cell_x = floor(_x / _cell_size);
    var _cell_y = floor(_y / _cell_size);
    var _key = string(_cell_x) + "|" + string(_cell_y);
    var _cell = undefined;

    if (ds_map_exists(_controller.traffic_map, _key)) {
        _cell = _controller.traffic_map[? _key];
    } else {
        _cell = {
            x : _cell_x * _cell_size + _cell_size * 0.5,
            y : _cell_y * _cell_size + _cell_size * 0.5,
            score : 0,
            angle : _angle
        };
    }

    _cell.score = min(1000, _cell.score + max(0.1, _weight));
    _cell.angle = lerp(_cell.angle, _angle, 0.18);

    // Храним не только центр клетки, но и среднюю фактическую линию прохода.
    // Это не даёт случайному смещению увести пятно под соседнюю стену.
    _cell.x = lerp(_cell.x, _x, 0.28);
    _cell.y = lerp(_cell.y, _y, 0.28);

    _controller.traffic_map[? _key] = _cell;
}

function cleanliness_sample_object_type(_controller, _object_type, _weight) {
    if (!instance_exists(_controller)) return;
    if (!ds_exists(_controller.actor_position_map, ds_type_map)) return;

    var _count = instance_number(_object_type);

    for (var _index = 0; _index < _count; _index++) {
        var _actor = instance_find(_object_type, _index);

        if (!instance_exists(_actor)) continue;
        if (variable_instance_exists(_actor, "is_candidate") && _actor.is_candidate) continue;
        if (variable_instance_exists(_actor, "visible") && !_actor.visible) continue;

        // xprevious/yprevious в некоторых событиях уже совпадают с x/y.
        // Поэтому используем собственную сохранённую позицию каждого instance.
        var _actor_key = string(_actor.id);

        if (!ds_map_exists(_controller.actor_position_map, _actor_key)) {
            _controller.actor_position_map[? _actor_key] = {
                x : _actor.x,
                y : _actor.y
            };
            continue;
        }

        var _last_position = _controller.actor_position_map[? _actor_key];
        var _dx = _actor.x - _last_position.x;
        var _dy = _actor.y - _last_position.y;
        var _distance = point_distance(0, 0, _dx, _dy);

        _last_position.x = _actor.x;
        _last_position.y = _actor.y;
        _controller.actor_position_map[? _actor_key] = _last_position;

        if (_distance <= 0.10) continue;

        cleanliness_add_traffic(
            _controller,
            _actor.x,
            _actor.y,
            point_direction(0, 0, _dx, _dy),
            _weight * clamp(_distance, 0.5, 8)
        );
    }
}

function cleanliness_point_in_marker_pair(
    _start_object,
    _end_object,
    _x,
    _y
) {
    if (!instance_exists(_start_object) || !instance_exists(_end_object)) {
        return false;
    }

    var _start = instance_find(_start_object, 0);
    var _end = instance_find(_end_object, 0);
    var _margin = 12;
    var _x1 = min(_start.x, _end.x) + _margin;
    var _y1 = min(_start.y, _end.y) + _margin;
    var _x2 = max(_start.x, _end.x) - _margin;
    var _y2 = max(_start.y, _end.y) - _margin;

    return point_in_rectangle(_x, _y, _x1, _y1, _x2, _y2);
}

function cleanliness_has_any_area() {
    var _zone_1_ready = (
        instance_exists(obj_cleanliness_area_start)
        && instance_exists(obj_cleanliness_area_end)
    );
    var _zone_2_ready = (
        instance_exists(obj_cleanliness_area_start_2)
        && instance_exists(obj_cleanliness_area_end_2)
    );

    return _zone_1_ready || _zone_2_ready;
}

function cleanliness_position_inside_clinic(_x, _y) {
    if (!cleanliness_has_any_area()) {
        // Без маркеров безопаснее не создавать грязь автоматически,
        // чем снова загрязнять наружную дорогу.
        return false;
    }

    // Объединение двух прямоугольников позволяет задать Г-образную клинику.
    if (cleanliness_point_in_marker_pair(
        obj_cleanliness_area_start,
        obj_cleanliness_area_end,
        _x,
        _y
    )) {
        return true;
    }

    if (cleanliness_point_in_marker_pair(
        obj_cleanliness_area_start_2,
        obj_cleanliness_area_end_2,
        _x,
        _y
    )) {
        return true;
    }

    return false;
}

function cleanliness_position_is_valid_floor(_x, _y) {
    if (!cleanliness_position_inside_clinic(_x, _y)) {
        return false;
    }

    if (_x < 32 || _y < 32 || _x > room_width - 32 || _y > room_height - 32) {
        return false;
    }

    // Стены, мебель и остальные препятствия проекта наследуются от par_objects.
    // Запас 22 пикселя удерживает центр пятна на открытом полу, а не под маской стены.
    var _obstacle = collision_circle(
        _x,
        _y,
        22,
        par_objects,
        false,
        true
    );

    if (instance_exists(_obstacle)) return false;
    return true;
}

function cleanliness_position_has_dirt(_x, _y, _radius) {
    for (var _index = 0; _index < instance_number(obj_floor_dirt); _index++) {
        var _dirt = instance_find(obj_floor_dirt, _index);

        if (
            instance_exists(_dirt)
            && point_distance(_x, _y, _dirt.x, _dirt.y) < _radius
        ) {
            return true;
        }
    }

    return false;
}

function cleanliness_try_spawn_dirt(_controller) {
    if (!instance_exists(_controller)) return false;
    if (!ds_exists(_controller.traffic_map, ds_type_map)) return false;
    if (instance_number(obj_floor_dirt) >= _controller.max_dirt_count) return false;

    _controller.spawn_attempts += 1;

    var _required_traffic = _controller.first_dirt_spawned
        ? _controller.min_traffic_for_dirt
        : max(2, round(_controller.min_traffic_for_dirt * 0.35));
    var _total_weight = 0;
    var _key = ds_map_find_first(_controller.traffic_map);

    while (!is_undefined(_key)) {
        var _cell = _controller.traffic_map[? _key];

        if (
            is_struct(_cell)
            && _cell.score >= _required_traffic
            && cleanliness_position_is_valid_floor(_cell.x, _cell.y)
            && !cleanliness_position_has_dirt(
                _cell.x,
                _cell.y,
                _controller.minimum_dirt_spacing
            )
        ) {
            _total_weight += _cell.score;
        }

        _key = ds_map_find_next(_controller.traffic_map, _key);
    }

    if (_total_weight <= 0) return false;

    var _roll = random(_total_weight);
    var _chosen_key = undefined;
    var _accumulator = 0;
    _key = ds_map_find_first(_controller.traffic_map);

    while (!is_undefined(_key)) {
        var _candidate = _controller.traffic_map[? _key];

        if (
            is_struct(_candidate)
            && _candidate.score >= _required_traffic
            && cleanliness_position_is_valid_floor(_candidate.x, _candidate.y)
            && !cleanliness_position_has_dirt(
                _candidate.x,
                _candidate.y,
                _controller.minimum_dirt_spacing
            )
        ) {
            _accumulator += _candidate.score;

            if (_roll <= _accumulator) {
                _chosen_key = _key;
                break;
            }
        }

        _key = ds_map_find_next(_controller.traffic_map, _key);
    }

    if (is_undefined(_chosen_key)) return false;

    var _chosen = _controller.traffic_map[? _chosen_key];
    var _spawn_x = _chosen.x;
    var _spawn_y = _chosen.y;
    var _spawn_position_found = false;

    // Случайная форма остаётся, но центр выбирается только на открытом полу.
    for (var _try_index = 0; _try_index < 20; _try_index++) {
        var _try_radius = random_range(0, 18);
        var _try_angle = random(360);
        var _try_x = _chosen.x + lengthdir_x(_try_radius, _try_angle);
        var _try_y = _chosen.y + lengthdir_y(_try_radius * 0.72, _try_angle);

        if (
            cleanliness_position_is_valid_floor(_try_x, _try_y)
            && !cleanliness_position_has_dirt(
                _try_x,
                _try_y,
                _controller.minimum_dirt_spacing
            )
        ) {
            _spawn_x = _try_x;
            _spawn_y = _try_y;
            _spawn_position_found = true;
            break;
        }
    }

    if (!_spawn_position_found) {
        _chosen.score *= 0.55;
        _controller.traffic_map[? _chosen_key] = _chosen;
        return false;
    }

    var _dirt = instance_create_layer(
        _spawn_x,
        _spawn_y,
        "Instances",
        obj_floor_dirt
    );

    if (!instance_exists(_dirt)) return false;

    _dirt.traffic_direction = _chosen.angle;
    _controller.first_dirt_spawned = true;

    _chosen.score *= 0.32;
    _controller.traffic_map[? _chosen_key] = _chosen;

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 6. ПУТЬ ИГРОКА К ПЯТНУ
// ═══════════════════════════════════════════════════════════════

function dirt_open_menu_immediate(_dirt) {
    if (!instance_exists(_dirt)) return false;
    if (!instance_exists(obj_player)) return false;

    var _player = instance_find(obj_player, 0);
    if (!instance_exists(_player)) return false;

    if (
        variable_instance_exists(_player, "doctor_state")
        && _player.doctor_state != "idle"
    ) {
        if (instance_exists(obj_UI_HUD)) {
            var _hud_busy = instance_find(obj_UI_HUD, 0);
            _hud_busy.show_notice(
                "ИГРОК ЗАНЯТ",
                "Сначала завершите текущее действие",
                room_speed * 2
            );
        }
        return false;
    }

    // Останавливаем путь, который игрок мог начать тем же кликом.
    with (_player) {
        path_end();
        speed = 0;
        hspeed = 0;
        vspeed = 0;
        is_walking = false;
        cleaning_target = _dirt;
        doctor_state = "clean_dirt_menu";
    }

    _dirt.targeted_by_player = true;
    _dirt.target_player = _player;
    _dirt.clean_after_arrival = false;

    global.clean_menu_open = true;
    global.clean_menu_target = _dirt;
    global.clean_menu_click_lock = 3;
    global.ui_block_world_click = true;

    return true;
}

function dirt_request_cleaning(_dirt) {
    if (!instance_exists(_dirt)) return false;
    if (!instance_exists(_dirt.target_player)) return false;

    _dirt.clean_after_arrival = true;
    return dirt_send_player_to(_dirt);
}

function dirt_send_player_to(_dirt) {
    if (!instance_exists(_dirt)) return false;
    if (!instance_exists(obj_player)) return false;

    var _player = instance_find(obj_player, 0);
    if (!instance_exists(_player)) return false;

    if (
        variable_instance_exists(_player, "doctor_state")
        && _player.doctor_state != "idle"
        && _player.doctor_state != "clean_dirt_menu"
        && _player.doctor_state != "going_to_clean_dirt"
    ) {
        if (instance_exists(obj_UI_HUD)) {
            var _hud_busy = instance_find(obj_UI_HUD, 0);
            _hud_busy.show_notice(
                "ИГРОК ЗАНЯТ",
                "Сначала завершите текущее действие",
                room_speed * 2
            );
        }
        return false;
    }

    _dirt.targeted_by_player = true;
    _dirt.target_player = _player;
    _player.cleaning_target = _dirt;
    _player.doctor_state = "going_to_clean_dirt";

    with (_player) {
        path_end();
        speed = 0;
        hspeed = 0;
        vspeed = 0;
        is_walking = false;
    }

    // Если игрок уже рядом, меню откроется на следующем Step без нового пути.
    if (point_distance(_player.x, _player.y, _dirt.x, _dirt.y) <= 58) {
        _dirt.interact_x = _player.x;
        _dirt.interact_y = _player.y;
        _dirt.interact_path_built = true;
        return true;
    }

    var _offsets = [
        [  0,  32],
        [ 32,   0],
        [-32,   0],
        [  0, -32],
        [ 24,  24],
        [-24,  24],
        [ 24, -24],
        [-24, -24],
        [  0,  42],
        [ 42,   0],
        [-42,   0],
        [  0, -42]
    ];
    var _path_built = false;

    for (var _offset_index = 0; _offset_index < array_length(_offsets); _offset_index++) {
        var _offset = _offsets[_offset_index];
        var _target_x = _dirt.x + _offset[0];
        var _target_y = _dirt.y + _offset[1];

        if (!cleanliness_position_is_valid_floor(_target_x, _target_y)) {
            continue;
        }

        if (mp_grid_path(
            global.ai_grid,
            _player.my_path,
            _player.x,
            _player.y,
            _target_x,
            _target_y,
            true
        )) {
            _dirt.interact_x = _target_x;
            _dirt.interact_y = _target_y;
            _dirt.interact_path_built = true;
            _path_built = true;
            break;
        }
    }

    if (_path_built) {
        with (_player) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
            image_speed = 1;
        }
    } else {
        // Последняя страховка: идём к текущей позиции игрока со стороны пятна.
        var _fallback_dir = point_direction(
            _dirt.x,
            _dirt.y,
            _player.x,
            _player.y
        );
        _dirt.interact_x = _dirt.x + lengthdir_x(40, _fallback_dir);
        _dirt.interact_y = _dirt.y + lengthdir_y(40, _fallback_dir);
        _dirt.interact_path_built = false;

        with (_player) {
            move_towards_point(
                _dirt.interact_x,
                _dirt.interact_y,
                p_move_speed
            );
            is_walking = true;
            image_speed = 1;
        }
    }

    return true;
}

function dirt_release_player(_dirt) {
    if (!instance_exists(_dirt)) return;

    var _player = _dirt.target_player;

    if (instance_exists(_player)) {
        with (_player) {
            path_end();
            speed = 0;
            is_walking = false;
            action_progress_active = false;
            action_progress_timer = 0;
            action_progress_timer_max = 0;
            cleaning_target = noone;

            if (
                doctor_state == "going_to_clean_dirt"
                || doctor_state == "clean_dirt_menu"
                || doctor_state == "cleaning_dirt"
            ) {
                doctor_state = "idle";
            }
        }
    }

    _dirt.targeted_by_player = false;
    _dirt.target_player = noone;
    _dirt.cleaning_active = false;
    _dirt.clean_after_arrival = false;
}

function dirt_start_cleaning(_dirt) {
    if (!instance_exists(_dirt)) return false;
    if (!instance_exists(_dirt.target_player)) return false;

    var _player = _dirt.target_player;

    player_extra_skills_init(_player);
    player_recalc_cleaning_stats(_player);

    _dirt.cleaning_active = true;
    _dirt.clean_timer_max = _player.cleaning_action_duration;
    _dirt.clean_timer = _dirt.clean_timer_max;
    _player.doctor_state = "cleaning_dirt";

    with (_player) {
        path_end();
        speed = 0;
        is_walking = false;
    }

    return true;
}

function dirt_finish_cleaning(_dirt) {
    if (!instance_exists(_dirt)) return false;

    global.clinic_cleanliness = clamp(
        global.clinic_cleanliness + _dirt.dirt_value,
        0,
        100
    );

    _dirt.cleaned_successfully = true;

    var _cleaning_player = _dirt.target_player;

    if (instance_exists(_cleaning_player)) {
        player_add_assistant_skill_xp(
            _cleaning_player,
            2,
            5,
            true
        );

        if (variable_instance_exists(_cleaning_player, "add_xp_log")) {
            _cleaning_player.add_xp_log("+5 УБОРКА");
        }
    }

    if (instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);
        _hud.show_notice(
            "ЧИСТОТА +" + string(_dirt.dirt_value) + "%",
            "Пятно удалено",
            room_speed * 2
        );
    }

    dirt_release_player(_dirt);

    with (_dirt) {
        instance_destroy();
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 6.1 АВТОМАТИЧЕСКАЯ УБОРКА NPC-АССИСТЕНТОМ
// ═══════════════════════════════════════════════════════════════

function dirt_release_assistant(_dirt) {
    if (!instance_exists(_dirt)) return;

    var _assistant = _dirt.target_assistant;

    if (instance_exists(_assistant)) {
        with (_assistant) {
            path_end();
            speed = 0;
            hspeed = 0;
            vspeed = 0;
            is_walking = false;
            action_progress_active = false;
            action_progress_timer = 0;
            action_progress_timer_max = 0;
            cleaning_target = noone;

            if (
                assistant_state == "cleaning_going_to_dirt"
                || assistant_state == "cleaning_dirt"
            ) {
                assistant_state = "idle";
            }
        }
    }

    _dirt.targeted_by_assistant = false;
    _dirt.target_assistant = noone;
    _dirt.assistant_cleaning_active = false;
}

function dirt_start_assistant_cleaning(_dirt) {
    if (!instance_exists(_dirt)) return false;
    if (!instance_exists(_dirt.target_assistant)) return false;

    var _assistant = _dirt.target_assistant;

    assistant_extra_skills_init(_assistant);
    assistant_recalc_cleaning_stats(_assistant);

    _dirt.assistant_cleaning_active = true;
    _dirt.assistant_clean_timer_max = _assistant.cleaning_action_duration;
    _dirt.assistant_clean_timer = _dirt.assistant_clean_timer_max;
    _assistant.assistant_state = "cleaning_dirt";

    with (_assistant) {
        path_end();
        speed = 0;
        hspeed = 0;
        vspeed = 0;
        is_walking = false;
    }

    return true;
}

function dirt_finish_assistant_cleaning(_dirt) {
    if (!instance_exists(_dirt)) return false;

    var _assistant = _dirt.target_assistant;

    global.clinic_cleanliness = clamp(
        global.clinic_cleanliness + _dirt.dirt_value,
        0,
        100
    );

    _dirt.cleaned_successfully = true;

    if (instance_exists(_assistant)) {
        assistant_add_skill_xp(
            _assistant,
            2,
            5,
            true
        );

        if (variable_instance_exists(_assistant, "add_xp_log")) {
            _assistant.add_xp_log("+5 УБОРКА");
        }
    }

    dirt_release_assistant(_dirt);

    with (_dirt) {
        instance_destroy();
    }

    return true;
}

function dirt_send_assistant_to(_dirt, _assistant) {
    if (!instance_exists(_dirt)) return false;
    if (!instance_exists(_assistant)) return false;
    if (_dirt.targeted_by_player || _dirt.targeted_by_assistant) return false;

    assistant_extra_skills_init(_assistant);
    assistant_recalc_cleaning_stats(_assistant);

    _dirt.targeted_by_assistant = true;
    _dirt.target_assistant = _assistant;
    _assistant.cleaning_target = _dirt;
    _assistant.assistant_state = "cleaning_going_to_dirt";

    with (_assistant) {
        path_end();
        speed = 0;
        hspeed = 0;
        vspeed = 0;
        is_walking = false;
    }

    if (point_distance(_assistant.x, _assistant.y, _dirt.x, _dirt.y) <= 58) {
        _dirt.assistant_interact_x = _assistant.x;
        _dirt.assistant_interact_y = _assistant.y;
        return true;
    }

    var _offsets = [
        [  0,  32], [ 32,   0], [-32,   0], [  0, -32],
        [ 24,  24], [-24,  24], [ 24, -24], [-24, -24],
        [  0,  42], [ 42,   0], [-42,   0], [  0, -42]
    ];
    var _path_built = false;

    for (var _index = 0; _index < array_length(_offsets); _index++) {
        var _offset = _offsets[_index];
        var _target_x = _dirt.x + _offset[0];
        var _target_y = _dirt.y + _offset[1];

        if (!cleanliness_position_is_valid_floor(_target_x, _target_y)) {
            continue;
        }

        if (mp_grid_path(
            global.ai_grid,
            _assistant.my_path,
            _assistant.x,
            _assistant.y,
            _target_x,
            _target_y,
            true
        )) {
            _dirt.assistant_interact_x = _target_x;
            _dirt.assistant_interact_y = _target_y;
            _path_built = true;
            break;
        }
    }

    if (_path_built) {
        with (_assistant) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
            image_speed = 1;
        }
    }
    else {
        _dirt.targeted_by_assistant = false;
        _dirt.target_assistant = noone;
        _assistant.cleaning_target = noone;
        _assistant.assistant_state = "idle";
        return false;
    }

    return true;
}

function cleanliness_try_assign_assistant_jobs(_controller) {
    if (!instance_exists(_controller)) return;

    for (var _assistant_index = 0; _assistant_index < instance_number(obj_staff_assistant); _assistant_index++) {
        var _assistant = instance_find(
            obj_staff_assistant,
            _assistant_index
        );

        if (!instance_exists(_assistant)) continue;
        if (_assistant.is_tired || _assistant.is_exhausted) continue;

        staff_workplace_init(_assistant);

        var _free_on_reception = (
            _assistant.workplace_id == "reception"
            && _assistant.assistant_state == "idle"
        );
        var _free_in_inpatient = (
            _assistant.workplace_id == "inpatient"
            && _assistant.assistant_state == "inpatient_available"
        );

        if (!_free_on_reception && !_free_in_inpatient) continue;

        var _best_dirt = noone;
        var _best_distance = 1000000;

        for (var _dirt_index = 0; _dirt_index < instance_number(obj_floor_dirt); _dirt_index++) {
            var _dirt = instance_find(obj_floor_dirt, _dirt_index);

            if (!instance_exists(_dirt)) continue;
            if (_dirt.targeted_by_player || _dirt.targeted_by_assistant) continue;
            if (_dirt.cleaning_active || _dirt.assistant_cleaning_active) continue;
            if (!cleanliness_position_inside_clinic(_dirt.x, _dirt.y)) continue;

            var _distance = point_distance(
                _assistant.x,
                _assistant.y,
                _dirt.x,
                _dirt.y
            );

            if (_distance < _best_distance) {
                _best_distance = _distance;
                _best_dirt = _dirt;
            }
        }

        if (instance_exists(_best_dirt)) {
            dirt_send_assistant_to(_best_dirt, _assistant);
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 7. STEP ПЯТНА
// ═══════════════════════════════════════════════════════════════

function dirt_instance_step(_dirt) {
    if (!instance_exists(_dirt)) return;

    var _mouse_over = point_distance(
        mouse_x,
        mouse_y,
        _dirt.x,
        _dirt.y
    ) <= _dirt.hit_radius;
    var _ui_closed = !world_clicks_blocked();

    _dirt.is_hovered = _mouse_over
        && _ui_closed
        && !global.clean_menu_open
        && !_dirt.targeted_by_assistant
        && !_dirt.assistant_cleaning_active;

    if (
        _dirt.is_hovered
        && mouse_check_button_pressed(mb_left)
    ) {
        // Меню появляется сразу. Маршрут строится только после «ПОЧИСТИТЬ».
        dirt_open_menu_immediate(_dirt);
    }

    if (
        _dirt.targeted_by_player
        && !instance_exists(_dirt.target_player)
    ) {
        _dirt.targeted_by_player = false;
        _dirt.target_player = noone;
        _dirt.cleaning_active = false;
    }

    if (
        _dirt.targeted_by_assistant
        && !instance_exists(_dirt.target_assistant)
    ) {
        _dirt.targeted_by_assistant = false;
        _dirt.target_assistant = noone;
        _dirt.assistant_cleaning_active = false;
    }

    if (
        _dirt.targeted_by_assistant
        && instance_exists(_dirt.target_assistant)
        && !_dirt.assistant_cleaning_active
    ) {
        var _assistant = _dirt.target_assistant;
        var _assistant_distance_to_point = point_distance(
            _assistant.x,
            _assistant.y,
            _dirt.assistant_interact_x,
            _dirt.assistant_interact_y
        );
        var _assistant_distance_to_dirt = point_distance(
            _assistant.x,
            _assistant.y,
            _dirt.x,
            _dirt.y
        );
        var _assistant_arrived = (
            _assistant_distance_to_point <= 14
            || (
                _assistant.path_index < 0
                && _assistant_distance_to_dirt <= 68
            )
        );

        if (_assistant_arrived) {
            with (_assistant) {
                path_end();
                speed = 0;
                hspeed = 0;
                vspeed = 0;
                is_walking = false;
            }

            dirt_start_assistant_cleaning(_dirt);
        }
        else if (_assistant.path_index < 0 && !_assistant.is_walking) {
            dirt_release_assistant(_dirt);
        }
    }

    if (
        _dirt.assistant_cleaning_active
        && instance_exists(_dirt.target_assistant)
    ) {
        var _assistant_cleaner = _dirt.target_assistant;

        with (_assistant_cleaner) {
            path_end();
            speed = 0;
            hspeed = 0;
            vspeed = 0;
            is_walking = false;
            assistant_state = "cleaning_dirt";
            action_progress_active = true;
            action_progress_timer = _dirt.assistant_clean_timer;
            action_progress_timer_max = _dirt.assistant_clean_timer_max;
            action_progress_label = "УБОРКА";
            action_progress_color = make_color_rgb(65, 150, 85);
        }

        _dirt.assistant_clean_timer -= 1;

        if (_dirt.assistant_clean_timer <= 0) {
            dirt_finish_assistant_cleaning(_dirt);
            return;
        }
    }

    if (
        _dirt.targeted_by_player
        && instance_exists(_dirt.target_player)
        && !_dirt.cleaning_active
        && !global.clean_menu_open
    ) {
        var _player = _dirt.target_player;
        var _distance_to_interact = point_distance(
            _player.x,
            _player.y,
            _dirt.interact_x,
            _dirt.interact_y
        );
        var _distance_to_dirt = point_distance(
            _player.x,
            _player.y,
            _dirt.x,
            _dirt.y
        );
        var _arrived = (
            _distance_to_interact <= 14
            || (
                _player.path_index < 0
                && _distance_to_dirt <= 68
            )
        );

        if (_arrived) {
            with (_player) {
                path_end();
                speed = 0;
                hspeed = 0;
                vspeed = 0;
                is_walking = false;
            }

            if (_dirt.clean_after_arrival) {
                _dirt.clean_after_arrival = false;
                dirt_start_cleaning(_dirt);
            } else {
                _player.doctor_state = "clean_dirt_menu";
                global.clean_menu_open = true;
                global.clean_menu_target = _dirt;
                global.clean_menu_click_lock = 3;
                global.ui_block_world_click = true;
            }
        }
        else if (_player.path_index < 0 && !_player.is_walking) {
            dirt_send_player_to(_dirt);
        }
    }

    if (_dirt.cleaning_active && instance_exists(_dirt.target_player)) {
        var _cleaner = _dirt.target_player;

        with (_cleaner) {
            path_end();
            speed = 0;
            is_walking = false;
            doctor_state = "cleaning_dirt";
            action_progress_active = true;
            action_progress_timer = _dirt.clean_timer;
            action_progress_timer_max = _dirt.clean_timer_max;
            action_progress_label = "УБОРКА";
            action_progress_color = make_color_rgb(65, 150, 85);
        }

        _dirt.clean_timer -= 1;

        if (_dirt.clean_timer <= 0) {
            dirt_finish_cleaning(_dirt);
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 8. РАСПИСАНИЕ ПОЯВЛЕНИЯ ГРЯЗИ
// Одно пятно через 60–180 игровых минут, только с 10:00 до 00:00.
// ═══════════════════════════════════════════════════════════════

function cleanliness_absolute_game_minute() {
    var _day = variable_global_exists("game_day")
        ? max(0, global.game_day)
        : 0;
    var _hour = variable_global_exists("game_hour")
        ? clamp(global.game_hour, 0, 23)
        : 0;
    var _minute = variable_global_exists("game_minute")
        ? clamp(global.game_minute, 0, 59)
        : 0;

    return _day * 1440 + _hour * 60 + _minute;
}

function cleanliness_schedule_next_dirt(_controller, _now_absolute) {
    if (!instance_exists(_controller)) return -1;

    var _day_start = floor(_now_absolute / 1440) * 1440;
    var _minute_of_day = _now_absolute - _day_start;
    var _open_minute = 10 * 60;
    var _close_minute = 24 * 60;
    var _delay = irandom_range(60, 180);
    var _next = _now_absolute + _delay;

    if (_minute_of_day < _open_minute) {
        // До открытия отсчёт начинается с 10:00.
        _next = _day_start + _open_minute + _delay;
    }
    else if (_minute_of_day >= _close_minute) {
        _next = _day_start + 1440 + _open_minute + _delay;
    }
    else if (_next >= _day_start + _close_minute) {
        // Если интервал пересёк полночь, переносим пятно на следующий день.
        _next = _day_start + 1440 + _open_minute + irandom_range(60, 180);
    }

    _controller.next_dirt_spawn_absolute_minute = _next;
    return _next;
}


// ═══════════════════════════════════════════════════════════════
// 9. STEP КОНТРОЛЛЕРА ЧИСТОТЫ
// ═══════════════════════════════════════════════════════════════

function cleanliness_controller_step(_controller) {
    if (!instance_exists(_controller)) return;

    if (!variable_global_exists("clinic_cleanliness")) {
        global.clinic_cleanliness = 100;
    }
    if (!variable_global_exists("clean_menu_open")) {
        global.clean_menu_open = false;
        global.clean_menu_target = noone;
    }
    if (!variable_global_exists("clean_menu_click_lock")) {
        global.clean_menu_click_lock = 0;
    }

    if (global.clean_menu_click_lock > 0) {
        global.clean_menu_click_lock -= 1;
    }

    // Уже созданные наружные пятна удаляются после установки маркеров зоны.
    if (cleanliness_has_any_area()) {
        for (var _outside_index = instance_number(obj_floor_dirt) - 1; _outside_index >= 0; _outside_index--) {
            var _outside_dirt = instance_find(obj_floor_dirt, _outside_index);

            if (
                instance_exists(_outside_dirt)
                && !cleanliness_position_inside_clinic(
                    _outside_dirt.x,
                    _outside_dirt.y
                )
            ) {
                global.clinic_cleanliness = clamp(
                    global.clinic_cleanliness + _outside_dirt.dirt_value,
                    0,
                    100
                );

                with (_outside_dirt) {
                    instance_destroy();
                }
            }
        }
    }

    if (global.clean_menu_open) {
        global.ui_block_world_click = true;

        if (!instance_exists(global.clean_menu_target)) {
            global.clean_menu_open = false;
            global.clean_menu_target = noone;
            global.ui_block_world_click = false;
        }
    }

    _controller.traffic_sample_timer -= 1;

    if (_controller.traffic_sample_timer <= 0) {
        _controller.traffic_sample_timer = _controller.traffic_sample_interval;

        // Перечисляем реальные дочерние объекты явно: instance_number(parent)
        // может не учитывать потомков одинаково в разных версиях GameMaker.
        cleanliness_sample_object_type(_controller, obj_player, 1.20);
        cleanliness_sample_object_type(_controller, obj_staff_doctor, 1.00);
        cleanliness_sample_object_type(_controller, obj_staff_assistant, 1.00);
        cleanliness_sample_object_type(_controller, obj_staff_admin, 1.00);
        cleanliness_sample_object_type(_controller, obj_owner, 0.85);
    }

    if (!variable_instance_exists(_controller, "assistant_clean_scan_timer")) {
        _controller.assistant_clean_scan_interval = room_speed;
        _controller.assistant_clean_scan_timer = room_speed;
    }

    _controller.assistant_clean_scan_timer -= 1;

    if (_controller.assistant_clean_scan_timer <= 0) {
        _controller.assistant_clean_scan_timer = max(
            1,
            _controller.assistant_clean_scan_interval
        );
        cleanliness_try_assign_assistant_jobs(_controller);
    }

    // Появление грязи привязано к игровым часам, а не к реальным кадрам.
    var _now_absolute = cleanliness_absolute_game_minute();
    var _day_minute = global.game_hour * 60 + global.game_minute;
    var _spawn_window_open = (
        _day_minute >= 10 * 60
        && _day_minute < 24 * 60
    );

    if (
        !variable_instance_exists(
            _controller,
            "next_dirt_spawn_absolute_minute"
        )
        || _controller.next_dirt_spawn_absolute_minute < 0
    ) {
        cleanliness_schedule_next_dirt(_controller, _now_absolute);
    }

    // Старый просроченный таймер, загруженный ночью, не создаёт пятно
    // сразу в 10:00 — сначала назначается нормальная задержка 1–3 часа.
    if (
        !_spawn_window_open
        && _now_absolute >= _controller.next_dirt_spawn_absolute_minute
    ) {
        cleanliness_schedule_next_dirt(_controller, _now_absolute);
    }

    if (
        _spawn_window_open
        && !global.time_paused
        && _now_absolute >= _controller.next_dirt_spawn_absolute_minute
    ) {
        cleanliness_try_spawn_dirt(_controller);

        // Даже неудачная попытка не запускает частые повторные проверки.
        cleanliness_schedule_next_dirt(_controller, _now_absolute);
    }

    global.clinic_cleanliness = clamp(
        global.clinic_cleanliness,
        0,
        100
    );
}


// ═══════════════════════════════════════════════════════════════
// 9. МЕНЮ «ПОЧИСТИТЬ»
// ═══════════════════════════════════════════════════════════════

function cleanliness_draw_clean_menu(_controller) {
    if (!instance_exists(_controller)) return;
    if (!global.clean_menu_open) return;
    if (!instance_exists(global.clean_menu_target)) return;

    var _target = global.clean_menu_target;
    var _gui_w = display_get_gui_width();
    var _gui_h = display_get_gui_height();
    var _cam = view_camera[0];
    var _view_w = camera_get_view_width(_cam);
    var _view_h = camera_get_view_height(_cam);
    var _view_x = camera_get_view_x(_cam);
    var _view_y = camera_get_view_y(_cam);
    var _anchor_x = (_target.x - _view_x) * (_gui_w / _view_w);
    var _anchor_y = (_target.y - 70 - _view_y) * (_gui_h / _view_h);

    // Компактный размер как у небольшой таблички кандидата.
    var _panel_w = 174;
    var _panel_h = 50;
    var _panel_x1 = clamp(
        _anchor_x - _panel_w * 0.5,
        12,
        _gui_w - _panel_w - 12
    );
    var _panel_y1 = clamp(
        _anchor_y - _panel_h,
        12,
        _gui_h - _panel_h - 12
    );
    var _panel_x2 = _panel_x1 + _panel_w;
    var _panel_y2 = _panel_y1 + _panel_h;
    var _button_x1 = _panel_x1 + 10;
    var _button_y1 = _panel_y1 + 10;
    var _button_x2 = _panel_x2 - 10;
    var _button_y2 = _panel_y2 - 10;
    var _mouse_x = device_mouse_x_to_gui(0);
    var _mouse_y = device_mouse_y_to_gui(0);
    var _hover = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _button_x1,
        _button_y1,
        _button_x2,
        _button_y2
    );

    var _paper = make_color_rgb(242, 232, 214);
    var _paper_hover = make_color_rgb(252, 244, 226);
    var _line_dark = make_color_rgb(58, 39, 24);
    var _text_dark = make_color_rgb(50, 38, 28);

    // Пакет №120: матовое стекло + деревянная рамка по краю.
    hud_draw_frosted_panel(_panel_x1, _panel_y1, _panel_x2, _panel_y2, 5);

    draw_set_color(_hover ? _paper_hover : _paper);
    draw_roundrect_ext(
        _button_x1,
        _button_y1,
        _button_x2,
        _button_y2,
        8,
        8,
        false
    );
    draw_set_color(_line_dark);
    draw_roundrect_ext(
        _button_x1,
        _button_y1,
        _button_x2,
        _button_y2,
        8,
        8,
        true
    );

    if (font_exists(fnt_main)) draw_set_font(fnt_main);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_text_dark);
    draw_text(
        (_button_x1 + _button_x2) * 0.5,
        (_button_y1 + _button_y2) * 0.5,
        "ПОЧИСТИТЬ"
    );

    var _menu_can_accept_click = (
        !variable_global_exists("clean_menu_click_lock")
        || global.clean_menu_click_lock <= 0
    );

    if (
        _menu_can_accept_click
        && mouse_check_button_pressed(mb_left)
    ) {
        var _inside_panel = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _panel_x1,
            _panel_y1,
            _panel_x2,
            _panel_y2
        );

        if (_hover) {
            var _clean_target = global.clean_menu_target;
            global.clean_menu_open = false;
            global.clean_menu_target = noone;
            global.ui_block_world_click = false;
            dirt_request_cleaning(_clean_target);
        }
        else if (!_inside_panel) {
            var _cancel_target = global.clean_menu_target;
            global.clean_menu_open = false;
            global.clean_menu_target = noone;
            global.ui_block_world_click = false;

            if (instance_exists(_cancel_target)) {
                dirt_release_player(_cancel_target);
            }
        }
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
    draw_set_color(c_white);
    gpu_set_blendmode(bm_normal);
}


// ═══════════════════════════════════════════════════════════════
// 10. ЧИСТОТА В ВЕРХНЕМ HUD
// ═══════════════════════════════════════════════════════════════

function cleanliness_draw_hud_value(_controller) {
    // Пакет №146: чистота теперь рисуется чипом в hud_draw_main_bars.
    // Старый отдельный чип в углу отключён (эта функция больше ничего не делает).
}

