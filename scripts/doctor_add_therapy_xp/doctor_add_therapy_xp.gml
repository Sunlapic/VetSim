/// doctor_skill_system.gml
/// @description Навыки врача. Награды Терапии уменьшены примерно в 3 раза.
/// Пакет №68: добавлен маппинг новых болезней на профильные навыки.

function doctor_get_skill_names() {
    if (!variable_struct_exists(global, "doctor_skill_names")) {
        global.doctor_skill_names = [
            "ТЕРАПИЯ",
            "ПРОЦЕДУРЫ",
            "ХИРУРГИЯ",
            "ОФТАЛЬМОЛОГИЯ",
            "ОТОЛАРИНГОЛОГИЯ",
            "ДЕРМАТОЛОГИЯ",
            "ИНФЕКЦИИ/ТОКС.",
            "АНЕСТЕЗИОЛОГИЯ",
            "ЛАБОРАТОРИЯ",
            "СТОМАТОЛОГИЯ",
            "СТАЦИОНАР"
        ];
    }

    // Комната могла быть перезапущена без очистки global-структур.
    while (array_length(global.doctor_skill_names) < 11) {
        array_push(global.doctor_skill_names, "СТАЦИОНАР");
    }

    return global.doctor_skill_names;
}

function doctor_get_skill_for_disease(_disease_id) {
    switch (_disease_id) {
        // Хирургия.
        case "disease_fracture":
        case "disease_limb_fracture":
        case "disease_bone_fracture":
        case "disease_wound":
        case "disease_open_wound":
        case "disease_bleeding":
        case "disease_hemorrhage":
        case "disease_cut":
        case "disease_abscess":
        case "disease_tumor":
        case "fracture":
        case "limb_fracture":
        case "wound":
        case "bleeding":
        case "hemorrhage":
        case "abscess":
        case "tumor":
            return 2;

        // Офтальмология.
        case "disease_conjunctivitis":
        case "disease_eye_redness":
        case "disease_eye_swelling":
        case "disease_eye_injury":
        case "disease_cataract":
        case "disease_stye":
        case "disease_keratitis":
        case "disease_blepharitis":
        case "disease_glaucoma":
        case "disease_dry_eye":
        case "conjunctivitis":
        case "eye_redness":
        case "eye_swelling":
        case "eye_injury":
        case "cataract":
        case "stye":
            return 3;

        // Отоларингология.
        case "disease_otitis":
        case "disease_rhinitis":
        case "disease_ear_shake":
        case "disease_nasal_discharge":
        case "disease_ear_mites":
        case "disease_sneezing":
        case "disease_foreign_body_ear":
        case "disease_foreign_body_nose":
        case "disease_sinusitis":
        case "disease_otitis_media":
        case "otitis":
        case "rhinitis":
        case "ear_shake":
        case "nasal_discharge":
        case "ear_mites":
        case "sneezing":
        case "foreign_body_ear":
        case "foreign_body_nose":
            return 4;

        // Дерматология.
        case "disease_fleas":
        case "disease_ticks":
        case "disease_lichen":
        case "disease_dermatitis":
        case "disease_allergy_skin":
        case "disease_hot_spot":
        case "disease_itching":
        case "disease_hair_loss":
        case "disease_rash":
        case "disease_demodicosis":
        case "disease_ringworm":
        case "fleas":
        case "ticks":
        case "lichen":
        case "dermatitis":
        case "allergy_skin":
        case "hot_spot":
        case "itching":
        case "hair_loss":
        case "rash":
            return 5;

        // Инфекции и токсикология.
        case "disease_piroplasmosis":
        case "disease_enteritis":
        case "disease_entheritis":
        case "disease_poisoning":
        case "disease_distemper":
        case "disease_parvovirus":
        case "disease_viral_infection":
        case "disease_helminths":
        case "disease_sepsis":
        case "disease_fever_unknown":
        case "disease_infection":
        case "disease_leptospirosis":
        case "disease_hepatitis_infectious":
        case "disease_helminthiasis":
        case "disease_ehrlichiosis":
        case "piroplasmosis":
        case "enteritis":
        case "entheritis":
        case "poisoning":
        case "distemper":
        case "parvovirus":
        case "viral_infection":
        case "helminths":
        case "sepsis":
        case "fever_unknown":
        case "infection":
            return 6;

        // Стоматология.
        case "disease_tartar":
        case "disease_gingivitis":
        case "disease_toothache":
        case "disease_stomatitis":
        case "disease_broken_tooth":
        case "disease_periodontitis":
        case "tartar":
        case "gingivitis":
        case "toothache":
        case "stomatitis":
        case "broken_tooth":
            return 9;

        // Процедуры.
        case "disease_foreign_body":
        case "disease_needs_bandage":
        case "disease_needs_injection":
        case "disease_needs_iv":
        case "disease_constipation":
        case "disease_anal_glands":
        case "foreign_body":
        case "needs_bandage":
        case "needs_injection":
        case "needs_iv":
            return 1;
    }

    return 0;
}

function doctor_xp_needed(_level) {
    _level = clamp(round(_level), 1, 9);

    var _requirements = [35, 55, 80, 115, 160, 210, 275, 345, 430];
    return _requirements[_level - 1];
}

// Только Терапия получает треть обычной награды.
function doctor_scale_xp_reward(_skill_index, _amount) {
    _amount = max(0, floor(_amount));

    if (_skill_index == 0 && _amount > 0) {
        return max(1, round(_amount / 3));
    }

    return _amount;
}

function doctor_recalc_skill_progress(_actor, _skill_index) {
    if (!instance_exists(_actor)) return false;
    if (!variable_instance_exists(_actor, "skills")) return false;
    if (_skill_index < 0 || _skill_index >= array_length(_actor.skills)) return false;

    if (!variable_instance_exists(_actor, "skill_xp")) {
        _actor.skill_xp = array_create(array_length(_actor.skills), 0);
    }

    while (array_length(_actor.skill_xp) < array_length(_actor.skills)) {
        array_push(_actor.skill_xp, 0);
    }

    if (_skill_index == 0 && variable_instance_exists(_actor, "therapy_xp")) {
        _actor.skill_xp[0] = _actor.therapy_xp;
    }

    var _level = clamp(round(_actor.skills[_skill_index]), 1, 10);
    var _xp = _actor.skill_xp[_skill_index];

    while (_level < 10) {
        var _needed = doctor_xp_needed(_level);

        if (_xp < _needed) break;

        _xp -= _needed;
        _level += 1;
    }

    if (_level >= 10) {
        _level = 10;
        _xp = 0;
    }

    _actor.skills[_skill_index] = _level;
    _actor.skill_xp[_skill_index] = _xp;

    if (_skill_index == 0) {
        _actor.therapy_level = _level;
        _actor.therapy_xp = _xp;
        _actor.therapy_xp_into_level = _xp;
        _actor.therapy_xp_next_level = (_level >= 10)
            ? 1
            : doctor_xp_needed(_level);
    }

    return true;
}

function doctor_add_skill_xp(
    _actor,
    _skill_index,
    _amount,
    _show_notice = true
) {
    if (!instance_exists(_actor)) return 0;
    if (!variable_instance_exists(_actor, "skills")) return 0;
    if (_skill_index < 0 || _skill_index >= array_length(_actor.skills)) return 0;

    doctor_recalc_skill_progress(_actor, _skill_index);

    if (_actor.skills[_skill_index] >= 10) return 0;

    var _actual_reward = doctor_scale_xp_reward(_skill_index, _amount);
    var _old_level = _actor.skills[_skill_index];

    _actor.skill_xp[_skill_index] += _actual_reward;

    if (_skill_index == 0) {
        _actor.therapy_xp = _actor.skill_xp[0];
    }

    doctor_recalc_skill_progress(_actor, _skill_index);

    var _new_level = _actor.skills[_skill_index];

    if (_show_notice && _new_level > _old_level && instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);
        var _names = doctor_get_skill_names();
        var _skill_name = (_skill_index < array_length(_names))
            ? _names[_skill_index]
            : "НАВЫК";
        var _actor_name = variable_instance_exists(_actor, "char_name")
            ? string(_actor.char_name)
            : "Врач";

        if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
            with (_hud) {
                show_notice(
                    _skill_name,
                    _actor_name + " повысил навык до Lv." + string(_new_level),
                    room_speed * 3
                );
            }
        }
    }

    return _actual_reward;
}

function doctor_add_therapy_xp(_actor, _amount, _show_notice = true) {
    return doctor_add_skill_xp(_actor, 0, _amount, _show_notice);
}

function doctor_recalc_all_skills(_actor) {
    if (!instance_exists(_actor)) return false;
    if (!variable_instance_exists(_actor, "skills")) return false;

    // Миграция старых врачей с 10 навыков на 11.
    doctor_ensure_inpatient_skill(_actor, false);

    if (!variable_instance_exists(_actor, "skill_xp")) {
        _actor.skill_xp = array_create(array_length(_actor.skills), 0);
    }

    while (array_length(_actor.skill_xp) < array_length(_actor.skills)) {
        array_push(_actor.skill_xp, 0);
    }

    for (var _index = 0; _index < array_length(_actor.skills); _index++) {
        doctor_recalc_skill_progress(_actor, _index);
    }

    _actor.__xp_migration_done = true;
    return true;
}
