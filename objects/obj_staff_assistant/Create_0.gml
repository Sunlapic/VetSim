/// Create obj_staff_assistant
/// @description Ассистент, процедуры и пополнение с учётом уровней навыков.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 1. ВНЕШНОСТЬ И РОЛЬ
// ═══════════════════════════════════════════════════════════════

staff_generate_appearance();
staff_apply_role("assistant");
assistant_extra_skills_init(id);
portrait_bake();

alarm[1] = -1;

home_x = x;
home_y = y;


// ═══════════════════════════════════════════════════════════════
// 2. ШКАЛА ДЕЙСТВИЯ И СОСТОЯНИЯ
// ═══════════════════════════════════════════════════════════════

action_progress_active = false;
action_progress_timer = 0;
action_progress_timer_max = 0;
action_progress_label = "";
action_progress_color = make_color_rgb(80, 170, 90);

assistant_state = "idle";

assigned_owner = noone;
assigned_table = noone;
assigned_pet = noone;

assistant_target_x = x;
assistant_target_y = y;
owner_target_x = x;
owner_target_y = y;
pet_floor_target_x = x;
pet_floor_target_y = y;
pet_table_target_x = x;
pet_table_target_y = y;


// ═══════════════════════════════════════════════════════════════
// 3. ДАННЫЕ ПОПОЛНЕНИЯ
// ═══════════════════════════════════════════════════════════════

restock_item_id = "";
restock_target_cabinet = noone;
restock_qty = 0;
restock_pickup_inst = noone;
action_progress_timer_tick = 0;

procedure_was_interrupted_by_restock = false;
interrupted_procedure_action_id = "";
interrupted_return_point_x = x;
interrupted_return_point_y = y;

// Рассчитывает:
// restock_action_duration = 2,0 ... 0,7 секунды;
// restock_carry_max       = 5 ... 15 предметов.
assistant_recalc_restock_stats(id);


// ═══════════════════════════════════════════════════════════════
// 4. СБРОС ПОПОЛНЕНИЯ
// ═══════════════════════════════════════════════════════════════

assistant_reset_restock = function() {
    // Если задание прервано во время переноски, возвращаем товар на склад.
    if (restock_qty > 0 && restock_item_id != "") {
        inventory_add_amount(
            global.inventory_main,
            restock_item_id,
            restock_qty
        );
    }

    restock_item_id = "";
    restock_target_cabinet = noone;
    restock_qty = 0;
    restock_pickup_inst = noone;
    action_progress_timer_tick = 0;

    action_progress_active = false;
    action_progress_timer = 0;
    action_progress_timer_max = 0;
    action_progress_label = "";

    sprite_index = spr_human_FR_walk;
    image_speed = 0;
    image_index = 0;
};


// ═══════════════════════════════════════════════════════════════
// 5. ПАРАМЕТРЫ ПРОЦЕДУР
// ═══════════════════════════════════════════════════════════════

procedure_skill_value = clamp(assistant_skill_levels[0], 1, 10);
procedure_timer = 0;
procedure_duration = round(
    lerp(
        room_speed * 5,
        room_speed * 2,
        (procedure_skill_value - 1) / 9
    )
);
procedure_condition_before = 0;
procedure_retry = 0;


// ═══════════════════════════════════════════════════════════════
// 6. СБРОС ПРОЦЕДУРЫ
// ═══════════════════════════════════════════════════════════════

assistant_reset_procedure = function() {
    if (instance_exists(assigned_table)) {
        with (assigned_table) {
            table_busy = false;
            assigned_owner = noone;
            assigned_doctor = noone;
            assigned_pet = noone;
        }
    }

    assigned_owner = noone;
    assigned_table = noone;
    assigned_pet = noone;

    procedure_timer = 0;
    procedure_condition_before = 0;

    action_progress_active = false;
    action_progress_timer = 0;
    action_progress_timer_max = 0;

    assistant_reset_restock();

    assistant_state = "idle";
    path_end();
    is_walking = false;
};


// ═══════════════════════════════════════════════════════════════
// 7. ЗАВЕРШЕНИЕ ПРОЦЕДУРНОГО ВИЗИТА
// ═══════════════════════════════════════════════════════════════

assistant_finish_procedure_visit = function() {
    if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
        assistant_reset_procedure();
        return false;
    }

    var _owner_done = assigned_owner;
    var _table_done = assigned_table;
    var _pet_done = assigned_pet;
    var _outcome = undefined;

    if (
        instance_exists(_pet_done)
        && variable_instance_exists(_pet_done, "current_case")
        && is_struct(_pet_done.current_case)
    ) {
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


    // ═══════════════════════════════════════════════════════════
    // 7.1 ДАННЫЕ ВИЗИТА
    // ═══════════════════════════════════════════════════════════

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
            var _case = _pet_done.current_case;

            _owner_done.visit_condition_before = procedure_condition_before;
            _owner_done.visit_condition_after = _case.condition;
            _owner_done.visit_case_id = variable_struct_exists(_case, "case_id") ? _case.case_id : "";
            _owner_done.visit_disease_id = variable_struct_exists(_case, "hidden_disease_id") ? _case.hidden_disease_id : "";
            _owner_done.visit_case_confirmed = variable_struct_exists(_case, "confirmed") ? _case.confirmed : false;
            _owner_done.visit_reveal_level = variable_struct_exists(_case, "reveal_level") ? _case.reveal_level : 0;
            _owner_done.visit_severity_level = variable_struct_exists(_case, "severity_level") ? _case.severity_level : 0;
            _owner_done.visit_severity_name_ru = variable_struct_exists(_case, "severity_name_ru") ? _case.severity_name_ru : "";
            _owner_done.visit_case_status = variable_struct_exists(_case, "case_status") ? _case.case_status : "";
            _owner_done.visit_completed_diagnostics = variable_struct_exists(_case, "completed_diagnostics") ? _case.completed_diagnostics : [];
            _owner_done.visit_treatment_progress = variable_struct_exists(_case, "treatment_progress") ? _case.treatment_progress : [];
            _owner_done.visit_visible_symptoms = variable_struct_exists(_case, "visible_symptoms") ? _case.visible_symptoms : [];
            _owner_done.visit_planned_treatment = variable_struct_exists(_case, "planned_treatment") ? _case.planned_treatment : [];
            _owner_done.visit_diagnostics_this_visit = variable_struct_exists(_case, "visit_diagnostics_done") ? _case.visit_diagnostics_done : [];
            _owner_done.visit_treatments_this_visit = variable_struct_exists(_case, "visit_treatments_done") ? _case.visit_treatments_done : [];
            _owner_done.visit_procedure_log = variable_struct_exists(_case, "visit_procedure_log") ? _case.visit_procedure_log : [];
            _owner_done.visit_required_treatment_complete = case_is_required_treatment_complete(_case);
        }

        db_register_completed_visit(_owner_done);

        if (!variable_instance_exists(_owner_done, "pending_payment_total")) {
            _owner_done.pending_payment_total = 0;
        }

        _owner_done.pending_payment_total += _payout;
    }


    // ═══════════════════════════════════════════════════════════
    // 7.2 СЛЕДУЮЩИЙ ВИЗИТ
    // ═══════════════════════════════════════════════════════════

    var _next_procedure_id = "";
    var _next_doctor_id = "";

    if (
        instance_exists(_owner_done)
        && instance_exists(_pet_done)
        && is_struct(_pet_done.current_case)
    ) {
        var _owner_record_id = variable_instance_exists(_owner_done, "owner_record_id")
            ? _owner_done.owner_record_id
            : "";
        var _pet_record_id = variable_instance_exists(_owner_done, "pet_record_id")
            ? _owner_done.pet_record_id
            : "";
        var _next_assignments = case_build_next_procedure_assignments(
            _pet_done.current_case
        );

        if (_owner_record_id != "" && _pet_record_id != "") {
            if (array_length(_next_assignments) > 0) {
                _next_procedure_id = schedule_procedure_visit(
                    _owner_record_id,
                    _pet_record_id,
                    _pet_done.current_case,
                    1,
                    "Продолжение процедур"
                );
            }
            else if (_pet_done.current_case.condition < 100) {
                _next_doctor_id = schedule_followup_visit(
                    _owner_record_id,
                    _pet_record_id,
                    _pet_done.current_case,
                    1,
                    "Контроль и коррекция лечения"
                );
            }
        }
    }

    if (instance_exists(_owner_done)) {
        reception_enqueue_priority_payment(_owner_done);
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


    // ═══════════════════════════════════════════════════════════
    // 7.3 УВЕДОМЛЕНИЕ
    // ═══════════════════════════════════════════════════════════

    if (instance_exists(obj_UI_HUD)) {
        with (obj_UI_HUD) {
            if (_next_procedure_id != "") {
                show_notice(
                    "АССИСТЕНТ",
                    "Процедуры выполнены. Следующий процедурный визит назначен.",
                    room_speed * 3
                );
            }
            else if (_next_doctor_id != "") {
                show_notice(
                    "АССИСТЕНТ",
                    "Процедуры выполнены. Пациенту нужен контроль у врача.",
                    room_speed * 3
                );
            } else {
                show_notice(
                    "АССИСТЕНТ",
                    "Процедуры выполнены. Клиент направлен на оплату.",
                    room_speed * 3
                );
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 7.4 ВОЗВРАЩЕНИЕ
    // ═══════════════════════════════════════════════════════════

    assigned_owner = noone;
    assigned_table = noone;
    assigned_pet = noone;

    procedure_timer = 0;
    procedure_condition_before = 0;

    action_progress_active = false;
    action_progress_timer = 0;
    action_progress_timer_max = 0;

    assistant_state = "returning";

    path_end();

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
    } else {
        assistant_state = "idle";
        is_walking = false;
    }

    return true;
};


function staff_apply_role(_role) {
    role = _role;

    skills = array_create(10, 1);
    skills_sum = 0;

    var _best_value = -1;
    var _best_index = 0;

    for (var i = 0; i < 10; i++) {
        var _value = irandom_range(1, 7);

        switch (_role) {
            case "doctor":
                if (i == 0 || i == 1) _value += 3;
            break;

            case "assistant":
                if (i == 2 || i == 3) _value += 2;
            break;

            case "admin":
                if (i == 4 || i == 5) _value += 3;
            break;
        }

        _value = clamp(_value, 1, 10);
        skills[i] = _value;
        skills_sum += _value;

        if (_value > _best_value) {
            _best_value = _value;
            _best_index = i;
        }
    }

    var _titles = [
        "ТЕРАПЕВТ",
        "ХИРУРГ",
        "ВРАЧ СТАЦИОНАРА",
        "ФЕЛЬДШЕР",
        "ЛАБОРАНТ",
        "ВРАЧ УЗИ",
        "РЕНТГЕНОЛОГ",
        "АНЕСТЕЗИОЛОГ",
        "ДЕРМАТОЛОГ",
        "СТОМАТОЛОГ"
    ];

    if (_role == "admin") {
        specialty_title = "АДМИНИСТРАТОР";
    } else if (_role == "assistant") {
        specialty_title = "";
    } else {
        // Для врача: выбираем по самому высокому навыку, при равенстве — случайно
        if (_role == "doctor") {
            var _doctor_best = [];
            for (var _d = 0; _d < 10; _d++) {
                if (skills[_d] == _best_value) array_push(_doctor_best, _d);
            }
            if (array_length(_doctor_best) > 0) {
                _best_index = _doctor_best[irandom_range(0, array_length(_doctor_best) - 1)];
            }
        }
        specialty_title = _titles[_best_index];
    }
}
