/// Step obj_storage_cabinet
/// @description Инициализация шкафа с пользовательским флагом отладки.

event_inherited();

// Новый пользовательский флаг отладки из obj_Render → Create.
var _debug_enabled = (
    variable_global_exists("vetsim_debug_mode")
    && global.vetsim_debug_mode
);

// На первом кадре Room Creation Code уже успел выставить exam_slot_id.
if (!_cabinet_inited) {
    _cabinet_inited = true;

    // Точка перед шкафом, к которой подходит ассистент.
    interact_x = x;
    interact_y = y + 40;

    if (
        !variable_instance_exists(id, "exam_slot_id")
        || exam_slot_id <= 0
    ) {
        storage_name_ru = "Шкаф БЕЗ СЛОТА!";

        // Инвентарь намеренно остаётся пустым, чтобы проблема была заметна.
        storage_inventory = {};

        if (_debug_enabled) {
            show_debug_message(
                "[CABINET] Шкаф в позиции ("
                + string(x)
                + ","
                + string(y)
                + ") не имеет exam_slot_id! "
                + "Добавь exam_slot_id = N; в Creation Code инстанса."
            );
        }
    }
    else {
        storage_name_ru = "Шкаф кабинета " + string(exam_slot_id);

        if (
            !variable_instance_exists(id, "storage_inventory")
            || !is_struct(storage_inventory)
        ) {
            storage_inventory = {};
        }

        // Стартовый запас по 3 единицы создаётся только в пустой ячейке.
        for (
            var _item_index = 0;
            _item_index < array_length(global.item_ids);
            _item_index++
        ) {
            var _item_id = global.item_ids[_item_index];

            if (inventory_get_amount(storage_inventory, _item_id) == 0) {
                inventory_add_amount(
                    storage_inventory,
                    _item_id,
                    3
                );
            }
        }

        if (_debug_enabled) {
            show_debug_message(
                "[CABINET] Инициализирован "
                + storage_name_ru
                + " в ("
                + string(x)
                + ","
                + string(y)
                + ")"
            );
        }
    }
}

// Шкаф корректно сортируется по глубине относительно ассистента.
depth = -y;
