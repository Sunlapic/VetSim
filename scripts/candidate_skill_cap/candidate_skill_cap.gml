/// candidate_skill_cap.gml
/// @description Потолок навыков кандидата по репутации клиники.
///              Пакет №319.
///
/// ── Смысл ──
///
/// В безвестную клинику сильные специалисты не идут. Пока репутация
/// низкая, приходят только новички; чем известнее клиника, тем выше
/// потолок навыков у тех, кто стучится в дверь.
///
/// Это меняет ход игры: чтобы нанять хорошего врача, сначала нужно
/// заработать имя. Раньше кандидат с навыком 10 мог прийти в первый же
/// день.


// ═══════════════════════════════════════════════════════════════
// 1. ПОТОЛОК ПО РЕПУТАЦИИ
// ═══════════════════════════════════════════════════════════════

/// @function candidate_skill_cap_for(_reputation)
/// @description Максимальный уровень навыка при такой репутации.
///
/// Шкала (задана пользователем):
///
///     0-20   -> 1
///     20-30  -> 2
///     30-40  -> 3
///     40-50  -> 4
///     ... каждые следующие 10 пунктов дают +1 уровень
///     90-100 -> 9
///     100+   -> 10
///
/// Первая ступень намеренно шире остальных: старт игры — это репутация
/// 35, и без широкой первой ступени игрок сразу перескакивал бы через
/// половину шкалы.
function candidate_skill_cap_for(_reputation) {

    var _rep = max(0, _reputation);

    if (_rep < 20) return 1;

    return clamp(2 + floor((_rep - 20) / 10), 1, 10);
}


/// @function candidate_skill_cap_current()
/// @description Потолок для текущей репутации клиники.
function candidate_skill_cap_current() {

    var _rep = variable_global_exists("clinic_reputation")
        ? global.clinic_reputation
        : 35;

    return candidate_skill_cap_for(_rep);
}


// ═══════════════════════════════════════════════════════════════
// 2. ПРИМЕНЕНИЕ К КАНДИДАТУ
// ═══════════════════════════════════════════════════════════════

/// @function candidate_apply_skill_cap(_candidate)
/// @description Обрезает навыки кандидата по потолку репутации.
///
/// Важно: вызывается ТОЛЬКО для кандидатов, уже после staff_apply_role.
/// Ту же функцию генерации используют стартовые сотрудники, расставленные
/// в комнате, — их резать нельзя, иначе игрок начнёт партию с командой
/// новичков.
///
/// Профильные навыки роли (у врача — Терапия, у админа — Регистрация и
/// Касса) обрезаются наравне с остальными: смысл в том, чтобы к слабой
/// клинике не приходил сильный специалист вообще ни в чём.
function candidate_apply_skill_cap(_candidate) {

    if (!instance_exists(_candidate)) return false;
    if (!variable_instance_exists(_candidate, "skills")) return false;
    if (!is_array(_candidate.skills)) return false;

    var _cap = candidate_skill_cap_current();
    var _sum = 0;
    var _best_value = -1;
    var _best_index = 0;

    with (_candidate) {
        for (var _index = 0; _index < array_length(skills); _index++) {
            skills[_index] = clamp(skills[_index], 1, _cap);

            _sum += skills[_index];

            if (skills[_index] > _best_value) {
                _best_value = skills[_index];
                _best_index = _index;
            }
        }

        skills_sum = _sum;
    }

    // ── Пересчёт производных значений ──
    //
    // После обрезки навыков изменились и специальность, и ожидаемая
    // зарплата. Если этого не сделать, кандидат с навыком 1 будет
    // просить деньги как за навык 8 — расчёт зарплаты идёт от уровней.
    if (
        variable_instance_exists(_candidate, "role")
        && _candidate.role == "doctor"
        && script_exists(asset_get_index("doctor_recalc_all_skills"))
    ) {
        doctor_recalc_all_skills(_candidate);
    }

    if (script_exists(asset_get_index("finance_calculate_staff_salary"))) {
        _candidate.salary_expected =
            finance_calculate_staff_salary(_candidate);
    }

    show_debug_message(
        "[HIRING] Потолок навыков "
        + string(_cap)
        + " (репутация "
        + string(
            variable_global_exists("clinic_reputation")
                ? global.clinic_reputation
                : 0
        )
        + ")"
    );

    return true;
}
