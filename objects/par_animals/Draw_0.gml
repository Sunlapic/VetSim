/// Draw par_animals
/// @description Питомец с мягкой тенью, подсветкой и шкалой выздоровления стационара.


// ═══════════════════════════════════════════════════════════════
// 0. МЯГКАЯ ОВАЛЬНАЯ ТЕНЬ
// ═══════════════════════════════════════════════════════════════

if (
    sprite_exists(sprite_index)
    && image_alpha > 0.1
) {
    var _base_w =
        sprite_get_width(sprite_index)
        * abs(image_xscale)
        * 0.09;

    var _base_h = _base_w * 0.40;

    // Размер соответствует прежней тени с плавным переходом к краям.
    var _shadow_w = _base_w * 1.85;
    var _shadow_h = _base_h * 1.85;

    draw_soft_oval_shadow(
        x,
        y,
        _shadow_w,
        _shadow_h,
        image_alpha
    );
}


// ═══════════════════════════════════════════════════════════════
// 1. ПОДСВЕТКА ПРИ НАВЕДЕНИИ
// ═══════════════════════════════════════════════════════════════

if (
    is_hovered
    && sprite_exists(sprite_index)
) {
    gpu_set_blendmode(bm_add);

    var _b = 1.5;
    var _a = 0.45;

    draw_sprite_ext(
        sprite_index,
        image_index,
        x + _b,
        y,
        image_xscale,
        image_yscale,
        image_angle,
        c_lime,
        _a
    );

    draw_sprite_ext(
        sprite_index,
        image_index,
        x - _b,
        y,
        image_xscale,
        image_yscale,
        image_angle,
        c_lime,
        _a
    );

    draw_sprite_ext(
        sprite_index,
        image_index,
        x,
        y + _b,
        image_xscale,
        image_yscale,
        image_angle,
        c_lime,
        _a
    );

    draw_sprite_ext(
        sprite_index,
        image_index,
        x,
        y - _b,
        image_xscale,
        image_yscale,
        image_angle,
        c_lime,
        _a
    );

    draw_sprite_ext(
        sprite_index,
        image_index,
        x + _b,
        y + _b,
        image_xscale,
        image_yscale,
        image_angle,
        c_lime,
        _a
    );

    draw_sprite_ext(
        sprite_index,
        image_index,
        x - _b,
        y - _b,
        image_xscale,
        image_yscale,
        image_angle,
        c_lime,
        _a
    );

    draw_sprite_ext(
        sprite_index,
        image_index,
        x + _b,
        y - _b,
        image_xscale,
        image_yscale,
        image_angle,
        c_lime,
        _a
    );

    draw_sprite_ext(
        sprite_index,
        image_index,
        x - _b,
        y + _b,
        image_xscale,
        image_yscale,
        image_angle,
        c_lime,
        _a
    );

    gpu_set_blendmode(bm_normal);
}


// ═══════════════════════════════════════════════════════════════
// 2. САМ ПИТОМЕЦ
// ═══════════════════════════════════════════════════════════════

if (sprite_exists(sprite_index)) {
    draw_sprite_ext(
        sprite_index,
        image_index,
        x,
        y,
        image_xscale,
        image_yscale,
        image_angle,
        image_blend,
        image_alpha
    );
}


// ═══════════════════════════════════════════════════════════════
// 3. ШКАЛА ВЫЗДОРОВЛЕНИЯ СТАЦИОНАРА
// Добавлена поверх прежнего Draw без удаления тени или подсветки.
// ═══════════════════════════════════════════════════════════════

if (
    variable_instance_exists(id, "inpatient_active")
    && inpatient_active
    && !is_dead
) {
    var _condition_value = variable_instance_exists(id, "condition")
        ? condition
        : 0;

    if (
        variable_instance_exists(id, "current_case")
        && is_struct(current_case)
        && variable_struct_exists(current_case, "condition")
    ) {
        _condition_value = current_case.condition;
    }

    var _ratio = clamp(_condition_value / 100, 0, 1);
    var _bar_w = 76;
    var _bar_h = 8;
    var _bar_x1 = x - _bar_w * 0.5;
    var _bar_x2 = x + _bar_w * 0.5;
    var _bar_y1 = bbox_top - 25;
    var _bar_y2 = _bar_y1 + _bar_h;
    var _fill_color = merge_color(
        make_color_rgb(190, 55, 50),
        make_color_rgb(65, 175, 80),
        _ratio
    );

    // Тень шкалы.
    draw_set_alpha(0.25 * image_alpha);
    draw_set_color(c_black);
    draw_roundrect_ext(
        _bar_x1 + 2,
        _bar_y1 + 3,
        _bar_x2 + 2,
        _bar_y2 + 3,
        6,
        6,
        false
    );
    draw_set_alpha(image_alpha);

    // Фон и заполнение.
    draw_set_color(make_color_rgb(225, 220, 210));
    draw_roundrect_ext(
        _bar_x1,
        _bar_y1,
        _bar_x2,
        _bar_y2,
        6,
        6,
        false
    );

    if (_ratio > 0) {
        draw_set_color(_fill_color);
        draw_roundrect_ext(
            _bar_x1,
            _bar_y1,
            _bar_x1 + _bar_w * _ratio,
            _bar_y2,
            6,
            6,
            false
        );
    }

    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(
        _bar_x1,
        _bar_y1,
        _bar_x2,
        _bar_y2,
        6,
        6,
        true
    );

    if (font_exists(fnt_main)) draw_set_font(fnt_main);

    var _recovery_text = "ВЫЗДОРОВЛЕНИЕ "
        + string(round(_condition_value))
        + "%";

    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    // Тёмная подложка текста и светлая надпись.
    draw_set_alpha(image_alpha);
    draw_set_color(c_black);
    draw_text_transformed(
        x + 1,
        _bar_y1 - 1,
        _recovery_text,
        0.48,
        0.48,
        0
    );

    draw_set_color(c_white);
    draw_text_transformed(
        x,
        _bar_y1 - 2,
        _recovery_text,
        0.48,
        0.48,
        0
    );
}


// ═══════════════════════════════════════════════════════════════
// 4. ФИНАЛЬНЫЙ СБРОС
// ═══════════════════════════════════════════════════════════════

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);
draw_set_color(c_white);
gpu_set_blendmode(bm_normal);
