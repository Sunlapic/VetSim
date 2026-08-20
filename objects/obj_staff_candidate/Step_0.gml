/// Step obj_staff_candidate
/// @description Выбор кандидата, движение по состояниям и лимит времени ожидания.

event_inherited();

var _world_click_blocked = world_clicks_blocked();


// ═══════════════════════════════════════════════════════════════
// 1. ОТКРЫТИЕ КОМПАКТНОЙ КАРТОЧКИ
// ═══════════════════════════════════════════════════════════════

if (
    candidate_state == "waiting_offer"
    && is_hovered
    && mouse_check_button_pressed(mb_left)
    && !_world_click_blocked
) {
    global.selected_candidate = id;

    // Старую огромную панель HUD не открываем.
    if (instance_exists(obj_UI_HUD)) {
        with (obj_UI_HUD) {
            hiring_panel_open = false;
            clinic_panel_open = false;
            clients_panel_open = false;
            staff_panel_open = false;
            finance_panel_open = false;
        }
    }

    var _candidate_ui = instance_exists(obj_UI_CandidateCard)
        ? instance_find(obj_UI_CandidateCard, 0)
        : instance_create_layer(0, 0, "Instances", obj_UI_CandidateCard);

    if (instance_exists(_candidate_ui)) {
        _candidate_ui.target_candidate = id;
        _candidate_ui.visible = true;
    }
}


// ═══════════════════════════════════════════════════════════════
// 2. СОСТОЯНИЯ
// ═══════════════════════════════════════════════════════════════

switch (candidate_state) {
    case "coming_in":
        if (
            candidate_target_ready
            && point_distance(x, y, candidate_wait_x, candidate_wait_y) <= 10
        ) {
            path_end();
            is_walking = false;
            candidate_state = "waiting_offer";

            // Пакет №66: час ожидания начинает отсчитываться,
            // когда кандидат встал на точку.
            candidate_wait_reset_timer(id);
        }
    break;

    case "waiting_offer":
        path_end();
        is_walking = false;

        // Страховка: если таймер ещё не запущен (например, кандидат
        // сразу телепортировался в точку из Alarm 0), запускаем его.
        if (
            !variable_instance_exists(id, "candidate_wait_timer_active")
            || !candidate_wait_timer_active
        ) {
            candidate_wait_reset_timer(id);
        }

        // Время ожидания вышло — кандидат уходит, как при отказе.
        if (candidate_wait_remaining_minutes(id) <= 0) {
            var _candidate_name = char_name;

            // Закрываем карточку кандидата, если она открыта.
            if (instance_exists(obj_UI_CandidateCard)) {
                with (obj_UI_CandidateCard) {
                    if (target_candidate == other.id) {
                        target_candidate = noone;
                        visible = false;
                    }
                }
            }

            if (instance_exists(obj_UI_HUD)) {
                var _hud = instance_find(obj_UI_HUD, 0);

                _hud.show_notice(
                    "КАНДИДАТ УШЁЛ",
                    _candidate_name
                        + " не дождался решения и покинул клинику.",
                    max(1, game_get_speed(gamespeed_fps)) * 3
                );
            }

            resolve_reject();
        }
    break;

    case "leaving":
        if (point_distance(x, y, exit_x, exit_y) <= 16) {
            instance_destroy();
        }
    break;
}


depth = -y;
