/// Step obj_owner
/// @description Очередь, ожидание, приём, терпение и уход владельца.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 0. ВОССТАНОВЛЕНИЕ ПРЕРВАННОЙ РЕГИСТРАЦИИ ИЛИ ОПЛАТЫ
// Если администратора уволили во время работы, владелец автоматически
// возвращается в начало очереди и снова становится доступен игроку.
// ═══════════════════════════════════════════════════════════════

reception_recover_orphaned_registration(id, false);


// ═══════════════════════════════════════════════════════════════
// 1. ДОВОДКА ДВИЖЕНИЯ БЕЗ PATH
// Используется после резервного move_towards_point().
// ═══════════════════════════════════════════════════════════════

if (is_walking && path_index < 0) {
    var _at_target = false;
    var _destination_x = x;
    var _destination_y = y;
    var _destination_state = "";

    if (state == "going_to_exam" && variable_instance_exists(id, "exam_target_x")) {
        _destination_x = exam_target_x;
        _destination_y = exam_target_y;
        _destination_state = "in_exam";

        if (point_distance(x, y, _destination_x, _destination_y) <= 12) {
            _at_target = true;
        } else {
            move_towards_point(_destination_x, _destination_y, p_move_speed);
        }
    }
    else if (
        state == "going_to_waiting"
        && variable_global_exists("wait_spots")
        && wait_spot_index >= 0
        && wait_spot_index < array_length(global.wait_spots)
    ) {
        var _wait_spot = global.wait_spots[wait_spot_index];

        _destination_x = _wait_spot.x;
        _destination_y = _wait_spot.y;
        _destination_state = "waiting";

        if (point_distance(x, y, _destination_x, _destination_y) <= 12) {
            _at_target = true;
        } else {
            move_towards_point(_destination_x, _destination_y, p_move_speed);
        }
    }
    else if (state == "leaving_clinic") {
        _destination_x = leave_target_x;
        _destination_y = leave_target_y;

        if (point_distance(x, y, _destination_x, _destination_y) <= 16) {
            path_end();
            speed = 0;
            is_walking = false;
            instance_destroy();
            exit;
        } else {
            move_towards_point(_destination_x, _destination_y, p_move_speed);
        }
    }
    else {
        is_walking = false;
        move_towards_point(x, y, 0);
    }

    if (_at_target) {
        path_end();
        speed = 0;
        is_walking = false;
        move_towards_point(x, y, 0);

        if (_destination_state != "") {
            state = _destination_state;
        }

        exit;
    }
}


// ═══════════════════════════════════════════════════════════════
// 2. СОСТОЯНИЯ ВЛАДЕЛЬЦА
// ═══════════════════════════════════════════════════════════════

switch (state) {
    case "going_to_queue":
        if (point_distance(x, y, queue_target_x, queue_target_y) <= 10) {
            path_end();
            is_walking = false;
            state = "in_queue";
        }
    break;

    case "registering":
        path_end();
        is_walking = false;
    break;

    case "going_to_waiting":
        if (
            variable_global_exists("wait_spots")
            && wait_spot_index >= 0
            && wait_spot_index < array_length(global.wait_spots)
        ) {
            var _spot = global.wait_spots[wait_spot_index];

            if (point_distance(x, y, _spot.x, _spot.y) <= 10) {
                path_end();
                is_walking = false;
                state = "waiting";
            }
        }
    break;

    case "waiting":
        image_speed = 0;
        image_index = 0;
        is_walking = false;
    break;

    case "going_to_exam":
        if (point_distance(x, y, exam_target_x, exam_target_y) <= 10) {
            path_end();
            is_walking = false;
            state = "in_exam";
        }
    break;

    case "in_exam":
        image_speed = 0;
        image_index = 0;
        is_walking = false;
    break;

    case "leaving_clinic":
        if (point_distance(x, y, leave_target_x, leave_target_y) <= 16) {
            path_end();
            speed = 0;
            is_walking = false;
            instance_destroy();
            exit;
        }
    break;
}


// ═══════════════════════════════════════════════════════════════
// 3. ПОЛОСКА РЕГИСТРАЦИИ И ОПЛАТЫ
// ═══════════════════════════════════════════════════════════════

if (state != "registering" && registration_in_progress) {
    registration_in_progress = false;
    registration_timer = 0;
    registration_timer_max = 0;
    registration_actor_name = "";
}


// ═══════════════════════════════════════════════════════════════
// 4. РАЗВОРОТ К СТОЛУ И РЕГИСТРАТУРЕ
// Направления FR/B оставлены в соответствии с текущими спрайтами проекта.
// ═══════════════════════════════════════════════════════════════

if (state == "in_exam" && instance_exists(assigned_table)) {
    var _table_dx = assigned_table.x - x;
    var _table_dy = assigned_table.y - y;

    if (_table_dy < 0) {
        sprite_index = spr_human_FR_walk;
        pFacing = (abs(_table_dx) > 1 && _table_dx < 0) ? -1 : 1;
    } else {
        sprite_index = spr_human_B_walk;
        pFacing = (abs(_table_dx) > 1 && _table_dx > 0) ? -1 : 1;
    }

    image_speed = 0;
    image_index = 0;
    is_walking = false;
}
else if (
    (
        state == "registering"
        || state == "paying"
        || (state == "in_queue" && queue_slot == 0)
    )
    && instance_exists(assigned_desk)
) {
    var _look_x = assigned_desk.x;
    var _look_y = assigned_desk.y;

    if (
        variable_instance_exists(assigned_desk, "reception_staff_point")
        && instance_exists(assigned_desk.reception_staff_point)
    ) {
        _look_x = assigned_desk.reception_staff_point.x;
        _look_y = assigned_desk.reception_staff_point.y;
    }
    else if (variable_instance_exists(assigned_desk, "admin_spot_x")) {
        _look_x = assigned_desk.admin_spot_x;
        _look_y = assigned_desk.admin_spot_y;
    }

    var _look_dx = _look_x - x;
    var _look_dy = _look_y - y;

    if (_look_dy < 0) {
        sprite_index = spr_human_FR_walk;
        pFacing = (abs(_look_dx) > 1 && _look_dx < 0) ? -1 : 1;
    } else {
        sprite_index = spr_human_B_walk;
        pFacing = (abs(_look_dx) > 1 && _look_dx > 0) ? -1 : 1;
    }

    image_speed = 0;
    image_index = 0;
    is_walking = false;
    image_xscale = abs(image_xscale) * pFacing;
}


// ═══════════════════════════════════════════════════════════════
// 5. СКОРОСТЬ ХОДЬБЫ И ТЕРПЕНИЕ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "owner_walk_speed_level")) {
    owner_generate_walk_speed(id);
}
else if (!variable_instance_exists(id, "owner_walk_speed_percent")) {
    owner_apply_walk_speed_level(id, owner_walk_speed_level);
}

// Терпение: уровень 1 = 15 секунд, уровень 10 = 87 секунд.
if (!variable_instance_exists(id, "patience_level")) {
    patience_level = irandom_range(1, 10);
    stat_patience = patience_level * 10;
}

if (!variable_instance_exists(id, "patience_success_progress")) {
    patience_success_progress = 0;
}

if (!variable_instance_exists(id, "patience_wait_xp_timer")) {
    patience_wait_xp_timer = 0;
}

if (!variable_instance_exists(id, "patience_xp_awarded_this_visit")) {
    patience_xp_awarded_this_visit = false;
}

if (!variable_instance_exists(id, "action_progress_active")) action_progress_active = false;
if (!variable_instance_exists(id, "action_progress_timer")) action_progress_timer = 0;
if (!variable_instance_exists(id, "action_progress_timer_max")) action_progress_timer_max = 1;
if (!variable_instance_exists(id, "action_progress_label")) action_progress_label = "";
if (!variable_instance_exists(id, "action_progress_color")) action_progress_color = c_white;

// Время ожидания увеличено в 2 раза: Lv.1 = 30 сек., Lv.10 = 174 сек.
var _wait_seconds = 30 + (patience_level - 1) * 16;
var _patience_max_frames = round(_wait_seconds * room_speed);

if (!variable_instance_exists(id, "patience_current")) {
    patience_current = _patience_max_frames;
    patience_max = _patience_max_frames;
}

if (!variable_instance_exists(id, "patience_max")) {
    patience_max = _patience_max_frames;
}


// ═══════════════════════════════════════════════════════════════
// 6. ОЖИДАНИЕ И ОКОНЧАНИЕ ТЕРПЕНИЯ
// ═══════════════════════════════════════════════════════════════

var _is_waiting = (state == "waiting" || state == "in_queue");

if (_is_waiting) {
    // За 10 секунд ожидания владелец получает 1/5 прогресса терпения.
    // За один визит награда выдаётся только один раз.
    if (!patience_xp_awarded_this_visit) {
        patience_wait_xp_timer += 1;

        if (patience_wait_xp_timer >= room_speed * 10) {
            var _old_patience_max = _patience_max_frames;
            var _patience_level_up = owner_patience_add_wait_progress(id);

            patience_xp_awarded_this_visit = true;

            if (_patience_level_up) {
                var _new_wait_seconds = 30 + (patience_level - 1) * 16;
                var _new_patience_max = round(_new_wait_seconds * room_speed);

                // Новый уровень сразу добавляет полученное время к текущему ожиданию.
                patience_current += max(0, _new_patience_max - _old_patience_max);
                patience_max = _new_patience_max;
                _patience_max_frames = _new_patience_max;

                if (instance_exists(obj_UI_HUD)) {
                    var _patience_hud = instance_find(obj_UI_HUD, 0);

                    if (
                        instance_exists(_patience_hud)
                        && variable_instance_exists(_patience_hud, "show_notice")
                    ) {
                        with (_patience_hud) {
                            show_notice(
                                "ТЕРПЕНИЕ ПОВЫШЕНО",
                                other.char_name + ": уровень " + string(other.patience_level),
                                room_speed * 3
                            );
                        }
                    }
                }
            }
        }
    }

    patience_current -= 1;

    // Первый клиент у стойки нервничает немного быстрее.
    if (queue_slot == 0) {
        patience_current -= 0.25;
    }

    action_progress_active = true;
    action_progress_timer = patience_current;
    action_progress_timer_max = patience_max;
    action_progress_label = "ОЖИДАНИЕ";
    action_progress_color = make_color_rgb(200, 140, 60);

    if (patience_current <= 0) {
        action_progress_active = false;
        action_progress_timer = 0;

        // Неудачное ожидание уменьшает только прогресс лояльности.
        owner_loyalty_apply_wait_failure(id);

        // Удаляем владельца из очереди стойки.
        if (instance_exists(assigned_desk) && variable_instance_exists(assigned_desk, "queue_list")) {
            var _queue_index = ds_list_find_index(assigned_desk.queue_list, id);

            if (_queue_index != -1) {
                ds_list_delete(assigned_desk.queue_list, _queue_index);
                assigned_desk.alarm[0] = 1;
            }
        }

        // Освобождаем место ожидания.
        if (
            variable_global_exists("wait_spots")
            && wait_spot_index >= 0
            && wait_spot_index < array_length(global.wait_spots)
        ) {
            global.wait_spots[wait_spot_index].occupied_by = noone;
            wait_spot_index = -1;
        }

        // Освобождаем смотровой стол.
        if (instance_exists(assigned_table)) {
            with (assigned_table) {
                table_busy = false;
                assigned_owner = noone;
                assigned_doctor = noone;
                assigned_pet = noone;
            }
        }

        assigned_table = noone;
        assigned_doctor = noone;
        assigned_pet = noone;

        if (variable_struct_exists(global, "speech_say")) {
            global.speech_say(id, "Слишком долго!", 2.4);
        }

        owner_start_leaving(id);

        if (instance_exists(obj_UI_HUD)) {
            var _hud = instance_find(obj_UI_HUD, 0);

            if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
                _hud.show_notice(
                    "КЛИЕНТ УШЁЛ",
                    "Не дождался приёма",
                    room_speed * 2
                );
            }
        }

        if (variable_global_exists("clinic_reputation")) {
            global.clinic_reputation = max(0, global.clinic_reputation - 1);
        }

        exit;
    }
} else {
    // Для следующего этапа обслуживания ожидание начинается с полного запаса.
    patience_current = _patience_max_frames;
    patience_max = _patience_max_frames;
    action_progress_active = false;
    action_progress_timer = 0;
}


// ═══════════════════════════════════════════════════════════════
// 7. ЗАЩИТА ОТ ЗАВИСАНИЯ ПРИ УХОДЕ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "leave_stuck_timer")) {
    leave_stuck_timer = 0;
}

if (state == "leaving_clinic") {
    var _exit_distance = point_distance(x, y, leave_target_x, leave_target_y);

    if (_exit_distance <= 16) {
        path_end();
        speed = 0;
        is_walking = false;
        instance_destroy();
        exit;
    }

    if (!is_walking) {
        leave_stuck_timer += 1;
    } else {
        leave_stuck_timer = 0;
    }

    if (leave_stuck_timer >= room_speed * 4) {
        leave_stuck_timer = 0;

        show_debug_message(
            "[OWNER EXIT] Повторный маршрут к выходу, id=" + string(id)
        );

        path_end();
        speed = 0;
        is_walking = false;

        if (mp_grid_path(
            global.ai_grid,
            my_path,
            x,
            y,
            leave_target_x,
            leave_target_y,
            true
        )) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
        } else {
            move_towards_point(leave_target_x, leave_target_y, p_move_speed);
            is_walking = true;
        }
    }
} else {
    leave_stuck_timer = 0;
}


// ═══════════════════════════════════════════════════════════════
// 8. ГЛУБИНА
// ═══════════════════════════════════════════════════════════════

depth = -y;
