/// draw_soft_rect_shadow(_x, _y, _half_width, _half_height, _opacity)
/// Мягкая прямоугольная тень:
/// светлая по краям и тёмная в центре.

function draw_soft_rect_shadow(
    _x,
    _y,
    _half_width,
    _half_height,
    _opacity = 1
) {
    if (_half_width <= 0) return;
    if (_half_height <= 0) return;
    if (_opacity <= 0) return;

    var _layers = 12;

    draw_set_color(c_black);

    // ─────────────────────────────────────────
    // ОСНОВНЫЕ СЛОИ
    // От большого светлого прямоугольника
    // к маленькому тёмному
    // ─────────────────────────────────────────

    for (var _layer = _layers; _layer >= 1; _layer--) {

        var _t = _layer / _layers;

        // Внешняя граница крупнее основной тени.
        var _scale = lerp(0.28, 1.30, _t);

        // Внешние слои почти прозрачные,
        // внутренние — более плотные.
        var _alpha = lerp(0.035, 0.003, _t);
        _alpha *= _opacity;

        var _width  = _half_width  * _scale;
        var _height = _half_height * _scale;

        draw_set_alpha(_alpha);

        draw_rectangle(
            _x - _width,
            _y - _height,
            _x + _width,
            _y + _height,
            false
        );
    }

    // ─────────────────────────────────────────
    // ДОПОЛНИТЕЛЬНОЕ ТЁМНОЕ ЯДРО
    // ─────────────────────────────────────────

    draw_set_alpha(0.025 * _opacity);

    draw_rectangle(
        _x - _half_width * 0.65,
        _y - _half_height * 0.65,
        _x + _half_width * 0.65,
        _y + _half_height * 0.65,
        false
    );

    draw_set_alpha(0.040 * _opacity);

    draw_rectangle(
        _x - _half_width * 0.45,
        _y - _half_height * 0.45,
        _x + _half_width * 0.45,
        _y + _half_height * 0.45,
        false
    );

    draw_set_alpha(0.070 * _opacity);

    draw_rectangle(
        _x - _half_width * 0.25,
        _y - _half_height * 0.25,
        _x + _half_width * 0.25,
        _y + _half_height * 0.25,
        false
    );

    // Обязательно восстанавливаем настройки Draw.
    draw_set_alpha(1);
    draw_set_color(c_white);
}