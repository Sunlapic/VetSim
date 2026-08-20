/// Create obj_inpatient_controller
/// @description Центральное состояние одной стационарной койки.
/// Пакет №73: койка определяется по exam_slot_id (101–104).

persistent = false;
visible = false;
depth = 100000;

// Номер койки. В Room Creation Code каждого контроллера пропиши:
// exam_slot_id = 101;  (койка 1)
// exam_slot_id = 102;  (койка 2)
// exam_slot_id = 103;  (койка 3)
// exam_slot_id = 104;  (койка 4)
if (!variable_instance_exists(id, "exam_slot_id")) {
    exam_slot_id = 100;
}

phase = "empty";

patient = noone;
departing_owner = noone;
returning_owner = noone;
escort_doctor = noone;
escort_return_x = x;
escort_return_y = y;
ward_doctor = noone;
ward_assistant = noone;

player_actor = noone;
player_task = "";

ward_table = noone;
doctor_chair = noone;
doctor_rest_point = noone;
doctor_point = noone;
assistant_point = noone;
pet_floor_point = noone;
pet_table_point = noone;
owner_point = noone;

owner_snapshot = {};
prescriptions_assigned = false;
treatment_actions = [];
cycle_action_index = 0;
cycle_active = false;
next_treatment_minute = -1;

missing_item_id = "";
missing_item_name = "";
stock_retry_timer = 0;
assistant_idle_restock_timer = 0;

admission_timer = 0;
doctor_action_timer = 0;
doctor_action_timer_max = 0;
assistant_action_timer = 0;
assistant_action_timer_max = 0;

link_retry_timer = 0;

inpatient_refresh_room_links(id);
