/// clinic_network_system.gml
/// @description Сеть клиник: свой персонал и склад у каждой, переход
///              между ними, работа купленных клиник «на бумаге».
///              Пакет №301.
///
/// ── Устройство ──
///
/// У каждой клиники есть «карман» — структура в global.clinic_state с
/// ключом по номеру клиники:
///
///   {
///       staff      : [снимки сотрудников],
///       inventory  : {склад},
///       visited    : был ли игрок внутри хоть раз
///   }
///
/// Когда игрок уезжает, персонал текущей клиники сворачивается в
/// снимки и кладётся в карман. Когда приезжает — снимки той клиники
/// разворачиваются обратно в живые объекты.
///
/// Формат снимка НЕ придуман заново: используются save_staff_snapshot и
/// save_staff_restore из save_system. Они уже умеют сохранять все
/// навыки, зарплату, состояние и рабочее место — и уже проверены на
/// сохранениях. Дублировать эту логику было бы ошибкой.


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
            visited : false
        });
    }

    return variable_struct_get(global.clinic_state, _key);
}


// ═══════════════════════════════════════════════════════════════
// 1.5 КАКАЯ КЛИНИКА ОТКРЫТА ПРЯМО СЕЙЧАС
//
// ПАКЕТ №306. global.active_clinic задаётся при переезде, но при
// ЗАПУСКЕ игры он просто равен 1 — независимо от того, в какой
// комнате игра стартовала.
//
// Из-за этого ломался весь учёт персонала. Игра запускалась в Room1
// (тестовой), там девять сотрудников из редактора, а active_clinic
// говорил «это клиника №1». При первом же переезде в маленькую
// клинику эти девять сохранялись в карман клиники №1 и появлялись
// там как её штат.
//
// Функция ниже сверяет реальную комнату со списком клиник и
// возвращает честный номер. Если комната ничьей клинике не
// принадлежит, возвращается 0 — «мы не в клинике».
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
// 2. СВЕРНУТЬ ТЕКУЩУЮ КЛИНИКУ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_network_store_current()
/// @description Складывает персонал и склад текущей клиники в её карман.
///              Вызывается перед выездом.
function clinic_network_store_current() {

    // ПАКЕТ №306: сохраняем в карман ТОЙ клиники, чья комната открыта,
    // а не в ту, что записана в active_clinic. Если комната ничьей
    // клинике не принадлежит, сохранять нечего и некуда.
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
    // случайный прохожий, он не принадлежит клинике. Тот же отбор, что
    // в save_system при сборке сохранения.
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

    _state.visited = true;

    show_debug_message(
        "[CLINIC NET] Клиника " + string(_clinic_id)
        + " свёрнута: сотрудников " + string(array_length(_staff_snapshots))
    );

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. РАЗВЕРНУТЬ КЛИНИКУ, В КОТОРУЮ ПРИЕХАЛИ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_network_restore(_clinic_id)
/// @description Достаёт персонал и склад клиники из её кармана.
///              Вызывается из Room Start после сборки обстановки.
function clinic_network_restore(_clinic_id) {

    var _state = clinic_state_get(_clinic_id);

    // ── Склад ──
    //
    // Первый визит: склад пустой, наполнять его — задача обычной
    // закупки. Не копируем сюда чужой инвентарь.
    global.inventory_main = save_copy_struct(_state.inventory);

    // ── ПЕРВЫЙ ВИЗИТ: ПРИНИМАЕМ ПЕРСОНАЛ ИЗ РЕДАКТОРА ──
    //
    // ПАКЕТ №304. Если игрок в этой клинике ещё ни разу не был, её
    // карман пуст, а в комнате может стоять персонал, расставленный
    // в редакторе. Такой случай появился, когда клиникой №4 временно
    // назначили room1 — там девять готовых сотрудников.
    //
    // Без этой ветки первый же вход стёр бы их: код ниже удаляет всех
    // из комнаты и разворачивает пустой карман. Клиника оказалась бы
    // без единого работника.
    //
    // Поэтому: пустой карман + непосещённая клиника = принимаем то,
    // что стоит в комнате, как стартовый штат и уходим. Со второго
    // визита работает обычная логика с карманом.
    if (!_state.visited && array_length(_state.staff) <= 0) {
        _state.visited = true;

        show_debug_message(
            "[CLINIC NET] Клиника " + string(_clinic_id)
            + ": первый визит, персонал взят из комнаты"
        );

        return true;
    }

    // ── Персонал ──
    //
    // Сначала убираем тех, кто мог остаться в комнате: стартовые
    // сотрудники, расставленные в редакторе, и всё, что не успело
    // очиститься. Иначе штат удвоился бы — ровно та ошибка, о которой
    // предупреждает комментарий в save_system → Alarm 1.
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
// 4. ПЕРЕЕЗД
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

    // ПАКЕТ №303: «уже здесь» проверяется по РЕАЛЬНОЙ комнате.
    //
    // Раньше сравнивался active_clinic. Но это «чья клиника ваша», а
    // не «где вы стоите»: у клиники №1 он равен 1 всегда, в том числе
    // когда игрок ушёл на тестовый полигон room1. Вернуться в
    // собственную клинику было невозможно — переход отклонялся с
    // «Вы уже здесь».
    //
    // Сама проверка ниже, после того как найдена комната клиники.

    // Комната клиники должна существовать в проекте. У клиник 2-6 поле
    // room_name пока пустое — до того, как их соберут в IDE, переезд
    // туда невозможен, и честнее сказать об этом прямо.
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
    //
    // ПАКЕТ №306: проверка «а из клиники ли мы уезжаем» переехала
    // внутрь clinic_network_store_current — она сама определяет
    // клинику по открытой комнате и молча выходит, если комната
    // ничья. Здесь достаточно простого вызова.
    clinic_network_store_current();

    global.active_clinic = _clinic_id;

    // Разворачивать будем уже в новой комнате: сейчас объектов новой
    // клиники ещё не существует. Флаг подхватит Room Start.
    global.clinic_restore_pending = true;

    // ПАКЕТ №309: при смене комнаты GameMaker вызывает CleanUp, а он
    // пишет сохранение — и падает, если объекты новой комнаты ещё не
    // прошли Create. Персонал и склад уже свёрнуты в карман выше,
    // терять нечего. Флаг снимается в Room Start.
    global.clinic_room_transition = true;

    room_goto(asset_get_index(_clinic.room_name));

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 5. ДОХОД КЛИНИК БЕЗ ИГРОКА
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

    var _active = variable_global_exists("active_clinic")
        ? global.active_clinic
        : 1;

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

        // Полный доход — при полном штате. Полным считаем троих:
        // врач, ассистент, администратор.
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
