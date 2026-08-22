/// Create obj_UI_HUD
/// @description Очищенная инициализация HUD без старой карточки кандидата.

visible = true;
tablet_click_lock = 0;


// ═══════════════════════════════════════════════════════════════
// 1. ОСНОВНЫЕ РАЗМЕРЫ
// ═══════════════════════════════════════════════════════════════

hud_margin = 14;
hud_top_h = 106;   // пакет №152: панель ниже (было 116)

btn_w = 44;
btn_h = 26;   // пакет №156: кнопки времени ниже (было 34), по центру с воздухом сверху/снизу
btn_gap = 8;

// Пакет №199: нижняя полоса выше, кнопки меню занимают её целиком.
// Точная ширина и высота кнопок считаются в Begin Step от ширины панели.
bottombar_h = 88;
bottom_btn_w = 180;   // осталось для совместимости, больше не используется
bottom_btn_h = 44;    // осталось для совместимости, больше не используется
bottom_btn_gap = 14;

staff_panel_w = 840;
staff_panel_h = 470;
info_panel_w = 700;
info_panel_h = 360;


// ═══════════════════════════════════════════════════════════════
// 2. ВЕРХНЯЯ И НИЖНЯЯ ПАНЕЛИ
// ═══════════════════════════════════════════════════════════════

topbar_x1 = 0;
topbar_y1 = 0;
topbar_x2 = 0;
topbar_y2 = 0;

bottombar_x1 = 0;
bottombar_y1 = 0;
bottombar_x2 = 0;
bottombar_y2 = 0;

clinic_x1 = 0;
clinic_y1 = 0;
clinic_x2 = 0;
clinic_y2 = 0;

clients_x1 = 0;
clients_y1 = 0;
clients_x2 = 0;
clients_y2 = 0;

staff_x1 = 0;
staff_y1 = 0;
staff_x2 = 0;
staff_y2 = 0;

finance_x1 = 0;
finance_y1 = 0;
finance_x2 = 0;
finance_y2 = 0;


// ═══════════════════════════════════════════════════════════════
// 3. ОСНОВНЫЕ ПАНЕЛИ
// ═══════════════════════════════════════════════════════════════

main_panel_x1 = 0;
main_panel_y1 = 0;
main_panel_x2 = 0;
main_panel_y2 = 0;

staff_panel_open = false;
clinic_panel_open = false;
finance_panel_open = false;
clients_panel_open = false;

// Совместимость со старым Begin Step/Draw GUI.
// Новая obj_UI_CandidateCard никогда не включает этот флаг.
hiring_panel_open = false;


// ═══════════════════════════════════════════════════════════════
// 4. КЛИНИКА И СКЛАД
// ═══════════════════════════════════════════════════════════════

clinic_subtab = "clinic";

clinic_tab_clinic_x1 = 0;
clinic_tab_clinic_y1 = 0;
clinic_tab_clinic_x2 = 0;
clinic_tab_clinic_y2 = 0;

clinic_tab_storage_x1 = 0;
clinic_tab_storage_y1 = 0;
clinic_tab_storage_x2 = 0;
clinic_tab_storage_y2 = 0;

hover_clinic_tab_clinic = false;
hover_clinic_tab_storage = false;

storage_scope_entries = [];
storage_scope_selected = "main";
storage_scope_selected_inst = noone;
storage_scope_row_hover = -1;

storage_open_pending_target = noone;
storage_open_pending_kind = "";
storage_radial_was_open = false;

stock_buy_buttons = [];
stock_buy_hover_index = -1;


// ═══════════════════════════════════════════════════════════════
// 5. ПЕРСОНАЛ И УВОЛЬНЕНИЕ
// ═══════════════════════════════════════════════════════════════

staff_panel_x1 = 0;
staff_panel_y1 = 0;
staff_panel_x2 = 0;
staff_panel_y2 = 0;

selected_staff_id = noone;
staff_entries = [];
staff_row_hover = -1;
staff_scroll = 0;

staff_card_x1 = 0;
staff_card_y1 = 0;
staff_card_x2 = 0;
staff_card_y2 = 0;

staff_focus_x1 = 0;
staff_focus_y1 = 0;
staff_focus_x2 = 0;
staff_focus_y2 = 0;

staff_fire_x1 = 0;
staff_fire_y1 = 0;
staff_fire_x2 = 0;
staff_fire_y2 = 0;

hover_staff_card = false;
hover_staff_focus = false;
hover_staff_fire = false;

fire_confirm_open = false;
fire_confirm_target = noone;

fire_confirm_x1 = 0;
fire_confirm_y1 = 0;
fire_confirm_x2 = 0;
fire_confirm_y2 = 0;

fire_yes_x1 = 0;
fire_yes_y1 = 0;
fire_yes_x2 = 0;
fire_yes_y2 = 0;

fire_no_x1 = 0;
fire_no_y1 = 0;
fire_no_x2 = 0;
fire_no_y2 = 0;

hover_fire_yes = false;
hover_fire_no = false;


// ═══════════════════════════════════════════════════════════════
// 6. КЛИЕНТЫ
// ═══════════════════════════════════════════════════════════════

clients_panel_x1 = 0;
clients_panel_y1 = 0;
clients_panel_x2 = 0;
clients_panel_y2 = 0;

client_entries = [];
selected_client_owner_id = "";
selected_client_pet_id = "";
client_row_hover = -1;
client_scroll = 0;

client_search_text = "";
client_search_active = false;
client_search_caret_timer = 0;
client_search_caret_visible = true;

client_search_x1 = 0;
client_search_y1 = 0;
client_search_x2 = 0;
client_search_y2 = 0;

client_clear_x1 = 0;
client_clear_y1 = 0;
client_clear_x2 = 0;
client_clear_y2 = 0;

hover_client_search = false;
hover_client_clear = false;

clients_subtab = "all";

clients_tab_all_x1 = 0;
clients_tab_all_y1 = 0;
clients_tab_all_x2 = 0;
clients_tab_all_y2 = 0;

clients_tab_followup_x1 = 0;
clients_tab_followup_y1 = 0;
clients_tab_followup_x2 = 0;
clients_tab_followup_y2 = 0;

hover_clients_tab_all = false;
hover_clients_tab_followup = false;

followup_entries = [];
selected_followup_id = "";
followup_row_hover = -1;
followup_scroll = 0;

client_visit_entries = [];
selected_client_visit_id = "";
client_visit_row_hover = -1;
client_visit_scroll = 0;

client_history_x1 = 0;
client_history_y1 = 0;
client_history_x2 = 0;
client_history_y2 = 0;

client_history_box_h = 170;
client_proc_preview_limit = 6;
client_plan_preview_limit = 6;


// ═══════════════════════════════════════════════════════════════
// 7. ВРЕМЯ И HOVER
// ═══════════════════════════════════════════════════════════════

pause_x1 = 0;
pause_y1 = 0;
pause_x2 = 0;
pause_y2 = 0;

speed1_x1 = 0;
speed1_y1 = 0;
speed1_x2 = 0;
speed1_y2 = 0;

speed2_x1 = 0;
speed2_y1 = 0;
speed2_x2 = 0;
speed2_y2 = 0;

speed4_x1 = 0;
speed4_y1 = 0;
speed4_x2 = 0;
speed4_y2 = 0;

hover_pause = false;
hover_1x = false;
hover_2x = false;
hover_4x = false;

hover_clinic = false;
hover_clients = false;
hover_staff = false;
hover_finance = false;

selected_sidebar_tab = "clinic";


// ═══════════════════════════════════════════════════════════════
// 8. УВЕДОМЛЕНИЯ (стопка, пакет №101)
// ═══════════════════════════════════════════════════════════════

notice_stack = [];
notice_max = 3;             // сколько уведомлений видно одновременно
notice_gap = 8;             // зазор между уведомлениями в стопке
notice_fall_speed = 16;     // скорость падения, px/кадр (меньше = медленнее)
notice_fade_frames = 15;    // кадров на затухание
notice_lifetime_multiplier = 2;  // во сколько раз дольше сообщение висит внизу

// Старые одиночные переменные оставлены для совместимости (не используются).
notice_title = "";
notice_text = "";
notice_timer = 0;
notice_timer_max = 0;

show_notice = function(_title, _text, _time_frames) {
    if (!is_array(notice_stack)) notice_stack = [];

    array_push(notice_stack, {
        title     : string(_title),
        text      : string(_text),
        timer     : _time_frames * notice_lifetime_multiplier,
        timer_max : _time_frames * notice_lifetime_multiplier,
        state     : "falling",   // falling → idle → fading
        y         : -320,        // появляется над экраном и падает вниз
        target_y  : 0,
        alpha     : 1,
        w         : 0,           // ширина/высота считаются при отрисовке
        h         : 0,
        x1        : 0,
        y1        : 0,
        x2        : 0,
        y2        : 0,
        measure   : undefined
    });

    // Больше notice_max живых — самые старые уходят в затухание.
    var _live = 0;
    var _total = array_length(notice_stack);
    for (var _i = 0; _i < _total; _i++) {
        if (notice_stack[_i].state != "fading") _live += 1;
    }

    var _overflow = _live - notice_max;
    for (var _i = 0; _i < _total && _overflow > 0; _i++) {
        if (notice_stack[_i].state != "fading") {
            notice_stack[_i].state = "fading";
            _overflow -= 1;
        }
    }
};


// ═══════════════════════════════════════════════════════════════
// 9. СПРАВОЧНИК БОЛЕЗНЕЙ (пакет №69)
// ═══════════════════════════════════════════════════════════════

handbook_open = false;

handbook_x1 = 0;
handbook_y1 = 0;
handbook_x2 = 0;
handbook_y2 = 0;

handbook_panel_x1 = 0;
handbook_panel_y1 = 0;
handbook_panel_x2 = 0;
handbook_panel_y2 = 0;

handbook_close_x1 = 0;
handbook_close_y1 = 0;
handbook_close_x2 = 0;
handbook_close_y2 = 0;

hover_handbook = false;
hover_handbook_close = false;

handbook_row_hover = -1;
handbook_scroll = 0;
selected_handbook_disease = "";
