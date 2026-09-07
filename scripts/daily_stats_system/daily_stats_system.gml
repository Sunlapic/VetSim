/// daily_stats_system.gml
/// @description Счётчики итогов дня в одном месте. Пакет №318.
///
/// ── Зачем понадобился отдельный скрипт ──
///
/// Счётчики увеличивались прямо там, где происходило событие: диагноз —
/// в obj_staff_doctor, процедура — в obj_staff_assistant, оплата — в
/// reception_finish_owner_payment. Каждое место писало в global.daily_stats
/// само, со своей проверкой «а существует ли поле».
///
/// Из-за этого действия ИГРОКА нигде не учитывались: он ставит диагноз и
/// делает процедуры через другие функции, а дописать туда счётчик забыли.
/// В итогах дня было «Поставлено диагнозов: 2», хотя игрок поставил больше.
///
/// Теперь все счётчики идут через функции ниже. Добавить новое место
/// учёта — одна строка, и она гарантированно совпадает с остальными.


// ═══════════════════════════════════════════════════════════════
// 1. БЕЗОПАСНОЕ УВЕЛИЧЕНИЕ
// ═══════════════════════════════════════════════════════════════

/// @function daily_stats_add(_key, _amount)
/// @description Прибавляет к счётчику дня. Создаёт поле, если его нет.
function daily_stats_add(_key, _amount = 1) {

    if (!variable_global_exists("daily_stats")) return false;
    if (!is_struct(global.daily_stats)) return false;

    var _name = string(_key);
    var _current = 0;

    if (variable_struct_exists(global.daily_stats, _name)) {
        _current = variable_struct_get(global.daily_stats, _name);

        if (!is_real(_current)) _current = 0;
    }

    variable_struct_set(global.daily_stats, _name, _current + _amount);

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 2. СОБЫТИЯ ДНЯ
// ═══════════════════════════════════════════════════════════════

/// @function daily_stats_count_diagnosis(_case)
/// @description Диагноз поставлен. Считается ОДИН раз на случай.
///
/// Защита от повторов важна: игрок может открыть карточку и сделать
/// ещё одно обследование уже после того, как диагноз подтверждён —
/// без флага это дало бы второй плюс к счётчику.
function daily_stats_count_diagnosis(_case) {

    if (!is_struct(_case)) return false;

    if (
        variable_struct_exists(_case, "stats_diagnosis_counted")
        && _case.stats_diagnosis_counted
    ) {
        return false;
    }

    _case.stats_diagnosis_counted = true;

    daily_stats_add("new_diagnosed", 1);

    return true;
}


/// @function daily_stats_count_procedure()
/// @description Выполнена лечебная процедура — кем угодно.
function daily_stats_count_procedure() {
    return daily_stats_add("procedures_done", 1);
}


/// @function daily_stats_count_exam(_case)
/// @description Приём проведён (пациент осмотрен врачом или игроком).
///
/// Раньше строка «Принято пациентов» показывала paid_visits — число
/// ОПЛАТ. Это не одно и то же: пациент, который ещё лечится и уйдёт
/// платить завтра, в счёт не попадал, а тот, кто пришёл только
/// заплатить за прошлый визит, попадал. Отсюда и расхождение с
/// количеством диагнозов.
///
/// Считается один раз на случай, как и диагноз.
function daily_stats_count_exam(_case) {

    if (!is_struct(_case)) return false;

    if (
        variable_struct_exists(_case, "stats_exam_counted")
        && _case.stats_exam_counted
    ) {
        return false;
    }

    _case.stats_exam_counted = true;

    daily_stats_add("exams_done", 1);

    return true;
}


/// @function daily_stats_value(_key)
/// @description Значение счётчика или 0.
function daily_stats_value(_key) {

    if (!variable_global_exists("daily_stats")) return 0;
    if (!is_struct(global.daily_stats)) return 0;

    var _name = string(_key);

    if (!variable_struct_exists(global.daily_stats, _name)) return 0;

    var _value = variable_struct_get(global.daily_stats, _name);

    return is_real(_value) ? _value : 0;
}
