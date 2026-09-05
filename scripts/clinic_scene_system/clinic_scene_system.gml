/// clinic_scene_system.gml
/// @description Обстановка текущей клиники: сетка путей, точки ожидания,
///              выход. Пакет №300.
///
/// ── Зачем это вынесено отдельно ──
///
/// Раньше всё лежало в obj_Render → Create. Пока комната была одна, это
/// работало. Но объект не persistent: при переходе в другую клинику он
/// пересоздаётся, и Create отрабатывает ВТОРОЙ раз — вместе с 73
/// присваиваниями global, среди которых деньги, репутация, время и
/// календарь. Переезд откатывал бы игру к началу.
///
/// Поэтому Create разделён на две части:
///
///   • ПРОГРЕСС (деньги, день, жители) — создаётся один раз за запуск,
///     под защитой variable_global_exists. Живёт всю игру.
///
///   • ОБСТАНОВКА (сетка, точки ожидания, выход) — своя у каждой комнаты
///     и пересобирается при каждом входе. Это и есть функции ниже.
///
/// Вызывается из obj_Render → Room Start: событие срабатывает и на первой
/// комнате, и на каждой следующей, поэтому отдельный вызов в Create не
/// нужен.


// ═══════════════════════════════════════════════════════════════
// 1. СЕТКА ПУТЕЙ ПОД ГЕОМЕТРИЮ ТЕКУЩЕЙ КОМНАТЫ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_scene_build_grid()
/// @description Пересоздаёт global.ai_grid под размеры текущей комнаты.
function clinic_scene_build_grid() {

    // Старую сетку обязательно освобождаем: mp_grid живёт вне сборщика
    // мусора GameMaker, и без destroy каждая новая клиника оставляла бы
    // за собой утечку памяти.
    //
    // mp_grid_exists в GML НЕТ (проверено), поэтому опираемся на то, что
    // переменная существует и хранит валидный id.
    if (variable_global_exists("ai_grid")) {
        if (is_real(global.ai_grid) && global.ai_grid >= 0) {
            mp_grid_destroy(global.ai_grid);
        }
    }

    var _precision = 16;
    var _grid_w = ceil(room_width / _precision);
    var _grid_h = ceil(room_height / _precision);

    global.ai_grid = mp_grid_create(
        0,
        0,
        _grid_w,
        _grid_h,
        _precision,
        _precision
    );

    mp_grid_add_instances(global.ai_grid, par_objects, true);

    show_debug_message(
        "[CLINIC SCENE] Сетка "
        + string(_grid_w) + "x" + string(_grid_h)
        + " для комнаты " + room_get_name(room)
    );

    return global.ai_grid;
}


// ═══════════════════════════════════════════════════════════════
// 2. ТОЧКИ ОЖИДАНИЯ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_scene_build_wait_spots()
/// @description Собирает global.wait_spots из obj_wait_spot текущей комнаты.
function clinic_scene_build_wait_spots() {

    global.wait_spots = [];

    var _count = instance_number(obj_wait_spot);

    for (var _index = 0; _index < _count; _index++) {
        var _spot = instance_find(obj_wait_spot, _index);

        if (!instance_exists(_spot)) continue;

        array_push(global.wait_spots, {
            x : _spot.x,
            y : _spot.y,
            occupied_by : noone,
            marker_inst : _spot
        });
    }

    show_debug_message(
        "[CLINIC SCENE] Точек ожидания: "
        + string(array_length(global.wait_spots))
    );

    return array_length(global.wait_spots);
}


// ═══════════════════════════════════════════════════════════════
// 3. ТОЧКА ВХОДА И ВЫХОДА
// ═══════════════════════════════════════════════════════════════

/// @function clinic_scene_apply_spawn(_render)
/// @description Ставит точки спавна и выхода для текущей комнаты.
///
/// Раньше координаты были записаны прямо в Create числами (100, 100).
/// В маленькой клинике это, скорее всего, другое место, поэтому точка
/// берётся из объекта obj_clinic_entrance, если он есть в комнате, и
/// только при его отсутствии — из прежних чисел.
function clinic_scene_apply_spawn(_render) {

    if (!instance_exists(_render)) return false;

    var _spawn_x = 100;
    var _spawn_y = 100;

    // asset_get_index — на случай, если объект входа ещё не создан в IDE:
    // без этой проверки проект просто не скомпилируется.
    var _entrance_object = asset_get_index("obj_clinic_entrance");

    if (
        _entrance_object != -1
        && object_exists(_entrance_object)
        && instance_number(_entrance_object) > 0
    ) {
        var _entrance = instance_find(_entrance_object, 0);

        if (instance_exists(_entrance)) {
            _spawn_x = _entrance.x;
            _spawn_y = _entrance.y;
        }
    }

    with (_render) {
        spawn_x = _spawn_x;
        spawn_y = _spawn_y;

        candidate_spawn_x = _spawn_x;
        candidate_spawn_y = _spawn_y;
        candidate_exit_x = _spawn_x;
        candidate_exit_y = _spawn_y;
    }

    global.clinic_exit_x = _spawn_x;
    global.clinic_exit_y = _spawn_y;

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 4. ОБЩАЯ ТОЧКА ВХОДА
// ═══════════════════════════════════════════════════════════════

/// @function clinic_scene_init(_render)
/// @description Полная сборка обстановки текущей клиники.
///              Вызывается из obj_Render → Room Start.
function clinic_scene_init(_render) {

    clinic_scene_build_grid();
    clinic_scene_build_wait_spots();
    clinic_scene_apply_spawn(_render);

    return true;
}
