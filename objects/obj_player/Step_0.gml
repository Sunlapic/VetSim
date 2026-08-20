/// Step obj_player
/// @description Ручная регистрация, оплата, приём, процедуры, склад и анимации игрока.
/// Пакет №83: клик по главному складу считается по всему стеллажу.
/// Пакет №141: тап по миру отделён от драга/щипка камеры (touch).

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 1. СТРАХОВОЧНАЯ ИНИЦИАЛИЗАЦИЯ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "therapy_xp")) {
    therapy_xp = 0;
    doctor_recalc_therapy_progress(id);
}

if (!variable_instance_exists(id, "action_progress_active")) {
    action_progress_active = false;
    action_progress_timer = 0;
    action_progress_timer_max = 0;
    action_progress_label = "";
    action_progress_color = make_color_rgb(80, 170, 90);
}

if (!variable_instance_exists(id, "interact_target")) {
    interact_target = noone;
}

action_progress_active = false;


// ═══════════════════════════════════════════════════════════════
// 1.1 РАННЯЯ ОТМЕНА ПУТИ К ВЛАДЕЛЬЦУ
// Проверка выполняется ДО switch, чтобы состояние не успело перейти
// из going_to_owner в going_to_doctor_point на кадре клика.
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "pending_service_cancel_seen")) {
    pending_service_cancel_seen = false;
    pending_service_cancel_delay = 0;
}

if (doctor_state == "going_to_owner") {
    if (!pending_service_cancel_seen) {
        // Не принимаем за отмену тот же клик, которым был начат приём.
        pending_service_cancel_seen = true;
        pending_service_cancel_delay = 1;
    } else if (pending_service_cancel_delay > 0) {
        pending_service_cancel_delay -= 1;
    }
} else {
    pending_service_cancel_seen = false;
    pending_service_cancel_delay = 0;
}

var _pending_service_cancelled_this_step = false;

if (
    doctor_state == "going_to_owner"
    && pending_service_cancel_seen
    && pending_service_cancel_delay <= 0
    && mouse_check_button_pressed(mb_left)
    && !world_clicks_blocked()
) {
    _pending_service_cancelled_this_step = player_cancel_pending_service(id);
}


// ═══════════════════════════════════════════════════════════════
// 2. ЦЕЛЬ ПРИЁМА БЫЛА ПЕРЕХВАЧЕНА ИЛИ УДАЛЕНА
// ═══════════════════════════════════════════════════════════════

if (
    doctor_state == "going_to_owner"
    || doctor_state == "going_to_doctor_point"
) {
    var _target_lost = false;

    if (assigned_owner != noone) {
        if (!instance_exists(assigned_owner)) {
            _target_lost = true;
        }
        else if (
            assigned_owner.assigned_doctor != noone
            && assigned_owner.assigned_doctor != id
        ) {
            _target_lost = true;
        }
    }

    if (assigned_table != noone && !instance_exists(assigned_table)) {
        _target_lost = true;
    }

    if (_target_lost) {
        var _lost_table = assigned_table;

        path_end();
        is_walking = false;

        if (instance_exists(_lost_table)) {
            with (_lost_table) {
                table_busy = false;
                assigned_owner = noone;
                assigned_doctor = noone;
                assigned_pet = noone;
            }
        }

        assigned_owner = noone;
        assigned_table = noone;
        assigned_pet = noone;
        doctor_state = "idle";
    }
}


// ═══════════════════════════════════════════════════════════════
// 3. СОСТОЯНИЯ ИГРОКА
// ═══════════════════════════════════════════════════════════════

switch (doctor_state) {
    // ───────────────────────────────────────────────────────────
    // 3.1 ИДЁТ К РЕГИСТРАТУРЕ ИЛИ КАССЕ
    // ───────────────────────────────────────────────────────────

    case "going_to_reception":
    case "going_to_payment": {
        if (
            !instance_exists(registration_target_owner)
            || !instance_exists(registration_target_desk)
        ) {
            player_reset_registration();
            break;
        }

        if (point_distance(x, y, reception_target_x, reception_target_y) <= 10) {
            path_end();
            is_walking = false;
            registration_timer = registration_duration;

            with (registration_target_owner) {
                state = "registering";
                path_end();
                is_walking = false;

                registration_in_progress = true;
                registration_timer = other.registration_timer;
                registration_timer_max = other.registration_duration;
                registration_actor_name = other.char_name;
            }

            doctor_state = (reception_action_type == "payment")
                ? "manual_payment"
                : "manual_registering";
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.2 РУЧНАЯ РЕГИСТРАЦИЯ
    // ───────────────────────────────────────────────────────────

    case "manual_registering": {
        action_progress_active = true;
        action_progress_timer = registration_timer;
        action_progress_timer_max = registration_duration;
        action_progress_label = "ОФОРМЛЕНИЕ";
        action_progress_color = make_color_rgb(80, 170, 90);

        if (
            !instance_exists(registration_target_owner)
            || !instance_exists(registration_target_desk)
        ) {
            player_reset_registration();
            break;
        }

        if (reception_find_free_wait_spot() == -1) {
            with (registration_target_owner) {
                state = "in_queue";
                registration_in_progress = false;
                registration_timer = 0;
                registration_timer_max = 0;
                registration_actor_name = "";
            }

            registration_target_desk.alarm[0] = 1;

            if (instance_exists(obj_UI_HUD)) {
                with (obj_UI_HUD) {
                    show_notice(
                        "НЕТ МЕСТ",
                        "В зоне ожидания нет свободных мест.",
                        room_speed * 3
                    );
                }
            }

            player_reset_registration();
            break;
        }

        path_end();
        is_walking = false;
        registration_timer -= 1;

        with (registration_target_owner) {
            registration_in_progress = true;
            registration_timer = other.registration_timer;
            registration_timer_max = other.registration_duration;
            registration_actor_name = other.char_name;
            state = "registering";
            path_end();
            is_walking = false;
        }

        if (registration_timer <= 0) {
            var _registered_owner = registration_target_owner;
            var _registration_success = reception_finish_owner_registration(
                _registered_owner,
                true
            );

            if (_registration_success) {
                player_add_admin_skill_xp(id, 0, 5, true);
                add_xp_log("+5 РЕГИСТРАЦИЯ");

                if (instance_exists(obj_UI_HUD)) {
                    with (obj_UI_HUD) {
                        show_notice(
                            "КЛИЕНТ ОФОРМЛЕН",
                            "Владелец поставлен в очередь.",
                            room_speed * 2
                        );
                    }
                }
            } else {
                if (instance_exists(_registered_owner)) {
                    with (_registered_owner) {
                        state = "in_queue";
                        registration_in_progress = false;
                        registration_timer = 0;
                        registration_timer_max = 0;
                        registration_actor_name = "";
                    }
                }

                if (instance_exists(registration_target_desk)) {
                    registration_target_desk.alarm[0] = 1;
                }

                if (instance_exists(obj_UI_HUD)) {
                    with (obj_UI_HUD) {
                        show_notice(
                            "ОШИБКА",
                            "Не удалось оформить.",
                            room_speed * 2
                        );
                    }
                }
            }

            player_reset_registration();
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.3 РУЧНАЯ ОПЛАТА
    // ───────────────────────────────────────────────────────────

    case "manual_payment": {
        action_progress_active = true;
        action_progress_timer = registration_timer;
        action_progress_timer_max = registration_duration;
        action_progress_label = "ОПЛАТА";
        action_progress_color = make_color_rgb(220, 170, 80);

        if (
            !instance_exists(registration_target_owner)
            || !instance_exists(registration_target_desk)
        ) {
            player_reset_registration();
            break;
        }

        path_end();
        is_walking = false;
        registration_timer -= 1;

        with (registration_target_owner) {
            registration_in_progress = true;
            registration_timer = other.registration_timer;
            registration_timer_max = other.registration_duration;
            registration_actor_name = other.char_name;
            state = "registering";
            path_end();
            is_walking = false;
        }

        if (registration_timer <= 0) {
            var _paying_owner = registration_target_owner;
            var _payment_success = reception_finish_owner_payment(_paying_owner);

            if (_payment_success) {
                player_add_admin_skill_xp(id, 1, 5, true);
                add_xp_log("+5 КАССА");

                if (instance_exists(obj_UI_HUD)) {
                    with (obj_UI_HUD) {
                        show_notice(
                            "ОПЛАТА ПРИНЯТА",
                            "Клиент рассчитан.",
                            room_speed * 2
                        );
                    }
                }
            } else if (instance_exists(obj_UI_HUD)) {
                with (obj_UI_HUD) {
                    show_notice(
                        "ОШИБКА",
                        "Не удалось принять оплату.",
                        room_speed * 2
                    );
                }
            }

            player_reset_registration();
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.4 ИДЁТ К ВЛАДЕЛЬЦУ
    // ───────────────────────────────────────────────────────────

    case "going_to_owner": {
        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
            if (instance_exists(assigned_table)) {
                with (assigned_table) {
                    table_busy = false;
                    assigned_owner = noone;
                    assigned_doctor = noone;
                    assigned_pet = noone;
                }
            }

            player_reset_exam();
            break;
        }

        if (point_distance(x, y, assigned_owner.x, assigned_owner.y) <= 40) {
            with (assigned_owner) {
                assigned_doctor = other.id;
                assigned_table = other.assigned_table;

                if (
                    wait_spot_index >= 0
                    && variable_global_exists("wait_spots")
                    && wait_spot_index < array_length(global.wait_spots)
                ) {
                    global.wait_spots[wait_spot_index].occupied_by = noone;
                    wait_spot_index = -1;
                }

                exam_target_x = other.owner_target_x;
                exam_target_y = other.owner_target_y;
                state = "going_to_exam";

                path_end();
                is_walking = false;

                if (mp_grid_path(
                    global.ai_grid,
                    my_path,
                    x,
                    y,
                    exam_target_x,
                    exam_target_y,
                    true
                )) {
                    path_set_kind(my_path, 1);
                    path_start(my_path, p_move_speed, path_action_stop, true);
                    is_walking = true;
                } else {
                    move_towards_point(
                        exam_target_x,
                        exam_target_y,
                        p_move_speed
                    );
                    is_walking = true;
                }
            }

            if (instance_exists(assigned_pet)) {
                with (assigned_pet) {
                    assigned_doctor = other.id;
                    assigned_table = other.assigned_table;
                    exam_floor_x = other.pet_floor_target_x;
                    exam_floor_y = other.pet_floor_target_y;
                    exam_table_x = other.pet_table_target_x;
                    exam_table_y = other.pet_table_target_y;
                    state = "going_to_exam_floor";

                    path_end();
                    is_walking = false;

                    if (mp_grid_path(
                        global.ai_grid,
                        my_path,
                        x,
                        y,
                        exam_floor_x,
                        exam_floor_y,
                        true
                    )) {
                        path_set_kind(my_path, 1);
                        path_start(my_path, p_move_speed, path_action_stop, true);
                        is_walking = true;
                    } else {
                        move_towards_point(
                            exam_floor_x,
                            exam_floor_y,
                            p_move_speed
                        );
                        is_walking = true;
                    }
                }
            }

            path_end();
            is_walking = false;

            if (mp_grid_path(
                global.ai_grid,
                my_path,
                x,
                y,
                doctor_target_x,
                doctor_target_y,
                true
            )) {
                path_set_kind(my_path, 1);
                path_start(my_path, p_move_speed, path_action_stop, true);
                is_walking = true;
            } else {
                move_towards_point(
                    doctor_target_x,
                    doctor_target_y,
                    p_move_speed
                );
                is_walking = true;
            }

            doctor_state = "going_to_doctor_point";
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.5 ИДЁТ К ТОЧКЕ ВРАЧА
    // ───────────────────────────────────────────────────────────

    case "going_to_doctor_point": {
        if (point_distance(x, y, doctor_target_x, doctor_target_y) <= 10) {
            path_end();
            speed = 0;
            is_walking = false;
            doctor_state = "waiting_positions";
        }
        else if (path_index < 0) {
            move_towards_point(
                doctor_target_x,
                doctor_target_y,
                p_move_speed
            );
            is_walking = true;
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.6 ЖДЁТ ПОЗИЦИЙ И ПЕРЕХОДИТ К РУЧНОМУ ПРИЁМУ
    // Первичный осмотр здесь НЕ выполняется автоматически.
    // ───────────────────────────────────────────────────────────

    case "waiting_positions": {
        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
            if (instance_exists(assigned_table)) {
                with (assigned_table) {
                    table_busy = false;
                    assigned_owner = noone;
                    assigned_doctor = noone;
                    assigned_pet = noone;
                }
            }

            player_reset_exam();
            break;
        }

        var _owner_ready = (assigned_owner.state == "in_exam");
        var _pet_ready = !instance_exists(assigned_pet)
            || assigned_pet.state == "in_exam";

        if (_owner_ready && _pet_ready) {
            if (service_mode == "doctor") {
                // Игрок сам нажимает кнопку «Первичный осмотр» в карточке питомца.
                doctor_state = "manual_exam";

                if (instance_exists(obj_UI_HUD)) {
                    with (obj_UI_HUD) {
                        show_notice(
                            "ПАЦИЕНТ ГОТОВ",
                            "Начните с первичного осмотра, затем выберите необходимые обследования.",
                            room_speed * 4
                        );
                    }
                }
            }
            else if (service_mode == "procedure") {
                doctor_state = "manual_procedure";

                if (instance_exists(obj_UI_HUD)) {
                    with (obj_UI_HUD) {
                        show_notice(
                            "ПРОЦЕДУРЫ",
                            "Можно выполнять назначения.",
                            room_speed * 4
                        );
                    }
                }
            }
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.7 РУЧНОЙ ПРИЁМ ИЛИ ПРОЦЕДУРЫ
    // ───────────────────────────────────────────────────────────

    case "manual_exam":
    case "manual_procedure":
        path_end();
        is_walking = false;
    break;

    // Игрок временно отошёл от пациента, чтобы пополнить шкаф.
    case "manual_procedure_restock": {
        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
            player_reset_exam();
            break;
        }

        var _stock_ready = false;

        if (
            instance_exists(assigned_pet)
            && variable_instance_exists(assigned_pet, "current_case")
            && is_struct(assigned_pet.current_case)
            && variable_struct_exists(assigned_pet.current_case, "stock_missing_item_id")
        ) {
            var _missing_item_id = assigned_pet.current_case.stock_missing_item_id;
            var _slot_id = assigned_table.exam_slot_id;
            var _cabinet = storage_find_cabinet_by_slot(_slot_id);

            if (
                _missing_item_id != ""
                && instance_exists(_cabinet)
                && variable_instance_exists(_cabinet, "storage_inventory")
                && inventory_get_amount(_cabinet.storage_inventory, _missing_item_id) > 0
            ) {
                _stock_ready = true;
                assigned_pet.current_case.stock_blocked = false;
            }
        }

        if (_stock_ready) {
            path_end();

            if (mp_grid_path(
                global.ai_grid,
                my_path,
                x,
                y,
                doctor_target_x,
                doctor_target_y,
                true
            )) {
                path_set_kind(my_path, 1);
                path_start(my_path, p_move_speed, path_action_stop, true);
                is_walking = true;
            } else {
                move_towards_point(
                    doctor_target_x,
                    doctor_target_y,
                    p_move_speed
                );
                is_walking = true;
            }

            doctor_state = "going_to_doctor_point";
        }
    }
    break;
}


// ═══════════════════════════════════════════════════════════════
// 4. ОБЫЧНОЕ ПЕРЕМЕЩЕНИЕ И КЛИК ПО СКЛАДУ
// ═══════════════════════════════════════════════════════════════

var _player_can_free_move = (
    doctor_state == "idle"
    || doctor_state == "manual_procedure_restock"
);

// Пакет №141: на телефоне клик по миру — только после ЧИСТОГО тапа
// (палец поднялся без движения). Драг/щипок камеры персонажа не двигают.
var _click_now = false;
var _click_x = mouse_x;
var _click_y = mouse_y;

if (
    variable_global_exists("touch_tap_confirmed")
    && global.touch_tap_confirmed
) {
    global.touch_tap_confirmed = false;
    _click_now = true;

    if (variable_global_exists("touch_tap_wx")) _click_x = global.touch_tap_wx;
    if (variable_global_exists("touch_tap_wy")) _click_y = global.touch_tap_wy;
}

if (
    mouse_check_button_pressed(mb_left)
    && !device_mouse_check_button_pressed(0, mb_left)
) {
    _click_now = true;
    _click_x = mouse_x;
    _click_y = mouse_y;
}

if (_click_now) {
    // Отмена pending-приёма уже обработана в начале события, до switch.
    // После неё этот же клик может сразу построить новый маршрут.
    if (_pending_service_cancelled_this_step) {
        _player_can_free_move = true;
    }

    if (global.radial_open && variable_global_exists("radial_panel_x1")) {
        var _mouse_gui_x = device_mouse_x_to_gui(0);
        var _mouse_gui_y = device_mouse_y_to_gui(0);

        if (point_in_rectangle(
            _mouse_gui_x,
            _mouse_gui_y,
            global.radial_panel_x1,
            global.radial_panel_y1,
            global.radial_panel_x2,
            global.radial_panel_y2
        )) {
            exit;
        }

        exit;
    }

    if (world_clicks_blocked()) exit;

    if (_player_can_free_move) {
        var _storage_target = noone;
        // Пакет №83: клик по главному складу считается по всему стеллажу.
        var _main_storage_hit = storage_main_hit_at_point(_click_x, _click_y);
        var _cabinet_hit = instance_position(_click_x, _click_y, obj_storage_cabinet);

        if (instance_exists(_main_storage_hit)) _storage_target = _main_storage_hit;
        if (instance_exists(_cabinet_hit)) _storage_target = _cabinet_hit;

        if (instance_exists(_storage_target)) {
            path_end();
            is_walking = false;
            interact_target = _storage_target;

            if (point_distance(x, y, _storage_target.x, _storage_target.y) >= 50) {
                var _target_x = variable_instance_exists(_storage_target, "interact_x")
                    ? _storage_target.interact_x
                    : _storage_target.x;
                var _target_y = variable_instance_exists(_storage_target, "interact_y")
                    ? _storage_target.interact_y
                    : _storage_target.y + 40;

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
                    instance_create_layer(
                        _target_x,
                        _target_y,
                        "Instances",
                        obj_click_effect
                    );
                }
            }

            exit;
        }

        var _clicked_interactive_actor = (
            global.hover_target != noone
            && instance_exists(global.hover_target)
        );

        if (!_clicked_interactive_actor || _pending_service_cancelled_this_step) {
            interact_target = noone;

            if (mp_grid_path(
                global.ai_grid,
                my_path,
                x,
                y,
                _click_x,
                _click_y,
                true
            )) {
                path_set_kind(my_path, 1);
                path_start(my_path, p_move_speed, path_action_stop, true);
                is_walking = true;

                instance_create_layer(
                    _click_x,
                    _click_y,
                    "Instances",
                    obj_click_effect
                );
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 5. ПРИБЫТИЕ К СКЛАДУ И ОТКРЫТИЕ РАДИАЛЬНОГО МЕНЮ
// ═══════════════════════════════════════════════════════════════

if (_player_can_free_move) {
    if (instance_exists(interact_target)) {
        var _distance_to_target = point_distance(
            x,
            y,
            interact_target.x,
            interact_target.y
        );

        if (
            _distance_to_target < 50
            || (!is_walking && _distance_to_target < 70)
        ) {
            path_end();
            is_walking = false;

            global.radial_open = true;
            global.radial_target = interact_target;
            global.ui_block_world_click = true;

            interact_target = noone;
        }
    }
} else {
    interact_target = noone;
    global.radial_open = false;
    global.radial_target = noone;
    global.ui_block_world_click = false;
}

if (!global.radial_open) {
    global.ui_block_world_click = false;
}


// ═══════════════════════════════════════════════════════════════
// 6. АНИМАЦИИ ИГРОКА
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "_idle_anim_timer")) _idle_anim_timer = 0;
if (!variable_instance_exists(id, "_work_anim_timer")) _work_anim_timer = 0;
if (!variable_instance_exists(id, "_idle_delay_timer")) _idle_delay_timer = 0;

var _player_really_moving = (
    is_walking
    || (path_index != -1 && path_position < 1)
    || abs(x - xprevious) > 0.1
    || abs(y - yprevious) > 0.1
);

var _player_is_working = (
    doctor_state == "manual_exam"
    || doctor_state == "manual_procedure"
    || doctor_state == "manual_registering"
    || doctor_state == "manual_payment"
);

var _player_is_carrying = (
    global.player_carry_item != ""
    && global.player_carry_qty > 0
);

if (!_player_is_working) {
    _work_anim_timer = 0;
}

if (_player_is_working && sprite_exists(spr_human_FR_work)) {
    _work_anim_timer += 1;

    sprite_index = spr_human_FR_work;
    image_speed = 0;
    image_index = floor(_work_anim_timer / 6)
        mod max(1, sprite_get_number(spr_human_FR_work));

    path_end();
    is_walking = false;
    _idle_anim_timer = 0;
    _idle_delay_timer = 0;
}
else if (
    _player_is_carrying
    && sprite_exists(spr_human_FR_carry)
    && sprite_exists(spr_human_B_carry)
) {
    var _back_view = string_pos(
        "_B_",
        sprite_get_name(sprite_index)
    ) > 0;

    sprite_index = _back_view
        ? spr_human_B_carry
        : spr_human_FR_carry;

    image_speed = _player_really_moving ? 1 : 0;

    if (!_player_really_moving) {
        image_index = 0;
    }

    _idle_anim_timer = 0;
    _work_anim_timer = 0;
    _idle_delay_timer = 0;
}
else if (
    !_player_really_moving
    && sprite_exists(spr_human_FR_idle)
) {
    _idle_delay_timer += 1;

    if (_idle_delay_timer >= 3) {
        _idle_anim_timer += 1;

        sprite_index = spr_human_FR_idle;
        image_speed = 0;
        image_index = floor(_idle_anim_timer / 10)
            mod max(1, sprite_get_number(spr_human_FR_idle));

        _work_anim_timer = 0;
        is_walking = false;
    }
}


// ═══════════════════════════════════════════════════════════════
// 7. РАЗВОРОТ ИГРОКА К СТОЙКЕ И ГЛУБИНА РУК
// ═══════════════════════════════════════════════════════════════

if (
    (doctor_state == "manual_registering" || doctor_state == "manual_payment")
    && instance_exists(registration_target_desk)
) {
    var _desk = registration_target_desk;
    var _look_x = _desk.queue_start_x;
    var _look_y = _desk.queue_start_y;

    if (instance_exists(registration_target_owner)) {
        _look_x = registration_target_owner.x;
        _look_y = registration_target_owner.y;
    }

    var _look_dx = _look_x - x;
    var _look_dy = _look_y - y;
    var _back_work_sprite = asset_get_index("spr_human_B_work");
    var _has_back_work = (
        _back_work_sprite != -1
        && sprite_exists(_back_work_sprite)
    );

    if (_look_dy < 0) {
        if (_has_back_work) {
            sprite_index = _back_work_sprite;
            image_index = floor(_work_anim_timer / 6)
                mod max(1, sprite_get_number(_back_work_sprite));
        } else {
            sprite_index = spr_human_B_walk;
            image_index = 0;
        }

        pFacing = (abs(_look_dx) > 1 && _look_dx > 0) ? -1 : 1;
    } else {
        sprite_index = spr_human_FR_work;
        image_index = floor(_work_anim_timer / 6)
            mod max(1, sprite_get_number(spr_human_FR_work));
        pFacing = (abs(_look_dx) > 1 && _look_dx < 0) ? -1 : 1;
    }

    image_speed = 0;
    image_xscale = abs(image_xscale) * pFacing;

    // Рабочая анимация и руки рисуются поверх стойки.
    depth = _desk.depth - 3;
} else {
    depth = -y;
}
