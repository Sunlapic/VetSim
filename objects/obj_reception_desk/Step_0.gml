/// Step obj_reception_desk

// ─────────────────────────────────────────────
// ИНИЦИАЛИЗАЦИЯ И ПРОВЕРКА ТОЧЕК
// ─────────────────────────────────────────────

var _points_need_refresh = !reception_points_ready;

if (
    reception_points_ready
    && !instance_exists(reception_owner_point)
) {
    _points_need_refresh = true;
}

if (
    reception_points_ready
    && !instance_exists(reception_staff_point)
) {
    _points_need_refresh = true;
}

// Если ID точки был изменён или точка больше не соответствует стойке
if (
    instance_exists(reception_owner_point)
    && reception_owner_point.reception_slot_id
        != reception_slot_id
) {
    _points_need_refresh = true;
}

if (
    instance_exists(reception_staff_point)
    && reception_staff_point.reception_slot_id
        != reception_slot_id
) {
    _points_need_refresh = true;
}

if (_points_need_refresh) {

    var _points_found = reception_refresh_points();

    if (_points_found) {
        // После получения новых координат перестраиваем очередь
        alarm[0] = 1;
    }
}

// ─────────────────────────────────────────────
// ЧИСТИМ УДАЛЁННЫХ КЛИЕНТОВ
// ─────────────────────────────────────────────

var _needs_shift = false;

for (
    var _queue_i = ds_list_size(queue_list) - 1;
    _queue_i >= 0;
    _queue_i--
) {
    var _client = queue_list[| _queue_i];

    if (!instance_exists(_client)) {
        ds_list_delete(queue_list, _queue_i);
        _needs_shift = true;
    }
}

if (_needs_shift) {
    alarm[0] = 1;
}