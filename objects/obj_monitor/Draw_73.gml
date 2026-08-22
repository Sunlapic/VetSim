// ─────────────────────────────────────────────
// Draw End obj_monitor — чистая версия (исправлены опечатки от чата)
// Положение берётся из monitor_screen_x / monitor_screen_y, заданных в Create
// ─────────────────────────────────────────────

var _draw_x = monitor_screen_x;
var _draw_y = monitor_screen_y - draw_offset_y;

// Собираем живой список ожидающих
var _entries = [];
for (var i = 0; i < instance_number(obj_owner); i++) {
    var _o = instance_find(obj_owner, i);
    if (!instance_exists(_o)) continue;
    if (_o.state == "waiting") {
        var _pet_name = "";
        if (variable_instance_exists(_o, "my_pet") && instance_exists(_o.my_pet)) {
            if (variable_instance_exists(_o.my_pet, "char_name")) {
                _pet_name = " + " + string(_o.my_pet.char_name);
            }
        }
        var _visit_label = "Первичный приём";
        if (variable_instance_exists(_o, "visit_type_name_ru")) {
            _visit_label = string(_o.visit_type_name_ru);
        }
        array_push(_entries, {
            wait_index   : _o.wait_spot_index,
            patient_name : string(_o.char_name) + _pet_name,
            destination  : _visit_label
        });
    }
}

// Сортировка по wait_spot_index
for (var a = 0; a < array_length(_entries) - 1; a++) {
    for (var b = a + 1; b < array_length(_entries); b++) {
        if (_entries[b].wait_index < _entries[a].wait_index) {
            var _tmp    = _entries[a];
            _entries[a] = _entries[b];
            _entries[b] = _tmp;
        }
    }
}

if (font_exists(fnt_main)) draw_set_font(fnt_main);

// 1. Корпус
draw_set_color(c_dkgray);
draw_rectangle(_draw_x - 6, _draw_y - 6, _draw_x + monitor_w + 6, _draw_y + monitor_h + 6, false);

// 2. Экран
draw_set_color(make_color_rgb(15, 25, 35));
draw_rectangle(_draw_x, _draw_y, _draw_x + monitor_w, _draw_y + monitor_h, false);

// 3. Шапка
draw_set_color(make_color_rgb(20, 50, 80));
draw_rectangle(_draw_x, _draw_y, _draw_x + monitor_w, _draw_y + 32, false);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text(_draw_x + 12, _draw_y + 16, "ОЧЕРЕДЬ");
draw_set_color(c_aqua);
draw_line(_draw_x, _draw_y + 32, _draw_x + monitor_w, _draw_y + 32);

// 4. Список ожидания
var _start_y = _draw_y + 35;
var _row_h   = 18;
var _text_scale = 0.8;
for (var j = 0; j < array_length(_entries); j++) {
    if (j >= max_rows) break;
    var _item  = _entries[j];
    var _cy    = _start_y + (j * _row_h);
    var _text_y = _cy + 8;
    draw_set_halign(fa_left);
    draw_set_color(j == 0 ? c_yellow : c_white);
    draw_text_transformed(_draw_x + 12, _text_y, _item.patient_name, _text_scale, _text_scale, 0);
    draw_set_halign(fa_right);
    draw_set_color(c_aqua);
    draw_text_transformed(_draw_x + monitor_w - 20, _text_y, _item.destination, 1.0, 1.0, 0);
}

// 5. Пустой экран
if (array_length(_entries) == 0) {
    draw_set_color(c_gray);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(_draw_x + monitor_w * 0.5, _draw_y + monitor_h * 0.5 + 10,
                          "Ожидание приема...", 1.15, 1.15, 0);
}

// Сброс
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_font(-1);
