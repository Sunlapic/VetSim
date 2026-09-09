/// clinic_diagnostics.gml
/// @description Пакет №329: диагностика, в которой понятно, ГДЕ проблема.
///
/// ═══════════════════════════════════════════════════════════════
/// ЗАЧЕМ
///
/// Раньше консоль писала «Стол в позиции (1200,840) без exam_slot_id»
/// или «Койка 102 не собрана». В четырёх клиниках это уже не
/// диагностика: непонятно, в какую комнату идти править.
///
/// Здесь две вещи:
///
///   1. clinic_diag_context() — приставка «Клиника №3 «Городской
///      ветцентр» · rm_clinic_3 · » для любого сообщения. Её
///      подставляют в свои предупреждения столы, шкафы, койки.
///
///   2. clinic_room_audit() — проверка состава комнаты. Функция
///      знает, что должно стоять в каждом кабинете, в каждой койке,
///      в операционной и в послеоперационной, и печатает ровно то,
///      чего не хватает:
///
///      [ПРОВЕРКА] Клиника №3 «Городской ветцентр» · rm_clinic_3 ·
///                 кабинет приёма 2: нет объекта obj_exam_point_owner
///                 (exam_slot_id = 2). Поставь объект и пропиши
///                 exam_slot_id = 2; в Creation Code инстанса.
///
/// ═══════════════════════════════════════════════════════════════
/// КОГДА ВЫЗЫВАЕТСЯ
///
/// obj_Render → Alarm 2, один раз за вход в комнату. Будильник
/// ставится в Room Start, список проверенных комнат обнуляется там
/// же — поэтому при переезде между клиниками каждая проверяется
/// заново.
///
/// Загрузка сохранения проверку не отменяет: она смотрит только на
/// расстановку объектов в комнате, а не на персонал.
///
/// В комнате, которая не принадлежит ни одной клинике (техническая
/// Room1 — база объектов), проверка не печатает ничего: там
/// намеренно собраны все системы разом и «недостающие» объекты
/// ничего не значат.
///
/// Печатается ВСЕГДА, а не только в режиме отладки: состав комнат
/// сейчас как раз наводится, и видеть пропуски нужно в любом запуске.
/// ═══════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════
// 1. ГДЕ МЫ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_room_clinic_id()
/// @description Номер клиники текущей комнаты или 0.
function clinic_room_clinic_id() {

    if (script_exists(asset_get_index("clinic_room_owner"))) {
        var _owner = clinic_room_owner();

        if (_owner > 0) return _owner;
    }

    // Комната ещё не привязана (первый кадр) — берём активную клинику,
    // но только если сеть уже собрана.
    if (
        variable_global_exists("clinics")
        && is_array(global.clinics)
        && array_length(global.clinics) > 0
        && variable_global_exists("active_clinic")
    ) {
        return global.active_clinic;
    }

    return 0;
}


/// @function clinic_diag_room_name()
/// @description Имя текущей комнаты.
function clinic_diag_room_name() {

    var _name = room_get_name(room);

    if (_name == undefined || string(_name) == "") {
        return "комната " + string(room);
    }

    return string(_name);
}


/// @function clinic_diag_clinic_label()
/// @description «Клиника №2 «Районная лечебница»» либо пометка
///              технической комнаты.
function clinic_diag_clinic_label() {

    var _id = clinic_room_clinic_id();

    if (_id <= 0) {
        return "Техническая комната (не клиника)";
    }

    var _name = "";

    if (script_exists(asset_get_index("clinic_value"))) {
        _name = string(clinic_value(_id, "name", ""));
    }

    if (_name == "") {
        return "Клиника №" + string(_id);
    }

    return "Клиника №" + string(_id) + " «" + _name + "»";
}


/// @function clinic_diag_context()
/// @description Приставка для любого сообщения: клиника и комната.
function clinic_diag_context() {
    return clinic_diag_clinic_label() + " · " + clinic_diag_room_name() + " · ";
}


/// @function clinic_audit_msg(_text)
/// @description Строка проверки состава комнаты.
function clinic_audit_msg(_text) {
    return "[ПРОВЕРКА] " + clinic_diag_context() + _text;
}


// ═══════════════════════════════════════════════════════════════
// 2. РУССКИЕ НАЗВАНИЯ ОБЪЕКТОВ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_object_name_ru(_object_name)
/// @description Понятное имя объекта для сообщений.
function clinic_object_name_ru(_object_name) {

    var _names = {
        obj_Render                          : "движок клиники (obj_Render)",
        obj_UI_HUD                          : "интерфейс (obj_UI_HUD)",
        obj_UI_Tablet                       : "планшет (obj_UI_Tablet)",
        obj_player                          : "игрок (obj_player)",
        obj_monitor                         : "монитор статистики (obj_monitor)",
        obj_storage_main                    : "главный склад (obj_storage_main)",
        obj_candidate_spot                  : "точка кандидата (obj_candidate_spot)",
        obj_cleanliness_controller          : "контроль чистоты (obj_cleanliness_controller)",
        obj_cleanliness_area_start          : "начало зоны уборки (obj_cleanliness_area_start)",
        obj_cleanliness_area_start_2        : "начало зоны уборки 2 (obj_cleanliness_area_start_2)",
        obj_cleanliness_area_end            : "конец зоны уборки (obj_cleanliness_area_end)",
        obj_cleanliness_area_end_2          : "конец зоны уборки 2 (obj_cleanliness_area_end_2)",
        obj_wait_spot                       : "точка ожидания (obj_wait_spot)",
        obj_reception_desk                  : "стойка регистратуры (obj_reception_desk)",
        obj_reception_point_staff           : "точка сотрудника регистратуры (obj_reception_point_staff)",
        obj_reception_point_owner           : "точка клиента регистратуры (obj_reception_point_owner)",
        obj_table                           : "стол приёма (obj_table)",
        obj_table_1                         : "стол приёма, второй вариант (obj_table_1)",
        obj_exam_point_doctor               : "точка врача (obj_exam_point_doctor)",
        obj_exam_point_owner                : "точка владельца (obj_exam_point_owner)",
        obj_exam_point_pet_floor            : "точка животного на полу (obj_exam_point_pet_floor)",
        obj_exam_point_pet_table            : "точка животного на столе (obj_exam_point_pet_table)",
        obj_storage_cabinet                 : "шкаф кабинета (obj_storage_cabinet)",
        obj_inpatient_controller            : "контроллер койки (obj_inpatient_controller)",
        obj_inpatient_table                 : "стационарный стол (obj_inpatient_table)",
        obj_inpatient_point_doctor          : "точка врача стационара (obj_inpatient_point_doctor)",
        obj_inpatient_point_assistant       : "точка ассистента стационара (obj_inpatient_point_assistant)",
        obj_inpatient_point_owner           : "точка владельца стационара (obj_inpatient_point_owner)",
        obj_inpatient_point_pet_table       : "точка животного на столе стационара (obj_inpatient_point_pet_table)",
        obj_inpatient_point_pet_floor       : "точка животного на полу стационара (obj_inpatient_point_pet_floor)",
        obj_inpatient_cabinet               : "шкаф стационара (obj_inpatient_cabinet)",
        obj_inpatient_doctor_chair          : "место отдыха врача стационара (obj_inpatient_doctor_chair)",
        obj_inpatient_point_doctor_rest     : "точка отдыха врача стационара (obj_inpatient_point_doctor_rest)",
        obj_operating_controller            : "контроллер операционной (obj_operating_controller)",
        obj_operating_table                 : "операционный стол (obj_operating_table)",
        obj_operating_seat                  : "сидение операционной (obj_operating_seat)",
        obj_operating_point_surgeon         : "точка хирурга (obj_operating_point_surgeon)",
        obj_operating_point_assistant       : "точка ассистента операционной (obj_operating_point_assistant)",
        obj_operating_point_anesthetist     : "точка анестезиолога (obj_operating_point_anesthetist)",
        obj_operating_point_pet             : "точка животного операционной (obj_operating_point_pet)",
        obj_or_recovery_bed                 : "койка послеоперационной (obj_or_recovery_bed)",
        obj_or_recovery_point_pet           : "точка животного послеоперационной (obj_or_recovery_point_pet)",
        obj_or_recovery_point_assistant     : "точка ассистента послеоперационной (obj_or_recovery_point_assistant)"
    };

    var _key = string(_object_name);

    if (variable_struct_exists(_names, _key)) {
        return string(variable_struct_get(_names, _key));
    }

    return _key;
}


// ═══════════════════════════════════════════════════════════════
// 3. ПОИСК ОБЪЕКТОВ ПО СЛОТУ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_slot_var_for(_object_name)
/// @description Какое поле задаёт принадлежность объекта: у койки
///              точки смотрят в ward_slot_id, у стола койки —
///              в exam_slot_id.
function clinic_slot_var_for(_object_name) {

    var _by_ward = [
        "obj_inpatient_point_doctor",
        "obj_inpatient_point_assistant",
        "obj_inpatient_point_owner",
        "obj_inpatient_point_pet_table",
        "obj_inpatient_point_pet_floor",
        "obj_or_recovery_point_pet",
        "obj_or_recovery_point_assistant"
    ];

    var _name = string(_object_name);

    for (var _index = 0; _index < array_length(_by_ward); _index++) {
        if (_by_ward[_index] == _name) return "ward_slot_id";
    }

    return "exam_slot_id";
}


/// @function clinic_count_by_slot(_object_name, _slot_id)
/// @description Сколько экземпляров объекта привязаны к слоту.
function clinic_count_by_slot(_object_name, _slot_id) {

    var _asset = asset_get_index(string(_object_name));

    if (_asset == -1) return 0;
    if (!object_exists(_asset)) return 0;

    var _var_name = clinic_slot_var_for(_object_name);
    var _count = 0;
    var _total = instance_number(_asset);

    for (var _index = 0; _index < _total; _index++) {
        var _inst = instance_find(_asset, _index);

        if (!instance_exists(_inst)) continue;
        if (!variable_instance_exists(_inst, _var_name)) continue;

        if (round(variable_instance_get(_inst, _var_name)) == round(_slot_id)) {
            _count++;
        }
    }

    return _count;
}


/// @function clinic_list_by_slot(_object_name, _slot_id)
/// @description Перечисляет найденные экземпляры: «inst_1A2B, inst_3C4D».
function clinic_list_by_slot(_object_name, _slot_id) {

    var _asset = asset_get_index(string(_object_name));

    if (_asset == -1) return "";
    if (!object_exists(_asset)) return "";

    var _var_name = clinic_slot_var_for(_object_name);
    var _result = "";
    var _total = instance_number(_asset);

    for (var _index = 0; _index < _total; _index++) {
        var _inst = instance_find(_asset, _index);

        if (!instance_exists(_inst)) continue;
        if (!variable_instance_exists(_inst, _var_name)) continue;

        if (round(variable_instance_get(_inst, _var_name)) == round(_slot_id)) {
            if (_result != "") _result += ", ";

            _result += string(_inst) + " ("
                + string(floor(_inst.x)) + "," + string(floor(_inst.y)) + ")";
        }
    }

    return _result;
}


/// @function clinic_missing_hint(_object_name)
/// @description Подсказка: что прописать в Creation Code инстанса.
function clinic_missing_hint(_object_name) {

    var _name = string(_object_name);
    var _by_ward = [
        "obj_inpatient_point_doctor",
        "obj_inpatient_point_assistant",
        "obj_inpatient_point_owner",
        "obj_inpatient_point_pet_table",
        "obj_inpatient_point_pet_floor",
        "obj_or_recovery_point_pet",
        "obj_or_recovery_point_assistant"
    ];

    for (var _index = 0; _index < array_length(_by_ward); _index++) {
        if (_by_ward[_index] == _name) {
            return "ward_slot_id = N;";
        }
    }

    if (_name == "obj_reception_desk"
        || _name == "obj_reception_point_staff"
        || _name == "obj_reception_point_owner"
    ) {
        return "reception_slot_id = N;";
    }

    return "exam_slot_id = N;";
}


// ═══════════════════════════════════════════════════════════════
// 4. ПРОВЕРКА ОДНОЙ ГРУППЫ ОБЪЕКТОВ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_audit_group(_slot_id, _objects, _where_ru, _problems)
/// @description Проверяет группу объектов одного слота: чего нет,
///              чего больше одного. Возвращает число новых проблем.
function clinic_audit_group(_slot_id, _objects, _where_ru, _problems) {

    var _found = 0;

    for (var _index = 0; _index < array_length(_objects); _index++) {
        var _object_name = _objects[_index];
        var _count = clinic_count_by_slot(_object_name, _slot_id);

        if (_count <= 0) {
            show_debug_message(clinic_audit_msg(
                _where_ru + ": нет объекта "
                + clinic_object_name_ru(_object_name) + ". "
                + "Поставь объект и пропиши "
                + clinic_missing_hint(_object_name) + " в Creation Code инстанса."
            ));

            _found++;
        }
        else if (_count > 1) {
            show_debug_message(clinic_audit_msg(
                _where_ru + ": " + string(_count) + " объекта "
                + clinic_object_name_ru(_object_name)
                + " на один слот — " + clinic_list_by_slot(_object_name, _slot_id) + ". "
                + "Нужен ровно один."
            ));

            _found++;
        }
    }

    return _problems + _found;
}


// ═══════════════════════════════════════════════════════════════
// 5. ПРОСТО «ЕСТЬ / НЕТ»
// ═══════════════════════════════════════════════════════════════

/// @function clinic_audit_object(_object_name, _min_count, _problems)
/// @description Проверяет, что объект в комнате есть.
function clinic_audit_object(_object_name, _min_count, _problems) {

    var _asset = asset_get_index(string(_object_name));

    if (_asset == -1 || !object_exists(_asset)) {
        show_debug_message(clinic_audit_msg(
            "в проекте нет объекта " + string(_object_name) + "."
        ));

        return _problems + 1;
    }

    var _count = instance_number(_asset);

    if (_count < _min_count) {
        var _need = _min_count > 1
            ? "нужно " + string(_min_count) + " шт."
            : "нужен 1 шт.";

        show_debug_message(clinic_audit_msg(
            "нет объекта " + clinic_object_name_ru(_object_name)
            + " — найдено " + string(_count) + ", " + _need + "."
        ));

        return _problems + 1;
    }

    return _problems;
}


// ═══════════════════════════════════════════════════════════════
// 6. ГЛАВНАЯ ПРОВЕРКА
// ═══════════════════════════════════════════════════════════════

/// @function clinic_room_audit()
/// @description Проверяет состав текущей комнаты клиники.
/// @return Число найденных проблем.
function clinic_room_audit() {

    var _clinic_id = clinic_room_clinic_id();

    if (_clinic_id <= 0) {
        // Техническая комната (база объектов). Состав там намеренно
        // неполный, ругаться не на что.
        return 0;
    }

    var _problems = 0;

    // ── Системные объекты ──
    var _system_objects = [
        "obj_Render",
        "obj_UI_HUD",
        "obj_UI_Tablet",
        "obj_player",
        "obj_monitor",
        "obj_storage_main",
        "obj_candidate_spot",
        "obj_cleanliness_controller"
    ];

    for (var _index = 0; _index < array_length(_system_objects); _index++) {
        _problems = clinic_audit_object(_system_objects[_index], 1, _problems);
    }

    // ── Точки ожидания ──
    var _wait_asset = asset_get_index("obj_wait_spot");

    if (_wait_asset != -1 && object_exists(_wait_asset)) {
        var _wait_count = instance_number(_wait_asset);

        if (_wait_count <= 0) {
            show_debug_message(clinic_audit_msg(
                "нет ни одной точки ожидания (obj_wait_spot) — "
                + "клиентам негде стоять."
            ));

            _problems++;
        }
    }

    // ── Зоны уборки ──
    var _area_objects = [
        "obj_cleanliness_area_start",
        "obj_cleanliness_area_end",
        "obj_cleanliness_area_start_2",
        "obj_cleanliness_area_end_2"
    ];

    for (var _index = 0; _index < array_length(_area_objects); _index++) {
        _problems = clinic_audit_object(_area_objects[_index], 1, _problems);
    }

    // ── Столы без Creation Code ──
    //
    // У obj_table слот по умолчанию 1, у obj_table_1 — 2. Такой стол
    // молча приписывается кабинету, которому не принадлежит.
    var _table_defaults = [
        { object_name : "obj_table",   default_slot : 1 },
        { object_name : "obj_table_1", default_slot : 2 }
    ];

    for (var _index = 0; _index < array_length(_table_defaults); _index++) {
        var _entry = _table_defaults[_index];
        var _asset = asset_get_index(_entry.object_name);

        if (_asset == -1 || !object_exists(_asset)) continue;

        var _total = instance_number(_asset);

        for (var _k = 0; _k < _total; _k++) {
            var _inst = instance_find(_asset, _k);

            if (!instance_exists(_inst)) continue;
            if (!variable_instance_exists(_inst, "exam_slot_id")) continue;

            if (round(_inst.exam_slot_id) == _entry.default_slot) {
                show_debug_message(clinic_audit_msg(
                    "стол " + string(_inst) + " ("
                    + string(floor(_inst.x)) + "," + string(floor(_inst.y))
                    + ") без exam_slot_id — считается кабинетом "
                    + string(_entry.default_slot) + ". "
                    + "Если это другой кабинет, пропиши exam_slot_id = N; "
                    + "в Creation Code инстанса."
                ));

                _problems++;
            }
        }
    }

    // ── Кабинеты приёма ──
    var _exam_objects = [
        "obj_table",
        "obj_exam_point_doctor",
        "obj_exam_point_owner",
        "obj_exam_point_pet_floor",
        "obj_exam_point_pet_table",
        "obj_storage_cabinet"
    ];

    var _exam_limit = 1;

    if (script_exists(asset_get_index("clinic_exam_room_limit"))) {
        _exam_limit = clinic_exam_room_limit();
    }

    for (var _slot = 1; _slot <= _exam_limit; _slot++) {
        var _exam_open = true;

        if (script_exists(asset_get_index("clinic_exam_room_is_open"))) {
            _exam_open = clinic_exam_room_is_open(_slot);
        }

        if (!_exam_open) continue;

        _problems = clinic_audit_group(
            _slot,
            _exam_objects,
            "кабинет приёма " + string(_slot),
            _problems
        );
    }

    // ── Регистратура ──
    var _reception_objects = [
        "obj_reception_desk",
        "obj_reception_point_staff",
        "obj_reception_point_owner"
    ];

    for (var _slot = 1; _slot <= 2; _slot++) {
        _problems = clinic_audit_group(
            _slot,
            _reception_objects,
            "регистратура " + string(_slot),
            _problems
        );
    }

    // ── Стационар ──
    var _ward_is_open = false;

    if (script_exists(asset_get_index("clinic_ward_is_open"))) {
        _ward_is_open = clinic_ward_is_open();
    }

    if (_ward_is_open) {
        var _ward_common = [
            "obj_inpatient_cabinet",
            "obj_inpatient_doctor_chair",
            "obj_inpatient_point_doctor_rest"
        ];

        for (var _index = 0; _index < array_length(_ward_common); _index++) {
            _problems = clinic_audit_object(_ward_common[_index], 1, _problems);
        }

        var _bed_objects = [
            "obj_inpatient_controller",
            "obj_inpatient_table",
            "obj_inpatient_point_doctor",
            "obj_inpatient_point_assistant",
            "obj_inpatient_point_owner",
            "obj_inpatient_point_pet_table",
            "obj_inpatient_point_pet_floor"
        ];

        var _bed_limit = 0;

        if (script_exists(asset_get_index("clinic_bed_limit"))) {
            _bed_limit = clinic_bed_limit();
        }

        for (var _slot = 101; _slot < 101 + _bed_limit; _slot++) {
            var _bed_open = true;

            if (script_exists(asset_get_index("clinic_bed_is_open"))) {
                _bed_open = clinic_bed_is_open(_slot);
            }

            if (!_bed_open) continue;

            _problems = clinic_audit_group(
                _slot,
                _bed_objects,
                "койка " + string(_slot),
                _problems
            );
        }
    }

    // ── Операционная ──
    var _oper_is_open = false;

    if (script_exists(asset_get_index("clinic_operating_is_open"))) {
        _oper_is_open = clinic_operating_is_open();
    }

    if (_oper_is_open) {
        var _oper_objects = [
            "obj_operating_controller",
            "obj_operating_table",
            "obj_operating_seat",
            "obj_operating_point_surgeon",
            "obj_operating_point_assistant",
            "obj_operating_point_anesthetist",
            "obj_operating_point_pet"
        ];

        for (var _index = 0; _index < array_length(_oper_objects); _index++) {
            _problems = clinic_audit_object(_oper_objects[_index], 1, _problems);
        }

        var _recovery_objects = [
            "obj_or_recovery_bed",
            "obj_or_recovery_point_pet",
            "obj_or_recovery_point_assistant"
        ];

        for (var _index = 0; _index < array_length(_recovery_objects); _index++) {
            _problems = clinic_audit_object(_recovery_objects[_index], 1, _problems);
        }
    }

    // ── Итог ──
    if (_problems <= 0) {
        show_debug_message(clinic_audit_msg(
            "состав комнаты в порядке — проблем не найдено."
        ));
    }
    else {
        show_debug_message(clinic_audit_msg(
            "ИТОГО: найдено проблем — " + string(_problems) + "."
        ));
    }

    return _problems;
}
