/// Step obj_staff_assistant
/// @description Автоматические процедуры и пополнение без телепортов.
/// Пакет №74 (hotfix): ассистент больше не зависает с «ПОПОЛНЕНИЕ»,
/// если точка подхода к складу/шкафу недостижима.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 1. СТРАХОВОЧНАЯ ИНИЦИАЛИЗАЦИЯ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "action_progress_active")) {
    action_progress_active = false;
    action_progress_timer = 0;
    action_progress_timer_max = 0;
    action_progress_label = "";
    action_progress_color = make_color_rgb(80, 170, 90);
}

if (!variable_instance_exists(id, "restock_item_id")) restock_item_id = "";
if (!variable_instance_exists(id, "restock_target_cabinet")) restock_target_cabinet = noone;
if (!variable_instance_exists(id, "restock_qty")) restock_qty = 0;
if (!variable_instance_exists(id, "restock_pickup_inst")) restock_pickup_inst = noone;
if (!variable_instance_exists(id, "action_progress_timer_tick")) action_progress_timer_tick = 0;
if (!variable_instance_exists(id, "procedure_retry")) procedure_retry = 0;
if (!variable_instance_exists(id, "procedure_was_interrupted_by_restock")) procedure_was_interrupted_by_restock = false;

// Пакет №74 (hotfix): защита от зависания при недостижимых точках подхода.
if (!variable_instance_exists(id, "restock_actual_x")) restock_actual_x = x;
if (!variable_instance_exists(id, "restock_actual_y")) restock_actual_y = y;
if (!variable_instance_exists(id, "restock_stuck_x")) restock_stuck_x = x;
if (!variable_instance_exists(id, "restock_stuck_y")) restock_stuck_y = y;
if (!variable_instance_exists(id, "restock_stuck_timer")) restock_stuck_timer = 0;
if (!variable_instance_exists(id, "restock_stuck_repaths")) restock_stuck_repaths = 0;

assistant_extra_skills_init(id);
assistant_recalc_restock_stats(id);

action_progress_active = false;

if (!instance_exists(assigned_owner)) assigned_owner = noone;
if (!instance_exists(assigned_table)) assigned_table = noone;
if (!instance_exists(assigned_pet)) assigned_pet = noone;
if (!instance_exists(restock_target_cabinet)) restock_target_cabinet = noone;
if (!instance_exists(restock_pickup_inst)) restock_pickup_inst = noone;


// ═══════════════════════════════════════════════════════════════
// 2. БЕЗОПАСНОЕ ДВИЖЕНИЕ К ЦЕЛИ
// ═══════════════════════════════════════════════════════════════

var _safe_walk = function(_target_x, _target_y) {
    path_end();
    is_walking = false;

    var _path_built = false;
    var _path_target_x = _target_x;
    var _path_target_y = _target_y;

    if (mp_grid_path(
        global.ai_grid,
        my_path,
        x,
        y,
        _target_x,
        _target_y,
        true
    )) {
        _path_built = true;
    } else {
        var _offsets = [-32, -24, -16, 0, 16, 24, 32];

        for (var _offset_x = 0; _offset_x < array_length(_offsets); _offset_x++) {
            for (var _offset_y = 0; _offset_y < array_length(_offsets); _offset_y++) {
                if (_offset_x == 3 && _offset_y == 3) continue;

                var _alternative_x = _target_x + _offsets[_offset_x];
                var _alternative_y = _target_y + _offsets[_offset_y];

                if (mp_grid_path(
                    global.ai_grid,
                    my_path,
                    x,
                    y,
                    _alternative_x,
                    _alternative_y,
                    true
                )) {
                    _path_target_x = _alternative_x;
                    _path_target_y = _alternative_y;
                    _path_built = true;
                    break;
                }
            }

            if (_path_built) break;
        }
    }

    if (_path_built) {
        path_set_kind(my_path, 1);
        path_start(my_path, p_move_speed, path_action_stop, true);
        is_walking = true;
        image_speed = 1;
    } else {
        // Резервное движение напрямую, без телепортации.
        move_towards_point(_target_x, _target_y, p_move_speed);
        is_walking = true;
        image_speed = 1;
    }

    // Запоминаем фактическую точку, куда реально можно дойти.
    // Проверка прибытия в going-состояниях идёт по этой точке,
    // поэтому недостижимый interact_y внутри стены больше не вешает ассистента.
    restock_actual_x = _path_target_x;
    restock_actual_y = _path_target_y;

    return _path_built;
};


// ═══════════════════════════════════════════════════════════════
// 3. СОСТОЯНИЯ АССИСТЕНТА
// ═══════════════════════════════════════════════════════════════

switch (assistant_state) {
    // ───────────────────────────────────────────────────────────
    // 3.1 ИДЁТ НА ОСНОВНОЙ СКЛАД
    // ───────────────────────────────────────────────────────────

    case "restock_going_to_storage": {
        if (
            !instance_exists(restock_pickup_inst)
            || !variable_instance_exists(restock_pickup_inst, "storage_inventory")
        ) {
            path_end();
            is_walking = false;
            assistant_reset_restock();
            assistant_state = "idle";
            break;
        }

        // Пакет №74 (hotfix): если точка подхода к складу недостижима,
        // ассистент останавливается на ближайшей клетке (16–32px от цели).
        // Раньше проверка ждала 12px и ассистент зависал с «ПОПОЛНЕНИЕ».
        var _pickup_dist = point_distance(
            x,
            y,
            restock_pickup_inst.interact_x,
            restock_pickup_inst.interact_y
        );

        if (
            _pickup_dist > 40
            && !is_walking
            && path_index < 0
        ) {
            _safe_walk(
                restock_pickup_inst.interact_x,
                restock_pickup_inst.interact_y
            );
        }

        if (_pickup_dist <= 40) {
            path_end();
            is_walking = false;

            var _take_amount = min(
                restock_qty,
                restock_carry_max,
                inventory_get_amount(global.inventory_main, restock_item_id)
            );

            if (_take_amount <= 0) {
                assistant_reset_restock();
                assistant_state = "idle";
                break;
            }

            inventory_add_amount(
                global.inventory_main,
                restock_item_id,
                -_take_amount
            );

            restock_qty = _take_amount;
            action_progress_timer_tick = restock_action_duration;
            assistant_state = "restock_picking_up";
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.2 БЕРЁТ ТОВАР
    // ───────────────────────────────────────────────────────────

    case "restock_picking_up": {
        action_progress_active = true;
        action_progress_timer_max = restock_action_duration;
        action_progress_timer = action_progress_timer_tick;
        action_progress_label = "БЕРЁТ ТОВАР";
        action_progress_color = make_color_rgb(72, 112, 145);

        action_progress_timer_tick -= 1;

        if (action_progress_timer_tick <= 0) {
            path_end();
            is_walking = false;

            if (!instance_exists(restock_target_cabinet)) {
                inventory_add_amount(
                    global.inventory_main,
                    restock_item_id,
                    restock_qty
                );

                assistant_reset_restock();
                assistant_state = "idle";
                break;
            }

            assistant_target_x = restock_target_cabinet.interact_x;
            assistant_target_y = restock_target_cabinet.interact_y;

            _safe_walk(assistant_target_x, assistant_target_y);
            assistant_state = "restock_going_to_cabinet";
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.3 ИДЁТ К ШКАФУ
    // ───────────────────────────────────────────────────────────

    case "restock_going_to_cabinet": {
        if (!instance_exists(restock_target_cabinet)) {
            inventory_add_amount(
                global.inventory_main,
                restock_item_id,
                restock_qty
            );

            path_end();
            is_walking = false;
            assistant_reset_restock();
            assistant_state = "idle";
            break;
        }

        // Пакет №74 (hotfix): та же защита от зависания у шкафа,
        // точка подхода которого недостижима (например, шкаф у стены).
        var _cabinet_dist = point_distance(
            x,
            y,
            restock_target_cabinet.interact_x,
            restock_target_cabinet.interact_y
        );

        if (
            _cabinet_dist > 40
            && !is_walking
            && path_index < 0
        ) {
            _safe_walk(
                restock_target_cabinet.interact_x,
                restock_target_cabinet.interact_y
            );
        }

        if (_cabinet_dist <= 40) {
            path_end();
            is_walking = false;
            action_progress_timer_tick = restock_action_duration;
            assistant_state = "restock_putting_in";
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.4 КЛАДЁТ ТОВАР В ШКАФ
    // ───────────────────────────────────────────────────────────

    case "restock_putting_in": {
        action_progress_active = true;
        action_progress_timer_max = restock_action_duration;
        action_progress_timer = action_progress_timer_tick;
        action_progress_label = "КЛАДЁТ В ШКАФ";
        action_progress_color = make_color_rgb(62, 112, 74);

        action_progress_timer_tick -= 1;

        if (action_progress_timer_tick <= 0) {
            var _put_amount = 0;

            if (
                instance_exists(restock_target_cabinet)
                && variable_instance_exists(restock_target_cabinet, "storage_inventory")
                && is_struct(restock_target_cabinet.storage_inventory)
            ) {
                var _cabinet_space = global.RESTOCK_MAX
                    - inventory_get_amount(
                        restock_target_cabinet.storage_inventory,
                        restock_item_id
                    );

                _put_amount = min(restock_qty, max(0, _cabinet_space));

                if (_put_amount > 0) {
                    inventory_add_amount(
                        restock_target_cabinet.storage_inventory,
                        restock_item_id,
                        _put_amount
                    );
                }

                var _leftover = restock_qty - _put_amount;

                if (_leftover > 0) {
                    inventory_add_amount(
                        global.inventory_main,
                        restock_item_id,
                        _leftover
                    );
                }
            } else {
                inventory_add_amount(
                    global.inventory_main,
                    restock_item_id,
                    restock_qty
                );
            }

            if (_put_amount > 0) {
                staff_spend_energy(2);
                assistant_add_skill_xp(id, 1, 2, true);
                add_xp_log("+2 ПОПОЛНЕНИЕ");
            }

            restock_qty = 0;
            assistant_reset_restock();

            path_end();
            is_walking = false;

            if (
                procedure_was_interrupted_by_restock
                && instance_exists(assigned_owner)
                && instance_exists(assigned_table)
                && instance_exists(assigned_pet)
            ) {
                procedure_was_interrupted_by_restock = false;

                assistant_target_x = interrupted_return_point_x;
                assistant_target_y = interrupted_return_point_y;
                assigned_table.table_busy = true;

                if (variable_struct_exists(global, "speech_say")) {
                    global.speech_say(self, "ПРОДОЛЖАЮ", 1.2);
                }

                _safe_walk(assistant_target_x, assistant_target_y);
                assistant_state = "going_to_assistant_point";
            } else {
                assistant_state = "idle";
            }
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.5 СВОБОДЕН: ПАЦИЕНТЫ ИЛИ ПОПОЛНЕНИЕ
    // ───────────────────────────────────────────────────────────

    case "idle": {
        if (is_exhausted) break;

        var _best_owner = noone;
        var _best_wait_index = 999999;

        for (var _owner_index = 0; _owner_index < instance_number(obj_owner); _owner_index++) {
            var _owner = instance_find(obj_owner, _owner_index);

            if (!instance_exists(_owner)) continue;

            if (
                _owner.state == "waiting"
                && _owner.assigned_doctor == noone
                && _owner.service_queue_type == "procedure"
                && _owner.wait_spot_index >= 0
                && _owner.wait_spot_index < _best_wait_index
            ) {
                _best_wait_index = _owner.wait_spot_index;
                _best_owner = _owner;
            }
        }

        var _free_table = noone;
        var _assistant_point = noone;
        var _owner_point = noone;
        var _pet_floor_point = noone;
        var _pet_table_point = noone;

        // Ищем свободный стол среди обоих типов.
        var _table_types = [obj_table, obj_table_1];

        for (var _type_index = 0; _type_index < array_length(_table_types); _type_index++) {
            var _table_object = _table_types[_type_index];

            for (var _table_index = 0; _table_index < instance_number(_table_object); _table_index++) {
                var _table = instance_find(_table_object, _table_index);

                if (!instance_exists(_table) || _table.table_busy) continue;

                var _slot = _table.exam_slot_id;
                var _doctor_point = noone;
                var _owner_point_test = noone;
                var _pet_floor_test = noone;
                var _pet_table_test = noone;

                for (var _point_index = 0; _point_index < instance_number(obj_exam_point_doctor); _point_index++) {
                    var _point = instance_find(obj_exam_point_doctor, _point_index);
                    if (instance_exists(_point) && _point.exam_slot_id == _slot) {
                        _doctor_point = _point;
                        break;
                    }
                }

                for (var _owner_point_index = 0; _owner_point_index < instance_number(obj_exam_point_owner); _owner_point_index++) {
                    var _point_owner = instance_find(obj_exam_point_owner, _owner_point_index);
                    if (instance_exists(_point_owner) && _point_owner.exam_slot_id == _slot) {
                        _owner_point_test = _point_owner;
                        break;
                    }
                }

                for (var _floor_index = 0; _floor_index < instance_number(obj_exam_point_pet_floor); _floor_index++) {
                    var _point_floor = instance_find(obj_exam_point_pet_floor, _floor_index);
                    if (instance_exists(_point_floor) && _point_floor.exam_slot_id == _slot) {
                        _pet_floor_test = _point_floor;
                        break;
                    }
                }

                for (var _pet_table_index = 0; _pet_table_index < instance_number(obj_exam_point_pet_table); _pet_table_index++) {
                    var _point_table = instance_find(obj_exam_point_pet_table, _pet_table_index);
                    if (instance_exists(_point_table) && _point_table.exam_slot_id == _slot) {
                        _pet_table_test = _point_table;
                        break;
                    }
                }

                if (
                    instance_exists(_doctor_point)
                    && instance_exists(_owner_point_test)
                    && instance_exists(_pet_floor_test)
                    && instance_exists(_pet_table_test)
                ) {
                    _free_table = _table;
                    _assistant_point = _doctor_point;
                    _owner_point = _owner_point_test;
                    _pet_floor_point = _pet_floor_test;
                    _pet_table_point = _pet_table_test;
                    break;
                }
            }

            if (instance_exists(_free_table)) break;
        }

        if (instance_exists(_best_owner) && instance_exists(_free_table)) {
            assigned_owner = _best_owner;
            assigned_table = _free_table;
            assigned_pet = instance_exists(_best_owner.my_pet)
                ? _best_owner.my_pet
                : noone;

            assistant_target_x = _assistant_point.x;
            assistant_target_y = _assistant_point.y;
            owner_target_x = _owner_point.x;
            owner_target_y = _owner_point.y;
            pet_floor_target_x = _pet_floor_point.x;
            pet_floor_target_y = _pet_floor_point.y;
            pet_table_target_x = _pet_table_point.x;
            pet_table_target_y = _pet_table_point.y;
            procedure_retry = 0;

            with (assigned_table) {
                table_busy = true;
                assigned_owner = other.assigned_owner;
                assigned_doctor = other.id;
                assigned_pet = other.assigned_pet;
            }

            _safe_walk(assigned_owner.x + 28, assigned_owner.y);
            assistant_state = "going_to_owner";
            break;
        }

        assistant_try_take_restock_job(id, false);
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.6 ИДЁТ К ВЛАДЕЛЬЦУ
    // ───────────────────────────────────────────────────────────

    case "going_to_owner": {
        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
            assistant_reset_procedure();
            break;
        }

        var _owner_taken = (
            assigned_owner.assigned_doctor != noone
            && assigned_owner.assigned_doctor != id
        );
        var _table_taken = (
            assigned_table.assigned_doctor != noone
            && assigned_table.assigned_doctor != id
        );
        var _owner_unavailable = (
            assigned_owner.state == "leaving_clinic"
            || assigned_owner.state == "paying"
            || assigned_owner.state == "registering"
        );

        if (_owner_taken || _table_taken || _owner_unavailable) {
            assistant_reset_procedure();
            break;
        }

        if (point_distance(x, y, assigned_owner.x, assigned_owner.y) <= 40) {
            with (assigned_owner) {
                assigned_doctor = other.id;
                assigned_table = other.assigned_table;

                if (
                    wait_spot_index >= 0
                    && variable_global_exists("wait_spots")
                    && wait_spot_index < array_length(global.wait_spots)
                ) {
                    global.wait_spots[wait_spot_index].occupied_by = noone;
                    wait_spot_index = -1;
                }

                exam_target_x = other.owner_target_x;
                exam_target_y = other.owner_target_y;
                state = "going_to_exam";

                path_end();
                is_walking = false;

                if (mp_grid_path(
                    global.ai_grid,
                    my_path,
                    x,
                    y,
                    exam_target_x,
                    exam_target_y,
                    true
                )) {
                    path_set_kind(my_path, 1);
                    path_start(my_path, p_move_speed, path_action_stop, true);
                    is_walking = true;
                    image_speed = 1;
                } else {
                    move_towards_point(
                        exam_target_x,
                        exam_target_y,
                        p_move_speed
                    );
                    is_walking = true;
                    image_speed = 1;
                }
            }

            if (instance_exists(assigned_pet)) {
                with (assigned_pet) {
                    assigned_doctor = other.id;
                    assigned_table = other.assigned_table;
                    exam_floor_x = other.pet_floor_target_x;
                    exam_floor_y = other.pet_floor_target_y;
                    exam_table_x = other.pet_table_target_x;
                    exam_table_y = other.pet_table_target_y;
                    state = "going_to_exam_floor";

                    path_end();
                    is_walking = false;

                    if (mp_grid_path(
                        global.ai_grid,
                        my_path,
                        x,
                        y,
                        exam_floor_x,
                        exam_floor_y,
                        true
                    )) {
                        path_set_kind(my_path, 1);
                        path_start(my_path, p_move_speed, path_action_stop, true);
                        is_walking = true;
                        image_speed = 1;
                    } else {
                        move_towards_point(
                            exam_floor_x,
                            exam_floor_y,
                            p_move_speed
                        );
                        is_walking = true;
                        image_speed = 1;
                    }
                }
            }

            _safe_walk(assistant_target_x, assistant_target_y);
            assistant_state = "going_to_assistant_point";
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.7 ИДЁТ К СВОЕЙ ТОЧКЕ
    // ───────────────────────────────────────────────────────────

    case "going_to_assistant_point": {
        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
            assistant_reset_procedure();
            break;
        }

        if (
            (assigned_owner.assigned_doctor != noone && assigned_owner.assigned_doctor != id)
            || (assigned_table.assigned_doctor != noone && assigned_table.assigned_doctor != id)
        ) {
            assistant_reset_procedure();
            break;
        }

        if (point_distance(x, y, assistant_target_x, assistant_target_y) <= 10) {
            path_end();
            is_walking = false;
            assistant_state = "waiting_positions";
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.8 ЖДЁТ ВЛАДЕЛЬЦА И ПИТОМЦА
    // ───────────────────────────────────────────────────────────

    case "waiting_positions": {
        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
            assistant_reset_procedure();
            break;
        }

        if (
            (assigned_owner.assigned_doctor != noone && assigned_owner.assigned_doctor != id)
            || (assigned_table.assigned_doctor != noone && assigned_table.assigned_doctor != id)
        ) {
            assistant_reset_procedure();
            break;
        }

        var _owner_ready = (assigned_owner.state == "in_exam");
        var _pet_ready = !instance_exists(assigned_pet)
            || assigned_pet.state == "in_exam";

        if (_owner_ready && _pet_ready) {
            procedure_condition_before = (
                instance_exists(assigned_pet)
                && is_struct(assigned_pet.current_case)
            ) ? assigned_pet.current_case.condition : 0;

            procedure_timer = procedure_duration;
            procedure_retry = 0;
            assistant_state = "performing_procedure";

            if (instance_exists(obj_UI_HUD)) {
                with (obj_UI_HUD) {
                    show_notice(
                        "АССИСТЕНТ",
                        "Ассистент начал выполнение назначений.",
                        room_speed * 2
                    );
                }
            }
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.9 ВЫПОЛНЯЕТ ПРОЦЕДУРЫ
    // ───────────────────────────────────────────────────────────

    case "performing_procedure": {
        action_progress_active = true;
        action_progress_timer = procedure_timer;
        action_progress_timer_max = procedure_duration;
        action_progress_label = "ПРОЦЕДУРА";
        action_progress_color = make_color_rgb(80, 170, 90);

        if (!instance_exists(assigned_owner) || !instance_exists(assigned_table)) {
            assistant_reset_procedure();
            break;
        }

        path_end();
        is_walking = false;
        procedure_timer -= 1;

        if (procedure_timer <= 0) {
            var _all_actions_completed = true;
            var _missing_item = "";

            if (instance_exists(assigned_pet) && is_struct(assigned_pet.current_case)) {
                var _pending_actions = variable_struct_exists(
                    assigned_pet.current_case,
                    "pending_procedure_actions"
                ) ? assigned_pet.current_case.pending_procedure_actions : [];

                for (var _action_index = 0; _action_index < array_length(_pending_actions); _action_index++) {
                    var _action_id = _pending_actions[_action_index];
                    var _action_ok = case_apply_treatment_action(
                        assigned_pet,
                        _action_id
                    );

                    if (!_action_ok) {
                        _all_actions_completed = false;

                        if (
                            variable_struct_exists(global.med_db.treatment_actions, _action_id)
                        ) {
                            var _action = variable_struct_get(
                                global.med_db.treatment_actions,
                                _action_id
                            );

                            if (
                                variable_struct_exists(_action, "required_items")
                                && array_length(_action.required_items) > 0
                            ) {
                                _missing_item = _action.required_items[0].item_id;
                            }
                        }

                        break;
                    }
                }
            }

            if (_all_actions_completed) {
                procedure_retry = 0;

                if (variable_global_exists("daily_stats")) {
                    global.daily_stats.procedures_done += 1;
                }

                staff_spend_energy(5);
                assistant_add_skill_xp(id, 0, 5, true);
                add_xp_log("+5 ПРОЦЕДУРЫ");

                assistant_finish_procedure_visit();
            } else {
                procedure_retry += 1;

                var _started_restock = assistant_try_take_restock_job(
                    id,
                    true
                );

                if (_started_restock) {
                    if (procedure_retry == 1 && instance_exists(obj_UI_HUD)) {
                        with (obj_UI_HUD) {
                            show_notice(
                                "ОЖИДАНИЕ ПРЕПАРАТА",
                                "Ассистент идёт за нужным препаратом",
                                room_speed * 2
                            );
                        }
                    }

                    procedure_was_interrupted_by_restock = true;
                    interrupted_procedure_action_id = _missing_item;
                    interrupted_return_point_x = assistant_target_x;
                    interrupted_return_point_y = assistant_target_y;

                    if (variable_struct_exists(global, "speech_say")) {
                        global.speech_say(
                            self,
                            "НЕТ " + string_upper(item_get_name(_missing_item)),
                            2.5
                        );
                    }
                } else {
                    action_progress_active = false;
                    action_progress_label = "ЖДЁТ ПРЕПАРАТ";

                    if (
                        procedure_retry == 1
                        || procedure_retry mod 10 == 0
                    ) {
                        if (instance_exists(obj_UI_HUD)) {
                            var _missing_name = item_get_name(_missing_item);

                            with (obj_UI_HUD) {
                                show_notice(
                                    "НЕТ ПРЕПАРАТА",
                                    "На складе закончился "
                                        + _missing_name
                                        + ". ЗАКУПИТЕ!",
                                    room_speed * 3
                                );
                            }
                        }
                    }

                    procedure_timer = room_speed * 2;
                }
            }
        }
    }
    break;


    // ───────────────────────────────────────────────────────────
    // 3.10 ВОЗВРАЩАЕТСЯ ДОМОЙ
    // ───────────────────────────────────────────────────────────

    case "returning": {
        if (point_distance(x, y, home_x, home_y) <= 10) {
            path_end();
            is_walking = false;
            assistant_state = "idle";
            break;
        }

        if (!is_walking || path_index < 0) {
            _safe_walk(home_x, home_y);
        }
    }
    break;
}


// ═══════════════════════════════════════════════════════════════
// 4. ЗАЩИТА АНИМАЦИИ ХОДЬБЫ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "_walk_freeze_timer")) {
    _walk_freeze_timer = 0;
}

var _is_working = (
    assistant_state == "performing_procedure"
    || assistant_state == "restock_picking_up"
    || assistant_state == "restock_putting_in"
);

var _is_carrying = (
    restock_item_id != ""
    && restock_qty > 0
);

if (is_walking && !_is_working && !_is_carrying) {
    if (image_speed < 0.9 || image_index == 0) {
        _walk_freeze_timer += 1;

        if (_walk_freeze_timer >= 12) {
            var _next_y = y;

            if (path_index != -1 && path_position < 1) {
                _next_y = path_get_y(
                    my_path,
                    min(path_position + 0.01, 1)
                );
            }

            sprite_index = (_next_y < y)
                ? spr_human_B_walk
                : spr_human_FR_walk;

            image_speed = 1;
            _walk_freeze_timer = 0;
        }
    } else {
        _walk_freeze_timer = 0;
    }
} else {
    _walk_freeze_timer = 0;
}


depth = -y;
