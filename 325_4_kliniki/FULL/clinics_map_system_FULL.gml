// ═══════════════════════════════════════════════════════════════════
// clinics_map_system
//
// Каркас сети клиник и экран карты.
//
// ПАКЕТ №325: сеть сокращена с шести клиник до ЧЕТЫРЁХ и каждая
// клиника описана полностью — со своими потолками развития.
//
//   №  Название              Приём  Койки  Опер.  Склад   Штат
//   1  Каморка на окраине      2      -      -     малый    4
//   2  Районная лечебница      3      2      -     средний  7
//   3  Городской ветцентр      4      5      -     средний 10
//   4  Клиника у парка         6      8      да    большой 17
//
// Общее у сети — ТОЛЬКО деньги (global.clinic_money) и кошелёк
// баллов развития (global.clinic_points). Всё остальное — репутация,
// пациенты, склад, персонал, построенные помещения и уровни
// улучшений — своё у каждой клиники и лежит в её кармане
// (global.clinic_state.clinic_N, см. clinic_network_system).
//
// Поля клиники:
//
//   exam_max        сколько кабинетов приёма может быть максимум;
//   bed_max         сколько коек стационара максимум (0 — стационара нет);
//   has_operating   можно ли открыть операционную;
//   storage_size    0 малый склад, 1 средний, 2 большой;
//   hire_max        потолок сотрудников, которых можно нанять;
//   reputation_start с какой репутации клиника начинает;
//   room_name       имя комнаты в проекте (собирается в IDE).
// ═══════════════════════════════════════════════════════════════════


/// clinics_spec()
/// @description Эталонное описание четырёх клиник. Собирается заново
///              при каждом вызове: это дёшево (четыре маленькие
///              структуры), зато исключает случай, когда кто-то
///              поправил общие данные и эталон «поплыл» вместе с ними.
function clinics_spec() {

    return [
        {
            id : 1,
            name : "Каморка на окраине",
            room_name : "rm_clinic_1",
            owned : true,
            price : 0,
            map_x : 0.14,
            map_y : 0.60,

            exam_max : 2,
            bed_max : 0,
            has_operating : false,
            storage_size : 0,
            hire_max : 4,

            income_per_day : 600,
            unlock_note : "",
            reputation_start : 35
        },
        {
            id : 2,
            name : "Районная лечебница",
            room_name : "rm_clinic_2",
            owned : false,
            price : 12000,
            map_x : 0.38,
            map_y : 0.34,

            exam_max : 3,
            bed_max : 2,
            has_operating : false,
            storage_size : 1,
            hire_max : 7,

            income_per_day : 1500,
            unlock_note : "",
            reputation_start : 0
        },
        {
            id : 3,
            name : "Городской ветцентр",
            room_name : "rm_clinic_3",
            owned : false,
            price : 30000,
            map_x : 0.62,
            map_y : 0.66,

            exam_max : 4,
            bed_max : 5,
            has_operating : false,
            storage_size : 1,
            hire_max : 10,

            income_per_day : 2600,
            unlock_note : "",
            reputation_start : 0
        },
        {
            id : 4,
            name : "Клиника у парка",
            room_name : "rm_clinic_4",
            owned : false,
            price : 70000,
            map_x : 0.86,
            map_y : 0.30,

            exam_max : 6,
            bed_max : 8,
            has_operating : true,
            storage_size : 2,
            hire_max : 17,

            income_per_day : 4200,
            unlock_note : "",
            reputation_start : 0
        }
    ];
}


/// clinics_init()
/// @description Создаёт global.clinics, если его ещё нет, и приводит
///              загруженное из сохранения к актуальной схеме.
///              Вызывается из obj_Render -> Create и безопасна при
///              повторном вызове: купленные клиники не «отбирает».
function clinics_init() {

    if (
        !variable_global_exists("clinics")
        || !is_array(global.clinics)
        || array_length(global.clinics) <= 0
    ) {
        global.clinics = clinics_spec();
    }
    else {
        clinics_migrate_to_spec();
    }

    // Клиника, в которой игрок находится прямо сейчас.
    if (!variable_global_exists("active_clinic")) {
        global.active_clinic = 1;
    }

    return true;
}


/// clinics_migrate_to_spec()
/// @description ПАКЕТ №325. Сохранение могло остаться от сети из шести
///              клиник, а потолки развития раньше не хранились вовсе.
///
///              Здесь общие поля каждой клиники приводятся к эталону
///              (имя, цена, потолки, доход, положение на карте), а
///              ЛИЧНЫЕ остаются как есть: куплена ли клиника и какая у
///              неё репутация. Лишние клиники (№5 и №6) выбрасываются,
///              их карманы чистятся — иначе проданная сеть продолжала
///              бы приносить доход «на бумаге».
function clinics_migrate_to_spec() {

    var _spec = clinics_spec();
    var _result = [];

    for (var _index = 0; _index < array_length(_spec); _index++) {

        var _fresh = _spec[_index];
        var _old = clinics_get(_fresh.id);

        if (is_struct(_old)) {
            // Личное игрока переносим из старой записи.
            if (variable_struct_exists(_old, "owned")) {
                _fresh.owned = _old.owned ? true : false;
            }

            if (
                variable_struct_exists(_old, "reputation")
                && is_real(_old.reputation)
            ) {
                _fresh.reputation_start = _old.reputation;
            }
        }

        array_push(_result, _fresh);
    }

    // Чистим карманы клиник, которых больше нет в сети.
    if (
        variable_global_exists("clinic_state")
        && is_struct(global.clinic_state)
    ) {
        for (var _drop = array_length(_spec) + 1; _drop <= 6; _drop++) {
            var _key = "clinic_" + string(_drop);

            if (variable_struct_exists(global.clinic_state, _key)) {
                variable_struct_remove(global.clinic_state, _key);
            }
        }
    }

    global.clinics = _result;

    show_debug_message(
        "[CLINICS] Сеть приведена к четырём клиникам (пакет №325)"
    );

    return true;
}


/// clinics_get(_clinic_id)
/// @description Возвращает структуру клиники по её номеру или
///              undefined, если такой нет.
function clinics_get(_clinic_id) {

    if (!variable_global_exists("clinics") || !is_array(global.clinics)) {
        return undefined;
    }

    for (var _i = 0; _i < array_length(global.clinics); _i++) {
        var _clinic = global.clinics[_i];

        if (is_struct(_clinic) && _clinic.id == _clinic_id) {
            return _clinic;
        }
    }

    return undefined;
}


/// clinics_count()
/// @description Сколько клиник в сети (купленных и чужих вместе).
function clinics_count() {

    if (!variable_global_exists("clinics") || !is_array(global.clinics)) {
        return 0;
    }

    return array_length(global.clinics);
}


/// clinics_count_owned()
/// @description Сколько клиник в собственности. Нужно для правила
///              «нельзя продать последнюю».
function clinics_count_owned() {

    if (!variable_global_exists("clinics") || !is_array(global.clinics)) {
        return 0;
    }

    var _count = 0;

    for (var _i = 0; _i < array_length(global.clinics); _i++) {
        if (is_struct(global.clinics[_i]) && global.clinics[_i].owned) {
            _count += 1;
        }
    }

    return _count;
}


/// clinics_sell_price(_clinic)
/// @description Возврат при продаже — 60% от цены. Так продажа
///              остаётся осознанным решением, а не способом фармить.
function clinics_sell_price(_clinic) {

    if (!is_struct(_clinic)) return 0;

    return floor(_clinic.price * 0.6);
}


/// clinics_can_sell(_clinic)
/// @description Проверяет, можно ли продать клинику. Возвращает
///              структуру { ok, reason } — причину показываем игроку,
///              чтобы кнопка не была просто мёртвой.
function clinics_can_sell(_clinic) {

    if (!is_struct(_clinic)) {
        return { ok : false, reason : "Клиника не найдена" };
    }

    if (!_clinic.owned) {
        return { ok : false, reason : "Клиника вам не принадлежит" };
    }

    // Нельзя продать ту, в которой стоишь: сначала уехать.
    // Сверяемся с реальной комнатой, а не с active_clinic: игрок мог
    // уйти на тестовый полигон, и active_clinic останется прежним.
    var _here = 0;

    if (script_exists(asset_get_index("clinic_room_owner"))) {
        _here = clinic_room_owner();
    }

    if (_here <= 0 && variable_global_exists("active_clinic")) {
        _here = global.active_clinic;
    }

    if (_clinic.id == _here) {
        return { ok : false, reason : "Нельзя продать клинику, в которой вы находитесь" };
    }

    // Должна остаться хотя бы одна.
    if (clinics_count_owned() <= 1) {
        return { ok : false, reason : "Это ваша последняя клиника" };
    }

    return { ok : true, reason : "" };
}


/// clinics_can_buy(_clinic)
/// @description Проверяет возможность покупки.
function clinics_can_buy(_clinic) {

    if (!is_struct(_clinic)) {
        return { ok : false, reason : "Клиника не найдена" };
    }

    if (_clinic.owned) {
        return { ok : false, reason : "Уже ваша" };
    }

    if (global.clinic_money < _clinic.price) {
        return {
            ok : false,
            reason : "Не хватает $" + string(_clinic.price - global.clinic_money)
        };
    }

    return { ok : true, reason : "" };
}


/// clinics_buy(_clinic_id)
/// @description Покупка клиники. Возвращает true при успехе.
function clinics_buy(_clinic_id) {

    var _clinic = clinics_get(_clinic_id);

    if (!is_struct(_clinic)) return false;

    var _check = clinics_can_buy(_clinic);

    if (!_check.ok) return false;

    global.clinic_money -= _clinic.price;
    _clinic.owned = true;

    // ПАКЕТ №325: у купленной клиники своя репутация. Она стартует с
    // нуля — зарабатывать имя приходится заново, деньгами сеть
    // делится, а репутацией нет.
    _clinic.reputation_start = max(0, round(_clinic.reputation_start));

    if (script_exists(asset_get_index("clinic_state_get"))) {
        clinic_state_get(_clinic.id);
    }

    show_debug_message(
        "[CLINICS] Куплена клиника " + string(_clinic_id)
        + " «" + _clinic.name + "» за $" + string(_clinic.price)
    );

    return true;
}


/// clinics_sell(_clinic_id)
/// @description Продажа клиники. Возвращает true при успехе.
function clinics_sell(_clinic_id) {

    var _clinic = clinics_get(_clinic_id);

    if (!is_struct(_clinic)) return false;

    var _check = clinics_can_sell(_clinic);

    if (!_check.ok) return false;

    global.clinic_money += clinics_sell_price(_clinic);
    _clinic.owned = false;

    // ПАКЕТ №325: карман очищаем ЦЕЛИКОМ — персонал, склад, картотека
    // пациентов, репутация, построенные помещения и уровни улучшений.
    // Иначе проданная клиника продолжала бы жить в памяти: приносила
    // доход «на бумаге», а при повторной покупке игрок получил бы
    // обратно и штат, и склад, и репутацию, за которые не платил.
    if (script_exists(asset_get_index("clinic_state_reset"))) {
        clinic_state_reset(_clinic.id);
    }

    show_debug_message(
        "[CLINICS] Продана клиника " + string(_clinic_id)
        + " за $" + string(clinics_sell_price(_clinic))
    );

    return true;
}
