/// clinic_case_gate.gml
/// @description Пакет №268: болезни приходят только те, которые клиника
/// реально может вылечить.
///
/// ═══════════════════════════════════════════════════════════════
/// ЗАЧЕМ ЭТО НУЖНО
///
/// Раньше db_pick_random_disease_for_species выбирал болезнь из всех
/// подходящих виду. Игрок мог получить перелом лапы, не имея операционной,
/// или пироплазмоз без единой койки в стационаре: случай приходил, но
/// закрыть его было физически нечем.
///
/// Теперь у каждой болезни считается, какие помещения нужны для её
/// лечения, и болезнь попадает в набор только если помещения открыты.
///
/// ═══════════════════════════════════════════════════════════════
/// КАК ОПРЕДЕЛЯЕТСЯ ПОТРЕБНОСТЬ
///
/// Отдельного поля «нужна операция» у болезни нет и добавлять его не нужно:
/// всё уже есть в связях лечения. В global.med_db.disease_treatment лежат
/// записи { disease_id, action_id, ... }, а у каждого действия в
/// global.med_db.treatment_actions есть room_id:
///
///     room_id = "room_operating"   -> нужна операционная (is_surgery = true)
///     room_id = "room_stationary"  -> нужна койка стационара
///     room_id = "room_exam"        -> хватает обычного кабинета
///
/// По базе на момент пакета №268:
///     хирургических действий 6, болезней с ними 6
///         (перелом лапы, рана, кровотечение, инородное тело в ухе,
///          пародонтит, мочекаменная болезнь)
///     стационарных действий 3, болезней с ними 13
///         (пироплазмоз, чумка, лептоспироз, пневмония, сепсис,
///          отравление, панкреатит, почечная и печёночная недостаточность,
///          гепатит, тепловой удар, вирусная инфекция, кровотечение)
///     кровотечение требует ОБА помещения сразу
///
/// Результат кэшируется: перебор 102 связей на каждого нового щенка
/// делать незачем.
/// ═══════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════
// 1. ЧТО ТРЕБУЕТ БОЛЕЗНЬ
// ═══════════════════════════════════════════════════════════════

/// Возвращает структуру { operating, stationary } для одной болезни.
/// Значения — true/false.
function clinic_case_disease_needs(_disease_id) {
    var _needs = {
        operating : false,
        stationary : false
    };

    if (!variable_global_exists("med_db")) return _needs;
    if (!is_struct(global.med_db)) return _needs;
    if (!variable_struct_exists(global.med_db, "disease_treatment")) return _needs;
    if (!variable_struct_exists(global.med_db, "treatment_actions")) return _needs;

    var _links = global.med_db.disease_treatment;
    var _actions = global.med_db.treatment_actions;
    var _target_id = string(_disease_id);

    for (var _i = 0; _i < array_length(_links); _i++) {
        var _link = _links[_i];

        if (!is_struct(_link)) continue;
        if (!variable_struct_exists(_link, "disease_id")) continue;
        if (string(_link.disease_id) != _target_id) continue;
        if (!variable_struct_exists(_link, "action_id")) continue;

        var _action_id = string(_link.action_id);

        if (!variable_struct_exists(_actions, _action_id)) continue;

        var _action = variable_struct_get(_actions, _action_id);

        if (!is_struct(_action)) continue;

        // Хирургия помечена двумя способами сразу — проверяем оба,
        // чтобы правило не сломалось при добавлении новых операций.
        if (
            variable_struct_exists(_action, "is_surgery")
            && _action.is_surgery
        ) {
            _needs.operating = true;
        }

        if (variable_struct_exists(_action, "room_id")) {
            var _room = string(_action.room_id);

            if (_room == "room_operating") _needs.operating = true;
            if (_room == "room_stationary") _needs.stationary = true;
        }
    }

    return _needs;
}


/// Кэш потребностей: строится один раз за запуск игры.
function clinic_case_needs_cache() {
    if (
        variable_global_exists("clinic_case_needs")
        && is_struct(global.clinic_case_needs)
    ) {
        return global.clinic_case_needs;
    }

    global.clinic_case_needs = {};

    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "disease_ids")
    ) {
        var _ids = global.med_db.disease_ids;

        for (var _i = 0; _i < array_length(_ids); _i++) {
            var _id = string(_ids[_i]);

            variable_struct_set(
                global.clinic_case_needs,
                _id,
                clinic_case_disease_needs(_id)
            );
        }
    }

    return global.clinic_case_needs;
}


/// Быстрый доступ к потребностям болезни через кэш.
function clinic_case_needs_for(_disease_id) {
    var _cache = clinic_case_needs_cache();
    var _key = string(_disease_id);

    if (variable_struct_exists(_cache, _key)) {
        return variable_struct_get(_cache, _key);
    }

    // Болезнь добавили в базу после построения кэша — считаем на месте.
    var _fresh = clinic_case_disease_needs(_key);
    variable_struct_set(_cache, _key, _fresh);

    return _fresh;
}


// ═══════════════════════════════════════════════════════════════
// 2. ЧТО УМЕЕТ КЛИНИКА ПРЯМО СЕЙЧАС
// ═══════════════════════════════════════════════════════════════

/// Операционная готова принимать пациентов.
///
/// ВАЖНО про CLINIC_OPERATING_FREE_WHILE_TESTING: этот макрос в
/// clinic_rooms_system открывает операционную бесплатно, пока игра в
/// разработке. Фильтр специально смотрит на ТУ ЖЕ функцию
/// clinic_operating_is_open(), а не на сырой ключ покупки — то есть при
/// включённом макросе хирургические случаи ходят как раньше, а когда вы
/// поставите макрос в false, фильтр заработает сам собой.
function clinic_case_operating_ready() {
    // Фильтр целиком выключен — считаем, что всё доступно.
    if (!CLINIC_CASE_GATE_ENABLED) return true;

    // По умолчанию фильтр уважает тестовую поблажку
    // CLINIC_OPERATING_FREE_WHILE_TESTING: пока она включена, операционная
    // считается открытой и хирургические случаи ходят как раньше.
    //
    // Если поставить CLINIC_GATE_IGNORE_TESTING_UNLOCK = true, фильтр начнёт
    // смотреть на реальную покупку — удобно, чтобы проверить механику,
    // не закрывая себе операционную для остальных тестов.
    var _open = CLINIC_GATE_IGNORE_TESTING_UNLOCK
        ? clinic_operating_is_purchased()
        : clinic_operating_is_open();

    if (!_open) return false;

    // Мало купить помещение — в нём должен стоять операционный стол.
    return instance_exists(obj_operating_table);
}


/// Стационар готов принимать пациентов.
///
/// По договорённости: стационар считается открытым, когда игрок купил
/// ХОТЯ БЫ ОДНУ койку. Койки 101 и 102 идут в комплекте с палатой, поэтому
/// для них clinic_bed_is_open всегда возвращает true — а значит проверять
/// нужно фактически существующие в комнате койки, а не диапазон номеров.
function clinic_case_stationary_ready() {
    if (!CLINIC_CASE_GATE_ENABLED) return true;

    if (!instance_exists(obj_inpatient_table)) return false;

    var _count = instance_number(obj_inpatient_table);

    for (var _i = 0; _i < _count; _i++) {
        var _bed = instance_find(obj_inpatient_table, _i);

        if (!instance_exists(_bed)) continue;

        // Некупленная койка скрыта и держит table_busy (пакет №173),
        // поэтому она не считается за рабочее место.
        var _slot = variable_instance_exists(_bed, "exam_slot_id")
            ? _bed.exam_slot_id
            : 0;

        if (clinic_room_is_open(_slot)) return true;
    }

    return false;
}


/// Клиника может полностью вылечить эту болезнь.
function clinic_case_disease_allowed(_disease_id) {
    var _needs = clinic_case_needs_for(_disease_id);

    if (_needs.operating && !clinic_case_operating_ready()) return false;
    if (_needs.stationary && !clinic_case_stationary_ready()) return false;

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. ЧЕГО НЕ ХВАТАЕТ ДЛЯ КОНКРЕТНОГО ПАЦИЕНТА
//
// Используется администратором на регистратуре: он «втайне» смотрит
// карту пациента и, если клиника не потянет, говорит об этом вслух.
// ═══════════════════════════════════════════════════════════════

/// Возвращает текст причины отказа или "" если всё в порядке.
function clinic_case_missing_room_text(_case) {
    if (!is_struct(_case)) return "";
    if (!variable_struct_exists(_case, "disease_id")) return "";

    var _needs = clinic_case_needs_for(_case.disease_id);
    var _no_operating = (_needs.operating && !clinic_case_operating_ready());
    var _no_stationary = (_needs.stationary && !clinic_case_stationary_ready());

    if (_no_operating && _no_stationary) return "Нет операционной и стационара";
    if (_no_operating) return "Нет операционной";
    if (_no_stationary) return "Нет стационара";

    return "";
}


/// То же самое, но по животному.
function clinic_case_missing_room_for_pet(_pet) {
    if (!instance_exists(_pet)) return "";
    if (!variable_instance_exists(_pet, "current_case")) return "";

    return clinic_case_missing_room_text(_pet.current_case);
}


/// То же самое, но по владельцу (у него в my_pet лежит питомец).
function clinic_case_missing_room_for_owner(_owner) {
    if (!instance_exists(_owner)) return "";
    if (!variable_instance_exists(_owner, "my_pet")) return "";

    return clinic_case_missing_room_for_pet(_owner.my_pet);
}


// ═══════════════════════════════════════════════════════════════
// 4. ВЫБОР БОЛЕЗНИ С УЧЁТОМ ОТКРЫТЫХ ПОМЕЩЕНИЙ
// ═══════════════════════════════════════════════════════════════

/// Замена db_pick_random_disease_for_species с фильтром по помещениям.
///
/// Если после фильтра не осталось ни одной болезни (например, кто-то
/// пометит все болезни вида как хирургические), возвращаем случайную из
/// полного набора — питомец без диагноза сломал бы приём. Такой случай
/// администратор всё равно отсеет на регистратуре репликой «Нет ...».
function clinic_case_pick_disease_for_species(_species_id) {
    var _pool = [];
    var _pool_any = [];

    if (
        !variable_global_exists("med_db")
        || !is_struct(global.med_db)
        || !variable_struct_exists(global.med_db, "disease_ids")
    ) {
        return "";
    }

    var _ids = global.med_db.disease_ids;

    for (var _i = 0; _i < array_length(_ids); _i++) {
        var _id = _ids[_i];
        var _d = variable_struct_get(global.med_db.diseases, _id);

        if (!db_species_match(_d.species, _species_id)) continue;

        array_push(_pool_any, _id);

        if (clinic_case_disease_allowed(_id)) {
            array_push(_pool, _id);
        }
    }

    if (array_length(_pool) > 0) {
        return _pool[irandom(array_length(_pool) - 1)];
    }

    if (array_length(_pool_any) > 0) {
        return _pool_any[irandom(array_length(_pool_any) - 1)];
    }

    return "";
}
