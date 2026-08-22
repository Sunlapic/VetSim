/// Create obj_staff_doctor
/// @description Врач с 11 профессиональными навыками и двухфазным приёмом.

event_inherited();

staff_generate_appearance();
staff_apply_role("doctor");

// У нового врача Стационар получает собственный случайный уровень 1–10.
doctor_ensure_inpatient_skill(id, true);
portrait_bake();

alarm[1] = -1;

doctor_state = "idle";

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

// Состояние второй фазы амбулаторного приёма.
doctor_visit_profile_time_added = false;
doctor_visit_profile_frames = 0;
doctor_visit_profile_index = 0;
doctor_visit_profile_name = "ТЕРАПИЯ";

home_x = x;
home_y = y;

if (!variable_instance_exists(id, "xp_log")) {
    xp_log = [];
}

add_xp_log = function(_text) {
    array_insert(xp_log, 0, { txt : _text });

    while (array_length(xp_log) > 5) {
        array_delete(xp_log, 5, 1);
    }
};

doctor_recalc_all_skills(id);

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

    // Пакет №186: профессия стоит на том же месте, что и навык в
    // doctor_get_skill_names — раньше списки разъезжались и врач с лучшей
    // «ОФТАЛЬМОЛОГИЕЙ» подписывался «ФЕЛЬДШЕР».
    var _titles = [
        "ТЕРАПЕВТ",       // ТЕРАПИЯ
        "ФЕЛЬДШЕР",       // ПРОЦЕДУРЫ
        "ХИРУРГ",         // ХИРУРГИЯ
        "ОФТАЛЬМОЛОГ",    // ОФТАЛЬМОЛОГИЯ
        "ЛОР-ВРАЧ",       // ОТОЛАРИНГОЛОГИЯ
        "ДЕРМАТОЛОГ",     // ДЕРМАТОЛОГИЯ
        "ИНФЕКЦИОНИСТ",   // ИНФЕКЦИИ/ТОКС.
        "АНЕСТЕЗИОЛОГ",   // АНЕСТЕЗИОЛОГИЯ
        "ЛАБОРАНТ",       // ЛАБОРАТОРИЯ
        "СТОМАТОЛОГ"      // СТОМАТОЛОГИЯ
    ];

    if (_role == "admin") {
        specialty_title = "АДМИНИСТРАТОР";
    } else if (_role == "assistant") {
        specialty_title = "";
    } else {
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
