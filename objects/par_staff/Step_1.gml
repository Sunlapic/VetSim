/// Begin Step par_staff
/// @description Энергия, усталость, XP выносливости, защита от зависаний и реплики.


// ═══════════════════════════════════════════════════════════════
// 1. СТРАХОВОЧНАЯ ИНИЦИАЛИЗАЦИЯ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "stamina_level")) {
    stamina_level = (object_index == obj_player)
        ? 1
        : irandom_range(1, 10);
}
if (!variable_instance_exists(id, "stamina_xp")) stamina_xp = 0;

if (!variable_instance_exists(id, "walk_skill_level")) {
    walk_skill_level = (object_index == obj_player)
        ? 1
        : irandom_range(1, 10);
}
if (!variable_instance_exists(id, "walk_skill_xp")) walk_skill_xp = 0;
if (!variable_instance_exists(id, "walk_skill_timer")) walk_skill_timer = 0;
if (!variable_instance_exists(id, "walk_xp_last_x")) walk_xp_last_x = x;
if (!variable_instance_exists(id, "walk_xp_last_y")) walk_xp_last_y = y;

walk_skill_xp_needed = (walk_skill_level >= 10)
    ? 1
    : doctor_xp_needed(walk_skill_level);

if (!variable_instance_exists(id, "energy_max")) energy_max = 20 + stamina_level * 10;
if (!variable_instance_exists(id, "stat_energy")) stat_energy = energy_max;
if (!variable_instance_exists(id, "energy")) energy = stat_energy;
if (!variable_instance_exists(id, "energy_regen_accumulator")) energy_regen_accumulator = 0;

if (!variable_instance_exists(id, "p_move_speed_base")) {
    p_move_speed_base = p_move_speed;
}

if (!variable_instance_exists(id, "is_tired")) is_tired = false;
if (!variable_instance_exists(id, "is_exhausted")) is_exhausted = false;

if (!variable_instance_exists(id, "stuck_suspect_timer")) stuck_suspect_timer = 0;
if (!variable_instance_exists(id, "STUCK_THRESHOLD")) STUCK_THRESHOLD = room_speed * 2;

if (!variable_instance_exists(id, "wander_walking")) wander_walking = false;
if (!variable_instance_exists(id, "wander_idle_timer")) wander_idle_timer = room_speed * 2;

// Миграция старых непропорциональных персонажей и защита будущих изменений.
// Высота является единственным масштабом телосложения; ширина всегда равна ей.
if (!variable_instance_exists(id, "_height_scale")) {
    _height_scale = 1;
}

_height_scale = clamp(abs(_height_scale), 0.85, 1.15);
_width_scale = _height_scale;

// У уже размещённых в комнате сотрудников зарплата могла отсутствовать.
// Инициализируем её один раз; дальнейший пересчёт выполняется в полночь.
if (
    object_index != obj_player
    && object_index != obj_staff_candidate
    && (
        !variable_instance_exists(id, "salary")
        || salary <= 0
    )
) {
    salary = finance_calculate_staff_salary(id);
}

// Миграция старого порога XP на лечебную кривую.
stamina_xp_needed = (stamina_level >= 10)
    ? 1
    : doctor_xp_needed(stamina_level);

// Состояние предыдущего кадра нужно для определения начала усталости.
var _was_tired_before_recalc = is_tired;


// ═══════════════════════════════════════════════════════════════
// 2. ОПРЕДЕЛЕНИЕ ЗАТРАТНОГО ДЕЙСТВИЯ
// Во время остальных состояний энергия восстанавливается.
// ═══════════════════════════════════════════════════════════════

var _is_busy_action = false;
var _object = object_index;

if (_object == obj_staff_candidate) {
    // Кандидат не работает и не получает усталость/XP.
    _is_busy_action = false;
    is_tired = false;
    is_exhausted = false;
}
else {
    if (role == "doctor" && variable_instance_exists(id, "doctor_state")) {
        _is_busy_action = (
            doctor_state == "examining"
            || doctor_state == "manual_exam"
            || doctor_state == "manual_procedure"
            || doctor_state == "performing_procedure"
        );
    }
    else if (role == "admin" && variable_instance_exists(id, "reception_state")) {
        _is_busy_action = (reception_state == "registering");
    }
    else if (role == "assistant" && variable_instance_exists(id, "assistant_state")) {
        _is_busy_action = (
            assistant_state == "performing_procedure"
            || assistant_state == "restock_picking_up"
            || assistant_state == "restock_putting_in"
            // Старые названия оставлены для совместимости.
            || assistant_state == "putting_in"
            || assistant_state == "restocking"
        );
    }

    // Главный игрок использует doctor_state для всех ручных действий.
    if (_object == obj_player && variable_instance_exists(id, "doctor_state")) {
        _is_busy_action = (
            doctor_state == "manual_exam"
            || doctor_state == "manual_procedure"
            || doctor_state == "manual_registering"
            || doctor_state == "manual_payment"
        );
    }
}

// Длительность ручной регистрации и оплаты главного игрока.
// Этот пересчёт перекрывает старые локальные формулы 4/1 и 3/0.8,
// поэтому obj_player не требует точечной правки.
if (
    _object == obj_player
    && variable_instance_exists(id, "player_admin_skill_levels")
    && array_length(player_admin_skill_levels) >= 2
    && variable_instance_exists(id, "doctor_state")
) {
    var _player_admin_level = 1;

    if (
        doctor_state == "going_to_payment"
        || doctor_state == "manual_payment"
    ) {
        _player_admin_level = player_admin_skill_levels[1];
    } else {
        _player_admin_level = player_admin_skill_levels[0];
    }

    registration_duration = round(
        room_speed * lerp(10, 1, (_player_admin_level - 1) / 9)
    );
}


// ═══════════════════════════════════════════════════════════════
// 3. ВОССТАНОВЛЕНИЕ И СИНХРОНИЗАЦИЯ ЭНЕРГИИ
// ═══════════════════════════════════════════════════════════════

if (!_is_busy_action) {
    staff_regen_energy_idle();
}

stat_energy = clamp(stat_energy, 0, energy_max);
energy = stat_energy;


// ═══════════════════════════════════════════════════════════════
// 4. УСТАЛОСТЬ, СКОРОСТЬ И XP ВЫНОСЛИВОСТИ
// ═══════════════════════════════════════════════════════════════

var _tired_speed_multiplier = staff_recalc_tiredness();

// Базовая скорость: 100% на Lv.1 и +10% за каждый следующий уровень.
staff_recalc_walk_speed();
p_move_speed = p_move_speed_base * _tired_speed_multiplier;

// Активный path должен сразу реагировать на уровень и усталость.
if (path_index != -1) {
    path_speed = p_move_speed;
}

// Каждые 30 секунд фактического движения дают +2 XP скорости ходьбы.
// Используем собственную сохранённую позицию, потому что xprevious/yprevious
// в Begin Step часто уже равны текущим x/y и дают нулевую дистанцию.
var _walk_distance_this_frame = point_distance(
    walk_xp_last_x,
    walk_xp_last_y,
    x,
    y
);

var _actually_walking = (_walk_distance_this_frame > 0.05);

// Сохраняем позицию для следующего Begin Step.
walk_xp_last_x = x;
walk_xp_last_y = y;

if (_actually_walking && object_index != obj_staff_candidate) {
    walk_skill_timer += 1;

    if (walk_skill_timer >= room_speed * 30) {
        walk_skill_timer -= room_speed * 30;
        staff_add_walk_speed_xp(2, true);

        if (variable_instance_exists(id, "add_xp_log")) {
            add_xp_log("+2 СКОРОСТЬ ХОДЬБЫ");
        }
    }
}

// +5 XP выдаётся только в момент перехода из «не устал» в «устал».
if (
    is_tired
    && !_was_tired_before_recalc
    && object_index != obj_staff_candidate
) {
    staff_add_stamina_xp(5, true);

    if (variable_instance_exists(id, "add_xp_log")) {
        add_xp_log("+5 ВЫНОСЛИВОСТЬ");
    }
}


// ═══════════════════════════════════════════════════════════════
// 5. ЗАЩИТА ВРАЧА И АССИСТЕНТА ОТ ЗАВИСАНИЙ
// Не применяется к игроку и администратору.
// ═══════════════════════════════════════════════════════════════

var _run_stuck_protection = (
    object_index != obj_player
    && !variable_instance_exists(id, "reception_state")
);

if (_run_stuck_protection) {
    var _is_doctor = variable_instance_exists(id, "doctor_state");
    var _is_assistant = variable_instance_exists(id, "assistant_state");
    var _is_doctor_like = _is_doctor || _is_assistant;

    var _suspect = false;
    var _current_state = "";

    if (_is_doctor) _current_state = doctor_state;
    if (_is_assistant) _current_state = assistant_state;


    // ═══════════════════════════════════════════════════════════
    // 5.1 ПРОВЕРКА ССЫЛОК И СОСТОЯНИЙ
    // ═══════════════════════════════════════════════════════════

    if (_is_doctor_like) {
        if (assigned_table != noone && !instance_exists(assigned_table)) _suspect = true;
        if (assigned_owner != noone && !instance_exists(assigned_owner)) _suspect = true;
        if (assigned_pet != noone && !instance_exists(assigned_pet)) _suspect = true;

        if (
            variable_instance_exists(id, "interact_target")
            && interact_target != noone
            && !instance_exists(interact_target)
        ) {
            _suspect = true;
        }

        if (instance_exists(assigned_owner)) {
            if (assigned_owner.state == "leaving_clinic") {
                _suspect = true;
            }

            var _other_doctor = assigned_owner.assigned_doctor;

            if (_other_doctor != noone && _other_doctor != id) {
                _suspect = true;
            }

            if (
                !_suspect
                && assigned_owner.state != "waiting"
                && assigned_owner.state != "registering"
                && assigned_owner.state != "going_to_waiting"
                && assigned_owner.state != "going_to_exam"
                && assigned_owner.state != "in_exam"
                && assigned_owner.assigned_doctor != id
            ) {
                _suspect = true;
            }
        }

        if (instance_exists(assigned_table)) {
            var _table_doctor = assigned_table.assigned_doctor;

            if (_table_doctor != noone && _table_doctor != id) {
                _suspect = true;
            }
        }

        if (string_copy(_current_state, 1, 7) == "restock") {
            if (
                variable_instance_exists(id, "restock_target_storage")
                && restock_target_storage != noone
                && !instance_exists(restock_target_storage)
            ) {
                _suspect = true;
            }

            if (
                variable_instance_exists(id, "restock_target_cabinet")
                && restock_target_cabinet != noone
                && !instance_exists(restock_target_cabinet)
            ) {
                _suspect = true;
            }

            if (
                variable_instance_exists(id, "restock_pickup_inst")
                && restock_pickup_inst != noone
                && !instance_exists(restock_pickup_inst)
            ) {
                _suspect = true;
            }
        }

        if (!is_walking && (_current_state == "idle" || _current_state == "returning")) {
            if (
                assigned_table != noone
                || assigned_owner != noone
                || assigned_pet != noone
            ) {
                _suspect = true;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 5.2 ТАЙМЕР ПОДОЗРИТЕЛЬНОГО СОСТОЯНИЯ
    // ═══════════════════════════════════════════════════════════

    if (_suspect) {
        stuck_suspect_timer += 1;
    } else {
        stuck_suspect_timer = 0;
    }

    var _stuck_threshold = STUCK_THRESHOLD;

    if (_is_doctor_like && instance_exists(assigned_owner)) {
        if (
            assigned_owner.assigned_doctor != noone
            && assigned_owner.assigned_doctor != id
        ) {
            _stuck_threshold = room_speed * 0.30;
        }
    }

    if (string_copy(_current_state, 1, 7) == "restock") {
        _stuck_threshold = max(_stuck_threshold, room_speed);
    }


    // ═══════════════════════════════════════════════════════════
    // 5.3 СБРОС ЗАВИСШЕЙ ЗАДАЧИ
    // ═══════════════════════════════════════════════════════════

    if (stuck_suspect_timer >= _stuck_threshold) {
        if (_is_doctor_like) {
            if (_is_doctor && variable_instance_exists(id, "doctor_reset_exam")) {
                doctor_reset_exam();
            }

            if (_is_assistant && variable_instance_exists(id, "assistant_reset_procedure")) {
                assistant_reset_procedure();
            }
            else if (instance_exists(assigned_table)) {
                with (assigned_table) {
                    table_busy = false;
                    assigned_owner = noone;
                    assigned_doctor = noone;
                    assigned_pet = noone;
                }
            }

            if (variable_instance_exists(id, "assistant_reset_restock")) {
                assistant_reset_restock();
            }

            if (_is_doctor) doctor_state = "idle";
            if (_is_assistant) assistant_state = "idle";

            assigned_table = noone;
            assigned_owner = noone;
            assigned_pet = noone;

            if (variable_instance_exists(id, "interact_target")) {
                interact_target = noone;
            }
        }

        path_end();
        is_walking = false;
        wander_walking = false;
        wander_idle_timer = room_speed * (1 + irandom(2));
        stuck_suspect_timer = 0;
    }
}


// ═══════════════════════════════════════════════════════════════
// 6. РЕПЛИКИ ПРИ УСТАЛОСТИ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "_speech_cooldown")) _speech_cooldown = 0;
if (!variable_instance_exists(id, "_speech_last_tired")) _speech_last_tired = false;
if (!variable_instance_exists(id, "_speech_last_exhaust")) _speech_last_exhaust = false;

if (_speech_cooldown > 0) {
    _speech_cooldown -= 1;
}

if (object_index == obj_staff_candidate) {
    _speech_last_tired = false;
    _speech_last_exhaust = false;
}
else {
    var _can_speak = variable_struct_exists(global, "speech_say_random");

    if (
        is_exhausted
        && !_speech_last_exhaust
        && _speech_cooldown <= 0
        && _can_speak
    ) {
        var _exhausted_phrases = [
            "Я ВЫМОТАЛСЯ",
            "НЕ МОГУ БОЛЬШЕ",
            "НУЖЕН ОТДЫХ",
            "Я УСТАЛ",
            "СИЛ НЕТ",
            "ПЕРЕРЫВ..."
        ];

        global.speech_say_random(self, _exhausted_phrases, 2.8);

        _speech_last_exhaust = true;
        _speech_last_tired = true;
        _speech_cooldown = room_speed * 45;
    }
    else if (
        is_tired
        && !_speech_last_tired
        && !is_exhausted
        && _speech_cooldown <= 0
        && _can_speak
    ) {
        var _tired_phrases = [
            "Уф...",
            "ПОДУСТАЛ",
            "КОФЕ БЫ...",
            "ТЯЖЁЛЫЙ ДЕНЬ",
            "НЕМНОГО УСТАЛ"
        ];

        global.speech_say_random(self, _tired_phrases, 2.2);

        _speech_last_tired = true;
        _speech_cooldown = room_speed * 45;
    }

    if (!is_tired) {
        _speech_last_tired = false;
    }

    if (!is_exhausted) {
        _speech_last_exhaust = false;
    }
}
