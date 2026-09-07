/// case_apply_treatment_action(_animal_id, _action_id)
/// @description Выполняет процедуру, списывает препараты и сохраняет причину блокировки склада.
/// Пакет №68: прирост состояния читается из condition_delta справочника (работает для новых действий).
/// Пакет №111: хирургические операции отправляются в операционную (не выполняются мгновенно).

function case_apply_treatment_action(_animal_id, _action_id) {
    if (!instance_exists(_animal_id)) return false;
    if (!variable_instance_exists(_animal_id, "current_case")) return false;
    if (!is_struct(_animal_id.current_case)) return false;

    var _case = _animal_id.current_case;

    // Пакет №111: операция запускается в операционной (бригада + шкала).
    // Прирост состояния и отметка «выполнено» произойдут после операции.
    if (operating_action_is_surgery(_action_id)) {
        return operating_request(_animal_id, _action_id);
    }

    if (!variable_struct_exists(_case, "treatment_progress")) _case.treatment_progress = [];
    if (!variable_struct_exists(_case, "visit_treatments_done")) _case.visit_treatments_done = [];
    if (!variable_struct_exists(_case, "visit_procedure_log")) _case.visit_procedure_log = [];
    if (!variable_struct_exists(_case, "planned_treatment")) _case.planned_treatment = [];
    if (!variable_struct_exists(_case, "visit_treatment_feedback_ok_ids")) _case.visit_treatment_feedback_ok_ids = [];
    if (!variable_struct_exists(_case, "visit_treatment_feedback_bad_ids")) _case.visit_treatment_feedback_bad_ids = [];

    var _repeat_until_recovered = false;
    var _per_visit_limit = 1;
    var _max_total_count = -1;

    for (var _plan_index = 0; _plan_index < array_length(_case.planned_treatment); _plan_index++) {
        var _plan = _case.planned_treatment[_plan_index];

        if (_plan.action_id == _action_id) {
            _repeat_until_recovered = variable_struct_exists(_plan, "repeat_until_recovered")
                ? _plan.repeat_until_recovered
                : false;
            _per_visit_limit = variable_struct_exists(_plan, "per_visit_limit")
                ? _plan.per_visit_limit
                : 1;
            _max_total_count = variable_struct_exists(_plan, "count")
                ? _plan.count
                : 1;
            break;
        }
    }

    if (_action_id == "treat_iv_drip" || _action_id == "treat_painkiller") {
        _repeat_until_recovered = true;
        _per_visit_limit = 1;
    }

    var _done_this_visit = 0;

    for (var _visit_index = 0; _visit_index < array_length(_case.visit_treatments_done); _visit_index++) {
        if (_case.visit_treatments_done[_visit_index] == _action_id) {
            _done_this_visit += 1;
        }
    }

    if (_done_this_visit >= _per_visit_limit) return false;

    var _done_total = case_count_treatment_done(_case, _action_id);

    if (_repeat_until_recovered) {
        if (_case.condition >= 100) return false;
    }
    else if (_max_total_count > 0 && _done_total >= _max_total_count) {
        return false;
    }

    var _slot_id = 0;

    if (
        variable_instance_exists(_animal_id, "assigned_table")
        && instance_exists(_animal_id.assigned_table)
        && variable_instance_exists(_animal_id.assigned_table, "exam_slot_id")
    ) {
        _slot_id = _animal_id.assigned_table.exam_slot_id;
    }

    var _stock_result = storage_prepare_and_consume_items_for_action(
        _slot_id,
        _action_id
    );

    if (!_stock_result.ok) {
        _case.stock_blocked = true;
        _case.stock_missing_item_id = variable_struct_exists(_stock_result, "missing_item_id")
            ? _stock_result.missing_item_id
            : "";
        _case.stock_missing_item_name = _stock_result.missing_item_name;
        _case.stock_blocked_action_id = _action_id;

        _animal_id.current_case = _case;
        animal_apply_case(_animal_id, _case);

        if (instance_exists(obj_UI_HUD)) {
            var _hud = instance_find(obj_UI_HUD, 0);

            if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
                with (_hud) {
                    show_notice(
                        "НЕТ ПРЕПАРАТА",
                        _stock_result.missing_item_name
                            + ". Пополните шкаф или отмените приём.",
                        room_speed * 4
                    );
                }
            }
        }

        return false;
    }

    _case.stock_blocked = false;
    _case.stock_missing_item_id = "";
    _case.stock_missing_item_name = "";
    _case.stock_blocked_action_id = "";

    array_push(_case.treatment_progress, _action_id);
    array_push(_case.visit_treatments_done, _action_id);
    array_push(_case.visit_procedure_log, {
        proc_type : "treatment",
        proc_id : _action_id,
        proc_name_ru : db_get_treatment_action_name(_action_id)
    });

    var _already_ok = false;

    for (var _ok_index = 0; _ok_index < array_length(_case.visit_treatment_feedback_ok_ids); _ok_index++) {
        if (_case.visit_treatment_feedback_ok_ids[_ok_index] == _action_id) {
            _already_ok = true;
            break;
        }
    }

    if (!_already_ok) {
        array_push(_case.visit_treatment_feedback_ok_ids, _action_id);
    }

    // Пакет №68: прирост состояния берётся из condition_delta справочника,
    // чтобы все новые лечебные действия корректно лечили пациента.
    var _condition_delta = 0;

    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "treatment_actions")
        && variable_struct_exists(global.med_db.treatment_actions, _action_id)
    ) {
        var _action_ref = variable_struct_get(
            global.med_db.treatment_actions,
            _action_id
        );

        if (variable_struct_exists(_action_ref, "condition_delta")) {
            _condition_delta = max(0, _action_ref.condition_delta);
        }
    }

    // Резерв для старых действий, если справочника вдруг нет.
    if (_condition_delta <= 0) {
        switch (_action_id) {
            case "treat_iv_drip": _condition_delta = 5; break;
            case "treat_antiprotozoal": _condition_delta = 5; break;
            case "treat_painkiller": _condition_delta = 5; break;
            case "treat_limb_fixation": _condition_delta = 8; break;
        }
    }

    _case.condition = clamp(_case.condition + _condition_delta, 0, 100);

    // ═══════════════════════════════════════════════════════════════
    // ДОБИВКА ДО 100% ПРИ ПОЛНОСТЬЮ ВЫПОЛНЕННОМ КУРСЕ
    //
    // Это понадобилось из-за двух других правок пакета: потолка 85 на
    // старте и отмены +5 за назначение. Без добивки лёгкие болезни
    // стали бы неизлечимыми, и я поймал это до выдачи.
    //
    // Считаем на примере ринита. Один обязательный шаг лечения,
    // treat_nose_drops даёт +5. Стартовое состояние теперь максимум
    // 85. Ассистент выполняет назначение: 85 + 5 = 90.
    //
    // Курс лечения выполнен полностью, делать больше нечего — но
    // case_evaluate_outcome выдаёт «Выздоровел» только при condition
    // >= 100. Пациент застрял бы на 90% и ходил на повторные приёмы
    // бесконечно. Так же вели бы себя все 10 болезней с одним шагом:
    // блохи, отит, конъюнктивит, лишай, глаукома и остальные.
    //
    // Поэтому: если ВСЕ обязательные шаги курса выполнены, животное
    // считается вылеченным и состояние доводится до 100%. Это не
    // подарок — курс честно отработан, включая работу ассистента.
    // Пока хоть один обязательный шаг не сделан, добивки нет.
    // ═══════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ №298: ДОБИВКА ДО 100% ПОЧТИ ОТМЕНЕНА
    //
    // Здесь стояло безусловное `_case.condition = 100`, как только
    // курс отработан. Задумка (пакет 279) была верной — не дать
    // пациенту застрять на 90% и ходить бесконечно, — но выполнение
    // оказалось грубым: состояние прыгало до сотни С ЛЮБОЙ отметки.
    // Конъюнктивит с 58% лечился за один визит, а критический
    // пациент с 20% получал 80 пунктов из воздуха.
    //
    // Застревания больше не будет по другой причине: болезни с одним
    // шагом курса получили флаг repeat_until_recovered — назначение
    // повторяется, пока животное не поправится. Сколько раз лечить,
    // решает честная condition_delta из справочника.
    //
    // Тяжёлые случаи это не мучает: всё, что ниже 50%, забирает
    // стационар (inpatient_can_admit), а там процедуры идут сами по
    // таймеру палаты, без новых визитов владельца.
    //
    // Ниже осталась узкая страховка на случай ошибки в данных: курс
    // выполнен, повторять нечего, а до сотни не хватает меньше 5% —
    // дотягиваем, иначе пациент завис бы на 97% навсегда. Порог
    // намеренно узкий, подарком это уже не назвать.
    // ═══════════════════════════════════════════════════════════════

    if (
        _case.condition >= 95
        && _case.condition < 100
        && case_is_required_treatment_complete(_case)
    ) {
        _case.condition = 100;
    }

    _case.case_status = (_case.condition >= 100)
        ? "recovered"
        : "in_treatment";

    _animal_id.current_case = _case;
    _animal_id.condition = _case.condition;
    animal_apply_case(_animal_id, _case);

    // ПАКЕТ №318: процедура засчитывается в итоги дня.
    //
    // Счётчик procedures_done стоял только в obj_staff_assistant и в
    // стационаре. Лечение, которое игрок делает руками из карточки
    // пациента, проходит через эту функцию — и в статистику не
    // попадало.
    //
    // Здесь считается ЛЮБОЕ применённое лечение, независимо от того,
    // кто его выполнил. Ассистент тоже вызывает эту функцию, поэтому
    // его собственный счётчик в Step убран — иначе вышел бы двойной
    // учёт.
    if (script_exists(asset_get_index("daily_stats_count_procedure"))) {
        daily_stats_count_procedure();
    }

    return true;
}
