/// Draw GUI obj_UI_CandidateCard
/// @description Вызывает точную копию карточки сотрудника с тем же масштабом.

if (!visible || !instance_exists(target_candidate)) exit;

if (font_exists(fnt_main)) draw_set_font(fnt_main);

var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();

// Берём тот же ui_scale, который использует обычный планшет персонала.
var _ui_scale = 1.8;

if (instance_exists(obj_UI_Tablet)) {
    var _staff_tablet = instance_find(obj_UI_Tablet, 0);

    if (
        instance_exists(_staff_tablet)
        && variable_instance_exists(_staff_tablet, "ui_scale")
    ) {
        _ui_scale = _staff_tablet.ui_scale;
    }
}

// Точная копия занимает 536 × 396 базовых единиц вместе с полями листа.
// На маленьком окне допускается только пропорциональное уменьшение целиком.
var _max_scale_x = (_gui_w - 40) / 536;
var _max_scale_y = (_gui_h - 40) / 396;
_ui_scale = min(_ui_scale, _max_scale_x, _max_scale_y);
_ui_scale = max(0.70, _ui_scale);

panel_scale = _ui_scale;
panel_w = 536 * _ui_scale;
panel_h = 396 * _ui_scale;

var _frame_x = (_gui_w - 520 * _ui_scale) * 0.5;
var _frame_y = (_gui_h - 396 * _ui_scale) * 0.5 + 12 * _ui_scale;
var _center_x = _frame_x + 260 * _ui_scale;
var _center_y = _frame_y + 188 * _ui_scale;

// Эти размеры фотографии передаются в ту же функцию и используют тот же масштаб.
var _photo_w = 68 * _ui_scale;
var _photo_h = 92 * _ui_scale;

// Затемнение мира под открытой карточкой.
draw_set_alpha(0.16);
draw_set_color(c_black);
draw_rectangle(0, 0, _gui_w, _gui_h, false);
draw_set_alpha(1);

// Лёгкая тень не меняет размер самого листа.
draw_set_alpha(0.18);
draw_set_color(c_black);
draw_roundrect_ext(
    _frame_x - 5 * _ui_scale,
    _frame_y - 9 * _ui_scale,
    _frame_x + 525 * _ui_scale,
    _frame_y + 388 * _ui_scale,
    12,
    12,
    false
);
draw_set_alpha(1);

// Внутри используется буквальная копия tablet_draw_staff_card.
tablet_draw_candidate_card(
    id,
    target_candidate,
    _center_x,
    _center_y,
    _ui_scale,
    _frame_x,
    _frame_y,
    _photo_w,
    _photo_h
);

// Крестик занимает верхний правый угол того же светлого листа.
close_x1 = _frame_x + 494 * _ui_scale;
close_y1 = _frame_y - 9 * _ui_scale;
close_x2 = _frame_x + 516 * _ui_scale;
close_y2 = _frame_y + 13 * _ui_scale;

var _mouse_x = device_mouse_x_to_gui(0);
var _mouse_y = device_mouse_y_to_gui(0);
var _close_hover = point_in_rectangle(
    _mouse_x,
    _mouse_y,
    close_x1,
    close_y1,
    close_x2,
    close_y2
);

var _wood_dark = make_color_rgb(74, 49, 31);
var _paper_2 = make_color_rgb(232, 220, 198);
var _red = make_color_rgb(148, 74, 64);

draw_set_color(
    _close_hover
        ? make_color_rgb(246, 225, 215)
        : _paper_2
);
draw_roundrect_ext(close_x1, close_y1, close_x2, close_y2, 5, 5, false);
draw_set_color(_wood_dark);
draw_roundrect_ext(close_x1, close_y1, close_x2, close_y2, 5, 5, true);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(_red);
draw_text_transformed(
    (close_x1 + close_x2) * 0.5,
    (close_y1 + close_y2) * 0.5,
    "X",
    0.58 * _ui_scale,
    0.64 * _ui_scale,
    0
);

// Обязательный сброс состояния отрисовки.
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
gpu_set_blendmode(bm_normal);
