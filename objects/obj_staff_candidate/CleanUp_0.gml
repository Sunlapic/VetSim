///Cleanup obj_staff_candidate

event_inherited();

if (global.current_candidate == id) global.current_candidate = noone;
if (global.selected_candidate == id) global.selected_candidate = noone;