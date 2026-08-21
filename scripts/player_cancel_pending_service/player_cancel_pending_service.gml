/// player_cancel_pending_service(_player)
/// @description Отменяет ещё не начавшийся путь к владельцу и освобождает бронь.

function player_cancel_pending_service(_player) {
    if (!instance_exists(_player)) return false;
    if (!variable_instance_exists(_player, "doctor_state")) return false;
    if (_player.doctor_state != "going_to_owner") return false;

    var _owner = _player.assigned_owner;
    var _table = _player.assigned_table;
    var _pet = _player.assigned_pet;

    if (instance_exists(_table)) {
        // У старых версий бронь могла поставить table_busy раньше,
        // чем записать assigned_doctor. Поэтому также сверяем владельца
        // и саму ссылку assigned_table у игрока.
        var _table_belongs_to_pending_service = (
            _table.assigned_doctor == _player
            || _table.assigned_owner == _owner
            || _player.assigned_table == _table
        );

        if (_table_belongs_to_pending_service) {
            _table.table_busy = false;
            _table.assigned_owner = noone;
            _table.assigned_doctor = noone;
            _table.assigned_pet = noone;
        }
    }

    if (instance_exists(_owner)) {
        if (_owner.assigned_doctor == _player) {
            _owner.assigned_doctor = noone;
        }

        if (_owner.assigned_table == _table) {
            _owner.assigned_table = noone;
        }

        // До контакта с игроком владелец ещё не покинул waiting spot.
        if (_owner.state != "leaving_clinic") {
            _owner.state = "waiting";
            _owner.is_walking = false;
        }
    }

    if (instance_exists(_pet)) {
        if (_pet.assigned_doctor == _player) _pet.assigned_doctor = noone;
        if (_pet.assigned_table == _table) _pet.assigned_table = noone;
    }

    with (_player) {
        path_end();
        speed = 0;
        is_walking = false;

        assigned_owner = noone;
        assigned_table = noone;
        assigned_pet = noone;
        service_mode = "";
        doctor_state = "idle";
    }

    return true;
}
