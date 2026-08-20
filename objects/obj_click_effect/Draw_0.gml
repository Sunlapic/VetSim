// Рисуем пульсирующий зеленый круг
var _alpha = image_alpha;
draw_set_alpha(_alpha);
draw_set_color(c_lime);
// Рисуем кольцо (внешний круг)
draw_circle(x, y, (1 - _alpha) * 30, true);
// Рисуем точку (в центре)
draw_circle(x, y, 5, false);
draw_set_alpha(1.0);
draw_set_color(c_white);

// Плавное исчезновение
image_alpha -= 0.05;
if (image_alpha <= 0) instance_destroy();