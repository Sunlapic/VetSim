/// Create obj_owner
/// @description Создание владельца, питомца и данных текущего визита.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 1. БАЗОВЫЕ ПАРАМЕТРЫ
// ═══════════════════════════════════════════════════════════════

pFacing = 1;
is_walking = false;
my_path = path_add();
p_move_speed = 2.5;

role = "owner";
depth = -y;


// ═══════════════════════════════════════════════════════════════
// 2. ПОРТРЕТ И ЛИЧНЫЕ ДАННЫЕ
// ═══════════════════════════════════════════════════════════════

portrait_x = 150;
portrait_y = 50;
portrait_zoom = 1.0;
portrait_offset = 35;
my_baked_portrait = -1;

is_female = choose(false, true);
char_name = get_random_name(is_female);
age = irandom_range(20, 70);
stat_energy = 100;

// Индивидуальная скорость зависит от возраста и не прокачивается.
owner_generate_walk_speed(id);

// Особенности владельцев будут добавляться позднее.
owner_feature_id = "none";
owner_feature_name_ru = "Нет особенности";


// ═══════════════════════════════════════════════════════════════
// 3. ХАРАКТЕРИСТИКИ ВЛАДЕЛЬЦА
// ═══════════════════════════════════════════════════════════════

patience_level = irandom_range(1, 10);
stat_patience = patience_level * 10;

// После 10 секунд ожидания начисляется 1/5 прогресса, но только раз за визит.
patience_success_progress = 0;
patience_wait_xp_timer = 0;
patience_xp_awarded_this_visit = false;

// Лояльность: 5/10 на старте, каждые 5 успешных оплат дают +1 уровень.
loyalty_level = 5;
loyalty_success_progress = 0;

// Старое доверие остаётся отдельной медицинской характеристикой.
if (!variable_instance_exists(id, "owner_trust")) {
    owner_trust = 60;
}


// ═══════════════════════════════════════════════════════════════
// 4. ВНЕШНОСТЬ
// ═══════════════════════════════════════════════════════════════

var _male_hair_front = [
    spr_fr_walk_hair_01,
    spr_fr_walk_hair_02,
    spr_fr_walk_hair_03,
    spr_fr_walk_hair_04,
    spr_fr_walk_hair_05
];

var _male_hair_back = [
    spr_b_walk_hair_01,
    spr_b_walk_hair_02,
    spr_b_walk_hair_03,
    spr_b_walk_hair_04,
    spr_b_walk_hair_05
];

var _female_hair_front = [
    spr_fr_walk_hair_06,
    spr_fr_walk_hair_07,
    spr_fr_walk_hair_08,
    spr_fr_walk_hair_09,
    spr_fr_walk_hair_10,
    spr_fr_walk_hair_11
];

var _female_hair_back = [
    spr_b_walk_hair_06,
    spr_b_walk_hair_07,
    spr_b_walk_hair_08,
    spr_b_walk_hair_09,
    spr_b_walk_hair_10,
    spr_b_walk_hair_11
];

if (is_female) {
    var _hair_index_f = irandom(array_length(_female_hair_front) - 1);
    my_hair = _female_hair_front[_hair_index_f];
    my_hair_back = _female_hair_back[_hair_index_f];
} else {
    var _hair_index_m = irandom(array_length(_male_hair_front) - 1);
    my_hair = _male_hair_front[_hair_index_m];
    my_hair_back = _male_hair_back[_hair_index_m];
}

my_eyes = spr_fr_walk_eyes_01;
my_nose = spr_fr_walk_nose_01;
my_mouth = spr_fr_walk_mouths_01;

hair_color = choose(
    c_white,
    c_yellow,
    c_orange,
    make_color_rgb(180, 100, 50)
);


// ═══════════════════════════════════════════════════════════════
// 5. ПРОПОРЦИОНАЛЬНЫЙ РОСТ И ПОРТРЕТ
// ═══════════════════════════════════════════════════════════════

var _person_scale = random_range(0.85, 1.15);

_height_scale = _person_scale;
_width_scale = _person_scale;

var _sprite_height = sprite_get_height(spr_human_FR_walk);
_draw_offset_y = _sprite_height * 0.5 * (1 - _person_scale);

sprite_index = spr_human_FR_walk;
portrait_bake();


// ═══════════════════════════════════════════════════════════════
// 6. ПИТОМЕЦ
// ═══════════════════════════════════════════════════════════════

my_pet = instance_create_layer(x + 20, y, "Instances", obj_dog_puppy);

if (instance_exists(my_pet)) {
    my_pet.my_owner = id;
}


// ═══════════════════════════════════════════════════════════════
// 7. ОЧЕРЕДЬ И РЕГИСТРАЦИЯ
// ═══════════════════════════════════════════════════════════════

state = "spawned";
assigned_desk = noone;

queue_slot = -1;
queue_target_x = x;
queue_target_y = y;
queue_purpose = "registration"; // registration / payment / none

registered = false;
wait_spot_index = -1;

registration_in_progress = false;
registration_timer = 0;
registration_timer_max = 0;
registration_actor_name = "";

// Владелец начнёт движение к стойке после создания всех объектов комнаты.
alarm[0] = 30;


// ═══════════════════════════════════════════════════════════════
// 8. ПРИЁМ И ВИЗИТ
// ═══════════════════════════════════════════════════════════════

assigned_doctor = noone;
assigned_table = noone;

exam_target_x = x;
exam_target_y = y;

scheduled_visit_id = "";
owner_record_id = "";
pet_record_id = "";
visit_id = "";

visit_type_id = "primary_exam";
visit_type_name_ru = "Первичный приём";
visit_reason_ru = "";
service_queue_type = "doctor"; // doctor / procedure

visit_price = 0;
pending_payment_total = 0;
payment_pending = false;
payment_done = false;
visit_done = false;

// Детализированный чек текущего визита.
finance_bill_items = [];
finance_bill_total = 0;
finance_bill_paid = false;
finance_paid_total = 0;
finance_paid_items = [];


// ═══════════════════════════════════════════════════════════════
// 9. ВЫХОД ИЗ КЛИНИКИ
// ═══════════════════════════════════════════════════════════════

entry_x = variable_global_exists("clinic_exit_x")
    ? global.clinic_exit_x
    : x;

entry_y = variable_global_exists("clinic_exit_y")
    ? global.clinic_exit_y
    : y;

leave_target_x = entry_x;
leave_target_y = entry_y;
leave_stuck_timer = 0;
