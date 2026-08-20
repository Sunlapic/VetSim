/// Step obj_inpatient_table

depth = -y;

if (assigned_pet != noone && !instance_exists(assigned_pet)) {
    assigned_pet = noone;
    assigned_owner = noone;
    assigned_doctor = noone;
    table_busy = false;
}
