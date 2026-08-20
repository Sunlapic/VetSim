/// @description Видеть сетку AI
draw_set_alpha(0.2);
// Рисуем сетку. Красные клетки - непроходимы.
if (variable_global_exists("ai_grid")) mp_grid_draw(global.ai_grid);
draw_set_alpha(1.0);