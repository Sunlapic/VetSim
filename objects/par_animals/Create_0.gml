/// Create par_animals
/// @description Общие данные всех видов животных, включая универсальные поля стационара.

event_inherited();

is_hovered = false;
is_walking = false;

my_path = path_add();

pFacing = 1;
p_move_speed = 2;


// ═══════════════════════════════════════════════════════════════
// 1. СТАНДАРТНЫЕ ДАННЫЕ
// ═══════════════════════════════════════════════════════════════

char_name = "Питомец";
role = "animal";

breed = "Неизвестно";
problem = "Здоров";

stat_energy = 100;
portrait_offset = 120;

skills = array_create(10, 0);
skills[0] = 8;
skills[1] = 5;
skills[2] = 7;

skills_sum = 0;
character_trait = 0;
hair_color = c_white;


// ═══════════════════════════════════════════════════════════════
// 2. НАСТРОЙКИ ФОТО
// ═══════════════════════════════════════════════════════════════

portrait_x = 100;
portrait_y = 50;
portrait_zoom = 0.4;


// ═══════════════════════════════════════════════════════════════
// 3. СИСТЕМА ВЛАДЕЛЬЦА
// ═══════════════════════════════════════════════════════════════

owner_id = -1;
my_owner = -1;
follow_target = -1;

follow_offset_x = 30;
follow_offset_y = 20;


// ═══════════════════════════════════════════════════════════════
// 4. ЖИЗНЕННЫЙ ЦИКЛ
// ═══════════════════════════════════════════════════════════════

life_stage = PET_STAGE.PUPPY;
pet_unique_id = -1;
pet_age_days = 0;


// ═══════════════════════════════════════════════════════════════
// 5. ЗДОРОВЬЕ И БОЛЕЗНИ
// ═══════════════════════════════════════════════════════════════

hidden_disease_id = "";
visible_symptoms = [];
reveal_level = 0;
diagnosis_confirmed = false;
condition = 100;

species_id = "unknown";
current_case = undefined;
current_case_id = "";

is_dead = false;
death_reason = "";


// ═══════════════════════════════════════════════════════════════
// 6. ВАКЦИНАЦИЯ
// ═══════════════════════════════════════════════════════════════

needs_vaccination = false;
last_vaccination_day = 0;


// ═══════════════════════════════════════════════════════════════
// 7. СОСТОЯНИЯ ДЛЯ ПРИЁМА
// ═══════════════════════════════════════════════════════════════

state = "follow_owner";

assigned_table = noone;
assigned_doctor = noone;

exam_floor_x = x;
exam_floor_y = y;

exam_table_x = x;
exam_table_y = y;

leave_target_x = x;
leave_target_y = y;

table_jump_lerp = 0.18;


// ═══════════════════════════════════════════════════════════════
// 8. УНИВЕРСАЛЬНЫЕ ДАННЫЕ СТАЦИОНАРА
// Эти поля наследуют щенки и все будущие виды животных.
// Отдельные объекты животных изменять для стационара не требуется.
// ═══════════════════════════════════════════════════════════════

inpatient_active = false;
inpatient_controller = noone;
inpatient_owner_record_id = "";
inpatient_pet_record_id = "";


// ═══════════════════════════════════════════════════════════════
// 9. СМЕРТЬ ПИТОМЦА
// ═══════════════════════════════════════════════════════════════

pet_die = function(_reason) {
    if (is_dead) exit;

    is_dead = true;
    death_reason = _reason;
    condition = 0;

    path_end();
    is_walking = false;
    state = "dead";

    if (instance_exists(my_owner)) {
        with (my_owner) {
            path_end();
            is_walking = false;

            leave_target_x = global.clinic_exit_x;
            leave_target_y = global.clinic_exit_y;
            state = "leaving_clinic";

            if (mp_grid_path(
                global.ai_grid,
                my_path,
                x,
                y,
                leave_target_x,
                leave_target_y,
                true
            )) {
                path_set_kind(my_path, 1);
                path_start(my_path, p_move_speed, path_action_stop, true);
                is_walking = true;
            } else {
                instance_destroy();
            }
        }
    }

    instance_destroy();
};


// ═══════════════════════════════════════════════════════════════
// 10. МЕДЛЕННАЯ ПОТЕРЯ СОСТОЯНИЯ
// ═══════════════════════════════════════════════════════════════

condition_decay_counter = 0;
condition_decay_interval = room_speed * 12;

depth = -y;
