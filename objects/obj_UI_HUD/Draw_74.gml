/// Draw GUI Begin obj_UI_HUD
/// @description Отделяет новые модульные панели от старого Draw GUI.

if (!variable_instance_exists(id, "staff_manage_panel_open")) {
    staff_manage_panel_open = false;
}

if (!variable_instance_exists(id, "finance_manage_panel_open")) {
    finance_manage_panel_open = false;
}

var _staff_button_impulse = staff_panel_open;
var _finance_button_impulse = finance_panel_open;

// Клиника, клиенты, найм и справочник закрывают обе большие модульные панели.
var _handbook_is_open = variable_instance_exists(id, "handbook_open")
    && handbook_open;

if (
    clinic_panel_open
    || clients_panel_open
    || hiring_panel_open
    || _handbook_is_open
) {
    staff_manage_panel_open = false;
    finance_manage_panel_open = false;
}

// Кнопка «ПЕРСОНАЛ» переключает только новую staff-панель.
if (_staff_button_impulse) {
    staff_manage_panel_open = !staff_manage_panel_open;
    finance_manage_panel_open = false;
}

// Кнопка «ФИНАНСЫ» переключает только новый прайс-лист.
if (_finance_button_impulse) {
    finance_manage_panel_open = !finance_manage_panel_open;
    staff_manage_panel_open = false;
}

// Старые блоки большого Draw GUI больше не выполняются.
staff_panel_open = false;
finance_panel_open = false;

staff_manage_draw_requested = staff_manage_panel_open;
finance_manage_draw_requested = finance_manage_panel_open;
