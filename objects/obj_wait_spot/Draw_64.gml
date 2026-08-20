// Рисуем маркер только в редакторе игры, в рантайме не виден!
if (event_perform_object(asset_get_index("obj_wait_spot"), ev_draw, 0)) exit; // чтобы не дублировать

draw_self();

// Рисуем круг и номер точки поверх спрайта чтобы было понятно какая точка где
draw_set_alpha(0.6);
draw_circle(x, y, 18, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_main);
draw_text(x, y, string(_i + 1));
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_black);