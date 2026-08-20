// ─────────────────────────────────────────────
// Create obj_monitor — с фиксированным положением на экране
// (подставляй свои цифры в monitor_screen_x / monitor_screen_y)
// ─────────────────────────────────────────────
event_inherited();

// Монитор рисуется полностью кодом
sprite_index = -1;

// Настройки
monitor_w = 400;
monitor_h = 140;
monitor_list = [];
max_rows = 6;
can_hover = false;
has_shadow = false;

// ═══════════════════════════════════════════
// РЕГУЛИРОВКА ПОЛОЖЕНИЯ ЗДЕСЬ
// ═══════════════════════════════════════════
// Координаты ЛЕВОГО ВЕРХНЕГО угла корпуса монитора в комнате.
// УМЕНЬШАЙ monitor_screen_x — сдвинется ВЛЕВО
// УВЕЛИЧИВАЙ monitor_screen_x — сдвинется ВПРАВО
// УМЕНЬШАЙ monitor_screen_y — сдвинется ВВЕРХ
// УВЕЛИЧИВАЙ monitor_screen_y — сдвинется ВНИЗ
monitor_screen_x = 1300;     // ← крути эту цифру (было x от инстанса в комнате)
monitor_screen_y = 900;     // ← и эту, если нужно вверх/вниз
// ═══════════════════════════════════════════

// Насколько выше точки объекта рисуется монитор (для совместимости,
// теперь _draw_y считается относительно monitor_screen_y, а не y инстанса)
draw_offset_y = 0;

// Применяем фиксированные координаты к инстансу, чтобы не зависеть от позиции в Room Editor
x = monitor_screen_x;
y = monitor_screen_y;

// Метод добавления строки на монитор
add_to_monitor = function(_name, _destination) {
    array_insert(monitor_list, 0, {
        patient_name : _name,
        destination  : _destination
    });
    if (array_length(monitor_list) > 10) {
        array_pop(monitor_list);
    }
};
