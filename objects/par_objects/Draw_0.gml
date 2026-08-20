/// Draw par_objects
/// @description Отрисовка с тенью и обводкой.

// Пакет №72: полностью скрываем мебель закрытых помещений (столы и шкафы).
if (
    variable_instance_exists(id, "exam_slot_id")
    && !clinic_room_is_open(exam_slot_id)
) {
    exit;
}

// ─────────────────────────────────────────────
// 1. МЯГКАЯ МНОГОСЛОЙНАЯ ТЕНЬ
// ─────────────────────────────────────────────

if (
    has_shadow
    && image_alpha > 0.1
    && sprite_exists(sprite_index)
) {
    // Размер тени зависит от размера предмета
    var _shadow_w =
        sprite_get_width(sprite_index)
        * abs(image_xscale)
        * 0.40;

    var _shadow_h = _shadow_w * 0.30;

    // Центр тени располагается около основания предмета
    var _shadow_x = x;
    var _shadow_y = y;

    // Количество плавных слоёв
    var _shadow_layers = 12;

    draw_set_color(c_black);

    // ─────────────────────────────────────────
    // МЯГКИЕ ВНЕШНИЕ СЛОИ
    // Рисуем от большого светлого слоя
    // к маленькому тёмному
    // ─────────────────────────────────────────

    for (
        var _shadow_layer = _shadow_layers;
        _shadow_layer >= 1;
        _shadow_layer--
    ) {
        var _shadow_t =
            _shadow_layer / _shadow_layers;

        // Размер текущего слоя
        var _shadow_scale = lerp(
            0.22,
            1.35,
            _shadow_t
        );

        // Внешние слои светлые,
        // внутренние постепенно темнее
        var _shadow_alpha = lerp(
            0.035,
            0.004,
            _shadow_t
        );

        _shadow_alpha *= image_alpha;

        draw_set_alpha(_shadow_alpha);

        draw_ellipse(
            _shadow_x - _shadow_w * _shadow_scale,
            _shadow_y - _shadow_h * _shadow_scale,
            _shadow_x + _shadow_w * _shadow_scale,
            _shadow_y + _shadow_h * _shadow_scale,
            false
        );
    }

    // ─────────────────────────────────────────
    // ДОПОЛНИТЕЛЬНОЕ ТЁМНОЕ ЯДРО
    // Делает центр плотнее, не затемняя края
    // ─────────────────────────────────────────

    draw_set_alpha(0.025 * image_alpha);

    draw_ellipse(
        _shadow_x - _shadow_w * 0.58,
        _shadow_y - _shadow_h * 0.58,
        _shadow_x + _shadow_w * 0.58,
        _shadow_y + _shadow_h * 0.58,
        false
    );

    draw_set_alpha(0.040 * image_alpha);

    draw_ellipse(
        _shadow_x - _shadow_w * 0.42,
        _shadow_y - _shadow_h * 0.42,
        _shadow_x + _shadow_w * 0.42,
        _shadow_y + _shadow_h * 0.42,
        false
    );

    draw_set_alpha(0.060 * image_alpha);

    draw_ellipse(
        _shadow_x - _shadow_w * 0.25,
        _shadow_y - _shadow_h * 0.25,
        _shadow_x + _shadow_w * 0.25,
        _shadow_y + _shadow_h * 0.25,
        false
    );

    // Восстанавливаем настройки Draw
    draw_set_alpha(1);
    draw_set_color(c_white);
}



// 2. ЖИРНАЯ ЗЕЛЕНАЯ ОБВОДКА (8 проходов для плотности)
if (can_hover && is_hovered) {
    gpu_set_blendmode(bm_add);
    var _b = 2.5; // Толщина
    var _a = 0.5; // Яркость
    
    // Рисуем во все стороны для мягкого контура
    draw_sprite_ext(sprite_index, image_index, x+_b, y,    image_xscale, image_yscale, image_angle, c_lime, _a);
    draw_sprite_ext(sprite_index, image_index, x-_b, y,    image_xscale, image_yscale, image_angle, c_lime, _a);
    draw_sprite_ext(sprite_index, image_index, x,    y+_b, image_xscale, image_yscale, image_angle, c_lime, _a);
    draw_sprite_ext(sprite_index, image_index, x,    y-_b, image_xscale, image_yscale, image_angle, c_lime, _a);
    draw_sprite_ext(sprite_index, image_index, x+_b, y+_b, image_xscale, image_yscale, image_angle, c_lime, _a);
    draw_sprite_ext(sprite_index, image_index, x-_b, y-_b, image_xscale, image_yscale, image_angle, c_lime, _a);
    gpu_set_blendmode(bm_normal);
}

// 3. САМ ПРЕДМЕТ
draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
