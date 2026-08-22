/// reception_finish_owner_payment(_owner_inst)
/// @description Принимает оплату, повышает прогресс лояльности и отправляет клиента к выходу.

function reception_finish_owner_payment(_owner_inst) {
    if (!instance_exists(_owner_inst)) return false;


    // ═══════════════════════════════════════════════════════════
    // 1. ПОИСК СТОЙКИ
    // ═══════════════════════════════════════════════════════════

    var _desk = noone;

    if (
        variable_instance_exists(_owner_inst, "assigned_desk")
        && instance_exists(_owner_inst.assigned_desk)
    ) {
        _desk = _owner_inst.assigned_desk;
    }
    else if (instance_exists(obj_reception_desk)) {
        _desk = instance_find(obj_reception_desk, 0);
    }


    // ═══════════════════════════════════════════════════════════
    // 2. УДАЛЕНИЕ ИЗ ОЧЕРЕДИ СТОЙКИ
    // ═══════════════════════════════════════════════════════════

    if (instance_exists(_desk) && variable_instance_exists(_desk, "queue_list")) {
        var _queue_index = ds_list_find_index(_desk.queue_list, _owner_inst);

        if (_queue_index != -1) {
            ds_list_delete(_desk.queue_list, _queue_index);
        }

        _desk.alarm[0] = 1;
    }


    // ═══════════════════════════════════════════════════════════
    // 3. СУММА ОПЛАТЫ
    // ═══════════════════════════════════════════════════════════

    // Перед оплатой чек пересобирается по фактически выполненным услугам.
    var _invoice = finance_owner_rebuild_invoice(_owner_inst);
    var _pay_amount = _invoice.total;

    if (_pay_amount <= 0 && variable_instance_exists(_owner_inst, "visit_price")) {
        _pay_amount = _owner_inst.visit_price;
    }

    _pay_amount = max(0, round(_pay_amount));
    global.clinic_money += _pay_amount;

    // Пакет №188: деньги приходят одной суммой, но раскладываются по
    // отделениям — приём, стационар, операционная. Каждая строка чека знает,
    // где услуга была выполнена (поле dept), поэтому делить «на глазок»
    // больше не нужно. Это видно во вкладке ФИНАНСЫ.
    finance_income_register(_invoice.items, _pay_amount);


    // ═══════════════════════════════════════════════════════════
    // 3.1 ЕДИНАЯ ДНЕВНАЯ СТАТИСТИКА
    // Работает одинаково для администратора и ручной оплаты игроком.
    // ═══════════════════════════════════════════════════════════

    if (
        variable_global_exists("daily_stats")
        && is_struct(global.daily_stats)
    ) {
        if (!variable_struct_exists(global.daily_stats, "paid_visits")) {
            global.daily_stats.paid_visits = 0;
        }
        if (!variable_struct_exists(global.daily_stats, "earned_money")) {
            global.daily_stats.earned_money = 0;
        }
        if (!variable_struct_exists(global.daily_stats, "cured")) {
            global.daily_stats.cured = 0;
        }
        if (!variable_struct_exists(global.daily_stats, "followups_scheduled")) {
            global.daily_stats.followups_scheduled = 0;
        }

        global.daily_stats.paid_visits += 1;
        global.daily_stats.earned_money += _pay_amount;

        if (
            variable_instance_exists(_owner_inst, "my_pet")
            && instance_exists(_owner_inst.my_pet)
            && variable_instance_exists(_owner_inst.my_pet, "current_case")
            && is_struct(_owner_inst.my_pet.current_case)
            && variable_struct_exists(
                _owner_inst.my_pet.current_case,
                "condition"
            )
            && _owner_inst.my_pet.current_case.condition >= 100
        ) {
            global.daily_stats.cured += 1;
        }

        if (
            variable_instance_exists(_owner_inst, "visit_followup_planned")
            && _owner_inst.visit_followup_planned
        ) {
            global.daily_stats.followups_scheduled += 1;
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 4. УСПЕШНЫЙ ПРОГРЕСС ЛОЯЛЬНОСТИ
    // ═══════════════════════════════════════════════════════════

    var _loyalty_level_up = owner_loyalty_add_paid_visit(_owner_inst);

    // Каждый успешно оплаченный визит повышает репутацию один раз.
    if (!variable_instance_exists(_owner_inst, "visit_reputation_awarded")) {
        _owner_inst.visit_reputation_awarded = false;
    }

    if (!_owner_inst.visit_reputation_awarded) {
        global.clinic_reputation += 1;
        _owner_inst.visit_reputation_awarded = true;
    }

    if (_loyalty_level_up && instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);

        if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
            with (_hud) {
                show_notice(
                    "ЛОЯЛЬНОСТЬ ПОВЫШЕНА",
                    _owner_inst.char_name + ": уровень " + string(_owner_inst.loyalty_level),
                    room_speed * 3
                );
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 5. ЗАВЕРШЕНИЕ ОПЛАТЫ
    // ═══════════════════════════════════════════════════════════

    with (_owner_inst) {
        queue_purpose = "none";
        queue_slot = -1;

        finance_bill_paid = true;
        finance_paid_total = _pay_amount;
        finance_paid_items = _invoice.items;
        finance_bill_total = _pay_amount;
        visit_price = _pay_amount;

        payment_pending = false;
        payment_done = true;
        pending_payment_total = 0;

        assigned_doctor = noone;
        assigned_table = noone;

        registration_in_progress = false;
        registration_timer = 0;
        registration_timer_max = 0;
        registration_actor_name = "";

        visit_done = true;
    }


    // ═══════════════════════════════════════════════════════════
    // 6. УХОД ИЗ КЛИНИКИ
    // ═══════════════════════════════════════════════════════════

    owner_start_leaving(_owner_inst);

    return true;
}
