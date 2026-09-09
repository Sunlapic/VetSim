/// vet_new_game.gml
/// @description Пакет №329: честная «Новая игра».
///
/// ═══════════════════════════════════════════════════════════════
/// ЗАЧЕМ ОТДЕЛЬНАЯ ФУНКЦИЯ
///
/// Раньше «Новая игра» только удаляла файл сохранения и вызывала
/// game_restart(). Дальше всё держалось на том, что game_restart
/// обнуляет global, а obj_Render → Create заново выставит старт.
/// Так оно и работало, но проверить это было нельзя: в консоли не
/// появлялось ни одной строки о том, с чего началась партия.
///
/// Теперь сброс делается явно и печатает стартовые значения. После
/// этого всё равно идёт game_restart: он единственный способ
/// гарантированно вычистить несколько сотен global, которые копятся
/// за игровой день.
///
/// ═══════════════════════════════════════════════════════════════
/// СТАРТОВЫЕ ЗНАЧЕНИЯ
///
/// 100 000 денег и 500 баллов — тестовый старт, пока четыре клиники
/// расставляются в редакторе. Обычный старт партии: 15 000 денег
/// и 0 баллов — вернуть, поменяв два значения ниже и запасные
/// значения в obj_Render → Create и в save_system.
/// ═══════════════════════════════════════════════════════════════

#macro NEW_GAME_START_MONEY  100000
#macro NEW_GAME_START_POINTS 500


// ═══════════════════════════════════════════════════════════════
// 1. СТАРТОВЫЕ ЗНАЧЕНИЯ
// ═══════════════════════════════════════════════════════════════

/// @function new_game_start_money()
/// @description Сколько денег на старте партии.
function new_game_start_money() {
    return NEW_GAME_START_MONEY;
}


/// @function new_game_start_points()
/// @description Сколько баллов развития на старте партии.
function new_game_start_points() {
    return NEW_GAME_START_POINTS;
}


// ═══════════════════════════════════════════════════════════════
// 2. СБРОС
// ═══════════════════════════════════════════════════════════════

/// @function new_game_reset()
/// @description Возвращает ВСЕ показатели к стартовым и ставит игру
///              в клинику №1. Вызывается из save_slot_new_game().
/// @return true, если сброс выполнен.
function new_game_reset() {

    if (script_exists(asset_get_index("clinics_init"))) {
        clinics_init();
    }

    // ── Сеть клиник ──
    //
    // clinics_spec — единственный источник правды: куплена только
    // клиника №1, цены и потолки из данных, репутация стартовая.
    if (script_exists(asset_get_index("clinics_spec"))) {
        global.clinics = clinics_spec();
    }

    // ── Карманы всех четырёх клиник ──
    //
    // В кармане лежат персонал, склад, построенные помещения,
    // улучшения, репутация и картотека. Сбрасываем ВСЕ четыре:
    // иначе проданная или купленная в прошлой партии клиника
    // вернулась бы со старым штатом.
    if (script_exists(asset_get_index("clinic_state_init"))) {
        clinic_state_init();

        global.clinic_state = {};

        var _count = script_exists(asset_get_index("clinics_count"))
            ? clinics_count()
            : 4;

        for (var _id = 1; _id <= _count; _id++) {
            clinic_state_reset(_id);
        }
    }

    // ── Общие показатели сети ──
    global.clinic_money = new_game_start_money();
    global.clinic_points = new_game_start_points();
    global.clinic_reputation = 0;

    global.clinic_cleanliness = 100;
    global.clinic_name = "VetSim Clinic";

    // ── Время ──
    global.game_day = 1;
    global.game_hour = 8;
    global.game_minute = 0;

    // ── Картотека клиентов ──
    //
    // У каждой клиники своя база: db_clients_init чистит 13 общих
    // переменных, из которых потом собирается база клиники №1.
    if (script_exists(asset_get_index("db_clients_init"))) {
        db_clients_init();
    }

    // ── Построенные помещения и улучшения ──
    //
    // Старт: один кабинет приёма, без коек и без операционной.
    if (script_exists(asset_get_index("clinic_rooms_reset_default"))) {
        clinic_rooms_reset_default();
    }

    global.clinic_upgrades = {};

    if (script_exists(asset_get_index("clinic_upgrade_init"))) {
        clinic_upgrade_init();
    }

    // ── Куда встаёт игрок ──
    global.active_clinic = 1;

    // Проверка состава комнат после перезапуска должна отработать
    // заново.
    global.clinic_room_audited = {};

    show_debug_message(
        "[НОВАЯ ИГРА] Старт с нуля: клиника №1, деньги "
        + string(global.clinic_money)
        + ", баллы " + string(global.clinic_points)
        + ", репутация " + string(global.clinic_reputation)
        + ", день " + string(global.game_day) + "."
    );

    return true;
}
