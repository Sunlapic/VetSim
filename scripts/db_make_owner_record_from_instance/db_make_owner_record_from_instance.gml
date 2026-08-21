/// db_make_owner_record_from_instance(_owner)
/// @description Создаёт постоянную запись владельца из экземпляра.

function db_make_owner_record_from_instance(_owner) {
    if (!instance_exists(_owner)) return undefined;


    // ═══════════════════════════════════════════════════════════
    // 1. ИДЕНТИФИКАТОРЫ СПРАЙТОВ ВНЕШНОСТИ
    // ═══════════════════════════════════════════════════════════

    var _hair_front_id = "";
    var _hair_back_id = "";
    var _eyes_id = "";
    var _nose_id = "";
    var _mouth_id = "";

    if (variable_instance_exists(_owner, "my_hair") && sprite_exists(_owner.my_hair)) {
        _hair_front_id = sprite_get_name(_owner.my_hair);
    }

    if (variable_instance_exists(_owner, "my_hair_back") && sprite_exists(_owner.my_hair_back)) {
        _hair_back_id = sprite_get_name(_owner.my_hair_back);
    }

    if (variable_instance_exists(_owner, "my_eyes") && sprite_exists(_owner.my_eyes)) {
        _eyes_id = sprite_get_name(_owner.my_eyes);
    }

    if (variable_instance_exists(_owner, "my_nose") && sprite_exists(_owner.my_nose)) {
        _nose_id = sprite_get_name(_owner.my_nose);
    }

    if (variable_instance_exists(_owner, "my_mouth") && sprite_exists(_owner.my_mouth)) {
        _mouth_id = sprite_get_name(_owner.my_mouth);
    }

    var _hair_color = variable_instance_exists(_owner, "hair_color")
        ? _owner.hair_color
        : c_white;

    var _person_scale = variable_instance_exists(_owner, "_height_scale")
        ? clamp(abs(_owner._height_scale), 0.85, 1.15)
        : 1.0;


    // ═══════════════════════════════════════════════════════════
    // 2. НОВАЯ ЗАПИСЬ ВЛАДЕЛЬЦА
    // ═══════════════════════════════════════════════════════════

    return {
        owner_id : db_next_owner_id(),
        full_name : variable_instance_exists(_owner, "char_name")
            ? string(_owner.char_name)
            : "Неизвестный владелец",
        age : variable_instance_exists(_owner, "age") ? _owner.age : 30,
        is_female : variable_instance_exists(_owner, "is_female")
            ? _owner.is_female
            : false,

        trust : variable_instance_exists(_owner, "owner_trust")
            ? _owner.owner_trust
            : 60,
        money : variable_instance_exists(_owner, "stat_money")
            ? _owner.stat_money
            : 0,
        patience : variable_instance_exists(_owner, "stat_patience")
            ? _owner.stat_patience
            : 50,
        patience_level : variable_instance_exists(_owner, "patience_level")
            ? clamp(round(_owner.patience_level), 1, 10)
            : 5,
        patience_success_progress : variable_instance_exists(_owner, "patience_success_progress")
            ? clamp(round(_owner.patience_success_progress), 0, 4)
            : 0,

        walk_speed_level : variable_instance_exists(_owner, "owner_walk_speed_level")
            ? clamp(round(_owner.owner_walk_speed_level), 1, 10)
            : owner_roll_walk_speed_level(_owner.age),

        walk_speed_percent : variable_instance_exists(_owner, "owner_walk_speed_percent")
            ? clamp(round(_owner.owner_walk_speed_percent), 100, 190)
            : 100,

        loyalty_level : variable_instance_exists(_owner, "loyalty_level")
            ? clamp(round(_owner.loyalty_level), 1, 10)
            : 5,
        loyalty_success_progress : variable_instance_exists(_owner, "loyalty_success_progress")
            ? clamp(round(_owner.loyalty_success_progress), 0, 4)
            : 0,

        owner_feature_id : variable_instance_exists(_owner, "owner_feature_id")
            ? string(_owner.owner_feature_id)
            : "none",
        owner_feature_name_ru : variable_instance_exists(_owner, "owner_feature_name_ru")
            ? string(_owner.owner_feature_name_ru)
            : "Нет особенности",

        pet_ids : [],
        visits_total : 0,
        last_visit_day : global.game_day,

        appearance : {
            body_front_id : "spr_human_FR_walk",
            body_back_id : "spr_human_B_walk",
            hair_front_id : _hair_front_id,
            hair_back_id : _hair_back_id,
            eyes_id : _eyes_id,
            nose_id : _nose_id,
            mouth_id : _mouth_id,

            hair_color_r : color_get_red(_hair_color),
            hair_color_g : color_get_green(_hair_color),
            hair_color_b : color_get_blue(_hair_color),

            // Старое поле оставлено для совместимости.
            body_scale : abs(_owner.image_xscale),

            // Рост хранится одним пропорциональным коэффициентом.
            // width_scale оставлен в записи только для совместимости старых БД.
            height_scale : _person_scale,
            width_scale : _person_scale,
            draw_offset_y : variable_instance_exists(_owner, "_draw_offset_y")
                ? _owner._draw_offset_y
                : 0
        }
    };
}
