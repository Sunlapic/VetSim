/// db_apply_owner_record_to_instance(_record, _owner_inst)
/// @description Восстанавливает владельца из постоянной записи.

function db_apply_owner_record_to_instance(_record, _owner_inst) {
    if (!is_struct(_record)) return false;
    if (!instance_exists(_owner_inst)) return false;


    // ═══════════════════════════════════════════════════════════
    // 1. ЛИЧНЫЕ ДАННЫЕ
    // ═══════════════════════════════════════════════════════════

    _owner_inst.owner_record_id = variable_struct_exists(_record, "owner_id")
        ? _record.owner_id
        : "";

    _owner_inst.char_name = variable_struct_exists(_record, "full_name")
        ? _record.full_name
        : "Неизвестный владелец";

    _owner_inst.age = variable_struct_exists(_record, "age")
        ? _record.age
        : 30;

    _owner_inst.is_female = variable_struct_exists(_record, "is_female")
        ? _record.is_female
        : false;

    _owner_inst.stat_money = variable_struct_exists(_record, "money")
        ? _record.money
        : 0;

    _owner_inst.stat_patience = variable_struct_exists(_record, "patience")
        ? _record.patience
        : 50;

    _owner_inst.patience_level = variable_struct_exists(_record, "patience_level")
        ? clamp(round(_record.patience_level), 1, 10)
        : clamp(ceil(_owner_inst.stat_patience / 10), 1, 10);

    _owner_inst.patience_success_progress = variable_struct_exists(
        _record,
        "patience_success_progress"
    ) ? clamp(round(_record.patience_success_progress), 0, 4) : 0;

    // Это состояние относится только к новому визиту и не хранится в базе.
    _owner_inst.patience_wait_xp_timer = 0;
    _owner_inst.patience_xp_awarded_this_visit = false;

    // Скорость постоянного клиента восстанавливается без нового случайного броска.
    var _walk_level = variable_struct_exists(_record, "walk_speed_level")
        ? clamp(round(_record.walk_speed_level), 1, 10)
        : owner_roll_walk_speed_level(_owner_inst.age);

    owner_apply_walk_speed_level(_owner_inst, _walk_level);

    _owner_inst.owner_trust = variable_struct_exists(_record, "trust")
        ? _record.trust
        : 60;


    // ═══════════════════════════════════════════════════════════
    // 2. ЛОЯЛЬНОСТЬ И ОСОБЕННОСТЬ
    // ═══════════════════════════════════════════════════════════

    _owner_inst.loyalty_level = variable_struct_exists(_record, "loyalty_level")
        ? clamp(round(_record.loyalty_level), 1, 10)
        : 5;

    _owner_inst.loyalty_success_progress = variable_struct_exists(_record, "loyalty_success_progress")
        ? clamp(round(_record.loyalty_success_progress), 0, 4)
        : 0;

    _owner_inst.owner_feature_id = variable_struct_exists(_record, "owner_feature_id")
        ? string(_record.owner_feature_id)
        : "none";

    _owner_inst.owner_feature_name_ru = variable_struct_exists(_record, "owner_feature_name_ru")
        ? string(_record.owner_feature_name_ru)
        : "Нет особенности";


    // ═══════════════════════════════════════════════════════════
    // 3. ВНЕШНОСТЬ
    // ═══════════════════════════════════════════════════════════

    if (variable_struct_exists(_record, "appearance") && is_struct(_record.appearance)) {
        var _appearance = _record.appearance;

        _owner_inst.my_hair = variable_struct_exists(_appearance, "hair_front_id")
            ? asset_get_index(_appearance.hair_front_id)
            : -1;

        _owner_inst.my_hair_back = variable_struct_exists(_appearance, "hair_back_id")
            ? asset_get_index(_appearance.hair_back_id)
            : -1;

        _owner_inst.my_eyes = variable_struct_exists(_appearance, "eyes_id")
            ? asset_get_index(_appearance.eyes_id)
            : -1;

        _owner_inst.my_nose = variable_struct_exists(_appearance, "nose_id")
            ? asset_get_index(_appearance.nose_id)
            : -1;

        _owner_inst.my_mouth = variable_struct_exists(_appearance, "mouth_id")
            ? asset_get_index(_appearance.mouth_id)
            : -1;

        var _hair_r = variable_struct_exists(_appearance, "hair_color_r")
            ? _appearance.hair_color_r
            : 255;
        var _hair_g = variable_struct_exists(_appearance, "hair_color_g")
            ? _appearance.hair_color_g
            : 255;
        var _hair_b = variable_struct_exists(_appearance, "hair_color_b")
            ? _appearance.hair_color_b
            : 255;

        _owner_inst.hair_color = make_color_rgb(_hair_r, _hair_g, _hair_b);

        var _legacy_scale = variable_struct_exists(_appearance, "body_scale")
            ? abs(_appearance.body_scale)
            : 1.0;

        _owner_inst.image_xscale = _legacy_scale;
        _owner_inst.image_yscale = _legacy_scale;

        // Миграция старых записей: рост сохраняем, независимую ширину удаляем.
        // Оба коэффициента становятся одинаковыми, поэтому тело не растягивается.
        var _saved_person_scale = variable_struct_exists(
            _appearance,
            "height_scale"
        )
            ? abs(_appearance.height_scale)
            : (
                variable_struct_exists(_appearance, "width_scale")
                    ? abs(_appearance.width_scale)
                    : 1.0
            );

        _saved_person_scale = clamp(_saved_person_scale, 0.85, 1.15);

        _owner_inst._height_scale = _saved_person_scale;
        _owner_inst._width_scale = _saved_person_scale;

        // Рост не меняется при миграции, поэтому сохранённая опора ног остаётся.
        _owner_inst._draw_offset_y = variable_struct_exists(
            _appearance,
            "draw_offset_y"
        )
            ? _appearance.draw_offset_y
            : 0;
    }


    // ═══════════════════════════════════════════════════════════
    // 4. ОБНОВЛЕНИЕ ПОРТРЕТА
    // ═══════════════════════════════════════════════════════════

    with (_owner_inst) {
        portrait_bake();
    }

    return true;
}
