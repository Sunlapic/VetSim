/// save_slots.gml
/// @description Пакет №271: слоты сохранений для меню игры.
///
/// ═══════════════════════════════════════════════════════════════
/// ЗАЧЕМ
///
/// Пакет 269 умел одно сохранение в файл vetsim_save.json. Игрок мог
/// только ждать конца дня — вручную сохраниться было нельзя.
///
/// Здесь появляются слоты:
///   5 РУЧНЫХ      vetsim_save_1.json .. vetsim_save_5.json
///   3 АВТО        vetsim_auto_1.json .. vetsim_auto_3.json (по кругу)
///
/// Автосейвы пишутся по кольцу: самый старый затирается. Ручные слоты
/// игрок выбирает сам и подтверждает перезапись.
///
/// ═══════════════════════════════════════════════════════════════
/// ПОЧЕМУ НЕТ ИНДЕКСНОГО ФАЙЛА
///
/// Соблазн держать отдельный «список сохранений» велик, но это второй
/// источник правды: стоит игре упасть между записью сейва и записью
/// индекса — и список врёт.
///
/// Вместо этого шапка читается из самих файлов. Сейв весит пару
/// килобайт, восемь штук читаются мгновенно, и список всегда честный.
/// ═══════════════════════════════════════════════════════════════


#macro SAVE_SLOT_MANUAL_COUNT 5
#macro SAVE_SLOT_AUTO_COUNT   3


// ═══════════════════════════════════════════════════════════════
// 1. ИМЕНА ФАЙЛОВ
// ═══════════════════════════════════════════════════════════════

/// Имя файла ручного слота: 1..SAVE_SLOT_MANUAL_COUNT
function save_slot_manual_file(_index) {
    return "vetsim_save_" + string(_index) + ".json";
}


/// Имя файла автосейва: 1..SAVE_SLOT_AUTO_COUNT
function save_slot_auto_file(_index) {
    return "vetsim_auto_" + string(_index) + ".json";
}


/// Имя файла по типу слота.
function save_slot_file(_is_auto, _index) {
    return _is_auto
        ? save_slot_auto_file(_index)
        : save_slot_manual_file(_index);
}


// ═══════════════════════════════════════════════════════════════
// 2. ЗАПИСЬ И ЧТЕНИЕ ПРОИЗВОЛЬНОГО ФАЙЛА
//
// Повторяют vetsim_save/vetsim_save_read из пакета 269, но с именем
// файла параметром. Логика та же: буфер, а не file_text_*.
// ═══════════════════════════════════════════════════════════════

/// Пишет текущее состояние игры в указанный файл.
function save_slot_write(_filename) {
    var _data = save_build_data();

    // Метка времени реального мира — чтобы игрок отличал два сейва,
    // сделанных в один игровой день.
    _data.saved_real_time = string(current_year) + "-"
        + string(current_month) + "-" + string(current_day)
        + " " + string(current_hour) + ":"
        + (current_minute < 10 ? "0" : "") + string(current_minute);

    var _json = json_stringify(_data);

    var _size = string_byte_length(_json) + 1;
    var _buffer = buffer_create(_size, buffer_fixed, 1);

    buffer_write(_buffer, buffer_string, _json);
    buffer_save(_buffer, _filename);
    buffer_delete(_buffer);

    show_debug_message(
        "[SLOT] Записан " + _filename
        + ": день " + string(save_field(_data, "game_day", 1))
        + ", $" + string(save_field(_data, "clinic_money", 0))
    );

    return true;
}


/// Читает файл слота. Возвращает структуру или undefined.
function save_slot_read(_filename) {
    if (!file_exists(_filename)) return undefined;

    var _buffer = buffer_load(_filename);

    if (_buffer < 0) return undefined;

    var _json = "";

    try {
        _json = buffer_read(_buffer, buffer_string);
    }
    catch (_read_error) {
        _json = "";
    }

    buffer_delete(_buffer);

    if (_json == "") return undefined;

    try {
        var _data = json_parse(_json);

        if (!is_struct(_data)) return undefined;

        if (save_field(_data, "version", 0) != SAVE_FORMAT_VERSION) {
            return undefined;
        }

        return _data;
    }
    catch (_error) {
        show_debug_message("[SLOT] Файл повреждён: " + _filename);
        return undefined;
    }
}


// ═══════════════════════════════════════════════════════════════
// 3. ШАПКА СЛОТА ДЛЯ СПИСКА В МЕНЮ
// ═══════════════════════════════════════════════════════════════

/// Краткие сведения о слоте, без разворачивания всего сейва.
///
/// Возвращает структуру:
///   exists     — есть ли сохранение
///   day        — игровой день
///   money      — деньги
///   staff      — сколько сотрудников
///   time_text  — "14:35" игровое время
///   real_text  — когда сохранено в реальном мире
///   label      — готовая строка для списка
function save_slot_info(_is_auto, _index) {
    var _file = save_slot_file(_is_auto, _index);

    var _info = {
        is_auto : _is_auto,
        index : _index,
        file : _file,
        exists : false,
        day : 0,
        money : 0,
        staff : 0,
        time_text : "",
        real_text : "",
        label : _is_auto
            ? ("Авто " + string(_index) + " — пусто")
            : (string(_index) + ". — пусто —")
    };

    var _data = save_slot_read(_file);

    if (!is_struct(_data)) return _info;

    _info.exists = true;
    _info.day = save_field(_data, "game_day", 1);
    _info.money = save_field(_data, "clinic_money", 0);

    var _staff_list = save_field(_data, "staff", []);
    _info.staff = is_array(_staff_list) ? array_length(_staff_list) : 0;

    var _hour = save_field(_data, "game_hour", 8);
    var _minute = save_field(_data, "game_minute", 0);

    _info.time_text = string(_hour) + ":"
        + (_minute < 10 ? "0" : "") + string(_minute);

    _info.real_text = string(save_field(_data, "saved_real_time", ""));

    // Строка для списка: «День 12, 14:35 — $143 250»
    _info.label = (_is_auto ? "Авто" : string(_index) + ".")
        + " День " + string(_info.day)
        + ", " + _info.time_text
        + " — $" + string(_info.money);

    return _info;
}


/// Список всех слотов для меню.
/// Сначала автосейвы (свежие сверху), затем 5 ручных.
function save_slot_list_all() {
    var _list = [];

    for (var _a = 1; _a <= SAVE_SLOT_AUTO_COUNT; _a++) {
        array_push(_list, save_slot_info(true, _a));
    }

    for (var _m = 1; _m <= SAVE_SLOT_MANUAL_COUNT; _m++) {
        array_push(_list, save_slot_info(false, _m));
    }

    return _list;
}


/// Только ручные слоты — для окна сохранения.
function save_slot_list_manual() {
    var _list = [];

    for (var _m = 1; _m <= SAVE_SLOT_MANUAL_COUNT; _m++) {
        array_push(_list, save_slot_info(false, _m));
    }

    return _list;
}


// ═══════════════════════════════════════════════════════════════
// 4. РУЧНОЕ СОХРАНЕНИЕ
// ═══════════════════════════════════════════════════════════════

/// Сохраняет игру в ручной слот 1..5.
function save_slot_save_manual(_index) {
    if (_index < 1 || _index > SAVE_SLOT_MANUAL_COUNT) return false;

    return save_slot_write(save_slot_manual_file(_index));
}


// ═══════════════════════════════════════════════════════════════
// 5. АВТОСОХРАНЕНИЕ ПО КОЛЬЦУ
//
// Три файла по очереди: 1 → 2 → 3 → 1 → ...
// Номер следующего лежит в global.save_auto_next и сам сохраняется
// внутри сейва, чтобы кольцо не сбивалось после перезапуска.
// ═══════════════════════════════════════════════════════════════

/// Определяет, в какой автослот писать следующим.
///
/// Если global.save_auto_next не задан (первый запуск), выбирает слот
/// с самым старым днём — так кольцо восстанавливается само, даже если
/// игра была закрыта аварийно.
function save_slot_auto_next_index() {
    if (variable_global_exists("save_auto_next")) {
        var _next = global.save_auto_next;

        if (_next >= 1 && _next <= SAVE_SLOT_AUTO_COUNT) return _next;
    }

    var _oldest_index = 1;
    var _oldest_day = -1;

    for (var _a = 1; _a <= SAVE_SLOT_AUTO_COUNT; _a++) {
        var _info = save_slot_info(true, _a);

        // Пустой слот занимаем сразу.
        if (!_info.exists) return _a;

        if (_oldest_day < 0 || _info.day < _oldest_day) {
            _oldest_day = _info.day;
            _oldest_index = _a;
        }
    }

    return _oldest_index;
}


/// Пишет автосохранение в следующий слот кольца.
function save_slot_autosave() {
    var _index = save_slot_auto_next_index();

    save_slot_write(save_slot_auto_file(_index));

    // Следующий по кругу.
    global.save_auto_next = (_index >= SAVE_SLOT_AUTO_COUNT) ? 1 : _index + 1;

    return true;
}


/// Проверка смены дня — вызывается из obj_Render/Step.
/// Заменяет save_autosave_check из пакета 269.
function save_slot_autosave_check() {
    var _day = save_global("game_day", 1);

    if (!variable_global_exists("save_last_day")) {
        global.save_last_day = _day;
        return false;
    }

    if (_day == global.save_last_day) return false;

    global.save_last_day = _day;

    return save_slot_autosave();
}


// ═══════════════════════════════════════════════════════════════
// 6. ЗАГРУЗКА ИЗ СЛОТА
// ═══════════════════════════════════════════════════════════════

/// Загружает игру из указанного слота.
///
/// Работает так же, как vetsim_load из пакета 269, но берёт данные из
/// произвольного файла. Чтобы не дублировать пятьсот строк разбора,
/// файл слота копируется в стандартный SAVE_FILE_NAME, а дальше
/// вызывается уже проверенный vetsim_load().
function save_slot_load(_is_auto, _index) {
    var _file = save_slot_file(_is_auto, _index);

    if (!file_exists(_file)) {
        show_debug_message("[SLOT] Нет файла: " + _file);
        return false;
    }

    // Копируем слот в рабочий файл через буфер.
    var _buffer = buffer_load(_file);

    if (_buffer < 0) return false;

    buffer_save(_buffer, SAVE_FILE_NAME);
    buffer_delete(_buffer);

    var _ok = vetsim_load();

    if (_ok) {
        // День для автосейва синхронизируем с загруженным, иначе
        // автосохранение сработает лишний раз сразу после загрузки.
        global.save_last_day = save_global("game_day", 1);

        show_debug_message("[SLOT] Загружен " + _file);
    }

    return _ok;
}


/// Есть ли хоть одно сохранение — для кнопки ЗАГРУЗИТЬ.
/// @function save_slot_delete(_is_auto, _index)
/// @description ПАКЕТ 274: удаляет файл одного слота.
///
/// Работает и с ручными, и с автослотами: игрок должен иметь право
/// стереть любую строку списка, включая автосейв.
///
/// Отдельная тонкость — автосейв. Кольцевой счётчик global.save_auto_next
/// указывает, куда писать следующий автосейв. Если удалить слот,
/// счётчик трогать не нужно: save_slot_auto_next_index сам предпочтёт
/// пустой слот занятому, то есть освободившееся место займётся первым.
function save_slot_delete(_is_auto, _index) {
    var _file = save_slot_file(_is_auto, _index);

    if (!file_exists(_file)) return false;

    file_delete(_file);

    show_debug_message("[SLOT] Удалён " + _file);

    return true;
}


function save_slot_any_exists() {
    for (var _a = 1; _a <= SAVE_SLOT_AUTO_COUNT; _a++) {
        if (file_exists(save_slot_auto_file(_a))) return true;
    }

    for (var _m = 1; _m <= SAVE_SLOT_MANUAL_COUNT; _m++) {
        if (file_exists(save_slot_manual_file(_m))) return true;
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 7. НОВАЯ ИГРА
// ═══════════════════════════════════════════════════════════════

/// Начинает игру заново.
///
/// Сохранения НЕ удаляются — игрок сможет вернуться к ним через меню.
/// Удаляется только рабочий файл SAVE_FILE_NAME, иначе Alarm 1 при
/// перезапуске тут же загрузил бы старую игру обратно.
function save_slot_new_game() {
    // ═══════════════════════════════════════════════════════════
    // ВАЖНО: флаг ставится ДО game_restart.
    //
    // game_restart() запускает Clean Up у obj_Render, а тот сохраняет
    // игру при выходе (пакет 269). Без флага произошло бы вот что:
    //   1. удаляем рабочий файл;
    //   2. game_restart -> Clean Up -> vetsim_save() создаёт его заново
    //      со СТАРЫМ состоянием;
    //   3. после перезапуска Alarm 1 грузит этот файл.
    // Итог: «новая игра» возвращала бы ту же самую игру.
    //
    // game_restart() обнуляет все global, поэтому флаг нужен только
    // на время выхода — до Clean Up он доживает, и этого достаточно.
    //
    // После перезапуска ничего проверять не надо: файла на диске уже
    // нет, Clean Up его не воссоздал, и Alarm 1 просто не найдёт
    // сохранение — начнётся честная новая игра.
    // ═══════════════════════════════════════════════════════════
    global.save_skip_on_exit = true;

    if (file_exists(SAVE_FILE_NAME)) {
        file_delete(SAVE_FILE_NAME);
    }

    show_debug_message("[SLOT] Новая игра — перезапуск.");

    game_restart();

    return true;
}
