/// clinic_network_system.gml
/// @description Сеть клиник: у каждой свой персонал, свой склад, своя
///              репутация, своя картотека пациентов, свои помещения и
///              свои уровни улучшений. Общее — только деньги и баллы.
///              Пакет №301, переработано в пакете №325.
///
/// ── Устройство ──
///
/// У каждой клиники есть «карман» — структура в global.clinic_state с
/// ключом по номеру клиники:
///
///   {
///       staff      : [снимки сотрудников],
///       inventory  : {склад},
///       rooms      : {построенные помещения},
///       upgrades   : {уровни улучшений},
///       reputation : число,
///       db         : {картотека: владельцы, питомцы, визиты, расписание},
///       visited    : был ли игрок внутри хоть раз
///   }
///
/// Когда игрок уезжает, состояние текущей клиники сворачивается в её
/// карман. Когда приезжает — карман той клиники разворачивается в
/// общие global, на которые смотрит остальная игра. Так остальные
/// системы (склад, регистратура, картотека, развитие) менять не
/// пришлось: они по-прежнему читают global, но видят данные той
/// клиники, в которой игрок стоит.
///
/// Формат снимка персонала НЕ придуман заново: используются
/// save_staff_snapshot и save_staff_restore из save_system. Они уже
/// умеют сохранять все навыки, зарплату, состояние и рабочее место —
/// и уже проверены на сохранениях.
///
/// ── Что остаётся общим ──
///
///   global.clinic_money   один кошелёк на всю сеть;
///   global.clinic_points  один кошелёк баллов развития (ветки при
///                         этом у каждой клиники свои).


// ═══════════════════════════════════════════════════════════════
// 1. ХРАНИЛИЩЕ КЛИНИК
// ═══════════════════════════════════════════════════════════════

/// @function clinic_state_init()
/// @description Создаёт global.clinic_state, если его ещё нет.
///              Идемпотентна: поднятое из сейва не трогает.
function clinic_state_init() {

    if (
        variable_global_exists("clinic_state")
        && is_struct(global.clinic_state)
    ) {
        return false;
    }

    global.clinic_state = {};

    return true;
}


/// @function clinic_state_get(_clinic_id)
/// @description Карман клиники. Создаёт пустой, если его ещё нет.
function clinic_state_get(_clinic_id) {

    clinic_state_init();

    var _key = "clinic_" + string(_clinic_id);

    if (!variable_struct_exists(global.clinic_state, _key)) {
        variable_struct_set(global.clinic_state, _key, {
            staff : [],
            inventory : {},
            visited : false,

            // Что построено именно в ЭТОЙ клинике (пакет №317).
            rooms : undefined,
            upgrades : undefined,

            // ПАКЕТ №325: репутация клиники. undefined — «её ещё ни
            // разу не сворачивали», тогда берётся значение из данных
            // клиники (reputation_start).
            reputation : undefined,

            // ПАКЕТ №325: картотека пациентов. У каждой клиники своя:
            // владельцы, питомцы, визиты и расписание повторных приёмов
            // не пересекаются между клиниками.
            db : undefined
        });
    }

    return variable_struct_get(global.clinic_state, _key);
}


/// @function clinic_state_reset(_clinic_id)
/// @description ПАКЕТ №325. Полностью обнуляет карман клиники.
///              Вызывается при продаже: проданная клиника не должна
///              хранить ни штат, ни склад, ни пациентов, ни репутацию.
function clinic_state_reset(_clinic_id) {

    clinic_state_init();

    var _key = "clinic_" + string(_clinic_id);

    variable_struct_set(global.clinic_state, _key, {
        staff : [],
        inventory : {},
        visited : false,
        rooms : undefined,
        upgrades : undefined,
        reputation : undefined,
        db : undefined
    });

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 2. КАКАЯ КЛИНИКА ОТКРЫТА ПРЯМО СЕЙЧАС
//
// global.active_clinic задаётся при переезде, но при ЗАПУСКЕ игры он
// просто равен 1 — независимо от того, в какой комнате игра стартовала.
// Функции ниже сверяют реальную комнату со списком клиник и возвращают
// честный номер. Если комната ничьей клинике не принадлежит,
// возвращается 0 — «мы не в клинике».
// ═══════════════════════════════════════════════════════════════

/// @function clinic_room_owner()
/// @description Номер клиники, чья комната открыта сейчас, или 0.
function clinic_room_owner() {

    if (!variable_global_exists("clinics") || !is_array(global.clinics)) {
        return 0;
    }

    for (var _index = 0; _index < array_length(global.clinics); _index++) {
        var _clinic = global.clinics[_index];

        if (!is_struct(_clinic)) continue;

        var _name = string(_clinic.room_name);

        if (_name == "") continue;

        var _room_index = asset_get_index(_name);

        if (_room_index == -1) continue;

        if (room == _room_index) return _clinic.id;
    }

    return 0;
}


/// @function clinic_current_id()
/// @description Номер клиники, к которой относится всё, что сейчас в
///              global. Сначала смотрим на комнату — она источник
///              правды, — и только потом на active_clinic.
function clinic_current_id() {

    var _owner = clinic_room_owner();

    if (_owner > 0) return _owner;

    return variable_global_exists("active_clinic")
        ? global.active_clinic
        : 0;
}


/// @function clinic_current()
/// @description Структура текущей клиники или undefined.
function clinic_current() {

    if (script_exists(asset_get_index("clinics_init"))) {
        clinics_init();
    }

    return clinics_get(clinic_current_id());
}


/// @function clinic_value(_clinic_id, _field, _default)
/// @description Одно поле клиники по номеру. Безопасная: если клиники
///              нет или поля в ней нет (старое сохранение), возвращает
///              значение по умолчанию, а не падает.
function clinic_value(_clinic_id, _field, _default) {

    if (script_exists(asset_get_index("clinics_init"))) {
        clinics_init();
    }

    var _clinic = clinics_get(_clinic_id);

    if (!is_struct(_clinic)) return _default;

    var _key = string(_field);

    if (!variable_struct_exists(_clinic, _key)) return _default;

    var _value = variable_struct_get(_clinic, _key);

    if (is_undefined(_value)) return _default;

    return _value;
}


/// @function clinic_value_here(_field, _default)
/// @description То же самое, но для клиники, в которой игрок стоит.
function clinic_value_here(_field, _default) {

    return clinic_value(clinic_current_id(), _field, _default);
}


/// @function clinic_sync_active()
/// @description Приводит global.active_clinic в соответствие с
///              открытой комнатой. Вызывается из Room Start.
function clinic_sync_active() {

    var _owner = clinic_room_owner();

    if (_owner > 0) {
        global.active_clinic = _owner;
    }

    return _owner;
}


// ═══════════════════════════════════════════════════════════════
// 3. ПОТОЛКИ РАЗВИТИЯ КЛИНИКИ
//
// Всё развитие клиники упирается в эти числа. Панель РАЗВИТИЕ строит
// ветки отсюда же (clinic_tree_panel), поэтому лишнего пункта в ней
// появиться не может: чего нет в данных клиники, того нет и в панели.
// ═══════════════════════════════════════════════════════════════

/// @function clinic_exam_room_limit()
/// @description Сколько кабинетов приёма может быть в текущей клинике.
function clinic_exam_room_limit() {
    return max(1, round(clinic_value_here("exam_max", 1)));
}


/// @function clinic_bed_limit()
/// @description Сколько коек стационара может быть. 0 — стационара
///              в этой клинике нет вообще.
function clinic_bed_limit() {
    return max(0, round(clinic_value_here("bed_max", 0)));
}


/// @function clinic_has_operating_room()
/// @description Предусмотрена ли в этой клинике операционная.
function clinic_has_operating_room() {
    return clinic_value_here("has_operating", false) ? true : false;
}


/// @function clinic_storage_size()
/// @description Размер склада: 0 малый, 1 средний, 2 большой.
function clinic_storage_size() {
    return clamp(round(clinic_value_here("storage_size", 0)), 0, 2);
}


/// @function clinic_hire_max()
/// @description Потолок сотрудников, которых можно нанять в этой
///              клинике. Слот найма в панели развития доходит ровно
///              до этого числа и дальше не растёт.
function clinic_hire_max() {
    return max(1, round(clinic_value_here("hire_max", 1)));
}


/// @function clinic_hire_max_level()
/// @description Сколько уровней у ветки «Слот найма»: потолок штата
///              минус один стартовый сотрудник.
function clinic_hire_max_level() {
    return max(0, clinic_hire_max() - 1);
}


/// @function clinic_start_reputation(_clinic_id)
/// @description Репутация, с которой клиника начинает (или начинает
///              заново после продажи).
function clinic_start_reputation(_clinic_id) {
    return max(0, round(clinic_value(_clinic_id, "reputation_start", 0)));
}


// ═══════════════════════════════════════════════════════════════
// 4. РЕПУТАЦИЯ КЛИНИКИ
//
// global.clinic_reputation остаётся единственной точкой, куда смотрит
// вся игра (потолок навыков кандидатов, HUD, дневной отчёт). Но это
// больше не «репутация сети»: в любой момент там лежит репутация той
// клиники, в которой игрок стоит, а значения всех клиник живут в их
// карманах и подменяются при переезде.
// ═══════════════════════════════════════════════════════════════

/// @function clinic_reputation_read(_clinic_id)
/// @description Репутация конкретной клиники из её кармана.
function clinic_reputation_read(_clinic_id) {

    var _state = clinic_state_get(_clinic_id);

    if (is_real(_state.reputation)) {
        return _state.reputation;
    }

    // Карман ещё не наполнялся — берём стартовое значение из данных
    // клиники и сразу записываем, чтобы дальше оно жило в кармане.
    var _start = clinic_start_reputation(_clinic_id);

    _state.reputation = _start;

    return _start;
}


/// @function clinic_reputation_current()
/// @description Репутация клиники, в которой игрок стоит.
function clinic_reputation_current() {
    return clinic_reputation_read(clinic_current_id());
}


// ═══════════════════════════════════════════════════════════════
// 5. КАРТОТЕКА ПАЦИЕНТОВ КЛИНИКИ
//
// У каждой клиники своя база: владельцы, питомцы, история визитов и
// расписание повторных приёмов. При переезде база сворачивается в
// карман прежней клиники и разворачивается база новой.
//
// Зачем целиком, а не фильтром по clinic_id: записи kartотеки
// пронизывают десятки мест (карточки, оплата, повторные визиты,
// статистика). Менять их все — значит менять всё. А подмена global —
// одна точка, и остальной код даже не знает, что клиники разные.
// ═══════════════════════════════════════════════════════════════

/// @function clinic_db_collect()
/// @description Снимок картотеки из текущих global.
function clinic_db_collect() {

    var _deep = asset_get_index("save_deep_copy");
    var _has_deep = (_deep != -1 && script_exists(_deep));

    if (_has_deep) {
        return {
            owner_db : save_deep_copy(
                variable_global_exists("owner_db") ? global.owner_db : {}, 0
            ),
            pet_db : save_deep_copy(
                variable_global_exists("pet_db") ? global.pet_db : {}, 0
            ),
            visit_db : save_deep_copy(
                variable_global_exists("visit_db") ? global.visit_db : {}, 0
            ),
            owner_list : save_deep_copy(
                variable_global_exists("owner_list") ? global.owner_list : [], 0
            ),
            pet_list : save_deep_copy(
                variable_global_exists("pet_list") ? global.pet_list : [], 0
            ),
            visit_list : save_deep_copy(
                variable_global_exists("visit_list") ? global.visit_list : [], 0
            ),
            owner_uid : variable_global_exists("owner_uid") ? global.owner_uid : 0,
            pet_uid : variable_global_exists("pet_uid") ? global.pet_uid : 0,
            visit_uid : variable_global_exists("visit_uid") ? global.visit_uid : 0,
            scheduled_visits : save_deep_copy(
                variable_global_exists("scheduled_visits")
                    ? global.scheduled_visits
                    : [], 0
            ),
            scheduled_visit_uid : variable_global_exists("scheduled_visit_uid")
                ? global.scheduled_visit_uid
                : 0,
            daily_random_visits : save_deep_copy(
                variable_global_exists("daily_random_visits")
                    ? global.daily_random_visits
                    : [], 0
            ),
            daily_random_visit_uid : variable_global_exists("daily_random_visit_uid")
                ? global.daily_random_visit_uid
                : 0,
            daily_random_spawned_today : variable_global_exists("daily_random_spawned_today")
                ? global.daily_random_spawned_today
                : 0
        };
    }

    // save_system не создан в проекте — работаем поверхностными
    // копиями. Хуже, но не падает.
    return {
        owner_db : variable_global_exists("owner_db") ? global.owner_db : {},
        pet_db : variable_global_exists("pet_db") ? global.pet_db : {},
        visit_db : variable_global_exists("visit_db") ? global.visit_db : {},
        owner_list : variable_global_exists("owner_list") ? global.owner_list : [],
        pet_list : variable_global_exists("pet_list") ? global.pet_list : [],
        visit_list : variable_global_exists("visit_list") ? global.visit_list : [],
        owner_uid : variable_global_exists("owner_uid") ? global.owner_uid : 0,
        pet_uid : variable_global_exists("pet_uid") ? global.pet_uid : 0,
        visit_uid : variable_global_exists("visit_uid") ? global.visit_uid : 0,
        scheduled_visits : variable_global_exists("scheduled_visits")
            ? global.scheduled_visits
            : [],
        scheduled_visit_uid : variable_global_exists("scheduled_visit_uid")
            ? global.scheduled_visit_uid
            : 0,
        daily_random_visits : [],
        daily_random_visit_uid : 0,
        daily_random_spawned_today : 0
    };
}


/// @function clinic_db_restore(_db)
/// @description Разворачивает картотеку в global.
function clinic_db_restore(_db) {

    if (!is_struct(_db)) {
        db_clients_init();
        return false;
    }

    var _deep = asset_get_index("save_deep_copy");
    var _has_deep = (_deep != -1 && script_exists(_deep));

    if (_has_deep) {
        global.owner_db = save_deep_copy(
            variable_struct_exists(_db, "owner_db") ? _db.owner_db : {}, 0
        );
        global.pet_db = save_deep_copy(
            variable_struct_exists(_db, "pet_db") ? _db.pet_db : {}, 0
        );
        global.visit_db = save_deep_copy(
            variable_struct_exists(_db, "visit_db") ? _db.visit_db : {}, 0
        );
        global.owner_list = save_deep_copy(
            variable_struct_exists(_db, "owner_list") ? _db.owner_list : [], 0
        );
        global.pet_list = save_deep_copy(
            variable_struct_exists(_db, "pet_list") ? _db.pet_list : [], 0
        );
        global.visit_list = save_deep_copy(
            variable_struct_exists(_db, "visit_list") ? _db.visit_list : [], 0
        );
        global.scheduled_visits = save_deep_copy(
            variable_struct_exists(_db, "scheduled_visits")
                ? _db.scheduled_visits
                : [], 0
        );
    }
    else {
        global.owner_db = variable_struct_exists(_db, "owner_db") ? _db.owner_db : {};
        global.pet_db = variable_struct_exists(_db, "pet_db") ? _db.pet_db : {};
        global.visit_db = variable_struct_exists(_db, "visit_db") ? _db.visit_db : {};
        global.owner_list = variable_struct_exists(_db, "owner_list") ? _db.owner_list : [];
        global.pet_list = variable_struct_exists(_db, "pet_list") ? _db.pet_list : [];
        global.visit_list = variable_struct_exists(_db, "visit_list") ? _db.visit_list : [];
        global.scheduled_visits = variable_struct_exists(_db, "scheduled_visits")
            ? _db.scheduled_visits
            : [];
    }

    global.owner_uid = variable_struct_exists(_db, "owner_uid") ? _db.owner_uid : 0;
    global.pet_uid = variable_struct_exists(_db, "pet_uid") ? _db.pet_uid : 0;
    global.visit_uid = variable_struct_exists(_db, "visit_uid") ? _db.visit_uid : 0;

    global.scheduled_visit_uid = variable_struct_exists(_db, "scheduled_visit_uid")
        ? _db.scheduled_visit_uid
        : 0;

    global.daily_random_visits = variable_struct_exists(_db, "daily_random_visits")
        && is_array(_db.daily_random_visits)
        ? _db.daily_random_visits
        : [];

    global.daily_random_visit_uid = variable_struct_exists(_db, "daily_random_visit_uid")
        ? _db.daily_random_visit_uid
        : 0;

    global.daily_random_spawned_today = variable_struct_exists(_db, "daily_random_spawned_today")
        ? _db.daily_random_spawned_today
        : 0;

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 6. ПРИМЕНИТЬ / ЗАБРАТЬ СОСТОЯНИЕ КЛИНИКИ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_apply_current()
/// @description Кладёт в общие global состояние ТОЙ клиники, в которой
///              игрок стоит: репутацию, построенные помещения, уровни
///              улучшений. Вызывается из Room Start после определения
///              клиники и после загрузки сохранения.
///
///              Картотеку пациентов здесь не трогаем: её разворачивает
///              clinic_network_restore (при переезде) или загрузка
///              сохранения (при старте).
function clinic_apply_current() {

    var _clinic_id = clinic_current_id();

    if (_clinic_id <= 0) return 0;

    var _state = clinic_state_get(_clinic_id);
    var _clinic = clinics_get(_clinic_id);

    // ── Репутация ──
    if (!is_real(_state.reputation)) {
        _state.reputation = is_struct(_clinic)
            ? clinic_start_reputation(_clinic_id)
            : 0;
    }

    global.clinic_reputation = _state.reputation;

    // ── Построенные помещения ──
    //
    // Пустой карман означает «клинику ещё ни разу не сворачивали».
    // Тогда берём стартовый набор: один кабинет приёма, без коек и без
    // операционной. Подменять на {} нельзя — у клиники пропали бы все
    // покупки, сделанные до первого выезда.
    if (!is_struct(_state.rooms)) {
        _state.rooms = {};

        if (script_exists(asset_get_index("clinic_rooms_reset_default"))) {
            clinic_rooms_reset_default();

            _state.rooms = save_copy_struct(global.clinic_rooms_open);
        }
    }

    global.clinic_rooms_open = save_copy_struct(_state.rooms);

    // ── Уровни улучшений ──
    if (!is_struct(_state.upgrades)) {
        _state.upgrades = {};
    }

    global.clinic_upgrades = save_copy_struct(_state.upgrades);

    if (script_exists(asset_get_index("clinic_upgrade_init"))) {
        clinic_upgrade_init();
    }

    // ── Дневной отчёт: репутация считается от текущей клиники ──
    //
    // День у сети общий, а репутация своя. Если этого не сделать, в
    // вечернем отчёте дельта считалась бы от репутации той клиники,
    // где день начался.
    if (
        variable_global_exists("daily_stats")
        && is_struct(global.daily_stats)
    ) {
        global.daily_stats.reputation_start = global.clinic_reputation;
    }

    show_debug_message(
        "[CLINIC NET] Клиника " + string(_clinic_id)
        + " применена: репутация " + string(global.clinic_reputation)
    );

    return _clinic_id;
}


/// @function clinic_adopt_globals()
/// @description ПАКЕТ №325. Забирает то, что сейчас лежит в global, в
///              карман текущей клиники.
///
///              Нужна после загрузки сохранения: сейв кладёт данные в
///              общие global, а правда теперь живёт в кармане клиники.
///              Без этого вызова первый же переезд перезаписал бы
///              карман клиники №1 тем, что было в сейве другой клиники.
function clinic_adopt_globals() {

    var _clinic_id = clinic_current_id();

    if (_clinic_id <= 0) return 0;

    var _state = clinic_state_get(_clinic_id);

    if (variable_global_exists("clinic_reputation")) {
        _state.reputation = global.clinic_reputation;
    }

    _state.rooms = save_copy_struct(
        variable_global_exists("clinic_rooms_open")
            ? global.clinic_rooms_open
            : {}
    );

    _state.upgrades = save_copy_struct(
        variable_global_exists("clinic_upgrades")
            ? global.clinic_upgrades
            : {}
    );

    _state.inventory = save_copy_struct(
        variable_global_exists("inventory_main")
            ? global.inventory_main
            : {}
    );

    _state.db = clinic_db_collect();
    _state.visited = true;

    show_debug_message(
        "[CLINIC NET] Клиника " + string(_clinic_id)
        + " забрала состояние из общих переменных"
    );

    return _clinic_id;
}


// ═══════════════════════════════════════════════════════════════
// 7. СВЕРНУТЬ ТЕКУЩУЮ КЛИНИКУ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_network_store_current()
/// @description Складывает персонал, склад, помещения, улучшения,
///              репутацию и картотеку текущей клиники в её карман.
///              Вызывается перед выездом.
function clinic_network_store_current() {

    // Сохраняем в карман ТОЙ клиники, чья комната открыта, а не в ту,
    // что записана в active_clinic. Если комната ничьей клинике не
    // принадлежит, сохранять нечего и некуда.
    var _clinic_id = clinic_room_owner();

    if (_clinic_id <= 0) {
        show_debug_message(
            "[CLINIC NET] Комната не принадлежит клинике — не сохраняем"
        );

        return false;
    }

    var _state = clinic_state_get(_clinic_id);

    // ── Персонал ──
    //
    // Игрок и кандидаты не сохраняются: игрок едет с нами, а кандидат —
    // случайный прохожий, он не принадлежит клинике.
    var _staff_snapshots = [];
    var _count = instance_number(par_staff);

    for (var _index = 0; _index < _count; _index++) {
        var _staff = instance_find(par_staff, _index);

        if (!instance_exists(_staff)) continue;
        if (_staff.object_index == obj_player) continue;
        if (_staff.object_index == obj_staff_candidate) continue;

        var _snapshot = save_staff_snapshot(_staff);

        if (is_struct(_snapshot)) {
            array_push(_staff_snapshots, _snapshot);
        }
    }

    _state.staff = _staff_snapshots;

    // ── Склад ──
    //
    // save_copy_struct, а не прямое присваивание: структура иначе
    // осталась бы общей ссылкой, и склад новой клиники менял бы
    // содержимое старой.
    _state.inventory = save_copy_struct(
        variable_global_exists("inventory_main")
            ? global.inventory_main
            : {}
    );

    // ── Построенные помещения и апгрейды ──
    _state.rooms = save_copy_struct(
        variable_global_exists("clinic_rooms_open")
            ? global.clinic_rooms_open
            : {}
    );

    _state.upgrades = save_copy_struct(
        variable_global_exists("clinic_upgrades")
            ? global.clinic_upgrades
            : {}
    );

    // ── ПАКЕТ №325: репутация и картотека ──
    _state.reputation = variable_global_exists("clinic_reputation")
        ? global.clinic_reputation
        : clinic_start_reputation(_clinic_id);

    _state.db = clinic_db_collect();

    _state.visited = true;

    show_debug_message(
        "[CLINIC NET] Клиника " + string(_clinic_id)
        + " свёрнута: сотрудников " + string(array_length(_staff_snapshots))
    );

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 8. РАЗВЕРНУТЬ КЛИНИКУ, В КОТОРУЮ ПРИЕХАЛИ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_network_restore(_clinic_id)
/// @description Достаёт персонал, склад, помещения, репутацию и
///              картотеку клиники из её кармана. Вызывается из Room
///              Start после сборки обстановки.
function clinic_network_restore(_clinic_id) {

    var _state = clinic_state_get(_clinic_id);
    var _first_visit = (!_state.visited && array_length(_state.staff) <= 0);

    // ── Склад ──
    //
    // Первый визит: склад пустой, наполнять его — задача обычной
    // закупки. Не копируем сюда чужой инвентарь.
    global.inventory_main = save_copy_struct(_state.inventory);

    // ── Репутация, помещения, улучшения ──
    //
    // До первого сворачивания карман пуст, и подставлять пустышку
    // нельзя: у клиники пропали бы её покупки. clinic_apply_current
    // сам разбирается, что считать стартовым состоянием.
    clinic_apply_current();

    // ── Картотека пациентов ──
    if (_first_visit) {
        // Клиника только что куплена: пациентов у неё нет, и чужих ей
        // отдавать нельзя — это была бы картотека предыдущей клиники.
        db_clients_init();
        _state.db = clinic_db_collect();

        show_debug_message(
            "[CLINIC NET] Клиника " + string(_clinic_id)
            + ": первый визит, картотека пустая"
        );
    }
    else {
        clinic_db_restore(_state.db);
    }

    // ── ПЕРВЫЙ ВИЗИТ: ПРИНИМАЕМ ПЕРСОНАЛ ИЗ РЕДАКТОРА ──
    //
    // Если игрок в этой клинике ещё ни разу не был, её карман пуст, а в
    // комнате может стоять персонал, расставленный в редакторе. Без
    // этой ветки первый же вход стёр бы его: код ниже удаляет всех из
    // комнаты и разворачивает пустой карман.
    if (_first_visit) {
        _state.visited = true;

        show_debug_message(
            "[CLINIC NET] Клиника " + string(_clinic_id)
            + ": первый визит, персонал взят из комнаты"
        );

        return true;
    }

    // ── Персонал ──
    //
    // Сначала убираем тех, кто мог остаться в комнате. Иначе штат
    // удвоился бы — ровно та ошибка, о которой предупреждает
    // комментарий в save_system → Alarm 1.
    var _existing = [];
    var _count = instance_number(par_staff);

    for (var _index = 0; _index < _count; _index++) {
        var _staff = instance_find(par_staff, _index);

        if (!instance_exists(_staff)) continue;
        if (_staff.object_index == obj_player) continue;

        array_push(_existing, _staff);
    }

    for (var _index = 0; _index < array_length(_existing); _index++) {
        instance_destroy(_existing[_index]);
    }

    // Разворачиваем снимки обратно в живых сотрудников.
    for (var _index = 0; _index < array_length(_state.staff); _index++) {
        save_staff_restore(_state.staff[_index]);
    }

    show_debug_message(
        "[CLINIC NET] Клиника " + string(_clinic_id)
        + " развёрнута: сотрудников " + string(array_length(_state.staff))
    );

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 9. ПЕРЕЕЗД
// ═══════════════════════════════════════════════════════════════

/// @function clinics_can_enter(_clinic_id)
/// @description Проверка перед переездом. Возвращает { ok, reason }.
function clinics_can_enter(_clinic_id) {

    var _clinic = clinics_get(_clinic_id);

    if (!is_struct(_clinic)) {
        return { ok : false, reason : "Клиника не найдена." };
    }

    if (!_clinic.owned) {
        return { ok : false, reason : "Клиника ещё не куплена." };
    }

    // Комната клиники должна существовать в проекте.
    var _room_name = string(_clinic.room_name);

    if (_room_name == "") {
        return {
            ok : false,
            reason : "Помещение этой клиники ещё не построено."
        };
    }

    var _room_index = asset_get_index(_room_name);

    if (_room_index == -1 || !room_exists(_room_index)) {
        return {
            ok : false,
            reason : "Комната " + _room_name + " не найдена в проекте."
        };
    }

    // Вот теперь честно: игрок физически в этой комнате.
    if (room == _room_index) {
        return { ok : false, reason : "Вы уже здесь." };
    }

    return { ok : true, reason : "" };
}


/// @function clinics_enter(_clinic_id)
/// @description Переезд в другую клинику. Возвращает true при успехе.
function clinics_enter(_clinic_id) {

    var _check = clinics_can_enter(_clinic_id);

    if (!_check.ok) {
        show_debug_message("[CLINIC NET] Переезд отклонён: " + _check.reason);
        return false;
    }

    var _clinic = clinics_get(_clinic_id);

    // ── Сворачиваем ту клинику, из которой уезжаем ──
    clinic_network_store_current();

    global.active_clinic = _clinic_id;

    // Разворачивать будем уже в новой комнате: сейчас объектов новой
    // клиники ещё не существует. Флаг подхватит Room Start.
    global.clinic_restore_pending = true;

    // При смене комнаты GameMaker вызывает CleanUp, а он пишет
    // сохранение — и падает, если объекты новой комнаты ещё не прошли
    // Create. Персонал и склад уже свёрнуты в карман выше, терять
    // нечего. Флаг снимается в Room Start.
    global.clinic_room_transition = true;

    room_goto(asset_get_index(_clinic.room_name));

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 10. ДОХОД КЛИНИК БЕЗ ИГРОКА
// ═══════════════════════════════════════════════════════════════

/// @function clinic_network_daily_income()
/// @description Начисляет доход купленных клиник, где игрока нет.
///              Вызывается раз в игровой день.
///
/// Клиника «на бумаге»: приёмы там не разыгрываются, но она приносит
/// income_per_day из данных клиники. Клиника, в которой игрок сейчас
/// работает руками, доход по этой статье НЕ получает — иначе он шёл бы
/// дважды, поверх реальной выручки с приёмов.
function clinic_network_daily_income() {

    if (!variable_global_exists("clinics") || !is_array(global.clinics)) {
        return 0;
    }

    var _active = clinic_current_id();

    var _total = 0;

    for (var _index = 0; _index < array_length(global.clinics); _index++) {
        var _clinic = global.clinics[_index];

        if (!is_struct(_clinic)) continue;
        if (!_clinic.owned) continue;
        if (_clinic.id == _active) continue;

        var _income = variable_struct_exists(_clinic, "income_per_day")
            ? _clinic.income_per_day
            : 0;

        // Без сотрудников клиника не работает: у пустой доход нулевой.
        // Так купленная клиника не превращается в бесплатный станок —
        // туда сначала нужно съездить и нанять людей.
        var _state = clinic_state_get(_clinic.id);
        var _staff_count = array_length(_state.staff);

        if (_staff_count <= 0) continue;

        // Полный доход — при штате в три человека: врач, ассистент,
        // администратор.
        var _ratio = min(1, _staff_count / 3);

        _total += floor(_income * _ratio);
    }

    if (_total > 0 && variable_global_exists("clinic_money")) {
        global.clinic_money += _total;

        show_debug_message(
            "[CLINIC NET] Доход прочих клиник за день: " + string(_total)
        );
    }

    return _total;
}
