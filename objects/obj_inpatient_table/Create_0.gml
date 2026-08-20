/// Create obj_inpatient_table
/// @description Единственная стационарная койка/стол.

// Если объекту назначен par_objects, сохраняем его базовую инициализацию.
event_inherited();

ward_slot_id = 0;
exam_slot_id = 100;

table_busy = false;
assigned_owner = noone;
assigned_doctor = noone;
assigned_pet = noone;

depth = -y;
