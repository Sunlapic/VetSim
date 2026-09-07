/// staff_salary_system.gml
/// @description Фиксированный оклад и просьбы о прибавке. Пакет №320.
///
/// ── Что было ──
///
/// Зарплата пересчитывалась от текущих навыков КАЖДУЮ полночь
/// (finance_payroll_add_object вызывал finance_refresh_staff_salary).
/// Обучать сотрудника было невыгодно: он сам себе поднимал оклад, а
/// нанять новичка выходило дешевле, чем растить своего.
///
/// ── Как стало ──
///
/// Оклад фиксируется в момент найма и дальше не меняется сам. Растёт
/// только по договорённости: сотрудник, прокачавший навыки, приходит
/// просить прибавку. Согласиться — платить больше; отказать — падает
/// лояльность, а после нескольких отказов он уходит.
///
/// Так выгоднее нанять одного и вложиться в него, чем перебирать
/// новичков — ровно то поведение, которое и задумывалось.


// ═══════════════════════════════════════════════════════════════
// 1. ПОЛЯ СОТРУДНИКА
// ═══════════════════════════════════════════════════════════════

/// @function staff_salary_init(_staff)
/// @description Заводит поля оклада и лояльности, если их ещё нет.
///
/// hire_skill_sum — сумма навыков на момент найма. По ней считается,
/// насколько человек вырос: сравнивать текущую зарплату с расчётной
/// ненадёжно, расчёт может измениться при правках баланса.
function staff_salary_init(_staff) {

    if (!instance_exists(_staff)) return false;

    with (_staff) {
        if (!variable_instance_exists(id, "salary")) {
            salary = 0;
        }

        if (!variable_instance_exists(id, "hire_skill_sum")) {
            hire_skill_sum = variable_instance_exists(id, "skills_sum")
                ? skills_sum
                : 0;
        }

        if (!variable_instance_exists(id, "staff_loyalty")) {
            staff_loyalty = 100;
        }

        if (!variable_instance_exists(id, "raise_refusals")) {
            raise_refusals = 0;
        }

        if (!variable_instance_exists(id, "raise_pending")) {
            raise_pending = false;
        }

        if (!variable_instance_exists(id, "raise_amount")) {
            raise_amount = 0;
        }

        if (!variable_instance_exists(id, "raise_check_day")) {
            raise_check_day = 0;
        }
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 2. НАСКОЛЬКО СОТРУДНИК ВЫРОС
// ═══════════════════════════════════════════════════════════════

/// @function staff_skill_growth(_staff)
/// @description Сколько уровней навыков набрано с момента найма.
function staff_skill_growth(_staff) {

    if (!instance_exists(_staff)) return 0;

    staff_salary_init(_staff);

    var _now = variable_instance_exists(_staff, "skills_sum")
        ? _staff.skills_sum
        : 0;

    return max(0, _now - _staff.hire_skill_sum);
}


/// @function staff_fair_salary(_staff)
/// @description Сколько сотрудник стоит по текущим навыкам.
function staff_fair_salary(_staff) {

    if (!instance_exists(_staff)) return 0;

    return finance_calculate_staff_salary(_staff);
}


// ═══════════════════════════════════════════════════════════════
// 3. ПРОСЬБА О ПРИБАВКЕ
// ═══════════════════════════════════════════════════════════════

/// @function staff_check_raise_request(_staff)
/// @description Раз в день проверяет, не пора ли просить прибавку.
///
/// Условия намеренно нежёсткие: сотрудник просит, только если вырос
/// заметно (три уровня суммарно) и текущий оклад отстаёт от честного
/// хотя бы на 15%. Иначе просьбы сыпались бы после каждого приёма.
function staff_check_raise_request(_staff) {

    if (!instance_exists(_staff)) return false;
    if (_staff.object_index == obj_player) return false;
    if (_staff.object_index == obj_staff_candidate) return false;

    staff_salary_init(_staff);

    // Уже просит — второй раз не спрашиваем.
    if (_staff.raise_pending) return false;

    // Не чаще одного раза в три дня.
    var _today = variable_global_exists("game_day") ? global.game_day : 0;

    if (_today - _staff.raise_check_day < 3) return false;

    _staff.raise_check_day = _today;

    if (staff_skill_growth(_staff) < 3) return false;

    var _fair = staff_fair_salary(_staff);
    var _now = _staff.salary;

    if (_now <= 0) return false;
    if (_fair < _now * 1.15) return false;

    // Просит не всю разницу сразу, а половину — так торг мягче.
    _staff.raise_amount = max(5, round((_fair - _now) * 0.5 / 5) * 5);
    _staff.raise_pending = true;

    return true;
}


/// @function staff_accept_raise(_staff)
/// @description Согласиться на прибавку.
function staff_accept_raise(_staff) {

    if (!instance_exists(_staff)) return false;

    staff_salary_init(_staff);

    if (!_staff.raise_pending) return false;

    _staff.salary += _staff.raise_amount;
    _staff.raise_pending = false;
    _staff.raise_amount = 0;
    _staff.raise_refusals = 0;

    // Новая точка отсчёта: следующая просьба — за следующий рост.
    _staff.hire_skill_sum = variable_instance_exists(_staff, "skills_sum")
        ? _staff.skills_sum
        : _staff.hire_skill_sum;

    _staff.staff_loyalty = min(100, _staff.staff_loyalty + 15);

    return true;
}


/// @function staff_refuse_raise(_staff)
/// @description Отказать. Возвращает true, если сотрудник уволился.
///
/// Каждый отказ бьёт по лояльности всё сильнее: первый −20, второй
/// −30, третий −40. Так первый отказ переживается спокойно, а
/// систематическая экономия на человеке заканчивается уходом.
function staff_refuse_raise(_staff) {

    if (!instance_exists(_staff)) return false;

    staff_salary_init(_staff);

    if (!_staff.raise_pending) return false;

    _staff.raise_pending = false;
    _staff.raise_amount = 0;
    _staff.raise_refusals += 1;

    var _hit = 20 + (_staff.raise_refusals - 1) * 10;

    _staff.staff_loyalty = max(0, _staff.staff_loyalty - _hit);

    // Три отказа подряд или обнулённая лояльность — увольняется.
    if (_staff.raise_refusals >= 3 || _staff.staff_loyalty <= 0) {
        return true;
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 4. ЕЖЕДНЕВНАЯ ПРОВЕРКА
// ═══════════════════════════════════════════════════════════════

/// @function staff_salary_daily_check()
/// @description Обходит персонал и собирает просьбы о прибавке.
///              Вызывается раз в игровой день.
function staff_salary_daily_check() {

    var _asked = 0;
    var _types = [obj_staff_doctor, obj_staff_assistant, obj_staff_admin];

    for (var _type_index = 0; _type_index < 3; _type_index++) {
        var _type = _types[_type_index];
        var _count = instance_number(_type);

        for (var _index = 0; _index < _count; _index++) {
            var _staff = instance_find(_type, _index);

            if (!instance_exists(_staff)) continue;
            if (_staff.object_index != _type) continue;

            if (staff_check_raise_request(_staff)) {
                _asked += 1;

                show_debug_message(
                    "[SALARY] "
                    + string(
                        variable_instance_exists(_staff, "char_name")
                            ? _staff.char_name
                            : "Сотрудник"
                    )
                    + " просит прибавку +"
                    + string(_staff.raise_amount)
                );
            }
        }
    }

    return _asked;
}


/// @function staff_find_raise_request()
/// @description Первый сотрудник, ожидающий ответа, или noone.
function staff_find_raise_request() {

    var _types = [obj_staff_doctor, obj_staff_assistant, obj_staff_admin];

    for (var _type_index = 0; _type_index < 3; _type_index++) {
        var _type = _types[_type_index];
        var _count = instance_number(_type);

        for (var _index = 0; _index < _count; _index++) {
            var _staff = instance_find(_type, _index);

            if (!instance_exists(_staff)) continue;
            if (!variable_instance_exists(_staff, "raise_pending")) continue;
            if (!_staff.raise_pending) continue;

            return _staff;
        }
    }

    return noone;
}
