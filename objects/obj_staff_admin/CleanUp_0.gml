/// Cleanup obj_staff_admin
/// @description Безопасно освобождает клиента при увольнении администратора.


// ═══════════════════════════════════════════════════════════════
// 1. СОХРАНЯЕМ ССЫЛКИ ДО РОДИТЕЛЬСКОЙ ОЧИСТКИ
// ═══════════════════════════════════════════════════════════════

var _interrupted_client = noone;
var _reception_desk = noone;

if (
    variable_instance_exists(id, "reception_client")
    && instance_exists(reception_client)
) {
    _interrupted_client = reception_client;
}

if (
    variable_instance_exists(id, "reception_desk")
    && instance_exists(reception_desk)
) {
    _reception_desk = reception_desk;
}
else if (instance_exists(obj_reception_desk)) {
    _reception_desk = instance_find(obj_reception_desk, 0);
}


// ═══════════════════════════════════════════════════════════════
// 2. НЕМЕДЛЕННО ВОЗВРАЩАЕМ КЛИЕНТА В ОЧЕРЕДЬ
// ═══════════════════════════════════════════════════════════════

var _client_was_recovered = false;

if (instance_exists(_interrupted_client)) {
    _client_was_recovered = reception_recover_orphaned_registration(
        _interrupted_client,
        true
    );
}

if (instance_exists(_reception_desk)) {
    _reception_desk.alarm[0] = 1;
}


// ═══════════════════════════════════════════════════════════════
// 3. СБРОС ЛОКАЛЬНОГО ДЕЙСТВИЯ АДМИНИСТРАТОРА
// ═══════════════════════════════════════════════════════════════

if (variable_instance_exists(id, "action_progress_active")) {
    action_progress_active = false;
    action_progress_timer = 0;
    action_progress_timer_max = 0;
}

if (variable_instance_exists(id, "reception_client")) {
    reception_client = noone;
}

path_end();
speed = 0;
is_walking = false;


// ═══════════════════════════════════════════════════════════════
// 4. УВЕДОМЛЕНИЕ
// ═══════════════════════════════════════════════════════════════

if (_client_was_recovered && instance_exists(obj_UI_HUD)) {
    var _hud = instance_find(obj_UI_HUD, 0);

    if (
        instance_exists(_hud)
        && variable_instance_exists(_hud, "show_notice")
    ) {
        with (_hud) {
            show_notice(
                "ОФОРМЛЕНИЕ ПРЕРВАНО",
                "Клиент возвращён в начало очереди",
                room_speed * 3
            );
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// 5. ОБЩАЯ ОЧИСТКА ПЕРСОНАЛА
// ═══════════════════════════════════════════════════════════════

event_inherited();
