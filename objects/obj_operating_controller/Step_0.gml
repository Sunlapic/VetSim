/// Step obj_operating_controller

operating_controller_step(id);

// Пакет №165: отладочные клавиши операционной.
// Работают только при global.vetsim_debug_mode = true (obj_Render → Create).
// Перед релизом достаточно выключить debug-режим — строку удалять не обязательно.
operating_debug_keys(id);
