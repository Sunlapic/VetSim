function case_create_from_disease(_disease_id, _species_id) {
    if (!variable_struct_exists(global.med_db.diseases, _disease_id)) {
        return undefined;
    }

    // ═══════════════════════════════════════════════════════════════
    // ТЯЖЕСТЬ СЛУЧАЯ
    //
    // Было: тяжесть выбиралась чистым irandom_range(1, 4) — по 25% на
    // каждую, без всякой связи с болезнью. Из-за этого блохи могли
    // приехать критическими, а заворот желудка — лёгким.
    //
    // Стало: тяжесть привязана к сложности болезни. Поле difficulty
    // уже есть у всех 50 болезней в db_init_diseases, придумывать
    // ничего не пришлось — берём готовое.
    //
    // Случайность сохранена, но в разумных пределах: болезнь задаёт
    // ОПОРНУЮ тяжесть, а разброс сдвигает её максимум на шаг в любую
    // сторону. Ринит останется лёгким или средним, но критическим уже
    // не станет; сепсис не придёт лёгким.
    // ═══════════════════════════════════════════════════════════════

    // Читаем через variable_struct_get — так сделано во всём проекте
    // (clinic_case_gate, handbook_system и другие).
    var _disease_ref = variable_struct_get(global.med_db.diseases, _disease_id);

    var _difficulty = 5;

    if (is_struct(_disease_ref) && variable_struct_exists(_disease_ref, "difficulty")) {
        _difficulty = clamp(_disease_ref.difficulty, 1, 10);
    }

    // difficulty 2-3 → лёгкое, 4-5 → среднее, 6-7 → тяжёлое, 8+ → критическое.
    var _severity_base = 1;

    if (_difficulty >= 8)      _severity_base = 4;
    else if (_difficulty >= 6) _severity_base = 3;
    else if (_difficulty >= 4) _severity_base = 2;
    else                       _severity_base = 1;

    // Разброс на один шаг. Веса подобраны так, чтобы опорная тяжесть
    // оставалась самой частой: примерно 20% легче, 60% как задумано,
    // 20% тяжелее.
    var _roll = irandom_range(1, 10);
    var _shift = 0;

    if (_roll <= 2)      _shift = -1;
    else if (_roll >= 9) _shift = 1;

    var _severity_level = clamp(_severity_base + _shift, 1, 4);

    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ №311: БЕЗ СТАЦИОНАРА НЕ БЫВАЕТ ТЯЖЁЛЫХ ПАЦИЕНТОВ
    //
    // Пациент с состоянием ниже 50% должен лечь в палату
    // (inpatient_can_admit). Если коек в клинике нет, он остаётся на
    // амбулаторном приёме, где курс идёт по одному применению за
    // визит — и выздоровление растягивается на десяток приходов.
    //
    // Гейт clinic_case_gate уже не выдаёт болезни, которые без
    // стационара не вылечить. Но тяжесть выбирается отдельно, кубиком
    // выше: лёгкая болезнь могла выпасть в тяжёлой форме и дать 40%.
    //
    // Поэтому в клинике без коек тяжесть ограничивается вторым
    // уровнем — «среднее», нижняя граница 58%. Порог 50 берётся из
    // inpatient_can_admit, запас в 8 пунктов — на просадку состояния,
    // пока владелец ждёт в очереди.
    // ═══════════════════════════════════════════════════════════════

    var _stationary_ready = true;

    if (script_exists(asset_get_index("clinic_case_stationary_ready"))) {
        _stationary_ready = clinic_case_stationary_ready();
    }

    if (!_stationary_ready) {
        _severity_level = min(_severity_level, 2);
    }

    var _severity_name_ru = "Среднее";
    var _base_condition = 70;

    // ═══════════════════════════════════════════════════════════════
    // СТАРТОВОЕ СОСТОЯНИЕ
    //
    // Главное изменение: ПОТОЛОК 85 вместо 100.
    //
    // Раньше лёгкий случай давал irandom_range(80, 100) — то есть
    // животное могло приехать уже стопроцентно здоровым, примерно
    // один визит из восьмидесяти. Теперь выше 85 состояние на входе
    // не поднимается никогда, при любой тяжести.
    //
    // Запас в 15% — это гарантия, что даже самый лёгкий случай
    // требует работы: одна процедура ассистента даёт +5...+8, значит
    // до сотни без него не дотянуть.
    // ═══════════════════════════════════════════════════════════════

    switch (_severity_level) {
        case 1:
            _severity_name_ru = "Лёгкое";
            _base_condition = irandom_range(72, 85);
        break;

        case 2:
            _severity_name_ru = "Среднее";
            _base_condition = irandom_range(58, 71);
        break;

        case 3:
            _severity_name_ru = "Тяжёлое";
            _base_condition = irandom_range(40, 57);
        break;

        case 4:
            _severity_name_ru = "Критическое";
            _base_condition = irandom_range(20, 39);
        break;
    }

    var _visible = case_build_visible_symptoms(_disease_id);

    var _planned_treatment = [];

    for (var i = 0; i < array_length(global.med_db.disease_treatment); i++) {
        var _step = global.med_db.disease_treatment[i];

        if (_step.disease_id != _disease_id) continue;

        array_push(_planned_treatment, {
            action_id : _step.action_id,
            count : variable_struct_exists(_step, "count") ? _step.count : 1,
            days : variable_struct_exists(_step, "days") ? _step.days : 1,
            reveal_level : variable_struct_exists(_step, "reveal_level") ? _step.reveal_level : 0,
            required : variable_struct_exists(_step, "required") ? _step.required : false,
            severity_or_condition : variable_struct_exists(_step, "severity_or_condition") ? _step.severity_or_condition : "any",
            notes : variable_struct_exists(_step, "notes") ? _step.notes : "",
            repeat_until_recovered : variable_struct_exists(_step, "repeat_until_recovered") ? _step.repeat_until_recovered : false,
            per_visit_limit : variable_struct_exists(_step, "per_visit_limit") ? _step.per_visit_limit : 1
        });
    }

    return {
        case_id : db_next_case_id(),
        animal_species : _species_id,
        hidden_disease_id : _disease_id,

        visible_symptoms : _visible,
        reveal_level : 0,
        confirmed : false,

        completed_diagnostics : [],
        treatment_progress : [],
        planned_treatment : _planned_treatment,

        visit_diagnostics_done : [],
        visit_treatments_done : [],
        visit_procedure_log : [],

        visit_treatment_feedback_ok_ids : [],
        visit_treatment_feedback_bad_ids : [],

        severity_level : _severity_level,
        severity_name_ru : _severity_name_ru,

        initial_condition : _base_condition,
        condition : _base_condition,

        owner_trust : 60,
        case_status : "new"
    };
}