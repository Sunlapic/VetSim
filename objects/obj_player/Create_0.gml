/// Create obj_player

event_inherited();


// ─────────────────────────────────────────────
// ВНЕШНОСТЬ И ДАННЫЕ ГЛАВНОГО ГЕРОЯ
// ─────────────────────────────────────────────
portrait_x = 150;
portrait_y = 50;
portrait_zoom = 1;
char_name = "Доктор Алекс (Я)";
age = 32;
role = "doctor";
specialty_title = "ГЛАВНЫЙ ВРАЧ";
character_trait = 1;

// ═══ НАВЫКИ ИГРОКА ВСЕГДА НАЧИНАЮТСЯ С 1 ЛВЛ ═══
// (не irandom 7-9, а ровно 1 в каждом — иначе баланс ломается сразу)
skills = array_create(10, 1);
skills_sum = 10;

// Массив XP по навыкам для новой системы
skill_xp = array_create(10, 0);

my_hair = spr_fr_walk_hair_01;
my_hair_back = spr_b_walk_hair_01;
my_eyes = spr_fr_walk_eyes_01;
my_nose = spr_fr_walk_nose_01;
my_mouth = spr_fr_walk_mouths_01;
hair_color = make_color_rgb(50, 30, 20);
portrait_offset = 35;
p_move_speed = 5.0;
sprite_index = spr_human_FR_walk;
image_speed = 0;
depth = -y;

// ─────────────────────────────────────────────
// РУЧНАЯ ЛОГИКА ИГРОКА
// ─────────────────────────────────────────────
doctor_state = "idle";
service_mode = "";
assigned_owner = noone;
assigned_table = noone;
assigned_pet = noone;
doctor_target_x = x;
doctor_target_y = y;
owner_target_x = x;
owner_target_y = y;
pet_floor_target_x = x;
pet_floor_target_y = y;
pet_table_target_x = x;
pet_table_target_y = y;
exam_timer = 0;
exam_timer_max = 0;

// ─────────────────────────────────────────────
// СИСТЕМА ВЫНОСЛИВОСТИ (как у персонала)
// ─────────────────────────────────────────────
if (!variable_instance_exists(self, "energy_max")) {
    var _stamina_lvl = 1;
    energy_max = 20 + _stamina_lvl * 10;   // 30 на первом уровне выносливости
}
energy = energy_max;
tired_speech_cd = 0;

// ─────────────────────────────────────────────
// ХАРАКТЕРИСТИКИ ВРАЧА (новая система XP — совместимо с doctor_add_skill_xp)
// ─────────────────────────────────────────────
therapy_xp = 0;
therapy_level = 1;
therapy_xp_into_level = 0;
therapy_xp_next_level = doctor_therapy_xp_needed(1);
therapy_error_chance = doctor_get_therapy_error_chance(1);
therapy_exam_duration_frames = doctor_get_exam_duration_frames(1);

// Пересчитываем и мигрируем все навыки — гарантирует 1 лвл на старте,
// не понижает уровень если загружен сейв с уже поднятыми навыками
doctor_recalc_all_skills(self);
// ═══════════════════════════════════════════════════════════════
// ДОПОЛНИТЕЛЬНЫЕ НАВЫКИ ГЛАВНОГО ИГРОКА
// ═══════════════════════════════════════════════════════════════

player_extra_skills_init(id);

// Создаются:
// player_admin_skill_levels    = [Регистрация, Касса]
// player_admin_skill_xp        = [0, 0]
// player_assistant_skill_levels= [Процедуры, Пополнение]
// player_assistant_skill_xp    = [0, 0]


// Лог последних навыков как у персонала
if (!variable_instance_exists(self, "xp_log") || !is_array(xp_log)) {
    xp_log = array_create(5, "");
}


// ─────────────────────────────────────────────
// РУЧНАЯ РЕГИСТРАЦИЯ / ОПЛАТА
// ─────────────────────────────────────────────
registration_target_owner = noone;
registration_target_desk = noone;

reception_target_x = x;
reception_target_y = y;

registration_timer = 0;
registration_duration = room_speed * 2;
reception_action_type = ""; // registration / payment

// ─────────────────────────────────────────────
// СБРОС РЕГИСТРАЦИИ / ОПЛАТЫ
// ─────────────────────────────────────────────
player_reset_registration = function() {

    if (instance_exists(registration_target_owner)) {
        with (registration_target_owner) {
            if (state == "registering" && queue_purpose != "payment" && !registered) {
                state = "in_queue";
            }

            registration_in_progress = false;
            registration_timer = 0;
            registration_timer_max = 0;
            registration_actor_name = "";
        }

        if (instance_exists(registration_target_desk)) {
            registration_target_desk.alarm[0] = 1;
        }
    }

    registration_target_owner = noone;
    registration_target_desk = noone;
    registration_timer = 0;
    reception_action_type = "";

    if (doctor_state == "going_to_reception"
    || doctor_state == "manual_registering"
    || doctor_state == "going_to_payment"
    || doctor_state == "manual_payment") {
        doctor_state = "idle";
    }
};

// ─────────────────────────────────────────────
// НАЧАТЬ РУЧНУЮ РЕГИСТРАЦИЮ
// ─────────────────────────────────────────────

player_begin_registration = function(_owner) {

    if (!instance_exists(_owner)) return false;
    if (doctor_state != "idle") return false;
    if (_owner.registered) return false;
    if (_owner.state != "in_queue") return false;
    if (_owner.queue_slot != 0) return false;

    // ─────────────────────────────────────────
    // ИЩЕМ СТОЙКУ ВЛАДЕЛЬЦА
    // ─────────────────────────────────────────

    var _desk = noone;

    if (
        variable_instance_exists(_owner, "assigned_desk")
        && instance_exists(_owner.assigned_desk)
    ) {
        _desk = _owner.assigned_desk;

    } else if (instance_exists(obj_reception_desk)) {

        _desk = instance_find(obj_reception_desk, 0);
    }

    if (!instance_exists(_desk)) {

        if (instance_exists(obj_UI_HUD)) {
            with (obj_UI_HUD) {
                show_notice(
                    "НЕТ СТОЙКИ",
                    "Стойка регистратуры не найдена.",
                    room_speed * 3
                );
            }
        }

        return false;
    }

    // ─────────────────────────────────────────
    // ОБНОВЛЯЕМ ТОЧКИ СТОЙКИ ИЗ ROOM EDITOR
    // ─────────────────────────────────────────

    if (
        variable_instance_exists(
            _desk,
            "reception_refresh_points"
        )
    ) {
        with (_desk) {
            reception_refresh_points();
        }
    }

    // ─────────────────────────────────────────
    // ПРОВЕРЯЕМ СВОБОДНОЕ МЕСТО ОЖИДАНИЯ
    // ─────────────────────────────────────────

    if (reception_find_free_wait_spot() == -1) {

        if (instance_exists(obj_UI_HUD)) {
            with (obj_UI_HUD) {
                show_notice(
                    "НЕТ МЕСТ",
                    "В зоне ожидания нет свободных мест.",
                    room_speed * 3
                );
            }
        }

        return false;
    }

    // ─────────────────────────────────────────
    // ЕСЛИ АДМИН УЖЕ ВЗЯЛ ЭТОГО КЛИЕНТА —
    // ИГРОК ПЕРЕХВАТЫВАЕТ РЕГИСТРАЦИЮ
    // ─────────────────────────────────────────

    for (
        var _admin_index = 0;
        _admin_index < instance_number(obj_staff_admin);
        _admin_index++
    ) {
        var _admin = instance_find(
            obj_staff_admin,
            _admin_index
        );

        if (!instance_exists(_admin)) continue;

        if (
            variable_instance_exists(
                _admin,
                "reception_client"
            )
        ) {
            if (_admin.reception_client == _owner) {

                _admin.reception_client = noone;

                if (
                    _admin.reception_state
                        == "going_to_register_spot"
                    || _admin.reception_state
                        == "registering"
                ) {
                    _admin.reception_state = "returning";
                    _admin.reception_timer = 0;
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // СОХРАНЯЕМ ЦЕЛИ РЕГИСТРАЦИИ
    // ─────────────────────────────────────────

    registration_target_owner = _owner;
    registration_target_desk  = _desk;

    // Эти координаты теперь поступают
    // из obj_reception_point_staff.
    // Если точка не найдена — стойка использует резервные координаты.
    reception_target_x = _desk.admin_spot_x;
    reception_target_y = _desk.admin_spot_y;

    reception_action_type = "registration";

    // Останавливаем владельца у стойки
    with (registration_target_owner) {

        state = "registering";

        path_end();
        is_walking = false;

        registration_in_progress = false;
        registration_timer = 0;
        registration_timer_max = 0;
        registration_actor_name = "";
    }

    // ─────────────────────────────────────────
    // ИГРОК ИДЁТ К ТОЧКЕ ПЕРСОНАЛА
    // ─────────────────────────────────────────

    path_end();
    is_walking = false;

    if (mp_grid_path(
        global.ai_grid,
        my_path,
        x,
        y,
        reception_target_x,
        reception_target_y,
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

    } else {

        // Сохраняем старое поведение:
        // если путь не построился, ставим игрока на точку.
        x = reception_target_x;
        y = reception_target_y;
        is_walking = false;
    }

    doctor_state = "going_to_reception";

    return true;
};


// ─────────────────────────────────────────────
// НАЧАТЬ ПРИЁМ ОПЛАТЫ
// ─────────────────────────────────────────────

player_begin_payment = function(_owner) {

    if (!instance_exists(_owner)) return false;
    if (doctor_state != "idle") return false;
    if (_owner.state != "in_queue") return false;

    if (
        !variable_instance_exists(
            _owner,
            "queue_purpose"
        )
    ) {
        return false;
    }

    if (_owner.queue_purpose != "payment") return false;
    if (_owner.queue_slot != 0) return false;

    // ─────────────────────────────────────────
    // ИЩЕМ СТОЙКУ ВЛАДЕЛЬЦА
    // ─────────────────────────────────────────

    var _desk = noone;

    if (
        variable_instance_exists(_owner, "assigned_desk")
        && instance_exists(_owner.assigned_desk)
    ) {
        _desk = _owner.assigned_desk;

    } else if (instance_exists(obj_reception_desk)) {

        _desk = instance_find(obj_reception_desk, 0);
    }

    if (!instance_exists(_desk)) {

        if (instance_exists(obj_UI_HUD)) {
            with (obj_UI_HUD) {
                show_notice(
                    "НЕТ СТОЙКИ",
                    "Стойка регистратуры не найдена.",
                    room_speed * 3
                );
            }
        }

        return false;
    }

    // ─────────────────────────────────────────
    // ОБНОВЛЯЕМ ТОЧКИ СТОЙКИ ИЗ ROOM EDITOR
    // ─────────────────────────────────────────

    if (
        variable_instance_exists(
            _desk,
            "reception_refresh_points"
        )
    ) {
        with (_desk) {
            reception_refresh_points();
        }
    }

    // ─────────────────────────────────────────
    // ЕСЛИ АДМИН УЖЕ НАЧАЛ ПРИНИМАТЬ ОПЛАТУ —
    // ИГРОК ПЕРЕХВАТЫВАЕТ КЛИЕНТА
    // ─────────────────────────────────────────

    for (
        var _admin_index = 0;
        _admin_index < instance_number(obj_staff_admin);
        _admin_index++
    ) {
        var _admin = instance_find(
            obj_staff_admin,
            _admin_index
        );

        if (!instance_exists(_admin)) continue;

        if (
            variable_instance_exists(
                _admin,
                "reception_client"
            )
        ) {
            if (_admin.reception_client == _owner) {

                _admin.reception_client = noone;

                if (
                    _admin.reception_state
                        == "going_to_register_spot"
                    || _admin.reception_state
                        == "registering"
                ) {
                    _admin.reception_state = "returning";
                    _admin.reception_timer = 0;
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // СОХРАНЯЕМ ЦЕЛИ ОПЛАТЫ
    // ─────────────────────────────────────────

    registration_target_owner = _owner;
    registration_target_desk  = _desk;

    // Эти координаты теперь поступают
    // из obj_reception_point_staff.
    reception_target_x = _desk.admin_spot_x;
    reception_target_y = _desk.admin_spot_y;

    reception_action_type = "payment";

    // Останавливаем владельца у стойки
    with (registration_target_owner) {

        state = "registering";

        path_end();
        is_walking = false;

        registration_in_progress = false;
        registration_timer = 0;
        registration_timer_max = 0;
        registration_actor_name = "";
    }

    // ─────────────────────────────────────────
    // ИГРОК ИДЁТ К ТОЧКЕ ПЕРСОНАЛА
    // ─────────────────────────────────────────

    path_end();
    is_walking = false;

    if (mp_grid_path(
        global.ai_grid,
        my_path,
        x,
        y,
        reception_target_x,
        reception_target_y,
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

    } else {

        // Сохраняем старое поведение:
        // если путь не построился, ставим игрока на точку.
        x = reception_target_x;
        y = reception_target_y;
        is_walking = false;
    }

    doctor_state = "going_to_payment";

    return true;
};
// ─────────────────────────────────────────────
// ОБЩИЙ СТАРТ СЕРВИСА
// ─────────────────────────────────────────────
player_begin_service = function(_owner, _mode) {

    if (!instance_exists(_owner)) return false;
    if (_owner.state != "waiting") return false;
    if (_owner.assigned_doctor != noone) return false;
    if (doctor_state != "idle") return false;

    if (_mode == "doctor" && _owner.service_queue_type != "doctor") return false;
    if (_mode == "procedure" && _owner.service_queue_type != "procedure") return false;

    var _free_table = noone;
    var _doc_point = noone;
    var _owner_point = noone;
    var _pet_floor_point = noone;
    var _pet_table_point = noone;

    for (var _i = 0; _i < instance_number(obj_table); _i++) {
        var _tbl = instance_find(obj_table, _i);
        if (!instance_exists(_tbl)) continue;
        if (_tbl.table_busy) continue;

        var _slot = _tbl.exam_slot_id;

        var _d = noone;
        var _o = noone;
        var _pf = noone;
        var _pt = noone;

        for (var _di = 0; _di < instance_number(obj_exam_point_doctor); _di++) {
            var _d_test = instance_find(obj_exam_point_doctor, _di);
            if (instance_exists(_d_test) && _d_test.exam_slot_id == _slot) { _d = _d_test; break; }
        }

        for (var _oi = 0; _oi < instance_number(obj_exam_point_owner); _oi++) {
            var _o_test = instance_find(obj_exam_point_owner, _oi);
            if (instance_exists(_o_test) && _o_test.exam_slot_id == _slot) { _o = _o_test; break; }
        }

        for (var _pfi = 0; _pfi < instance_number(obj_exam_point_pet_floor); _pfi++) {
            var _pf_test = instance_find(obj_exam_point_pet_floor, _pfi);
            if (instance_exists(_pf_test) && _pf_test.exam_slot_id == _slot) { _pf = _pf_test; break; }
        }

        for (var _pti = 0; _pti < instance_number(obj_exam_point_pet_table); _pti++) {
            var _pt_test = instance_find(obj_exam_point_pet_table, _pti);
            if (instance_exists(_pt_test) && _pt_test.exam_slot_id == _slot) { _pt = _pt_test; break; }
        }

        if (instance_exists(_d) && instance_exists(_o) && instance_exists(_pf) && instance_exists(_pt)) {
            _free_table = _tbl;
            _doc_point = _d;
            _owner_point = _o;
            _pet_floor_point = _pf;
            _pet_table_point = _pt;
            break;
        }
    }

    if (_free_table == noone) {
        for (var _j = 0; _j < instance_number(obj_table_1); _j++) {
            var _tbl2 = instance_find(obj_table_1, _j);
            if (!instance_exists(_tbl2)) continue;
            if (_tbl2.table_busy) continue;

            var _slot2 = _tbl2.exam_slot_id;

            var _d2 = noone;
            var _o2 = noone;
            var _pf2 = noone;
            var _pt2 = noone;

            for (var _di2 = 0; _di2 < instance_number(obj_exam_point_doctor); _di2++) {
                var _d_test2 = instance_find(obj_exam_point_doctor, _di2);
                if (instance_exists(_d_test2) && _d_test2.exam_slot_id == _slot2) { _d2 = _d_test2; break; }
            }

            for (var _oi2 = 0; _oi2 < instance_number(obj_exam_point_owner); _oi2++) {
                var _o_test2 = instance_find(obj_exam_point_owner, _oi2);
                if (instance_exists(_o_test2) && _o_test2.exam_slot_id == _slot2) { _o2 = _o_test2; break; }
            }

            for (var _pfi2 = 0; _pfi2 < instance_number(obj_exam_point_pet_floor); _pfi2++) {
                var _pf_test2 = instance_find(obj_exam_point_pet_floor, _pfi2);
                if (instance_exists(_pf_test2) && _pf_test2.exam_slot_id == _slot2) { _pf2 = _pf_test2; break; }
            }

            for (var _pti2 = 0; _pti2 < instance_number(obj_exam_point_pet_table); _pti2++) {
                var _pt_test2 = instance_find(obj_exam_point_pet_table, _pti2);
                if (instance_exists(_pt_test2) && _pt_test2.exam_slot_id == _slot2) { _pt2 = _pt_test2; break; }
            }

            if (instance_exists(_d2) && instance_exists(_o2) && instance_exists(_pf2) && instance_exists(_pt2)) {
                _free_table = _tbl2;
                _doc_point = _d2;
                _owner_point = _o2;
                _pet_floor_point = _pf2;
                _pet_table_point = _pt2;
                break;
            }
        }
    }

    if (!instance_exists(_free_table)) {
        if (instance_exists(obj_UI_HUD)) {
            with (obj_UI_HUD) {
                show_notice("НЕТ СВОБОДНОГО СТОЛА", "Все смотровые столы заняты.", room_speed * 3);
            }
        }
        return false;
    }

    assigned_owner = _owner;
    assigned_table = _free_table;
    assigned_pet = instance_exists(_owner.my_pet) ? _owner.my_pet : noone;
    service_mode = _mode;

    doctor_target_x = _doc_point.x;
    doctor_target_y = _doc_point.y;

    owner_target_x = _owner_point.x;
    owner_target_y = _owner_point.y;

    pet_floor_target_x = _pet_floor_point.x;
    pet_floor_target_y = _pet_floor_point.y;

    pet_table_target_x = _pet_table_point.x;
    pet_table_target_y = _pet_table_point.y;

    with (assigned_table) {
        table_busy = true;
        assigned_owner = other.assigned_owner;
        assigned_doctor = other.id;
        assigned_pet = other.assigned_pet;
    }

    // ═══════════════════════════════════════════════════════════════
// 2. НОВЫЙ СБРОС ДАННЫХ ТЕКУЩЕГО ВИЗИТА
// ═══════════════════════════════════════════════════════════════

if (
    instance_exists(assigned_pet)
    && variable_instance_exists(assigned_pet, "current_case")
    && is_struct(assigned_pet.current_case)
) {
    with (assigned_pet) {
        // Диагностика.
        current_case.visit_diagnostics_done = [];
        current_case.visit_diagnostic_feedback_ok_ids = [];
        current_case.visit_diagnostic_feedback_bad_ids = [];
        current_case.visit_wrong_diagnostics_done = [];
        current_case.visit_extra_diagnostic_cost = 0;
        current_case.visit_extra_diagnostic_time_min = 0;

        // Лечение и назначения.
        current_case.visit_treatments_done = [];
        current_case.visit_treatment_feedback_ok_ids = [];
        current_case.visit_treatment_feedback_bad_ids = [];
        current_case.visit_prescribed_actions = [];

        // Общий журнал визита.
        current_case.visit_procedure_log = [];

        animal_apply_case(id, current_case);
    }
}

    var _meet_x = assigned_owner.x + 28;
    var _meet_y = assigned_owner.y;

    path_end();

    if (mp_grid_path(global.ai_grid, my_path, x, y, _meet_x, _meet_y, true)) {
        path_set_kind(my_path, 1);
        path_start(my_path, p_move_speed, path_action_stop, true);
        is_walking = true;
    } else {
        x = _meet_x;
        y = _meet_y;
        is_walking = false;
    }

    doctor_state = "going_to_owner";
    return true;
};

player_begin_exam = function(_owner) {
    return player_begin_service(_owner, "doctor");
};

player_begin_procedure_visit = function(_owner) {
    return player_begin_service(_owner, "procedure");
};

// ─────────────────────────────────────────────
// СБРОС РУЧНОГО СЕРВИСА
// ─────────────────────────────────────────────
player_reset_exam = function() {
    assigned_owner = noone;
    assigned_table = noone;
    assigned_pet = noone;

    exam_timer = 0;
    exam_timer_max = 0;

    service_mode = "";
    doctor_state = "idle";
};

// ─────────────────────────────────────────────
// ЗАВЕРШИТЬ ПРИЁМ ВРАЧА
// ─────────────────────────────────────────────
player_finish_exam = function(_successful) {

    if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
        player_reset_exam();
        return;
    }

    var _owner_done = assigned_owner;
    var _table_done = assigned_table;
    var _pet_done = assigned_pet;

    var _outcome = undefined;

    var _condition_before = 80;
    var _required_complete = false;
    var _case_confirmed = false;
    var _case_id = "";
    var _disease_id = "";
    var _reveal_level = 0;
    var _severity_level = 0;
    var _severity_name_ru = "";
    var _case_status = "";

    var _completed_diagnostics = [];
    var _treatment_progress = [];
    var _visible_symptoms = [];
    var _planned_treatment = [];
    var _diagnostics_this_visit = [];
    var _treatments_this_visit = [];
    var _procedure_log = [];

    if (instance_exists(_pet_done) && variable_instance_exists(_pet_done, "current_case") && is_struct(_pet_done.current_case)) {

        _condition_before = _pet_done.current_case.condition;
        _required_complete = case_is_required_treatment_complete(_pet_done.current_case);
        _case_confirmed = _pet_done.current_case.confirmed;
        _outcome = case_evaluate_outcome(_pet_done.current_case);

        if (variable_struct_exists(_pet_done.current_case, "case_id")) _case_id = _pet_done.current_case.case_id;
        if (variable_struct_exists(_pet_done.current_case, "hidden_disease_id")) _disease_id = _pet_done.current_case.hidden_disease_id;
        if (variable_struct_exists(_pet_done.current_case, "reveal_level")) _reveal_level = _pet_done.current_case.reveal_level;
        if (variable_struct_exists(_pet_done.current_case, "severity_level")) _severity_level = _pet_done.current_case.severity_level;
        if (variable_struct_exists(_pet_done.current_case, "severity_name_ru")) _severity_name_ru = _pet_done.current_case.severity_name_ru;
        if (variable_struct_exists(_pet_done.current_case, "case_status")) _case_status = _pet_done.current_case.case_status;

        if (variable_struct_exists(_pet_done.current_case, "completed_diagnostics")) _completed_diagnostics = _pet_done.current_case.completed_diagnostics;
        if (variable_struct_exists(_pet_done.current_case, "treatment_progress")) _treatment_progress = _pet_done.current_case.treatment_progress;
        if (variable_struct_exists(_pet_done.current_case, "visible_symptoms")) _visible_symptoms = _pet_done.current_case.visible_symptoms;
        if (variable_struct_exists(_pet_done.current_case, "planned_treatment")) _planned_treatment = _pet_done.current_case.planned_treatment;
        if (variable_struct_exists(_pet_done.current_case, "visit_diagnostics_done")) _diagnostics_this_visit = _pet_done.current_case.visit_diagnostics_done;
        if (variable_struct_exists(_pet_done.current_case, "visit_treatments_done")) _treatments_this_visit = _pet_done.current_case.visit_treatments_done;
        if (variable_struct_exists(_pet_done.current_case, "visit_procedure_log")) _procedure_log = _pet_done.current_case.visit_procedure_log;
    }

    if (!is_struct(_outcome)) {
        _outcome = {
            outcome_id : "outcome_generic",
            outcome_name_ru : "Приём завершён",
            trust_delta : 0,
            payout_mult : (_successful ? 1.0 : 0.5),
            condition_after : 80,
            needs_followup : false,
            followup_days : 0,
            followup_reason : ""
        };
    }

    with (_table_done) {
        table_busy = false;
        assigned_owner = noone;
        assigned_doctor = noone;
        assigned_pet = noone;
    }

    if (instance_exists(_pet_done) && variable_instance_exists(_pet_done, "current_case") && is_struct(_pet_done.current_case)) {
        _pet_done.current_case.condition = _outcome.condition_after;
        _pet_done.current_case.case_status = "doctor_visit_done";
        _pet_done.condition = _outcome.condition_after;
        _case_status = _pet_done.current_case.case_status;
    }

    if (instance_exists(_owner_done)) {
        if (!variable_instance_exists(_owner_done, "owner_trust")) {
            _owner_done.owner_trust = 60;
        }

        _owner_done.owner_trust = clamp(_owner_done.owner_trust + _outcome.trust_delta, 0, 100);
    }

    var _payout = global.base_visit_price;
    _payout += irandom_range(0, global.visit_price_random);
    _payout = floor(_payout * _outcome.payout_mult);
    _payout = max(20, _payout);

    if (instance_exists(_owner_done)) {
        _owner_done.visit_price = _payout;

        _owner_done.visit_outcome_id = _outcome.outcome_id;
        _owner_done.visit_outcome_name_ru = _outcome.outcome_name_ru;
        _owner_done.visit_trust_delta = _outcome.trust_delta;
        _owner_done.visit_payout_mult = _outcome.payout_mult;

        _owner_done.visit_condition_before = _condition_before;
        _owner_done.visit_condition_after = _outcome.condition_after;

        _owner_done.visit_followup_planned = case_needs_followup(_outcome);
        _owner_done.visit_followup_days = _outcome.followup_days;
        _owner_done.visit_followup_reason = _outcome.followup_reason;

        _owner_done.visit_case_id = _case_id;
        _owner_done.visit_disease_id = _disease_id;
        _owner_done.visit_case_confirmed = _case_confirmed;
        _owner_done.visit_reveal_level = _reveal_level;
        _owner_done.visit_severity_level = _severity_level;
        _owner_done.visit_severity_name_ru = _severity_name_ru;
        _owner_done.visit_case_status = _case_status;
        _owner_done.visit_required_treatment_complete = _required_complete;

        _owner_done.visit_completed_diagnostics = _completed_diagnostics;
        _owner_done.visit_treatment_progress = _treatment_progress;
        _owner_done.visit_visible_symptoms = _visible_symptoms;
        _owner_done.visit_planned_treatment = _planned_treatment;
        _owner_done.visit_diagnostics_this_visit = _diagnostics_this_visit;
        _owner_done.visit_treatments_this_visit = _treatments_this_visit;
        _owner_done.visit_procedure_log = _procedure_log;

        _owner_done.visit_type_id = "doctor_visit";
        _owner_done.visit_type_name_ru = "Приём врача";
    }

    if (instance_exists(_owner_done)) {
        db_register_completed_visit(_owner_done);
    }

   // ─────────────────────────────────────────────
   // XP ИГРОКУ ПО ОКОНЧАНИИ ПРИЁМА (+5 ТЕРАПИИ +4 ПРОФИЛЬНОМУ, как у NPC)
   // ─────────────────────────────────────────────
if (_case_confirmed) {
    var _xp_base_therapy = 5;
    var _xp_specialty    = 4;
    var _log_txt = "+" + string(_xp_base_therapy) + " ТЕРАПИЯ";

    doctor_add_skill_xp(self, 0, _xp_base_therapy, false);
    staff_spend_energy(8);

    if (instance_exists(_pet_done) && is_struct(_pet_done.current_case)) {
        var _hid = undefined;
        if (variable_struct_exists(_pet_done.current_case, "hidden_disease_id"))
            _hid = _pet_done.current_case.hidden_disease_id;
        if ((!is_string(_hid) || _hid == "") && variable_struct_exists(_pet_done.current_case, "selected_disease_id"))
            _hid = _pet_done.current_case.selected_disease_id;

        if (is_string(_hid) && _hid != "") {
            var _diag_skill = doctor_get_skill_for_disease(_hid);
            if (_diag_skill < 0) _diag_skill = 0;

            doctor_add_skill_xp(self, _diag_skill, _xp_specialty, true);
            if (_diag_skill == 0) {
                _log_txt = "+" + string(_xp_base_therapy + _xp_specialty) + " ТЕРАПИЯ";
            } else {
                var _skill_names = doctor_get_skill_names();
                var _sname = (_diag_skill < array_length(_skill_names)) ? _skill_names[_diag_skill] : "ТЕРАПИЯ";
                _log_txt += "   +" + string(_xp_specialty) + " " + _sname;
            }
        } else {
            doctor_add_skill_xp(self, 0, _xp_specialty, true);
            _log_txt = "+" + string(_xp_base_therapy + _xp_specialty) + " ТЕРАПИЯ";
        }
    }
    add_xp_log(_log_txt);
}

    // Стоимость добавляем в будущую оплату
    if (instance_exists(_owner_done)) {
        if (!variable_instance_exists(_owner_done, "pending_payment_total")) {
            _owner_done.pending_payment_total = 0;
        }
        _owner_done.pending_payment_total += _payout;
    }

    var _moved_to_procedure_queue = false;

    if (instance_exists(_pet_done) && variable_instance_exists(_pet_done, "current_case") && is_struct(_pet_done.current_case)) {
        var _next_assignments = case_build_next_procedure_assignments(_pet_done.current_case);

        if (_case_confirmed && array_length(_next_assignments) > 0) {
            _pet_done.current_case.pending_procedure_actions = _next_assignments;

            var _wait_index = reception_find_free_wait_spot();

            if (_wait_index != -1) {
                global.wait_spots[_wait_index].occupied_by = _owner_done;

               with (_owner_done) {

                    registered = true;
                    wait_spot_index = _wait_index;
                    assigned_doctor = noone;
                    assigned_table  = noone;
                    service_queue_type = "procedure";
                    visit_type_id = "procedure_visit";
                    visit_type_name_ru = "Процедурный визит";
                    visit_reason_ru = "Выполнение назначений";
                    state = "going_to_waiting";

                    var _spot = global.wait_spots[wait_spot_index];
                    path_end();
                    is_walking = false;

                    // ── Ищем достижимую точку рядом с креслом ожидания ──
                    var _tx = _spot.x;
                    var _ty = _spot.y;
                    var _built = false;

                    if (mp_grid_path(global.ai_grid, my_path, x, y, _tx, _ty, true)) {
                        _built = true;
                    } else {
                        var _offs = [-32, -24, -16, 0, 16, 24, 32];
                        for (var _ox = 0; _ox < array_length(_offs); _ox++) {
                            for (var _oy = 0; _oy < array_length(_offs); _oy++) {
                                if (_ox == 3 && _oy == 3) continue;
                                var _ax = _spot.x + _offs[_ox];
                                var _ay = _spot.y + _offs[_oy];
                                if (mp_grid_path(global.ai_grid, my_path, x, y, _ax, _ay, true)) {
                                    _tx = _ax;
                                    _ty = _ay;
                                    _built = true;
                                    break;
                                }
                            }
                            if (_built) break;
                        }
                    }

                    if (_built) {
                        path_set_kind(my_path, 1);
                        path_start(my_path, p_move_speed, path_action_stop, true);
                        is_walking = true;
                    } else {
                        // Фоллбек: идём по прямой, НЕ ТЕЛЕПОРТИРУЕМ
                        // (доводку до 12px и переключение в waiting делает
                        //  блок "страховка прибытия" в Step obj_owner)
                        is_walking = true;
                        move_towards_point(_spot.x, _spot.y, p_move_speed);
                    }
                }
                if (instance_exists(_pet_done)) {
                    with (_pet_done) {
                        path_end();
                        is_walking = false;
                        assigned_doctor = noone;
                        assigned_table = noone;
                        state = "follow_owner";
                        follow_offset_x = 30;
                        follow_offset_y = 20;
                    }
                }

                if (instance_exists(obj_UI_HUD)) {
                    with (obj_UI_HUD) {
                        show_notice("НАЗНАЧЕНИЯ ГОТОВЫ", "Пациент переведён в очередь на процедуры.", room_speed * 3);
                    }
                }

                _moved_to_procedure_queue = true;
            }
        }
    }

    if (_moved_to_procedure_queue) {
        player_reset_exam();
        return;
    }

    if (instance_exists(_owner_done)) {
        reception_enqueue_priority_payment(_owner_done);
    }

    if (instance_exists(obj_UI_HUD)) {
        with (obj_UI_HUD) {
            show_notice("НА ОПЛАТУ", "Клиент направлен к стойке для расчёта.", room_speed * 3);
        }
    }

    player_reset_exam();
};
// ─────────────────────────────────────────────
// ЗАВЕРШИТЬ ПРОЦЕДУРНЫЙ ВИЗИТ
// ─────────────────────────────────────────────
player_finish_procedure_visit = function() {

    if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
        player_reset_exam();
        return;
    }

    var _owner_done = assigned_owner;
    var _table_done = assigned_table;
    var _pet_done = assigned_pet;

    var _outcome = undefined;

    if (instance_exists(_pet_done) && variable_instance_exists(_pet_done, "current_case") && is_struct(_pet_done.current_case)) {
        _outcome = case_evaluate_outcome(_pet_done.current_case);
        _pet_done.current_case.pending_procedure_actions = [];
    }

    if (!is_struct(_outcome)) {
        _outcome = {
            outcome_id : "outcome_procedure",
            outcome_name_ru : "Процедуры выполнены",
            trust_delta : 1,
            payout_mult : 0.6,
            condition_after : 100,
            needs_followup : false,
            followup_days : 0,
            followup_reason : ""
        };
    }

    with (_table_done) {
        table_busy = false;
        assigned_owner = noone;
        assigned_doctor = noone;
        assigned_pet = noone;
    }

    var _payout = max(20, floor(global.base_visit_price * 0.45));

    if (instance_exists(_owner_done)) {
        _owner_done.visit_price = _payout;

        _owner_done.visit_type_id = "procedure_visit";
        _owner_done.visit_type_name_ru = "Процедурный визит";
        _owner_done.visit_reason_ru = "Выполнение назначений";

        _owner_done.visit_outcome_id = _outcome.outcome_id;
        _owner_done.visit_outcome_name_ru = _outcome.outcome_name_ru;
        _owner_done.visit_trust_delta = _outcome.trust_delta;
        _owner_done.visit_payout_mult = _outcome.payout_mult;

        if (instance_exists(_pet_done) && is_struct(_pet_done.current_case)) {
            _owner_done.visit_condition_before = _pet_done.current_case.condition;
            _owner_done.visit_condition_after = _pet_done.current_case.condition;

            _owner_done.visit_case_id = variable_struct_exists(_pet_done.current_case, "case_id") ? _pet_done.current_case.case_id : "";
            _owner_done.visit_disease_id = variable_struct_exists(_pet_done.current_case, "hidden_disease_id") ? _pet_done.current_case.hidden_disease_id : "";
            _owner_done.visit_case_confirmed = variable_struct_exists(_pet_done.current_case, "confirmed") ? _pet_done.current_case.confirmed : false;
            _owner_done.visit_reveal_level = variable_struct_exists(_pet_done.current_case, "reveal_level") ? _pet_done.current_case.reveal_level : 0;
            _owner_done.visit_severity_level = variable_struct_exists(_pet_done.current_case, "severity_level") ? _pet_done.current_case.severity_level : 0;
            _owner_done.visit_severity_name_ru = variable_struct_exists(_pet_done.current_case, "severity_name_ru") ? _pet_done.current_case.severity_name_ru : "";
            _owner_done.visit_case_status = variable_struct_exists(_pet_done.current_case, "case_status") ? _pet_done.current_case.case_status : "";

            _owner_done.visit_completed_diagnostics = variable_struct_exists(_pet_done.current_case, "completed_diagnostics") ? _pet_done.current_case.completed_diagnostics : [];
            _owner_done.visit_treatment_progress = variable_struct_exists(_pet_done.current_case, "treatment_progress") ? _pet_done.current_case.treatment_progress : [];
            _owner_done.visit_visible_symptoms = variable_struct_exists(_pet_done.current_case, "visible_symptoms") ? _pet_done.current_case.visible_symptoms : [];
            _owner_done.visit_planned_treatment = variable_struct_exists(_pet_done.current_case, "planned_treatment") ? _pet_done.current_case.planned_treatment : [];

            _owner_done.visit_diagnostics_this_visit = variable_struct_exists(_pet_done.current_case, "visit_diagnostics_done") ? _pet_done.current_case.visit_diagnostics_done : [];
            _owner_done.visit_treatments_this_visit = variable_struct_exists(_pet_done.current_case, "visit_treatments_done") ? _pet_done.current_case.visit_treatments_done : [];
            _owner_done.visit_procedure_log = variable_struct_exists(_pet_done.current_case, "visit_procedure_log") ? _pet_done.current_case.visit_procedure_log : [];

            _owner_done.visit_required_treatment_complete = case_is_required_treatment_complete(_pet_done.current_case);
        }
    }

    if (instance_exists(_owner_done)) {
        db_register_completed_visit(_owner_done);
    }

    // Стоимость добавляем в будущую оплату
    if (instance_exists(_owner_done)) {
        if (!variable_instance_exists(_owner_done, "pending_payment_total")) {
            _owner_done.pending_payment_total = 0;
        }
        _owner_done.pending_payment_total += _payout;
    }

    var _next_proc_id = "";
    var _next_doctor_id = "";

    if (instance_exists(_owner_done) && instance_exists(_pet_done) && variable_instance_exists(_pet_done, "current_case") && is_struct(_pet_done.current_case)) {
        var _owner_id3 = variable_instance_exists(_owner_done, "owner_record_id") ? _owner_done.owner_record_id : "";
        var _pet_id3 = variable_instance_exists(_owner_done, "pet_record_id") ? _owner_done.pet_record_id : "";

        var _next_assignments2 = case_build_next_procedure_assignments(_pet_done.current_case);

        if (_owner_id3 != "" && _pet_id3 != "") {
            if (array_length(_next_assignments2) > 0) {
                _next_proc_id = schedule_procedure_visit(
                    _owner_id3,
                    _pet_id3,
                    _pet_done.current_case,
                    1,
                    "Продолжение процедур"
                );
            } else if (_pet_done.current_case.condition < 100) {
                _next_doctor_id = schedule_followup_visit(
                    _owner_id3,
                    _pet_id3,
                    _pet_done.current_case,
                    1,
                    "Контроль и коррекция лечения"
                );
            }
        }
    }

    // Всегда отправляем на оплату
    if (instance_exists(_owner_done)) {
        reception_enqueue_priority_payment(_owner_done);
    }

    if (instance_exists(obj_UI_HUD)) {
        with (obj_UI_HUD) {
            if (_next_proc_id != "") {
                show_notice("НА ОПЛАТУ", "Процедуры выполнены. Клиент идёт к стойке, следующий процедурный визит назначен.", room_speed * 3);
            } else if (_next_doctor_id != "") {
                show_notice("НА ОПЛАТУ", "Процедуры выполнены. Клиент идёт к стойке, затем будет контроль у врача.", room_speed * 3);
            } else {
                show_notice("НА ОПЛАТУ", "Процедуры выполнены. Клиент идёт к стойке для расчёта.", room_speed * 3);
            }
        }
    }

    player_reset_exam();
};

