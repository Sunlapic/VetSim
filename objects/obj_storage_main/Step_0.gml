/// Step obj_storage_main
/// Пакет №83: hover считается по всей площади стеллажа, а не по маленькому спрайту.

event_inherited();

depth = -y;

var _r = storage_shelf_unit_rect(id);

is_hovered = point_in_rectangle(
    mouse_x,
    mouse_y,
    _r.x1,
    _r.y1,
    _r.x2,
    _r.y2
);
