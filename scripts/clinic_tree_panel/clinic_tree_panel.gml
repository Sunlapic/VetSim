/// clinic_tree_panel.gml
/// @description Пакет №173. Панель «КЛИНИКА - РАЗВИТИЕ» в виде дерева.
/// Пакет №200: при прокрутке карточки больше не вылезают за окно на HUD —
/// рисуется только то, что помещается целиком.
///
/// Правка 3: всё крупное под телефон, ничего не налезает друг на друга.
///   • подписи и цены крупным шрифтом, длинные строки сами ужимаются;
///   • цена словами: «Баллов: 14» и «$ 1 600»;
///   • кружки уровня зелёные, шаг одинаковый во всех узлах;
///   • балансы денег и баллов убраны — они уже есть в верхней панели HUD;
///   • сетка адаптивная: сколько колонок влезет, столько и будет,
///     на узком экране всё выстраивается в одну колонку с прокруткой.
///
/// Иконки собраны из примитивов (прямоугольник, круг, линия) — в fnt_main
/// нет ни эмодзи, ни значков, а новые спрайты рисовать не нужно.


// ═══════════════════════════════════════════════════════════════
// 1. ПАЛИТРА И РАЗМЕРЫ
// ═══════════════════════════════════════════════════════════════

function tree_color_wood_dark()  { return make_color_rgb(74, 49, 31); }
function tree_color_wood_light() { return make_color_rgb(150, 107, 73); }
function tree_color_paper()      { return make_color_rgb(242, 232, 214); }
function tree_color_paper_2()    { return make_color_rgb(232, 220, 198); }
function tree_color_line()       { return make_color_rgb(58, 39, 24); }
function tree_color_text()       { return make_color_rgb(50, 38, 28); }
function tree_color_text_soft()  { return make_color_rgb(88, 70, 52); }
function tree_color_green()      { return make_color_rgb(62, 112, 74); }
function tree_color_green_dark() { return make_color_rgb(45, 84, 54); }
function tree_color_green_bg()   { return make_color_rgb(217, 232, 213); }
function tree_color_gold()       { return make_color_rgb(180, 140, 64); }
function tree_color_gold_bg()    { return make_color_rgb(247, 237, 214); }
function tree_color_lock()       { return make_color_rgb(109, 97, 84); }
function tree_color_lock_bg()    { return make_color_rgb(207, 199, 184); }

// Минимальная ширина узла: если не влезает — колонок становится меньше.
#macro TREE_NODE_MIN_W 520

// Эталон шага кружков: самый длинный ряд (слот найма, 14 уровней + запас).
#macro TREE_DOT_REFERENCE 15
#macro TREE_HIRE_MAX_LEVEL 14

// Масштабы шрифта. Всё крупное — игра телефонная.
#macro TREE_FS_TITLE 1.75
#macro TREE_FS_EFFECT 1.25
#macro TREE_FS_COST 1.45
#macro TREE_FS_HEADER 1.55

// Высоты блоков внутри узла.
#macro TREE_PAD 18
#macro TREE_ICON 72
#macro TREE_H_TITLE 40
#macro TREE_H_EFFECT 32
#macro TREE_H_COST 56
#macro TREE_H_DOTS 48


// Пакет №174: подбор масштаба переехал в общий UI-кит (hud_ui_scale),
// чтобы во всех окнах работало одинаковое правило.
function tree_fit_scale(_text, _max_w, _base) {
    return ui_fit_scale(_text, _max_w, _base);
}

function tree_dot_metrics(_node_w) {
    var _avail = _node_w - TREE_PAD * 2 - 12;
    var _gap = _avail / TREE_DOT_REFERENCE;

    return {
        gap : _gap,
        radius : clamp(_gap * 0.32, 6, 16)
    };
}

function tree_node_height(_node) {
    var _h = TREE_PAD * 2 + TREE_H_TITLE + TREE_H_EFFECT + TREE_H_COST;

    if (_node.kind == "upg") _h += TREE_H_DOTS;

    return _h;
}


// ═══════════════════════════════════════════════════════════════
// 2. ИКОНКИ ИЗ ПРИМИТИВОВ
// ═══════════════════════════════════════════════════════════════

function tree_icon_door(_cx, _cy, _size, _color) {
    var _w = _size * 0.42;
    var _h = _size * 0.72;

    draw_set_color(_color);
    draw_roundrect_ext(_cx - _w, _cy - _h, _cx + _w, _cy + _h, 3, 3, true);
    draw_roundrect_ext(_cx - _w + 1, _cy - _h + 1, _cx + _w - 1, _cy + _h - 1, 3, 3, true);
    draw_circle(_cx + _w * 0.45, _cy + _size * 0.06, max(2, _size * 0.08), false);
}

function tree_icon_bed(_cx, _cy, _size, _color) {
    var _w = _size * 0.78;
    var _h = _size * 0.26;

    draw_set_color(_color);
    draw_roundrect_ext(_cx - _w, _cy - _h, _cx + _w, _cy + _h, 3, 3, true);
    draw_roundrect_ext(_cx - _w + 1, _cy - _h + 1, _cx + _w - 1, _cy + _h - 1, 3, 3, true);
    draw_roundrect_ext(
        _cx - _w + 2, _cy - _h - _size * 0.26,
        _cx - _w + _size * 0.52, _cy - _h,
        3, 3, true
    );
    draw_line(_cx - _w, _cy + _h, _cx - _w, _cy + _h + _size * 0.20);
    draw_line(_cx + _w, _cy + _h, _cx + _w, _cy + _h + _size * 0.20);
}

function tree_icon_surgery(_cx, _cy, _size, _color) {
    var _w = _size * 0.78;

    draw_set_color(_color);
    draw_roundrect_ext(_cx - _w, _cy, _cx + _w, _cy + _size * 0.24, 3, 3, true);
    draw_roundrect_ext(_cx - _w + 1, _cy + 1, _cx + _w - 1, _cy + _size * 0.24 - 1, 3, 3, true);
    draw_line(_cx - _w * 0.6, _cy + _size * 0.24, _cx - _w * 0.6, _cy + _size * 0.54);
    draw_line(_cx + _w * 0.6, _cy + _size * 0.24, _cx + _w * 0.6, _cy + _size * 0.54);
    draw_circle(_cx, _cy - _size * 0.40, _size * 0.26, true);
    draw_circle(_cx, _cy - _size * 0.40, _size * 0.26 - 1, true);
}

function tree_icon_book(_cx, _cy, _size, _color) {
    var _w = _size * 0.68;
    var _h = _size * 0.58;

    draw_set_color(_color);
    draw_roundrect_ext(_cx - _w, _cy - _h, _cx + _w, _cy + _h, 3, 3, true);
    draw_roundrect_ext(_cx - _w + 1, _cy - _h + 1, _cx + _w - 1, _cy + _h - 1, 3, 3, true);
    draw_line(_cx, _cy - _h, _cx, _cy + _h);
}

function tree_icon_person(_cx, _cy, _size, _color) {
    draw_set_color(_color);

    draw_circle(_cx - _size * 0.14, _cy - _size * 0.36, _size * 0.26, true);
    draw_circle(_cx - _size * 0.14, _cy - _size * 0.36, _size * 0.26 - 1, true);

    draw_line(_cx - _size * 0.64, _cy + _size * 0.48, _cx - _size * 0.44, _cy + _size * 0.02);
    draw_line(_cx + _size * 0.16, _cy + _size * 0.48, _cx + _size * 0.00, _cy + _size * 0.02);
    draw_line(_cx - _size * 0.64, _cy + _size * 0.48, _cx + _size * 0.16, _cy + _size * 0.48);

    draw_set_color(tree_color_green());
    draw_line(_cx + _size * 0.54, _cy - _size * 0.50, _cx + _size * 0.54, _cy - _size * 0.06);
    draw_line(_cx + _size * 0.32, _cy - _size * 0.28, _cx + _size * 0.76, _cy - _size * 0.28);
    draw_line(_cx + _size * 0.55, _cy - _size * 0.50, _cx + _size * 0.55, _cy - _size * 0.06);
    draw_line(_cx + _size * 0.32, _cy - _size * 0.27, _cx + _size * 0.76, _cy - _size * 0.27);
}

function tree_icon_dumbbell(_cx, _cy, _size, _color) {
    draw_set_color(_color);

    draw_roundrect_ext(
        _cx - _size * 0.50, _cy - _size * 0.14,
        _cx + _size * 0.50, _cy + _size * 0.14,
        3, 3, true
    );
    draw_roundrect_ext(
        _cx - _size * 0.84, _cy - _size * 0.36,
        _cx - _size * 0.50, _cy + _size * 0.36,
        3, 3, true
    );
    draw_roundrect_ext(
        _cx + _size * 0.50, _cy - _size * 0.36,
        _cx + _size * 0.84, _cy + _size * 0.36,
        3, 3, true
    );
}

function tree_icon_pill(_cx, _cy, _size, _color) {
    draw_set_color(_color);

    draw_circle(_cx, _cy, _size * 0.54, true);
    draw_circle(_cx, _cy, _size * 0.54 - 1, true);
    draw_line(
        _cx - _size * 0.38, _cy + _size * 0.38,
        _cx + _size * 0.38, _cy - _size * 0.38
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
// kind: "room" — помещение за деньги, "bed" — койка стационара,
//       "oper" — операционная, "upg" — улучшение за баллы,
//       "soon" — заглушка под будущие узлы.
// ═══════════════════════════════════════════════════════════════

function tree_node_room(_slot, _icon, _effect) {
    return { kind : "room", key : _slot, icon : _icon, effect : _effect };
}

function tree_node_bed(_slot) {
    return { kind : "bed", key : _slot, icon : "bed", effect : "место в стационаре" };
}

function tree_node_upgrade(_id, _icon) {
    return { kind : "upg", key : _id, icon : _icon, effect : "" };
}

function tree_sections() {
    return [
        {
            title : "ОБЩЕЕ ДЛЯ КЛИНИКИ",
            nodes : [
                tree_node_upgrade("hire_slot", "person"),
                tree_node_upgrade("library", "book"),
                tree_node_upgrade("gym", "dumbbell"),
                tree_node_upgrade("pharmacy", "pill")
            ]
        },
        {
            title : "РЕГИСТРАТУРА",
            nodes : [
                {
                    kind : "soon",
                    key : "reception",
                    icon : "person",
                    effect : "ветка появится позже"
                }
            ]
        },
        {
            title : "ПРИЁМ",
            nodes : [
                tree_node_room(2, "door", "второй стол приёма"),
                tree_node_room(3, "door", "третий стол приёма")
            ]
        },
        {
            title : "СТАЦИОНАР",
            nodes : [
                tree_node_bed(101),
                tree_node_bed(102),
                tree_node_bed(103),
                tree_node_bed(104)
            ]
        },
        {
            title : "ОПЕРАЦИОННАЯ",
            nodes : [
                {
                    kind : "oper",
                    key : "operating",
                    icon : "surgery",
                    effect : "стол, лампа, места бригады"
                }
            ]
        }
    ];
}


// ═══════════════════════════════════════════════════════════════
// 4. СОСТОЯНИЕ И ПОДПИСИ УЗЛА
// ═══════════════════════════════════════════════════════════════

function tree_node_state(_node) {
    switch (_node.kind) {
        case "soon": return "lock";

        case "room": {
            if (clinic_room_is_open(_node.key)) return "done";
            if (round(_node.key) == 3 && !clinic_room_is_open(2)) return "lock";
            return "open";
        }

        case "bed": {
            if (clinic_bed_is_open(_node.key)) return "done";
            if (round(_node.key) == 104 && !clinic_bed_is_open(103)) return "lock";
            return "open";
        }

        case "oper": return clinic_operating_is_open() ? "done" : "open";

        case "upg": return clinic_upgrade_is_maxed(_node.key) ? "done" : "open";
    }

    return "lock";
}

function tree_node_title(_node) {
    switch (_node.kind) {
        case "soon": return "СКОРО";
        case "room": return clinic_room_name(_node.key);
        case "bed":  return clinic_room_name(_node.key);
        case "oper": return "Открыть операционную";
        case "upg":  return clinic_upgrade_name(_node.key);
    }

    return "";
}

function tree_node_effect(_node) {
    if (_node.kind == "upg") return clinic_upgrade_effect_now(_node.key);

    return _node.effect;
}

function tree_node_cost_text(_node, _state) {
    if (_node.kind == "soon") return "В РАЗРАБОТКЕ";

    if (_state == "done") {
        return (_node.kind == "upg") ? "МАКСИМАЛЬНЫЙ УРОВЕНЬ" : "УЖЕ ОТКРЫТО";
    }

    // Пакет №173 (правка): цена словами, без значков.
    if (_node.kind == "upg") {
        return "Баллов: " + string(clinic_upgrade_cost(_node.key));
    }

    return "Цена: $ " + string(clinic_room_price(_node.key));
}

function tree_node_affordable(_node) {
    if (_node.kind == "soon") return false;

    if (_node.kind == "upg") {
        return (global.clinic_points >= clinic_upgrade_cost(_node.key));
    }

    return (global.clinic_money >= clinic_room_price(_node.key));
}

function tree_node_buy(_node) {
    switch (_node.kind) {
        case "room":
        case "bed":  return clinic_room_purchase(_node.key);
        case "oper": return clinic_room_purchase("operating");
        case "upg":  return clinic_upgrade_apply(_node.key);
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 5. ОТРИСОВКА УЗЛА
// Порядок строк жёсткий, каждая в своей полосе — наложений быть не может.
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

    // Корпус.
    draw_set_alpha(0.20);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 3, _y1 + 5, _x2 + 3, _y2 + 5, 14, 14, false);
    draw_set_alpha(1);

    draw_set_color(_bg);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, false);
    draw_set_color(_border);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, true);
    draw_roundrect_ext(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, 13, 13, true);
    draw_roundrect_ext(_x1 + 2, _y1 + 2, _x2 - 2, _y2 - 2, 12, 12, true);

    // Иконка.
    var _icon_x1 = _x1 + TREE_PAD;
    var _icon_y1 = _y1 + TREE_PAD;

    draw_set_color(tree_color_paper_2());
    draw_roundrect_ext(_icon_x1, _icon_y1, _icon_x1 + TREE_ICON, _icon_y1 + TREE_ICON, 10, 10, false);
    draw_set_color(_border);
    draw_roundrect_ext(_icon_x1, _icon_y1, _icon_x1 + TREE_ICON, _icon_y1 + TREE_ICON, 10, 10, true);
    draw_roundrect_ext(_icon_x1 + 1, _icon_y1 + 1, _icon_x1 + TREE_ICON - 1, _icon_y1 + TREE_ICON - 1, 10, 10, true);

    tree_draw_icon(
        _node.icon,
        _icon_x1 + TREE_ICON * 0.5,
        _icon_y1 + TREE_ICON * 0.5,
        TREE_ICON * 0.44,
        _border
    );

    // ── Полоса 1: название ──
    var _text_x = _icon_x1 + TREE_ICON + 16;
    var _text_w = (_x2 - TREE_PAD) - _text_x;
    var _line_y = _y1 + TREE_PAD;

    var _title = tree_node_title(_node);
    var _title_scale = tree_fit_scale(_title, _text_w, TREE_FS_TITLE);

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_color(_ink);
    draw_text_transformed(_text_x, _line_y + TREE_H_TITLE * 0.5, _title, _title_scale, _title_scale, 0);

    // ── Полоса 2: подсказка (эффект) ──
    _line_y += TREE_H_TITLE;

    var _effect = tree_node_effect(_node);

    if (_effect != "") {
        var _eff_scale = tree_fit_scale(_effect, _text_w, TREE_FS_EFFECT);

        draw_set_color(tree_color_text_soft());
        draw_text_transformed(_text_x, _line_y + TREE_H_EFFECT * 0.5, _effect, _eff_scale, _eff_scale, 0);
    }

    // ── Полоса 3: цена ──
    _line_y += TREE_H_EFFECT;

    var _cost_text = tree_node_cost_text(_node, _state);
    var _cost_scale = tree_fit_scale(_cost_text, _text_w - 28, TREE_FS_COST);
    var _cost_w = string_width(_cost_text) * _cost_scale + 28;
    var _cost_x1 = _text_x;
    var _cost_x2 = min(_x2 - TREE_PAD, _cost_x1 + _cost_w);
    var _cost_y1 = _line_y + 4;
    var _cost_y2 = _line_y + TREE_H_COST - 8;

    var _cost_bg = _is_points ? tree_color_gold_bg() : make_color_rgb(226, 239, 224);
    var _cost_border = _is_points ? tree_color_gold() : tree_color_green();
    var _cost_ink = _is_points ? make_color_rgb(122, 90, 20) : make_color_rgb(47, 92, 58);

    if (_state == "done") {
        _cost_bg = tree_color_green();
        _cost_border = tree_color_green_dark();
        _cost_ink = c_white;
    }
    else if (_state == "lock" || !tree_node_affordable(_node)) {
        _cost_bg = make_color_rgb(179, 168, 151);
        _cost_border = make_color_rgb(141, 129, 114);
        _cost_ink = make_color_rgb(74, 66, 56);
    }

    draw_set_color(_cost_bg);
    draw_roundrect_ext(_cost_x1, _cost_y1, _cost_x2, _cost_y2, 9, 9, false);
    draw_set_color(_cost_border);
    draw_roundrect_ext(_cost_x1, _cost_y1, _cost_x2, _cost_y2, 9, 9, true);
    draw_roundrect_ext(_cost_x1 + 1, _cost_y1 + 1, _cost_x2 - 1, _cost_y2 - 1, 8, 8, true);

    draw_set_halign(fa_center);
    draw_set_color(_cost_ink);
    draw_text_transformed(
        (_cost_x1 + _cost_x2) * 0.5,
        (_cost_y1 + _cost_y2) * 0.5,
        _cost_text,
        _cost_scale,
        _cost_scale,
        0
    );

    // ── Полоса 4: кружки уровня, зелёные, по низу ──
    if (_node.kind == "upg") {
        var _level = clinic_upgrade_level(_node.key);
        var _max_level = clinic_upgrade_max_level_for(_node.key);

        var _metrics = tree_dot_metrics(_x2 - _x1);
        var _gap = _metrics.gap;
        var _dot_r = _metrics.radius;

        var _row_w = (_max_level - 1) * _gap;
        var _dot_x = (_x1 + _x2) * 0.5 - _row_w * 0.5;
        var _dot_y = _y2 - TREE_H_DOTS * 0.5;

        for (var _dot = 0; _dot < _max_level; _dot++) {
            var _px = _dot_x + _dot * _gap;

            draw_set_alpha(0.18);
            draw_set_color(c_black);
            draw_circle(_px + 1, _dot_y + 2, _dot_r, false);
            draw_set_alpha(1);

            // Заполненные — зелёные (пакет №173, правка 3).
            draw_set_color((_dot < _level) ? tree_color_green() : tree_color_lock_bg());
            draw_circle(_px, _dot_y, _dot_r, false);

            draw_set_color((_dot < _level) ? tree_color_green_dark() : tree_color_line());
            draw_circle(_px, _dot_y, _dot_r, true);
            draw_circle(_px, _dot_y, _dot_r - 1, true);
        }
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    return _state;
}


// ═══════════════════════════════════════════════════════════════
// 6. СОЕДИНИТЕЛЬ МЕЖДУ УЗЛАМИ ВЕТКИ
// ═══════════════════════════════════════════════════════════════

function tree_draw_stem(_cx, _y1, _y2, _active) {
    draw_set_color(_active ? tree_color_wood_light() : make_color_rgb(141, 129, 114));
    draw_roundrect_ext(_cx - 4, _y1, _cx + 4, _y2, 4, 4, false);
}


// ═══════════════════════════════════════════════════════════════
// 7. КРУПНАЯ КНОПКА ДЛЯ ВКЛАДОК
// ═══════════════════════════════════════════════════════════════

function hud_draw_button_big(
    _x1, _y1, _x2, _y2, _text, _active, _hover,
    _fill, _hover_fill, _active_fill, _line_dark, _text_color
) {
    // Пакет №180: единый стиль вкладок переехал в UI-кит (ui_draw_tab).
    // Функция оставлена ради совместимости со старыми вызовами.
    ui_draw_tab(_x1, _y1, _x2, _y2, _text, _active, _hover);
}


// ═══════════════════════════════════════════════════════════════
// 8. ПАНЕЛЬ ЦЕЛИКОМ
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
        if (!variable_instance_exists(id, "tree_content_h")) tree_content_h = 0;

        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);

        var _panel_x1 = main_panel_x1 + 24;
        var _panel_x2 = main_panel_x2 - 30;
        var _panel_y1 = main_panel_y1 + 104;
        var _panel_y2 = main_panel_y2 - 20;

        var _panel_w = _panel_x2 - _panel_x1;
        var _panel_h = _panel_y2 - _panel_y1;

        // ── Сколько колонок влезет ──
        var _col_gap = 16;
        var _cols = clamp(
            floor((_panel_w + _col_gap) / (TREE_NODE_MIN_W + _col_gap)),
            1,
            3
        );
        var _col_w = (_panel_w - _col_gap * (_cols - 1)) / _cols;

        // ── Ввод: колесо и перетаскивание ──
        var _in_panel = point_in_rectangle(_mx, _my, _panel_x1, _panel_y1, _panel_x2, _panel_y2);

        if (_in_panel) {
            if (mouse_wheel_down()) tree_scroll += 70;
            if (mouse_wheel_up()) tree_scroll -= 70;
        }

        var _pressed = mouse_check_button_pressed(mb_left)
            || device_mouse_check_button_pressed(0, mb_left);
        var _down = mouse_check_button(mb_left)
            || device_mouse_check_button(0, mb_left);
        var _released = mouse_check_button_released(mb_left)
            || device_mouse_check_button_released(0, mb_left);

        if (_pressed && _in_panel) {
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

                if (abs(_delta) > 3) _dragged = true;
            }

            if (_released) tree_touch_active = false;
        }

        // Пакет №200: небольшой запас, чтобы последняя карточка точно
        // доезжала до конца и не «пропадала» из-за округлений.
        var _max_scroll = max(0, tree_content_h - _panel_h + 12);
        tree_scroll = clamp(tree_scroll, 0, _max_scroll);

        // ── Раскладка: секции идут сверху вниз, узлы внутри — по колонкам ──
        var _sections = tree_sections();
        var _y = _panel_y1 - tree_scroll;
        var _click_node = undefined;
        var _header_h = 56;
        var _section_gap = 26;

        for (var _s = 0; _s < array_length(_sections); _s++) {
            var _section = _sections[_s];

            // Пакет №200: рисуем только то, что помещается в окно ЦЕЛИКОМ.
            // Раньше проверялось «задевает ли элемент область» — и верхняя
            // (или нижняя) часть карточки вылезала за панель прямо на
            // верхний и нижний HUD.
            if (_y >= _panel_y1 && _y + _header_h <= _panel_y2) {
                draw_set_color(tree_color_wood_dark());
                draw_roundrect_ext(_panel_x1, _y, _panel_x2, _y + _header_h, 12, 12, false);
                draw_set_color(tree_color_wood_light());
                draw_roundrect_ext(_panel_x1 + 2, _y + 2, _panel_x2 - 2, _y + _header_h - 2, 10, 10, true);

                var _h_scale = tree_fit_scale(_section.title, _panel_w - 40, TREE_FS_HEADER);

                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(255, 233, 194));
                draw_text_transformed(
                    (_panel_x1 + _panel_x2) * 0.5,
                    _y + _header_h * 0.5,
                    _section.title,
                    _h_scale,
                    _h_scale,
                    0
                );
                draw_set_halign(fa_left);
                draw_set_valign(fa_top);
            }

            _y += _header_h + 14;

            // Узлы секции по колонкам.
            var _nodes = _section.nodes;
            var _row_y = _y;
            var _row_max_h = 0;

            for (var _n = 0; _n < array_length(_nodes); _n++) {
                var _node = _nodes[_n];
                var _col = _n mod _cols;

                if (_col == 0 && _n > 0) {
                    _row_y += _row_max_h + 14;
                    _row_max_h = 0;
                }

                var _nx1 = _panel_x1 + _col * (_col_w + _col_gap);
                var _nx2 = _nx1 + _col_w;
                var _nh = tree_node_height(_node);
                var _ny1 = _row_y;
                var _ny2 = _ny1 + _nh;

                if (_nh > _row_max_h) _row_max_h = _nh;

                // Соединитель к предыдущему узлу этой же колонки.
                if (
                    _n >= _cols
                    && (_ny1 - 14) >= _panel_y1
                    && _ny1 <= _panel_y2
                ) {
                    tree_draw_stem((_nx1 + _nx2) * 0.5, _ny1 - 14, _ny1, true);
                }

                // Узел показывается, только если влезает в окно полностью.
                // Исключение — узел выше самого окна: иначе он не появился бы
                // вообще (на очень низком экране).
                var _node_fits = (_ny1 >= _panel_y1 && _ny2 <= _panel_y2)
                    || (_nh >= _panel_h);

                if (_node_fits) {
                    var _hover = point_in_rectangle(_mx, _my, _nx1, _ny1, _nx2, _ny2);

                    tree_draw_node(_node, _nx1, _ny1, _nx2, _ny2, _hover);

                    if (_hover && _pressed) _click_node = _node;
                }
            }

            _y = _row_y + _row_max_h + _section_gap;
        }

        // Фактическая высота содержимого — для следующего кадра.
        tree_content_h = (_y + tree_scroll) - _panel_y1;

        // ── Бегунок ──
        if (_max_scroll > 0) {
            var _sb_x2 = _panel_x2 + 18;
            var _sb_x1 = _sb_x2 - 12;

            draw_set_alpha(0.18);
            draw_set_color(c_black);
            draw_roundrect_ext(_sb_x1, _panel_y1, _sb_x2, _panel_y2, 6, 6, false);
            draw_set_alpha(1);

            var _thumb_h = max(60, _panel_h * (_panel_h / max(1, tree_content_h)));
            var _thumb_y = _panel_y1 + (_panel_h - _thumb_h) * (tree_scroll / max(1, _max_scroll));

            draw_set_color(tree_color_wood_light());
            draw_roundrect_ext(_sb_x1, _thumb_y, _sb_x2, _thumb_y + _thumb_h, 6, 6, false);
            draw_set_color(tree_color_wood_dark());
            draw_roundrect_ext(_sb_x1, _thumb_y, _sb_x2, _thumb_y + _thumb_h, 6, 6, true);
        }

        // ── Покупка ──
        if (!is_undefined(_click_node) && !_dragged && tablet_click_lock <= 0) {
            var _state = tree_node_state(_click_node);

            if (_state == "open") {
                tablet_click_lock = 6;
                tree_node_buy(_click_node);
            }
            else if (_state == "lock") {
                tablet_click_lock = 6;

                if (variable_instance_exists(id, "show_notice")) {
                    var _msg = (_click_node.kind == "soon")
                        ? "Эта ветка ещё в разработке."
                        : "Сначала откройте предыдущий узел ветки.";

                    show_notice("ЕЩЁ РАНО", _msg, max(1, game_get_speed(gamespeed_fps)) * 2);
                }
            }
        }

        draw_set_color(c_white);
        draw_set_alpha(1);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
}
