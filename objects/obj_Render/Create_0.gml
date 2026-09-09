/// Create obj_Render
/// @description Инициализация проекта без readonly debug_mode и устаревшего game_get_speed(gamespeed_fps).
///
/// ═══════════════════════════════════════════════════════════════
/// ПАКЕТ №300: СОБЫТИЕ РАЗДЕЛЕНО НА ПРОГРЕСС И ОБСТАНОВКУ
///
/// obj_Render не persistent. Пока комната была одна, это не мешало,
/// но для перехода между клиниками стало опасно: при room_goto объект
/// пересоздаётся и Create отрабатывает ВТОРОЙ раз.
///
/// Здесь 73 присваивания global, и защита стояла только у трёх. Всё
/// остальное сбрасывалось безусловно — деньги возвращались к стартовым
/// 100 000, репутация к 35, время на 8 утра, календарь на первый день,
/// список жителей города очищался. То есть переезд в новую клинику
/// откатил бы игру к началу.
///
/// Теперь:
///
///   • ПРОГРЕСС — под `if (!variable_global_exists(...))`. Создаётся
///     один раз за запуск и переживает любые переходы. Список сверен
///     с save_system: там перечислено ровно то, что игра считает
///     прогрессом и пишет в сохранение.
///
///   • ОБСТАНОВКА КОМНАТЫ (сетка путей, точки ожидания, вход) —
///     переехала в clinic_scene_system и вызывается из нового события
///     Room Start. Она обязана пересобираться под каждую клинику.
///
///   • НАСТРОЙКИ И КОНСТАНТЫ (цены, лимиты, расписание) остались как
///     были: их безопасно присваивать повторно, они одинаковы всегда.
/// ═══════════════════════════════════════════════════════════════
/// Пакет №138: убран вызов удалённого inventory_init() (склад наполняет db_init_items).
/// Пакет №140: global.inventory_main создаётся сразу (вместо удалённого inventory_init).
/// Пакет №144: тест — старт с $100 000 и 300 баллами.

randomize();

// Современная частота игры. Внутри Create используется вместо game_get_speed(gamespeed_fps).
var _game_fps = max(1, game_get_speed(gamespeed_fps));

db_clients_init();
db_init_medical();
db_init_items();

// Пакет №280: сеть клиник для экрана карты.
// Вызов безопасен при повторе — если список уже есть (например,
// поднят из сохранения), функция ничего не трогает.
clinics_init();

// Пакет №287: массив истории финансов. Функция идемпотентна:
// если загрузка уже подняла историю из сейва, она её не затрёт.
finance_history_init();

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
// Пакет №211: ассистент идёт пополнять шкаф, только если не хватает
// хотя бы стольких единиц. Из-за нехватки одной штуки он больше не бегает.
global.RESTOCK_MIN_GAP = 5;
global.RESTOCK_MAX = 10;


depth = 10000;


// ═══════════════════════════════════════════════════════════════
// 2. ГЛОБАЛЬНЫЕ СЧЁТЧИКИ И МАССИВЫ
// ═══════════════════════════════════════════════════════════════

// ПАКЕТ №300: прогресс. Счётчики и списки жителей города копятся всю
// игру — при переезде в другую клинику их нельзя обнулять.
//
// active_visitors — исключение: это посетители, которые физически
// находятся в комнате. При смене клиники старые инстансы уничтожаются
// вместе с комнатой, поэтому список честно начинается заново.
if (!variable_global_exists("game_day")) global.game_day = 1;
if (!variable_global_exists("owner_counter")) global.owner_counter = 0;
if (!variable_global_exists("pet_counter")) global.pet_counter = 0;

if (!variable_global_exists("city_citizens")) global.city_citizens = [];
if (!variable_global_exists("city_pet_owners")) global.city_pet_owners = [];

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

// ПАКЕТ №300: прогресс. Это первое, что ломалось бы при переезде —
// деньги возвращались к стартовым, а купленная клиника «оплачивалась»
// заново.
//
// ПАКЕТ №329: тестовый старт — 100 000 денег и 500 баллов, пока
// четыре клиники расставляются в редакторе. Обычный старт партии:
// 15 000 денег и 0 баллов. Значения дублируются в скрипте
// vet_new_game (NEW_GAME_START_MONEY / NEW_GAME_START_POINTS) и в
// запасных значениях save_system — менять нужно во всех местах.
//
// Пакет №144 (тест): старт с большими деньгами и баллами.
// Вернуть обычный старт: money 15000, points убрать строку ниже.
if (!variable_global_exists("clinic_name")) global.clinic_name = "VetSim Clinic";
if (!variable_global_exists("clinic_money")) global.clinic_money = 100000;
if (!variable_global_exists("clinic_points")) global.clinic_points = 500;
// ПАКЕТ №325: старт с нулевой репутацией. Правда всё равно лежит в
// кармане клиники — это значение подменяет clinic_apply_current в
// Room Start. Ноль здесь нужен, чтобы первый кадр не показывал 35.
if (!variable_global_exists("clinic_reputation")) global.clinic_reputation = 0;


// ═══════════════════════════════════════════════════════════════
// 6. ВРЕМЯ И КАЛЕНДАРЬ
// ═══════════════════════════════════════════════════════════════

// ПАКЕТ №300: время у сети клиник ОБЩЕЕ — переезд не должен
// отматывать часы на утро, а календарь на первое число.
// ПАКЕТ №342: утро по умолчанию — 10:00, как в новой игре.
if (!variable_global_exists("game_hour")) global.game_hour = 10;
if (!variable_global_exists("game_minute")) global.game_minute = 0;

if (!variable_global_exists("week_day_index")) global.week_day_index = 0;
if (!variable_global_exists("calendar_day")) global.calendar_day = 1;
if (!variable_global_exists("calendar_month")) global.calendar_month = 1;
if (!variable_global_exists("calendar_year")) global.calendar_year = 1;

// Скорость и пауза — настройки сеанса, а не прогресс: при входе в
// новую клинику логично снимать паузу и возвращать обычный темп.
global.time_speed = 1;
global.time_paused = false;
global.time_step_frames = _game_fps;

time_accumulator = 0;
render_last_day = global.game_day;


// ═══════════════════════════════════════════════════════════════
// 7. СЕТКА AI
//
// ПАКЕТ №300: переехала в clinic_scene_build_grid (скрипт
// clinic_scene_system), вызывается из нового события Room Start.
//
// Причина: размер сетки считается от room_width/room_height, а
// препятствия собираются обходом объектов ТЕКУЩЕЙ комнаты. В другой
// клинике геометрия другая, и сетку обязательно строить заново —
// иначе персонажи ходили бы по карте прошлой клиники.
//
// Здесь оставлена только заглушка: до Room Start ни один объект
// комнаты сетку не трогает, но переменная должна существовать.
if (!variable_global_exists("ai_grid")) {
    global.ai_grid = -1;
}


// ═══════════════════════════════════════════════════════════════
// 8. ТОЧКИ СПАВНА И ОЖИДАНИЯ
// ═══════════════════════════════════════════════════════════════

desk_x = 800;
desk_y = 400;

// ПАКЕТ №300: точки ожидания и координаты входа собираются в
// clinic_scene_system → Room Start, потому что зависят от объектов
// конкретной комнаты (obj_wait_spot их может быть разное количество).
//
// Значения ниже — только начальные, до первого Room Start. Он
// срабатывает сразу после создания объектов комнаты и перезапишет их.
spawn_x = 100;
spawn_y = 100;

if (!variable_global_exists("wait_spots")) {
    global.wait_spots = [];
}


// ═══════════════════════════════════════════════════════════════
// 9. СИСТЕМА КАНДИДАТОВ
// ═══════════════════════════════════════════════════════════════

global.current_candidate = noone;
global.selected_candidate = noone;
global.clinic_hiring_open = true;

global.candidate_test_mode = true;

// ПАКЕТ №300: перезаписываются в Room Start под вход текущей клиники.
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

// ПАКЕТ №300: расписание найма — прогресс. Иначе каждый переезд
// сбрасывал бы очередь кандидатов на «прямо сейчас».
if (!variable_global_exists("next_candidate_day")) {
    global.next_candidate_day = global.game_day;
}

if (!variable_global_exists("next_candidate_minute")) {
    global.next_candidate_minute = global.candidate_test_mode
        ? global.game_hour * 60 + 2
        : 9 * 60;
}


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

// ПАКЕТ №300: точный выход ставит Room Start (clinic_scene_apply_spawn).
// Здесь — начальное значение, чтобы переменная существовала раньше.
if (!variable_global_exists("clinic_exit_x")) {
    global.clinic_exit_x = spawn_x;
    global.clinic_exit_y = spawn_y;
}

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

// Пакет №211: обнуление дневной статистики вынесено в функцию —
// её вызывает и полночь, и закрытие окна итогов.
global.daily_stats_reset_pending = false;

function daily_stats_reset_now() {
    // ═══════════════════════════════════════════════════════
    // ПАКЕТ №287: СНИМОК ДНЯ В ИСТОРИЮ
    //
    // Снимаем ДО обнуления — ниже все цифры станут нулями.
    //
    // Точка выбрана именно здесь, а не в полночи obj_Render/Step:
    // сброс вызывается из ДВУХ мест (обычное и отложенное
    // из пакета 211, когда открыто окно итогов дня). Одна точка
    // внутри функции обслуживает оба пути и не даёт потерять день.
    //
    // Повторный вызов за тот же день дубля не создаёт —
    // finance_history_close_day обновит запись на месте.
    // ═══════════════════════════════════════════════════════
    finance_history_close_day();

    global.daily_stats.paid_visits = 0;
    global.daily_stats.earned_money = 0;
    global.daily_stats.spent_money = 0;
    global.daily_stats.salary_expense = 0;
    global.daily_stats.new_diagnosed = 0;
    global.daily_stats.procedures_done = 0;
    global.daily_stats.cured = 0;
    global.daily_stats.followups_scheduled = 0;
    global.daily_stats.reputation_start = global.clinic_reputation;
    global.daily_stats.reputation_delta = 0;
    global.daily_stats.day_start_money = global.clinic_money;

    // Доход по отделениям (приём / стационар / операционная) обнуляется
    // вместе с остальным — иначе утром в ФИНАНСАХ висели вчерашние цифры.
    if (
        variable_global_exists("finance_income_by_dept")
        && is_struct(global.finance_income_by_dept)
    ) {
        global.finance_income_by_dept.reception = 0;
        global.finance_income_by_dept.inpatient = 0;
        global.finance_income_by_dept.operating = 0;
        global.finance_income_by_dept.day = variable_global_exists("game_day")
            ? global.game_day
            : 0;
    }
}

global.day_summary_open = false;
global.day_summary_ready = false;
global.day_summary_wait_frames = 0;
// Пакет №210: обратный отсчёт до автоматического начала нового дня.
// -1 означает «окно закрыто, отсчёт не идёт».
global.day_summary_autoclose = -1;

// Состояние ежедневной выплаты зарплаты.
global.finance_last_payroll_day = -1;
global.finance_last_payroll_total = 0;
global.finance_last_payroll_lines = [];


// ═══════════════════════════════════════════════════════════════
// 12. ЗАГРУЗКА СОХРАНЕНИЯ (пакет №269)
//
// Загрузка НЕ вызывается прямо здесь. Причина: Create объекта
// выполняется до того, как GameMaker создал остальные объекты комнаты
// (столы, койки, точки ожидания, стартовый персонал). Если восстановить
// сотрудников сейчас, их тут же перекроют экземпляры из комнаты, а
// поиск свободных коек ничего не найдёт.
//
// Поэтому ставим будильник на 1 шаг: к моменту Alarm 1 комната
// полностью собрана, и загрузка отработает по живым объектам.
//
// Alarm 0 занят потоком клиентов — используем Alarm 1.
// ═══════════════════════════════════════════════════════════════

global.save_last_day = global.game_day;
global.save_load_pending = true;

alarm[1] = 1;


// ═══════════════════════════════════════════════════════════════
// 13. ПАКЕТ №308: ИГРА НАЧИНАЕТСЯ В МАЛЕНЬКОЙ КЛИНИКЕ
//
// Стартовая комната задаётся порядком в Room Order, а он живёт в
// файле проекта .yyp — его я не отдаю (правило: никаких .yy/.yyp).
// Поэтому переход делается кодом, здесь.
//
// Как это работает: если игра запустилась в комнате, которая НЕ
// принадлежит клинике №1, мы уходим в её комнату.
//
// ПАКЕТ №329: теперь это запасной путь. Основную работу делает
// защита в самом конце Create (раздел 14): она ловит любую комнату,
// которая не принадлежит клинике, — в том числе техническую Room1.
// Клавиша R и вход в Room1 из игры убраны.
//
// Почему именно в Create, а не в Room Start: Room Start срабатывает
// при КАЖДОМ входе в комнату, и переход оттуда зациклил бы игру —
// заход в Room1 тут же выбрасывал бы обратно. Create у obj_Render
// выполняется один раз на комнату, а флаг ниже гарантирует, что
// перенос случится ровно один раз за запуск игры.
//
// room_goto (а не room_goto_immediate) — переход произойдёт в конце
// шага, когда текущий Create спокойно доработает до конца.
// ═══════════════════════════════════════════════════════════════

if (!variable_global_exists("clinic_start_redirect_done")) {
    global.clinic_start_redirect_done = false;
}

if (!variable_global_exists("clinic_room_transition")) {
    global.clinic_room_transition = false;
}

if (!global.clinic_start_redirect_done) {
    global.clinic_start_redirect_done = true;

    var _home = clinics_get(1);

    if (
        is_struct(_home)
        && string(_home.room_name) != ""
    ) {
        var _home_room = asset_get_index(_home.room_name);

        if (
            _home_room != -1
            && room_exists(_home_room)
            && room != _home_room
        ) {
            // Сохранение подхватится уже в новой комнате: флаг
            // save_load_pending выставлен выше и переживёт переход,
            // а Alarm 1 сработает у нового obj_Render.
            show_debug_message(
                "[CLINIC START] Старт перенесён в "
                + string(_home.room_name)
            );

            // Будильник загрузки гасим: он сработал бы ЗДЕСЬ, в
            // покидаемой комнате, и сохранение применилось бы к
            // Room1 — с её девятью сотрудниками. Флаг
            // save_load_pending остаётся поднятым, поэтому загрузку
            // подхватит Alarm 1 нового obj_Render уже в клинике.
            alarm[1] = -1;

            // ═══════════════════════════════════════════════════
            // ПАКЕТ №309: НЕ СОХРАНЯТЬ ПРИ ЭТОМ ПЕРЕХОДЕ
            //
            // При смене комнаты GameMaker вызывает CleanUp у всех
            // объектов, а CleanUp у obj_Render пишет сохранение.
            // На старте это падало с ошибкой: объекты комнаты
            // создаются по очереди, obj_Render идёт раньше коек
            // стационара, и у части obj_inpatient_controller
            // событие Create ещё не выполнялось — переменной phase
            // просто нет, а save_build_wards её читает.
            //
            // Сохранять тут и не нужно: игра только что запустилась,
            // сохранять нечего. Флаг снимается в Room Start новой
            // комнаты, чтобы обычный выход из игры сохранялся как
            // раньше.
            //
            // Отдельный флаг, а не save_skip_on_exit: тот отвечает за
            // «сохранение удалили, не воссоздавай», смешивать нельзя.
            // ═══════════════════════════════════════════════════

            global.clinic_room_transition = true;

            room_goto(_home_room);
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 14. ПАКЕТ №329: ТЕХНИЧЕСКАЯ КОМНАТА В ИГРЕ НЕ УЧАСТВУЕТ
//
// Первая комната в Room Order задаётся файлом проекта .yyp, и там
// стоит Room1 — база объектов, из которой расставляются четыре
// клиники. Она НЕ игровая: в ней не должно появляться ни дня, ни
// денег, ни персонала, ни предупреждений диагностики.
//
// Поэтому в комнате, которая не принадлежит ни одной клинике,
// obj_Render делает ровно одно: уводит игру в клинику №1 и выходит,
// не запуская ничего остального.
//
// Почему защита стоит В КОНЦЕ Create, а не в начале: будильник
// загрузки сохранения (alarm[1] = 1) ставится выше. Если уйти из
// Create до него, сохранение подхватилось бы уже в клинике — но
// если бы порядок строк когда-нибудь поменялся, сейв применился бы
// к технической комнате. Здесь будильник уже стоит, и мы его
// честно гасим перед переходом.
//
// Отдельный флаг global.clinic_technical_room — для диагностики:
// столы, шкафы и койки технической комнаты молчат, ругаться там
// не на что (пакет №329).
// ═══════════════════════════════════════════════════════════════

var _room_clinic_id = script_exists(asset_get_index("clinic_room_owner"))
    ? clinic_room_owner()
    : 0;

if (_room_clinic_id <= 0) {

    global.clinic_technical_room = true;

    var _home_room_name = "rm_clinic_1";

    if (script_exists(asset_get_index("clinics_init"))) {
        clinics_init();
    }

    if (script_exists(asset_get_index("clinics_get"))) {
        var _home = clinics_get(1);

        if (is_struct(_home) && string(_home.room_name) != "") {
            _home_room_name = string(_home.room_name);
        }
    }

    var _home_room = asset_get_index(_home_room_name);

    if (_home_room != -1 && room_exists(_home_room) && room != _home_room) {

        show_debug_message(
            "[CLINIC START] Комната " + room_get_name(room)
            + " не принадлежит ни одной клинике — в игре не участвует. "
            + "Переход в клинику №1 (" + _home_room_name + ")."
        );

        // Ничего из технической комнаты в клинику не переносится.
        //
        // Уничтожать инстансы здесь НЕЛЬЗЯ: obj_player наследуется
        // от par_staff (проверено по obj_player.yy), и
        // instance_destroy(par_staff) убил бы игрока. Они и так
        // исчезнут вместе с комнатой при room_goto.
        //
        // Персонал технической комнаты в карман клиники тоже не
        // сворачивается — clinic_network_store_current здесь не
        // вызывается намеренно.
        //
        // Сохранение при выходе из этой комнаты не пишем (оно бы
        // создалось из технического состояния) и загрузку сейва не
        // применяем — подхватит уже клиника №1.
        global.clinic_room_transition = true;

        alarm[0] = -1;
        alarm[1] = -1;

        room_goto(_home_room);
    }
    else {
        show_debug_message(
            "[CLINIC START] ВНИМАНИЕ: комната клиники №1 ("
            + _home_room_name + ") не найдена в проекте. "
            + "Игра осталась в технической комнате."
        );
    }

    exit;
}

global.clinic_technical_room = false;
