/// Draw GUI End obj_UI_HUD
/// @description Модульные панели, чистота и итоги дня в правильном порядке слоёв.

if (!variable_instance_exists(id, "staff_manage_draw_requested")) {
    staff_manage_draw_requested = false;
}

if (!variable_instance_exists(id, "finance_manage_draw_requested")) {
    finance_manage_draw_requested = false;
}

if (staff_manage_draw_requested) {
    hud_draw_staff_management_panel(id);
}

if (finance_manage_draw_requested) {
    hud_draw_finance_price_panel(id);
}

hud_draw_cleanliness_topbar(id);

if (instance_exists(obj_cleanliness_controller)) {
    cleanliness_draw_clean_menu(
        instance_find(obj_cleanliness_controller, 0)
    );
}

// Итоги дня перекрывают все остальные панели.
hud_draw_day_summary(id);
