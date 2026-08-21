/// db_register_completed_visit(_owner_inst)
/// @description Сохраняет владельца, питомца и полный медицинский итог визита.

function db_register_completed_visit(_owner_inst) {
    if (!instance_exists(_owner_inst)) return "";

    // История визита сохраняет тот же итог, который увидит владелец в чеке.
    finance_owner_rebuild_invoice(_owner_inst);

    var _owner_id = "";
    var _pet_id = "";
    var _pet_inst = noone;


    // ═══════════════════════════════════════════════════════════
    // 1. ВЛАДЕЛЕЦ: СОЗДАНИЕ ИЛИ ОБНОВЛЕНИЕ ЗАПИСИ
    // ═══════════════════════════════════════════════════════════

    if (variable_instance_exists(_owner_inst, "owner_record_id")) {
        _owner_id = _owner_inst.owner_record_id;
    }

    if (_owner_id == "" || !variable_struct_exists(global.owner_db, _owner_id)) {
        var _owner_record = db_make_owner_record_from_instance(_owner_inst);

        if (!is_struct(_owner_record)) return "";

        _owner_id = _owner_record.owner_id;
        variable_struct_set(global.owner_db, _owner_id, _owner_record);
        array_push(global.owner_list, _owner_id);
        _owner_inst.owner_record_id = _owner_id;
    }

    var _owner_ref = variable_struct_get(global.owner_db, _owner_id);

    if (!variable_struct_exists(_owner_ref, "pet_ids")) {
        _owner_ref.pet_ids = [];
    }

    if (!variable_struct_exists(_owner_ref, "visits_total")) {
        _owner_ref.visits_total = 0;
    }

    _owner_ref.last_visit_day = global.game_day;
    _owner_ref.visits_total += 1;

    if (variable_instance_exists(_owner_inst, "stat_money")) {
        _owner_ref.money = _owner_inst.stat_money;
    }

    if (variable_instance_exists(_owner_inst, "stat_patience")) {
        _owner_ref.patience = _owner_inst.stat_patience;
    }

    if (variable_instance_exists(_owner_inst, "patience_level")) {
        _owner_ref.patience_level = clamp(round(_owner_inst.patience_level), 1, 10);
    }

    _owner_ref.patience_success_progress = variable_instance_exists(
        _owner_inst,
        "patience_success_progress"
    ) ? clamp(round(_owner_inst.patience_success_progress), 0, 4) : 0;

    _owner_ref.walk_speed_level = variable_instance_exists(_owner_inst, "owner_walk_speed_level")
        ? clamp(round(_owner_inst.owner_walk_speed_level), 1, 10)
        : owner_roll_walk_speed_level(_owner_inst.age);

    _owner_ref.walk_speed_percent = 100
        + (_owner_ref.walk_speed_level - 1) * 10;

    if (variable_instance_exists(_owner_inst, "owner_trust")) {
        _owner_ref.trust = _owner_inst.owner_trust;
    }

    // Лояльность хранится отдельно от старого owner_trust.
    _owner_ref.loyalty_level = variable_instance_exists(_owner_inst, "loyalty_level")
        ? clamp(round(_owner_inst.loyalty_level), 1, 10)
        : 5;

    _owner_ref.loyalty_success_progress = variable_instance_exists(_owner_inst, "loyalty_success_progress")
        ? clamp(round(_owner_inst.loyalty_success_progress), 0, 4)
        : 0;

    _owner_ref.owner_feature_id = variable_instance_exists(_owner_inst, "owner_feature_id")
        ? string(_owner_inst.owner_feature_id)
        : "none";

    _owner_ref.owner_feature_name_ru = variable_instance_exists(_owner_inst, "owner_feature_name_ru")
        ? string(_owner_inst.owner_feature_name_ru)
        : "Нет особенности";


    // ═══════════════════════════════════════════════════════════
    // 2. ПИТОМЕЦ: СОЗДАНИЕ ИЛИ ОБНОВЛЕНИЕ ЗАПИСИ
    // ═══════════════════════════════════════════════════════════

    if (variable_instance_exists(_owner_inst, "my_pet") && instance_exists(_owner_inst.my_pet)) {
        _pet_inst = _owner_inst.my_pet;

        if (variable_instance_exists(_owner_inst, "pet_record_id")) {
            _pet_id = _owner_inst.pet_record_id;
        }

        if (_pet_id == "" || !variable_struct_exists(global.pet_db, _pet_id)) {
            var _pet_record = db_make_pet_record_from_instance(_pet_inst, _owner_id);

            if (is_struct(_pet_record)) {
                _pet_id = _pet_record.pet_id;
                variable_struct_set(global.pet_db, _pet_id, _pet_record);
                array_push(global.pet_list, _pet_id);
                _owner_inst.pet_record_id = _pet_id;
            }
        }

        if (_pet_id != "") {
            var _has_pet_id = false;

            for (var _pet_index = 0; _pet_index < array_length(_owner_ref.pet_ids); _pet_index++) {
                if (_owner_ref.pet_ids[_pet_index] == _pet_id) {
                    _has_pet_id = true;
                    break;
                }
            }

            if (!_has_pet_id) {
                array_push(_owner_ref.pet_ids, _pet_id);
            }
        }

        if (_pet_id != "" && variable_struct_exists(global.pet_db, _pet_id)) {
            var _pet_ref = variable_struct_get(global.pet_db, _pet_id);

            if (!variable_struct_exists(_pet_ref, "visit_history")) {
                _pet_ref.visit_history = [];
            }

            _pet_ref.owner_id = _owner_id;

            if (variable_instance_exists(_pet_inst, "char_name")) {
                _pet_ref.name = string(_pet_inst.char_name);
            }

            if (variable_instance_exists(_pet_inst, "species_id")) {
                _pet_ref.species = string(_pet_inst.species_id);
            }

            if (variable_instance_exists(_pet_inst, "breed")) {
                _pet_ref.breed = string(_pet_inst.breed);
            }

            if (variable_instance_exists(_pet_inst, "age")) {
                _pet_ref.age_text = string(_pet_inst.age);
            }

            if (variable_instance_exists(_pet_inst, "pet_age_days")) {
                _pet_ref.pet_age_days = max(0, round(_pet_inst.pet_age_days));
            }

            if (variable_instance_exists(_pet_inst, "problem")) {
                _pet_ref.problem = string(_pet_inst.problem);
            }

            if (variable_instance_exists(_pet_inst, "condition")) {
                _pet_ref.condition = _pet_inst.condition;
            }

            if (variable_instance_exists(_pet_inst, "life_stage")) {
                _pet_ref.life_stage = _pet_inst.life_stage;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 3. МЕДИЦИНСКИЕ ДАННЫЕ ИЗ ВЛАДЕЛЬЦА
    // ═══════════════════════════════════════════════════════════

    var _case_id = variable_instance_exists(_owner_inst, "visit_case_id")
        ? _owner_inst.visit_case_id : "";
    var _disease_id = variable_instance_exists(_owner_inst, "visit_disease_id")
        ? _owner_inst.visit_disease_id : "";
    var _case_confirmed = variable_instance_exists(_owner_inst, "visit_case_confirmed")
        ? _owner_inst.visit_case_confirmed : false;
    var _reveal_level = variable_instance_exists(_owner_inst, "visit_reveal_level")
        ? _owner_inst.visit_reveal_level : 0;
    var _severity_level = variable_instance_exists(_owner_inst, "visit_severity_level")
        ? _owner_inst.visit_severity_level : 0;
    var _severity_name_ru = variable_instance_exists(_owner_inst, "visit_severity_name_ru")
        ? _owner_inst.visit_severity_name_ru : "";
    var _case_status = variable_instance_exists(_owner_inst, "visit_case_status")
        ? _owner_inst.visit_case_status : "";

    var _required_treatment_complete = variable_instance_exists(_owner_inst, "visit_required_treatment_complete")
        ? _owner_inst.visit_required_treatment_complete : false;

    var _outcome_id = variable_instance_exists(_owner_inst, "visit_outcome_id")
        ? _owner_inst.visit_outcome_id : "outcome_generic";
    var _outcome_name_ru = variable_instance_exists(_owner_inst, "visit_outcome_name_ru")
        ? _owner_inst.visit_outcome_name_ru : "Приём завершён";
    var _trust_delta = variable_instance_exists(_owner_inst, "visit_trust_delta")
        ? _owner_inst.visit_trust_delta : 0;
    var _payout_mult = variable_instance_exists(_owner_inst, "visit_payout_mult")
        ? _owner_inst.visit_payout_mult : 0.50;

    var _condition_before = variable_instance_exists(_owner_inst, "visit_condition_before")
        ? _owner_inst.visit_condition_before : 0;
    var _condition_after = variable_instance_exists(_owner_inst, "visit_condition_after")
        ? _owner_inst.visit_condition_after : _condition_before;

    var _followup_planned = variable_instance_exists(_owner_inst, "visit_followup_planned")
        ? _owner_inst.visit_followup_planned : false;
    var _followup_days = variable_instance_exists(_owner_inst, "visit_followup_days")
        ? _owner_inst.visit_followup_days : 0;
    var _followup_reason = variable_instance_exists(_owner_inst, "visit_followup_reason")
        ? _owner_inst.visit_followup_reason : "";

    var _completed_diagnostics = variable_instance_exists(_owner_inst, "visit_completed_diagnostics")
        ? _owner_inst.visit_completed_diagnostics : [];
    var _treatment_progress = variable_instance_exists(_owner_inst, "visit_treatment_progress")
        ? _owner_inst.visit_treatment_progress : [];
    var _visible_symptoms = variable_instance_exists(_owner_inst, "visit_visible_symptoms")
        ? _owner_inst.visit_visible_symptoms : [];
    var _planned_treatment = variable_instance_exists(_owner_inst, "visit_planned_treatment")
        ? _owner_inst.visit_planned_treatment : [];
    var _diagnostics_this_visit = variable_instance_exists(_owner_inst, "visit_diagnostics_this_visit")
        ? _owner_inst.visit_diagnostics_this_visit : [];
    var _treatments_this_visit = variable_instance_exists(_owner_inst, "visit_treatments_this_visit")
        ? _owner_inst.visit_treatments_this_visit : [];
    var _procedure_log = variable_instance_exists(_owner_inst, "visit_procedure_log")
        ? _owner_inst.visit_procedure_log : [];


    // ═══════════════════════════════════════════════════════════
    // 4. РЕЗЕРВНЫЕ ДАННЫЕ ИЗ CURRENT_CASE ПИТОМЦА
    // ═══════════════════════════════════════════════════════════

    if (
        instance_exists(_pet_inst)
        && variable_instance_exists(_pet_inst, "current_case")
        && is_struct(_pet_inst.current_case)
    ) {
        var _case = _pet_inst.current_case;

        if (_case_id == "" && variable_struct_exists(_case, "case_id")) {
            _case_id = _case.case_id;
        }

        if (_disease_id == "" && variable_struct_exists(_case, "hidden_disease_id")) {
            _disease_id = _case.hidden_disease_id;
        }

        if (!_case_confirmed && variable_struct_exists(_case, "confirmed")) {
            _case_confirmed = _case.confirmed;
        }

        if (_reveal_level <= 0 && variable_struct_exists(_case, "reveal_level")) {
            _reveal_level = _case.reveal_level;
        }

        if (_severity_level <= 0 && variable_struct_exists(_case, "severity_level")) {
            _severity_level = _case.severity_level;
        }

        if (_severity_name_ru == "" && variable_struct_exists(_case, "severity_name_ru")) {
            _severity_name_ru = _case.severity_name_ru;
        }

        if (_case_status == "" && variable_struct_exists(_case, "case_status")) {
            _case_status = _case.case_status;
        }

        if (array_length(_completed_diagnostics) <= 0 && variable_struct_exists(_case, "completed_diagnostics")) {
            _completed_diagnostics = _case.completed_diagnostics;
        }

        if (array_length(_treatment_progress) <= 0 && variable_struct_exists(_case, "treatment_progress")) {
            _treatment_progress = _case.treatment_progress;
        }

        if (array_length(_visible_symptoms) <= 0 && variable_struct_exists(_case, "visible_symptoms")) {
            _visible_symptoms = _case.visible_symptoms;
        }

        if (array_length(_planned_treatment) <= 0 && variable_struct_exists(_case, "planned_treatment")) {
            _planned_treatment = _case.planned_treatment;
        }

        if (array_length(_diagnostics_this_visit) <= 0 && variable_struct_exists(_case, "visit_diagnostics_done")) {
            _diagnostics_this_visit = _case.visit_diagnostics_done;
        }

        if (array_length(_treatments_this_visit) <= 0 && variable_struct_exists(_case, "visit_treatments_done")) {
            _treatments_this_visit = _case.visit_treatments_done;
        }

        if (array_length(_procedure_log) <= 0 && variable_struct_exists(_case, "visit_procedure_log")) {
            _procedure_log = _case.visit_procedure_log;
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 5. ЗАПИСЬ ВИЗИТА
    // ═══════════════════════════════════════════════════════════

    var _visit_id = db_next_visit_id();

    var _visit_record = {
        visit_id : _visit_id,
        owner_id : _owner_id,
        pet_id : _pet_id,

        visit_day : global.game_day,
        visit_hour : global.game_hour,
        visit_minute : global.game_minute,
        status : "completed",

        is_followup : (
            variable_instance_exists(_owner_inst, "scheduled_visit_id")
            && _owner_inst.scheduled_visit_id != ""
        ),
        scheduled_visit_id : variable_instance_exists(_owner_inst, "scheduled_visit_id")
            ? _owner_inst.scheduled_visit_id : "",

        visit_type_id : variable_instance_exists(_owner_inst, "visit_type_id")
            ? _owner_inst.visit_type_id : "primary_exam",
        visit_type_name_ru : variable_instance_exists(_owner_inst, "visit_type_name_ru")
            ? _owner_inst.visit_type_name_ru : "Первичный приём",
        visit_reason_ru : variable_instance_exists(_owner_inst, "visit_reason_ru")
            ? _owner_inst.visit_reason_ru : "",
        paid_amount : variable_instance_exists(_owner_inst, "visit_price")
            ? _owner_inst.visit_price : 0,

        case_id : _case_id,
        disease_id : _disease_id,
        case_confirmed : _case_confirmed,
        reveal_level : _reveal_level,
        severity_level : _severity_level,
        severity_name_ru : _severity_name_ru,
        case_status : _case_status,

        completed_diagnostics : _completed_diagnostics,
        treatment_progress : _treatment_progress,
        visible_symptoms : _visible_symptoms,
        planned_treatment : _planned_treatment,
        diagnostics_this_visit : _diagnostics_this_visit,
        treatments_this_visit : _treatments_this_visit,
        procedure_log : _procedure_log,
        required_treatment_complete : _required_treatment_complete,

        outcome_id : _outcome_id,
        outcome_name_ru : _outcome_name_ru,
        trust_delta : _trust_delta,
        payout_mult : _payout_mult,
        condition_before : _condition_before,
        condition_after : _condition_after,

        followup_planned : _followup_planned,
        followup_days : _followup_days,
        followup_reason : _followup_reason,
        followup_created : false,
        scheduled_followup_id : ""
    };

    variable_struct_set(global.visit_db, _visit_id, _visit_record);
    array_push(global.visit_list, _visit_id);

    _owner_inst.visit_id = _visit_id;


    // ═══════════════════════════════════════════════════════════
    // 6. ПОСЛЕДНИЕ ДАННЫЕ ВЛАДЕЛЬЦА И ПИТОМЦА
    // ═══════════════════════════════════════════════════════════

    _owner_ref.last_visit_id = _visit_id;
    _owner_ref.last_pet_id = _pet_id;
    _owner_ref.last_outcome_id = _outcome_id;
    _owner_ref.last_outcome_name_ru = _outcome_name_ru;
    _owner_ref.last_disease_id = _disease_id;

    if (_pet_id != "" && variable_struct_exists(global.pet_db, _pet_id)) {
        var _pet_ref2 = variable_struct_get(global.pet_db, _pet_id);

        if (!variable_struct_exists(_pet_ref2, "visit_history")) {
            _pet_ref2.visit_history = [];
        }

        array_push(_pet_ref2.visit_history, _visit_id);

        _pet_ref2.last_visit_id = _visit_id;
        _pet_ref2.last_visit_day = global.game_day;
        _pet_ref2.last_disease_id = _disease_id;
        _pet_ref2.last_outcome_id = _outcome_id;
        _pet_ref2.last_outcome_name_ru = _outcome_name_ru;
        _pet_ref2.last_condition_after = _condition_after;
        _pet_ref2.last_case_id = _case_id;
        _pet_ref2.last_severity_level = _severity_level;
        _pet_ref2.last_severity_name_ru = _severity_name_ru;
    }


    // ═══════════════════════════════════════════════════════════
    // 7. ЗАКРЫТИЕ ЗАПЛАНИРОВАННОГО ВИЗИТА
    // ═══════════════════════════════════════════════════════════

    if (
        variable_instance_exists(_owner_inst, "scheduled_visit_id")
        && _owner_inst.scheduled_visit_id != ""
    ) {
        for (var _schedule_index = 0; _schedule_index < array_length(global.scheduled_visits); _schedule_index++) {
            if (
                global.scheduled_visits[_schedule_index].scheduled_visit_id
                == _owner_inst.scheduled_visit_id
            ) {
                global.scheduled_visits[_schedule_index].status = "completed";
                break;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 8. БАЛЛЫ КЛИНИКИ (пакет №71)
    // +1 балл за полное выздоровление (состояние 100%).
    // Если пациент вылечился в стационаре, балл уже выдан там и помечен
    // флагом на питомце — повторное начисление здесь не произойдёт.
    // ═══════════════════════════════════════════════════════════

    if (_condition_after >= 100) {
        var _already_awarded = (
            instance_exists(_pet_inst)
            && variable_instance_exists(_pet_inst, "clinic_points_cure_awarded")
            && _pet_inst.clinic_points_cure_awarded
        );

        if (!_already_awarded) {
            clinic_points_add(1);

            if (instance_exists(_pet_inst)) {
                _pet_inst.clinic_points_cure_awarded = true;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 9. DEBUG
    // ═══════════════════════════════════════════════════════════

    show_debug_message("OWNER SAVED: " + string(_owner_id));
    show_debug_message("PET SAVED: " + string(_pet_id));
    show_debug_message("VISIT SAVED: " + string(_visit_id));

    return _visit_id;
}
