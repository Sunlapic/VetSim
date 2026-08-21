/// candidate_wait_system.gml
/// @description Ограниченное время ожидания кандидата и шкала в табличке «КАНДИДАТ».


// ═══════════════════════════════════════════════════════════════
// 1. ДЛИТЕЛЬНОСТЬ ОЖИДАНИЯ
// Считается в игровых минутах: зависит от скорости времени и
// останавливается на паузе игры (вместе с global.game_hour/minute).
// ═══════════════════════════════════════════════════════════════

function candidate_wait_timeout_minutes() {
    return 60; // 1 час игрового времени
}


// ═══════════════════════════════════════════════════════════════
// 2. СТАРТ ТАЙМЕРА
// Фиксирует игровое время на момент, когда кандидат встал на точку.
// ═══════════════════════════════════════════════════════════════

function candidate_wait_reset_timer(_candidate) {
    if (!instance_exists(_candidate)) return;

    _candidate.candidate_wait_timer_active = true;
    _candidate.candidate_wait_start_day = global.game_day;
    _candidate.candidate_wait_start_hour = global.game_hour;
    _candidate.candidate_wait_start_minute = global.game_minute;
}


// ═══════════════════════════════════════════════════════════════
// 3. ПРОШЛО ИГРОВЫХ МИНУТ С МОМЕНТА СТАРТА
// Учитывает переход через полночь (через смену game_day).
// ═══════════════════════════════════════════════════════════════

function candidate_wait_elapsed_minutes(_candidate) {
    if (!instance_exists(_candidate)) return 0;

    if (
        !variable_instance_exists(_candidate, "candidate_wait_timer_active")
        || !_candidate.candidate_wait_timer_active
    ) {
        return 0;
    }

    var _elapsed =
        (global.game_day - _candidate.candidate_wait_start_day) * 1440
        + (global.game_hour - _candidate.candidate_wait_start_hour) * 60
        + (global.game_minute - _candidate.candidate_wait_start_minute);

    return max(0, _elapsed);
}


// ═══════════════════════════════════════════════════════════════
// 4. ОСТАЛОСЬ ИГРОВЫХ МИНУТ ДО УХОДА
// ═══════════════════════════════════════════════════════════════

function candidate_wait_remaining_minutes(_candidate) {
    if (!instance_exists(_candidate)) return 0;

    var _elapsed = candidate_wait_elapsed_minutes(_candidate);

    return max(0, candidate_wait_timeout_minutes() - _elapsed);
}


// ═══════════════════════════════════════════════════════════════
// 5. ДОЛЯ ОСТАВШЕГОСЯ ВРЕМЕНИ (0..1) ДЛЯ ШКАЛЫ
// 1 = полный час, 0 = кандидат сейчас уйдёт.
// ═══════════════════════════════════════════════════════════════

function candidate_wait_ratio(_candidate) {
    if (!instance_exists(_candidate)) return 0;

    var _total = candidate_wait_timeout_minutes();

    return clamp(
        candidate_wait_remaining_minutes(_candidate) / max(0.01, _total),
        0,
        1
    );
}
