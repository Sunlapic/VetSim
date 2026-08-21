/// db_make_pet_record_from_instance(_pet, _owner_id)
/// @description Создаёт постоянную запись питомца из экземпляра.

function db_make_pet_record_from_instance(_pet, _owner_id) {
    if (!instance_exists(_pet)) return undefined;


    // ═══════════════════════════════════════════════════════════
    // 1. ВНЕШНОСТЬ
    // ═══════════════════════════════════════════════════════════

    var _sprite_id = sprite_exists(_pet.sprite_index)
        ? sprite_get_name(_pet.sprite_index)
        : "";


    // ═══════════════════════════════════════════════════════════
    // 2. ЗАПИСЬ ПИТОМЦА
    // ═══════════════════════════════════════════════════════════

    return {
        pet_id : db_next_pet_id(),
        owner_id : _owner_id,

        name : variable_instance_exists(_pet, "char_name")
            ? string(_pet.char_name)
            : "Питомец",

        species : variable_instance_exists(_pet, "species_id")
            ? string(_pet.species_id)
            : "dog",

        breed : variable_instance_exists(_pet, "breed")
            ? string(_pet.breed)
            : "Неизвестно",

        age_text : variable_instance_exists(_pet, "age")
            ? string(_pet.age)
            : "Неизвестно",

        pet_age_days : variable_instance_exists(_pet, "pet_age_days")
            ? max(0, round(_pet.pet_age_days))
            : 0,

        problem : variable_instance_exists(_pet, "problem")
            ? string(_pet.problem)
            : "Причина не указана",

        condition : variable_instance_exists(_pet, "condition")
            ? _pet.condition
            : 100,

        life_stage : variable_instance_exists(_pet, "life_stage")
            ? _pet.life_stage
            : 0,

        pet_object_name : object_get_name(_pet.object_index),

        appearance : {
            sprite_id : _sprite_id,
            scale_x : abs(_pet.image_xscale),
            scale_y : abs(_pet.image_yscale)
        },

        visit_history : []
    };
}
