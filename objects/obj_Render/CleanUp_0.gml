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

var _save_fn = asset_get_index("vetsim_save");

if (!_skip_save && _save_fn != -1 && script_exists(_save_fn)) {
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
