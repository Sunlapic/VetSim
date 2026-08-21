/// case_get_visible_treatment(_case, _therapy_level)
/// @description Возвращает стабильную равномерно перемешанную смесь правильных и ложных назначений.

function case_get_visible_treatment(_case, _therapy_level = 1) {
    var _result = [];

    if (!is_struct(_case)) return _result;

    _therapy_level = clamp(round(_therapy_level), 1, 10);


    // ═══════════════════════════════════════════════════════════
    // 1. ЛОКАЛЬНЫЕ ПОМОЩНИКИ
    // ═══════════════════════════════════════════════════════════

    function contains_action_id(_array, _action_id) {
        for (var _index = 0; _index < array_length(_array); _index++) {
            if (_array[_index] == _action_id) return true;
        }

        return false;
    }

    // Стабильный псевдослучайный балл.
    // ВАЖНО: правильность варианта намеренно не входит в расчёт,
    // поэтому правильные ответы больше не смещаются вниз списка.
    function stable_choice_score(_seed, _choice_id) {
        var _text = _seed + "|" + _choice_id;
        var _score = 17;

        for (var _char_index = 1; _char_index <= string_length(_text); _char_index++) {
            var _char_code = ord(string_copy(_text, _char_index, 1));
            _score = (_score * 131 + _char_code + _char_index * 17) mod 2147483647;
        }

        return _score;
    }

    function wrong_count_for_level(_level) {
        switch (_level) {
            case 1:  return 4;
            case 2:  return 4;
            case 3:  return 3;
            case 4:  return 3;
            case 5:  return 2;
            case 6:  return 2;
            case 7:  return 2;
            case 8:  return 1;
            case 9:  return 1;
            case 10: return 0;
        }

        return 4;
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


    // ═══════════════════════════════════════════════════════════
    // 2. ПЛАН ЛЕЧЕНИЯ БОЛЕЗНИ
    // ═══════════════════════════════════════════════════════════

    var _correct_choices = [];
    var _wrong_candidates = [];
    var _disease_action_ids = [];
    var _base_steps = [];

    if (
        variable_struct_exists(_case, "planned_treatment")
        && array_length(_case.planned_treatment) > 0
    ) {
        _base_steps = _case.planned_treatment;
    } else {
        for (var _step_index = 0; _step_index < array_length(global.med_db.disease_treatment); _step_index++) {
            var _database_step = global.med_db.disease_treatment[_step_index];

            if (_database_step.disease_id == _case.hidden_disease_id) {
                array_push(_base_steps, _database_step);
            }
        }
    }

    for (var _disease_step_index = 0; _disease_step_index < array_length(_base_steps); _disease_step_index++) {
        var _disease_step = _base_steps[_disease_step_index];

        if (!variable_struct_exists(global.med_db.treatment_actions, _disease_step.action_id)) {
            continue;
        }

        if (!contains_action_id(_disease_action_ids, _disease_step.action_id)) {
            array_push(_disease_action_ids, _disease_step.action_id);
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 3. ПРАВИЛЬНЫЕ ВАРИАНТЫ
    // ═══════════════════════════════════════════════════════════

    for (var _correct_index = 0; _correct_index < array_length(_base_steps); _correct_index++) {
        var _step = _base_steps[_correct_index];

        if (!variable_struct_exists(global.med_db.treatment_actions, _step.action_id)) {
            continue;
        }

        var _required_reveal = variable_struct_exists(_step, "reveal_level")
            ? _step.reveal_level
            : 0;

        if (_required_reveal > _case.reveal_level) continue;

        var _repeat_until_recovered = variable_struct_exists(_step, "repeat_until_recovered")
            ? _step.repeat_until_recovered
            : false;

        var _planned_count = variable_struct_exists(_step, "count")
            ? _step.count
            : 1;

        var _completed_count = case_count_treatment_done(_case, _step.action_id);

        if (_step.action_id == "treat_iv_drip" || _step.action_id == "treat_painkiller") {
            _repeat_until_recovered = true;
        }

        // Одноразовое действие, выполненное в прошлых визитах, больше не показываем.
        if (!_repeat_until_recovered && _completed_count >= _planned_count) {
            continue;
        }

        var _display_total = _planned_count;

        if (_repeat_until_recovered) {
            var _condition_delta = 5;
            var _action = variable_struct_get(global.med_db.treatment_actions, _step.action_id);

            if (variable_struct_exists(_action, "condition_delta")) {
                _condition_delta = max(1, _action.condition_delta);
            }

            var _remaining_condition = max(0, 100 - _case.condition);
            var _extra_needed = ceil(_remaining_condition / _condition_delta);
            _display_total = _completed_count + _extra_needed;

            if (_case.condition < 100 && _display_total <= _completed_count) {
                _display_total = _completed_count + 1;
            }

            _display_total = max(1, _display_total);
        }

        array_push(_correct_choices, {
            action_id : _step.action_id,
            count : _display_total,
            reveal_level : _required_reveal,
            required : variable_struct_exists(_step, "required") ? _step.required : false,
            notes : variable_struct_exists(_step, "notes") ? _step.notes : "",
            is_correct : true,
            repeat_until_recovered : _repeat_until_recovered,
            per_visit_limit : variable_struct_exists(_step, "per_visit_limit")
                ? _step.per_visit_limit
                : 1,
            sort_score : 0
        });
    }


    // ═══════════════════════════════════════════════════════════
    // 4. ЛОЖНЫЕ ВАРИАНТЫ ИЗ ДРУГИХ БОЛЕЗНЕЙ
    // ═══════════════════════════════════════════════════════════

    for (var _action_index = 0; _action_index < array_length(global.med_db.treatment_action_ids); _action_index++) {
        var _action_id = global.med_db.treatment_action_ids[_action_index];

        if (contains_action_id(_disease_action_ids, _action_id)) continue;
        if (!variable_struct_exists(global.med_db.treatment_actions, _action_id)) continue;

        array_push(_wrong_candidates, {
            action_id : _action_id,
            count : 0,
            reveal_level : 0,
            required : false,
            notes : "",
            is_correct : false,
            repeat_until_recovered : false,
            per_visit_limit : 1,
            sort_score : 0
        });
    }


    // ═══════════════════════════════════════════════════════════
    // 5. СТАБИЛЬНОЕ РАВНОМЕРНОЕ ПЕРЕМЕШИВАНИЕ
    // ═══════════════════════════════════════════════════════════

    var _case_seed = variable_struct_exists(_case, "case_id")
        ? string(_case.case_id)
        : string(_case.hidden_disease_id);

    _case_seed += "|treatment|" + string(_case.reveal_level) + "|" + string(_therapy_level);

    for (var _correct_score_index = 0; _correct_score_index < array_length(_correct_choices); _correct_score_index++) {
        _correct_choices[_correct_score_index].sort_score = stable_choice_score(
            _case_seed,
            _correct_choices[_correct_score_index].action_id
        );
    }

    for (var _wrong_score_index = 0; _wrong_score_index < array_length(_wrong_candidates); _wrong_score_index++) {
        _wrong_candidates[_wrong_score_index].sort_score = stable_choice_score(
            _case_seed,
            _wrong_candidates[_wrong_score_index].action_id
        );
    }

    _wrong_candidates = sort_choices_by_score(_wrong_candidates);

    for (var _push_correct = 0; _push_correct < array_length(_correct_choices); _push_correct++) {
        array_push(_result, _correct_choices[_push_correct]);
    }

    var _wrong_limit = wrong_count_for_level(_therapy_level);
    var _free_slots = max(0, 6 - array_length(_result));
    var _wrong_needed = min(_wrong_limit, _free_slots);

    for (var _push_wrong = 0; _push_wrong < _wrong_needed; _push_wrong++) {
        if (_push_wrong >= array_length(_wrong_candidates)) break;
        array_push(_result, _wrong_candidates[_push_wrong]);
    }

    // Защита на случай, если у болезни когда-нибудь станет больше шести правильных действий.
    while (array_length(_result) > 6) {
        array_delete(_result, array_length(_result) - 1, 1);
    }

    // Правильные и ложные варианты сортируются одной и той же функцией.
    // Поэтому ни одна группа не получает приоритета сверху или снизу.
    _result = sort_choices_by_score(_result);

    return _result;
}
