/// owner_walk_speed.gml
/// @description Возрастная скорость владельцев без прокачки.


// ═══════════════════════════════════════════════════════════════
// 1. СЛУЧАЙНЫЙ УРОВЕНЬ С УЧЁТОМ ВОЗРАСТА
// ═══════════════════════════════════════════════════════════════

function owner_roll_walk_speed_level(_age) {
    _age = clamp(round(_age), 20, 70);

    // 20 лет -> Lv.10, 70 лет -> Lv.1.
    var _age_ratio = (_age - 20) / 50;
    var _base_level = round(lerp(10, 1, _age_ratio));

    // Небольшая индивидуальная разница между людьми одного возраста.
    var _rolled_level = _base_level + irandom_range(-1, 1);

    // Самые молодые и самые старые сохраняют крайние значения.
    if (_age <= 22) _rolled_level = 10;
    if (_age >= 68) _rolled_level = 1;

    return clamp(_rolled_level, 1, 10);
}


// ═══════════════════════════════════════════════════════════════
// 2. ПРИМЕНЕНИЕ УРОВНЯ К ЭКЗЕМПЛЯРУ
// ═══════════════════════════════════════════════════════════════

function owner_apply_walk_speed_level(_owner, _level) {
    if (!instance_exists(_owner)) return false;

    _level = clamp(round(_level), 1, 10);

    var _speed_percent = 100 + (_level - 1) * 10;

    _owner.owner_walk_speed_level = _level;
    _owner.owner_walk_speed_percent = _speed_percent;

    // Та же внутренняя формула, что у общего навыка сотрудников.
    _owner.p_move_speed = 1.4 * (_speed_percent / 100);

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. СОЗДАНИЕ НОВОЙ СКОРОСТИ
// ═══════════════════════════════════════════════════════════════

function owner_generate_walk_speed(_owner) {
    if (!instance_exists(_owner)) return false;

    var _owner_age = variable_instance_exists(_owner, "age")
        ? _owner.age
        : 40;

    var _level = owner_roll_walk_speed_level(_owner_age);
    return owner_apply_walk_speed_level(_owner, _level);
}
