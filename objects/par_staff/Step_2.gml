        // ═════════════════════════════════════════════════
// par_staff → End Step ФИНАЛ (нет залипания анимации работы, нет ходьбы спиной)
// Пакет №75: стационарные состояния (inpatient_prescribing / inpatient_treating)
// включают рабочую анимацию и рисуются поверх койки, как на приёме.
// ═════════════════════════════════════════════════

// ─────────────────────────────────────────────
// 0.1 ИНИЦИАЛИЗАЦИЯ ПЕРЕМЕННЫХ И ОПРЕДЕЛЕНИЕ СОСТОЯНИЙ
// ─────────────────────────────────────────────
if (!variable_instance_exists(self, "_walk_sprite_cache")) _walk_sprite_cache = sprite_index;
if (!variable_instance_exists(self, "_work_anim_timer")) _work_anim_timer = 0;
if (!variable_instance_exists(self, "_work_anim_active")) _work_anim_active = false;
if (!variable_instance_exists(self, "_is_sitting")) _is_sitting = false;
if (!variable_instance_exists(self, "_idle_anim_timer")) _idle_anim_timer = 0;
if (!variable_instance_exists(self, "_sit_anim_timer")) _sit_anim_timer = 0;

var _sprite_idle_exists = sprite_exists(spr_human_FR_idle);
var _sprite_sit_exists  = sprite_exists(spr_human_FR_sit);
var _sprite_work_exists = sprite_exists(spr_human_FR_work);
var _sprite_carry_exists_f = sprite_exists(spr_human_FR_carry);
var _sprite_carry_exists_b = sprite_exists(spr_human_B_carry);

// ─────────────────────────────────────────────
// НАПРАВЛЕНИЕ ПО ФАКТИЧЕСКОМУ ДВИЖЕНИЮ
// Для заднего спрайта зеркалирование противоположное
// ─────────────────────────────────────────────

var _dx = x - xprevious;
var _dy = y - yprevious;

var _is_moving_horiz = abs(_dx) > 0.01;

// Проверяем, используется ли задний спрайт.
// Работает и для spr_human_B_walk,
// и для spr_human_B_carry.
var _is_back_view_now = false;

if (sprite_exists(sprite_index)) {
    _is_back_view_now =
        (string_pos("_B_", sprite_get_name(sprite_index)) > 0);
}

if (_is_moving_horiz) {

    if (_is_back_view_now) {

        // Задний спрайт зеркалится наоборот:
        // вверх-вправо
        if (_dx > 0) {
            pFacing = -1;
        }
        // вверх-влево
        else {
            pFacing = 1;
        }

    } else {

        // Передний спрайт:
        // вниз-вправо
        if (_dx > 0) {
            pFacing = 1;
        }
        // вниз-влево
        else {
            pFacing = -1;
        }

    }

}

// Определяем текущие состояния (ТОЛЬКО ФЛАГИ, НЕ МЕНЯЕМ СПРАЙТ ЗДЕСЬ!)
var _is_walking = is_walking;
var _is_carrying = false;
var _is_working = false;

// Переноска у ассистента
if (object_index == obj_staff_assistant && variable_instance_exists(self, "assistant_state")) begin
    _is_carrying = (variable_instance_exists(self, "restock_item_id") && restock_item_id != ""
                   && variable_instance_exists(self, "restock_qty") && restock_qty > 0
                   && (assistant_state == "restock_going_to_cabinet" || assistant_state == "restock_putting_in"));
end

// Работа у врача
if (object_index == obj_staff_doctor && variable_instance_exists(self, "doctor_state")) begin
    if (doctor_state == "examining"
     || doctor_state == "performing_procedure"
     || doctor_state == "inpatient_prescribing") _is_working = true;
end
// Работа у ассистента
if (object_index == obj_staff_assistant && variable_instance_exists(self, "assistant_state")) begin
    if (assistant_state == "performing_procedure" && !_is_carrying) _is_working = true;
    if (assistant_state == "inpatient_treating" && !_is_carrying) _is_working = true;
end
// Работа у админа за стойкой
if (object_index == obj_staff_admin && variable_instance_exists(self, "reception_state")) begin
    if (reception_state == "registering") _is_working = true;
end
// ─────────────────────────────────────────────
// СИНХРОНИЗАЦИЯ ДЕТАЛЕЙ ГОЛОВЫ
// Обязательно выполняется ДО выхода игрока
// ─────────────────────────────────────────────

_person_really_walking =
    is_walking
    && (
        abs(x - xprevious) > 0.1
        || abs(y - yprevious) > 0.1
    );

// ─────────────────────────────────────────────
// ИСКЛЮЧАЕМ ИГРОКА ИЗ NPC-ЛОГИКИ
// ─────────────────────────────────────────────

if (object_index == obj_player) exit;

// ─────────────────────────────────────────────
// 0.5 СБРАСЫВАЕМ is_walking ТОЛЬКО ДЛЯ ПУТЕЙ ГУЛЯНИЯ
// ─────────────────────────────────────────────
if (wander_walking) {
    var _wander_path_done = false;
    if (is_walking && path_index != -1) {
        if (path_position >= 0.98) _wander_path_done = true;
    } else {
        _wander_path_done = true;
    }
    if (_wander_path_done) {
        path_end();
        is_walking = false;
        _is_walking = false;
    }
}

// ─────────────────────────────────────────────
// 1. ОПРЕДЕЛЯЕМ, СВОБОДЕН ЛИ СОТРУДНИК
// ─────────────────────────────────────────────
var _is_idle = false;
var _is_assistant = false;
if (variable_instance_exists(id, "assistant_state")) {
    _is_assistant = true;
}

// Врач / ассистент
if (variable_instance_exists(id, "doctor_state") || variable_instance_exists(id, "assistant_state")) {
    var _state_doctor = "";
    if (variable_instance_exists(id, "doctor_state")) _state_doctor = doctor_state;
    if (_is_assistant) _state_doctor = assistant_state;

    var _no_targets = true;
    if (variable_instance_exists(id, "assigned_table") && instance_exists(assigned_table)) _no_targets = false;
    if (variable_instance_exists(id, "assigned_owner") && instance_exists(assigned_owner)) _no_targets = false;
    if (variable_instance_exists(id, "assigned_pet") && instance_exists(assigned_pet)) _no_targets = false;
    if (variable_instance_exists(id, "interact_target") && instance_exists(interact_target)) _no_targets = false;
    if (variable_instance_exists(id, "restock_item_id") && restock_item_id != "") _no_targets = false;

    _is_idle = (_state_doctor == "idle" && _no_targets);
    // Ассистент сначала проверяет, нужно ли пополнить шкаф,
// но НЕ выходит из End Step — иначе idle-анимация не включится.
if (_is_idle && _is_assistant) {

    restock_scan_needs();

    // Проверяем, не получил ли ассистент новую задачу после сканирования.
    var _assistant_started_task = (assistant_state != "idle");

    if (variable_instance_exists(id, "restock_item_id")) {
        if (restock_item_id != "") {
            _assistant_started_task = true;
        }
    }

    if (variable_instance_exists(id, "restock_target_storage")) {
        if (instance_exists(restock_target_storage)) {
            _assistant_started_task = true;
        }
    }

    if (variable_instance_exists(id, "restock_target_cabinet")) {
        if (instance_exists(restock_target_cabinet)) {
            _assistant_started_task = true;
        }
    }

    if (is_walking || (path_index != -1 && path_position < 1)) {
        _assistant_started_task = true;
    }

    // Если после проверки появилась задача,
    // ассистент больше не считается свободным в этом кадре.
    if (_assistant_started_task) {
        _is_idle = false;
    }
}
}

// Администратор
if (variable_instance_exists(id, "reception_state")) {
    var _queue_empty = true;
    if (instance_exists(reception_desk) && ds_exists(reception_desk.queue_list, ds_type_list)) {
        _queue_empty = (ds_list_size(reception_desk.queue_list) == 0);
    }
    _is_idle = (reception_state == "idle" && reception_client == noone && _queue_empty);
}

// ─────────────────────────────────────────────
// 2. ГУЛЯНИЕ (врач + ассистент + админ)
// ─────────────────────────────────────────────
if (_is_idle) {
    wander_idle_timer -= 1;
    if (!wander_walking && wander_idle_timer <= 0) {
        var _wx = wander_x1 + irandom(wander_x2 - wander_x1);
        var _wy = wander_y1 + irandom(wander_y2 - wander_y1);
        if (mp_grid_path(global.ai_grid, my_path, x, y, _wx, _wy, true)) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed * 0.6, path_action_stop, true);
            is_walking     = true;
            _is_walking     = true;
            wander_walking = true;
        }
        wander_idle_timer = room_speed * (1 + irandom(2));
    }
    if (wander_walking && !is_walking) {
        wander_walking    = false;
        wander_idle_timer = room_speed * (2 + irandom(4));
    }
} else {
    if (wander_walking) {
        if (path_index != -1 && is_walking) {
            var _end_x = path_get_x(my_path, 1);
            var _end_y = path_get_y(my_path, 1);
            var _in_wander_zone = (_end_x >= wander_x1 && _end_x <= wander_x2
                               && _end_y >= wander_y1 && _end_y <= wander_y2);
            if (_in_wander_zone) {
                path_end();
                is_walking = false;
                _is_walking = false;
            }
        }
    }
    wander_walking    = false;
    wander_idle_timer = room_speed * (2 + irandom(3));
}

// ─────────────────────────────────────────────
// 3. АНИМАЦИЯ ПУТИ (выбор спрайта ходьбы вперёд/назад)
// ─────────────────────────────────────────────
if (path_index != -1 && path_position < 1) {
    var _nx = path_get_x(my_path, path_position + 0.01);
    var _ny = path_get_y(my_path, path_position + 0.01);
    if (_ny < y) sprite_index = spr_human_B_walk; else sprite_index = spr_human_FR_walk;
    if (_nx > x) {
        if (sprite_index == spr_human_B_walk) pFacing = -1; else pFacing = 1;
    }
    else if (_nx < x) {
        if (sprite_index == spr_human_B_walk) pFacing = 1; else pFacing = -1;
    }
}

// ─────────────────────────────────────────────
// 4. РАЗВОРОТ К СТОЛУ
// Пакет №75: добавлены состояния стационара.
// ─────────────────────────────────────────────
if (variable_instance_exists(id, "assigned_table") && instance_exists(assigned_table)) {
    var _at_table = false;
    if (variable_instance_exists(id, "doctor_state")) {
        if (doctor_state == "waiting_positions"
         || doctor_state == "examining"
         || doctor_state == "manual_exam"
         || doctor_state == "manual_procedure"
         || doctor_state == "inpatient_prescribing") _at_table = true;
    }
    if (variable_instance_exists(id, "assistant_state")) {
        if (assistant_state == "waiting_positions"
         || assistant_state == "performing_procedure"
         || assistant_state == "inpatient_treating") _at_table = true;
    }
    if (_at_table) {
        var _table_cy = assigned_table.y;
        var _dx_table = assigned_table.x - x;
        var _face_right = (_dx_table > 0);
        if (y < _table_cy) {
            pFacing = _face_right ? 1 : -1;
        } else {
            pFacing = _face_right ? -1 : 1;
        }
    }
}

// ─────────────────────────────────────────────
// ФИНАЛЬНАЯ УСТАНОВКА СПРАЙТА И АНИМАЦИИ (ВСЕГДА ПОСЛЕДНЯЯ, НЕ ПЕРЕБИВАЕТСЯ НИЧЕМ)
// ─────────────────────────────────────────────
// Исправление: не застываем на первом кадре ходьбы, считаем движение и при активном пути
var _really_moving = _is_walking && ((path_index != -1 && path_position < 1) || abs(x - xprevious) > 0.1 || abs(y - yprevious) > 0.1);
var _is_back = false;

// ═══ СНАЧАЛА СБРАСЫВАЕМ ТАЙМЕР РАБОТЫ КОГДА РАБОТА ЗАКОНЧИЛАСЬ
if (!_is_working) {
    _work_anim_timer = 0;
    _work_anim_active = false;
}

// 1. Реально идём — гарантированно оставляем спрайт ходьбы и анимацию
if (_really_moving && !_is_working && !_is_carrying && !_is_sitting) {
    // Если вдруг спрайт сбился на idle — возвращаем правильный спрайт ходьбы
    if (sprite_index != spr_human_FR_walk && sprite_index != spr_human_B_walk && sprite_index != _walk_sprite_cache) {
        var _ny_next = path_get_y(my_path, min(path_position + 0.01, 1));
        sprite_index = _ny_next < y ? spr_human_B_walk : spr_human_FR_walk;
    }
    image_speed = 1;
    _idle_anim_timer = 0;
    _sit_anim_timer = 0;
    depth = -y;
}
// 2. РАБОТАЕМ — АНИМАЦИЯ РУК
// Во время работы персонаж рисуется поверх стола или стойки

else if (_is_working && _sprite_work_exists) {

    _work_anim_timer += 1;

    var _work_speed = 6;
    var _work_frames = sprite_get_number(spr_human_FR_work);

    sprite_index = spr_human_FR_work;

    image_speed = 0;
    image_index =
        floor(_work_anim_timer / _work_speed)
        mod _work_frames;

    path_end();

    is_walking = false;
    _is_walking = false;
    _work_anim_active = true;

    _idle_anim_timer = 0;
    _sit_anim_timer = 0;

    // ─────────────────────────────────────────
    // ВРАЧ ИЛИ АССИСТЕНТ У СМОТРОВОГО СТОЛА
    // ─────────────────────────────────────────

    if (
        variable_instance_exists(id, "assigned_table")
        && instance_exists(assigned_table)
    ) {
        // Рисуем рабочую анимацию поверх смотрового стола
        depth = assigned_table.depth - 3;
    }

    // ─────────────────────────────────────────
    // АДМИНИСТРАТОР У СТОЙКИ РЕГИСТРАТУРЫ
    // ─────────────────────────────────────────

    else if (
        object_index == obj_staff_admin
        && variable_instance_exists(id, "reception_state")
        && reception_state == "registering"
        && variable_instance_exists(id, "reception_desk")
        && instance_exists(reception_desk)
    ) {
        // Рисуем рабочую анимацию поверх стойки:
        // руки больше не будут уходить под столешницу
        depth = reception_desk.depth - 3;
    }

    // ─────────────────────────────────────────
    // ДРУГАЯ РАБОТА БЕЗ СТОЛА
    // ─────────────────────────────────────────

    else {
        depth = -y - 3;
    }
}
// 3. Сидим — анимация дыхания 12 как у владельцев
else if (_is_sitting && _sprite_sit_exists) {
    _sit_anim_timer += 1;
    var _sit_speed = 12;
    var _sit_frames = sprite_get_number(spr_human_FR_sit);
    sprite_index = spr_human_FR_sit;
    image_speed = 0;
    image_index = floor(_sit_anim_timer / _sit_speed) mod _sit_frames;
    depth = -y - 500;
    _idle_anim_timer = 0;
    _work_anim_timer = 0;
    path_end();
    is_walking = false;
    _is_walking = false;
}
// 4. Несём предмет
else if (_is_carrying && _sprite_carry_exists_f && _sprite_carry_exists_b) {
    if (variable_instance_exists(self, "is_back")) _is_back = is_back;
    else if (sprite_exists(sprite_index)) _is_back = (string_pos("_B_", sprite_get_name(sprite_index)) > 0);
    sprite_index = _is_back ? spr_human_B_carry : spr_human_FR_carry;
    image_speed = _really_moving ? 1 : 0;
    if (!_really_moving) image_index = 0;
    _idle_anim_timer = 0;
    _sit_anim_timer = 0;
    _work_anim_timer = 0;
    depth = -y;
}
// 5. Стоим на месте — анимация дыхания 10 как у владельцев
else if (_sprite_idle_exists) {
    _idle_anim_timer += 1;
    var _idle_speed = 10;
    var _idle_frames = sprite_get_number(spr_human_FR_idle);
    sprite_index = spr_human_FR_idle;
    image_speed = 0;
    image_index = floor(_idle_anim_timer / _idle_speed) mod _idle_frames;
    depth = -y;
    _sit_anim_timer = 0;
    _work_anim_timer = 0;
    is_walking = false;
    _is_walking = false;
}

// Применяем поворот
image_xscale = abs(image_xscale) * pFacing;

// ═══ ФИНАЛЬНАЯ СТРОЧКА ДЛЯ СТАТИЧНОГО ЛИЦА
_person_really_walking = is_walking && (abs(x - xprevious) > 0.1 || abs(y - yprevious) > 0.1);
