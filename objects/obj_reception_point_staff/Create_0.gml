/// Create obj_reception_point_staff

// Номер стойки, к которой относится точка
if (!variable_instance_exists(id, "reception_slot_id")) {
    reception_slot_id = 1;
}

// В Room Editor точка видна, во время игры скрыта
visible = false;

solid = false;
persistent = false;