///Create obj_table_1

event_inherited();

// Уникальный слот кабинета / стола
if (!variable_instance_exists(id, "exam_slot_id")) {
    exam_slot_id = 2;
}

// Состояние стола
table_busy = false;
assigned_owner = noone;
assigned_doctor = noone;
assigned_pet = noone;

// Длительность приёма
exam_duration = room_speed * 5;

// Базовая interact point логика
interact_x = x;
interact_y = y + 40;
