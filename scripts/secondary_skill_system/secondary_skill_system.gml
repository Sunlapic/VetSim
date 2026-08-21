/// secondary_skill_system.gml
/// @description Дополнительные навыки игрока и ассистента, включая параметры Пополнения.


// ═══════════════════════════════════════════════════════════════
// 1. XP ДОПОЛНИТЕЛЬНЫХ НАВЫКОВ
// ═══════════════════════════════════════════════════════════════

function secondary_skill_xp_needed(_level) {
    _level = clamp(round(_level), 1, 9);

    var _requirements = [30, 45, 65, 90, 120, 155, 195, 240, 290];
    return _requirements[_level - 1];
}

function secondary_skill_add_xp(
    _actor,
    _levels_field,
    _xp_field,
    _skill_index,
    _amount,
    _skill_names,
    _show_notice
) {
    if (!instance_exists(_actor)) return false;

    if (!variable_instance_exists(_actor, _levels_field)) {
        variable_instance_set(
            _actor,
            _levels_field,
            array_create(array_length(_skill_names), 1)
        );
    }

    if (!variable_instance_exists(_actor, _xp_field)) {
        variable_instance_set(
            _actor,
            _xp_field,
            array_create(array_length(_skill_names), 0)
        );
    }

    var _levels = variable_instance_get(_actor, _levels_field);
    var _xp = variable_instance_get(_actor, _xp_field);

    while (array_length(_levels) < array_length(_skill_names)) {
        array_push(_levels, 1);
    }

    while (array_length(_xp) < array_length(_skill_names)) {
        array_push(_xp, 0);
    }

    if (_skill_index < 0 || _skill_index >= array_length(_levels)) return false;
    if (_levels[_skill_index] >= 10) return false;

    var _old_level = _levels[_skill_index];
    _xp[_skill_index] += max(0, floor(_amount));

    while (_levels[_skill_index] < 10) {
        var _needed = secondary_skill_xp_needed(_levels[_skill_index]);

        if (_xp[_skill_index] < _needed) break;

        _xp[_skill_index] -= _needed;
        _levels[_skill_index] += 1;
    }

    if (_levels[_skill_index] >= 10) {
        _levels[_skill_index] = 10;
        _xp[_skill_index] = 0;
    }

    variable_instance_set(_actor, _levels_field, _levels);
    variable_instance_set(_actor, _xp_field, _xp);

    var _level_up = (_levels[_skill_index] > _old_level);

    if (_level_up && _show_notice && instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);
        var _actor_name = variable_instance_exists(_actor, "char_name")
            ? string(_actor.char_name)
            : "Сотрудник";
        var _skill_name = (_skill_index < array_length(_skill_names))
            ? _skill_names[_skill_index]
            : "НАВЫК";
        var _message = _actor_name
            + " повысил навык до Lv."
            + string(_levels[_skill_index]);

        if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
            with (_hud) {
                show_notice(
                    string_upper(_skill_name),
                    _message,
                    room_speed * 3
                );
            }
        }
    }

    return _level_up;
}


// ═══════════════════════════════════════════════════════════════
// 2. ФОРМУЛЫ НАВЫКА «ПОПОЛНЕНИЕ»
// ═══════════════════════════════════════════════════════════════

function restock_get_carry_max(_level) {
    _level = clamp(round(_level), 1, 10);

    var _carry_by_level = [5, 6, 7, 8, 9, 10, 11, 12, 13, 15];
    return _carry_by_level[_level - 1];
}

function restock_get_duration_frames(_level) {
    _level = clamp(round(_level), 1, 10);

    var _seconds = lerp(2.0, 0.7, (_level - 1) / 9);
    return max(1, round(room_speed * _seconds));
}

function player_recalc_restock_stats(_player) {
    if (!instance_exists(_player)) return false;

    if (!variable_instance_exists(_player, "player_assistant_skill_levels")) {
        _player.player_assistant_skill_levels = [1, 1, 1];
    }

    var _restock_level = clamp(
        round(_player.player_assistant_skill_levels[1]),
        1,
        10
    );

    _player.player_restock_carry_max = restock_get_carry_max(_restock_level);
    _player.player_restock_duration = restock_get_duration_frames(_restock_level);

    // HUD и радиальное меню уже читают эту глобальную переменную.
    global.PLAYER_CARRY_MAX = _player.player_restock_carry_max;

    return true;
}

function assistant_recalc_restock_stats(_assistant) {
    if (!instance_exists(_assistant)) return false;

    if (!variable_instance_exists(_assistant, "assistant_skill_levels")) {
        _assistant.assistant_skill_levels = [1, 1, 1];
    }

    var _restock_level = clamp(
        round(_assistant.assistant_skill_levels[1]),
        1,
        10
    );

    _assistant.restock_skill_value = _restock_level;
    _assistant.restock_carry_max = restock_get_carry_max(_restock_level);
    _assistant.restock_action_duration = restock_get_duration_frames(_restock_level);

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 2.1 ФОРМУЛЫ НАВЫКА «УБОРКА»
// Lv.1 = 10 секунд, Lv.10 = 1 секунда — как регистрация администратора.
// ═══════════════════════════════════════════════════════════════

function cleaning_get_duration_frames(_level) {
    _level = clamp(round(_level), 1, 10);

    var _seconds = lerp(10, 1, (_level - 1) / 9);
    return max(1, round(room_speed * _seconds));
}

function player_recalc_cleaning_stats(_player) {
    if (!instance_exists(_player)) return false;

    if (!variable_instance_exists(_player, "player_assistant_skill_levels")) {
        _player.player_assistant_skill_levels = [1, 1, 1];
    }

    while (array_length(_player.player_assistant_skill_levels) < 3) {
        array_push(_player.player_assistant_skill_levels, 1);
    }

    var _cleaning_level = clamp(
        round(_player.player_assistant_skill_levels[2]),
        1,
        10
    );

    _player.cleaning_skill_value = _cleaning_level;
    _player.cleaning_action_duration = cleaning_get_duration_frames(
        _cleaning_level
    );

    return true;
}

function assistant_recalc_cleaning_stats(_assistant) {
    if (!instance_exists(_assistant)) return false;

    if (!variable_instance_exists(_assistant, "assistant_skill_levels")) {
        _assistant.assistant_skill_levels = [1, 1, 1];
    }

    while (array_length(_assistant.assistant_skill_levels) < 3) {
        array_push(_assistant.assistant_skill_levels, 1);
    }

    var _cleaning_level = clamp(
        round(_assistant.assistant_skill_levels[2]),
        1,
        10
    );

    _assistant.cleaning_skill_value = _cleaning_level;
    _assistant.cleaning_action_duration = cleaning_get_duration_frames(
        _cleaning_level
    );

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. ДОПОЛНИТЕЛЬНЫЕ НАВЫКИ ГЛАВНОГО ИГРОКА
// ═══════════════════════════════════════════════════════════════

function player_extra_skills_init(_player) {
    if (!instance_exists(_player)) return false;

    if (!variable_instance_exists(_player, "player_admin_skill_levels")) {
        _player.player_admin_skill_levels = [1, 1];
    }

    if (!variable_instance_exists(_player, "player_admin_skill_xp")) {
        _player.player_admin_skill_xp = [0, 0];
    }

    if (!variable_instance_exists(_player, "player_assistant_skill_levels")) {
        _player.player_assistant_skill_levels = [1, 1, 1];
    }

    if (!variable_instance_exists(_player, "player_assistant_skill_xp")) {
        _player.player_assistant_skill_xp = [0, 0, 0];
    }

    // Миграция старого сохранения с двумя навыками.
    while (array_length(_player.player_assistant_skill_levels) < 3) {
        array_push(_player.player_assistant_skill_levels, 1);
    }
    while (array_length(_player.player_assistant_skill_xp) < 3) {
        array_push(_player.player_assistant_skill_xp, 0);
    }

    player_recalc_restock_stats(_player);
    player_recalc_cleaning_stats(_player);

    return true;
}

function player_add_admin_skill_xp(
    _player,
    _skill_index,
    _amount,
    _show_notice = true
) {
    player_extra_skills_init(_player);

    // Регистрация и касса всегда дают по 5 XP за успешное действие.
    var _unified_amount = (_skill_index == 0 || _skill_index == 1)
        ? 5
        : _amount;

    return secondary_skill_add_xp(
        _player,
        "player_admin_skill_levels",
        "player_admin_skill_xp",
        _skill_index,
        _unified_amount,
        ["Регистрация", "Касса"],
        _show_notice
    );
}

function player_add_assistant_skill_xp(
    _player,
    _skill_index,
    _amount,
    _show_notice = true
) {
    player_extra_skills_init(_player);

    var _level_up = secondary_skill_add_xp(
        _player,
        "player_assistant_skill_levels",
        "player_assistant_skill_xp",
        _skill_index,
        _amount,
        ["Процедуры", "Пополнение", "Уборка"],
        _show_notice
    );

    if (_skill_index == 1) {
        player_recalc_restock_stats(_player);
    }

    if (_skill_index == 2) {
        player_recalc_cleaning_stats(_player);
    }

    return _level_up;
}


// ═══════════════════════════════════════════════════════════════
// 4. НАВЫКИ АССИСТЕНТА
// ═══════════════════════════════════════════════════════════════

function assistant_extra_skills_init(_assistant) {
    if (!instance_exists(_assistant)) return false;

    if (!variable_instance_exists(_assistant, "assistant_skill_levels")) {
        var _procedure_level = 1;
        var _restock_level = 1;
        var _cleaning_level = 1;

        if (variable_instance_exists(_assistant, "skills")) {
            if (array_length(_assistant.skills) > 1) {
                _procedure_level = clamp(round(_assistant.skills[1]), 1, 10);
            }

            if (array_length(_assistant.skills) > 4) {
                _restock_level = clamp(round(_assistant.skills[4]), 1, 10);
            }

            // В базовом массиве ассистента индекс 7 — «Чистота».
            if (array_length(_assistant.skills) > 7) {
                _cleaning_level = clamp(round(_assistant.skills[7]), 1, 10);
            }
        }

        _assistant.assistant_skill_levels = [
            _procedure_level,
            _restock_level,
            _cleaning_level
        ];
    }

    if (!variable_instance_exists(_assistant, "assistant_skill_xp")) {
        _assistant.assistant_skill_xp = [0, 0, 0];
    }

    // Миграция старых ассистентов с двумя навыками.
    while (array_length(_assistant.assistant_skill_levels) < 3) {
        var _migrated_cleaning_level = 1;

        if (
            variable_instance_exists(_assistant, "skills")
            && array_length(_assistant.skills) > 7
        ) {
            _migrated_cleaning_level = clamp(
                round(_assistant.skills[7]),
                1,
                10
            );
        }

        array_push(
            _assistant.assistant_skill_levels,
            _migrated_cleaning_level
        );
    }
    while (array_length(_assistant.assistant_skill_xp) < 3) {
        array_push(_assistant.assistant_skill_xp, 0);
    }

    assistant_recalc_restock_stats(_assistant);
    assistant_recalc_cleaning_stats(_assistant);

    return true;
}

function assistant_add_skill_xp(
    _assistant,
    _skill_index,
    _amount,
    _show_notice = true
) {
    assistant_extra_skills_init(_assistant);

    var _level_up = secondary_skill_add_xp(
        _assistant,
        "assistant_skill_levels",
        "assistant_skill_xp",
        _skill_index,
        _amount,
        ["Процедуры", "Пополнение", "Уборка"],
        _show_notice
    );

    if (!instance_exists(_assistant)) return _level_up;

    if (_skill_index == 0) {
        var _procedure_level = _assistant.assistant_skill_levels[0];

        _assistant.procedure_skill_value = _procedure_level;
        _assistant.procedure_duration = round(
            lerp(
                room_speed * 5,
                room_speed * 2,
                (_procedure_level - 1) / 9
            )
        );
    }

    if (_skill_index == 1) {
        assistant_recalc_restock_stats(_assistant);
    }

    if (_skill_index == 2) {
        assistant_recalc_cleaning_stats(_assistant);
    }

    return _level_up;
}
