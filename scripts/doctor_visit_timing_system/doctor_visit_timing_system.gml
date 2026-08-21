/// doctor_visit_timing_system.gml
/// @description Двухфазный приём и новый одиннадцатый навык «Стационар».


// ═══════════════════════════════════════════════════════════════
// 1. НОВЫЙ НАВЫК «СТАЦИОНАР»
// ═══════════════════════════════════════════════════════════════

function doctor_inpatient_skill_index() {
    return 10;
}

function doctor_ensure_inpatient_skill(
    _actor,
    _randomize_if_missing = false
) {
    if (!instance_exists(_actor)) return false;

    if (!variable_instance_exists(_actor, "skills")) {
        _actor.skills = array_create(10, 1);
    }

    var _required_length = doctor_inpatient_skill_index() + 1;

    while (array_length(_actor.skills) < _required_length) {
        var _start_level = (
            _randomize_if_missing
            && _actor.object_index != obj_player
        ) ? irandom_range(1, 10) : 1;

        array_push(_actor.skills, _start_level);
    }

    if (!variable_instance_exists(_actor, "skill_xp")) {
        _actor.skill_xp = array_create(array_length(_actor.skills), 0);
    }

    while (array_length(_actor.skill_xp) < _required_length) {
        array_push(_actor.skill_xp, 0);
    }

    // skills_sum участвует в старых формулах и интерфейсах.
    _actor.skills_sum = 0;

    for (var _index = 0; _index < array_length(_actor.skills); _index++) {
        _actor.skills[_index] = clamp(round(_actor.skills[_index]), 1, 10);
        _actor.skills_sum += _actor.skills[_index];
    }

    return true;
}

function doctor_get_actor_skill_level(_actor, _skill_index) {
    if (!instance_exists(_actor)) return 1;

    doctor_ensure_inpatient_skill(_actor, false);

    if (
        _skill_index < 0
        || _skill_index >= array_length(_actor.skills)
    ) {
        return 1;
    }

    return clamp(round(_actor.skills[_skill_index]), 1, 10);
}

function doctor_get_inpatient_level(_actor) {
    return doctor_get_actor_skill_level(
        _actor,
        doctor_inpatient_skill_index()
    );
}


// ═══════════════════════════════════════════════════════════════
// 2. ПРОФИЛЬ БОЛЕЗНИ
// ═══════════════════════════════════════════════════════════════

function doctor_visit_get_disease_id(_pet) {
    if (!instance_exists(_pet)) return "";
    if (!variable_instance_exists(_pet, "current_case")) return "";
    if (!is_struct(_pet.current_case)) return "";

    var _case = _pet.current_case;

    if (variable_struct_exists(_case, "hidden_disease_id")) {
        return string(_case.hidden_disease_id);
    }
    if (variable_struct_exists(_case, "selected_disease_id")) {
        return string(_case.selected_disease_id);
    }
    if (variable_struct_exists(_case, "disease_id")) {
        return string(_case.disease_id);
    }

    return "";
}

function doctor_visit_get_profile_index(_pet) {
    var _disease_id = doctor_visit_get_disease_id(_pet);

    if (_disease_id == "") return 0;

    return clamp(
        doctor_get_skill_for_disease(_disease_id),
        0,
        9
    );
}

function doctor_visit_get_skill_name(_skill_index) {
    var _names = doctor_get_skill_names();

    return (
        _skill_index >= 0
        && _skill_index < array_length(_names)
    ) ? _names[_skill_index] : "ТЕРАПИЯ";
}


// ═══════════════════════════════════════════════════════════════
// 3. ПЛАН ДВУХФАЗНОГО ПРИЁМА
// ═══════════════════════════════════════════════════════════════

function doctor_visit_build_timing(_doctor, _pet) {
    doctor_ensure_inpatient_skill(_doctor, false);

    var _therapy_index = 0;
    var _profile_index = doctor_visit_get_profile_index(_pet);
    var _therapy_level = doctor_get_actor_skill_level(
        _doctor,
        _therapy_index
    );
    var _profile_level = doctor_get_actor_skill_level(
        _doctor,
        _profile_index
    );
    var _therapy_frames = doctor_get_exam_duration_frames(
        _therapy_level
    );
    var _profile_frames = doctor_get_exam_duration_frames(
        _profile_level
    );

    return {
        therapy_index : _therapy_index,
        therapy_level : _therapy_level,
        therapy_frames : _therapy_frames,
        profile_index : _profile_index,
        profile_level : _profile_level,
        profile_frames : _profile_frames,
        profile_name : doctor_visit_get_skill_name(_profile_index),
        total_frames : _therapy_frames + _profile_frames
    };
}


// ═══════════════════════════════════════════════════════════════
// 4. NPC-ВРАЧ: ДОБАВЛЕНИЕ ВТОРОЙ ФАЗЫ К СУЩЕСТВУЮЩЕМУ ТАЙМЕРУ
// ═══════════════════════════════════════════════════════════════

function doctor_visit_update_npc_timing(_doctor) {
    if (!instance_exists(_doctor)) return false;

    if (_doctor.doctor_state != "examining") {
        _doctor.doctor_visit_profile_time_added = false;
        _doctor.doctor_visit_profile_frames = 0;
        _doctor.doctor_visit_profile_index = 0;
        _doctor.doctor_visit_profile_name = "ТЕРАПИЯ";
        return false;
    }

    if (!variable_instance_exists(
        _doctor,
        "doctor_visit_profile_time_added"
    )) {
        _doctor.doctor_visit_profile_time_added = false;
    }

    if (!_doctor.doctor_visit_profile_time_added) {
        var _timing = doctor_visit_build_timing(
            _doctor,
            _doctor.assigned_pet
        );

        // Основной Step уже создал первую фазу по Терапии.
        // Здесь один раз добавляется только профильная фаза.
        _doctor.exam_timer += _timing.profile_frames;
        _doctor.exam_timer_max += _timing.profile_frames;
        _doctor.doctor_visit_profile_frames = _timing.profile_frames;
        _doctor.doctor_visit_profile_index = _timing.profile_index;
        _doctor.doctor_visit_profile_name = _timing.profile_name;
        _doctor.doctor_visit_profile_time_added = true;
    }

    if (_doctor.exam_timer > _doctor.doctor_visit_profile_frames) {
        _doctor.action_progress_label = "ПРИЁМ: ТЕРАПИЯ";
    }
    else {
        _doctor.action_progress_label = "ПРИЁМ: "
            + _doctor.doctor_visit_profile_name;
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 5. ГЛАВНЫЙ ИГРОК: ТАЙМЕР ДО РАЗБЛОКИРОВКИ КНОПОК
// ═══════════════════════════════════════════════════════════════

function doctor_visit_player_reset_timing(_player) {
    if (!instance_exists(_player)) return;

    _player.manual_visit_timing_active = false;
    _player.manual_visit_timing_ready = false;
    _player.manual_visit_timing_target = noone;
    _player.manual_visit_timing_mode = "";
    _player.manual_visit_timer = 0;
    _player.manual_visit_timer_max = 0;
    _player.manual_visit_profile_frames = 0;
    _player.manual_visit_profile_name = "ТЕРАПИЯ";
    _player.manual_visit_ready_notice_shown = false;
}

function doctor_visit_update_player_timing(_player) {
    if (!instance_exists(_player)) return false;

    doctor_ensure_inpatient_skill(_player, false);

    if (!variable_instance_exists(_player, "manual_visit_timing_active")) {
        doctor_visit_player_reset_timing(_player);
    }

    var _pet = variable_instance_exists(_player, "assigned_pet")
        ? _player.assigned_pet
        : noone;
    var _inpatient_assign = (
        _player.doctor_state == "manual_exam"
        && variable_instance_exists(_player, "inpatient_manual_task")
        && _player.inpatient_manual_task == "assign"
        && instance_exists(_pet)
        && variable_instance_exists(_pet, "inpatient_active")
        && _pet.inpatient_active
    );
    var _outpatient_exam = (
        _player.doctor_state == "manual_exam"
        && instance_exists(_pet)
        && !_inpatient_assign
    );

    if (!_outpatient_exam && !_inpatient_assign) {
        doctor_visit_player_reset_timing(_player);
        return false;
    }

    var _mode = _inpatient_assign ? "inpatient" : "outpatient";
    var _must_start = (
        !_player.manual_visit_timing_active
        || _player.manual_visit_timing_target != _pet
        || _player.manual_visit_timing_mode != _mode
    );

    if (_must_start) {
        _player.manual_visit_timing_active = true;
        _player.manual_visit_timing_target = _pet;
        _player.manual_visit_timing_mode = _mode;
        _player.manual_visit_ready_notice_shown = false;

        if (_outpatient_exam) {
            // ═══════════════════════════════════════════════════
            // ПАКЕТ №65.
            // Амбулаторный приём главного игрока больше НЕ ждёт
            // двухфазную шкалу «терапия + профиль»: обследования и
            // назначения доступны сразу, как до пакета №64.
            // Двухфазное время остаётся только у NPC-врачей.
            // ═══════════════════════════════════════════════════
            _player.manual_visit_timing_ready = true;
            _player.manual_visit_timer = 0;
            _player.manual_visit_timer_max = 0;
            _player.manual_visit_profile_frames = 0;
            _player.manual_visit_profile_name = "ТЕРАПИЯ";
            _player.manual_visit_ready_notice_shown = true;

            // Шкала не рисуется: гасим прогресс действия.
            _player.action_progress_active = false;
            _player.action_progress_timer = 0;
            _player.action_progress_timer_max = 0;
        }
        else {
            // Ручное назначение в стационаре сохраняет шкалу
            // «СТАЦИОНАР», зависящую от нового навыка.
            var _inpatient_level = doctor_get_inpatient_level(_player);
            var _inpatient_frames = doctor_get_exam_duration_frames(
                _inpatient_level
            );

            _player.manual_visit_timing_ready = false;
            _player.manual_visit_timer = _inpatient_frames;
            _player.manual_visit_timer_max = _inpatient_frames;
            _player.manual_visit_profile_frames = _inpatient_frames;
            _player.manual_visit_profile_name = "СТАЦИОНАР";
        }
    }

    if (_player.manual_visit_timing_ready) return true;

    // Ниже выполняется только стационарный таймер игрока:
    // амбулаторный приём выше всегда мгновенно готов.
    _player.manual_visit_timer = max(
        0,
        _player.manual_visit_timer - 1
    );
    _player.action_progress_active = true;
    _player.action_progress_timer = _player.manual_visit_timer;
    _player.action_progress_timer_max = max(
        1,
        _player.manual_visit_timer_max
    );
    _player.action_progress_color = make_color_rgb(80, 140, 220);
    _player.action_progress_label = "СТАЦИОНАР";

    if (_player.manual_visit_timer <= 0) {
        _player.manual_visit_timing_ready = true;
        _player.action_progress_active = false;

        if (
            !_player.manual_visit_ready_notice_shown
            && instance_exists(obj_UI_HUD)
        ) {
            _player.manual_visit_ready_notice_shown = true;
            var _hud = instance_find(obj_UI_HUD, 0);
            var _fps = max(1, game_get_speed(gamespeed_fps));

            _hud.show_notice(
                "СТАЦИОНАР",
                "Можно назначать лечение",
                _fps * 2
            );
        }
    }

    return _player.manual_visit_timing_ready;
}

function doctor_visit_player_ready_for_actions(_player, _pet) {
    if (!instance_exists(_player)) return false;
    if (!instance_exists(_pet)) return false;

    return variable_instance_exists(
        _player,
        "manual_visit_timing_ready"
    )
        && _player.manual_visit_timing_ready
        && _player.manual_visit_timing_target == _pet;
}


// ═══════════════════════════════════════════════════════════════
// 6. XP РУЧНОГО АМБУЛАТОРНОГО ПРИЁМА
// ═══════════════════════════════════════════════════════════════

function doctor_visit_award_manual_outpatient_xp(_doctor, _pet) {
    if (!instance_exists(_doctor)) return false;
    if (!instance_exists(_pet)) return false;
    if (!variable_instance_exists(_pet, "current_case")) return false;
    if (!is_struct(_pet.current_case)) return false;

    var _case = _pet.current_case;

    if (
        variable_struct_exists(_case, "visit_doctor_skill_xp_awarded")
        && _case.visit_doctor_skill_xp_awarded
    ) {
        return false;
    }

    var _profile_index = doctor_visit_get_profile_index(_pet);
    var _therapy_added = doctor_add_skill_xp(
        _doctor,
        0,
        5,
        false
    );
    var _profile_added = doctor_add_skill_xp(
        _doctor,
        _profile_index,
        4,
        true
    );
    var _log_text = "+" + string(_therapy_added) + " ТЕРАПИЯ";

    if (_profile_index == 0) {
        _log_text = "+"
            + string(_therapy_added + _profile_added)
            + " ТЕРАПИЯ";
    }
    else {
        _log_text += "   +"
            + string(_profile_added)
            + " "
            + doctor_visit_get_skill_name(_profile_index);
    }

    if (variable_instance_exists(_doctor, "add_xp_log")) {
        _doctor.add_xp_log(_log_text);
    }

    _case.visit_doctor_skill_xp_awarded = true;
    _pet.current_case = _case;
    return true;
}


// ═══════════════════════════════════════════════════════════════
// 7. ВРАЧ, НАЗНАЧИВШИЙ ЛЕЧЕНИЕ В СТАЦИОНАРЕ
// ═══════════════════════════════════════════════════════════════

function doctor_visit_mark_inpatient_prescriber(_pet, _doctor) {
    if (!instance_exists(_pet)) return false;
    if (!instance_exists(_doctor)) return false;
    if (!variable_instance_exists(_pet, "current_case")) return false;
    if (!is_struct(_pet.current_case)) return false;

    var _case = _pet.current_case;
    _case.inpatient_prescribing_doctor = _doctor;
    _case.inpatient_skill_xp_awarded = false;
    _pet.current_case = _case;
    return true;
}

function doctor_visit_award_inpatient_cure(_pet) {
    if (!instance_exists(_pet)) return false;
    if (!variable_instance_exists(_pet, "current_case")) return false;
    if (!is_struct(_pet.current_case)) return false;

    var _case = _pet.current_case;

    if (!variable_struct_exists(_case, "condition")) return false;
    if (_case.condition < 100) return false;

    if (
        variable_struct_exists(_case, "inpatient_skill_xp_awarded")
        && _case.inpatient_skill_xp_awarded
    ) {
        return false;
    }

    var _doctor = variable_struct_exists(
        _case,
        "inpatient_prescribing_doctor"
    ) ? _case.inpatient_prescribing_doctor : noone;

    // Флаг ставится даже после увольнения назначившего врача:
    // награда не должна перейти другому сотруднику.
    _case.inpatient_skill_xp_awarded = true;
    _pet.current_case = _case;

    // Пакет №71: +1 балл клиники за полное выздоровление в стационаре.
    // Выдаётся один раз (вместе с XP-наградой врача) и не зависит от того,
    // уволен ли назначивший врач.
    clinic_points_add(1);
    _pet.clinic_points_cure_awarded = true;

    if (!instance_exists(_doctor)) return false;

    doctor_ensure_inpatient_skill(_doctor, false);
    var _actual_xp = doctor_add_skill_xp(
        _doctor,
        doctor_inpatient_skill_index(),
        80,
        true
    );

    if (variable_instance_exists(_doctor, "add_xp_log")) {
        _doctor.add_xp_log(
            "+" + string(_actual_xp) + " СТАЦИОНАР"
        );
    }

    return true;
}
