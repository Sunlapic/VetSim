/// End Step obj_player
/// @description Глубина у стойки и стандартная рабочая анимация уборки.

var _real_player_state = doctor_state;
var _cleaning_visual_state = (
    _real_player_state == "going_to_clean_dirt"
    || _real_player_state == "clean_dirt_menu"
    || _real_player_state == "cleaning_dirt"
);

// Родитель видит знакомые состояния и использует обычные составные спрайты.
if (_real_player_state == "cleaning_dirt") {
    doctor_state = "manual_procedure";
}
else if (_real_player_state == "going_to_clean_dirt") {
    doctor_state = "going_to_doctor_point";
}
else if (_real_player_state == "clean_dirt_menu") {
    doctor_state = "idle";
}

event_inherited();
doctor_state = _real_player_state;


// ═══════════════════════════════════════════════════════════════
// 1. РЕГИСТРАЦИЯ И ОПЛАТА
// ═══════════════════════════════════════════════════════════════

if (
    (doctor_state == "manual_registering" || doctor_state == "manual_payment")
    && instance_exists(registration_target_desk)
) {
    depth = registration_target_desk.depth - 3;
}
else {
    depth = -y;
}


// ═══════════════════════════════════════════════════════════════
// 2. УБОРКА
// ═══════════════════════════════════════════════════════════════

if (_cleaning_visual_state) {
    if (doctor_state == "clean_dirt_menu") {
        path_end();
        speed = 0;
        is_walking = false;
    }

    if (
        doctor_state == "cleaning_dirt"
        && sprite_exists(spr_human_FR_work)
    ) {
        if (!variable_instance_exists(id, "cleaning_anim_timer")) {
            cleaning_anim_timer = 0;
        }

        cleaning_anim_timer += 1;
        sprite_index = spr_human_FR_work;
        image_speed = 0;
        image_index = floor(cleaning_anim_timer / 6)
            mod max(1, sprite_get_number(spr_human_FR_work));
    }
    else if (variable_instance_exists(id, "cleaning_anim_timer")) {
        cleaning_anim_timer = 0;
    }
}


// ═══════════════════════════════════════════════════════════════
// 3. ДВУХФАЗНЫЙ ПРИЁМ И РУЧНЫЕ НАЗНАЧЕНИЯ СТАЦИОНАРА
// End Step выполняется после основного Step, поэтому шкала перекрывает
// старое action_progress_active = false и видна в текущем кадре.
// ═══════════════════════════════════════════════════════════════

doctor_visit_update_player_timing(id);


// ═══════════════════════════════════════════════════════════════
// 4. СПРАВОЧНИК БОЛЕЗНЕЙ (пакет №69)
// Идеальный ручной приём открывает запись болезни сразу и навсегда.
// NPC-врачи сюда не попадают: проверяется только ручной приём игрока.
// ═══════════════════════════════════════════════════════════════

if (
    doctor_state == "manual_exam"
    && instance_exists(assigned_pet)
) {
    var _handbook_disease = handbook_check_perfect_exam(assigned_pet);

    if (_handbook_disease != "") {
        handbook_unlock(_handbook_disease);
    }
}


// ═══════════════════════════════════════════════════════════════
// 5. ОТЛАДОЧНАЯ КНОПКА Q (пакет №74, ВРЕМЕННАЯ)
// Нажатие клавиши Q добавляет +10 баллов клиники.
// Нужна только для проверки прокачки в КЛИНИКА → РАЗВИТИЕ.
// Перед релизом удалить или спрятать за global.vetsim_debug_mode.
// ═══════════════════════════════════════════════════════════════

if (keyboard_check_pressed(ord("Q"))) {
    clinic_upgrade_init();

    global.clinic_points += 10;

    if (instance_exists(obj_UI_HUD)) {
        var _hud_q = instance_find(obj_UI_HUD, 0);

        if (
            instance_exists(_hud_q)
            && variable_instance_exists(_hud_q, "show_notice")
        ) {
            with (_hud_q) {
                show_notice(
                    "ТЕСТ +10 БАЛЛОВ",
                    "Всего баллов: " + string(global.clinic_points),
                    max(1, game_get_speed(gamespeed_fps)) * 2
                );
            }
        }
    }
}
