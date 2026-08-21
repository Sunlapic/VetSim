// ─────────────────────────────────────────────
// СИСТЕМА ОПЫТА АДМИНА (ребаланс)
// ─────────────────────────────────────────────
//
// XP за действие:
//   • Регистрация  → +4
//   • Касса        → +5
//   • Скор.ходьбы  → +2 каждые 30 сек работы
//
// Кривую опыта делаем такой же формы как у врача, но чуть легче
// (админ быстрее качает первый уровни, медленнее последние):
//   1→2: 30, 2→3: 50, 3→4: 75, 4→5: 105, 5→6: 140,
//   6→7: 180, 7→8: 225, 8→9: 275, 9→10: 330
//   Всего 1410 опыта до 10 лвл.
//   С средним +4.5 опыта за действие ≈ 310 действий до макс.
//
// Первые 3 лвла за ~20 регистраций/касс, 10 лвл за ~300 действий.
// ─────────────────────────────────────────────

function admin_xp_needed(_lvl) {
    _lvl = clamp(_lvl, 1, 9);
    var _table = [30, 50, 75, 105, 140, 180, 225, 275, 330];
    return _table[_lvl - 1];
}

// Пересчёт уровня по XP (не понижает, не сбивает)
function admin_recalc_skill_progress(_actor, _idx) {
    if (!instance_exists(_actor)) return;
    if (!variable_instance_exists(_actor, "skill_level")) return;
    if (_idx < 0 || _idx >= array_length(_actor.skill_level)) return;

    // Инициализация массива skill_xp
    if (!variable_instance_exists(_actor, "skill_xp")) {
        _actor.skill_xp = array_create(array_length(_actor.skill_level), 0);
    }
    while (array_length(_actor.skill_xp) < array_length(_actor.skill_level)) {
        array_push(_actor.skill_xp, 0);
    }

    var _cur_lvl = _actor.skill_level[_idx];
    if (_cur_lvl < 1) _cur_lvl = 1;
    if (_cur_lvl >= 10) {
        _actor.skill_xp[_idx] = 0;
        _actor.skill_level[_idx] = 10;
        return;
    }

    var _xp = _actor.skill_xp[_idx];
    while (_cur_lvl < 10) {
        var _need = admin_xp_needed(_cur_lvl);
        if (_xp >= _need) {
            _xp -= _need;
            _cur_lvl += 1;
        } else break;
    }

    _actor.skill_level[_idx] = _cur_lvl;
    _actor.skill_xp[_idx] = _xp;
}
/// admin_add_skill_xp(_actor, _skill_index, _amount, _show_popup)
/// @description Добавляет XP Регистрации или Кассы.

function admin_add_skill_xp(_actor, _skill_index, _amount, _show_popup = true) {
    if (!instance_exists(_actor)) return false;

    admin_recalc_skills(_actor);

    // Допустимы только: 0 = Регистрация, 1 = Касса.
    if (_skill_index < 0 || _skill_index >= 2) return false;
    if (_actor.skill_level[_skill_index] >= 10) return false;

    var _levels = _actor.skill_level;
    var _xp = _actor.skill_xp;
    var _needed = _actor.skill_xp_needed;
    var _old_level = _levels[_skill_index];

    _xp[_skill_index] += max(0, floor(_amount));

    while (_levels[_skill_index] < 10) {
        var _current_needed = secondary_skill_xp_needed(
            _levels[_skill_index]
        );

        if (_xp[_skill_index] < _current_needed) break;

        _xp[_skill_index] -= _current_needed;
        _levels[_skill_index] += 1;

        if (_levels[_skill_index] >= 10) {
            _levels[_skill_index] = 10;
            _xp[_skill_index] = 0;
            _needed[_skill_index] = 1;
            break;
        }

        _needed[_skill_index] = secondary_skill_xp_needed(
            _levels[_skill_index]
        );
    }

    _actor.skill_level = _levels;
    _actor.skill_xp = _xp;
    _actor.skill_xp_needed = _needed;

    admin_recalc_skills(_actor);

    var _level_up = (
        _actor.skill_level[_skill_index] > _old_level
    );

    if (_level_up && _show_popup && instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);
        var _skill_names = ["РЕГИСТРАЦИЯ", "КАССА"];
        var _message = _actor.char_name
            + " повысил навык до Lv."
            + string(_actor.skill_level[_skill_index]);

        if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
            with (_hud) {
                show_notice(
                    _skill_names[_skill_index],
                    _message,
                    room_speed * 3
                );
            }
        }
    }

    return _level_up;
}



/// admin_recalc_skills(_actor)
/// @description Пересчитывает только Регистрацию и Кассу. Скорость ходьбы теперь является общим навыком.

function admin_recalc_skills(_actor) {
    if (!instance_exists(_actor)) return false;


    // ═══════════════════════════════════════════════════════════
    // 1. МИГРАЦИЯ МАССИВОВ ДО ДВУХ АДМИНСКИХ НАВЫКОВ
    // ═══════════════════════════════════════════════════════════

    if (!variable_instance_exists(_actor, "skill_level")) {
        _actor.skill_level = [1, 1];
    }

    if (!variable_instance_exists(_actor, "skill_xp")) {
        _actor.skill_xp = [0, 0];
    }

    if (!variable_instance_exists(_actor, "skill_xp_needed")) {
        _actor.skill_xp_needed = [30, 30];
    }

    // Старый третий элемент скорости ходьбы больше нигде не читается.
    // Создаём новые массивы только из Регистрации и Кассы.
    var _old_levels = _actor.skill_level;
    var _old_xp = _actor.skill_xp;
    var _old_needed = _actor.skill_xp_needed;

    var _levels = [
        (array_length(_old_levels) > 0) ? _old_levels[0] : 1,
        (array_length(_old_levels) > 1) ? _old_levels[1] : 1
    ];

    var _xp = [
        (array_length(_old_xp) > 0) ? _old_xp[0] : 0,
        (array_length(_old_xp) > 1) ? _old_xp[1] : 0
    ];

    var _needed = [
        (array_length(_old_needed) > 0) ? _old_needed[0] : 30,
        (array_length(_old_needed) > 1) ? _old_needed[1] : 30
    ];


    // ═══════════════════════════════════════════════════════════
    // 2. НОРМАЛИЗАЦИЯ УРОВНЕЙ И XP
    // ═══════════════════════════════════════════════════════════

    for (var _index = 0; _index < 2; _index++) {
        _levels[_index] = clamp(round(_levels[_index]), 1, 10);

        if (_levels[_index] >= 10) {
            _levels[_index] = 10;
            _xp[_index] = 0;
            _needed[_index] = 1;
        } else {
            _needed[_index] = secondary_skill_xp_needed(_levels[_index]);
            _xp[_index] = clamp(_xp[_index], 0, _needed[_index] - 1);
        }
    }

    _actor.skill_level = _levels;
    _actor.skill_xp = _xp;
    _actor.skill_xp_needed = _needed;


    // ═══════════════════════════════════════════════════════════
    // 3. ДЛИТЕЛЬНОСТЬ РЕГИСТРАЦИИ И ОПЛАТЫ
    // ═══════════════════════════════════════════════════════════

    _actor.register_duration = round(
        room_speed * lerp(10, 1, (_levels[0] - 1) / 9)
    );

    _actor.payment_duration = round(
        room_speed * lerp(10, 1, (_levels[1] - 1) / 9)
    );

    _actor.registration_skill_value = _levels[0];

    return true;
}




// Пересчитать все скиллы сразу (в Create админа)
function admin_recalc_all_skills(_actor) {
    if (!instance_exists(_actor)) return;
    if (!variable_instance_exists(_actor, "skill_level")) return;

    // Инициализация skill_xp
    if (!variable_instance_exists(_actor, "skill_xp")) {
        _actor.skill_xp = array_create(array_length(_actor.skill_level), 0);
    }
    while (array_length(_actor.skill_xp) < array_length(_actor.skill_level)) {
        array_push(_actor.skill_xp, 0);
    }

    for (var i = 0; i < array_length(_actor.skill_level); i++) {
        admin_recalc_skill_progress(_actor, i);
    }
    admin_recalc_skills(_actor);
}
