/// Create obj_staff_candidate
/// @description Создание кандидата и методы решения.

event_inherited();

is_candidate = true;

// Профессия выбирается только из включённых во вкладке
// «ПЕРСОНАЛ → ПОИСК СОТРУДНИКОВ».
var _picked_role = staff_hiring_search_pick_role();

staff_generate_appearance();
staff_apply_role(_picked_role);

// Врач-кандидат сразу получает новый 11-й навык Стационар.
if (_picked_role == "doctor") {
    doctor_ensure_inpatient_skill(id, true);
}

portrait_x = 150;
portrait_y = 50;
portrait_zoom = 1;

alarm[1] = -1;

// Ожидаемая дневная зарплата рассчитывается по тем же правилам,
// по которым в полночь оплачивается уже нанятый персонал.
salary_expected = finance_calculate_staff_salary(id);

candidate_state = "coming_in";
candidate_target_ready = false;

entry_x = x;
entry_y = y;
exit_x = x;
exit_y = y;

candidate_wait_x = x;
candidate_wait_y = y;

portrait_bake();
alarm[0] = 5;


// ═══════════════════════════════════════════════════════════════
// 1. ОТКАЗ
// ═══════════════════════════════════════════════════════════════

resolve_reject = function() {
    candidate_state = "leaving";

    if (global.current_candidate == id) global.current_candidate = noone;
    if (global.selected_candidate == id) global.selected_candidate = noone;

    if (instance_exists(obj_Render)) {
        with (instance_find(obj_Render, 0)) {
            schedule_next_candidate(true);
        }
    }

    path_end();

    if (mp_grid_path(
        global.ai_grid,
        my_path,
        x,
        y,
        exit_x,
        exit_y,
        true
    )) {
        path_set_kind(my_path, 1);
        path_start(my_path, p_move_speed, path_action_stop, true);
        is_walking = true;
    } else {
        move_towards_point(exit_x, exit_y, p_move_speed);
        is_walking = true;
    }
};


// ═══════════════════════════════════════════════════════════════
// 2. НАЙМ
// ═══════════════════════════════════════════════════════════════

resolve_hire = function() {
    // Пакет №71: проверка лимита слотов найма.
    // Слоты считаются по всем сотрудникам (врачи + админы + ассистенты),
    // главный игрок не учитывается. Лимит прокачивается в РАЗВИТИИ.
    if (!clinic_hire_slot_available()) {
        if (instance_exists(obj_UI_HUD)) {
            var _hire_hud = instance_find(obj_UI_HUD, 0);

            if (
                instance_exists(_hire_hud)
                && variable_instance_exists(_hire_hud, "show_notice")
            ) {
                with (_hire_hud) {
                    show_notice(
                        "НЕТ СЛОТОВ",
                        "Прокачайте Слот найма в КЛИНИКА - РАЗВИТИЕ.",
                        max(1, game_get_speed(gamespeed_fps)) * 3
                    );
                }
            }
        }

        return false;
    }

    var _new_object = obj_staff_assistant;

    switch (role) {
        case "doctor": _new_object = obj_staff_doctor; break;
        case "assistant": _new_object = obj_staff_assistant; break;
        case "admin": _new_object = obj_staff_admin; break;
    }

    var _new_staff = instance_create_layer(
        x,
        y,
        "Instances",
        _new_object
    );

    if (!instance_exists(_new_staff)) return false;

    with (_new_staff) {
        is_candidate = false;

        is_female = other.is_female;
        char_name = other.char_name;
        age = other.age;
        role = other.role;
        specialty_title = other.specialty_title;
        stat_energy = min(other.stat_energy, energy_max);
        character_trait = other.character_trait;
        salary = other.salary_expected;

        hair_color = other.hair_color;
        my_hair = other.my_hair;
        my_hair_back = other.my_hair_back;
        my_eyes = other.my_eyes;
        my_nose = other.my_nose;
        my_mouth = other.my_mouth;

        portrait_x = other.portrait_x;
        portrait_y = other.portrait_y;
        portrait_zoom = other.portrait_zoom;
        portrait_offset = other.portrait_offset;

        // Нанятый сотрудник сохраняет рост и пропорции кандидата.
        _height_scale = other._height_scale;
        _width_scale = other._height_scale;
        _draw_offset_y = other._draw_offset_y;

        skills = array_create(array_length(other.skills), 0);
        skills_sum = 0;

        for (var _skill_index = 0; _skill_index < array_length(other.skills); _skill_index++) {
            skills[_skill_index] = other.skills[_skill_index];
            skills_sum += skills[_skill_index];
        }

        // Общие навыки кандидата переходят нанятому сотруднику.
        walk_skill_level = other.walk_skill_level;
        walk_skill_xp = 0;
        walk_skill_timer = 0;
        staff_recalc_walk_speed();

        stamina_level = other.stamina_level;
        stamina_xp = 0;
        stamina_xp_needed = (stamina_level >= 10)
            ? 1
            : doctor_xp_needed(stamina_level);
        energy_max = 20 + stamina_level * 10;
        stat_energy = energy_max;
        energy = stat_energy;

        if (role == "doctor") {
            skill_xp = array_create(array_length(skills), 0);
            doctor_recalc_all_skills(id);
        }
        else if (role == "assistant") {
            assistant_skill_levels = [
                clamp(skills[1], 1, 10),
                clamp(skills[4], 1, 10),
                clamp(skills[7], 1, 10)
            ];
            assistant_skill_xp = [0, 0, 0];
            assistant_recalc_restock_stats(id);
        }
        else if (role == "admin") {
            skill_level = [
                clamp(skills[0], 1, 10),
                clamp(skills[1], 1, 10)
            ];
            skill_xp = [0, 0];
            skill_xp_needed = [30, 30];
            admin_recalc_skills(id);
        }

        sprite_index = spr_human_FR_walk;
        image_index = 0;
        image_speed = 0;
        pFacing = 1;

        portrait_bake();

        if (role == "admin" && instance_exists(obj_reception_desk)) {
            var _desk = instance_find(obj_reception_desk, 0);

            reception_desk = _desk;
            home_x = _desk.admin_spot_x;
            home_y = _desk.admin_spot_y;
            reception_state = "returning";

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
            }
        }
    }

    array_push(global.city_citizens, _new_staff);

    if (global.current_candidate == id) global.current_candidate = noone;
    if (global.selected_candidate == id) global.selected_candidate = noone;

    if (instance_exists(obj_Render)) {
        with (instance_find(obj_Render, 0)) {
            schedule_next_candidate(true);
        }
    }

    instance_destroy();
    return true;
};
