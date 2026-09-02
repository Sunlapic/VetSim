function portrait_bake() {

    // Удаляем старый baked portrait, если он уже был
    if (variable_instance_exists(id, "my_baked_portrait")) {
        if (my_baked_portrait != -1 && sprite_exists(my_baked_portrait)) {
            sprite_delete(my_baked_portrait);
        }
    }

    my_baked_portrait = -1;

    // ─────────────────────────────────────────
    // ЛОГИЧЕСКИЙ размер фото в карточке
    // Это тот самый "кадр", который раньше красиво работал в UI
    // ─────────────────────────────────────────
    var _photo_w = 99;
    var _photo_h = round(_photo_w * 1.15);

    // Множитель качества baked-портрета
    var _res = 4;

    // Реальный размер поверхности
    var _pw = _photo_w * _res;
    var _ph = _photo_h * _res;

    // Параметры виртуальной камеры
    var _px_cam = variable_instance_exists(id, "portrait_x") ? portrait_x : 150;
    var _py_cam = variable_instance_exists(id, "portrait_y") ? portrait_y : 50;
    var _pz_cam = variable_instance_exists(id, "portrait_zoom") ? portrait_zoom : 1.0;

    // ВАЖНО:
    // source rectangle считаем от логического размера фото,
    // а масштаб рисования умножаем на _res
    var _src_w = _photo_w / _pz_cam;
    var _src_h = _photo_h / _pz_cam;
    var _draw_scale = _pz_cam * _res;

    var _surf = surface_create(_pw, _ph);
    if (!surface_exists(_surf)) exit;

    surface_set_target(_surf);
    draw_clear_alpha(c_black, 0);

    // ─────────────────────────────────────────
    // ЖИВОТНЫЕ
    // ─────────────────────────────────────────
    if (variable_instance_exists(id, "role") && role == "animal") {

        if (sprite_exists(sprite_index)) {
            draw_sprite_general(
                sprite_index, 0,
                _px_cam, _py_cam, _src_w, _src_h,
                0, 0, _draw_scale, _draw_scale, 0,
                c_white, c_white, c_white, c_white, 1
            );
        }

    }
    // ─────────────────────────────────────────
    // ЛЮДИ
    // ─────────────────────────────────────────
    else {

        draw_sprite_general(
            spr_human_FR_walk, 0,
            _px_cam, _py_cam, _src_w, _src_h,
            0, 0, _draw_scale, _draw_scale, 0,
            c_white, c_white, c_white, c_white, 1
        );

        // ── Пакет 226: ОДЕЖДА в портрете (халат врача / роба ассистента) ──
        var _p_role = "";
        if (variable_instance_exists(id, "role")) _p_role = role;
        var _p_f = (variable_instance_exists(id, "is_female") && is_female);

        var _cloth_spr = -1;
        var _cloth_is_scrub = false;
        if (_p_role == "doctor" || object_index == obj_staff_doctor || object_index == obj_player) {
            _cloth_spr = _p_f ? spr_human_FR_walk_Robe_Woman : spr_human_FR_walk_Robe_Man;
        } else if (_p_role == "assistant" || object_index == obj_staff_assistant) {
            _cloth_spr = _p_f ? spr_human_FR_walk_Scrub_Woman : spr_human_FR_walk_Scrub;
            _cloth_is_scrub = true;
        }

        if (_cloth_spr != -1 && sprite_exists(_cloth_spr)) {
            // цвет/узор: если ещё не назначены (портрет печётся в Create,
            // до первого кадра) — выдаём здесь, в игре сохранится тот же
            if (!variable_instance_exists(id, "robe_color")) {
                robe_color = _cloth_is_scrub
                    ? staff_random_scrub_color()
                    : staff_random_robe_color();
            }
            if (_cloth_is_scrub && !variable_instance_exists(id, "scrub_pattern")) {
                scrub_pattern    = irandom(4);
                scrub_pat_size   = random_range(0.6, 1.8);
                scrub_pat_phase  = random(1.0);
            }
            // в фото узор не рисуем (мелко), только цвет формы
            draw_sprite_general(
                _cloth_spr, 0,
                _px_cam, _py_cam, _src_w, _src_h,
                0, 0, _draw_scale, _draw_scale, 0,
                robe_color, robe_color, robe_color, robe_color, 1
            );
        }

        if (variable_instance_exists(id, "my_nose") && sprite_exists(my_nose)) {
            draw_sprite_general(
                my_nose, 0,
                _px_cam, _py_cam, _src_w, _src_h,
                0, 0, _draw_scale, _draw_scale, 0,
                c_white, c_white, c_white, c_white, 1
            );
        }

        if (variable_instance_exists(id, "my_eyes") && sprite_exists(my_eyes)) {
            draw_sprite_general(
                my_eyes, 0,
                _px_cam, _py_cam, _src_w, _src_h,
                0, 0, _draw_scale, _draw_scale, 0,
                c_white, c_white, c_white, c_white, 1
            );
        }

        if (variable_instance_exists(id, "my_mouth") && sprite_exists(my_mouth)) {
            draw_sprite_general(
                my_mouth, 0,
                _px_cam, _py_cam, _src_w, _src_h,
                0, 0, _draw_scale, _draw_scale, 0,
                c_white, c_white, c_white, c_white, 1
            );
        }

        if (variable_instance_exists(id, "my_hair") && sprite_exists(my_hair)) {
            var _hair_c = c_white;

            if (variable_instance_exists(id, "hair_color")) {
                _hair_c = hair_color;
            }

            draw_sprite_general(
                my_hair, 0,
                _px_cam, _py_cam, _src_w, _src_h,
                0, 0, _draw_scale, _draw_scale, 0,
                _hair_c, _hair_c, _hair_c, _hair_c, 1
            );
        }
    }

    surface_reset_target();

    my_baked_portrait = sprite_create_from_surface(_surf, 0, 0, _pw, _ph, false, false, 0, 0);

    surface_free(_surf);
}