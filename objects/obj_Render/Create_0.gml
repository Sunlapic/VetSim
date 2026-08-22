/// Create obj_Render
/// @description Инициализация проекта без readonly debug_mode и устаревшего room_speed.
/// Пакет №138: убран вызов удалённого inventory_init() (склад наполняет db_init_items).
/// Пакет №140: global.inventory_main создаётся сразу (вместо удалённого inventory_init).
/// Пакет №144: тест — старт с $100 000 и 300 баллами.

randomize();

// Современная частота игры. Внутри Create используется вместо room_speed.
var _game_fps = max(1, game_get_speed(gamespeed_fps));

db_clients_init();
db_init_medical();
db_init_items();

// Пакет №140: создаём глобальный склад сразу (раньше это делал удалённый
// inventory_init). obj_storage_main → Create читает global.inventory_main,
// поэтому он обязан существовать до создания объектов комнаты.
if (!variable_global_exists("inventory_main")) {
    global.inventory_main = {};
}


// ═══════════════════════════════════════════════════════════════
// 1. ПОПОЛНЕНИЕ СКЛАДОВ
// ═══════════════════════════════════════════════════════════════

global.restock_jobs = [];
global.restock_scan_timer = 0;
global.RESTOCK_BATCH = 5;
global.RESTOCK_TARGET = 10;
global.RESTOCK_MAX = 10;


depth = 10000;


// ═══════════════════════════════════════════════════════════════
// 2. ГЛОБАЛЬНЫЕ СЧЁТЧИКИ И МАССИВЫ
// ═══════════════════════════════════════════════════════════════

global.game_day = 1;
global.owner_counter = 0;
global.pet_counter = 0;

global.city_citizens = [];
global.city_pet_owners = [];
global.active_visitors = [];


// ═══════════════════════════════════════════════════════════════
// 3. ОТЛАДКА
// debug_mode является встроенной readonly-переменной GameMaker.
// Пользовательский флаг обязан иметь другое имя.
// ═══════════════════════════════════════════════════════════════

global.vetsim_debug_mode = true;


// ═══════════════════════════════════════════════════════════════
// 4. HOVER И БЛОКИРОВКА МИРА
// ═══════════════════════════════════════════════════════════════

global.hover_target = noone;
hover_best = noone;
hover_best_dist = 1000000;
hover_best_y = -1000000;

global.ui_block_world_click = false;


// ═══════════════════════════════════════════════════════════════
// 5. КЛИНИКА И РЕСУРСЫ
// ═══════════════════════════════════════════════════════════════

global.clinic_name = "VetSim Clinic";
// Пакет №144 (тест): старт с большими деньгами и баллами.
// Вернуть обычный старт: money 15000, points убрать строку ниже.
global.clinic_money = 100000;
global.clinic_points = 300;
global.clinic_reputation = 35;


// ═══════════════════════════════════════════════════════════════
// 6. ВРЕМЯ И КАЛЕНДАРЬ
// ═══════════════════════════════════════════════════════════════

global.game_hour = 8;
global.game_minute = 0;

global.week_day_index = 0;
global.calendar_day = 1;
global.calendar_month = 1;
global.calendar_year = 1;

global.time_speed = 1;
global.time_paused = false;
global.time_step_frames = _game_fps;

time_accumulator = 0;
render_last_day = global.game_day;


// ═══════════════════════════════════════════════════════════════
// 7. СЕТКА AI
// ═══════════════════════════════════════════════════════════════

var _precision = 16;
var _grid_w = ceil(room_width / _precision);
var _grid_h = ceil(room_height / _precision);

global.ai_grid = mp_grid_create(
    0,
    0,
    _grid_w,
    _grid_h,
    _precision,
    _precision
);
mp_grid_add_instances(global.ai_grid, par_objects, true);


// ═══════════════════════════════════════════════════════════════
// 8. ТОЧКИ СПАВНА И ОЖИДАНИЯ
// ═══════════════════════════════════════════════════════════════

desk_x = 800;
desk_y = 400;

spawn_x = 100;
spawn_y = 100;

global.wait_spots = [];

for (var _wait_index = 0; _wait_index < instance_number(obj_wait_spot); _wait_index++) {
    var _spot = instance_find(obj_wait_spot, _wait_index);

    if (!instance_exists(_spot)) continue;

    array_push(global.wait_spots, {
        x : _spot.x,
        y : _spot.y,
        occupied_by : noone,
        marker_inst : _spot
    });
}

show_debug_message(
    "[WAIT SPOTS] Загружено "
    + string(array_length(global.wait_spots))
    + " точек ожидания"
);


// ═══════════════════════════════════════════════════════════════
// 9. СИСТЕМА КАНДИДАТОВ
// ═══════════════════════════════════════════════════════════════

global.current_candidate = noone;
global.selected_candidate = noone;
global.clinic_hiring_open = true;

global.candidate_test_mode = true;

candidate_spawn_x = 100;
candidate_spawn_y = 100;
candidate_exit_x = candidate_spawn_x;
candidate_exit_y = candidate_spawn_y;

if (global.candidate_test_mode) {
    candidate_min_gap_minutes = 5;
    candidate_max_gap_minutes = 12;
}
else {
    candidate_min_gap_minutes = 90;
    candidate_max_gap_minutes = 240;
}

global.next_candidate_day = global.game_day;

global.next_candidate_minute = global.candidate_test_mode
    ? global.game_hour * 60 + 2
    : 9 * 60;


// ═══════════════════════════════════════════════════════════════
// 10. СОЗДАНИЕ СЛУЧАЙНОГО ВЛАДЕЛЬЦА
// ═══════════════════════════════════════════════════════════════

function spawn_owner() {
    var _owner = instance_create_layer(
        spawn_x,
        spawn_y,
        "Instances",
        obj_owner
    );

    if (!instance_exists(_owner)) return noone;

    _owner.target_x = desk_x;
    _owner.target_y = desk_y;
    _owner.move_state = "walking_to_desk";

    _owner.visit_type_id = "primary_exam";
    _owner.visit_type_name_ru = "Первичный приём";
    _owner.visit_reason_ru = "Первичный приём";
    _owner.scheduled_visit_id = "";

    array_push(global.city_pet_owners, _owner);
    array_push(global.active_visitors, _owner);

    show_debug_message("[SPAWN] Владелец: " + _owner.char_name);
    return _owner;
}


// ═══════════════════════════════════════════════════════════════
// 11. РАСПИСАНИЕ КАНДИДАТОВ
// ═══════════════════════════════════════════════════════════════

function schedule_next_candidate(_after_resolution) {
    var _work_start = 9 * 60;
    var _work_end = 18 * 60;
    var _now = global.game_hour * 60 + global.game_minute;

    if (_after_resolution) {
        var _next = _now + irandom_range(
            candidate_min_gap_minutes,
            candidate_max_gap_minutes
        );

        if (_next <= _work_end) {
            global.next_candidate_day = global.game_day;
            global.next_candidate_minute = _next;
        }
        else {
            global.next_candidate_day = global.game_day + 1;
            global.next_candidate_minute = irandom_range(
                _work_start,
                16 * 60
            );
        }
    }
    else {
        global.next_candidate_day = global.game_day;
        global.next_candidate_minute = irandom_range(
            _work_start,
            16 * 60
        );
    }
}

function spawn_candidate() {
    if (instance_exists(global.current_candidate)) return noone;

    // Пакет №190: поиск остановлен (в ПЕРСОНАЛ -> ПОИСК сняты все
    // профессии) — кандидаты в клинику не приходят вообще.
    if (staff_hiring_search_is_paused()) {
        // Проверять каждую минуту незачем — переносим на завтра.
        global.next_candidate_day = global.game_day + 1;
        global.next_candidate_minute = irandom_range(9 * 60, 16 * 60);
        return noone;
    }

    if (!instance_exists(obj_candidate_spot)) {
        show_debug_message("[HIRING] Нет obj_candidate_spot в комнате.");
        schedule_next_candidate(false);
        return noone;
    }

    var _candidate = instance_create_layer(
        candidate_spawn_x,
        candidate_spawn_y,
        "Instances",
        obj_staff_candidate
    );

    if (!instance_exists(_candidate)) return noone;

    _candidate.entry_x = candidate_spawn_x;
    _candidate.entry_y = candidate_spawn_y;
    _candidate.exit_x = candidate_exit_x;
    _candidate.exit_y = candidate_exit_y;

    global.current_candidate = _candidate;

    show_debug_message(
        "[HIRING] Пришел кандидат: "
        + _candidate.char_name
        + " | "
        + string_upper(_candidate.role)
    );

    if (instance_exists(obj_UI_HUD)) {
        with (obj_UI_HUD) {
            show_notice(
                "НОВЫЙ КАНДИДАТ",
                "В клинику прибыл новый кандидат.",
                game_get_speed(gamespeed_fps) * 4
            );
        }
    }

    return _candidate;
}

schedule_next_candidate(false);


// ═══════════════════════════════════════════════════════════════
// 12. КАМЕРА И ЗУМ
// ═══════════════════════════════════════════════════════════════

camera_mode = "free";
camera_focus_target = noone;
camera_focus_timer = 0;
camera_follow_lerp = 0.10;

camera_drag_active = false;
camera_drag_start_mouse_x = 0;
camera_drag_start_mouse_y = 0;
camera_drag_start_view_x = 0;
camera_drag_start_view_y = 0;
camera_drag_sensitivity = 1.0;

zoom_level = 1.0;
zoom_target = 1.0;
zoom_speed = 0.18;
zoom_min = 0.5;
zoom_max = 2.0;

cam_base_w = camera_get_view_width(view_camera[0]);
cam_base_h = camera_get_view_height(view_camera[0]);

zoom_anchor_x = camera_get_view_x(view_camera[0]) + cam_base_w * 0.5;
zoom_anchor_y = camera_get_view_y(view_camera[0]) + cam_base_h * 0.5;
zoom_animating = false;
zoom_epsilon = 0.001;


// ═══════════════════════════════════════════════════════════════
// 13. ВЫХОД И БАЗОВАЯ ЦЕНА ПРИЁМА
// ═══════════════════════════════════════════════════════════════

global.clinic_exit_x = spawn_x;
global.clinic_exit_y = spawn_y;
global.base_visit_price = 180;
global.visit_price_random = 90;


// ═══════════════════════════════════════════════════════════════
// 14. РАБОЧИЙ ДЕНЬ И ПОТОК КЛИЕНТОВ
// ═══════════════════════════════════════════════════════════════

global.clinic_day_start_minute = 9 * 60;
global.clinic_day_end_minute = 22 * 60;

global.followup_morning_start = 10 * 60;
global.followup_morning_end = global.clinic_day_end_minute;
global.followup_spacing_minutes = 15;

global.max_active_visitors = 7;

global.min_random_clients_per_day = 5;
global.max_random_clients_per_day = 15;

followup_spawn_cooldown = 0;
followup_spawn_interval_frames = 0;

arrival_spawn_cooldown = 0;
arrival_spawn_interval_frames = 0;

global.random_arrival_min_seconds = 5;
global.random_arrival_max_seconds = 60;
global.random_arrival_min_frames = _game_fps
    * global.random_arrival_min_seconds;
global.random_arrival_max_frames = _game_fps
    * global.random_arrival_max_seconds;

random_arrival_pending = false;
random_arrival_cooldown = 0;

global.daily_random_visits = [];
global.daily_random_spawned_today = 0;
schedule_daily_random_visits();

alarm[0] = -1;


// ═══════════════════════════════════════════════════════════════
// 15. ПЕРЕНОС ПРЕПАРАТОВ И RADIAL-МЕНЮ
// ═══════════════════════════════════════════════════════════════

global.PLAYER_CARRY_MAX = 5;
global.player_carry_item = "";
global.player_carry_qty = 0;

global.radial_open = false;
global.radial_target = noone;
global.radial_x = 0;
global.radial_y = 0;


// ═══════════════════════════════════════════════════════════════
// 16. ДНЕВНАЯ СТАТИСТИКА
// ═══════════════════════════════════════════════════════════════

global.daily_stats = {
    paid_visits : 0,
    earned_money : 0,
    spent_money : 0,
    salary_expense : 0,
    new_diagnosed : 0,
    procedures_done : 0,
    cured : 0,
    followups_scheduled : 0,
    reputation_start : global.clinic_reputation,
    reputation_delta : 0,
    day_start_money : global.clinic_money
};

global.day_summary_open = false;
global.day_summary_ready = false;
global.day_summary_wait_frames = 0;

// Состояние ежедневной выплаты зарплаты.
global.finance_last_payroll_day = -1;
global.finance_last_payroll_total = 0;
global.finance_last_payroll_lines = [];
