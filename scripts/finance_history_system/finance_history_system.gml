/// finance_history_system.gml
/// @description Пакет №287. История финансов по дням.
///
/// Что хранится: за каждый закрытый день — доход по трём отделениям
/// (приём / стационар / операционная), расходы (зарплата и закупки),
/// баланс на конец дня и итог дня.
///
/// Глубина — 30 дней, ровно месяц игрового календаря. Записи старше
/// вытесняются: массив не растёт бесконечно, и сейв не пухнет.
///
/// ВАЖНО о точке съёма. День закрывается в полночь, в obj_Render/Step.
/// Там же вызывается daily_stats_reset_now(), которая обнуляет и
/// global.daily_stats, и global.finance_income_by_dept. Снимок нужно
/// снять ДО обнуления, поэтому finance_history_close_day() вызывается
/// внутри daily_stats_reset_now() первой строкой — так одна точка
/// обслуживает оба пути сброса (обычный и отложенный из пакета 211).


// ═══════════════════════════════════════════════════════════════
// 1. ХРАНИЛИЩЕ
// ═══════════════════════════════════════════════════════════════

#macro FINANCE_HISTORY_MAX_DAYS 30

/// Массив истории. Идемпотентна: существующие данные не затирает.
function finance_history_init() {
    if (
        !variable_global_exists("finance_history")
        || !is_array(global.finance_history)
    ) {
        global.finance_history = [];
    }

    return global.finance_history;
}

/// Пустая запись дня — единая форма для всех потребителей.
function finance_history_blank_record(_day) {
    return {
        day : _day,
        reception : 0,
        inpatient : 0,
        operating : 0,
        income : 0,
        salary : 0,
        purchases : 0,
        expense : 0,
        profit : 0,
        balance_end : 0,
        visits : 0
    };
}


// ═══════════════════════════════════════════════════════════════
// 2. ЗАКРЫТИЕ ДНЯ
// ═══════════════════════════════════════════════════════════════

/// Снять снимок уходящего дня и положить в историю.
///
/// Вызывается ИЗ daily_stats_reset_now() до обнуления счётчиков.
/// Повторный вызов за тот же день не создаёт дубль — запись
/// обновляется на месте (страховка на случай двойного сброса).
function finance_history_close_day() {
    finance_history_init();

    var _day = variable_global_exists("game_day") ? global.game_day : 0;

    // Доход по отделениям берём напрямую из структуры, а НЕ через
    // finance_income_stats(): та функция сама обнуляет графы, если
    // global.game_day уже сменился, а в полночь он именно сменился.
    var _reception = 0;
    var _inpatient = 0;
    var _operating = 0;
    var _stats_day = _day;

    if (
        variable_global_exists("finance_income_by_dept")
        && is_struct(global.finance_income_by_dept)
    ) {
        var _dept = global.finance_income_by_dept;

        if (variable_struct_exists(_dept, "reception")) {
            _reception = _dept.reception;
        }

        if (variable_struct_exists(_dept, "inpatient")) {
            _inpatient = _dept.inpatient;
        }

        if (variable_struct_exists(_dept, "operating")) {
            _operating = _dept.operating;
        }

        // Графы помнят, за какой день они набраны. В полночь game_day
        // уже увеличился, поэтому закрываем именно день из структуры.
        if (variable_struct_exists(_dept, "day")) {
            _stats_day = _dept.day;
        }
    }

    var _earned = 0;
    var _spent = 0;
    var _salary = 0;
    var _visits = 0;

    if (variable_global_exists("daily_stats") && is_struct(global.daily_stats)) {
        var _ds = global.daily_stats;

        if (variable_struct_exists(_ds, "earned_money")) {
            _earned = _ds.earned_money;
        }

        if (variable_struct_exists(_ds, "spent_money")) {
            _spent = _ds.spent_money;
        }

        if (variable_struct_exists(_ds, "salary_expense")) {
            _salary = _ds.salary_expense;
        }

        if (variable_struct_exists(_ds, "paid_visits")) {
            _visits = _ds.paid_visits;
        }
    }

    var _record = finance_history_blank_record(_stats_day);

    _record.reception = round(_reception);
    _record.inpatient = round(_inpatient);
    _record.operating = round(_operating);

    // Доход берём из daily_stats: это фактически полученные деньги.
    // Сумма по отделениям может отличаться на копейки округления.
    _record.income = round(_earned);

    _record.salary = round(_salary);
    _record.purchases = max(0, round(_spent - _salary));
    _record.expense = round(_spent);
    _record.profit = round(_earned - _spent);
    _record.visits = _visits;

    _record.balance_end = variable_global_exists("clinic_money")
        ? round(global.clinic_money)
        : 0;

    // Пустой день тоже записываем: провал в графике — тоже информация.
    // Но день без единого события в самом начале игры не пишем, иначе
    // история заполнится нулями ещё до первого пациента.
    var _has_anything = (
        _record.income != 0
        || _record.expense != 0
        || _record.visits != 0
    );

    var _history = global.finance_history;
    var _count = array_length(_history);

    if (!_has_anything && _count == 0) {
        return false;
    }

    // Тот же день уже закрыт — обновляем запись, а не плодим дубли.
    if (_count > 0) {
        var _last = _history[_count - 1];

        if (is_struct(_last) && _last.day == _record.day) {
            _history[_count - 1] = _record;
            return true;
        }
    }

    array_push(_history, _record);

    // Вытесняем самые старые дни.
    while (array_length(_history) > FINANCE_HISTORY_MAX_DAYS) {
        array_delete(_history, 0, 1);
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. ЧТЕНИЕ
// ═══════════════════════════════════════════════════════════════

/// Вся история, новые дни в конце.
function finance_history_get() {
    return finance_history_init();
}

/// Текущий, ещё не закрытый день — как запись того же формата.
/// Показывается в таблице первой строкой с пометкой «сегодня».
function finance_history_today_record() {
    var _day = variable_global_exists("game_day") ? global.game_day : 0;
    var _record = finance_history_blank_record(_day);

    if (
        variable_global_exists("finance_income_by_dept")
        && is_struct(global.finance_income_by_dept)
    ) {
        var _dept = global.finance_income_by_dept;

        // Графы отделений могли остаться от вчера, если сегодня ещё
        // никто не платил. Показываем их только для текущего дня.
        var _dept_day = variable_struct_exists(_dept, "day")
            ? _dept.day
            : _day;

        if (_dept_day == _day) {
            if (variable_struct_exists(_dept, "reception")) {
                _record.reception = round(_dept.reception);
            }

            if (variable_struct_exists(_dept, "inpatient")) {
                _record.inpatient = round(_dept.inpatient);
            }

            if (variable_struct_exists(_dept, "operating")) {
                _record.operating = round(_dept.operating);
            }
        }
    }

    if (variable_global_exists("daily_stats") && is_struct(global.daily_stats)) {
        var _ds = global.daily_stats;

        var _earned = variable_struct_exists(_ds, "earned_money")
            ? _ds.earned_money
            : 0;
        var _spent = variable_struct_exists(_ds, "spent_money")
            ? _ds.spent_money
            : 0;
        var _salary = variable_struct_exists(_ds, "salary_expense")
            ? _ds.salary_expense
            : 0;

        _record.income = round(_earned);
        _record.salary = round(_salary);
        _record.purchases = max(0, round(_spent - _salary));
        _record.expense = round(_spent);
        _record.profit = round(_earned - _spent);

        if (variable_struct_exists(_ds, "paid_visits")) {
            _record.visits = _ds.paid_visits;
        }
    }

    _record.balance_end = variable_global_exists("clinic_money")
        ? round(global.clinic_money)
        : 0;

    return _record;
}

/// Итоги за последние _days дней (сегодня не считается — он не закрыт).
function finance_history_totals(_days) {
    var _history = finance_history_init();
    var _count = array_length(_history);
    var _from = max(0, _count - _days);

    var _totals = finance_history_blank_record(0);
    _totals.balance_end = 0;

    for (var _i = _from; _i < _count; _i++) {
        var _rec = _history[_i];

        if (!is_struct(_rec)) continue;

        _totals.reception += _rec.reception;
        _totals.inpatient += _rec.inpatient;
        _totals.operating += _rec.operating;
        _totals.income += _rec.income;
        _totals.salary += _rec.salary;
        _totals.purchases += _rec.purchases;
        _totals.expense += _rec.expense;
        _totals.profit += _rec.profit;
        _totals.visits += _rec.visits;
    }

    return _totals;
}

/// Наибольший модуль дохода/расхода за период — для масштаба графика.
function finance_history_peak(_records) {
    var _peak = 1;

    for (var _i = 0; _i < array_length(_records); _i++) {
        var _rec = _records[_i];

        if (!is_struct(_rec)) continue;

        _peak = max(_peak, abs(_rec.income), abs(_rec.expense));
    }

    return _peak;
}


// ═══════════════════════════════════════════════════════════════
// 4. СОХРАНЕНИЕ
// ═══════════════════════════════════════════════════════════════

/// История в виде простого массива структур — прямо в сейв.
function finance_history_to_save() {
    var _history = finance_history_init();
    var _out = [];

    for (var _i = 0; _i < array_length(_history); _i++) {
        var _rec = _history[_i];

        if (!is_struct(_rec)) continue;

        array_push(_out, {
            day : _rec.day,
            reception : _rec.reception,
            inpatient : _rec.inpatient,
            operating : _rec.operating,
            income : _rec.income,
            salary : _rec.salary,
            purchases : _rec.purchases,
            expense : _rec.expense,
            profit : _rec.profit,
            balance_end : _rec.balance_end,
            visits : _rec.visits
        });
    }

    return _out;
}

/// Восстановить историю из сейва. Старые сохранения без этого ключа
/// просто дают пустую историю — версия формата не поднимается.
function finance_history_from_save(_array) {
    finance_history_init();

    if (!is_array(_array)) return false;

    var _history = [];

    for (var _i = 0; _i < array_length(_array); _i++) {
        var _src = _array[_i];

        if (!is_struct(_src)) continue;

        var _rec = finance_history_blank_record(
            variable_struct_exists(_src, "day") ? _src.day : 0
        );

        var _keys = [
            "reception",
            "inpatient",
            "operating",
            "income",
            "salary",
            "purchases",
            "expense",
            "profit",
            "balance_end",
            "visits"
        ];

        for (var _k = 0; _k < array_length(_keys); _k++) {
            var _key = _keys[_k];

            if (variable_struct_exists(_src, _key)) {
                var _value = variable_struct_get(_src, _key);

                if (is_real(_value)) {
                    variable_struct_set(_rec, _key, _value);
                }
            }
        }

        array_push(_history, _rec);
    }

    while (array_length(_history) > FINANCE_HISTORY_MAX_DAYS) {
        array_delete(_history, 0, 1);
    }

    global.finance_history = _history;

    return true;
}
