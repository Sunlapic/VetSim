/// Alarm 0 obj_owner
/// @description Добавление владельца в очередь регистратуры.

if (!instance_exists(obj_reception_desk)) exit;

var _desk = instance_find(obj_reception_desk, 0);
assigned_desk = _desk;


// ═══════════════════════════════════════════════════════════════
// 1. ОБНОВЛЕНИЕ ТОЧЕК СТОЙКИ
// ═══════════════════════════════════════════════════════════════

if (variable_instance_exists(_desk, "reception_refresh_points")) {
    with (_desk) {
        reception_refresh_points();
    }
}

if (!variable_instance_exists(_desk, "queue_list")) exit;


// ═══════════════════════════════════════════════════════════════
// 2. ДОБАВЛЕНИЕ В ОЧЕРЕДЬ
// ═══════════════════════════════════════════════════════════════

if (ds_list_find_index(_desk.queue_list, id) == -1) {
    ds_list_add(_desk.queue_list, id);
}

queue_purpose = "registration";
payment_pending = false;
payment_done = false;

queue_slot = ds_list_find_index(_desk.queue_list, id);
queue_target_x = _desk.queue_start_x + queue_slot * _desk.queue_step_x;
queue_target_y = _desk.queue_start_y;
state = "going_to_queue";


// ═══════════════════════════════════════════════════════════════
// 3. ДВИЖЕНИЕ К СВОЕМУ МЕСТУ
// ═══════════════════════════════════════════════════════════════

path_end();

if (mp_grid_path(
    global.ai_grid,
    my_path,
    x,
    y,
    queue_target_x,
    queue_target_y,
    true
)) {
    path_set_kind(my_path, 1);
    path_start(my_path, p_move_speed, path_action_stop, true);
    is_walking = true;
} else {
    show_debug_message(
        "[OWNER] Путь к очереди заблокирован: " + char_name
    );
}
