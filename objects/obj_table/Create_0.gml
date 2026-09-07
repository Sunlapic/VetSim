///Create obj_table

event_inherited();

// ═══════════════════════════════════════════════════════════════
// Уникальный слот кабинета / стола
//
// ПАКЕТ №316: ЗДЕСЬ ЛЕГКО ОШИБИТЬСЯ, ПОЭТОМУ ДОБАВЛЕНА ПРОВЕРКА
//
// Значение по умолчанию — 1, а слот 1 в clinic_room_is_open открыт
// безусловно (`if (_slot_id <= 1) return true;`). Значит стол, у
// которого в Creation Code инстанса ЗАБЫЛИ прописать exam_slot_id,
// молча становится вторым столом первого кабинета — открытым и
// бесплатным.
//
// Именно так и вышло со вторым столом в rm_clinic: кабинет числился
// закрытым, а стол работал, потому что считал себя слотом 1.
//
// Сообщение ниже пишется в консоль при запуске и сразу показывает,
// какому инстансу не хватает строки.
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "exam_slot_id")) {
    exam_slot_id = 1;

    if (
        variable_global_exists("vetsim_debug_mode")
        && global.vetsim_debug_mode
    ) {
        show_debug_message(
            "[TABLE] Стол в позиции ("
            + string(x) + "," + string(y)
            + ") без exam_slot_id — считается кабинетом 1. "
            + "Если это второй стол, добавь exam_slot_id = 2; "
            + "в Creation Code инстанса."
        );
    }
}

// Состояние стола
table_busy = false;
assigned_owner = noone;
assigned_doctor = noone;
assigned_pet = noone;

// Длительность приёма
exam_duration = room_speed * 5;

// Базовая interact point логика
interact_x = x;
interact_y = y + 40;


