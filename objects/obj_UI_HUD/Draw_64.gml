/// Draw GUI obj_UI_HUD
/// @description Короткий диспетчер модульного HUD без старых staff/finance/hiring блоков.
/// Пакет №127: временный счётчик FPS в правом верхнем углу.
/// Пакет №145: счётчик упрощён — только FPS и REAL, крупно.

if (!visible) exit;

if (font_exists(fnt_main)) {
    draw_set_font(fnt_main);
}

if (!variable_instance_exists(id, "tablet_click_lock")) {
    tablet_click_lock = 0;
}

tablet_click_lock = max(0, tablet_click_lock - 1);

// Основные постоянные панели.
hud_draw_main_bars(id);

// Большие панели, которые ещё относятся к основному HUD.
hud_draw_clinic_storage(id);
hud_draw_clients_database(id);

// Справочник болезней (пакет №69).
hud_draw_handbook_panel(id);

// Элементы поверх мира и основных панелей.
hud_draw_notifications(id);
hud_draw_hover_tooltip(id);
hud_draw_storage_radial_menu(id);

// Итоги дня рисуются в Draw GUI End поверх staff/finance/чистоты.

// ═══════════════════════════════════════════════════════════════
// DEBUG: СЧЁТЧИК FPS (пакет №127, временный)
// Показывает fps, fps_real и среднее за 30 кадров.
// Чтобы выключить — поставь hud_debug_fps_show = false.
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "hud_debug_fps_show")) hud_debug_fps_show = true;

if (hud_debug_fps_show) {
    // Пакет №145: только FPS и REAL, крупно. Убраны TGT/AVG30/OWNERS/VISITS/INST/REDRAW.

    var _dbg_x = display_get_gui_width() - 10;
    var _dbg_y = topbar_y2 + 8;

    var _fps_col = (fps >= 55)
        ? make_color_rgb(70, 200, 90)
        : (fps >= 30
            ? make_color_rgb(210, 170, 50)
            : make_color_rgb(210, 70, 60));

    draw_set_halign(fa_right);
    draw_set_valign(fa_top);

    // Подложка, чтобы цифры читались на любом фоне.
    var _dbg_w = 200;
    var _dbg_h = 46;
    var _dbg_x1 = _dbg_x - _dbg_w;
    draw_set_alpha(0.55);
    draw_set_color(c_black);
    draw_roundrect_ext(_dbg_x1, _dbg_y, _dbg_x, _dbg_y + _dbg_h, 8, 8, false);
    draw_set_alpha(1);

    draw_set_color(_fps_col);
    draw_text_transformed(
        _dbg_x - 8,
        _dbg_y + 6,
        "FPS " + string(fps) + "   REAL " + string(fps_real),
        1.4,
        1.4,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// Единый обязательный сброс состояния рисования.
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);
gpu_set_blendmode(bm_normal);
