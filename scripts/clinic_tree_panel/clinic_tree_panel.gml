/// clinic_tree_panel.gml
/// @description Пакет №173. Панель «КЛИНИКА → РАЗВИТИЕ» в виде дерева.
///
/// Вместо двух колонок со строчками — общий верхний блок и три ветки:
/// ПРИЁМ, СТАЦИОНАР, ОПЕРАЦИОННАЯ. Узлы соединены стволом, где нужно —
/// развилка. Деньги и баллы в одной таблице, валюта видна по цвету цены:
/// зелёная — доллары, золотая — баллы клиники.
///
/// Иконки собраны из примитивов (прямоугольник, круг, линия) — в fnt_main
/// нет ни эмодзи, ни значков, а новые спрайты рисовать не нужно.


// ═══════════════════════════════════════════════════════════════
// 1. ПАЛИТРА
// ═══════════════════════════════════════════════════════════════

function tree_color_wood_dark()  { return make_color_rgb(74, 49, 31); }
function tree_color_wood_light() { return make_color_rgb(150, 107, 73); }
function tree_color_paper()      { return make_color_rgb(242, 232, 214); }
function tree_color_paper_2()    { return make_color_rgb(232, 220, 198); }
function tree_color_line()       { return make_color_rgb(58, 39, 24); }
function tree_color_text()       { return make_color_rgb(50, 38, 28); }
function tree_color_text_soft()  { return make_color_rgb(90, 70, 50); }
function tree_color_green()      { return make_color_rgb(62, 112, 74); }
function tree_color_green_bg()   { return make_color_rgb(217, 232, 213); }
function tree_color_gold()       { return make_color_rgb(180, 140, 64); }
function tree_color_gold_bg()    { return make_color_rgb(247, 237, 214); }
function tree_color_lock()       { return make_color_rgb(109, 97, 84); }
function tree_color_lock_bg()    { return make_color_rgb(207, 199, 184); }


// ═══════════════════════════════════════════════════════════════
// 2. ИКОНКИ ИЗ ПРИМИТИВОВ
// Каждая рисуется в квадрате _size × _size с центром (_cx, _cy).
// ═══════════════════════════════════════════════════════════════

function tree_icon_door(_cx, _cy, _size, _color) {
    var _w = _size * 0.42;
    var _h = _size * 0.72;

    draw_set_color(_color);
    draw_roundrect_ext(_cx - _w, _cy - _h, _cx + _w, _cy + _h, 3, 3, true);
    draw_circle(_cx + _w * 0.45, _cy + _size * 0.06, max(1.5, _size * 0.06), false);
}

function tree_icon_bed(_cx, _cy, _size, _color) {
    var _w = _size * 0.78;
    var _h = _size * 0.26;

    draw_set_color(_color);

    // матрас
    draw_roundrect_ext(_cx - _w, _cy - _h, _cx + _w, _cy + _h, 3, 3, true);
    // подушка
    draw_roundrect_ext(
        _cx - _w + 2, _cy - _h - _size * 0.24,
        _cx - _w + _size * 0.5, _cy - _h,
        3, 3, true
    );
    // ножки
    draw_line(_cx - _w, _cy + _h, _cx - _w, _cy + _h + _size * 0.18);
    draw_line(_cx + _w, _cy + _h, _cx + _w, _cy + _h + _size * 0.18);
}

function tree_icon_surgery(_cx, _cy, _size, _color) {
    var _w = _size * 0.78;

    draw_set_color(_color);

    // стол
    draw_roundrect_ext(_cx - _w, _cy, _cx + _w, _cy + _size * 0.22, 3, 3, true);
    draw_line(_cx - _w * 0.6, _cy + _size * 0.22, _cx - _w * 0.6, _cy + _size * 0.5);
    draw_line(_cx + _w * 0.6, _cy + _size * 0.22, _cx + _w * 0.6, _cy + _size * 0.5);
    // лампа
    draw_circle(_cx, _cy - _size * 0.38, _size * 0.24, true);
}

function tree_icon_book(_cx, _cy, _size, _color) {
    var _w = _size * 0.66;
    var _h = _size * 0.56;

    draw_set_color(_color);
    draw_roundrect_ext(_cx - _w, _cy - _h, _cx + _w, _cy + _h, 3, 3, true);
    draw_line(_cx, _cy - _h, _cx, _cy + _h);
}

function tree_icon_person(_cx, _cy, _size, _color) {
    draw_set_color(_color);

    draw_circle(_cx - _size * 0.12, _cy - _size * 0.34, _size * 0.24, true);

    // плечи
    draw_line(_cx - _size * 0.62, _cy + _size * 0.46, _cx - _size * 0.42, _cy + _size * 0.02);
    draw_line(_cx + _size * 0.18, _cy + _size * 0.46, _cx + _size * 0.02, _cy + _size * 0.02);
    draw_line(_cx - _size * 0.62, _cy + _size * 0.46, _cx + _size * 0.18, _cy + _size * 0.46);

    // плюсик «+1 место»
    draw_set_color(tree_color_green());
    draw_line(_cx + _size * 0.52, _cy - _size * 0.48, _cx + _size * 0.52, _cy - _size * 0.08);
    draw_line(_cx + _size * 0.32, _cy - _size * 0.28, _cx + _size * 0.72, _cy - _size * 0.28);
}

function tree_icon_dumbbell(_cx, _cy, _size, _color) {
    draw_set_color(_color);

    draw_roundrect_ext(
        _cx - _size * 0.5, _cy - _size * 0.14,
        _cx + _size * 0.5, _cy + _size * 0.14,
        3, 3, true
    );
    draw_roundrect_ext(
        _cx - _size * 0.82, _cy - _size * 0.34,
        _cx - _size * 0.5, _cy + _size * 0.34,
        3, 3, true
    );
    draw_roundrect_ext(
        _cx + _size * 0.5, _cy - _size * 0.34,
        _cx + _size * 0.82, _cy + _size * 0.34,
        3, 3, true
    );
}

function tree_icon_pill(_cx, _cy, _size, _color) {
    draw_set_color(_color);

    draw_circle(_cx, _cy, _size * 0.52, true);
    draw_line(
        _cx - _size * 0.36, _cy + _size * 0.36,
        _cx + _size * 0.36, _cy - _size * 0.36
    );
}

function tree_draw_icon(_icon_id, _cx, _cy, _size, _color) {
    switch (string(_icon_id)) {
        case "door":     tree_icon_door(_cx, _cy, _size, _color); break;
        case "bed":      tree_icon_bed(_cx, _cy, _size, _color); break;
        case "surgery":  tree_icon_surgery(_cx, _cy, _size, _color); break;
        case "book":     tree_icon_book(_cx, _cy, _size, _color); break;
        case "person":   tree_icon_person(_cx, _cy, _size, _color); break;
        case "dumbbell": tree_icon_dumbbell(_cx, _cy, _size, _color); break;
        case "pill":     tree_icon_pill(_cx, _cy, _size, _color); break;
    }
}


// ═══════════════════════════════════════════════════════════════
// 3. ДАННЫЕ ДЕРЕВА
//
// kind: "room" — помещение за деньги (clinic_rooms_system)
//       "bed"  — койка стационара за деньги
//       "oper" — операционная за деньги
//       "upg"  — улучшение за баллы (clinic_upgrade_system)
//
// Каждая ветка — массив рядов, ряд — массив узлов (1 или 2 = развилка).
// ═══════════════════════════════════════════════════════════════

function tree_node_room(_slot, _icon, _effect) {
    return {
        kind : "room",
        key : _slot,
        icon : _icon,
        effect : _effect
    };
}

function tree_node_bed(_slot) {
    return {
        kind : "bed",
        key : _slot,
        icon : "bed",
        effect : "место в стационаре"
    };
}

function tree_node_upgrade(_id, _icon) {
    return {
        kind : "upg",
        key : _id,
        icon : _icon,
        effect : ""
    };
}

function tree_branches() {
    return [
        {
            title : "ПРИЁМ",
            rows : [
                [ tree_node_room(2, "door", "второй стол приёма") ],
                [ tree_node_room(3, "door", "третий стол приёма") ],
                [ tree_node_upgrade("library", "book") ]
            ]
        },
        {
            title : "СТАЦИОНАР",
            rows : [
                [ tree_node_bed(101), tree_node_bed(102) ],
                [ tree_node_bed(103), tree_node_bed(104) ]
            ]
        },
        {
            title : "ОПЕРАЦИОННАЯ",
            rows : [
                [ {
                    kind : "oper",
                    key : "operating",
                    icon : "surgery",
                    effect : "стол, лампа, места бригады"
                } ]
            ]
        }
    ];
}

function tree_common_nodes() {
    return [
        tree_node_upgrade("hire_slot", "person"),
        tree_node_upgrade("gym", "dumbbell"),
        tree_node_upgrade("pharmacy", "pill")
    ];
}


// ═══════════════════════════════════════════════════════════════
// 4. СОСТОЯНИЕ УЗЛА
// "done" — куплено, "open" — можно купить, "lock" — рано
// ═══════════════════════════════════════════════════════════════

function tree_node_state(_node) {
    switch (_node.kind) {
        case "room": {
            if (clinic_room_is_open(_node.key)) return "done";

            // Кабинет 3 открывается только после второго.
            if (round(_node.key) == 3 && !clinic_room_is_open(2)) return "lock";

            return "open";
        }

        case "bed": {
            if (clinic_bed_is_open(_node.key)) return "done";

            // Четвёртую койку продаём только после третьей.
            if (round(_node.key) == 104 && !clinic_bed_is_open(103)) return "lock";

            return "open";
        }

        case "oper": {
            return clinic_operating_is_open() ? "done" : "open";
        }

        case "upg": {
            if (clinic_upgrade_is_maxed(_node.key)) return "done";
            return "open";
        }
    }

    return "lock";
}

function tree_node_title(_node) {
    switch (_node.kind) {
        case "room": return clinic_room_name(_node.key);
        case "bed":  return clinic_room_name(_node.key);
        case "oper": return "Открыть операционную";
        case "upg":  return clinic_upgrade_name(_node.key);
    }

    return "";
}

function tree_node_effect(_node) {
    if (_node.kind == "upg") {
        return clinic_upgrade_effect_now(_node.key);
    }

    return _node.effect;
}

function tree_node_cost_text(_node, _state) {
    if (_state == "done") {
        if (_node.kind == "upg") return "МАКСИМУМ";
        return "ЕСТЬ";
    }

    if (_node.kind == "upg") {
        return "* " + string(clinic_upgrade_cost(_node.key));
    }

    return "$ " + string(clinic_room_price(_node.key));
}

// Хватает ли валюты прямо сейчас.
function tree_node_affordable(_node) {
    if (_node.kind == "upg") {
        return (global.clinic_points >= clinic_upgrade_cost(_node.key));
    }

    return (global.clinic_money >= clinic_room_price(_node.key));
}


// ═══════════════════════════════════════════════════════════════
// 5. ОТРИСОВКА ОДНОГО УЗЛА
// ═══════════════════════════════════════════════════════════════

function tree_draw_node(_node, _x1, _y1, _x2, _y2, _hovered) {
    var _state = tree_node_state(_node);
    var _is_points = (_node.kind == "upg");

    var _bg = tree_color_paper();
    var _border = tree_color_wood_dark();
    var _ink = tree_color_text();

    if (_state == "done") {
        _bg = tree_color_green_bg();
        _border = tree_color_green();
    }
    else if (_state == "lock") {
        _bg = tree_color_lock_bg();
        _border = tree_color_lock();
        _ink = make_color_rgb(74, 66, 56);
    }
    else if (_hovered) {
        _bg = make_color_rgb(250, 242, 226);
    }

    // Тень и корпус.
    draw_set_alpha(0.20);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 2, _y1 + 4, _x2 + 2, _y2 + 4, 12, 12, false);
    draw_set_alpha(1);

    draw_set_color(_bg);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
    draw_set_color(_border);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, true);
    draw_roundrect_ext(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, 11, 11, true);

    // Иконка в рамке слева.
    var _icon_box = min(46, (_y2 - _y1) - 16);
    var _icon_x1 = _x1 + 10;
    var _icon_y1 = (_y1 + _y2) * 0.5 - _icon_box * 0.5;

    draw_set_color(tree_color_paper_2());
    draw_roundrect_ext(
        _icon_x1, _icon_y1,
        _icon_x1 + _icon_box, _icon_y1 + _icon_box,
        8, 8, false
    );
    draw_set_color(_border);
    draw_roundrect_ext(
        _icon_x1, _icon_y1,
        _icon_x1 + _icon_box, _icon_y1 + _icon_box,
        8, 8, true
    );

    tree_draw_icon(
        _node.icon,
        _icon_x1 + _icon_box * 0.5,
        _icon_y1 + _icon_box * 0.5,
        _icon_box * 0.42,
        _border
    );

    // Название и эффект.
    var _text_x = _icon_x1 + _icon_box + 10;

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_ink);
    draw_text_transformed(_text_x, _y1 + 9, tree_node_title(_node), 1.15, 1.15, 0);

    var _effect = tree_node_effect(_node);

    if (_effect != "") {
        draw_set_color(tree_color_text_soft());
        draw_text_transformed(_text_x, _y1 + 31, _effect, 0.85, 0.85, 0);
    }

    // Точки уровня для улучшений.
    var _cost_y = _y2 - 26;

    if (_node.kind == "upg") {
        var _level = clinic_upgrade_level(_node.key);
        var _max_level = clinic_upgrade_max_level_for(_node.key);
        var _dot_gap = (_max_level > 5) ? 13 : 17;
        var _dot_r = (_max_level > 5) ? 4 : 5;
        var _dot_x = _text_x + _dot_r;
        var _dot_y = _y2 - 34;

        for (var _dot = 0; _dot < _max_level; _dot++) {
            draw_set_color((_dot < _level) ? tree_color_gold() : tree_color_lock_bg());
            draw_circle(_dot_x + _dot * _dot_gap, _dot_y, _dot_r, false);
            draw_set_color(tree_color_line());
            draw_circle(_dot_x + _dot * _dot_gap, _dot_y, _dot_r, true);
        }

        _cost_y = _y2 - 22;
    }

    // Цена: зелёная — деньги, золотая — баллы.
    var _cost_text = tree_node_cost_text(_node, _state);
    var _cost_w = string_width(_cost_text) * 1.05 + 20;
    var _cost_x1 = _x2 - _cost_w - 10;
    var _cost_x2 = _x2 - 10;
    var _cost_y1 = _cost_y - 4;
    var _cost_y2 = _cost_y + 22;

    var _cost_bg = _is_points ? tree_color_gold_bg() : make_color_rgb(226, 239, 224);
    var _cost_border = _is_points ? tree_color_gold() : tree_color_green();
    var _cost_ink = _is_points ? make_color_rgb(122, 90, 20) : make_color_rgb(47, 92, 58);

    if (_state == "done") {
        _cost_bg = tree_color_green();
        _cost_border = make_color_rgb(45, 84, 54);
        _cost_ink = c_white;
    }
    else if (_state == "lock" || !tree_node_affordable(_node)) {
        _cost_bg = make_color_rgb(179, 168, 151);
        _cost_border = make_color_rgb(141, 129, 114);
        _cost_ink = make_color_rgb(74, 66, 56);
    }

    draw_set_color(_cost_bg);
    draw_roundrect_ext(_cost_x1, _cost_y1, _cost_x2, _cost_y2, 7, 7, false);
    draw_set_color(_cost_border);
    draw_roundrect_ext(_cost_x1, _cost_y1, _cost_x2, _cost_y2, 7, 7, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_cost_ink);
    draw_text_transformed(
        (_cost_x1 + _cost_x2) * 0.5,
        (_cost_y1 + _cost_y2) * 0.5,
        _cost_text,
        1.05,
        1.05,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    return _state;
}


// ═══════════════════════════════════════════════════════════════
// 6. СОЕДИНИТЕЛИ
// ═══════════════════════════════════════════════════════════════

function tree_draw_stem(_cx, _y1, _y2, _active) {
    draw_set_color(_active ? tree_color_wood_light() : make_color_rgb(141, 129, 114));

    var _w = 3;
    draw_roundrect_ext(_cx - _w, _y1, _cx + _w, _y2, 3, 3, false);
}

// Развилка: вертикаль вниз, горизонталь, вертикали к двум узлам.
function tree_draw_fork(_cx, _y1, _y2, _left_x, _right_x, _active) {
    var _mid_y = (_y1 + _y2) * 0.5;

    tree_draw_stem(_cx, _y1, _mid_y, _active);

    draw_set_color(_active ? tree_color_wood_light() : make_color_rgb(141, 129, 114));
    draw_roundrect_ext(_left_x - 3, _mid_y - 3, _right_x + 3, _mid_y + 3, 3, 3, false);

    tree_draw_stem(_left_x, _mid_y, _y2, _active);
    tree_draw_stem(_right_x, _mid_y, _y2, _active);
}


// ═══════════════════════════════════════════════════════════════
// 7. ПОКУПКА
// ═══════════════════════════════════════════════════════════════

function tree_node_buy(_node) {
    switch (_node.kind) {
        case "room":
        case "bed":
            return clinic_room_purchase(_node.key);

        case "oper":
            return clinic_room_purchase("operating");

        case "upg":
            return clinic_upgrade_apply(_node.key);
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 8. ПАНЕЛЬ ЦЕЛИКОМ
// Вызывается из hud_draw_clinic_upgrades вместо старых двух колонок.
// ═══════════════════════════════════════════════════════════════

function clinic_tree_draw(_hud) {
    if (!instance_exists(_hud)) return;

    clinic_rooms_init();
    clinic_upgrade_init();

    with (_hud) {
        if (font_exists(fnt_main)) draw_set_font(fnt_main);

        if (!variable_instance_exists(id, "tree_scroll")) tree_scroll = 0;
        if (!variable_instance_exists(id, "tree_touch_active")) tree_touch_active = false;
        if (!variable_instance_exists(id, "tree_touch_last_y")) tree_touch_last_y = 0;

        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);

        var _panel_x1 = main_panel_x1 + 24;
        var _panel_x2 = main_panel_x2 - 24;
        var _panel_y1 = main_panel_y1 + 86;
        var _panel_y2 = main_panel_y2 - 24;

        // ── Балансы в шапке ──
        var _bal_y1 = _panel_y1 - 40;
        var _bal_y2 = _bal_y1 + 32;
        var _money_text = "$ " + string(global.clinic_money);
        var _points_text = "* " + string(global.clinic_points);

        var _money_w = string_width(_money_text) * 1.15 + 26;
        var _pts_w = string_width(_points_text) * 1.15 + 26;
        var _money_x2 = _panel_x2 - _pts_w - 10;
        var _money_x1 = _money_x2 - _money_w;
        var _pts_x1 = _money_x2 + 10;
        var _pts_x2 = _pts_x1 + _pts_w;

        draw_set_color(tree_color_paper());
        draw_roundrect_ext(_money_x1, _bal_y1, _money_x2, _bal_y2, 9, 9, false);
        draw_set_color(tree_color_green());
        draw_roundrect_ext(_money_x1, _bal_y1, _money_x2, _bal_y2, 9, 9, true);

        draw_set_color(tree_color_gold_bg());
        draw_roundrect_ext(_pts_x1, _bal_y1, _pts_x2, _bal_y2, 9, 9, false);
        draw_set_color(tree_color_gold());
        draw_roundrect_ext(_pts_x1, _bal_y1, _pts_x2, _bal_y2, 9, 9, true);

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(47, 92, 58));
        draw_text_transformed((_money_x1 + _money_x2) * 0.5, (_bal_y1 + _bal_y2) * 0.5, _money_text, 1.15, 1.15, 0);
        draw_set_color(make_color_rgb(122, 90, 20));
        draw_text_transformed((_pts_x1 + _pts_x2) * 0.5, (_bal_y1 + _bal_y2) * 0.5, _points_text, 1.15, 1.15, 0);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

        // ── Прокрутка ──
        var _wheel_in = point_in_rectangle(_mx, _my, _panel_x1, _panel_y1, _panel_x2, _panel_y2);

        if (_wheel_in) {
            if (mouse_wheel_down()) tree_scroll += 46;
            if (mouse_wheel_up()) tree_scroll -= 46;
        }

        var _pressed = mouse_check_button_pressed(mb_left)
            || device_mouse_check_button_pressed(0, mb_left);
        var _down = mouse_check_button(mb_left)
            || device_mouse_check_button(0, mb_left);
        var _released = mouse_check_button_released(mb_left)
            || device_mouse_check_button_released(0, mb_left);

        if (_pressed && _wheel_in) {
            tree_touch_active = true;
            tree_touch_last_y = _my;
        }

        var _dragged = false;

        if (tree_touch_active) {
            if (_down) {
                var _delta = _my - tree_touch_last_y;

                if (abs(_delta) > 0) {
                    tree_scroll -= _delta;
                    tree_touch_last_y = _my;
                }

                if (abs(_delta) > 2) _dragged = true;
            }

            if (_released) tree_touch_active = false;
        }

        // ── Общий блок сверху ──
        var _content_y = _panel_y1 - tree_scroll;

        var _common = tree_common_nodes();
        var _common_gap = 12;
        var _common_w = (_panel_x2 - _panel_x1 - _common_gap * 2) / 3;
        var _node_h = 78;

        draw_set_color(tree_color_text());
        draw_set_halign(fa_center);
        draw_text_transformed(
            (_panel_x1 + _panel_x2) * 0.5,
            _content_y,
            "ОБЩЕЕ ДЛЯ КЛИНИКИ",
            1.1,
            1.1,
            0
        );
        draw_set_halign(fa_left);

        var _common_y1 = _content_y + 26;
        var _common_y2 = _common_y1 + _node_h;
        var _click_node = undefined;

        for (var _c = 0; _c < array_length(_common); _c++) {
            var _cx1 = _panel_x1 + _c * (_common_w + _common_gap);
            var _cx2 = _cx1 + _common_w;

            var _c_hover = point_in_rectangle(_mx, _my, _cx1, _common_y1, _cx2, _common_y2)
                && _common_y1 > _panel_y1 - _node_h;

            tree_draw_node(_common[_c], _cx1, _common_y1, _cx2, _common_y2, _c_hover);

            if (_c_hover && _pressed) _click_node = _common[_c];
        }

        // Ствол от общего блока к веткам.
        var _trunk_y1 = _common_y2;
        var _trunk_y2 = _common_y2 + 26;
        tree_draw_stem((_panel_x1 + _panel_x2) * 0.5, _trunk_y1, _trunk_y2, true);

        // ── Три ветки ──
        var _branches = tree_branches();
        var _branch_gap = 14;
        var _branch_w = (_panel_x2 - _panel_x1 - _branch_gap * 2) / 3;
        var _branch_y = _trunk_y2 + 6;

        for (var _b = 0; _b < array_length(_branches); _b++) {
            var _branch = _branches[_b];
            var _bx1 = _panel_x1 + _b * (_branch_w + _branch_gap);
            var _bx2 = _bx1 + _branch_w;
            var _bcx = (_bx1 + _bx2) * 0.5;

            // Заголовок ветки.
            draw_set_color(tree_color_wood_dark());
            draw_roundrect_ext(_bx1, _branch_y, _bx2, _branch_y + 34, 9, 9, false);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(255, 233, 194));
            draw_text_transformed(_bcx, _branch_y + 17, _branch.title, 1.1, 1.1, 0);
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);

            var _row_y = _branch_y + 34;

            for (var _r = 0; _r < array_length(_branch.rows); _r++) {
                var _row = _branch.rows[_r];
                var _pair = (array_length(_row) > 1);

                // Соединитель от предыдущего ряда.
                var _link_y1 = _row_y;
                var _link_y2 = _row_y + 24;

                if (_pair) {
                    tree_draw_fork(
                        _bcx,
                        _link_y1,
                        _link_y2,
                        _bx1 + _branch_w * 0.25,
                        _bx1 + _branch_w * 0.75,
                        true
                    );
                } else {
                    tree_draw_stem(_bcx, _link_y1, _link_y2, true);
                }

                var _node_y1 = _link_y2;
                var _node_y2 = _node_y1 + _node_h;
                var _visible = (_node_y2 > _panel_y1) && (_node_y1 < _panel_y2);

                for (var _n = 0; _n < array_length(_row); _n++) {
                    var _nx1, _nx2;

                    if (_pair) {
                        var _half = (_branch_w - 8) * 0.5;
                        _nx1 = _bx1 + _n * (_half + 8);
                        _nx2 = _nx1 + _half;
                    } else {
                        _nx1 = _bx1;
                        _nx2 = _bx2;
                    }

                    if (!_visible) continue;

                    var _hover = point_in_rectangle(_mx, _my, _nx1, _node_y1, _nx2, _node_y2);

                    tree_draw_node(_row[_n], _nx1, _node_y1, _nx2, _node_y2, _hover);

                    if (_hover && _pressed) _click_node = _row[_n];
                }

                _row_y = _node_y2;
            }
        }

        // Ограничиваем прокрутку по фактической высоте содержимого.
        var _content_h = 26 + _node_h + 26 + 34 + 4 * (24 + _node_h) + 40;
        var _max_scroll = max(0, _content_h - (_panel_y2 - _panel_y1));
        tree_scroll = clamp(tree_scroll, 0, _max_scroll);

        // Бегунок.
        if (_max_scroll > 0) {
            var _sb_x2 = _panel_x2 + 12;
            var _sb_x1 = _sb_x2 - 8;

            draw_set_alpha(0.18);
            draw_set_color(c_black);
            draw_roundrect_ext(_sb_x1, _panel_y1, _sb_x2, _panel_y2, 4, 4, false);
            draw_set_alpha(1);

            var _track_h = _panel_y2 - _panel_y1;
            var _thumb_h = max(40, _track_h * (_track_h / _content_h));
            var _thumb_y = _panel_y1 + (_track_h - _thumb_h) * (tree_scroll / max(1, _max_scroll));

            draw_set_color(tree_color_wood_light());
            draw_roundrect_ext(_sb_x1, _thumb_y, _sb_x2, _thumb_y + _thumb_h, 4, 4, false);
        }

        // ── Покупка ──
        if (
            !is_undefined(_click_node)
            && !_dragged
            && tablet_click_lock <= 0
        ) {
            var _state = tree_node_state(_click_node);

            if (_state == "open") {
                tablet_click_lock = 6;
                tree_node_buy(_click_node);
            }
            else if (_state == "lock") {
                tablet_click_lock = 6;

                if (variable_instance_exists(id, "show_notice")) {
                    show_notice(
                        "ЕЩЁ РАНО",
                        "Сначала откройте предыдущий узел ветки.",
                        max(1, game_get_speed(gamespeed_fps)) * 2
                    );
                }
            }
        }

        draw_set_color(c_white);
        draw_set_alpha(1);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
}
