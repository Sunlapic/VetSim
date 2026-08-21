/// world_clicks_blocked.gml
/// @description Быстрый единый блокировщик мира и камеры без покадровых массивов.


// ═══════════════════════════════════════════════════════════════
// 1. РЕЕСТР БУДУЩИХ МОДАЛЬНЫХ ПАНЕЛЕЙ
// Счётчик не создаёт временные массивы при каждой проверке.
// ═══════════════════════════════════════════════════════════════

function ui_modal_registry_init() {
    if (!variable_global_exists("__ui_modal_locks")) {
        global.__ui_modal_locks = {};
    }

    if (!variable_global_exists("__ui_modal_lock_count")) {
        global.__ui_modal_lock_count = 0;
    }
}

function ui_modal_lock_acquire(_key) {
    ui_modal_registry_init();

    var _name = string(_key);
    var _already_active = variable_struct_exists(
        global.__ui_modal_locks,
        _name
    ) && variable_struct_get(global.__ui_modal_locks, _name);

    if (!_already_active) {
        variable_struct_set(
            global.__ui_modal_locks,
            _name,
            true
        );
        global.__ui_modal_lock_count += 1;
    }

    return true;
}

function ui_modal_lock_release(_key) {
    ui_modal_registry_init();

    var _name = string(_key);
    var _was_active = variable_struct_exists(
        global.__ui_modal_locks,
        _name
    ) && variable_struct_get(global.__ui_modal_locks, _name);

    if (_was_active) {
        variable_struct_set(
            global.__ui_modal_locks,
            _name,
            false
        );
        global.__ui_modal_lock_count = max(
            0,
            global.__ui_modal_lock_count - 1
        );
    }

    return true;
}

function ui_modal_custom_lock_active() {
    ui_modal_registry_init();
    return global.__ui_modal_lock_count > 0;
}


// ═══════════════════════════════════════════════════════════════
// 2. ТЕКУЩИЕ ПАНЕЛИ HUD
// В игре один HUD, поэтому обход всех instances не нужен.
// ═══════════════════════════════════════════════════════════════

function ui_hud_modal_panel_open() {
    if (!instance_exists(obj_UI_HUD)) return false;

    var _hud = instance_find(obj_UI_HUD, 0);

    if (!instance_exists(_hud)) return false;
    if (variable_instance_exists(_hud, "visible") && !_hud.visible) {
        return false;
    }

    if (_hud.staff_panel_open) return true;
    if (_hud.clinic_panel_open) return true;
    if (_hud.clients_panel_open) return true;
    if (_hud.finance_panel_open) return true;
    if (_hud.hiring_panel_open) return true;
    if (_hud.fire_confirm_open) return true;

    if (
        variable_instance_exists(_hud, "handbook_open")
        && _hud.handbook_open
    ) {
        return true;
    }

    if (
        variable_instance_exists(_hud, "staff_manage_panel_open")
        && _hud.staff_manage_panel_open
    ) {
        return true;
    }

    if (
        variable_instance_exists(_hud, "staff_manage_draw_requested")
        && _hud.staff_manage_draw_requested
    ) {
        return true;
    }

    if (
        variable_instance_exists(_hud, "finance_manage_panel_open")
        && _hud.finance_manage_panel_open
    ) {
        return true;
    }

    if (
        variable_instance_exists(_hud, "finance_manage_draw_requested")
        && _hud.finance_manage_draw_requested
    ) {
        return true;
    }

    if (
        variable_instance_exists(_hud, "staff_manage_fire_confirm")
        && _hud.staff_manage_fire_confirm
    ) {
        return true;
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 3. ДРУГИЕ ТЕКУЩИЕ МОДАЛЬНЫЕ ОКНА
// Никаких локальных массивов и variable_*_get в каждом кадре.
// ═══════════════════════════════════════════════════════════════

function ui_other_modal_panel_open() {
    if (
        instance_exists(obj_UI_Tablet)
        && obj_UI_Tablet.visible
    ) {
        return true;
    }

    if (
        instance_exists(obj_UI_CandidateCard)
        && obj_UI_CandidateCard.visible
    ) {
        return true;
    }

    if (variable_global_exists("radial_open") && global.radial_open) {
        return true;
    }

    if (variable_global_exists("clean_menu_open") && global.clean_menu_open) {
        return true;
    }

    if (variable_global_exists("day_summary_open") && global.day_summary_open) {
        return true;
    }

    if (variable_global_exists("pause_menu_open") && global.pause_menu_open) {
        return true;
    }

    if (variable_global_exists("settings_menu_open") && global.settings_menu_open) {
        return true;
    }

    if (variable_global_exists("tutorial_open") && global.tutorial_open) {
        return true;
    }

    if (variable_global_exists("dialog_open") && global.dialog_open) {
        return true;
    }

    if (variable_global_exists("modal_open") && global.modal_open) {
        return true;
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 4. ЕДИНЫЙ БЛОКИРОВЩИК МИРА И КАМЕРЫ
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// 3.5 ПАКЕТ №172: ЗАЩЕЛКА ЗАКРЫВАЮЩЕГО КЛИКА
//
// Проблема: крестик карточки, кнопки панелей и «НОВЫЙ ДЕНЬ» закрывают окно
// в СВОЁМ обработчике, и к моменту, когда obj_player читает тот же самый
// клик, окна уже нет — world_clicks_blocked() возвращает false, и герой
// уходит в точку под крестиком.
//
// Решение: ui_modal_guard_step() вызывается РАЗ в кадр из
// obj_Render → Begin Step. Все Begin Step в GameMaker гарантированно
// выполняются раньше любого Step, поэтому защёлка успевает встать до того,
// как игрок прочитает нажатие — независимо от порядка объектов.
// ═══════════════════════════════════════════════════════════════

function ui_modal_state_now() {
    if (
        variable_global_exists("ui_block_world_click")
        && global.ui_block_world_click
    ) {
        return true;
    }

    if (ui_hud_modal_panel_open()) return true;
    if (ui_other_modal_panel_open()) return true;

    return ui_modal_custom_lock_active();
}

function ui_modal_guard_step() {
    if (!variable_global_exists("ui_modal_open_prev")) {
        global.ui_modal_open_prev = false;
    }

    if (!variable_global_exists("ui_modal_close_guard")) {
        global.ui_modal_close_guard = 0;
    }

    var _now = ui_modal_state_now();

    // Нажатие произошло, пока окно было открыто (сейчас или в прошлом кадре).
    // Гасим мир на несколько кадров: этот клик принадлежит интерфейсу.
    if (
        mouse_check_button_pressed(mb_left)
        && (_now || global.ui_modal_open_prev)
    ) {
        global.ui_modal_close_guard = 10;

        // На телефоне тап подтверждается на ОТПУСКАНИЕ пальца, уже после
        // закрытия окна. Пользуемся штатным подавителем тапа.
        if (variable_global_exists("touch_suppress_tap")) {
            global.touch_suppress_tap = true;
        }
    }

    if (global.ui_modal_close_guard > 0) {
        global.ui_modal_close_guard -= 1;
    }

    global.ui_modal_open_prev = _now;
}


function world_clicks_blocked() {
    // Пакет №172: клик, которым закрыли окно, не уходит в мир.
    if (
        variable_global_exists("ui_modal_close_guard")
        && global.ui_modal_close_guard > 0
    ) {
        return true;
    }

    // Пакет №82: клик по миру заблокирован и когда курсор находится над
    // верхней/нижней панелью HUD (global.ui_block_world_click вычисляется
    // в Begin Step obj_UI_HUD). Раньше кнопки меню «протекали»: клик по
    // «ПЕРСОНАЛ» и т.п. уходил в мир, и герой шёл к точке под кнопкой.
    if (
        variable_global_exists("ui_block_world_click")
        && global.ui_block_world_click
    ) {
        return true;
    }

    if (ui_hud_modal_panel_open()) return true;
    if (ui_other_modal_panel_open()) return true;
    return ui_modal_custom_lock_active();
}

function world_camera_input_blocked() {
    return world_clicks_blocked();
}
