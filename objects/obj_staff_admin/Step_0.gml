/// Step obj_staff_admin
/// @description Очередь, регистрация, оплата и возвращение администратора.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 1. СТРАХОВОЧНАЯ ИНИЦИАЛИЗАЦИЯ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "action_progress_active")) {
    action_progress_active = false;
    action_progress_timer = 0;
    action_progress_timer_max = 0;
    action_progress_label = "";
    action_progress_color = make_color_rgb(80, 170, 90);
}

action_progress_active = false;

if (!variable_instance_exists(id, "admin_idle_timer")) {
    admin_idle_timer = 0;
}


// ═══════════════════════════════════════════════════════════════
// 2. СТОЙКА, ТОЧКИ И ССЫЛКИ
// ═══════════════════════════════════════════════════════════════

if (!instance_exists(reception_desk) && instance_exists(obj_reception_desk)) {
    reception_desk = instance_find(obj_reception_desk, 0);
}

if (
    instance_exists(reception_desk)
    && variable_instance_exists(reception_desk, "reception_refresh_points")
) {
    with (reception_desk) {
        reception_refresh_points();
    }
}

if (!instance_exists(reception_client)) {
    reception_client = noone;

    if (
        reception_state == "going_to_register_spot"
        || reception_state == "registering"
    ) {
        reception_state = "returning";
    }
}

var _free_wait_spot_index = reception_find_free_wait_spot();
var _has_free_wait_spot = (_free_wait_spot_index != -1);


// ═══════════════════════════════════════════════════════════════
// 3. СОСТОЯНИЯ АДМИНИСТРАТОРА
// ═══════════════════════════════════════════════════════════════

switch (reception_state) {
    // ───────────────────────────────────────────────────────────
    // 3.1 СВОБОДЕН
    // ───────────────────────────────────────────────────────────

    case "idle": {
        if (is_exhausted) break;

        if (
            !instance_exists(reception_desk)
            || !variable_instance_exists(reception_desk, "queue_list")
            || !ds_exists(reception_desk.queue_list, ds_type_list)
            || ds_list_size(reception_desk.queue_list) <= 0
        ) {
            // Ничего не останавливаем: End Step родителя управляет гулянием.
            break;
        }

        var _first_client = reception_desk.queue_list[| 0];

        if (!instance_exists(_first_client)) break;

        var _is_payment = (
            variable_instance_exists(_first_client, "queue_purpose")
            && _first_client.queue_purpose == "payment"
        );

        // Для обычной регистрации требуется свободное место ожидания.
        if (!_is_payment && !_has_free_wait_spot) {
            if (wander_walking || is_walking) {
                path_end();
                is_walking = false;
            }

            wander_walking = false;
            break;
        }

        var _client_ready = (_first_client.state == "in_queue");
        var _client_at_front = point_distance(
            _first_client.x,
            _first_client.y,
            reception_desk.queue_start_x,
            reception_desk.queue_start_y
        ) <= 12;

        if (_client_ready && _client_at_front) {
            reception_client = _first_client;
            reception_state = "going_to_register_spot";

            path_end();
            is_walking = false;
            wander_walking = false;

            var _target_x = reception_desk.admin_spot_x;
            var _target_y = reception_desk.admin_spot_y;

            if (point_distance(x, y, _target_x, _target_y) > 10) {
                if (mp_grid_path(
                    global.ai_grid,
                    my_path,
                    x,
                    y,
                    _target_x,
                    _target_y,
                    true
                )) {
                    path_set_kind(my_path, 1);
                    path_start(my_path, p_move_speed, path_action_stop, true);
                    is_walking = true;
                } else {
                    // Не начинаем регистрацию на расстоянии.
                    path_end();
                    is_walking = false;

                    show_debug_message(
                        "[RECEPTION] Не удалось построить путь к точке персонала: "
                        + string(_target_x)
                        + ", "
                        + string(_target_y)
                    );
                }
            }
        }
        else {
            // Клиент ещё идёт к стойке — администратор подходит заранее.
            if (wander_walking) {
                path_end();
                wander_walking = false;
            }

            if (
                point_distance(
                    x,
                    y,
                    reception_desk.admin_spot_x,
                    reception_desk.admin_spot_y
                ) > 10
            ) {
                if (!is_walking || path_index < 0) {
                    if (mp_grid_path(
                        global.ai_grid,
                        my_path,
                        x,
                        y,
                        reception_desk.admin_spot_x,
                        reception_desk.admin_spot_y,
                        true
                    )) {
                        path_set_kind(my_path, 1);
                        path_start(my_path, p_move_speed, path_action_stop, true);
                        is_walking = true;
                    }
                }
            } else {
                is_walking = false;
            }
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.2 ИДЁТ К ТОЧКЕ ПЕРСОНАЛА
    // ───────────────────────────────────────────────────────────

    case "going_to_register_spot": {
        wander_walking = false;

        if (!instance_exists(reception_desk)) {
            reception_state = "idle";
            reception_client = noone;
            path_end();
            is_walking = false;
            break;
        }

        if (
            variable_instance_exists(reception_desk, "reception_refresh_points")
        ) {
            with (reception_desk) {
                reception_refresh_points();
            }
        }

        if (!instance_exists(reception_client)) {
            reception_state = "idle";
            reception_client = noone;
            path_end();
            is_walking = false;
            break;
        }

        if (
            reception_client.state == "leaving_clinic"
            || reception_client.queue_slot != 0
        ) {
            reception_state = "idle";
            reception_client = noone;
            path_end();
            is_walking = false;
            break;
        }

        var _target_x = reception_desk.admin_spot_x;
        var _target_y = reception_desk.admin_spot_y;
        var _distance_to_point = point_distance(x, y, _target_x, _target_y);

        if (_distance_to_point <= 10) {
            path_end();
            speed = 0;
            is_walking = false;

            var _client_is_payment = (
                variable_instance_exists(reception_client, "queue_purpose")
                && reception_client.queue_purpose == "payment"
            );

            reception_duration = _client_is_payment
                ? payment_duration
                : register_duration;

            reception_timer = reception_duration;
            reception_state = "registering";

            with (reception_client) {
                state = "registering";
                path_end();
                speed = 0;
                is_walking = false;

                registration_in_progress = true;
                registration_timer = other.reception_timer;
                registration_timer_max = other.reception_duration;
                registration_actor_name = other.char_name;
            }
        }
        else {
            var _needs_new_path = (
                !is_walking
                || path_index == -1
                || path_position >= 1
            );

            if (_needs_new_path) {
                path_end();
                speed = 0;
                is_walking = false;

                if (mp_grid_path(
                    global.ai_grid,
                    my_path,
                    x,
                    y,
                    _target_x,
                    _target_y,
                    true
                )) {
                    path_set_kind(my_path, 1);
                    path_start(my_path, p_move_speed, path_action_stop, true);
                    is_walking = true;
                } else {
                    show_debug_message(
                        "[RECEPTION] Точка персонала недостижима: "
                        + string(_target_x)
                        + ", "
                        + string(_target_y)
                    );
                }
            }
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.3 РЕГИСТРАЦИЯ ИЛИ ОПЛАТА
    // ───────────────────────────────────────────────────────────

    case "registering": {
        wander_walking = false;

        if (!instance_exists(reception_client)) {
            reception_state = "returning";
            break;
        }

        var _client_is_payment = (
            variable_instance_exists(reception_client, "queue_purpose")
            && reception_client.queue_purpose == "payment"
        );

        reception_duration = _client_is_payment
            ? payment_duration
            : register_duration;

        action_progress_active = true;
        action_progress_timer = reception_timer;
        action_progress_timer_max = reception_duration;
        action_progress_label = _client_is_payment ? "ОПЛАТА" : "ОФОРМЛЕНИЕ";
        action_progress_color = _client_is_payment
            ? make_color_rgb(220, 170, 80)
            : make_color_rgb(80, 170, 90);

        // При регистрации место ожидания могло закончиться, пока шёл таймер.
        if (!_client_is_payment && !_has_free_wait_spot) {
            with (reception_client) {
                state = "in_queue";
                registration_in_progress = false;
                registration_timer = 0;
                registration_timer_max = 0;
                registration_actor_name = "";
            }

            reception_desk.alarm[0] = 1;
            reception_client = noone;
            reception_state = "returning";
            break;
        }

        reception_timer -= 1;

        with (reception_client) {
            registration_in_progress = true;
            registration_timer = other.reception_timer;
            registration_timer_max = other.reception_duration;
            registration_actor_name = other.char_name;
            state = "registering";
            path_end();
            is_walking = false;
        }

        if (reception_timer <= 0) {
            var _finished_client = reception_client;
            reception_client = noone;

            var _success = false;

            if (_client_is_payment) {
                _success = reception_finish_owner_payment(_finished_client);

                if (_success) {
                    admin_add_skill_xp(id, 1, 5, true);
                    add_xp_log("+5 КАССА");
                    staff_spend_energy(3);

                    if (variable_struct_exists(global, "speech_say")) {
                        global.speech_say(self, "Оплачено!", 2);
                    }
                }
            }
            else {
                _success = reception_finish_owner_registration(
                    _finished_client,
                    false
                );

                if (_success) {
                    admin_add_skill_xp(id, 0, 5, true);
                    add_xp_log("+5 РЕГИСТРАЦИЯ");
                    staff_spend_energy(3);

                    if (variable_struct_exists(global, "speech_say")) {
                        global.speech_say(self, "Проходите!", 2);
                    }
                }
                else if (instance_exists(_finished_client)) {
                    with (_finished_client) {
                        state = "in_queue";
                        registration_in_progress = false;
                        registration_timer = 0;
                        registration_timer_max = 0;
                        registration_actor_name = "";
                    }

                    if (instance_exists(reception_desk)) {
                        reception_desk.alarm[0] = 1;
                    }
                }
            }


            // ═══════════════════════════════════════════════════
            // 3.3.1 ДНЕВНАЯ СТАТИСТИКА ОПЛАТЫ
            // Начисляется внутри reception_finish_owner_payment(),
            // одинаково для NPC-администратора и главного игрока.
            // ═══════════════════════════════════════════════════


            // ═══════════════════════════════════════════════════
            // 3.3.2 СЛЕДУЮЩИЙ КЛИЕНТ
            // ═══════════════════════════════════════════════════

            var _next_client = noone;
            var _next_ready = false;

            if (
                instance_exists(reception_desk)
                && ds_exists(reception_desk.queue_list, ds_type_list)
                && ds_list_size(reception_desk.queue_list) > 0
            ) {
                _next_client = reception_desk.queue_list[| 0];

                if (instance_exists(_next_client)) {
                    _next_ready = (
                        _next_client.state == "in_queue"
                        && point_distance(
                            _next_client.x,
                            _next_client.y,
                            reception_desk.queue_start_x,
                            reception_desk.queue_start_y
                        ) <= 12
                    );
                }
            }

            path_end();
            is_walking = false;
            admin_idle_timer = 0;

            var _admin_at_point = (
                instance_exists(reception_desk)
                && point_distance(
                    x,
                    y,
                    reception_desk.admin_spot_x,
                    reception_desk.admin_spot_y
                ) <= 10
            );

            if (_next_ready && _admin_at_point) {
                reception_client = _next_client;

                var _next_is_payment = (
                    variable_instance_exists(reception_client, "queue_purpose")
                    && reception_client.queue_purpose == "payment"
                );

                reception_duration = _next_is_payment
                    ? payment_duration
                    : register_duration;

                reception_timer = reception_duration;
                reception_state = "registering";

                with (reception_client) {
                    state = "registering";
                    path_end();
                    speed = 0;
                    is_walking = false;

                    registration_in_progress = true;
                    registration_timer = other.reception_timer;
                    registration_timer_max = other.reception_duration;
                    registration_actor_name = other.char_name;
                }
            } else {
                reception_client = noone;
                reception_state = "idle";
            }
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.4 ВОЗВРАЩЕНИЕ К ДОМАШНЕЙ ТОЧКЕ
    // ───────────────────────────────────────────────────────────

    case "returning": {
        wander_walking = false;

        if (point_distance(x, y, home_x, home_y) <= 10) {
            path_end();
            is_walking = false;
            reception_state = "idle";
            admin_idle_timer = 0;
            break;
        }

        if (!is_walking || path_index < 0) {
            admin_idle_timer += 1;

            if (admin_idle_timer > room_speed * 2) {
                path_end();
                is_walking = false;

                if (mp_grid_path(
                    global.ai_grid,
                    my_path,
                    x,
                    y,
                    home_x,
                    home_y,
                    true
                )) {
                    path_set_kind(my_path, 1);
                    path_start(my_path, p_move_speed, path_action_stop, true);
                    is_walking = true;
                    admin_idle_timer = 0;
                } else {
                    reception_state = "idle";
                    path_end();
                    is_walking = false;
                    admin_idle_timer = 0;
                }
            }
        } else {
            admin_idle_timer = 0;
        }
    }
    break;
}


// ═══════════════════════════════════════════════════════════════
// 4. ГЛУБИНА
// Скорость ходьбы прокачивается централизованно в Begin Step par_staff.
// ═══════════════════════════════════════════════════════════════

depth = -y;
