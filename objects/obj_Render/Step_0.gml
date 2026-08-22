/// Step obj_Render
/// @description Игровое время, поток клиентов и камера с единым UI-блокировщиком.
/// Пакет №100: приближение камеры можно сделать ближе (render_zoom_min_factor).
/// Пакет №114: кнопка W (+15 000 денег) и полный склад при старте.
/// Пакет №129: склад полный (render_seed_storage_full = true).
/// Пакет №130: фикс кадрового тайминга на телефоне (sleep_margin).
/// Пакет №131: принудительное выключение VSync (display_reset).
/// Пакет №132: страховка скорости 60.
/// Пакет №135: оптимизация логики — restock_scan_needs раз в 15 кадров.
/// Пакет №141: тап по миру отделён от драга/щипка камеры (touch).
/// Пакет №142: после щипка тап не срабатывает при быстром отпускании пальцев.
/// Пакет №158: на телефоне tm_sleep вместо tm_countvsyncs (фикс запирания FPS=30).


// ═══════════════════════════════════════════════════════════════
// 0.0 КАДРОВЫЙ ТАЙМИНГ (пакеты №130–132, №158)
// Симптом: FPS ≈ 30 при REAL ≈ 50–60. Это не «тяжёлая картинка», а
// запирание vsync: кадр чуть не успевает к 16.7 мс, движок ждёт
// следующий vsync и падает ровно на 30.
//
// №132 ставил tm_countvsyncs — на телефоне это как раз даёт половину
// частоты. №158 на Android/iOS переключает на tm_sleep (кадры идут
// своим ходом, FPS едет за REAL), vsync выключен, цель 60.
//
// Откат:
//   render_timing_method = tm_countvsyncs;  // как в №132
//   render_sleep_margin  = 1;
//   render_vsync_off     = true;
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "render_timing_phone")) {
    render_timing_phone = (os_type == os_android || os_type == os_ios);
}

if (!variable_instance_exists(id, "render_sleep_margin")) {
    // Телефон: 4 мс — не проспать кадр. ПК: 1 мс, как в №130.
    render_sleep_margin = render_timing_phone ? 4 : 1;
}

if (!variable_instance_exists(id, "render_vsync_off")) {
    render_vsync_off = true;
}

if (!variable_instance_exists(id, "render_timing_method")) {
    render_timing_method = render_timing_phone ? tm_sleep : tm_countvsyncs;
}

if (!variable_instance_exists(id, "render_speed_safeguard")) {
    render_speed_safeguard = true;
}

if (!variable_instance_exists(id, "render_timing_applied")) {
    render_timing_applied = false;
}

if (!variable_instance_exists(id, "render_app_focus")) {
    render_app_focus = window_has_focus();
}

var _render_focus_now = window_has_focus();
if (_render_focus_now && !render_app_focus) {
    // Возврат из фона: Android часто сбрасывает тайминг.
    render_timing_applied = false;
}
render_app_focus = _render_focus_now;

if (!render_timing_applied) {
    render_timing_applied = true;

    // Сначала сброс дисплея (vsync выкл), потом метод и sleep.
    if (render_vsync_off) {
        display_reset(0, false);
    }

    display_set_timing_method(render_timing_method);
    display_set_sleep_margin(render_sleep_margin);
    sleep_margin = render_sleep_margin;

    if (render_speed_safeguard) {
        game_set_speed(60, gamespeed_fps);
    }

    global.time_step_frames = max(1, game_get_speed(gamespeed_fps));

    show_debug_message(
        "[TIMING 158] method="
        + string(display_get_timing_method())
        + " sleep="
        + string(display_get_sleep_margin())
        + " hz="
        + string(display_get_frequency())
        + " speed="
        + string(game_get_speed(gamespeed_fps))
        + " phone="
        + string(render_timing_phone)
    );
}


// ═══════════════════════════════════════════════════════════════
// 0. СКЛАД ПРИ СТАРТЕ (пакет №129: полный, ёмкость полки из скрипта)
// Каждый препарат заполняется до storage_shelf_box_max().
// Чтобы склад стартовал пустым — поставь render_seed_storage_full = false.
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "render_seed_storage_full")) {
    render_seed_storage_full = true;    // true = полный склад (до ёмкости), false = пустой
}

if (!variable_instance_exists(id, "render_storage_seeded")) {
    render_storage_seeded = true;

    if (render_seed_storage_full) {
        var _full = storage_shelf_box_max();

        if (
            !variable_global_exists("inventory_main")
            || !is_struct(global.inventory_main)
        ) {
            global.inventory_main = {};
        }

        if (variable_global_exists("item_ids") && is_array(global.item_ids)) {
            for (var _si = 0; _si < array_length(global.item_ids); _si++) {
                var _s_item_id = global.item_ids[_si];
                var _s_cur = inventory_get_amount(
                    global.inventory_main,
                    _s_item_id
                );
                var _s_need = _full - _s_cur;

                if (_s_need > 0) {
                    inventory_add_amount(
                        global.inventory_main,
                        _s_item_id,
                        _s_need
                    );
                }
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 0.1 СКАНИРОВАНИЕ ПОТРЕБНОСТЕЙ В ПОПОЛНЕНИИ СКЛАДОВ
// Пакет №135: сканируем раз в 15 кадров (было — каждый кадр). Потребности
// пополнения не меняются 60 раз в секунду, а каждый кадр это заметная
// работа по всем шкафам и препаратам.
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "render_restock_tick")) render_restock_tick = 0;
render_restock_tick += 1;

if (render_restock_tick >= 15) {
    render_restock_tick = 0;
    restock_scan_needs();
}


// ═══════════════════════════════════════════════════════════════
// 1. ОБНОВЛЕНИЕ ИГРОВОГО ВРЕМЕНИ
// ═══════════════════════════════════════════════════════════════

if (!global.time_paused) {
    time_accumulator += global.time_speed;

    while (time_accumulator >= global.time_step_frames) {
        time_accumulator -= global.time_step_frames;
        global.game_minute += 1;

        if (global.game_minute >= 60) {
            global.game_minute = 0;
            global.game_hour += 1;
        }

        if (global.game_hour >= 24) {
            global.game_hour = 0;
            global.game_day += 1;

            global.week_day_index += 1;
            if (global.week_day_index > 6) global.week_day_index = 0;

            global.calendar_day += 1;

            if (global.calendar_day > 30) {
                global.calendar_day = 1;
                global.calendar_month += 1;

                if (global.calendar_month > 12) {
                    global.calendar_month = 1;
                    global.calendar_year += 1;
                }
            }
        }
    }
}

var _now_minute = global.game_hour * 60 + global.game_minute;
var _live_visitors = active_visitors_live_count();

if (followup_spawn_cooldown > 0) {
    followup_spawn_cooldown -= 1;
}


// ═══════════════════════════════════════════════════════════════
// 1.5. НОЧНОЕ ЗАКРЫТИЕ КЛИНИКИ В 00:00
// Все владельцы уходят, сотрудники остаются.
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "render_last_close_day")) {
    render_last_close_day = -1;
}

if (_now_minute == 0 && render_last_close_day != global.game_day) {
    render_last_close_day = global.game_day;

    random_arrival_pending = false;
    random_arrival_cooldown = 0;
    followup_spawn_cooldown = 0;

    // В конце завершившегося дня пересчитываем зарплаты по текущим
    // навыкам сотрудников и списываем их с баланса клиники один раз.
    finance_payroll_process_day(global.game_day);

    if (variable_global_exists("wait_spots")) {
        for (var _ws = 0; _ws < array_length(global.wait_spots); _ws++) {
            global.wait_spots[_ws].occupied_by = noone;
        }
    }

    if (instance_exists(obj_reception_desk)) {
        with (obj_reception_desk) {
            if (variable_instance_exists(id, "queue_list")) {
                ds_list_clear(queue_list);
            }
            alarm[0] = 1;
        }
    }

    if (instance_exists(obj_monitor)) {
        with (obj_monitor) {
            if (variable_instance_exists(id, "monitor_list")) {
                monitor_list = [];
            }
        }
    }

    if (instance_exists(obj_staff_admin)) {
        with (obj_staff_admin) {
            reception_client = noone;

            if (
                reception_state == "going_to_register_spot"
                || reception_state == "registering"
            ) {
                reception_state = "returning";
                reception_timer = 0;
            }
        }
    }

    if (instance_exists(obj_table)) {
        with (obj_table) {
            table_busy = false;
            assigned_owner = noone;
            assigned_doctor = noone;
            assigned_pet = noone;
        }
    }

    if (instance_exists(obj_table_1)) {
        with (obj_table_1) {
            table_busy = false;
            assigned_owner = noone;
            assigned_doctor = noone;
            assigned_pet = noone;
        }
    }

    if (instance_exists(obj_player)) {
        with (obj_player) {
            if (variable_instance_exists(id, "player_reset_registration")) {
                player_reset_registration();
            }

            if (variable_instance_exists(id, "player_reset_exam")) {
                player_reset_exam();
            }

            service_mode = "";
            doctor_state = "idle";
            assigned_owner = noone;
            assigned_table = noone;
            assigned_pet = noone;
            registration_target_owner = noone;
            registration_target_desk = noone;

            path_end();
            is_walking = false;
        }
    }

    if (instance_exists(obj_staff_doctor)) {
        with (obj_staff_doctor) {
            assigned_owner = noone;
            assigned_table = noone;
            assigned_pet = noone;
            doctor_state = "idle";
            exam_timer = 0;
            exam_timer_max = 0;

            path_end();
            is_walking = false;
        }
    }

    if (instance_exists(obj_UI_Tablet)) {
        with (obj_UI_Tablet) {
            visible = false;
            target_id = noone;
        }
    }

    if (instance_exists(obj_owner)) {
        with (obj_owner) {
            queue_slot = -1;
            registered = false;
            wait_spot_index = -1;

            assigned_doctor = noone;
            assigned_table = noone;

            registration_in_progress = false;
            registration_timer = 0;
            registration_timer_max = 0;
            registration_actor_name = "";

            if (
                variable_instance_exists(id, "my_pet")
                && instance_exists(my_pet)
            ) {
                with (my_pet) {
                    path_end();
                    is_walking = false;
                    assigned_doctor = noone;
                    assigned_table = noone;
                    state = "follow_owner";
                    follow_offset_x = 30;
                    follow_offset_y = 20;
                }
            }

            leave_target_x = global.clinic_exit_x;
            leave_target_y = global.clinic_exit_y;
            state = "leaving_clinic";

            path_end();

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
                path_start(
                    my_path,
                    p_move_speed,
                    path_action_stop,
                    true
                );
                is_walking = true;
            }
            else {
                instance_destroy();
            }
        }

        global.daily_stats.reputation_delta = global.clinic_reputation
            - global.daily_stats.reputation_start;
        global.daily_stats.day_num = global.game_day;
        global.daily_stats.week_day = global.week_day_index;
        global.daily_stats.calendar_day = global.calendar_day;
        global.daily_stats.calendar_month = global.calendar_month;
        global.day_summary_open = true;
        global.day_summary_ready = false;
        global.day_summary_wait_frames = room_speed * 2;
        global.time_paused = true;
    }

    if (instance_exists(obj_UI_HUD)) {
        with (obj_UI_HUD) {
            show_notice(
                "КЛИНИКА ЗАКРЫТА",
                "Наступила полночь. Все владельцы покинули клинику.",
                room_speed * 4
            );
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 2. ЧИСТИМ ССЫЛКИ НА КАНДИДАТА
// ═══════════════════════════════════════════════════════════════

if (!instance_exists(global.current_candidate)) {
    global.current_candidate = noone;
}

if (!instance_exists(global.selected_candidate)) {
    global.selected_candidate = noone;
}

if (instance_exists(global.current_candidate)) {
    if (global.current_candidate.candidate_state == "waiting_offer") {
        if (global.selected_candidate == noone) {
            global.selected_candidate = global.current_candidate;
        }
    }
    else {
        if (global.selected_candidate == global.current_candidate) {
            global.selected_candidate = noone;
        }
    }
}
else {
    if (
        global.selected_candidate != noone
        && !instance_exists(global.selected_candidate)
    ) {
        global.selected_candidate = noone;
    }
}


// ═══════════════════════════════════════════════════════════════
// 3. DEBUG: ПРИНУДИТЕЛЬНО ПОЗВАТЬ КАНДИДАТА
// ═══════════════════════════════════════════════════════════════

if (keyboard_check_pressed(ord("N"))) {
    if (
        global.clinic_hiring_open
        && global.current_candidate == noone
    ) {
        spawn_candidate();
    }
}


// ═══════════════════════════════════════════════════════════════
// 3.5 DEBUG: КНОПКА W — +15 000 ДЕНЕГ (пакет №114)
// ═══════════════════════════════════════════════════════════════

if (keyboard_check_pressed(ord("W"))) {
    global.clinic_money += 15000;

    if (instance_exists(obj_UI_HUD)) {
        var _hud_money = instance_find(obj_UI_HUD, 0);

        if (
            instance_exists(_hud_money)
            && variable_instance_exists(_hud_money, "show_notice")
        ) {
            with (_hud_money) {
                show_notice(
                    "ДЕНЬГИ",
                    "+ $15 000",
                    room_speed * 2
                );
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 4. СЛУЧАЙНОЕ ПОЯВЛЕНИЕ КАНДИДАТА В ТЕЧЕНИЕ ДНЯ
// ═══════════════════════════════════════════════════════════════

if (
    global.clinic_hiring_open
    && global.current_candidate == noone
) {
    var _cand_now = global.game_hour * 60 + global.game_minute;

    if (
        global.game_day > global.next_candidate_day
        || (
            global.game_day == global.next_candidate_day
            && _cand_now >= global.next_candidate_minute
        )
    ) {
        spawn_candidate();
    }
}


// ═══════════════════════════════════════════════════════════════
// 5. ПОВТОРНЫЕ ВИЗИТЫ
// С 10:00, пока не закончились повторники на сегодня.
// ═══════════════════════════════════════════════════════════════

var _pending_followups = followup_count_pending_today();

if (
    _now_minute >= global.followup_morning_start
    && _now_minute < global.followup_morning_end
) {
    if (
        _pending_followups > 0
        && _live_visitors < global.max_active_visitors
        && followup_spawn_cooldown <= 0
    ) {
        var _spawned_followup = spawn_next_followup_today();

        if (instance_exists(_spawned_followup)) {
            followup_spawn_cooldown = followup_spawn_interval_frames;

            _live_visitors = active_visitors_live_count();
            _pending_followups = followup_count_pending_today();

            if (instance_exists(obj_UI_HUD)) {
                with (obj_UI_HUD) {
                    show_notice(
                        "ПОВТОРНЫЙ ПРИЁМ",
                        "Прибыл постоянный клиент на контрольный визит.",
                        room_speed * 4
                    );
                }
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 6. НОВЫЕ СЛУЧАЙНЫЕ КЛИЕНТЫ
// Работают с 09:00 до 22:00.
// ═══════════════════════════════════════════════════════════════

var _clinic_open_for_random = (
    _now_minute >= global.clinic_day_start_minute
    && _now_minute < global.clinic_day_end_minute
);

if (!_clinic_open_for_random || _pending_followups > 0) {
    random_arrival_pending = false;
    random_arrival_cooldown = 0;
}
else {
    if (_live_visitors >= global.max_active_visitors) {
        random_arrival_pending = false;
        random_arrival_cooldown = 0;
    }
    else {
        if (!random_arrival_pending) {
            schedule_next_random_arrival();
        }
        else {
            random_arrival_cooldown -= 1;

            if (random_arrival_cooldown <= 0) {
                var _spawned_random = spawn_owner();

                random_arrival_pending = false;
                random_arrival_cooldown = 0;

                if (instance_exists(_spawned_random)) {
                    global.daily_random_spawned_today += 1;

                    if (instance_exists(obj_UI_HUD)) {
                        with (obj_UI_HUD) {
                            show_notice(
                                "НОВЫЙ КЛИЕНТ",
                                "В клинику пришёл новый клиент.",
                                room_speed * 4
                            );
                        }
                    }
                }

                _live_visitors = active_visitors_live_count();
                _pending_followups = followup_count_pending_today();
                _now_minute = global.game_hour * 60
                    + global.game_minute;

                _clinic_open_for_random = (
                    _now_minute >= global.clinic_day_start_minute
                    && _now_minute < global.clinic_day_end_minute
                );

                if (
                    _clinic_open_for_random
                    && _pending_followups <= 0
                    && _live_visitors < global.max_active_visitors
                ) {
                    schedule_next_random_arrival();
                }
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 7. КАМЕРА / DRAG ПРАВОЙ КНОПКОЙ
// ═══════════════════════════════════════════════════════════════

var _view_w = camera_get_view_width(view_camera[0]);
var _view_h = camera_get_view_height(view_camera[0]);
var _cam_x = camera_get_view_x(view_camera[0]);
var _cam_y = camera_get_view_y(view_camera[0]);
var _mx_gui = device_mouse_x_to_gui(0);
var _my_gui = device_mouse_y_to_gui(0);
var _gui_w = max(1, display_get_gui_width());
var _gui_h = max(1, display_get_gui_height());
var _world_per_gui_x = _view_w / _gui_w;
var _world_per_gui_y = _view_h / _gui_h;
var _world_input_blocked = world_camera_input_blocked();

// Открытие любой модальной панели немедленно завершает drag камеры.
if (_world_input_blocked) {
    camera_drag_active = false;
}

if (mouse_check_button_pressed(mb_right)) {
    if (!_world_input_blocked) {
        camera_mode = "free";
        camera_focus_target = noone;
        camera_focus_timer = 0;

        camera_drag_active = true;
        camera_drag_start_mouse_x = _mx_gui;
        camera_drag_start_mouse_y = _my_gui;
        camera_drag_start_view_x = _cam_x;
        camera_drag_start_view_y = _cam_y;
    }
}

if (mouse_check_button_released(mb_right)) {
    camera_drag_active = false;
}

if (camera_mode == "focus_staff" && !camera_drag_active) {
    if (
        instance_exists(camera_focus_target)
        && camera_focus_timer > 0
    ) {
        camera_focus_timer -= 1;

        var _target_x = camera_focus_target.x - _view_w * 0.5;
        var _target_y = camera_focus_target.y - _view_h * 0.5;

        _target_x = clamp(
            _target_x,
            0,
            max(0, room_width - _view_w)
        );
        _target_y = clamp(
            _target_y,
            0,
            max(0, room_height - _view_h)
        );

        _cam_x = lerp(_cam_x, _target_x, camera_follow_lerp);
        _cam_y = lerp(_cam_y, _target_y, camera_follow_lerp);

        camera_set_view_pos(
            view_camera[0],
            floor(_cam_x),
            floor(_cam_y)
        );
    }
    else {
        camera_mode = "free";
        camera_focus_target = noone;
        camera_focus_timer = 0;
    }
}

if (camera_mode == "free" && camera_drag_active) {
    var _dx_gui = _mx_gui - camera_drag_start_mouse_x;
    var _dy_gui = _my_gui - camera_drag_start_mouse_y;

    var _target_cam_x = camera_drag_start_view_x
        - (_dx_gui * _world_per_gui_x * camera_drag_sensitivity);
    var _target_cam_y = camera_drag_start_view_y
        - (_dy_gui * _world_per_gui_y * camera_drag_sensitivity);

    _target_cam_x = clamp(
        _target_cam_x,
        0,
        max(0, room_width - _view_w)
    );
    _target_cam_y = clamp(
        _target_cam_y,
        0,
        max(0, room_height - _view_h)
    );

    camera_set_view_pos(
        view_camera[0],
        floor(_target_cam_x),
        floor(_target_cam_y)
    );
}


// ═══════════════════════════════════════════════════════════════
// 8. ЗУМ КАМЕРЫ
// Колесо полностью принадлежит UI, пока открыта любая панель.
// ═══════════════════════════════════════════════════════════════

// Пакет №100: насколько близко можно приближаться.
// 1.0 = как было; меньше = ближе (0.5 ≈ в 2 раза ближе).
if (!variable_instance_exists(id, "render_zoom_min_factor")) {
    render_zoom_min_factor = 0.5;
}

var _wheel_changed = false;

if (!_world_input_blocked) {
    if (mouse_wheel_up()) {
        zoom_target -= 0.1;
        _wheel_changed = true;
    }

    if (mouse_wheel_down()) {
        zoom_target += 0.1;
        _wheel_changed = true;
    }
}

zoom_target = clamp(
    zoom_target,
    zoom_min * render_zoom_min_factor,
    zoom_max
);

if (_wheel_changed) {
    var _old_w = camera_get_view_width(view_camera[0]);
    var _old_h = camera_get_view_height(view_camera[0]);
    var _old_x = camera_get_view_x(view_camera[0]);
    var _old_y = camera_get_view_y(view_camera[0]);

    zoom_anchor_x = _old_x + _old_w * 0.5;
    zoom_anchor_y = _old_y + _old_h * 0.5;
    zoom_animating = true;
}

if (abs(zoom_level - zoom_target) > zoom_epsilon) {
    zoom_level = lerp(zoom_level, zoom_target, zoom_speed);
    zoom_animating = true;
}
else {
    zoom_level = zoom_target;
    zoom_animating = false;
}

if (zoom_animating) {
    var _new_w = cam_base_w * zoom_level;
    var _new_h = cam_base_h * zoom_level;

    camera_set_view_size(view_camera[0], _new_w, _new_h);

    var _new_x = zoom_anchor_x - _new_w * 0.5;
    var _new_y = zoom_anchor_y - _new_h * 0.5;

    _new_x = clamp(_new_x, 0, max(0, room_width - _new_w));
    _new_y = clamp(_new_y, 0, max(0, room_height - _new_h));

    camera_set_view_pos(
        view_camera[0],
        floor(_new_x),
        floor(_new_y)
    );
}


// ═══════════════════════════════════════════════════════════════
// 8.5. СЕНСОРНОЕ УПРАВЛЕНИЕ КАМЕРОЙ
// Один палец — drag камеры, два — pinch. Под UI оба жеста отключены.
// ═══════════════════════════════════════════════════════════════

if (!variable_struct_exists(global, "__touch_init_done")) {
    global.__touch_init_done = true;
    global.touch_pinch_active = false;
    global.touch_drag_active = false;
    global.touch_tap_pending = false;
    global.touch_tap_moved = false;
    global.touch_tap_gx = 0;
    global.touch_tap_gy = 0;
    global.touch_tap_wx = 0;
    global.touch_tap_wy = 0;
    global.touch_tap_confirmed = false;
    global.touch_suppress_tap = false;
    global.touch_pinch_start_dist = 0;
    global.touch_pinch_start_zoom = 1;
    global.touch_pinch_anchor_wx = 0;
    global.touch_pinch_anchor_wy = 0;
    global.touch_pinch_anchor_gx = 0;
    global.touch_pinch_anchor_gy = 0;
    global.touch_drag_start_gx = 0;
    global.touch_drag_start_gy = 0;
    global.touch_drag_start_vx = 0;
    global.touch_drag_start_vy = 0;
}

var _touch_can_drag = !_world_input_blocked;
var _t0x = device_mouse_x_to_gui(0);
var _t0y = device_mouse_y_to_gui(0);
var _t0_down = device_mouse_check_button(0, mb_left);
var _t1x = device_mouse_x_to_gui(1);
var _t1y = device_mouse_y_to_gui(1);
var _t1_down = device_mouse_check_button(1, mb_left);

if (_world_input_blocked || mouse_check_button(mb_right)) {
    global.touch_pinch_active = false;
    global.touch_drag_active = false;
}
else {
    // ───────────────────────────────────────────────────────────
    // PINCH: ДВА ПАЛЬЦА
    // ───────────────────────────────────────────────────────────

    if (_t0_down && _t1_down && _touch_can_drag) {
        if (global.touch_drag_active) {
            global.touch_drag_active = false;
        }

        var _mid_gx = (_t0x + _t1x) * 0.5;
        var _mid_gy = (_t0y + _t1y) * 0.5;

        if (!global.touch_pinch_active) {
            global.touch_pinch_active = true;

            // Пакет №141: щипок (два пальца) — это не тап.
            global.touch_tap_pending = false;
            global.touch_tap_moved = true;
            global.touch_tap_confirmed = false;

            var _pinch_dx = _t1x - _t0x;
            var _pinch_dy = _t1y - _t0y;
            global.touch_pinch_start_dist = max(
                1,
                sqrt(
                    _pinch_dx * _pinch_dx
                    + _pinch_dy * _pinch_dy
                )
            );
            global.touch_pinch_start_zoom = zoom_target;

            var _start_cam_x = camera_get_view_x(view_camera[0]);
            var _start_cam_y = camera_get_view_y(view_camera[0]);
            var _start_vw = camera_get_view_width(view_camera[0]);
            var _start_vh = camera_get_view_height(view_camera[0]);

            global.touch_pinch_anchor_gx = _mid_gx;
            global.touch_pinch_anchor_gy = _mid_gy;
            global.touch_pinch_anchor_wx = _start_cam_x
                + (_mid_gx / _gui_w) * _start_vw;
            global.touch_pinch_anchor_wy = _start_cam_y
                + (_mid_gy / _gui_h) * _start_vh;
        }
        else {
            var _pinch_dx = _t1x - _t0x;
            var _pinch_dy = _t1y - _t0y;
            var _cur_dist = max(
                1,
                sqrt(
                    _pinch_dx * _pinch_dx
                    + _pinch_dy * _pinch_dy
                )
            );
            var _ratio = global.touch_pinch_start_dist
                / _cur_dist;

            zoom_target = clamp(
                global.touch_pinch_start_zoom * _ratio,
                zoom_min * render_zoom_min_factor,
                zoom_max
            );

            var _pinch_new_w = cam_base_w * zoom_target;
            var _pinch_new_h = cam_base_h * zoom_target;
            var _shift_gx = _mid_gx
                - global.touch_pinch_anchor_gx;
            var _shift_gy = _mid_gy
                - global.touch_pinch_anchor_gy;

            var _pinch_x = global.touch_pinch_anchor_wx
                - (global.touch_pinch_anchor_gx / _gui_w)
                    * _pinch_new_w
                - (_shift_gx / _gui_w) * _pinch_new_w;
            var _pinch_y = global.touch_pinch_anchor_wy
                - (global.touch_pinch_anchor_gy / _gui_h)
                    * _pinch_new_h
                - (_shift_gy / _gui_h) * _pinch_new_h;

            _pinch_x = clamp(
                _pinch_x,
                0,
                max(0, room_width - _pinch_new_w)
            );
            _pinch_y = clamp(
                _pinch_y,
                0,
                max(0, room_height - _pinch_new_h)
            );

            zoom_level = zoom_target;
            camera_set_view_size(
                view_camera[0],
                _pinch_new_w,
                _pinch_new_h
            );
            camera_set_view_pos(
                view_camera[0],
                floor(_pinch_x),
                floor(_pinch_y)
            );
            zoom_animating = false;
        }
    }
    else {
        // Пакет №142: щипок закончился, но палец ещё на экране —
        // запрещаем тап, чтобы персонаж не пошёл при быстром отпускании.
        if (global.touch_pinch_active && (_t0_down || _t1_down)) {
            global.touch_suppress_tap = true;
        }

        global.touch_pinch_active = false;
    }

    // ───────────────────────────────────────────────────────────
    // DRAG: ОДИН ПАЛЕЦ
    // ───────────────────────────────────────────────────────────

    if (
        !global.touch_pinch_active
        && _touch_can_drag
        && _t0_down
        && !_t1_down
    ) {
        if (!global.touch_drag_active) {
            global.touch_drag_active = true;

            // Пакет №142: если это остаток щипка — тап не вооружаем.
            if (global.touch_suppress_tap) {
                global.touch_tap_pending = false;
                global.touch_tap_moved = true;
            } else {
                // Пакет №141: начинаем отличать тап от драга камеры.
                global.touch_tap_pending = true;
                global.touch_tap_moved = false;
                global.touch_tap_confirmed = false;
                global.touch_tap_gx = _t0x;
                global.touch_tap_gy = _t0y;
            }

            camera_mode = "free";
            camera_focus_target = noone;
            camera_focus_timer = 0;
            global.touch_drag_start_gx = _t0x;
            global.touch_drag_start_gy = _t0y;
            global.touch_drag_start_vx = camera_get_view_x(
                view_camera[0]
            );
            global.touch_drag_start_vy = camera_get_view_y(
                view_camera[0]
            );
        }
        else {
            // Пакет №141: палец сдвинулся — это драг камеры, тап отменяем.
            if (
                point_distance(
                    _t0x, _t0y,
                    global.touch_tap_gx, global.touch_tap_gy
                ) > 12
            ) {
                global.touch_tap_moved = true;
                global.touch_tap_pending = false;
            }

            var _touch_view_w = camera_get_view_width(
                view_camera[0]
            );
            var _touch_view_h = camera_get_view_height(
                view_camera[0]
            );
            var _wpgx = _touch_view_w / _gui_w;
            var _wpgy = _touch_view_h / _gui_h;
            var _touch_dx_gui = _t0x
                - global.touch_drag_start_gx;
            var _touch_dy_gui = _t0y
                - global.touch_drag_start_gy;
            var _sens = variable_global_exists(
                "camera_drag_sensitivity"
            )
                ? global.camera_drag_sensitivity
                : 1;
            var _touch_cam_x = global.touch_drag_start_vx
                - (_touch_dx_gui * _wpgx * _sens);
            var _touch_cam_y = global.touch_drag_start_vy
                - (_touch_dy_gui * _wpgy * _sens);

            _touch_cam_x = clamp(
                _touch_cam_x,
                0,
                max(0, room_width - _touch_view_w)
            );
            _touch_cam_y = clamp(
                _touch_cam_y,
                0,
                max(0, room_height - _touch_view_h)
            );

            camera_set_view_pos(
                view_camera[0],
                floor(_touch_cam_x),
                floor(_touch_cam_y)
            );
        }
    }
    else {
        global.touch_drag_active = false;
    }

    // Пакет №141: палец поднялся без движения — подтверждаем тап по миру.
    // Пакет №142: после щипка тап не срабатывает, пока не подняты все пальцы.
    if (!_t0_down && !_t1_down) {
        global.touch_suppress_tap = false;
    }

    if (
        !_t0_down
        && !_t1_down
        && global.touch_tap_pending
        && !global.touch_tap_moved
        && !global.touch_suppress_tap
    ) {
        global.touch_tap_wx = camera_get_view_x(view_camera[0])
            + (_t0x / max(1, _gui_w)) * camera_get_view_width(view_camera[0]);
        global.touch_tap_wy = camera_get_view_y(view_camera[0])
            + (_t0y / max(1, _gui_h)) * camera_get_view_height(view_camera[0]);
        global.touch_tap_confirmed = true;
        global.touch_tap_pending = false;
    }
}


// ═══════════════════════════════════════════════════════════════
// 9. НОВЫЙ ДЕНЬ — СБРОС ДНЕВНОГО ПОТОКА
// ═══════════════════════════════════════════════════════════════

if (render_last_day != global.game_day) {
    render_last_day = global.game_day;
    followup_spawn_cooldown = 0;
    random_arrival_pending = false;
    random_arrival_cooldown = 0;
    global.daily_random_spawned_today = 0;
    schedule_daily_random_visits();

    if (variable_struct_exists(global, "staff_daily_recharge")) {
        global.staff_daily_recharge();
    }

    if (!global.day_summary_open) {
        global.daily_stats.paid_visits = 0;
        global.daily_stats.earned_money = 0;
        global.daily_stats.spent_money = 0;
        global.daily_stats.salary_expense = 0;
        global.daily_stats.new_diagnosed = 0;
        global.daily_stats.procedures_done = 0;
        global.daily_stats.cured = 0;
        global.daily_stats.followups_scheduled = 0;
        global.daily_stats.reputation_start = global.clinic_reputation;
        global.daily_stats.reputation_delta = 0;
        global.daily_stats.day_start_money = global.clinic_money;
    }
}

if (global.day_summary_open) {
    if (global.day_summary_wait_frames > 0) {
        global.day_summary_wait_frames -= 1;

        if (global.day_summary_wait_frames <= 0) {
            global.day_summary_ready = true;
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 10. ЕДИНАЯ СОВМЕСТИМАЯ БЛОКИРОВКА МИРА
// Старый код больше не сбрасывает флаг только потому, что radial закрыт.
// ═══════════════════════════════════════════════════════════════

var _ui_blocks_world = world_clicks_blocked();
global.ui_block_world_click = _ui_blocks_world;

if (_ui_blocks_world) {
    global.hover_target = noone;
}
