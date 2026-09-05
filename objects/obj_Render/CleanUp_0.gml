/// Cleanup obj_Render
/// @description Освобождает динамическую навигационную сетку комнаты.
/// Пакет №269: перед выходом сохраняет игру.


// ═══════════════════════════════════════════════════════════════
// СОХРАНЕНИЕ ПРИ ВЫХОДЕ (пакет №269)
//
// CleanUp срабатывает и при закрытии игры, и при смене комнаты —
// то есть в обоих случаях, когда состояние может потеряться.
//
// Сохраняем ДО уничтожения сетки: сотрудники ещё живы и их можно
// свернуть в слепки.
//
// script_exists — защита на случай, если скрипт save_system не создан
// в IDE: игра просто не сохранится, но не упадёт.
// ═══════════════════════════════════════════════════════════════

// Пакет 271: «Новая игра» ставит save_skip_on_exit, чтобы Clean Up
// не воссоздал только что удалённый файл сохранения. Без этой
// проверки новая игра возвращала бы старое состояние.
var _skip_save = variable_global_exists("save_skip_on_exit")
    && global.save_skip_on_exit;

// ═══════════════════════════════════════════════════════════════
// ПАКЕТ №309: НЕ СОХРАНЯТЬ ПРИ СМЕНЕ КОМНАТЫ
//
// CleanUp вызывается в двух совершенно разных случаях: при выходе из
// игры и при переходе в другую комнату. Сохранять нужно только в
// первом.
//
// Во втором это опасно. Объекты комнаты создаются по очереди, и
// obj_Render может оказаться раньше коек стационара: у части
// obj_inpatient_controller событие Create ещё не выполнялось,
// переменной phase не существует, а save_build_wards её читает.
// Игра падала с «Variable obj_inpatient_controller.phase not set».
//
// Отличить один случай от другого автоматически нельзя: в обоих
// CleanUp выглядит одинаково. Поэтому используется явный флаг
// global.clinic_room_transition — его поднимают перед каждым
// room_goto и снимают в Room Start новой комнаты.
//
// Сохранение при переезде между клиниками не теряется: персонал и
// склад сворачиваются в карман клиники в clinics_enter (пакет 301),
// а полное сохранение произойдёт при выходе из игры или в новый день.
// ═══════════════════════════════════════════════════════════════

var _room_change = (
    variable_global_exists("clinic_room_transition")
    && global.clinic_room_transition
);

var _save_fn = asset_get_index("vetsim_save");

if (!_skip_save && !_room_change && _save_fn != -1 && script_exists(_save_fn)) {
    vetsim_save();
}


if (
    variable_global_exists("ai_grid")
    && global.ai_grid != -1
) {
    mp_grid_destroy(global.ai_grid);
    global.ai_grid = -1;
}

// Старые ссылки на объекты комнаты не должны переходить в следующую комнату.
if (variable_global_exists("hover_target")) {
    global.hover_target = noone;
}

if (variable_global_exists("current_candidate")) {
    global.current_candidate = noone;
}

if (variable_global_exists("selected_candidate")) {
    global.selected_candidate = noone;
}

if (variable_global_exists("restock_jobs")) {
    global.restock_jobs = [];
}
