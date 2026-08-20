///Step par_animals

// 1. Подсветка теперь приходит только из obj_Render
is_hovered = (global.hover_target == id);

// 2. Клик по животному — открыть планшет
if (is_hovered && mouse_check_button_pressed(mb_left) && !global.ui_block_world_click && !(instance_exists(obj_UI_Tablet) && obj_UI_Tablet.visible)) {
    if (instance_exists(obj_UI_Tablet)) {
        obj_UI_Tablet.visible = true;
        obj_UI_Tablet.target_id = id;
    }
}

// 3. Если уже мёртв — ничего больше не делаем
if (is_dead) {
    depth = -y;
    exit;
}

// ─────────────────────────────────────────────
// 4. АНИМАЦИЯ ПРИ ДВИЖЕНИИ ПО PATH
// Для щенка анимацией управляет obj_dog_puppy End Step
// ─────────────────────────────────────────────
if (object_index != obj_dog_puppy) {

    if (path_index != -1 && path_position < 1) {
        image_speed = 1;

        var _nx = path_get_x(my_path, path_position + 0.02);

        if (_nx > x) pFacing = 1;
        if (_nx < x) pFacing = -1;

    } else {
        image_speed = 0;
        image_index = 0;
        is_walking = false;
    }

}

// ─────────────────────────────────────────────
// 5. СТЕЙТЫ ЖИВОТНОГО
// ─────────────────────────────────────────────
switch (state) {

    case "follow_owner":

        if (instance_exists(my_owner)) {

            if (!variable_instance_exists(id, "follow_offset_x")) follow_offset_x = 0;
            if (!variable_instance_exists(id, "follow_offset_y")) follow_offset_y = 0;

            var _tx = my_owner.x + follow_offset_x;
            var _ty = my_owner.y + follow_offset_y;

            x = lerp(x, _tx, 0.1);
            y = lerp(y, _ty, 0.1);

            if (abs(my_owner.x - x) > 3) {
                pFacing = (my_owner.x > x) ? 1 : -1;
            }
        }
    break;

    case "going_to_exam_floor":

        if (point_distance(x, y, exam_floor_x, exam_floor_y) <= 10) {
            path_end();
            is_walking = false;
            state = "jumping_to_table";
        }
    break;

    case "jumping_to_table":

        x = lerp(x, exam_table_x, table_jump_lerp);
        y = lerp(y, exam_table_y, table_jump_lerp);

        if (abs(exam_table_x - x) > 1) {
            pFacing = (exam_table_x > x) ? 1 : -1;
        }

        if (point_distance(x, y, exam_table_x, exam_table_y) <= 4) {
            x = exam_table_x;
            y = exam_table_y;
            state = "in_exam";
        }
    break;

    case "in_exam":
        path_end();
        is_walking = false;
        image_speed = 0;
        image_index = 0;
    break;

    case "leaving_clinic":

        if (point_distance(x, y, leave_target_x, leave_target_y) <= 16) {
            instance_destroy();
        }
    break;
}

// ─────────────────────────────────────────────
// 6. ОБНОВЛЕНИЕ ВОЗРАСТА И СОСТОЯНИЯ
// ─────────────────────────────────────────────
if (instance_exists(my_owner)) {

    if (variable_instance_exists(my_owner, "pet_birth_day")) {
        pet_age_days = global.game_day - my_owner.pet_birth_day;
    }

    if (pet_age_days < 30) {
        life_stage = PET_STAGE.PUPPY;
        image_xscale = 0.2;
        image_yscale = 0.2;
    } else if (pet_age_days < 60) {
        life_stage = PET_STAGE.TEEN;
        image_xscale = 0.4;
        image_yscale = 0.4;
    } else if (pet_age_days < 365) {
        life_stage = PET_STAGE.ADULT;
        image_xscale = 0.6;
        image_yscale = 0.6;
    } else {
        life_stage = PET_STAGE.SENIOR;
        image_xscale = 0.9;
        image_yscale = 0.9;
    }

    // ─────────────────────────────────────────
    // ВРЕМЕННОЕ ПРАВИЛО:
    // здоровье падает ТОЛЬКО пока пациент ждёт,
    // и НЕ падает в пути / в очереди / на приёме
    // ─────────────────────────────────────────
    var _allow_condition_drop = false;

    if (variable_instance_exists(my_owner, "state")) {
        switch (my_owner.state) {
            case "waiting":
                _allow_condition_drop = true;
            break;
        }
    }

    if (_allow_condition_drop && hidden_disease_id != "" && condition > 0) {

        condition_decay_counter += max(1, global.time_speed);

        if (condition_decay_counter >= condition_decay_interval) {
            condition_decay_counter -= condition_decay_interval;

            var _severity = 1;
            if (is_struct(current_case)) {
                if (variable_struct_exists(current_case, "severity_level")) {
                    _severity = current_case.severity_level;
                }
            }

            var _dec = 0.10; // лёгкий случай
            switch (_severity) {
                case 1: _dec = 0.10; break;
                case 2: _dec = 0.18; break;
                case 3: _dec = 0.30; break;
            }

            condition = max(0, condition - _dec);

            if (is_struct(current_case)) {
                current_case.condition = condition;
            }

            if (condition <= 0) {
                pet_die("illness");
            }
        }

    } else {
        condition_decay_counter = 0;
    }
}
// ─────────────────────────────────────────────
// 7. DEPTH
// Если животное на столе — рисуем его чуть ПОВЕРХ стола
// ─────────────────────────────────────────────
if ((state == "jumping_to_table" || state == "in_exam") && instance_exists(assigned_table)) {
    depth = assigned_table.depth - 1;
} else {
    depth = -y;
}