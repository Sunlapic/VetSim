/// db_apply_pet_record_to_instance(_record, _pet_inst)
/// @description Восстанавливает питомца из постоянной записи.

function db_apply_pet_record_to_instance(_record, _pet_inst) {
    if (!is_struct(_record)) return false;
    if (!instance_exists(_pet_inst)) return false;


    // ═══════════════════════════════════════════════════════════
    // 1. ОСНОВНЫЕ ДАННЫЕ
    // ═══════════════════════════════════════════════════════════

    _pet_inst.char_name = variable_struct_exists(_record, "name")
        ? _record.name
        : "Питомец";

    _pet_inst.species_id = variable_struct_exists(_record, "species")
        ? _record.species
        : "dog";

    _pet_inst.breed = variable_struct_exists(_record, "breed")
        ? _record.breed
        : "Неизвестно";

    _pet_inst.age = variable_struct_exists(_record, "age_text")
        ? _record.age_text
        : "Неизвестно";

    _pet_inst.pet_age_days = variable_struct_exists(_record, "pet_age_days")
        ? max(0, round(_record.pet_age_days))
        : 0;

    _pet_inst.problem = variable_struct_exists(_record, "problem")
        ? _record.problem
        : "Причина не указана";

    _pet_inst.condition = variable_struct_exists(_record, "condition")
        ? _record.condition
        : 100;

    _pet_inst.life_stage = variable_struct_exists(_record, "life_stage")
        ? _record.life_stage
        : 0;


    // ═══════════════════════════════════════════════════════════
    // 2. ВНЕШНОСТЬ
    // ═══════════════════════════════════════════════════════════

    if (variable_struct_exists(_record, "appearance") && is_struct(_record.appearance)) {
        var _appearance = _record.appearance;

        if (
            variable_struct_exists(_appearance, "sprite_id")
            && _appearance.sprite_id != ""
        ) {
            var _sprite = asset_get_index(_appearance.sprite_id);

            if (sprite_exists(_sprite)) {
                _pet_inst.sprite_index = _sprite;
            }
        }

        if (variable_struct_exists(_appearance, "scale_x")) {
            _pet_inst.image_xscale = abs(_appearance.scale_x);
        }

        if (variable_struct_exists(_appearance, "scale_y")) {
            _pet_inst.image_yscale = abs(_appearance.scale_y);
        }
    }

    return true;
}
