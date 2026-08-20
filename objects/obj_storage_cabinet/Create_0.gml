/// Create obj_storage_cabinet
event_inherited();

sprite_index = spr_cabinet;
image_speed = 0;

// В Create exam_slot_id ЕЩЁ НЕ УСТАНОВЛЕН — его выставит
// Room Creation Code инстанса ПОЗЖЕ. Поэтому мы НЕ рассчитываем
// на него в Create, а сделаем всю инициализацию на первом кадре Step.
//
// Значение по умолчанию = 0 (сигнал "ещё не настроен")
if (!variable_instance_exists(id, "exam_slot_id")) {
    exam_slot_id = 0;
}

storage_name_ru = "";
if (!variable_instance_exists(id, "storage_inventory")) {
    storage_inventory = noone; // отложенная инициализация
}
_cabinet_inited = false; // <-- флаг одноразовой инициализации

depth = -y;
