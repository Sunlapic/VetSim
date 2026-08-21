/// owner_loyalty.gml
/// @description Лояльность владельцев и синхронизация с owner_db.


// ═══════════════════════════════════════════════════════════════
// 1. СИНХРОНИЗАЦИЯ ЛОЯЛЬНОСТИ С БАЗОЙ
// ═══════════════════════════════════════════════════════════════

function owner_loyalty_sync_record(_owner_inst) {
    if (!instance_exists(_owner_inst)) return false;
    if (!variable_instance_exists(_owner_inst, "owner_record_id")) return false;

    var _owner_id = _owner_inst.owner_record_id;

    if (_owner_id == "") return false;
    if (!variable_global_exists("owner_db")) return false;
    if (!variable_struct_exists(global.owner_db, _owner_id)) return false;

    var _record = variable_struct_get(global.owner_db, _owner_id);

    _record.patience_level = variable_instance_exists(_owner_inst, "patience_level")
        ? clamp(round(_owner_inst.patience_level), 1, 10)
        : 5;

    _record.patience_success_progress = variable_instance_exists(_owner_inst, "patience_success_progress")
        ? clamp(round(_owner_inst.patience_success_progress), 0, 4)
        : 0;

    _record.loyalty_level = variable_instance_exists(_owner_inst, "loyalty_level")
        ? clamp(round(_owner_inst.loyalty_level), 1, 10)
        : 5;

    _record.loyalty_success_progress = variable_instance_exists(_owner_inst, "loyalty_success_progress")
        ? clamp(round(_owner_inst.loyalty_success_progress), 0, 4)
        : 0;

    _record.owner_feature_id = variable_instance_exists(_owner_inst, "owner_feature_id")
        ? string(_owner_inst.owner_feature_id)
        : "none";

    _record.owner_feature_name_ru = variable_instance_exists(_owner_inst, "owner_feature_name_ru")
        ? string(_owner_inst.owner_feature_name_ru)
        : "Нет особенности";

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 2. УСПЕШНО ОПЛАЧЕННЫЙ ВИЗИТ
// Каждые 5 оплат повышают уровень лояльности на 1.
// Возвращает true, если уровень повысился.
// ═══════════════════════════════════════════════════════════════

function owner_loyalty_add_paid_visit(_owner_inst) {
    if (!instance_exists(_owner_inst)) return false;

    if (!variable_instance_exists(_owner_inst, "loyalty_level")) {
        _owner_inst.loyalty_level = 5;
    }

    if (!variable_instance_exists(_owner_inst, "loyalty_success_progress")) {
        _owner_inst.loyalty_success_progress = 0;
    }

    _owner_inst.loyalty_level = clamp(round(_owner_inst.loyalty_level), 1, 10);
    _owner_inst.loyalty_success_progress = clamp(
        round(_owner_inst.loyalty_success_progress),
        0,
        4
    );

    var _level_up = false;

    if (_owner_inst.loyalty_level < 10) {
        _owner_inst.loyalty_success_progress += 1;

        if (_owner_inst.loyalty_success_progress >= 5) {
            _owner_inst.loyalty_success_progress -= 5;
            _owner_inst.loyalty_level = min(10, _owner_inst.loyalty_level + 1);
            _level_up = true;
        }
    } else {
        _owner_inst.loyalty_success_progress = 0;
    }

    owner_loyalty_sync_record(_owner_inst);

    return _level_up;
}


// ═══════════════════════════════════════════════════════════════
// 3. ПРОГРЕСС ТЕРПЕНИЯ ЗА ОЖИДАНИЕ
// Вызывается один раз за визит после 10 секунд ожидания.
// Каждые 5 единиц прогресса дают +1 уровень терпения.
// Возвращает true, если уровень повысился.
// ═══════════════════════════════════════════════════════════════

function owner_patience_add_wait_progress(_owner_inst) {
    if (!instance_exists(_owner_inst)) return false;

    if (!variable_instance_exists(_owner_inst, "patience_level")) {
        _owner_inst.patience_level = 5;
    }

    if (!variable_instance_exists(_owner_inst, "patience_success_progress")) {
        _owner_inst.patience_success_progress = 0;
    }

    _owner_inst.patience_level = clamp(round(_owner_inst.patience_level), 1, 10);
    _owner_inst.patience_success_progress = clamp(
        round(_owner_inst.patience_success_progress),
        0,
        4
    );

    var _level_up = false;

    if (_owner_inst.patience_level < 10) {
        _owner_inst.patience_success_progress += 1;

        if (_owner_inst.patience_success_progress >= 5) {
            _owner_inst.patience_success_progress -= 5;
            _owner_inst.patience_level = min(10, _owner_inst.patience_level + 1);
            _owner_inst.stat_patience = _owner_inst.patience_level * 10;
            _level_up = true;
        }
    } else {
        _owner_inst.patience_success_progress = 0;
    }

    owner_loyalty_sync_record(_owner_inst);

    return _level_up;
}


// ═══════════════════════════════════════════════════════════════
// 4. КЛИЕНТ НЕ ДОЖДАЛСЯ
// Прогресс терпения и лояльности уменьшается на 1.
// Сами уровни характеристик не понижаются.
// ═══════════════════════════════════════════════════════════════

function owner_loyalty_apply_wait_failure(_owner_inst) {
    if (!instance_exists(_owner_inst)) return false;

    if (!variable_instance_exists(_owner_inst, "patience_level")) {
        _owner_inst.patience_level = 5;
    }

    if (!variable_instance_exists(_owner_inst, "patience_success_progress")) {
        _owner_inst.patience_success_progress = 0;
    }

    if (!variable_instance_exists(_owner_inst, "loyalty_level")) {
        _owner_inst.loyalty_level = 5;
    }

    if (!variable_instance_exists(_owner_inst, "loyalty_success_progress")) {
        _owner_inst.loyalty_success_progress = 0;
    }

    _owner_inst.patience_level = clamp(round(_owner_inst.patience_level), 1, 10);
    _owner_inst.patience_success_progress = max(
        0,
        round(_owner_inst.patience_success_progress) - 1
    );

    _owner_inst.loyalty_level = clamp(round(_owner_inst.loyalty_level), 1, 10);
    _owner_inst.loyalty_success_progress = max(
        0,
        round(_owner_inst.loyalty_success_progress) - 1
    );

    owner_loyalty_sync_record(_owner_inst);

    return true;
}
