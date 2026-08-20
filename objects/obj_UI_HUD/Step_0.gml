/// Step obj_UI_HUD
/// @description Поиск клиентов и открытие точной вкладки выбранного шкафа.
/// Пакет №101: таймеры уведомлений переехали в hud_draw_notifications (Draw GUI).

if (!visible) exit;


// ═══════════════════════════════════════════════════════════════
// 0. ЗАПОМИНАЕМ КОНКРЕТНОЕ ХРАНИЛИЩЕ ИЗ РАДИАЛЬНОГО МЕНЮ
// Draw GUI закрывает radial после кнопки «ОТКРЫТЬ». На следующем Step
// восстанавливаем точный instance шкафа вместо первой строки «СКЛАД».
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "storage_open_pending_target")) {
    storage_open_pending_target = noone;
    storage_open_pending_kind = "";
    storage_radial_was_open = false;
}

var _radial_is_open = (
    variable_global_exists("radial_open")
    && global.radial_open
);

if (
    _radial_is_open
    && variable_global_exists("radial_target")
    && instance_exists(global.radial_target)
) {
    var _storage_target = global.radial_target;
    var _storage_object = _storage_target.object_index;
    var _target_is_cabinet = (
        _storage_object == obj_storage_cabinet
        || object_is_ancestor(
            _storage_object,
            obj_storage_cabinet
        )
    );
    var _target_is_main = (
        _storage_object == obj_storage_main
        || object_is_ancestor(
            _storage_object,
            obj_storage_main
        )
    );

    if (_target_is_cabinet) {
        storage_open_pending_target = _storage_target;
        storage_open_pending_kind = "cabinet";
    }
    else if (_target_is_main) {
        storage_open_pending_target = _storage_target;
        storage_open_pending_kind = "main";
    }
}

// Переход true → false происходит после обработки кнопки в Draw GUI.
if (
    storage_radial_was_open
    && !_radial_is_open
    && clinic_panel_open
    && clinic_subtab == "storage"
    && storage_open_pending_kind != ""
) {
    if (
        storage_open_pending_kind == "cabinet"
        && instance_exists(storage_open_pending_target)
    ) {
        storage_scope_selected = "cab_"
            + string(storage_open_pending_target);
        storage_scope_selected_inst = storage_open_pending_target;
    }
    else if (storage_open_pending_kind == "main") {
        storage_scope_selected = "main";
        storage_scope_selected_inst = noone;
    }

    storage_open_pending_target = noone;
    storage_open_pending_kind = "";
}

// Если radial закрыли без открытия панели, старую цель не переносим
// на следующее взаимодействие.
if (
    storage_radial_was_open
    && !_radial_is_open
    && !(clinic_panel_open && clinic_subtab == "storage")
) {
    storage_open_pending_target = noone;
    storage_open_pending_kind = "";
}

storage_radial_was_open = _radial_is_open;


// ═══════════════════════════════════════════════════════════════
// 1. УВЕДОМЛЕНИЯ (пакет №101)
// Таймеры, падение, затухание и отрисовка стопки теперь целиком внутри
// hud_draw_notifications (Draw GUI). Здесь для уведомлений ничего нет.
// ═══════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════
// 2. ПОИСК КЛИЕНТОВ
// ═══════════════════════════════════════════════════════════════

if (!clients_panel_open) {
    client_search_active = false;
}

if (client_search_active) {
    client_search_caret_timer += 1;

    if (client_search_caret_timer >= 20) {
        client_search_caret_timer = 0;
        client_search_caret_visible = !client_search_caret_visible;
    }
} else {
    client_search_caret_timer = 0;
    client_search_caret_visible = false;
}

if (clients_panel_open && client_search_active) {
    client_search_text = keyboard_string;

    if (string_length(client_search_text) > 40) {
        client_search_text = string_copy(client_search_text, 1, 40);
        keyboard_string = client_search_text;
    }

    if (keyboard_check_pressed(vk_enter)) {
        client_search_active = false;
    }

    if (keyboard_check_pressed(vk_escape)) {
        client_search_active = false;
    }
}
