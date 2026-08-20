///Create obj_dog_puppy

event_inherited();

if (is_walking && path_index < 0) {
    var _at_target = false;
    var _dest_state = "";
    var _dest_x = x;
    var _dest_y = y;

    if (state == "going_to_exam_floor"
    && variable_instance_exists(id, "exam_floor_x")) {
        _dest_x = exam_floor_x;
        _dest_y = exam_floor_y;
        _dest_state = "jumping_to_table";
        if (point_distance(x, y, _dest_x, _dest_y) <= 12) _at_target = true;
        else move_towards_point(_dest_x, _dest_y, p_move_speed);
    } else if (state == "going_to_owner"
           && variable_instance_exists(id, "follow_target")
           && instance_exists(follow_target)) {
        // Следование за владельцем идёт в обычном AI
        _at_target = false;
    } else {
        is_walking = false;
        move_towards_point(x, y, 0);
    }

    if (_at_target) {
        path_end();
        is_walking = false;
        move_towards_point(x, y, 0);
        if (_dest_state != "") state = _dest_state;
        exit;
    }
}

// ─────────────────────────────────────────────
// 1. НАСТРОЙКИ ФОТО
// ─────────────────────────────────────────────
portrait_x = 50;
portrait_y = 50;
portrait_zoom = 0.5;
portrait_offset = 150;

// ─────────────────────────────────────────────
// 2. ДАННЫЕ ЩЕНКА
// ─────────────────────────────────────────────
var _names = ["Бадди", "Джек", "Арчи", "Белла", "Дейзи", "Лаки"];

char_name = _names[irandom(array_length(_names) - 1)];
role = "animal";

breed = "Лабрадор (щенок)";
age = string(irandom_range(2, 6)) + " мес.";

problem = choose("Нужна прививка", "Плохой аппетит", "Плановый осмотр", "Болит лапа");

hair_color = c_white;
stat_energy = 100;
character_trait = 0;

skills = array_create(10, 0);
skills_sum = 0;

my_eyes = -1;
my_nose = -1;
my_mouth = -1;
my_hair = -1;

// ─────────────────────────────────────────────
// 3. СПРАЙТ
// ─────────────────────────────────────────────
sprite_index = spr_pappy_FR_walk;

// ─────────────────────────────────────────────
// 4. ЖИЗНЕННЫЙ ЦИКЛ
// ─────────────────────────────────────────────
life_stage = PET_STAGE.PUPPY;
alarm[1] = room_speed * random_range(5, 10);

// ─────────────────────────────────────────────
// 5. МЕДИЦИНСКИЙ СЛУЧАЙ
// ─────────────────────────────────────────────
species_id = "dog";

current_case = case_create_random_for_species(species_id);

if (is_struct(current_case)) {
    animal_apply_case(id, current_case);
}

// ─────────────────────────────────────────────
// 6. ЖИВОЕ СЛЕДОВАНИЕ ЩЕНКА
// ─────────────────────────────────────────────
puppy_pos_x = x;
puppy_pos_y = y;

puppy_vel_x = 0;
puppy_vel_y = 0;

puppy_following = false;

puppy_owner_dir = 270;
puppy_side_sign = choose(-1, 1);
puppy_face = 1;

puppy_wobble = random(360);
puppy_wobble_speed = random_range(3.5, 6.0);
puppy_idle_phase = random(360);

puppy_side_timer = irandom_range(room_speed * 3, room_speed * 6);

puppy_follow_min_speed = 1.0;
puppy_follow_max_speed = 4.8;
puppy_follow_accel = 0.24;
puppy_follow_drag = 0.72;

puppy_follow_start_distance = 18;
puppy_follow_stop_distance = 6;

puppy_follow_teleport_distance = 260;

puppy_follow_behind_distance = 42;
puppy_follow_side_distance = 22;

puppy_follow_anticipation = 4;
puppy_personal_space = 24;

puppy_idle_radius = 4;

// Оставляем, чтобы родитель не мешал
follow_offset_x = 0;
follow_offset_y = 0;