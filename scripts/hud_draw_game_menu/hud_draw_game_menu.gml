/// hud_draw_game_menu.gml
/// @description Пакет №271: кнопка-шестерёнка и окна меню игры.
///
/// Шрифты берутся из UI-кита (hud_ui_scale, пакет 174), а не задаются
/// числами: игра телефонная, и правило проекта — крупный текст,
/// который сам ужимается, если не влезает.
///   UI_FS_TITLE  1.75  заголовок окна
///   UI_FS_BUTTON 1.60  текст на кнопке
///   UI_FS_ROW    1.25  строка списка


// ═══════════════════════════════════════════════════════════════
// 1. ШЕСТЕРЁНКА
//
// Спрайта шестерёнки в проекте нет, поэтому рисуем вектором:
// восемь зубцов по кругу + отверстие. Выглядит одинаково на любом
// разрешении и не требует нового ассета.
// ═══════════════════════════════════════════════════════════════

function hud_draw_gear_icon(_cx, _cy, _radius, _color) {
    draw_set_color(_color);
    draw_set_alpha(1);

    var _teeth = 8;
    var _inner = _radius * 0.62;
    var _tooth_w = 360 / _teeth * 0.42;

    // Зубцы — короткие толстые лучи.
    for (var _t = 0; _t < _teeth; _t++) {
        var _ang = _t * (360 / _teeth);

        draw_primitive_begin(pr_trianglestrip);

        var _a1 = _ang - _tooth_w;
        var _a2 = _ang + _tooth_w;

        draw_vertex(_cx + lengthdir_x(_inner, _a1), _cy + lengthdir_y(_inner, _a1));
        draw_vertex(_cx + lengthdir_x(_radius, _a1), _cy + lengthdir_y(_radius, _a1));
        draw_vertex(_cx + lengthdir_x(_inner, _a2), _cy + lengthdir_y(_inner, _a2));
        draw_vertex(_cx + lengthdir_x(_radius, _a2), _cy + lengthdir_y(_radius, _a2));

        draw_primitive_end();
    }

    // Тело шестерёнки.
    draw_circle(_cx, _cy, _inner, false);

    // Отверстие в центре — вырезаем фоном панели.
    draw_set_color(make_color_rgb(52, 40, 28));
    draw_circle(_cx, _cy, _radius * 0.26, false);

    draw_set_color(c_white);
}


/// Кнопка-шестерёнка в верхней панели.
function hud_draw_gear_button(_hud) {
    with (_hud) {
        var _active = (game_menu_mode != "");

        var _fill = _active
            ? make_color_rgb(198, 168, 108)
            : (hover_gear
                ? make_color_rgb(248, 238, 220)
                : make_color_rgb(242, 232, 214));

        // Тень.
        draw_set_alpha(0.25);
        draw_set_color(c_black);
        draw_roundrect_ext(gear_x1 + 1, gear_y1 + 2, gear_x2 + 1, gear_y2 + 2, 8, 8, false);
        draw_set_alpha(1);

        draw_set_color(_fill);
        draw_roundrect_ext(gear_x1, gear_y1, gear_x2, gear_y2, 8, 8, false);

        draw_set_color(make_color_rgb(58, 39, 24));
        draw_roundrect_ext(gear_x1, gear_y1, gear_x2, gear_y2, 8, 8, true);

        var _cx = (gear_x1 + gear_x2) * 0.5;
        var _cy = (gear_y1 + gear_y2) * 0.5;
        var _r = min(gear_x2 - gear_x1, gear_y2 - gear_y1) * 0.34;

        hud_draw_gear_icon(_cx, _cy, _r, make_color_rgb(58, 39, 24));

        draw_set_color(c_white);
        draw_set_alpha(1);
    }
}


// ═══════════════════════════════════════════════════════════════
// 2. ОБЩИЕ ЭЛЕМЕНТЫ ОКОН
// ═══════════════════════════════════════════════════════════════

/// Затемнение позади модального окна.
function hud_menu_draw_shade() {
    draw_set_alpha(0.55);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}


/// Рамка окна в бумажном стиле проекта.
function hud_menu_draw_frame(_x1, _y1, _x2, _y2, _title) {
    draw_set_alpha(0.3);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 4, _y1 + 6, _x2 + 4, _y2 + 6, 14, 14, false);
    draw_set_alpha(1);

    draw_set_color(make_color_rgb(242, 232, 214));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, false);

    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 14, 14, true);
    draw_roundrect_ext(_x1 + 2, _y1 + 2, _x2 - 2, _y2 - 2, 12, 12, true);

    // Заголовок крупно.
    draw_set_color(make_color_rgb(50, 38, 28));
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        _y1 + 46,
        _title,
        (_x2 - _x1) - 48,
        UI_FS_TITLE
    );

    // Линия под заголовком.
    draw_set_color(make_color_rgb(120, 96, 68));
    draw_line(_x1 + 24, _y1 + 78, _x2 - 24, _y1 + 78);

    draw_set_color(c_white);
}


/// Крупная кнопка меню. Текст сам ужимается под ширину.
///
/// _font_scale — базовый масштаб. По умолчанию UI_FS_BUTTON (1.60),
/// но кнопки ДА/ОТМЕНА в подтверждении просят крупнее: текст там
/// короткий, места навалом, и это последний рубеж перед необратимым
/// действием — надо читаться с одного взгляда.
function hud_menu_draw_button(_x1, _y1, _x2, _y2, _text, _hover, _enabled, _font_scale = UI_FS_BUTTON) {
    var _fill = make_color_rgb(232, 220, 198);
    var _ink = make_color_rgb(50, 38, 28);

    if (!_enabled) {
        _fill = make_color_rgb(214, 206, 192);
        _ink = make_color_rgb(140, 130, 116);
    }
    else if (_hover) {
        _fill = make_color_rgb(250, 240, 220);
    }

    draw_set_alpha(0.22);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 2, _y1 + 3, _x2 + 2, _y2 + 3, 10, 10, false);
    draw_set_alpha(1);

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);

    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    draw_set_color(_ink);
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5,
        _text,
        (_x2 - _x1) - 30,
        _font_scale
    );

    draw_set_color(c_white);
}


// ═══════════════════════════════════════════════════════════════
// 3. ГЛАВНОЕ ОКНО МЕНЮ
// ═══════════════════════════════════════════════════════════════

function hud_draw_game_menu(_hud) {
    with (_hud) {
        if (game_menu_mode == "") exit;

        hud_menu_draw_shade();

        // ── Главное меню ──
        if (game_menu_mode == "main") {
            hud_menu_draw_frame(
                game_menu_x1, game_menu_y1, game_menu_x2, game_menu_y2,
                "МЕНЮ ИГРЫ"
            );

            hud_menu_draw_button(
                menu_save_x1, menu_save_y1, menu_save_x2, menu_save_y2,
                "СОХРАНИТЬ", hover_menu_save, true
            );

            // ЗАГРУЗИТЬ гаснет, если сохранений нет вообще.
            var _has_saves = false;

            if (script_exists(asset_get_index("save_slot_any_exists"))) {
                _has_saves = save_slot_any_exists();
            }

            hud_menu_draw_button(
                menu_load_x1, menu_load_y1, menu_load_x2, menu_load_y2,
                _has_saves ? "ЗАГРУЗИТЬ" : "ЗАГРУЗИТЬ (нет сохранений)",
                hover_menu_load, _has_saves
            );

            hud_menu_draw_button(
                menu_new_x1, menu_new_y1, menu_new_x2, menu_new_y2,
                "НОВАЯ ИГРА", hover_menu_new, true
            );

            hud_menu_draw_button(
                menu_close_x1, menu_close_y1, menu_close_x2, menu_close_y2,
                "ЗАКРЫТЬ", hover_menu_close, true
            );
        }

        // ── Список слотов ──
        else if (game_menu_mode == "save" || game_menu_mode == "load") {
            hud_menu_draw_frame(
                game_menu_x1, game_menu_y1, game_menu_x2, game_menu_y2,
                (game_menu_mode == "save") ? "СОХРАНИТЬ ИГРУ" : "ЗАГРУЗИТЬ ИГРУ"
            );

            for (var _i = 0; _i < array_length(menu_slot_rects); _i++) {
                var _rect = menu_slot_rects[_i];
                var _entry = menu_slot_entries[_rect.entry_index];

                // Автослот в режиме сохранения выбрать нельзя.
                var _selectable = (game_menu_mode == "save")
                    ? !_entry.is_auto
                    : _entry.exists;

                var _hover = (hover_menu_slot == _i) && _selectable;

                var _fill = make_color_rgb(232, 220, 198);

                if (!_selectable) {
                    _fill = make_color_rgb(216, 208, 194);
                }
                else if (_hover) {
                    _fill = make_color_rgb(250, 240, 220);
                }

                draw_set_color(_fill);
                draw_roundrect_ext(_rect.x1, _rect.y1, _rect.x2, _rect.y2, 8, 8, false);

                draw_set_color(make_color_rgb(58, 39, 24));
                draw_roundrect_ext(_rect.x1, _rect.y1, _rect.x2, _rect.y2, 8, 8, true);

                // Автосейвы помечаем полоской слева, чтобы их было
                // видно с одного взгляда.
                if (_entry.is_auto) {
                    draw_set_color(make_color_rgb(150, 130, 90));
                    draw_rectangle(_rect.x1 + 3, _rect.y1 + 3, _rect.x1 + 9, _rect.y2 - 3, false);
                }

                var _ink = _selectable
                    ? make_color_rgb(50, 38, 28)
                    : make_color_rgb(140, 130, 116);

                draw_set_color(_ink);

                // Первая строка — крупно: номер, день, деньги.
                ui_text_fit_left(
                    _rect.x1 + 20,
                    _rect.y1 + 10,
                    _entry.label,
                    (_rect.x2 - _rect.x1) - 40,
                    UI_FS_BUTTON
                );

                // Вторая строка — мелко: штат и реальное время.
                if (_entry.exists) {
                    var _sub = "Сотрудников: " + string(_entry.staff);

                    if (_entry.real_text != "") {
                        _sub += "    " + _entry.real_text;
                    }

                    draw_set_color(make_color_rgb(96, 80, 62));
                    ui_text_fit_left(
                        _rect.x1 + 20,
                        _rect.y1 + 40,
                        _sub,
                        (_rect.x2 - _rect.x1) - 40,
                        UI_FS_ROW
                    );
                }

                draw_set_color(c_white);
            }

            hud_menu_draw_button(
                menu_close_x1, menu_close_y1, menu_close_x2, menu_close_y2,
                "НАЗАД", hover_menu_close, true
            );
        }

        // ── Окно подтверждения поверх всего ──
        if (menu_confirm_open) {
            hud_menu_draw_shade();

            hud_menu_draw_frame(
                menu_confirm_x1, menu_confirm_y1,
                menu_confirm_x2, menu_confirm_y2,
                "ПОДТВЕРЖДЕНИЕ"
            );

            // ── Текст подтверждения ──
            //
            // Раньше он рисовался масштабом UI_FS_ROW (1.25) — это
            // размер строки списка, для главного вопроса окна мелко.
            // Теперь стартуем от UI_FS_TITLE (1.75) и снижаем масштаб
            // только если текст реально не влезает в отведённую высоту.
            //
            // Высоту меряем через string_height_ext с тем же переносом,
            // что и при отрисовке, иначе длинный вопрос про
            // перезапись наехал бы на кнопки.
            draw_set_color(make_color_rgb(50, 38, 28));
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);

            var _text_w = (menu_confirm_x2 - menu_confirm_x1) - 56;

            // Полоса под текст: от линии заголовка до кнопок.
            var _text_top = menu_confirm_y1 + 88;
            var _text_bottom = menu_confirm_yes_y1 - 18;
            var _text_h = _text_bottom - _text_top;

            // ВАЖНО: sep и w у draw_text_ext_transformed задаются в
            // ЕДИНИЦАХ ДО масштабирования — поэтому их делят на
            // масштаб, а не умножают (так же сделано в справочнике
            // болезней: "30 / UI_FS_ROW, _detail_w / UI_FS_ROW").
            // Умножение давало бы разъезжающиеся строки.
            var _scale = UI_FS_TITLE;
            var _line_sep = round(34 / _scale);
            var _wrap = round(_text_w / _scale);

            // Ужимаем, пока не влезет по высоте. Шаг мелкий, чтобы не
            // проскочить мимо подходящего размера.
            while (
                _scale > UI_FS_ROW
                && string_height_ext(menu_confirm_text, _line_sep, _wrap) * _scale > _text_h
            ) {
                _scale -= 0.05;
                _line_sep = round(34 / _scale);
                _wrap = round(_text_w / _scale);
            }

            draw_text_ext_transformed(
                (menu_confirm_x1 + menu_confirm_x2) * 0.5,
                (_text_top + _text_bottom) * 0.5,
                menu_confirm_text,
                _line_sep,
                _wrap,
                _scale, _scale, 0
            );

            draw_set_halign(fa_left);
            draw_set_valign(fa_top);

            // ДА / ОТМЕНА крупнее обычных кнопок меню: слова
            // короткие, кнопки широкие — место есть, а промахнуться
            // тут нельзя.
            hud_menu_draw_button(
                menu_confirm_yes_x1, menu_confirm_yes_y1,
                menu_confirm_yes_x2, menu_confirm_yes_y2,
                "ДА", hover_menu_yes, true, UI_FS_TITLE
            );

            hud_menu_draw_button(
                menu_confirm_no_x1, menu_confirm_no_y1,
                menu_confirm_no_x2, menu_confirm_no_y2,
                "ОТМЕНА", hover_menu_no, true, UI_FS_TITLE
            );
        }

        draw_set_color(c_white);
        draw_set_alpha(1);
    }
}
