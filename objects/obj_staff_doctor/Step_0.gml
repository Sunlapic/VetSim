/// Step obj_staff_doctor

event_inherited();

// Инициализация терапии врача
if (!variable_instance_exists(id, "therapy_xp")) {

    var _start_level = 1;

    if (variable_instance_exists(id, "skills")) {
        if (array_length(skills) > 0) {
            _start_level = clamp(skills[0], 1, 10);
        }
    }

    therapy_xp = 0;

    for (var _lvl = 1; _lvl < _start_level; _lvl++) {
        therapy_xp += doctor_therapy_xp_needed(_lvl);
    }

    doctor_recalc_therapy_progress(id);
}

// Инициализация прогресс-бара
if (!variable_instance_exists(id, "action_progress_active")) {
    action_progress_active = false;
    action_progress_timer = 0;
    action_progress_timer_max = 0;
    action_progress_label = "";
    action_progress_color = make_color_rgb(80, 140, 220);
}

action_progress_active = false;

// Внутренние данные текущего приёма
if (!variable_instance_exists(id, "doctor_exam_condition_before")) doctor_exam_condition_before = 0;

// Страховка от битых ссылок
if (!instance_exists(assigned_owner)) assigned_owner = noone;
if (!instance_exists(assigned_table)) assigned_table = noone;
if (!instance_exists(assigned_pet)) assigned_pet = noone;

switch (doctor_state) {

    // ─────────────────────────────────────────
    // 1. ИЩЕМ ПЕРВОГО ЖДУЩЕГО ВЛАДЕЛЬЦА И СВОБОДНЫЙ СТОЛ
    // ─────────────────────────────────────────
    case "idle":
        if (variable_instance_exists(id, "is_exhausted") && is_exhausted) {
            // Вымотан — не берём нового пациента, ждём пока энергия восстановится
            doctor_state = "idle";
            break;
        }
        var _best_owner = noone;
        var _best_wait_index = 999999;

        for (var i = 0; i < instance_number(obj_owner); i++) {
            var _o = instance_find(obj_owner, i);
            if (!instance_exists(_o)) continue;

            if (_o.state == "waiting"
            && _o.assigned_doctor == noone
            && variable_instance_exists(_o, "service_queue_type")
            && _o.service_queue_type == "doctor") {

                if (_o.wait_spot_index >= 0 && _o.wait_spot_index < _best_wait_index) {
                    _best_wait_index = _o.wait_spot_index;
                    _best_owner = _o;
                }
            }
        }

        var _free_table = noone;
        var _doc_point = noone;
        var _owner_point = noone;
        var _pet_floor_point = noone;
        var _pet_table_point = noone;

        // Ищем среди obj_table
        for (var t = 0; t < instance_number(obj_table); t++) {
            var _tbl = instance_find(obj_table, t);
            if (!instance_exists(_tbl)) continue;
            if (_tbl.table_busy) continue;

            var _slot = _tbl.exam_slot_id;

            var _d = noone;
            var _o2 = noone;
            var _pf = noone;
            var _pt = noone;

            for (var pd = 0; pd < instance_number(obj_exam_point_doctor); pd++) {
                var _pd = instance_find(obj_exam_point_doctor, pd);
                if (instance_exists(_pd) && _pd.exam_slot_id == _slot) { _d = _pd; break; }
            }

            for (var po = 0; po < instance_number(obj_exam_point_owner); po++) {
                var _po = instance_find(obj_exam_point_owner, po);
                if (instance_exists(_po) && _po.exam_slot_id == _slot) { _o2 = _po; break; }
            }

            for (var ppf = 0; ppf < instance_number(obj_exam_point_pet_floor); ppf++) {
                var _ppf = instance_find(obj_exam_point_pet_floor, ppf);
                if (instance_exists(_ppf) && _ppf.exam_slot_id == _slot) { _pf = _ppf; break; }
            }

            for (var ppt = 0; ppt < instance_number(obj_exam_point_pet_table); ppt++) {
                var _ppt = instance_find(obj_exam_point_pet_table, ppt);
                if (instance_exists(_ppt) && _ppt.exam_slot_id == _slot) { _pt = _ppt; break; }
            }

            if (instance_exists(_d) && instance_exists(_o2) && instance_exists(_pf) && instance_exists(_pt)) {
                _free_table = _tbl;
                _doc_point = _d;
                _owner_point = _o2;
                _pet_floor_point = _pf;
                _pet_table_point = _pt;
                break;
            }
        }

        // Если не нашли — ищем среди obj_table_1
        if (_free_table == noone) {
            for (var t2 = 0; t2 < instance_number(obj_table_1); t2++) {
                var _tbl2 = instance_find(obj_table_1, t2);
                if (!instance_exists(_tbl2)) continue;
                if (_tbl2.table_busy) continue;

                var _slot2 = _tbl2.exam_slot_id;

                var _d2 = noone;
                var _o3 = noone;
                var _pf2 = noone;
                var _pt2 = noone;

                for (var pd2 = 0; pd2 < instance_number(obj_exam_point_doctor); pd2++) {
                    var _pd2 = instance_find(obj_exam_point_doctor, pd2);
                    if (instance_exists(_pd2) && _pd2.exam_slot_id == _slot2) { _d2 = _pd2; break; }
                }

                for (var po2 = 0; po2 < instance_number(obj_exam_point_owner); po2++) {
                    var _po2 = instance_find(obj_exam_point_owner, po2);
                    if (instance_exists(_po2) && _po2.exam_slot_id == _slot2) { _o3 = _po2; break; }
                }

                for (var ppf2 = 0; ppf2 < instance_number(obj_exam_point_pet_floor); ppf2++) {
                    var _ppf2 = instance_find(obj_exam_point_pet_floor, ppf2);
                    if (instance_exists(_ppf2) && _ppf2.exam_slot_id == _slot2) { _pf2 = _ppf2; break; }
                }

                for (var ppt2 = 0; ppt2 < instance_number(obj_exam_point_pet_table); ppt2++) {
                    var _ppt2 = instance_find(obj_exam_point_pet_table, ppt2);
                    if (instance_exists(_ppt2) && _ppt2.exam_slot_id == _slot2) { _pt2 = _ppt2; break; }
                }

                if (instance_exists(_d2) && instance_exists(_o3) && instance_exists(_pf2) && instance_exists(_pt2)) {
                    _free_table = _tbl2;
                    _doc_point = _d2;
                    _owner_point = _o3;
                    _pet_floor_point = _pf2;
                    _pet_table_point = _pt2;
                    break;
                }
            }
        }

        if (instance_exists(_best_owner) && instance_exists(_free_table)) {

            assigned_owner = _best_owner;
            assigned_table = _free_table;
            assigned_pet = instance_exists(_best_owner.my_pet) ? _best_owner.my_pet : noone;

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

            path_end();

            var _meet_x = assigned_owner.x + 28;
            var _meet_y = assigned_owner.y;

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
        }

    break;

    // ─────────────────────────────────────────
    // 2. ДОКТОР ПОДОШЕЛ К ВЛАДЕЛЬЦУ
    // ─────────────────────────────────────────
    case "going_to_owner":

        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {

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
            doctor_state = "idle";
            break;
        }

        if (point_distance(x, y, assigned_owner.x, assigned_owner.y) <= 40) {

            with (assigned_owner) {

                assigned_doctor = other.id;
                assigned_table  = other.assigned_table;

                if (wait_spot_index >= 0) {
                    if (variable_global_exists("wait_spots")) {
                        if (wait_spot_index < array_length(global.wait_spots)) {
                            global.wait_spots[wait_spot_index].occupied_by = noone;
                        }
                    }
                    wait_spot_index = -1;
                }

                exam_target_x = other.owner_target_x;
                exam_target_y = other.owner_target_y;

                state = "going_to_exam";
                path_end();
                is_walking = false;

                // ── Ищем достижимую точку рядом с целью ──
                var _tx = exam_target_x;
                var _ty = exam_target_y;
                var _built = false;

                if (mp_grid_path(global.ai_grid, my_path, x, y, _tx, _ty, true)) {
                    _built = true;
                } else {
                    // Смещения: 8 направлений × 3 дистанции = 24 попытки
                    var _offs = [-32, -24, -16, 0, 16, 24, 32];
                    for (var _ox = 0; _ox < array_length(_offs); _ox++) {
                        for (var _oy = 0; _oy < array_length(_offs); _oy++) {
                            if (_ox == 3 && _oy == 3) continue; // смещение 0,0 уже пробовали
                            var _ax = exam_target_x + _offs[_ox];
                            var _ay = exam_target_y + _offs[_oy];
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
                    exam_target_x = _tx;
                    exam_target_y = _ty;
                    path_set_kind(my_path, 1);
                    path_start(my_path, p_move_speed, path_action_stop, true);
                    is_walking = true;
                } else {
                    // Ни одна точка не строится — идём по прямой (НЕ ТЕЛЕПОРТИРУЕМ!)
                    // Доводка и переключение в in_exam делает БЛОК 2 в Step владельца
                    is_walking = true;
                    move_towards_point(exam_target_x, exam_target_y, p_move_speed);
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

                    if (mp_grid_path(global.ai_grid, my_path, x, y, exam_floor_x, exam_floor_y, true)) {
                        path_set_kind(my_path, 1);
                        path_start(my_path, p_move_speed, path_action_stop, true);
                        is_walking = true;
                    } else {
                        x = exam_floor_x;
                        y = exam_floor_y;
                        state = "jumping_to_table";
                        is_walking = false;
                    }
                }
            }

            path_end();

            if (mp_grid_path(global.ai_grid, my_path, x, y, doctor_target_x, doctor_target_y, true)) {
                path_set_kind(my_path, 1);
                path_start(my_path, p_move_speed, path_action_stop, true);
                is_walking = true;
            } else {
                x = doctor_target_x;
                y = doctor_target_y;
                is_walking = false;
            }

            doctor_state = "going_to_doctor_point";
        }

    break;

    // ─────────────────────────────────────────
    // 3. ДОКТОР ДОШЕЛ ДО СВОЕЙ ТОЧКИ
    // ─────────────────────────────────────────
    case "going_to_doctor_point":

        if (point_distance(x, y, doctor_target_x, doctor_target_y) <= 10) {
            path_end();
            is_walking = false;
            doctor_state = "waiting_positions";
        }

    break;

    // ─────────────────────────────────────────
    // 4. ЖДЁМ, ПОКА ВЛАДЕЛЕЦ И ПИТОМЕЦ ДОЙДУТ
    // ─────────────────────────────────────────
    case "waiting_positions":

        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {

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
            doctor_state = "idle";
            break;
        }

        var _owner_ready = (assigned_owner.state == "in_exam");
        var _pet_ready = true;

        if (instance_exists(assigned_pet)) {
            _pet_ready = (assigned_pet.state == "in_exam");
        }

        if (_owner_ready && _pet_ready) {

            if (instance_exists(assigned_pet) && variable_instance_exists(assigned_pet, "current_case") && is_struct(assigned_pet.current_case)) {
                doctor_exam_condition_before = assigned_pet.current_case.condition;
                animal_perform_physical_exam(assigned_pet);
            } else {
                doctor_exam_condition_before = 0;
            }

            var _exam_frames = doctor_get_exam_duration_frames(therapy_level);
            exam_timer = _exam_frames;
            exam_timer_max = _exam_frames;
            doctor_state = "examining";
        }

    break;

    // ─────────────────────────────────────────
    // 5. ПРИЁМ NPC-ВРАЧА (исправленный XP + выносливость)
    // ─────────────────────────────────────────
    case "examining":
        action_progress_active = true;
        action_progress_timer = exam_timer;
        action_progress_timer_max = exam_timer_max;
        action_progress_label = "ПРИЁМ";
        action_progress_color = make_color_rgb(80, 140, 220);
        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
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
            exam_timer = 0;
            exam_timer_max = 0;
            doctor_state = "idle";
            break;
        }
        exam_timer -= 1;
        if (exam_timer <= 0) {
            var _owner_done = assigned_owner;
            var _table_done = assigned_table;
            var _pet_done   = assigned_pet;

            // СТАВИМ ДИАГНОЗ ПОСЛЕ ОБСЛЕДОВАНИЯ (NPC-врач не ошибается)
            if (instance_exists(_pet_done) && variable_instance_exists(_pet_done, "current_case") && is_struct(_pet_done.current_case)) {
                var _case = _pet_done.current_case;
                if (variable_struct_exists(_case, "hidden_disease_id")) {
                    _case.selected_disease_id = _case.hidden_disease_id;
                }
                _case.confirmed = true;
                _case.case_status = "diagnosed";
                if (variable_global_exists("daily_stats")) {
                    global.daily_stats.new_diagnosed += 1;
                }
                // Пакет №67: вместо фиктивного id "doctor_exam" логируем
                // настоящий первичный осмотр. case_add_diagnostic защищён
                // от повторов, поэтому дублей в чеке не появится.
                _case = case_add_diagnostic(_case, "diag_physical_exam");
            }

            // 1. Врач автоматически назначает ВСЕ правильные доступные назначения
            if (instance_exists(_pet_done) && variable_instance_exists(_pet_done, "current_case") && is_struct(_pet_done.current_case)) {
                var _auto_choices = case_get_visible_treatment(_pet_done.current_case, therapy_level);
                for (var _ch = 0; _ch < array_length(_auto_choices); _ch++) {
                    var _choice = _auto_choices[_ch];
                    if (_choice.is_correct) {
                        case_assign_treatment_action(_pet_done, _choice.action_id);
                    }
                }
            }

            // 2. Освобождаем стол
            with (_table_done) {
                table_busy = false;
                assigned_owner = noone;
                assigned_doctor = noone;
                assigned_pet = noone;
            }

            // 3. Собираем итоговые данные уже ПОСЛЕ назначений
            var _outcome = undefined;
            var _condition_before = doctor_exam_condition_before;
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
                _required_complete = case_is_required_treatment_complete(_pet_done.current_case);
                _case_confirmed = _pet_done.current_case.confirmed;
                _outcome = case_evaluate_outcome(_pet_done.current_case);
                if (variable_struct_exists(_pet_done.current_case, "case_id"))             _case_id = _pet_done.current_case.case_id;
                if (variable_struct_exists(_pet_done.current_case, "hidden_disease_id"))  _disease_id = _pet_done.current_case.hidden_disease_id;
                if (variable_struct_exists(_pet_done.current_case, "reveal_level"))        _reveal_level = _pet_done.current_case.reveal_level;
                if (variable_struct_exists(_pet_done.current_case, "severity_level"))      _severity_level = _pet_done.current_case.severity_level;
                if (variable_struct_exists(_pet_done.current_case, "severity_name_ru"))   _severity_name_ru = _pet_done.current_case.severity_name_ru;
                if (variable_struct_exists(_pet_done.current_case, "case_status"))         _case_status = _pet_done.current_case.case_status;
                if (variable_struct_exists(_pet_done.current_case, "completed_diagnostics")) _completed_diagnostics = _pet_done.current_case.completed_diagnostics;
                if (variable_struct_exists(_pet_done.current_case, "treatment_progress"))  _treatment_progress = _pet_done.current_case.treatment_progress;
                if (variable_struct_exists(_pet_done.current_case, "visible_symptoms"))    _visible_symptoms = _pet_done.current_case.visible_symptoms;
                if (variable_struct_exists(_pet_done.current_case, "planned_treatment"))   _planned_treatment = _pet_done.current_case.planned_treatment;
                if (variable_struct_exists(_pet_done.current_case, "visit_diagnostics_done")) _diagnostics_this_visit = _pet_done.current_case.visit_diagnostics_done;
                if (variable_struct_exists(_pet_done.current_case, "visit_treatments_done"))  _treatments_this_visit = _pet_done.current_case.visit_treatments_done;
                if (variable_struct_exists(_pet_done.current_case, "visit_procedure_log"))    _procedure_log = _pet_done.current_case.visit_procedure_log;
            }
            if (!is_struct(_outcome)) {
                _outcome = {
                    outcome_id : "outcome_generic",
                    outcome_name_ru : "Приём завершён",
                    trust_delta : 0,
                    payout_mult : 0.5,
                    condition_after : 80,
                    needs_followup : false,
                    followup_days : 0,
                    followup_reason : ""
                };
            }

            // 4. Обновляем владельца
            if (instance_exists(_owner_done)) {
                if (!variable_instance_exists(_owner_done, "owner_trust")) {
                    _owner_done.owner_trust = 60;
                }
                _owner_done.owner_trust = clamp(_owner_done.owner_trust + _outcome.trust_delta, 0, 100);
                var _payout = global.base_visit_price;
                _payout += irandom_range(0, global.visit_price_random);
                _payout = floor(_payout * _outcome.payout_mult);
                _payout = max(20, _payout);
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
                if (!variable_instance_exists(_owner_done, "pending_payment_total")) {
                    _owner_done.pending_payment_total = 0;
                }
                _owner_done.pending_payment_total += _payout;
            }

            // 5. Сохраняем визит
            if (instance_exists(_owner_done)) {
                db_register_completed_visit(_owner_done);
            }

            // ─────────────────────────────────────────────
            // 5б. ОПЫТ ВРАЧУ (ЧИСТЫЙ, БЕЗ ОШИБОК)
            // ─────────────────────────────────────────────
            var _xp_base_therapy = 5;
            var _xp_specialty    = 4;

            doctor_add_skill_xp(id, 0, _xp_base_therapy, false);
            staff_spend_energy(8);
            var _log_txt = "+" + string(_xp_base_therapy) + " ТЕРАПИЯ";

            if (_case_confirmed && instance_exists(_pet_done) && is_struct(_pet_done.current_case)) {
                var _hid = undefined;
                if (variable_struct_exists(_pet_done.current_case, "hidden_disease_id"))
                    _hid = _pet_done.current_case.hidden_disease_id;
                if ((!is_string(_hid) || _hid == "") && variable_struct_exists(_pet_done.current_case, "selected_disease_id"))
                    _hid = _pet_done.current_case.selected_disease_id;
                if ((!is_string(_hid) || _hid == "") && variable_struct_exists(_pet_done.current_case, "disease_id"))
                    _hid = _pet_done.current_case.disease_id;

                show_debug_message("[XP v2] USED='" + string(_hid) + "'");

                if (is_string(_hid) && _hid != "") {
                    var _diag_skill = doctor_get_skill_for_disease(_hid);
                    if (_diag_skill < 0) _diag_skill = 0;

                    show_debug_message("[XP v2] -> skill=" + string(_diag_skill) + " amount=" + string(_xp_specialty));

                    doctor_add_skill_xp(id, _diag_skill, _xp_specialty, true);
                    if (_diag_skill == 0) {
                        _log_txt = "+" + string(_xp_base_therapy + _xp_specialty) + " ТЕРАПИЯ";
                    } else {
                        var _skill_names = doctor_get_skill_names();
                        var _sname = (_diag_skill < array_length(_skill_names)) ? _skill_names[_diag_skill] : "ТЕРАПИЯ";
                        _log_txt += "   +" + string(_xp_specialty) + " " + _sname;
                    }
                } else {
                    doctor_add_skill_xp(id, 0, _xp_specialty, true);
                    _log_txt = "+" + string(_xp_base_therapy + _xp_specialty) + " ТЕРАПИЯ";
                }
            }
            add_xp_log(_log_txt);

            // ─────────────────────────────────────────────
            // 6. Формируем процедуры
            // ─────────────────────────────────────────────
            var _moved_to_procedure_queue = false;
            if (instance_exists(_pet_done) && variable_instance_exists(_pet_done, "current_case") && is_struct(_pet_done.current_case)) {
                if (!variable_instance_exists(_pet_done.current_case, "pending_procedure_actions")) {
                    _pet_done.current_case.pending_procedure_actions = [];
                }
                var _next_assignments = case_build_next_procedure_assignments(_pet_done.current_case);
                _pet_done.current_case.pending_procedure_actions = _next_assignments;
                if (array_length(_next_assignments) > 0) {
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
                                is_walking = true;
                                move_towards_point(_spot.x, _spot.y, p_move_speed);
                            }
                        }
                        _moved_to_procedure_queue = true;
                    }
                }
            }

            // 7. Питомец снова следует за владельцем
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

            // 8. Если процедур нет — на оплату
            if (!_moved_to_procedure_queue && instance_exists(_owner_done)) {
                with (_owner_done) {
                    queue_purpose = "payment";
                    payment_pending = true;
                    payment_done = false;
                    assigned_doctor = noone;
                    assigned_table = noone;
                }
                reception_enqueue_priority_payment(_owner_done);
            }

            assigned_owner = noone;
            assigned_table = noone;
            assigned_pet = noone;
            exam_timer = 0;
            exam_timer_max = 0;

            // ── ТРАТА ЭНЕРГИИ за приём (через выносливость) ──
            staff_spend_energy(8);

            doctor_state = "idle";
        }
    break;


}

depth = -y;
