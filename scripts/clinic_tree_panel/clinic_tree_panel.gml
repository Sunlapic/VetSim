/// clinic_tree_panel.gml
/// @description Пакет №173. Панель «КЛИНИКА - РАЗВИТИЕ» в виде дерева.
/// Пакет №202: покупка только по отпусканию пальца и с подтверждением.
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

        // Пакет №202: касание больше не покупает сразу.
        // tree_touch_start_y  — где палец коснулся экрана;
        // tree_touch_moved    — палец уехал дальше 8 пикселей, это прокрутка;
        // tree_confirm_node   — узел, для которого открыт вопрос «покупаем?».
        if (!variable_instance_exists(id, "tree_touch_start_y")) tree_touch_start_y = 0;
        if (!variable_instance_exists(id, "tree_touch_moved")) tree_touch_moved = false;
        if (!variable_instance_exists(id, "tree_confirm_node")) tree_confirm_node = undefined;

        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);

        var _panel_x1 = main_panel_x1 + 24;
        var _panel_x2 = main_panel_x2 - 30;
        var _panel_y1 = main_panel_y1 + 104;
        var _panel_y2 = main_panel_y2 - 20;

        var _panel_w = _panel_x2 - _panel_x1;
        var _panel_h = _panel_y2 - _panel_y1;

        // Пакет №201: число столбцов считается ниже, вместе с раскладкой веток.
        var _col_gap = 16;

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

        // Пока открыт вопрос о покупке, список не прокручивается.
        var _confirm_open = !is_undefined(tree_confirm_node);

        if (_pressed && _in_panel && !_confirm_open) {
            tree_touch_active = true;
            tree_touch_last_y = _my;
            tree_touch_start_y = _my;
            tree_touch_moved = false;
        }

        if (tree_touch_active) {
            if (_down) {
                var _delta = _my - tree_touch_last_y;

                if (abs(_delta) > 0) {
                    tree_scroll -= _delta;
                    tree_touch_last_y = _my;
                }

                // 8 пикселей — порог: меньше считается нажатием, больше уже
                // прокруткой. Палец при обычном тапе всегда чуть смещается.
                if (abs(_my - tree_touch_start_y) > 8) tree_touch_moved = true;
            }
        }

        // Тап = отпустили палец там же, где нажали, и не прокручивали.
        var _tap = (
            tree_touch_active
            && _released
            && !tree_touch_moved
            && !_confirm_open
        );

        if (_released) tree_touch_active = false;

        // Пакет №200: небольшой запас, чтобы последняя карточка точно
        // доезжала до конца и не «пропадала» из-за округлений.
        var _max_scroll = max(0, tree_content_h - _panel_h + 12);
        tree_scroll = clamp(tree_scroll, 0, _max_scroll);

        // ═══════════════════════════════════════════════════════
        // Пакет №201: РАСКЛАДКА СТОЛБИКАМИ
        //
        //   ┌ ОБЩЕЕ ДЛЯ КЛИНИКИ ───────────────────────────────┐
        //   │ [найм] [библиотека] [зал] [аптека]               │
        //   └──────────────────────────────────────────────────┘
        //   РЕГИСТРАТУРА │ ПРИЁМ      │ СТАЦИОНАР │ ОПЕРАЦИОННАЯ
        //   [узел]       │ [стол 2]   │ [койка 1] │ [операционная]
        //                │ [стол 3]   │ [койка 2] │
        //                            │ [койка 3] │
        //
        // Общая секция всегда сверху во всю ширину, остальные ветки —
        // четырьмя столбиками рядом. На узком экране столбиков меньше:
        // 4 → 2 → 1, и секции раскладываются по самым коротким столбцам.
        // ═══════════════════════════════════════════════════════

        var _sections = tree_sections();
        var _click_node = undefined;
        var _header_h = 56;
        var _section_gap = 26;
        var _node_gap = 14;

        var _branch_cols = (_panel_w >= 1240) ? 4 : ((_panel_w >= 660) ? 2 : 1);
        var _branch_w = (_panel_w - _col_gap * (_branch_cols - 1)) / _branch_cols;

        var _y = _panel_y1 - tree_scroll;

        // ── 1. Общая секция: заголовок и узлы в ряд ──
        var _common = _sections[0];

        if (_y >= _panel_y1 && _y + _header_h <= _panel_y2) {
            draw_set_color(tree_color_wood_dark());
            draw_roundrect_ext(_panel_x1, _y, _panel_x2, _y + _header_h, 12, 12, false);
            draw_set_color(tree_color_wood_light());
            draw_roundrect_ext(_panel_x1 + 2, _y + 2, _panel_x2 - 2, _y + _header_h - 2, 10, 10, true);

            var _ch_scale = tree_fit_scale(_common.title, _panel_w - 40, TREE_FS_HEADER);

            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(255, 233, 194));
            draw_text_transformed(
                (_panel_x1 + _panel_x2) * 0.5,
                _y + _header_h * 0.5,
                _common.title,
                _ch_scale,
                _ch_scale,
                0
            );
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
        }

        _y += _header_h + 14;

        var _common_nodes = _common.nodes;
        var _common_count = array_length(_common_nodes);
        var _common_cols = max(1, min(_branch_cols, _common_count));
        var _common_w = (_panel_w - _col_gap * (_common_cols - 1)) / _common_cols;
        var _common_row_y = _y;
        var _common_row_h = 0;

        for (var _cn = 0; _cn < _common_count; _cn++) {
            var _cnode = _common_nodes[_cn];
            var _ccol = _cn mod _common_cols;

            if (_ccol == 0 && _cn > 0) {
                _common_row_y += _common_row_h + _node_gap;
                _common_row_h = 0;
            }

            var _cx1 = _panel_x1 + _ccol * (_common_w + _col_gap);
            var _cx2 = _cx1 + _common_w;
            var _cnh = tree_node_height(_cnode);
            var _cy1 = _common_row_y;
            var _cy2 = _cy1 + _cnh;

            if (_cnh > _common_row_h) _common_row_h = _cnh;

            if (
                (_cy1 >= _panel_y1 && _cy2 <= _panel_y2)
                || (_cnh >= _panel_h)
            ) {
                var _chover = point_in_rectangle(_mx, _my, _cx1, _cy1, _cx2, _cy2);

                tree_draw_node(_cnode, _cx1, _cy1, _cx2, _cy2, _chover);

                if (_chover && _tap) _click_node = _cnode;
            }
        }

        _y = _common_row_y + _common_row_h + _section_gap;

        // ── 2. Ветки столбиками ──
        // Каждая ветка целиком ложится в один столбец; при 4 столбцах и
        // четырёх ветках получается ровно по одной на столбец.
        var _col_y = array_create(_branch_cols, _y);

        for (var _s = 1; _s < array_length(_sections); _s++) {
            var _section = _sections[_s];

            // Столбец с наименьшей текущей высотой.
            var _target_col = 0;

            for (var _c = 1; _c < _branch_cols; _c++) {
                if (_col_y[_c] < _col_y[_target_col]) _target_col = _c;
            }

            var _bx1 = _panel_x1 + _target_col * (_branch_w + _col_gap);
            var _bx2 = _bx1 + _branch_w;
            var _by = _col_y[_target_col];

            // Заголовок ветки — шапка столбца.
            if (_by >= _panel_y1 && _by + _header_h <= _panel_y2) {
                draw_set_color(tree_color_wood_dark());
                draw_roundrect_ext(_bx1, _by, _bx2, _by + _header_h, 12, 12, false);
                draw_set_color(tree_color_wood_light());
                draw_roundrect_ext(_bx1 + 2, _by + 2, _bx2 - 2, _by + _header_h - 2, 10, 10, true);

                var _bh_scale = tree_fit_scale(_section.title, _branch_w - 30, TREE_FS_HEADER);

                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(255, 233, 194));
                draw_text_transformed(
                    (_bx1 + _bx2) * 0.5,
                    _by + _header_h * 0.5,
                    _section.title,
                    _bh_scale,
                    _bh_scale,
                    0
                );
                draw_set_halign(fa_left);
                draw_set_valign(fa_top);
            }

            _by += _header_h + 14;

            // Узлы ветки — друг под другом, соединённые стволом.
            var _bnodes = _section.nodes;

            for (var _bn = 0; _bn < array_length(_bnodes); _bn++) {
                var _bnode = _bnodes[_bn];
                var _bnh = tree_node_height(_bnode);
                var _by1 = _by;
                var _by2 = _by1 + _bnh;

                if (
                    _bn > 0
                    && (_by1 - _node_gap) >= _panel_y1
                    && _by1 <= _panel_y2
                ) {
                    tree_draw_stem((_bx1 + _bx2) * 0.5, _by1 - _node_gap, _by1, true);
                }

                if (
                    (_by1 >= _panel_y1 && _by2 <= _panel_y2)
                    || (_bnh >= _panel_h)
                ) {
                    var _bhover = point_in_rectangle(_mx, _my, _bx1, _by1, _bx2, _by2);

                    tree_draw_node(_bnode, _bx1, _by1, _bx2, _by2, _bhover);

                    if (_bhover && _tap) _click_node = _bnode;
                }

                _by = _by2 + _node_gap;
            }

            _col_y[_target_col] = _by + _section_gap;
        }

        // Самый длинный столбец задаёт высоту содержимого.
        var _lowest = _y;

        for (var _c2 = 0; _c2 < _branch_cols; _c2++) {
            if (_col_y[_c2] > _lowest) _lowest = _col_y[_c2];
        }

        _y = _lowest;

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

        // ── Нажатие на узел ──
        if (!is_undefined(_click_node) && tablet_click_lock <= 0) {
            var _state = tree_node_state(_click_node);

            if (_state == "open") {
                // Пакет №202: сразу не покупаем — спрашиваем подтверждение,
                // как при увольнении сотрудника.
                tablet_click_lock = 6;
                tree_confirm_node = _click_node;
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

        // ═══════════════════════════════════════════════════════
        // Пакет №202: ОКНО ПОДТВЕРЖДЕНИЯ ПОКУПКИ
        // ═══════════════════════════════════════════════════════

        if (!is_undefined(tree_confirm_node)) {
            var _node_c = tree_confirm_node;
            var _state_c = tree_node_state(_node_c);

            // Узел уже куплен другим способом или подорожал — закрываем.
            if (_state_c != "open") {
                tree_confirm_node = undefined;
            }
            else {
                var _gui_w = display_get_gui_width();
                var _gui_h = display_get_gui_height();
                var _cw = 700;
                var _ch = 300;
                var _cx1 = (_gui_w - _cw) * 0.5;
                var _cy1 = (_gui_h - _ch) * 0.5;
                var _cx2 = _cx1 + _cw;
                var _cy2 = _cy1 + _ch;

                draw_set_alpha(0.40);
                draw_set_color(c_black);
                draw_rectangle(0, 0, _gui_w, _gui_h, false);
                draw_set_alpha(1);

                draw_set_color(tree_color_paper());
                draw_roundrect_ext(_cx1, _cy1, _cx2, _cy2, 14, 14, false);
                draw_set_color(tree_color_wood_dark());
                draw_roundrect_ext(_cx1, _cy1, _cx2, _cy2, 14, 14, true);
                draw_set_color(tree_color_wood_light());
                draw_roundrect_ext(_cx1 + 3, _cy1 + 3, _cx2 - 3, _cy2 - 3, 12, 12, true);

                draw_set_halign(fa_center);
                draw_set_valign(fa_top);
                draw_set_color(tree_color_text());
                ui_text_fit_center(
                    (_cx1 + _cx2) * 0.5,
                    _cy1 + 48,
                    "КУПИТЬ УЛУЧШЕНИЕ?",
                    _cw - 60,
                    UI_FS_TITLE
                );

                draw_set_color(tree_color_text_soft());
                ui_text_fit_center(
                    (_cx1 + _cx2) * 0.5,
                    _cy1 + 104,
                    tree_node_title(_node_c),
                    _cw - 60,
                    UI_FS_HEADER
                );

                draw_set_color(tree_color_green());
                ui_text_fit_center(
                    (_cx1 + _cx2) * 0.5,
                    _cy1 + 152,
                    tree_node_cost_text(_node_c, _state_c),
                    _cw - 60,
                    UI_FS_VALUE
                );

                var _byes_x1 = _cx1 + 30;
                var _byes_x2 = (_cx1 + _cx2) * 0.5 - 8;
                var _bno_x1 = (_cx1 + _cx2) * 0.5 + 8;
                var _bno_x2 = _cx2 - 30;
                var _by1 = _cy2 - 96;
                var _by2 = _cy2 - 28;

                var _yes_hover = point_in_rectangle(_mx, _my, _byes_x1, _by1, _byes_x2, _by2);
                var _no_hover = point_in_rectangle(_mx, _my, _bno_x1, _by1, _bno_x2, _by2);

                hud_draw_button(
                    _byes_x1,
                    _by1,
                    _byes_x2,
                    _by2,
                    "КУПИТЬ",
                    false,
                    _yes_hover,
                    tree_color_green_bg(),
                    make_color_rgb(232, 245, 228),
                    make_color_rgb(205, 226, 200),
                    tree_color_line(),
                    tree_color_green_dark()
                );

                hud_draw_button(
                    _bno_x1,
                    _by1,
                    _bno_x2,
                    _by2,
                    "ОТМЕНА",
                    false,
                    _no_hover,
                    tree_color_paper_2(),
                    make_color_rgb(248, 238, 220),
                    make_color_rgb(228, 210, 186),
                    tree_color_line(),
                    tree_color_text()
                );

                if (_released && tablet_click_lock <= 0) {
                    if (_yes_hover) {
                        tablet_click_lock = 6;
                        tree_node_buy(_node_c);
                        tree_confirm_node = undefined;
                    }
                    else if (_no_hover) {
                        tablet_click_lock = 6;
                        tree_confirm_node = undefined;
                    }
                }
            }
        }

        draw_set_color(c_white);
        draw_set_alpha(1);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
}
