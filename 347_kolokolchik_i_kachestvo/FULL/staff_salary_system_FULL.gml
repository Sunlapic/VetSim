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

        // ── ПАКЕТ 347: снимок уровней по каждому навыку на момент
        // найма. По нему в просьбе о прибавке называется конкретный
        // навык: «поднял навык ТЕРАПИЯ с 3 по 5 лвл».
        if (!variable_instance_exists(id, "hire_skills")
            || !is_array(hire_skills)
        ) {
            hire_skills = array_create(11, 1);

            if (variable_instance_exists(id, "skills") && is_array(skills)) {
                for (var _hi = 0; _hi < array_length(skills); _hi++) {
                    hire_skills[_hi] = skills[_hi];
                }
            }
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

    // ── ПАКЕТ 347: просьба попадает в общую очередь (колокольчик).
    //
    // Раньше запрос только писался в debug-лог — игрок никогда его
    // не видел. Теперь он ждёт ответа в панели колокольчика:
    // «Имя поднял навык ТЕРАПИЯ с 3 по 5 лвл, просит поднять
    // зарплату со 140 до 150. Одобрить? ДА / НЕТ».
    var _skill_info = staff_best_grown_skill(
        _staff.skills,
        _staff.hire_skills
    );

    staff_request_push(
        script_exists(asset_get_index("clinic_current_id"))
            ? clinic_current_id()
            : 1,
        string(_staff.char_name),
        _skill_info.name,
        _skill_info.from_lvl,
        _skill_info.to_lvl,
        _now,
        _staff.raise_amount
    );

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



// ═══════════════════════════════════════════════════════════
// ПАКЕТ №347. ОЧЕРЕДЬ ПРОСЬБ (КОЛОКОЛЬЧИК), НЕАКТИВНЫЕ КЛИНИКИ
// И МЕДЛЕННАЯ ПРОКАЧКА БЕЗ РАБОТЫ.
// ═══════════════════════════════════════════════════════════

// ─────────────────────────────────────────────
// Сколько пунктов опыта сотрудник неактивной клиники получает
// за день. Калибровка: у врача уровень стоит 30 + (лвл-1)*20
// пунктов. 24 пункта в день без работы — это «понемногу»:
// 2-й уровень приходит за полтора дня простоя, 10-й — за
// неделю-полторы. Пункты, не уровни: уровень даётся только
// когда пунктов накопилось достаточно.
// ─────────────────────────────────────────────
#macro STAFF_IDLE_XP_PER_DAY 24

function staff_idle_xp_needed(_level) {
    _level = clamp(round(real(_level)), 1, 10);
    if (_level >= 10) return 0;
    return 30 + ((_level - 1) * 20);
}


/// Навык врача, который растёт без работы: по рабочему месту.
/// Приём → терапия (0), хирург → хирургия (2), анестезиолог →
/// анестезиология (7), стационар → стационар (10).
function staff_doctor_idle_skill(_workplace_id, _operating_role) {
    switch (string(_workplace_id)) {
        case "operating":
            return (string(_operating_role) == "anesthetist") ? 7 : 2;
        case "inpatient":
            return 10;
        default:
            return 0;
    }
}


/// Сумма массива чисел (без array_sum — в проекте его нет).
function staff_array_sum(_values) {
    if (!is_array(_values)) return 0;
    var _sum = 0;
    for (var _i = 0; _i < array_length(_values); _i++) {
        _sum += real(_values[_i]);
    }
    return _sum;
}


/// Среднее по массиву уровней (1..10). Пустой массив → 1.
function staff_average_levels(_levels) {
    if (!is_array(_levels) || array_length(_levels) <= 0) return 1;
    var _sum = 0;
    for (var _i = 0; _i < array_length(_levels); _i++) {
        _sum += clamp(round(real(_levels[_i])), 1, 10);
    }
    return _sum / array_length(_levels);
}


/// Главный (профильный) уровень сотрудника — по роли.
/// Работает и с инстансом, и со снимком (структурой).
function staff_main_skill_average(_snap) {
    var _role = variable_struct_exists(_snap, "role")
        ? string(_snap.role)
        : "";

    if (_role == "admin") {
        if (variable_struct_exists(_snap, "skill_level")
            && is_array(_snap.skill_level)
        ) {
            return staff_average_levels(_snap.skill_level);
        }
    }
    else if (_role == "assistant") {
        if (variable_struct_exists(_snap, "assistant_skill_levels")
            && is_array(_snap.assistant_skill_levels)
            && array_length(_snap.assistant_skill_levels) > 0
        ) {
            return staff_average_levels(_snap.assistant_skill_levels);
        }
    }

    if (variable_struct_exists(_snap, "skills") && is_array(_snap.skills)) {
        return staff_average_levels(_snap.skills);
    }

    return 1;
}


/// Честная зарплата по формуле финансов, но для снимка (структуры).
/// finance_calculate_staff_salary работает только с инстансами,
/// поэтому формула продублирована здесь один в один.
function staff_salary_fair_snapshot(_snap) {
    var _role = variable_struct_exists(_snap, "role")
        ? string(_snap.role)
        : "";

    var _base = 120;
    var _professional_rate = 28;

    switch (_role) {
        case "admin":
            _base = 80;
            _professional_rate = 18;
        break;
        case "assistant":
            _base = 70;
            _professional_rate = 16;
        break;
    }

    var _professional = staff_main_skill_average(_snap);

    var _walk = variable_struct_exists(_snap, "walk_skill_level")
        ? clamp(real(_snap.walk_skill_level), 1, 10)
        : 1;
    var _stamina = variable_struct_exists(_snap, "stamina_level")
        ? clamp(real(_snap.stamina_level), 1, 10)
        : 1;

    var _salary = _base
        + _professional * _professional_rate
        + ((_walk + _stamina) * 0.5) * 4;

    return max(0, round(_salary / 5) * 5);
}


/// Какой навык вырос сильнее всего: { name, from_lvl, to_lvl }.
function staff_best_grown_skill(_skills, _hire_skills) {
    var _names = script_exists(asset_get_index("doctor_get_skill_names"))
        ? doctor_get_skill_names()
        : [];

    var _best_index = 0;
    var _best_growth = 0;

    if (is_array(_skills) && is_array(_hire_skills)) {
        var _len = min(array_length(_skills), array_length(_hire_skills));
        for (var _i = 0; _i < _len; _i++) {
            var _growth = real(_skills[_i]) - real(_hire_skills[_i]);
            if (_growth > _best_growth) {
                _best_growth = _growth;
                _best_index = _i;
            }
        }
    }

    var _to = (is_array(_skills) && array_length(_skills) > _best_index)
        ? clamp(round(real(_skills[_best_index])), 1, 10)
        : 1;
    var _from = max(1, _to - max(1, _best_growth));

    var _name = (_best_index < array_length(_names))
        ? string(_names[_best_index])
        : "НАВЫКИ";

    return {
        name: _name,
        from_lvl: _from,
        to_lvl: _to
    };
}


// ─────────────────────────────────────────────
// ОЧЕРЕДЬ ПРОСЬБ
// ─────────────────────────────────────────────
function staff_requests_init() {
    if (!variable_global_exists("staff_requests")
        || !is_array(global.staff_requests)
    ) {
        global.staff_requests = [];
        global.staff_requests_next_id = 1;
        global.staff_requests_unread = false;
    }
}


/// Добавить просьбу в очередь (колокольчик загорится красным).
function staff_request_push(
    _clinic_id,
    _staff_name,
    _skill_name,
    _from_lvl,
    _to_lvl,
    _old_salary,
    _amount
) {
    staff_requests_init();

    var _req = {
        id: real(global.staff_requests_next_id),
        clinic_id: real(_clinic_id),
        staff_name: string(_staff_name),
        skill_name: string(_skill_name),
        from_lvl: real(_from_lvl),
        to_lvl: real(_to_lvl),
        old_salary: real(_old_salary),
        amount: real(_amount),
        day: real(global.game_day),
        read: false
    };

    global.staff_requests_next_id = real(global.staff_requests_next_id) + 1;

    array_insert(global.staff_requests, 0, _req);
    global.staff_requests_unread = true;

    show_debug_message("ЗАРПЛАТА: " + _req.staff_name
        + " просит прибавку $" + string(_amount)
        + " (клиника " + string(_clinic_id) + ")");
}


/// Найти просьбу по id.
function staff_request_find(_req_id) {
    staff_requests_init();
    for (var _i = 0; _i < array_length(global.staff_requests); _i++) {
        if (global.staff_requests[_i].id == real(_req_id)) {
            return global.staff_requests[_i];
        }
    }
    return undefined;
}


/// Снять просьбу с очереди.
function staff_request_remove(_req_id) {
    staff_requests_init();
    for (var _i = array_length(global.staff_requests) - 1; _i >= 0; _i--) {
        if (global.staff_requests[_i].id == real(_req_id)) {
            array_delete(global.staff_requests, _i, 1);
            return;
        }
    }
}


/// Инстанс активного сотрудника по имени (для ответа на просьбу).
function staff_find_active_by_name(_name) {
    _name = string(_name);
    var _objs = [obj_staff_doctor, obj_staff_assistant, obj_staff_admin];

    for (var _o = 0; _o < array_length(_objs); _o++) {
        with (_objs[_o]) {
            if (variable_instance_exists(id, "char_name")
                && string(char_name) == _name
            ) {
                return id;
            }
        }
    }

    return noone;
}


/// Снимок сотрудника неактивной клиники по имени.
function staff_snapshot_find(_clinic_id, _name) {
    _name = string(_name);

    if (!variable_global_exists("clinics")) return undefined;
    if (!script_exists(asset_get_index("clinic_state_get"))) return undefined;

    var _owned = false;
    for (var _c = 0; _c < array_length(global.clinics); _c++) {
        if (global.clinics[_c].id == real(_clinic_id)
            && global.clinics[_c].owned
        ) {
            _owned = true;
            break;
        }
    }
    if (!_owned) return undefined;

    var _state = clinic_state_get(real(_clinic_id));
    if (!variable_struct_exists(_state, "staff")) return undefined;

    for (var _i = 0; _i < array_length(_state.staff); _i++) {
        if (variable_struct_exists(_state.staff[_i], "char_name")
            && string(_state.staff[_i].char_name) == _name
        ) {
            return _state.staff[_i];
        }
    }

    return undefined;
}


/// Ответить на просьбу: _accept — одобрить или отказать.
/// Возвращает true, если сотрудник уволился после отказа.
function staff_request_resolve(_req_id, _accept) {
    var _req = staff_request_find(_req_id);
    if (_req == undefined) return false;

    staff_request_remove(_req_id);

    var _is_current = script_exists(asset_get_index("clinic_current_id"))
        && (real(_req.clinic_id) == clinic_current_id());

    // ── Активная клиника: работаем с инстансом. ──
    if (_is_current) {
        var _staff = staff_find_active_by_name(_req.staff_name);
        if (!instance_exists(_staff)) return false;

        if (_accept) {
            staff_accept_raise(_staff);
            return false;
        }

        var _quit = staff_refuse_raise(_staff);

        if (_quit) {
            // Как в панели управления персоналом при увольнении.
            with (_staff) {
                instance_destroy();
            }
        }

        return _quit;
    }

    // ── Неактивная клиника: работаем со снимком. ──
    var _snap = staff_snapshot_find(_req.clinic_id, _req.staff_name);
    if (_snap == undefined) return false;

    _snap.raise_pending = false;

    if (_accept) {
        _snap.salary = real(_snap.salary) + real(_req.amount);
        _snap.staff_loyalty = min(100, real(_snap.staff_loyalty) + 15);
        _snap.raise_refusals = 0;
        _snap.hire_skill_sum = real(_snap.skills_sum);
        return false;
    }

    var _refusals = real(_snap.raise_refusals);
    _snap.staff_loyalty = max(0,
        real(_snap.staff_loyalty) - 20 * (_refusals + 1));
    _snap.raise_refusals = _refusals + 1;

    // Три отказа подряд или обнулённая лояльность — увольняется.
    if (_snap.raise_refusals >= 3 || _snap.staff_loyalty <= 0) {
        var _state = clinic_state_get(real(_req.clinic_id));
        for (var _i = array_length(_state.staff) - 1; _i >= 0; _i--) {
            if (string(_state.staff[_i].char_name)
                == string(_req.staff_name)
            ) {
                array_delete(_state.staff, _i, 1);
                break;
            }
        }
        return true;
    }

    return false;
}


/// Раз в день: просьбы старше 3 дней отклоняются сами
/// (со штрафом к лояльности, как при обычном отказе).
function staff_requests_expire() {
    staff_requests_init();

    var _day = real(global.game_day);

    for (var _i = array_length(global.staff_requests) - 1; _i >= 0; _i--) {
        var _req = global.staff_requests[_i];
        if (_req.day + 3 <= _day) {
            staff_request_resolve(_req.id, false);
        }
    }
}


// ─────────────────────────────────────────────
// ПРОКАЧКА СОТРУДНИКОВ НЕАКТИВНЫХ КЛИНИК
// ─────────────────────────────────────────────

/// Дать снимку пункты опыта в нужный навык и поднять уровень,
/// если пунктов хватило. Возвращает true, если был рост уровня.
function staff_snapshot_grow_idle(_snap) {
    var _role = variable_struct_exists(_snap, "role")
        ? string(_snap.role)
        : "";

    // ── Врач: навык по рабочему месту. ──
    if (_role == "doctor") {
        if (!variable_struct_exists(_snap, "skills")
            || !is_array(_snap.skills)
            || array_length(_snap.skills) < 11
        ) {
            return false;
        }

        if (!variable_struct_exists(_snap, "skill_xp")
            || !is_array(_snap.skill_xp)
        ) {
            _snap.skill_xp = array_create(array_length(_snap.skills), 0);
        }
        while (array_length(_snap.skill_xp) < array_length(_snap.skills)) {
            array_push(_snap.skill_xp, 0);
        }

        var _idx = staff_doctor_idle_skill(
            variable_struct_exists(_snap, "workplace_id")
                ? _snap.workplace_id : "reception",
            variable_struct_exists(_snap, "operating_role")
                ? _snap.operating_role : ""
        );

        if (real(_snap.skills[_idx]) >= 10) return false;

        _snap.skill_xp[_idx] = real(_snap.skill_xp[_idx])
            + STAFF_IDLE_XP_PER_DAY;

        var _grew = false;
        var _needed = staff_idle_xp_needed(_snap.skills[_idx]);

        while (_needed > 0 && real(_snap.skill_xp[_idx]) >= _needed) {
            _snap.skill_xp[_idx] = real(_snap.skill_xp[_idx]) - _needed;
            _snap.skills[_idx] = real(_snap.skills[_idx]) + 1;
            _grew = true;

            if (real(_snap.skills[_idx]) >= 10) {
                _snap.skill_xp[_idx] = 0;
                break;
            }

            _needed = staff_idle_xp_needed(_snap.skills[_idx]);
        }

        _snap.skills_sum = staff_array_sum(_snap.skills);
        return _grew;
    }

    // ── Ассистент: процедуры. ──
    if (_role == "assistant") {
        if (!variable_struct_exists(_snap, "assistant_skill_levels")
            || !is_array(_snap.assistant_skill_levels)
            || array_length(_snap.assistant_skill_levels) <= 0
        ) {
            return false;
        }

        if (!variable_struct_exists(_snap, "assistant_skill_xp")
            || !is_array(_snap.assistant_skill_xp)
        ) {
            _snap.assistant_skill_xp =
                array_create(array_length(_snap.assistant_skill_levels), 0);
        }
        while (array_length(_snap.assistant_skill_xp)
            < array_length(_snap.assistant_skill_levels)
        ) {
            array_push(_snap.assistant_skill_xp, 0);
        }

        if (real(_snap.assistant_skill_levels[0]) >= 10) return false;

        _snap.assistant_skill_xp[0] = real(_snap.assistant_skill_xp[0])
            + STAFF_IDLE_XP_PER_DAY;

        var _grew2 = false;
        var _needed2 = staff_idle_xp_needed(_snap.assistant_skill_levels[0]);

        while (_needed2 > 0
            && real(_snap.assistant_skill_xp[0]) >= _needed2
        ) {
            _snap.assistant_skill_xp[0] =
                real(_snap.assistant_skill_xp[0]) - _needed2;
            _snap.assistant_skill_levels[0] =
                real(_snap.assistant_skill_levels[0]) + 1;
            _grew2 = true;

            if (real(_snap.assistant_skill_levels[0]) >= 10) {
                _snap.assistant_skill_xp[0] = 0;
                break;
            }

            _needed2 = staff_idle_xp_needed(_snap.assistant_skill_levels[0]);
        }

        if (variable_struct_exists(_snap, "skills_sum")) {
            _snap.skills_sum = real(_snap.skills_sum) + (_grew2 ? 1 : 0);
        }

        return _grew2;
    }

    // ── Админ: регистрация. ──
    if (_role == "admin") {
        if (!variable_struct_exists(_snap, "skill_level")
            || !is_array(_snap.skill_level)
            || array_length(_snap.skill_level) <= 0
        ) {
            return false;
        }

        if (!variable_struct_exists(_snap, "skill_xp")
            || !is_array(_snap.skill_xp)
        ) {
            _snap.skill_xp = array_create(array_length(_snap.skill_level), 0);
        }
        while (array_length(_snap.skill_xp) < array_length(_snap.skill_level)) {
            array_push(_snap.skill_xp, 0);
        }

        if (real(_snap.skill_level[0]) >= 10) return false;

        _snap.skill_xp[0] = real(_snap.skill_xp[0]) + STAFF_IDLE_XP_PER_DAY;

        var _grew3 = false;
        var _needed3 = staff_idle_xp_needed(_snap.skill_level[0]);

        while (_needed3 > 0 && real(_snap.skill_xp[0]) >= _needed3) {
            _snap.skill_xp[0] = real(_snap.skill_xp[0]) - _needed3;
            _snap.skill_level[0] = real(_snap.skill_level[0]) + 1;
            _grew3 = true;

            if (real(_snap.skill_level[0]) >= 10) {
                _snap.skill_xp[0] = 0;
                break;
            }

            _needed3 = staff_idle_xp_needed(_snap.skill_level[0]);
        }

        _snap.skills_sum = staff_array_sum(_snap.skill_level);
        return _grew3;
    }

    return false;
}


/// Просьба о прибавке от сотрудника неактивной клиники.
/// Условия те же, что у активных: рост ≥3 уровней и честный
/// оклад выше текущего хотя бы на 15%.
function staff_snapshot_check_raise(_clinic_id, _snap) {
    if (variable_struct_exists(_snap, "raise_pending") && _snap.raise_pending) {
        return;
    }

    var _day = real(global.game_day);
    var _check_day = variable_struct_exists(_snap, "raise_check_day")
        ? real(_snap.raise_check_day)
        : 0;

    if (_day - _check_day < 3) return;

    _snap.raise_check_day = _day;

    var _salary = variable_struct_exists(_snap, "salary")
        ? real(_snap.salary)
        : 0;
    if (_salary <= 0) return;

    var _growth = real(_snap.skills_sum) - real(_snap.hire_skill_sum);
    if (_growth < 3) return;

    var _fair = staff_salary_fair_snapshot(_snap);
    if (_fair < _salary * 1.15) return;

    var _amount = max(5, round((_fair - _salary) * 0.5 / 5) * 5);

    _snap.raise_pending = true;
    _snap.raise_amount = _amount;

    var _skill_info = staff_best_grown_skill(
        variable_struct_exists(_snap, "skills") ? _snap.skills : [],
        variable_struct_exists(_snap, "hire_skills") ? _snap.hire_skills : []
    );

    staff_request_push(
        _clinic_id,
        string(_snap.char_name),
        _skill_info.name,
        _skill_info.from_lvl,
        _skill_info.to_lvl,
        _salary,
        _amount
    );
}


/// Раз в день: прокачка и просьбы сотрудников неактивных клиник.
function staff_idle_daily_tick() {
    if (!variable_global_exists("clinics")) return;
    if (!script_exists(asset_get_index("clinic_state_get"))) return;

    for (var _i = 0; _i < array_length(global.clinics); _i++) {
        var _clinic = global.clinics[_i];

        if (!_clinic.owned || _clinic.id == clinic_current_id()) {
            continue;
        }

        var _state = clinic_state_get(_clinic.id);
        if (!variable_struct_exists(_state, "staff")) continue;

        for (var _s = 0; _s < array_length(_state.staff); _s++) {
            var _snap = _state.staff[_s];

            staff_snapshot_grow_idle(_snap);
            staff_snapshot_check_raise(_clinic.id, _snap);
        }
    }
}
