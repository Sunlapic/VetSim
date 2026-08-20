/// Create par_staff
/// @description Общая инициализация персонала, энергии, выносливости, речи и XP-лога.


// ═══════════════════════════════════════════════════════════════
// 1. БАЗОВЫЕ ПАРАМЕТРЫ
// ═══════════════════════════════════════════════════════════════

my_path = path_add();

p_move_speed = 3.5;
p_move_speed_base = p_move_speed;
is_walking = false;
pFacing = 1;
is_hovered = false;

char_name = "Сотрудник";
role = "assistant";
age = 25;
character_trait = 0;

skills = array_create(10, 1);
skills_sum = 0;

depth = -y;


// ═══════════════════════════════════════════════════════════════
// 2. ВНЕШНОСТЬ И ПОРТРЕТ
// ═══════════════════════════════════════════════════════════════

portrait_offset = 35;
my_baked_portrait = -1;

hair_color = c_white;
my_hair = -1;
my_hair_back = -1;
my_eyes = -1;
my_nose = -1;
my_mouth = -1;

sprite_index = spr_human_FR_walk;
image_speed = 0;


// ═══════════════════════════════════════════════════════════════
// 3. ШКАЛА ТЕКУЩЕГО ДЕЙСТВИЯ
// ═══════════════════════════════════════════════════════════════

action_progress_active = false;
action_progress_timer = 0;
action_progress_timer_max = 0;
action_progress_label = "";
action_progress_color = make_color_rgb(80, 170, 90);


// ═══════════════════════════════════════════════════════════════
// 4. СВОБОДНОЕ ГУЛЯНИЕ И ЗАЩИТА ОТ ЗАВИСАНИЯ
// ═══════════════════════════════════════════════════════════════

wander_idle_timer = room_speed * (2 + irandom(3));
wander_walking = false;

wander_x1 = 1800;
wander_x2 = 3200;
wander_y1 = 1000;
wander_y2 = 1300;

stuck_suspect_timer = 0;
STUCK_THRESHOLD = room_speed * 2;


// ═══════════════════════════════════════════════════════════════
// 5. ГЛОБАЛЬНЫЕ ФУНКЦИИ РЕЧИ
// Создаются один раз первым появившимся сотрудником.
// ═══════════════════════════════════════════════════════════════

if (!variable_struct_exists(global, "__speech_funcs_ready")) {
    global.__speech_funcs_ready = true;

    global.speech_say = function(_who, _text, _seconds = 2.5) {
        if (!instance_exists(_who)) return noone;

        // У одного персонажа одновременно может быть только одно облачко.
        with (obj_speech_bubble) {
            if (target == _who) {
                instance_destroy();
            }
        }

        var _bubble = instance_create_depth(
            _who.x,
            _who.y,
            -1000,
            obj_speech_bubble
        );

        _bubble.target = _who;
        _bubble.bubble_text = _text;
        _bubble.duration = max(1, round(_seconds * room_speed));
        _bubble.life = 0;
        _bubble.image_alpha = 1;
        _bubble.y_base = _who.y + _bubble.b_y_off;
        _bubble.y = _bubble.y_base;

        return _bubble;
    };

    global.speech_say_random = function(_who, _phrases, _seconds = 2.5) {
        if (!is_array(_phrases)) return noone;
        if (array_length(_phrases) <= 0) return noone;

        var _text = _phrases[irandom(array_length(_phrases) - 1)];
        return global.speech_say(_who, _text, _seconds);
    };
}


// ═══════════════════════════════════════════════════════════════
// 6. ВОССТАНОВЛЕНИЕ ПЕРСОНАЛА В НАЧАЛЕ ДНЯ
// Глобальная функция создаётся один раз.
// ═══════════════════════════════════════════════════════════════

if (!variable_struct_exists(global, "__staff_daily_recharge_ready")) {
    global.__staff_daily_recharge_ready = true;

    global.staff_daily_recharge = function() {
        var _staff_instances = [];

        with (obj_player) {
            array_push(_staff_instances, id);
        }

        with (obj_staff_doctor) {
            if (object_index == obj_staff_doctor) {
                array_push(_staff_instances, id);
            }
        }

        with (obj_staff_assistant) {
            if (object_index == obj_staff_assistant) {
                array_push(_staff_instances, id);
            }
        }

        with (obj_staff_admin) {
            if (object_index == obj_staff_admin) {
                array_push(_staff_instances, id);
            }
        }

        var _recharged_count = 0;

        for (var _index = 0; _index < array_length(_staff_instances); _index++) {
            var _staff = _staff_instances[_index];

            if (!instance_exists(_staff)) continue;

            if (variable_instance_exists(_staff, "stat_energy")) {
                _staff.stat_energy = variable_instance_exists(_staff, "energy_max")
                    ? _staff.energy_max
                    : 100;
            }

            if (variable_instance_exists(_staff, "energy")) {
                _staff.energy = _staff.stat_energy;
            }

            if (variable_instance_exists(_staff, "is_tired")) {
                _staff.is_tired = false;
            }

            if (variable_instance_exists(_staff, "is_exhausted")) {
                _staff.is_exhausted = false;
            }

            if (variable_instance_exists(_staff, "_speech_cooldown")) {
                _staff._speech_cooldown = 0;
            }

            if (variable_instance_exists(_staff, "_speech_last_tired")) {
                _staff._speech_last_tired = false;
            }

            if (variable_instance_exists(_staff, "_speech_last_exhaust")) {
                _staff._speech_last_exhaust = false;
            }

            _recharged_count += 1;
        }

        if (instance_exists(obj_UI_HUD)) {
            var _hud = instance_find(obj_UI_HUD, 0);

            if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
                with (_hud) {
                    show_notice(
                        "НОВЫЙ ДЕНЬ",
                        "Сотрудники отдохнули, энергия восстановлена",
                        room_speed * 3
                    );
                }
            }
        }

        show_debug_message(
            "[DAY] staff_daily_recharge: восстановлено "
            + string(_recharged_count)
            + " сотрудников"
        );
    };
}


// ═══════════════════════════════════════════════════════════════
// 7. ЛОГ ПОСЛЕДНИХ ПОЛУЧЕННЫХ НАВЫКОВ
// ═══════════════════════════════════════════════════════════════

xp_log = [];

add_xp_log = function(_text) {
    // Совместимость со старой строкой ручной регистрации игрока.
    if (_text == "+4 РЕГИСТРАЦИЯ") {
        _text = "+5 РЕГИСТРАЦИЯ";
    }

    array_insert(xp_log, 0, { txt : _text });

    while (array_length(xp_log) > 5) {
        array_delete(xp_log, 5, 1);
    }
};

if (!variable_struct_exists(global, "__xp_log_staff_ready")) {
    global.__xp_log_staff_ready = true;

    global.xp_skill_names_doctor = [
        "ТЕРАПИЯ",
        "ПРОЦЕДУРЫ",
        "ХИРУРГИЯ",
        "ОФТАЛЬМОЛОГИЯ",
        "ОТОЛАРИНГ.",
        "ДЕРМАТОЛОГИЯ",
        "ИНФЕКЦ./ТОКС.",
        "АНЕСТЕЗИОЛ.",
        "ЛАБОРАТОРИЯ",
        "СТОМАТОЛОГИЯ"
    ];

    global.xp_skill_names_assistant = [
        "ПРОЦЕДУРЫ",
        "ПЕРЕВЯЗКИ",
        "ИНЪЕКЦИИ",
        "УХОД",
        "ПОПОЛНЕНИЕ",
        "СКОРОСТЬ",
        "ОБЩЕНИЕ",
        "ЧИСТОТА",
        "ВНИМАНИЕ",
        "СТРЕССОУСТ."
    ];

    global.xp_skill_names_admin = [
        "РЕГИСТРАЦИЯ",
        "КАССА",
        "СКОР.ХОДЬБЫ",
        "ОБЩЕНИЕ",
        "РАСПИСАНИЕ",
        "ДОКУМЕНТЫ",
        "ПРОДАЖИ",
        "КОНФЛИКТЫ",
        "ВНИМАНИЕ",
        "СТРЕССОУСТ."
    ];

    global.xp_get_skill_name = function(_role, _skill_index) {
        var _names = undefined;

        if (_role == "doctor" || _role == "player") {
            _names = global.xp_skill_names_doctor;
        }
        else if (_role == "assistant") {
            _names = global.xp_skill_names_assistant;
        }
        else if (_role == "admin") {
            _names = global.xp_skill_names_admin;
        }

        if (!is_array(_names)) return "НАВЫК";
        if (_skill_index < 0 || _skill_index >= array_length(_names)) return "НАВЫК";

        return _names[_skill_index];
    };
}


// ═══════════════════════════════════════════════════════════════
// 8. ЭНЕРГИЯ И СОСТОЯНИЯ УСТАЛОСТИ
// ═══════════════════════════════════════════════════════════════

stat_energy = 100;
energy_max = 100;
energy = stat_energy;
energy_regen_accumulator = 0;

is_tired = false;
is_exhausted = false;


// ═══════════════════════════════════════════════════════════════
// 9. ОБЩИЙ НАВЫК «СКОРОСТЬ ХОДЬБЫ»
// Одинаковая шкала для игрока, врачей, ассистентов и администраторов.
// ═══════════════════════════════════════════════════════════════

// У главного игрока общие навыки начинаются с Lv.1.
// У нанимаемых сотрудников стартовый уровень выбирается случайно.
walk_skill_level = (object_index == obj_player)
    ? 1
    : irandom_range(1, 10);
walk_skill_xp = 0;
walk_skill_xp_needed = doctor_xp_needed(walk_skill_level);
walk_skill_timer = 0;

// Собственная позиция предыдущего кадра для подсчёта реальной ходьбы.
// xprevious/yprevious в Begin Step могут уже совпадать с текущей позицией.
walk_xp_last_x = x;
walk_xp_last_y = y;

staff_recalc_walk_speed = function() {
    walk_skill_level = clamp(round(walk_skill_level), 1, 10);

    // Lv.1 = 100%, каждый следующий уровень даёт ещё +10%.
    // Пакет №71: Спортзал добавляет +10% за уровень к скорости персонала.
    var _walk_speed_percent = 100
        + (walk_skill_level - 1) * 10
        + clinic_get_gym_bonus_percent();
    p_move_speed_base = 1.4 * (_walk_speed_percent / 100);

    return p_move_speed_base;
};

staff_add_walk_speed_xp = function(_amount, _show_popup) {
    if (walk_skill_level >= 10) return false;

    walk_skill_xp += max(0, floor(_amount));

    var _level_up = false;

    while (walk_skill_level < 10) {
        walk_skill_xp_needed = doctor_xp_needed(walk_skill_level);

        if (walk_skill_xp < walk_skill_xp_needed) break;

        walk_skill_xp -= walk_skill_xp_needed;
        walk_skill_level += 1;
        _level_up = true;

        if (walk_skill_level >= 10) {
            walk_skill_level = 10;
            walk_skill_xp = 0;
            walk_skill_xp_needed = 1;
            break;
        }
    }

    if (walk_skill_level < 10) {
        walk_skill_xp_needed = doctor_xp_needed(walk_skill_level);
    }

    staff_recalc_walk_speed();

    if (_level_up && _show_popup && instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);
        var _title = "СКОРОСТЬ ХОДЬБЫ Lv." + string(walk_skill_level);
        var _walk_percent = 100 + (walk_skill_level - 1) * 10;
        var _message = char_name + ": скорость " + string(_walk_percent) + "%";

        if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
            with (_hud) {
                show_notice(_title, _message, room_speed * 3);
            }
        }
    }

    return _level_up;
};

staff_recalc_walk_speed();
p_move_speed = p_move_speed_base;


// ═══════════════════════════════════════════════════════════════
// 10. ВЫНОСЛИВОСТЬ И XP
// Выносливость растёт только при начале усталости.
// ═══════════════════════════════════════════════════════════════

stamina_level = (object_index == obj_player)
    ? 1
    : irandom_range(1, 10);
stamina_xp = 0;
stamina_xp_needed = (stamina_level >= 10)
    ? 1
    : doctor_xp_needed(stamina_level);

energy_max = 20 + stamina_level * 10;
stat_energy = energy_max;
energy = stat_energy;

// Трата энергии больше не выдаёт XP автоматически.
staff_spend_energy = function(_base_cost) {
    stat_energy = max(0, stat_energy - _base_cost);
    energy = stat_energy;
};

staff_add_stamina_xp = function(_amount, _show_popup) {
    if (stamina_level >= 10) return false;

    stamina_xp += max(0, floor(_amount));

    var _level_up = false;

    while (stamina_level < 10) {
        stamina_xp_needed = doctor_xp_needed(stamina_level);

        if (stamina_xp < stamina_xp_needed) break;

        stamina_xp -= stamina_xp_needed;
        stamina_level += 1;
        _level_up = true;

        energy_max = 20 + stamina_level * 10;
        stat_energy = min(stat_energy + 25, energy_max);
        energy = stat_energy;

        if (stamina_level >= 10) {
            stamina_level = 10;
            stamina_xp = 0;
            stamina_xp_needed = 1;
            break;
        }
    }

    if (stamina_level < 10) {
        stamina_xp_needed = doctor_xp_needed(stamina_level);
    }

    if (_level_up && _show_popup && instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);
        var _title = "ВЫНОСЛИВОСТЬ Lv." + string(stamina_level);
        var _message = char_name + ": максимум энергии " + string(energy_max);

        if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
            with (_hud) {
                show_notice(_title, _message, room_speed * 3);
            }
        }
    }

    return _level_up;
};

staff_recalc_tiredness = function() {
    var _tired_threshold = energy_max * 0.30;
    var _exhausted_threshold = energy_max * 0.10;

    is_tired = (stat_energy < _tired_threshold);
    is_exhausted = (stat_energy <= _exhausted_threshold);

    return is_tired ? 0.70 : 1.0;
};


// ═══════════════════════════════════════════════════════════════
// 11. ВОССТАНОВЛЕНИЕ ЭНЕРГИИ ВНЕ ЗАТРАТНОГО ДЕЙСТВИЯ
// Текущая скорость: 0,25 энергии в секунду.
// ═══════════════════════════════════════════════════════════════

staff_regen_energy_idle = function() {
    if (!variable_instance_exists(id, "energy_regen_accumulator")) {
        energy_regen_accumulator = 0;
    }

    var _regen_per_second = 0.25;
    var _regen_per_frame = _regen_per_second / room_speed;

    energy_regen_accumulator += _regen_per_frame;

    if (energy_regen_accumulator >= 1) {
        var _energy_to_add = floor(energy_regen_accumulator);

        stat_energy = min(energy_max, stat_energy + _energy_to_add);
        energy = stat_energy;
        energy_regen_accumulator -= _energy_to_add;
    }
};


// ═══════════════════════════════════════════════════════════════
// 12. ПРОПОРЦИОНАЛЬНЫЙ РОСТ
// Рост изменяет обе оси одинаково: человек становится целиком выше/крупнее
// или ниже/мельче, но больше не растягивается по вертикали.
// ═══════════════════════════════════════════════════════════════

var _person_scale = random_range(0.85, 1.15);

if (object_index == obj_player) {
    _person_scale = 1;
}

_height_scale = _person_scale;
_width_scale = _person_scale;

var _base_draw_scale = 0.5;
var _feet_offset_in_sprite = 27;

_draw_offset_y = _feet_offset_in_sprite
    * _base_draw_scale
    * (_person_scale - 1);

_person_really_walking = false;
