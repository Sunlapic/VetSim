/// Step par_objects
/// @description Проверка наведения и сортировка.

depth = -y;

// Пакет №72: мебель закрытого помещения не подсвечивается и не работает.
var _room_has_slot = variable_instance_exists(id, "exam_slot_id");

if (_room_has_slot && !clinic_room_is_open(exam_slot_id)) {
    is_hovered = false;

    // Столы закрытого кабинета всегда «заняты», поэтому игрок, врачи
    // и ассистенты не найдут их в поиске свободного стола.
    if (variable_instance_exists(id, "table_busy")) {
        table_busy = true;
    }

    exit;
}

if (variable_instance_exists(id, "can_hover") && can_hover) {
    var _mx = mouse_x;
    var _my = mouse_y;
    
    // Получаем реальные размеры спрайта с учетом масштаба
    var _sw = sprite_get_width(sprite_index) * abs(image_xscale);
    var _sh = sprite_get_height(sprite_index) * abs(image_yscale);
    
    // Получаем смещение Origin (так как он у нас внизу по центру)
    var _x_offset = sprite_get_xoffset(sprite_index) * abs(image_xscale);
    var _y_offset = sprite_get_yoffset(sprite_index) * abs(image_yscale);
    
    // Вычисляем четыре края картинки
    var _x1 = x - _x_offset;
    var _x2 = x - _x_offset + _sw;
    var _y1 = y - _y_offset; // Это верхняя точка (макушка)
    var _y2 = y - _y_offset + _sh; // Это нижняя точка (пол)

    // Проверяем: попала ли мышка в этот прямоугольник
    if (_mx > _x1 && _mx < _x2 && _my > _y1 && _my < _y2) {
        is_hovered = true;
    } else {
        is_hovered = false;
    }
} else {
    is_hovered = false;
}
