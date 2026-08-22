/// clinic_upgrade_system.gml
/// @description Баллы клиники и дерево развития: слоты найма, библиотека, спортзал, аптека.
/// Пакет №71. Пакет №121: колонки РАЗВИТИЯ на матовом стекле.
/// Пакет №122: подложка-кнопка под счётчиком баллов.


// ═══════════════════════════════════════════════════════════════
// 1. ИНИЦИАЛИЗАЦИЯ И БАЛЛЫ
// Баллы начисляются за полное выздоровление пациента (100% состояния).
// ═══════════════════════════════════════════════════════════════

function clinic_upgrade_init() {
    if (!variable_global_exists("clinic_points")) {
        global.clinic_points = 0;
    }

    if (!variable_global_exists("clinic_upgrades")) {
        global.clinic_upgrades = {};
    }

    var _upgrade_keys = ["hire_slot", "library", "gym", "pharmacy"];

    for (var _index = 0; _index < array_length(_upgrade_keys); _index++) {
        if (!variable_struct_exists(global.clinic_upgrades, _upgrade_keys[_index])) {
            variable_struct_set(
                global.clinic_upgrades,
                _upgrade_keys[_index],
                0
            );
        }
    }
}

function clinic_upgrade_max_level() {
    return 5;
}

// Пакет №71 (правка): у каждого улучшения свой потолок.
// Пакет №173 (правка): «Слот найма» прокачивается до 14 уровня —
// 1 стартовый + 14 = 15 сотрудников максимум.
function clinic_upgrade_max_level_for(_upgrade_id) {
    if (string(_upgrade_id) == "hire_slot") return TREE_HIRE_MAX_LEVEL;

    return clinic_upgrade_max_level();
}

function clinic_get_points() {
    clinic_upgrade_init();
    return max(0, round(global.clinic_points));
}

function clinic_points_add(_amount) {
    clinic_upgrade_init();

    var _add = max(0, round(_amount));

    if (_add <= 0) return;

    global.clinic_points += _add;

    if (instance_exists(obj_UI_HUD)) {
        var _hud = instance_find(obj_UI_HUD, 0);

        if (
            instance_exists(_hud)
            && variable_instance_exists(_hud, "show_notice")
        ) {
            with (_hud) {
                show_notice(
                    "БАЛЛЫ +" + string(_add),
                    "Полное выздоровление! Всего баллов: "
                        + string(global.clinic_points),
                    max(1, game_get_speed(gamespeed_fps)) * 2
                );
            }
        }
    }
}

function clinic_points_spend(_amount) {
    clinic_upgrade_init();

    var _spend = max(0, round(_amount));

    if (global.clinic_points < _spend) return false;

    global.clinic_points -= _spend;
    return true;
}


// ═══════════════════════════════════════════════════════════════
// 2. УРОВНИ И ЦЕНЫ УЛУЧШЕНИЙ
// ═══════════════════════════════════════════════════════════════

function clinic_upgrade_level(_upgrade_id) {
    clinic_upgrade_init();

    var _key = string(_upgrade_id);

    if (variable_struct_exists(global.clinic_upgrades, _key)) {
        return clamp(
            round(variable_struct_get(global.clinic_upgrades, _key)),
            0,
            clinic_upgrade_max_level_for(_key)
        );
    }

    return 0;
}

function clinic_upgrade_is_maxed(_upgrade_id) {
    return clinic_upgrade_level(_upgrade_id)
        >= clinic_upgrade_max_level_for(_upgrade_id);
}

function clinic_upgrade_cost(_upgrade_id) {
    // Цена перехода на следующий уровень.
    var _next = clinic_upgrade_level(_upgrade_id) + 1;

    switch (string(_upgrade_id)) {
        case "hire_slot":
            switch (_next) {
                case 1: return 5;
                case 2: return 8;
                case 3: return 12;
                case 4: return 18;
                case 5: return 26;
                case 6: return 34;
                case 7: return 44;
                case 8: return 56;
                case 9: return 70;
                // Пакет №173: уровни 10–14, штат до 15 сотрудников.
                case 10: return 86;
                case 11: return 104;
                case 12: return 124;
                case 13: return 146;
                case 14: return 170;
            }
        break;

        case "library":
            switch (_next) {
                case 1: return 4;
                case 2: return 8;
                case 3: return 14;
                case 4: return 22;
                case 5: return 32;
            }
        break;

        case "gym":
            switch (_next) {
                case 1: return 4;
                case 2: return 8;
                case 3: return 14;
                case 4: return 22;
                case 5: return 32;
            }
        break;

        case "pharmacy":
            switch (_next) {
                case 1: return 3;
                case 2: return 6;
                case 3: return 10;
                case 4: return 16;
                case 5: return 24;
            }
        break;
    }

    return 99999;
}

function clinic_upgrade_apply(_upgrade_id) {
    clinic_upgrade_init();

    if (clinic_upgrade_is_maxed(_upgrade_id)) return false;

    var _cost = clinic_upgrade_cost(_upgrade_id);

    if (!clinic_points_spend(_cost)) {
        if (instance_exists(obj_UI_HUD)) {
            var _hud = instance_find(obj_UI_HUD, 0);

            if (
                instance_exists(_hud)
                && variable_instance_exists(_hud, "show_notice")
            ) {
                with (_hud) {
                    show_notice(
                        "МАЛО БАЛЛОВ",
                        "Нужно " + string(_cost) + " баллов.",
                        max(1, game_get_speed(gamespeed_fps)) * 2
                    );
                }
            }
        }

        return false;
    }

    var _key = string(_upgrade_id);
    var _new_level = clinic_upgrade_level(_key) + 1;

    variable_struct_set(global.clinic_upgrades, _key, _new_level);

    if (instance_exists(obj_UI_HUD)) {
        var _hud_ok = instance_find(obj_UI_HUD, 0);

        if (
            instance_exists(_hud_ok)
            && variable_instance_exists(_hud_ok, "show_notice")
        ) {
            with (_hud_ok) {
                show_notice(
                    clinic_upgrade_name(_key),
                    "Уровень " + string(_new_level)
                        + " из " + string(clinic_upgrade_max_level_for(_key)),
                    max(1, game_get_speed(gamespeed_fps)) * 2
                );
            }
        }
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 3. ЭФФЕКТЫ УЛУЧШЕНИЙ
// ═══════════════════════════════════════════════════════════════

function clinic_get_hire_slots() {
    // Стартовый лимит — 1 сотрудник (не считая главного игрока).
    // Пакет №173: максимум 1 + 14 = 15 сотрудников.
    return 1 + clinic_upgrade_level("hire_slot");
}

function clinic_get_library_bonus() {
    // +1 Терапия всем врачам (влияет на ручной приём игрока:
    // меньше ложных вариантов в карточке).
    return clinic_upgrade_level("library");
}

function clinic_get_gym_bonus_percent() {
    // +10% к скорости ходьбы персонала за уровень.
    return clinic_upgrade_level("gym") * 10;
}

function clinic_get_pharmacy_discount_percent() {
    // −5% на закупку препаратов за уровень.
    return clinic_upgrade_level("pharmacy") * 5;
}

function clinic_staff_count_for_slots() {
    return instance_number(obj_staff_doctor)
        + instance_number(obj_staff_admin)
        + instance_number(obj_staff_assistant);
}

function clinic_hire_slot_available() {
    return clinic_staff_count_for_slots() < clinic_get_hire_slots();
}


// ═══════════════════════════════════════════════════════════════
// 4. ТЕКСТЫ ДЛЯ ПАНЕЛИ
// ═══════════════════════════════════════════════════════════════

function clinic_upgrade_name(_upgrade_id) {
    switch (string(_upgrade_id)) {
        case "hire_slot": return "Слот найма";
        case "library": return "Библиотека";
        case "gym": return "Спортзал";
        case "pharmacy": return "Аптека";
    }

    return "Улучшение";
}

function clinic_upgrade_effect_now(_upgrade_id) {
    switch (string(_upgrade_id)) {
        case "hire_slot":
            return "Слотов для сотрудников: " + string(clinic_get_hire_slots());
        case "library":
            return "+" + string(clinic_get_library_bonus())
                + " Терапия всем врачам";
        case "gym":
            return "+" + string(clinic_get_gym_bonus_percent())
                + "% к скорости персонала";
        case "pharmacy":
            return "Скидка на закупку: -"
                + string(clinic_get_pharmacy_discount_percent())
                + "%";
    }

    return "";
}

function clinic_upgrade_effect_next(_upgrade_id) {
    if (clinic_upgrade_is_maxed(_upgrade_id)) {
        return "Максимальный уровень";
    }

    var _cost = clinic_upgrade_cost(_upgrade_id);

    switch (string(_upgrade_id)) {
        case "hire_slot":
            return "След.: " + string(clinic_get_hire_slots() + 1)
                + " слотов за " + string(_cost) + " баллов";
        case "library":
            return "След.: +" + string(clinic_get_library_bonus() + 1)
                + " Терапия за " + string(_cost) + " баллов";
        case "gym":
            return "След.: +" + string(clinic_get_gym_bonus_percent() + 10)
                + "% за " + string(_cost) + " баллов";
        case "pharmacy":
            return "След.: -" + string(clinic_get_pharmacy_discount_percent() + 5)
                + "% за " + string(_cost) + " баллов";
    }

    return "";
}


// ═══════════════════════════════════════════════════════════════
// 5. ПАНЕЛЬ «РАЗВИТИЕ» (вкладка КЛИНИКА → РАЗВИТИЕ)
// ═══════════════════════════════════════════════════════════════

function hud_draw_clinic_upgrades(_hud) {
    // Пакет №173: панель РАЗВИТИЕ переехала на дерево веток.
    // Старая версия рисовала две колонки со строчками: слева ПОМЕЩЕНИЯ (деньги),
    // справа УЛУЧШЕНИЯ (баллы). Теперь это общий блок сверху и три ветки —
    // ПРИЁМ, СТАЦИОНАР, ОПЕРАЦИОННАЯ, обе валюты в одной таблице.
    //
    // Вся отрисовка и клики — в Script Asset clinic_tree_panel.
    // Логика уровней, цен и эффектов улучшений осталась здесь, ниже по файлу.
    clinic_tree_draw(_hud);
}
