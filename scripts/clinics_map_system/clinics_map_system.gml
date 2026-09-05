// ═══════════════════════════════════════════════════════════════════
// clinics_map_system
//
// Каркас сети клиник и экран карты.
//
// ЭТО ПЕРВЫЙ ШАГ. Здесь только данные и отрисовка: список клиник,
// карта, карточка по тапу, покупка и продажа. Переезда между
// клиниками ещё НЕТ — кнопка «ВОЙТИ» пока сообщает, что комната не
// готова. Так и задумано: комнаты 2-6 предстоит собрать в IDE, и
// делать переход некуда.
//
// Порядок работ из дизайн-документа: каркас -> карта -> переезд ->
// доход «на бумаге» -> главврач -> комнаты.
// ═══════════════════════════════════════════════════════════════════


/// clinics_init()
/// @description Создаёт global.clinics, если его ещё нет.
///              Вызывается из obj_Render -> Create и безопасна при
///              повторном вызове: существующие данные не затирает.
function clinics_init() {

    // Уже создано (например, поднято из сохранения) — не трогаем.
    if (variable_global_exists("clinics") && is_array(global.clinics)) {
        if (array_length(global.clinics) > 0) return false;
    }

    // ── СЕТКА ИЗ ШЕСТИ КЛИНИК ──
    // Цены и параметры взяты из утверждённого дизайн-документа.
    // Поле room пока пустое: комнаты 2-6 ещё не собраны в IDE,
    // поэтому храним имя строкой и разрешаем его позже.
    global.clinics = [
        // ПАКЕТ №302: клиника №1 открывается в собранной комнате
        // rm_clinic. Имя было прописано здесь заранее (пакет 280), но
        // самой комнаты в проекте не существовало — теперь она есть.
        //
        // room1 из игрового цикла выведена: она остаётся тестовой
        // площадкой и открывается отладочной клавишей R (см.
        // obj_Render -> Step). Стартовая комната проекта тоже должна
        // быть переключена на rm_clinic — это делается в IDE, в
        // настройках Room Order, см. README пакета.
        {
            id : 1,
            name : "Каморка на окраине",
            room_name : "rm_clinic",
            owned : true,
            price : 0,
            map_x : 0.14,          // доля от ширины карты, не пиксели:
            map_y : 0.62,          // так карта не поедет на другом экране
            exam_rooms : 1,
            beds : 0,
            has_operating : false,
            income_per_day : 600,
            unlock_note : "",
            reputation : 35
        },
        {
            id : 2,
            name : "Районная лечебница",
            room_name : "",
            owned : false,
            price : 10000,
            map_x : 0.32,
            map_y : 0.38,
            exam_rooms : 2,
            beds : 2,
            has_operating : false,
            income_per_day : 1400,
            unlock_note : "",
            reputation : 0
        },
        {
            id : 3,
            name : "Городской ветцентр",
            room_name : "",
            owned : false,
            price : 25000,
            map_x : 0.50,
            map_y : 0.66,
            exam_rooms : 3,
            beds : 4,
            has_operating : true,
            income_per_day : 2800,
            unlock_note : "Нужен врач с навыком 8 (главврач)",
            reputation : 0
        },
        // ПАКЕТ №304: временно указывает на room1 — бывшую тестовую
        // комнату. Она подходит по составу лучше прочих: три смотровых
        // кабинета, четыре койки стационара и операционная, а по данным
        // у клиники №4 как раз beds 6 и has_operating true.
        //
        // Это временно. Когда для клиники №4 соберут собственную
        // комнату, здесь меняется одна строка room_name, и room1 снова
        // становится чистым полигоном.
        {
            id : 4,
            name : "Клиника у парка",
            room_name : "Room1",
            owned : false,
            price : 50000,
            map_x : 0.66,
            map_y : 0.32,
            exam_rooms : 4,
            beds : 6,
            has_operating : true,
            income_per_day : 4200,
            unlock_note : "Нужен главврач и репутация 60",
            reputation : 0
        },
        {
            id : 5,
            name : "Областная больница",
            room_name : "",
            owned : false,
            price : 90000,
            map_x : 0.81,
            map_y : 0.60,
            exam_rooms : 4,
            beds : 8,
            has_operating : true,
            income_per_day : 6000,
            unlock_note : "Нужно два главврача",
            reputation : 0
        },
        {
            id : 6,
            name : "Столичный госпиталь",
            room_name : "",
            owned : false,
            price : 150000,
            map_x : 0.92,
            map_y : 0.24,
            exam_rooms : 5,
            beds : 10,
            has_operating : true,
            income_per_day : 8500,
            unlock_note : "Нужен врач с навыком 10",
            reputation : 0
        }
    ];

    // Клиника, в которой игрок находится прямо сейчас.
    if (!variable_global_exists("active_clinic")) {
        global.active_clinic = 1;
    }

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
    if (_clinic.id == global.active_clinic) {
        return { ok : false, reason : "Нельзя продать клинику, в которой вы находитесь" };
    }

    // Должна остаться хотя бы одна.
    if (clinics_count_owned() <= 1) {
        return { ok : false, reason : "Это ваша последняя клиника" };
    }

    // Правило про пациентов в стационаре заработает вместе с
    // переездом: пока клиника всего одна и она же активная, лежачих
    // пациентов в неактивных клиниках просто не бывает.

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

    // Условия открытия (главврач, репутация) пока только показываем
    // текстом. Проверять их будем, когда появится сама механика
    // главврача — иначе получится заглушка, которая врёт.
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

    // ПАКЕТ 301: заводим карман под персонал и склад новой клиники.
    // Пустой: сотрудников туда игрок нанимает сам, приехав на место.
    if (script_exists(asset_get_index("clinic_state_get"))) {
        clinic_state_get(_clinic.id);
    }

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

    // ПАКЕТ 301: карман очищаем. Иначе персонал проданной клиники
    // остался бы в памяти и продолжал приносить доход «на бумаге».
    if (
        variable_global_exists("clinic_state")
        && is_struct(global.clinic_state)
    ) {
        var _key = "clinic_" + string(_clinic.id);

        if (variable_struct_exists(global.clinic_state, _key)) {
            variable_struct_set(global.clinic_state, _key, {
                staff : [],
                inventory : {},
                visited : false
            });
        }
    }

    return true;
}
