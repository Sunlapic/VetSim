/// draw_soft_oval_shadow(
///     _x,
///     _y,
///     _half_width,
///     _half_height,
///     _opacity
/// )
///
/// Мягкая овальная тень.
/// Центр тёмный, края плавно растворяются.

function draw_soft_oval_shadow(
    _x,
    _y,
    _half_width,
    _half_height,
    _opacity = 1
) {
    if (_half_width <= 0) return;
    if (_half_height <= 0) return;
    if (_opacity <= 0) return;

    var _layers = 14;

    draw_set_color(c_black);

    // ─────────────────────────────────────────
    // ПЛАВНЫЕ ОСНОВНЫЕ СЛОИ
    // ─────────────────────────────────────────

    for (var _layer = _layers; _layer >= 1; _layer--) {

        var _t = _layer / _layers;

        // Внешний слой большой, внутренний маленький
        var _scale = lerp(
            0.25,
            1.35,
            _t
        );

        // Края почти прозрачные,
        // центр постепенно становится темнее
        var _alpha = lerp(
            0.045,
            0.004,
            _t
        );

        _alpha *= _opacity;

        var _layer_w = _half_width * _scale;
        var _layer_h = _half_height * _scale;

        draw_set_alpha(_alpha);

        draw_ellipse(
            _x - _layer_w,
            _y - _layer_h,
            _x + _layer_w,
            _y + _layer_h,
            false
        );
    }

    // ─────────────────────────────────────────
    // ТЁМНОЕ ВНУТРЕННЕЕ ЯДРО
    // ─────────────────────────────────────────

    draw_set_alpha(0.025 * _opacity);

    draw_ellipse(
        _x - _half_width * 0.65,
        _y - _half_height * 0.65,
        _x + _half_width * 0.65,
        _y + _half_height * 0.65,
        false
    );

    draw_set_alpha(0.040 * _opacity);

    draw_ellipse(
        _x - _half_width * 0.45,
        _y - _half_height * 0.45,
        _x + _half_width * 0.45,
        _y + _half_height * 0.45,
        false
    );

    draw_set_alpha(0.070 * _opacity);

    draw_ellipse(
        _x - _half_width * 0.25,
        _y - _half_height * 0.25,
        _x + _half_width * 0.25,
        _y + _half_height * 0.25,
        false
    );

    // Сброс настроек Draw
    draw_set_alpha(1);
    draw_set_color(c_white);
}