/// case_get_visible_diagnostics(_case, _therapy_level)
/// @description Смесь правильных и ложных обследований с учётом уровня Терапии.

function case_get_visible_diagnostics(_case, _therapy_level = 1) {
    var _result = [];

    if (!is_struct(_case)) return _result;

    _therapy_level = clamp(round(_therapy_level), 1, 10);


    // ═══════════════════════════════════════════════════════════
    // 1. ЛОКАЛЬНЫЕ ПОМОЩНИКИ
    // ═══════════════════════════════════════════════════════════

    function contains_id(_array, _id) {
        for (var _index = 0; _index < array_length(_array); _index++) {
            if (_array[_index] == _id) return true;
        }

        return false;
    }

    function stable_choice_score(_seed, _choice_id) {
        var _text = _seed + "|" + _choice_id;
        var _score = 17;

        for (var _char_index = 1; _char_index <= string_length(_text); _char_index++) {
            var _char_code = ord(string_copy(_text, _char_index, 1));
            _score = (_score * 131 + _char_code + _char_index * 17) mod 2147483647;
        }

        return _score;
    }

    // В обследованиях максимум два ложных варианта.
    function wrong_count_for_level(_level) {
        switch (_level) {
            case 1:  return 2;
            case 2:  return 2;
            case 3:  return 2;
            case 4:  return 2;
            case 5:  return 2;
            case 6:  return 1;
            case 7:  return 1;
            case 8:  return 1;
            case 9:  return 1;
            case 10: return 0;
        }

        return 2;
    }

    function sort_choices_by_score(_choices) {
        for (var _left = 0; _left < array_length(_choices) - 1; _left++) {
            for (var _right = _left + 1; _right < array_length(_choices); _right++) {
                if (_choices[_right].sort_score < _choices[_left].sort_score) {
                    var _temporary = _choices[_left];
                    _choices[_left] = _choices[_right];
                    _choices[_right] = _temporary;
                }
            }
        }

        return _choices;
    }

    function has_feedback(_case_struct, _field_name, _diagnostic_id) {
        if (!variable_struct_exists(_case_struct, _field_name)) return false;

        var _feedback_ids = variable_struct_get(_case_struct, _field_name);

        for (var _index = 0; _index < array_length(_feedback_ids); _index++) {
            if (_feedback_ids[_index] == _diagnostic_id) return true;
        }

        return false;
    }


    // ═══════════════════════════════════════════════════════════
    // 2. ДИАГНОСТИКИ ТЕКУЩЕЙ БОЛЕЗНИ
    // ═══════════════════════════════════════════════════════════

    var _correct_choices = [];
    var _wrong_candidates = [];
    var _disease_diagnostic_ids = [];

    for (var _link_index = 0; _link_index < array_length(global.med_db.disease_diagnostics); _link_index++) {
        var _link = global.med_db.disease_diagnostics[_link_index];

        if (_link.disease_id != _case.hidden_disease_id) continue;
        if (!variable_struct_exists(global.med_db.diagnostics, _link.diagnostic_id)) continue;

        if (!contains_id(_disease_diagnostic_ids, _link.diagnostic_id)) {
            array_push(_disease_diagnostic_ids, _link.diagnostic_id);
        }

        var _shown_as_completed = has_feedback(
            _case,
            "visit_diagnostic_feedback_ok_ids",
            _link.diagnostic_id
        );

        // Выполненное в прошлом визите обследование не показываем.
        // Выполненное прямо сейчас оставляем зелёным до конца текущего визита.
        if (case_has_diagnostic(_case, _link.diagnostic_id) && !_shown_as_completed) {
            continue;
        }

        array_push(_correct_choices, {
            diagnostic_id : _link.diagnostic_id,
            is_correct : true,
            required_to_confirm : variable_struct_exists(_link, "required_to_confirm")
                ? _link.required_to_confirm
                : false,
            priority : variable_struct_exists(_link, "priority") ? _link.priority : 0,
            sort_score : 0
        });
    }


    // ═══════════════════════════════════════════════════════════
    // 3. ЛОЖНЫЕ ОБСЛЕДОВАНИЯ
    // ═══════════════════════════════════════════════════════════

    for (var _diagnostic_index = 0; _diagnostic_index < array_length(global.med_db.diagnostic_ids); _diagnostic_index++) {
        var _diagnostic_id = global.med_db.diagnostic_ids[_diagnostic_index];

        // Первичный осмотр выполняется автоматически и не используется как приманка.
        if (_diagnostic_id == "diag_physical_exam") continue;
        if (contains_id(_disease_diagnostic_ids, _diagnostic_id)) continue;
        if (!variable_struct_exists(global.med_db.diagnostics, _diagnostic_id)) continue;

        array_push(_wrong_candidates, {
            diagnostic_id : _diagnostic_id,
            is_correct : false,
            required_to_confirm : false,
            priority : 0,
            sort_score : 0
        });
    }


    // ═══════════════════════════════════════════════════════════
    // 4. СТАБИЛЬНОЕ РАВНОМЕРНОЕ ПЕРЕМЕШИВАНИЕ
    // ═══════════════════════════════════════════════════════════

    var _case_seed = variable_struct_exists(_case, "case_id")
        ? string(_case.case_id)
        : string(_case.hidden_disease_id);

    _case_seed += "|diagnostic|" + string(_therapy_level);

    for (var _correct_score_index = 0; _correct_score_index < array_length(_correct_choices); _correct_score_index++) {
        _correct_choices[_correct_score_index].sort_score = stable_choice_score(
            _case_seed,
            _correct_choices[_correct_score_index].diagnostic_id
        );
    }

    for (var _wrong_score_index = 0; _wrong_score_index < array_length(_wrong_candidates); _wrong_score_index++) {
        _wrong_candidates[_wrong_score_index].sort_score = stable_choice_score(
            _case_seed,
            _wrong_candidates[_wrong_score_index].diagnostic_id
        );
    }

    _wrong_candidates = sort_choices_by_score(_wrong_candidates);

    for (var _push_correct = 0; _push_correct < array_length(_correct_choices); _push_correct++) {
        array_push(_result, _correct_choices[_push_correct]);
    }

    var _wrong_limit = wrong_count_for_level(_therapy_level);
    var _free_slots = max(0, 4 - array_length(_result));
    var _wrong_needed = min(_wrong_limit, _free_slots);

    for (var _push_wrong = 0; _push_wrong < _wrong_needed; _push_wrong++) {
        if (_push_wrong >= array_length(_wrong_candidates)) break;
        array_push(_result, _wrong_candidates[_push_wrong]);
    }

    while (array_length(_result) > 4) {
        array_delete(_result, array_length(_result) - 1, 1);
    }

    _result = sort_choices_by_score(_result);

    return _result;
}
