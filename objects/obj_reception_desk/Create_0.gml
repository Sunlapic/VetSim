/// Create obj_reception_desk
/// @description Настройка стойки регистратуры через точки комнаты

event_inherited();

queue_list = ds_list_create();

// Номер стойки.
// Для первой стойки — 1, для второй — 2 и т. д.
if (!variable_instance_exists(id, "reception_slot_id")) {
    reception_slot_id = 1;
}

// Найденные объекты-точки
reception_owner_point = noone;
reception_staff_point = noone;
reception_points_ready = false;

// ─────────────────────────────────────────────
// Резервные координаты
// Используются, только если точки забыли поставить
// ─────────────────────────────────────────────

queue_start_x = interact_x - 60;
queue_start_y = interact_y;

// Направление остальных клиентов от первого.
// Сейчас очередь продолжается влево.
queue_step_x = -50;
queue_step_y = 0;

admin_spot_x = queue_start_x;
admin_spot_y = y - 40;

// ─────────────────────────────────────────────
// ПОИСК ТОЧЕК ЭТОЙ СТОЙКИ
// ─────────────────────────────────────────────

reception_refresh_points = function() {

    reception_owner_point = noone;
    reception_staff_point = noone;

    // Ищем клиентскую точку
    for (
        var _owner_i = 0;
        _owner_i < instance_number(obj_reception_point_owner);
        _owner_i++
    ) {
        var _owner_point =
            instance_find(obj_reception_point_owner, _owner_i);

        if (!instance_exists(_owner_point)) continue;

        if (!variable_instance_exists(
            _owner_point,
            "reception_slot_id"
        )) {
            continue;
        }

        if (
            _owner_point.reception_slot_id
            == reception_slot_id
        ) {
            reception_owner_point = _owner_point;
            break;
        }
    }

    // Ищем точку персонала
    for (
        var _staff_i = 0;
        _staff_i < instance_number(obj_reception_point_staff);
        _staff_i++
    ) {
        var _staff_point =
            instance_find(obj_reception_point_staff, _staff_i);

        if (!instance_exists(_staff_point)) continue;

        if (!variable_instance_exists(
            _staff_point,
            "reception_slot_id"
        )) {
            continue;
        }

        if (
            _staff_point.reception_slot_id
            == reception_slot_id
        ) {
            reception_staff_point = _staff_point;
            break;
        }
    }

    // Первая позиция очереди теперь берётся из Room Editor
    if (instance_exists(reception_owner_point)) {
        queue_start_x = reception_owner_point.x;
        queue_start_y = reception_owner_point.y;
    }

    // Позиция администратора и игрока
    if (instance_exists(reception_staff_point)) {
        admin_spot_x = reception_staff_point.x;
        admin_spot_y = reception_staff_point.y;
    }

    reception_points_ready =
        instance_exists(reception_owner_point)
        && instance_exists(reception_staff_point);

    return reception_points_ready;
};