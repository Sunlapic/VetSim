/// Create obj_reception_point_owner

// Номер стойки, к которой относится точка
if (!variable_instance_exists(id, "reception_slot_id")) {
    reception_slot_id = 1;
}

// В игре служебный спрайт не показываем.
// В Room Editor он всё равно останется виден.
visible = false;

solid = false;
persistent = false;