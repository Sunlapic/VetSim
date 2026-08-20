/// Begin Step obj_UI_HUD
/// Пакет №136: списки (персонал/клиенты/склады) собираются только
/// при открытой панели — убрана пустая покадровая работа.

if (!visible) exit;

// ─────────────────────────────────────────────
// ПАКЕТ №69 (hotfix): СТРАХОВКА СПРАВОЧНИКА
// Гарантирует, что переменные справочника существуют до первого чтения.
// Это убирает ошибку «Variable handbook_open not set before reading»,
// даже если Create ещё не заменён или файлы установлены в другом порядке.
// ─────────────────────────────────────────────
if (!variable_instance_exists(id, "handbook_open")) handbook_open = false;
if (!variable_instance_exists(id, "handbook_close_x1")) handbook_close_x1 = 0;
if (!variable_instance_exists(id, "handbook_close_y1")) handbook_close_y1 = 0;
if (!variable_instance_exists(id, "handbook_close_x2")) handbook_close_x2 = 0;
if (!variable_instance_exists(id, "handbook_close_y2")) handbook_close_y2 = 0;
if (!variable_instance_exists(id, "handbook_panel_x1")) handbook_panel_x1 = 0;
if (!variable_instance_exists(id, "handbook_panel_y1")) handbook_panel_y1 = 0;
if (!variable_instance_exists(id, "handbook_panel_x2")) handbook_panel_x2 = 0;
if (!variable_instance_exists(id, "handbook_panel_y2")) handbook_panel_y2 = 0;
if (!variable_instance_exists(id, "handbook_x1")) handbook_x1 = 0;
if (!variable_instance_exists(id, "handbook_y1")) handbook_y1 = 0;
if (!variable_instance_exists(id, "handbook_x2")) handbook_x2 = 0;
if (!variable_instance_exists(id, "handbook_y2")) handbook_y2 = 0;
if (!variable_instance_exists(id, "hover_handbook")) hover_handbook = false;
if (!variable_instance_exists(id, "hover_handbook_close")) hover_handbook_close = false;
if (!variable_instance_exists(id, "handbook_row_hover")) handbook_row_hover = -1;
if (!variable_instance_exists(id, "handbook_scroll")) handbook_scroll = 0;
if (!variable_instance_exists(id, "selected_handbook_disease")) selected_handbook_disease = "";

var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

// ─────────────────────────────────────────────
// ГАРАНТИЯ СУЩЕСТВОВАНИЯ ГЛОБАЛЬНЫХ БАЗ
// ─────────────────────────────────────────────
if (!variable_global_exists("owner_db")) global.owner_db = {};
if (!variable_global_exists("pet_db")) global.pet_db = {};
if (!variable_global_exists("visit_db")) global.visit_db = {};

if (!variable_global_exists("owner_list")) global.owner_list = [];
if (!variable_global_exists("pet_list")) global.pet_list = [];
if (!variable_global_exists("visit_list")) global.visit_list = [];
if (!variable_global_exists("scheduled_visits")) global.scheduled_visits = [];

if (!variable_global_exists("item_db")) global.item_db = {};
if (!variable_global_exists("item_ids")) global.item_ids = [];
if (!variable_global_exists("inventory_main")) global.inventory_main = {};
if (!variable_global_exists("storage_buy_batch")) global.storage_buy_batch = 5;

// ─────────────────────────────────────────────
// ЧИСТИМ ССЫЛКИ
// ─────────────────────────────────────────────
if (!instance_exists(global.current_candidate)) {
    global.current_candidate = noone;
}

if (!instance_exists(global.selected_candidate)) {
    global.selected_candidate = noone;
}

if (!instance_exists(selected_staff_id)) {
    selected_staff_id = noone;
}

if (!instance_exists(fire_confirm_target)) {
    fire_confirm_target = noone;
    fire_confirm_open = false;
}

if (global.selected_candidate == noone && instance_exists(global.current_candidate)) {
    if (global.current_candidate.candidate_state == "waiting_offer") {
        global.selected_candidate = global.current_candidate;
    }
}

if (hiring_panel_open && !instance_exists(global.selected_candidate) && !instance_exists(global.current_candidate)) {
    hiring_panel_open = false;
}

// ─────────────────────────────────────────────
if (staff_panel_open) {

// СОБИРАЕМ СПИСОК ПЕРСОНАЛА
// ─────────────────────────────────────────────
staff_entries = [];

if (instance_exists(obj_player)) {
    array_push(staff_entries, instance_find(obj_player, 0));
}

with (obj_staff_admin) {
    array_push(other.staff_entries, id);
}

with (obj_staff_doctor) {
    array_push(other.staff_entries, id);
}

with (obj_staff_assistant) {
    array_push(other.staff_entries, id);
}

if (array_length(staff_entries) > 0) {
    if (!instance_exists(selected_staff_id)) {
        selected_staff_id = staff_entries[0];
    }
} else {
    selected_staff_id = noone;
}

// Пакет №136: конец блока «список персонала только при staff_panel_open»
}


// Пакет №136: списки клиентов и складов собираем только когда открыта
// соответствующая панель (иначе — пустая работа каждый кадр).
if (clients_panel_open || clinic_panel_open) {

// СОБИРАЕМ СПИСОК КЛИЕНТОВ ИЗ БАЗЫ
// ─────────────────────────────────────────────
client_entries = [];
followup_entries = [];
client_visit_entries = [];

// ─────────────────────────────────────────────
// СОБИРАЕМ СПИСОК СКЛАДОВ
// ─────────────────────────────────────────────
storage_scope_entries = [];

var _main_inst = noone;
with (obj_storage_main) { _main_inst = id; break; }
array_push(storage_scope_entries, {
    scope_id   : "main",
    label_ru   : "Основной склад",
    cabinet_id : _main_inst
});

// Собираем только шкафы с корректным slot_id
var _cab_list = [];
with (obj_storage_cabinet) {
    if (variable_instance_exists(id, "exam_slot_id") && exam_slot_id > 0) {
        array_push(_cab_list, { inst: id, slot: exam_slot_id });
    }
}
// Сортировка по slot (1, 2, 3)
for (var _a = 0; _a < array_length(_cab_list); _a++) {
    for (var _b = _a + 1; _b < array_length(_cab_list); _b++) {
        if (_cab_list[_b].slot < _cab_list[_a].slot) {
            var _tmp = _cab_list[_a];
            _cab_list[_a] = _cab_list[_b];
            _cab_list[_b] = _tmp;
        }
    }
}
// Проверка дублей слотов — чтобы при расстановке двух шкафов на один слот
// игра в лог писала предупреждение и ты видел ошибку
var _used_slots = [];
for (var _k = 0; _k < array_length(_cab_list); _k++) {
    var _cinst = _cab_list[_k].inst;
    var _cslot = _cab_list[_k].slot;
    var _clbl  = "Шкаф кабинета " + string(_cslot);
    if (instance_exists(_cinst) && variable_instance_exists(_cinst, "storage_name_ru") && _cinst.storage_name_ru != "") {
        _clbl = _cinst.storage_name_ru;
    }
    if (array_contains(_used_slots, _cslot) && global.debug_mode) {
        show_debug_message("[CABINET WARNING] Два шкафа имеют одинаковый exam_slot_id = " + string(_cslot) + "! Проверь расстановку в Room Editor.");
        _clbl = "[ДУБЛЬ] " + _clbl;
    }
    array_push(_used_slots, _cslot);
    array_push(storage_scope_entries, {
        scope_id   : "cab_" + string(_cinst),
        label_ru   : _clbl,
        cabinet_id : _cinst
    });
}

// Проверяем выбранный склад
var _storage_selected_ok = false;

for (var _ss = 0; _ss < array_length(storage_scope_entries); _ss++) {
    if (storage_scope_entries[_ss].scope_id == storage_scope_selected) {
        _storage_selected_ok = true;
        break;
    }
}

if (!_storage_selected_ok) {
    storage_scope_selected = "main";
}

var _query = string_lower(client_search_text);

// ВСЕ КЛИЕНТЫ
for (var _owner_i = 0; _owner_i < array_length(global.owner_list); _owner_i++) {
    var _owner_id = global.owner_list[_owner_i];
    if (!variable_struct_exists(global.owner_db, _owner_id)) continue;

    var _owner_ref = variable_struct_get(global.owner_db, _owner_id);
    var _owner_name = variable_struct_exists(_owner_ref, "full_name") ? string(_owner_ref.full_name) : "Клиент";

    var _pet_ids = [];
    if (variable_struct_exists(_owner_ref, "pet_ids")) {
        _pet_ids = _owner_ref.pet_ids;
    }

    if (array_length(_pet_ids) > 0) {
        for (var _pet_i = 0; _pet_i < array_length(_pet_ids); _pet_i++) {
            var _pet_id = _pet_ids[_pet_i];
            if (!variable_struct_exists(global.pet_db, _pet_id)) continue;

            var _pet_ref = variable_struct_get(global.pet_db, _pet_id);
            var _pet_name = variable_struct_exists(_pet_ref, "name") ? string(_pet_ref.name) : "";
            var _pet_breed = variable_struct_exists(_pet_ref, "breed") ? string(_pet_ref.breed) : "";

            var _hay = string_lower(_owner_name + " " + _pet_name + " " + _pet_breed);

            if (_query == "" || string_pos(_query, _hay) > 0) {
                array_push(client_entries, {
                    owner_id : _owner_id,
                    pet_id : _pet_id
                });
            }
        }
    } else {
        var _hay2 = string_lower(_owner_name);

        if (_query == "" || string_pos(_query, _hay2) > 0) {
            array_push(client_entries, {
                owner_id : _owner_id,
                pet_id : ""
            });
        }
    }
}

// ПОВТОРНЫЕ ПРИЁМЫ
for (var _sv_i = 0; _sv_i < array_length(global.scheduled_visits); _sv_i++) {
    var _sv = global.scheduled_visits[_sv_i];

    if (_sv.status != "pending" && _sv.status != "spawned") continue;
    if (!variable_struct_exists(global.owner_db, _sv.owner_id)) continue;
    if (!variable_struct_exists(global.pet_db, _sv.pet_id)) continue;

    var _owner_ref2 = variable_struct_get(global.owner_db, _sv.owner_id);
    var _pet_ref2 = variable_struct_get(global.pet_db, _sv.pet_id);

    var _owner_name2 = variable_struct_exists(_owner_ref2, "full_name") ? string(_owner_ref2.full_name) : "Клиент";
    var _pet_name2 = variable_struct_exists(_pet_ref2, "name") ? string(_pet_ref2.name) : "";
    var _pet_breed2 = variable_struct_exists(_pet_ref2, "breed") ? string(_pet_ref2.breed) : "";
    var _visit_type2 = variable_struct_exists(_sv, "visit_type_name_ru") ? string(_sv.visit_type_name_ru) : "Повторный приём";
    var _reason2 = variable_struct_exists(_sv, "reason") ? string(_sv.reason) : "";

    var _hay3 = string_lower(_owner_name2 + " " + _pet_name2 + " " + _pet_breed2 + " " + _visit_type2 + " " + _reason2);

    if (_query == "" || string_pos(_query, _hay3) > 0) {
        array_push(followup_entries, {
            scheduled_visit_id : _sv.scheduled_visit_id,
            owner_id : _sv.owner_id,
            pet_id : _sv.pet_id
        });
    }
}

// ─────────────────────────────────────────────
// ПРОВЕРКА ВЫБРАННОГО КЛИЕНТА
// ─────────────────────────────────────────────
var _client_selected_ok = false;

for (var _ci = 0; _ci < array_length(client_entries); _ci++) {
    if (client_entries[_ci].owner_id == selected_client_owner_id
    && client_entries[_ci].pet_id == selected_client_pet_id) {
        _client_selected_ok = true;
        break;
    }
}

if (!_client_selected_ok) {
    if (array_length(client_entries) > 0) {
        selected_client_owner_id = client_entries[0].owner_id;
        selected_client_pet_id = client_entries[0].pet_id;
    } else {
        selected_client_owner_id = "";
        selected_client_pet_id = "";
    }

    selected_client_visit_id = "";
    client_visit_scroll = 0;
}

// ─────────────────────────────────────────────
// ПРОВЕРКА ВЫБРАННОГО FOLLOW-UP
// ─────────────────────────────────────────────
var _followup_selected_ok = false;

for (var _fi = 0; _fi < array_length(followup_entries); _fi++) {
    if (followup_entries[_fi].scheduled_visit_id == selected_followup_id) {
        _followup_selected_ok = true;
        break;
    }
}

if (!_followup_selected_ok) {
    if (array_length(followup_entries) > 0) {
        selected_followup_id = followup_entries[0].scheduled_visit_id;
    } else {
        selected_followup_id = "";
    }
}

// ─────────────────────────────────────────────
// СОБИРАЕМ ИСТОРИЮ ВИЗИТОВ ДЛЯ ВЫБРАННОГО КЛИЕНТА
// ─────────────────────────────────────────────
if (selected_client_owner_id != "") {
    if (selected_client_pet_id != "" && variable_struct_exists(global.pet_db, selected_client_pet_id)) {
        var _pet_data = variable_struct_get(global.pet_db, selected_client_pet_id);

        if (variable_struct_exists(_pet_data, "visit_history")) {
            for (var _vh = 0; _vh < array_length(_pet_data.visit_history); _vh++) {
                var _visit_id = _pet_data.visit_history[_vh];

                if (variable_struct_exists(global.visit_db, _visit_id)) {
                    array_push(client_visit_entries, {
                        visit_id : _visit_id
                    });
                }
            }
        }
    } else {
        for (var _vi = 0; _vi < array_length(global.visit_list); _vi++) {
            var _visit_id2 = global.visit_list[_vi];
            if (!variable_struct_exists(global.visit_db, _visit_id2)) continue;

            var _visit_ref = variable_struct_get(global.visit_db, _visit_id2);

            if (_visit_ref.owner_id == selected_client_owner_id) {
                array_push(client_visit_entries, {
                    visit_id : _visit_id2
                });
            }
        }
    }
}

// Сортировка истории по убыванию времени
for (var _a = 0; _a < array_length(client_visit_entries) - 1; _a++) {
    for (var _b = _a + 1; _b < array_length(client_visit_entries); _b++) {
        var _va = variable_struct_get(global.visit_db, client_visit_entries[_a].visit_id);
        var _vb = variable_struct_get(global.visit_db, client_visit_entries[_b].visit_id);

        var _key_a = _va.visit_day * 1440 + _va.visit_hour * 60 + _va.visit_minute;
        var _key_b = _vb.visit_day * 1440 + _vb.visit_hour * 60 + _vb.visit_minute;

        if (_key_b > _key_a) {
            var _tmp = client_visit_entries[_a];
            client_visit_entries[_a] = client_visit_entries[_b];
            client_visit_entries[_b] = _tmp;
        }
    }
}

// Проверка выбранного визита
var _visit_selected_ok = false;

for (var _cv = 0; _cv < array_length(client_visit_entries); _cv++) {
    if (client_visit_entries[_cv].visit_id == selected_client_visit_id) {
        _visit_selected_ok = true;
        break;
    }
}

if (!_visit_selected_ok) {
    if (array_length(client_visit_entries) > 0) {
        selected_client_visit_id = client_visit_entries[0].visit_id;
    } else {
        selected_client_visit_id = "";
    }

    client_visit_scroll = 0;
}

// Пакет №136: конец блока «списки только при открытой панели»
}

// ─────────────────────────────────────────────
// ВЕРХНЯЯ ПАНЕЛЬ
// ─────────────────────────────────────────────
topbar_x1 = hud_margin;
topbar_y1 = hud_margin;
topbar_x2 = _gw - hud_margin;
topbar_y2 = hud_margin + hud_top_h;

// ─────────────────────────────────────────────
// НИЖНЯЯ ПАНЕЛЬ
// ─────────────────────────────────────────────
bottombar_x1 = hud_margin;
bottombar_y1 = _gh - hud_margin - bottombar_h;
bottombar_x2 = _gw - hud_margin;
bottombar_y2 = _gh - hud_margin;

// Главная рабочая зона
main_panel_x1 = 24;
main_panel_y1 = topbar_y2 + 12;
main_panel_x2 = _gw - 24;
main_panel_y2 = bottombar_y1 - 12;

// ─────────────────────────────────────────────
// ПАНЕЛИ
// ─────────────────────────────────────────────
staff_panel_x1 = main_panel_x1;
staff_panel_y1 = main_panel_y1;
staff_panel_x2 = main_panel_x2;
staff_panel_y2 = main_panel_y2;

candidate_x1 = main_panel_x1 + 40;
candidate_y1 = main_panel_y1 + 10;
candidate_x2 = main_panel_x2 - 40;
candidate_y2 = main_panel_y2 - 10;

clients_panel_x1 = main_panel_x1;
clients_panel_y1 = main_panel_y1;
clients_panel_x2 = main_panel_x2;
clients_panel_y2 = main_panel_y2;

// Панель справочника (пакет №69)
handbook_panel_x1 = main_panel_x1;
handbook_panel_y1 = main_panel_y1;
handbook_panel_x2 = main_panel_x2;
handbook_panel_y2 = main_panel_y2;

handbook_close_x2 = handbook_panel_x2 - 20;
handbook_close_x1 = handbook_close_x2 - 28;
handbook_close_y1 = handbook_panel_y1 + 16;
handbook_close_y2 = handbook_close_y1 + 28;

// Подвкладки клиники
clinic_tab_clinic_x1 = main_panel_x1 + 26;
clinic_tab_clinic_y1 = main_panel_y1 + 20;
clinic_tab_clinic_x2 = clinic_tab_clinic_x1 + 110;
clinic_tab_clinic_y2 = clinic_tab_clinic_y1 + 30;

clinic_tab_storage_x1 = clinic_tab_clinic_x2 + 10;
clinic_tab_storage_y1 = clinic_tab_clinic_y1;
clinic_tab_storage_x2 = clinic_tab_storage_x1 + 110;
clinic_tab_storage_y2 = clinic_tab_storage_y1 + 30;

// Подвкладки клиентов
clients_tab_all_x1 = clients_panel_x1 + 26;
clients_tab_all_y1 = clients_panel_y1 + 20;
clients_tab_all_x2 = clients_tab_all_x1 + 110;
clients_tab_all_y2 = clients_tab_all_y1 + 30;

clients_tab_followup_x1 = clients_tab_all_x2 + 10;
clients_tab_followup_y1 = clients_tab_all_y1;
clients_tab_followup_x2 = clients_tab_followup_x1 + 190;
clients_tab_followup_y2 = clients_tab_followup_y1 + 30;

// Поле поиска
client_search_x1 = clients_panel_x1 + 26;
client_search_y1 = clients_tab_all_y2 + 10;
client_search_x2 = client_search_x1 + 360;
client_search_y2 = client_search_y1 + 34;

client_clear_x2 = client_search_x2 - 6;
client_clear_x1 = client_clear_x2 - 24;
client_clear_y1 = client_search_y1 + 5;
client_clear_y2 = client_clear_y1 + 24;

// ─────────────────────────────────────────────
// КНОПКИ НИЖНЕЙ ПАНЕЛИ
// ─────────────────────────────────────────────
var _menu_total_w = bottom_btn_w * 5 + bottom_btn_gap * 4;
var _menu_x = bottombar_x1 + ((bottombar_x2 - bottombar_x1) - _menu_total_w) * 0.5;
var _menu_y = bottombar_y1 + ((bottombar_y2 - bottombar_y1) - bottom_btn_h) * 0.5;

clinic_x1 = _menu_x;
clinic_y1 = _menu_y;
clinic_x2 = clinic_x1 + bottom_btn_w;
clinic_y2 = clinic_y1 + bottom_btn_h;

clients_x1 = clinic_x2 + bottom_btn_gap;
clients_y1 = _menu_y;
clients_x2 = clients_x1 + bottom_btn_w;
clients_y2 = clients_y1 + bottom_btn_h;

staff_x1 = clients_x2 + bottom_btn_gap;
staff_y1 = _menu_y;
staff_x2 = staff_x1 + bottom_btn_w;
staff_y2 = staff_y1 + bottom_btn_h;

finance_x1 = staff_x2 + bottom_btn_gap;
finance_y1 = _menu_y;
finance_x2 = finance_x1 + bottom_btn_w;
finance_y2 = finance_y1 + bottom_btn_h;

handbook_x1 = finance_x2 + bottom_btn_gap;
handbook_y1 = _menu_y;
handbook_x2 = handbook_x1 + bottom_btn_w;
handbook_y2 = handbook_y1 + bottom_btn_h;

// ─────────────────────────────────────────────
// ВЕРХНИЕ КНОПКИ ВРЕМЕНИ
// ─────────────────────────────────────────────
var _group_right = topbar_x2 - 18;
// Пакет №146: кнопки по центру более высокой панели.
var _group_y = topbar_y1 + round((topbar_y2 - topbar_y1 - btn_h) * 0.5);

speed4_x1 = _group_right - btn_w;
speed4_y1 = _group_y;
speed4_x2 = speed4_x1 + btn_w;
speed4_y2 = speed4_y1 + btn_h;

speed2_x1 = speed4_x1 - btn_gap - btn_w;
speed2_y1 = _group_y;
speed2_x2 = speed2_x1 + btn_w;
speed2_y2 = speed2_y1 + btn_h;

speed1_x1 = speed2_x1 - btn_gap - btn_w;
speed1_y1 = _group_y;
speed1_x2 = speed1_x1 + btn_w;
speed1_y2 = speed1_y1 + btn_h;

pause_x1 = speed1_x1 - btn_gap - btn_w;
pause_y1 = _group_y;
pause_x2 = pause_x1 + btn_w;
pause_y2 = pause_y1 + btn_h;

// ─────────────────────────────────────────────
// КРЕСТИК ПАНЕЛИ НАЙМА
// ─────────────────────────────────────────────
hiring_close_x2 = candidate_x2 - 18;
hiring_close_x1 = hiring_close_x2 - 24;
hiring_close_y1 = candidate_y1 + 16;
hiring_close_y2 = hiring_close_y1 + 24;

// ─────────────────────────────────────────────
// КНОПКИ ПЕРСОНАЛА
// ─────────────────────────────────────────────
staff_fire_x2 = staff_panel_x2 - 18;
staff_fire_x1 = staff_fire_x2 - 118;
staff_fire_y1 = staff_panel_y1 + 18;
staff_fire_y2 = staff_fire_y1 + 30;

staff_focus_x2 = staff_fire_x1 - 10;
staff_focus_x1 = staff_focus_x2 - 118;
staff_focus_y1 = staff_panel_y1 + 18;
staff_focus_y2 = staff_focus_y1 + 30;

staff_card_x2 = staff_focus_x1 - 10;
staff_card_x1 = staff_card_x2 - 118;
staff_card_y1 = staff_panel_y1 + 18;
staff_card_y2 = staff_card_y1 + 30;

// ─────────────────────────────────────────────
// КНОПКИ НАЙМА
// ─────────────────────────────────────────────
hire_x2 = candidate_x2 - 18;
hire_x1 = hire_x2 - 118;
hire_y1 = candidate_y1 + 18;
hire_y2 = hire_y1 + 30;

reject_x2 = hire_x1 - 10;
reject_x1 = reject_x2 - 118;
reject_y1 = candidate_y1 + 18;
reject_y2 = reject_y1 + 30;

// ─────────────────────────────────────────────
// КООРДИНАТЫ ИСТОРИИ ВИЗИТОВ
// ─────────────────────────────────────────────
client_history_x1 = 0;
client_history_y1 = 0;
client_history_x2 = 0;
client_history_y2 = 0;

if (clients_panel_open && clients_subtab == "all") {
    var _list_x1_hist = clients_panel_x1 + 28;
    var _list_x2_hist = _list_x1_hist + 380;
    var _detail_x1_hist = _list_x2_hist + 20;
    var _detail_y1_hist = clients_panel_y1 + 122;
    var _detail_x2_hist = clients_panel_x2 - 28;
    var _detail_y2_hist = clients_panel_y2 - 32;

    client_history_x1 = _detail_x1_hist + 10;
    client_history_y1 = _detail_y2_hist - client_history_box_h;
    client_history_x2 = _detail_x2_hist - 10;
    client_history_y2 = _detail_y2_hist - 10;
}

// ─────────────────────────────────────────────
// HOVER
// ─────────────────────────────────────────────
hover_pause = point_in_rectangle(_mx, _my, pause_x1, pause_y1, pause_x2, pause_y2);
hover_1x    = point_in_rectangle(_mx, _my, speed1_x1, speed1_y1, speed1_x2, speed1_y2);
hover_2x    = point_in_rectangle(_mx, _my, speed2_x1, speed2_y1, speed2_x2, speed2_y2);
hover_4x    = point_in_rectangle(_mx, _my, speed4_x1, speed4_y1, speed4_x2, speed4_y2);

hover_clinic  = point_in_rectangle(_mx, _my, clinic_x1, clinic_y1, clinic_x2, clinic_y2);
hover_clients = point_in_rectangle(_mx, _my, clients_x1, clients_y1, clients_x2, clients_y2);
hover_staff   = point_in_rectangle(_mx, _my, staff_x1, staff_y1, staff_x2, staff_y2);
hover_finance = point_in_rectangle(_mx, _my, finance_x1, finance_y1, finance_x2, finance_y2);
hover_handbook = point_in_rectangle(_mx, _my, handbook_x1, handbook_y1, handbook_x2, handbook_y2);

hover_handbook_close = handbook_open && point_in_rectangle(_mx, _my, handbook_close_x1, handbook_close_y1, handbook_close_x2, handbook_close_y2);

hover_clinic_tab_clinic = clinic_panel_open && point_in_rectangle(_mx, _my, clinic_tab_clinic_x1, clinic_tab_clinic_y1, clinic_tab_clinic_x2, clinic_tab_clinic_y2);
hover_clinic_tab_storage = clinic_panel_open && point_in_rectangle(_mx, _my, clinic_tab_storage_x1, clinic_tab_storage_y1, clinic_tab_storage_x2, clinic_tab_storage_y2);

hover_hiring_close = hiring_panel_open && point_in_rectangle(_mx, _my, hiring_close_x1, hiring_close_y1, hiring_close_x2, hiring_close_y2);
hover_client_clear = clients_panel_open && point_in_rectangle(_mx, _my, client_clear_x1, client_clear_y1, client_clear_x2, client_clear_y2);
hover_client_search = clients_panel_open && point_in_rectangle(_mx, _my, client_search_x1, client_search_y1, client_clear_x1 - 4, client_search_y2);

hover_clients_tab_all = clients_panel_open && point_in_rectangle(_mx, _my, clients_tab_all_x1, clients_tab_all_y1, clients_tab_all_x2, clients_tab_all_y2);
hover_clients_tab_followup = clients_panel_open && point_in_rectangle(_mx, _my, clients_tab_followup_x1, clients_tab_followup_y1, clients_tab_followup_x2, clients_tab_followup_y2);

hover_staff_card = false;
hover_staff_focus = false;
hover_staff_fire = false;

if (staff_panel_open && instance_exists(selected_staff_id)) {
    hover_staff_card  = point_in_rectangle(_mx, _my, staff_card_x1, staff_card_y1, staff_card_x2, staff_card_y2);
    hover_staff_focus = point_in_rectangle(_mx, _my, staff_focus_x1, staff_focus_y1, staff_focus_x2, staff_focus_y2);
    hover_staff_fire  = point_in_rectangle(_mx, _my, staff_fire_x1, staff_fire_y1, staff_fire_x2, staff_fire_y2);
}

hover_hire = false;
hover_reject = false;

if (hiring_panel_open && instance_exists(global.selected_candidate)) {
    hover_hire = point_in_rectangle(_mx, _my, hire_x1, hire_y1, hire_x2, hire_y2);
    hover_reject = point_in_rectangle(_mx, _my, reject_x1, reject_y1, reject_x2, reject_y2);
}

// ─────────────────────────────────────────────
// ПРОКРУТКА И ВЫБОР СТРОК ПЕРСОНАЛА
// ─────────────────────────────────────────────
staff_row_hover = -1;

if (staff_panel_open) {
    var _list_x1 = staff_panel_x1 + 32;
    var _list_y1 = staff_panel_y1 + 70;
    var _list_x2 = _list_x1 + 340;
    var _list_y2 = staff_panel_y2 - 32;

    var _row_h = 58;
    var _row_top = _list_y1 + 28;
    var _visible_rows = max(1, floor((_list_y2 - _row_top) / _row_h));
    var _max_scroll = max(0, array_length(staff_entries) - _visible_rows);

    staff_scroll = clamp(staff_scroll, 0, _max_scroll);

    if (point_in_rectangle(_mx, _my, _list_x1, _list_y1, _list_x2, _list_y2)) {
        if (mouse_wheel_down()) staff_scroll = min(_max_scroll, staff_scroll + 1);
        if (mouse_wheel_up())   staff_scroll = max(0, staff_scroll - 1);
    }

    for (var _j = 0; _j < _visible_rows; _j++) {
        var _idx = staff_scroll + _j;
        if (_idx >= array_length(staff_entries)) break;

        var _ry1 = _row_top + _j * _row_h;
        var _ry2 = _ry1 + (_row_h - 6);
        var _rx1 = _list_x1 + 8;
        var _rx2 = _list_x2 - 8;

        if (point_in_rectangle(_mx, _my, _rx1, _ry1, _rx2, _ry2)) {
            staff_row_hover = _idx;

            if (mouse_check_button_pressed(mb_left)) {
                selected_staff_id = staff_entries[_idx];
            }
        }
    }
}

// ─────────────────────────────────────────────
// ПРОКРУТКА И ВЫБОР СТРОК КЛИЕНТОВ
// ─────────────────────────────────────────────
client_row_hover = -1;
followup_row_hover = -1;
client_visit_row_hover = -1;

if (clients_panel_open) {
    var _cl_list_x1 = clients_panel_x1 + 28;
    var _cl_list_y1 = clients_panel_y1 + 122;
    var _cl_list_x2 = _cl_list_x1 + 380;
    var _cl_list_y2 = clients_panel_y2 - 32;
    var _cl_row_h = 68;
    var _cl_row_top = _cl_list_y1 + 30;

    if (clients_subtab == "all") {
        var _cl_visible_rows = max(1, floor((_cl_list_y2 - _cl_row_top) / _cl_row_h));
        var _cl_max_scroll = max(0, array_length(client_entries) - _cl_visible_rows);

        client_scroll = clamp(client_scroll, 0, _cl_max_scroll);

        if (point_in_rectangle(_mx, _my, _cl_list_x1, _cl_list_y1, _cl_list_x2, _cl_list_y2)) {
            if (mouse_wheel_down()) client_scroll = min(_cl_max_scroll, client_scroll + 1);
            if (mouse_wheel_up())   client_scroll = max(0, client_scroll - 1);
        }

        for (var _cj = 0; _cj < _cl_visible_rows; _cj++) {
            var _cidx = client_scroll + _cj;
            if (_cidx >= array_length(client_entries)) break;

            var _cry1 = _cl_row_top + _cj * _cl_row_h;
            var _cry2 = _cry1 + (_cl_row_h - 6);
            var _crx1 = _cl_list_x1 + 8;
            var _crx2 = _cl_list_x2 - 8;

            if (point_in_rectangle(_mx, _my, _crx1, _cry1, _crx2, _cry2)) {
                client_row_hover = _cidx;

                if (mouse_check_button_pressed(mb_left)) {
                    selected_client_owner_id = client_entries[_cidx].owner_id;
                    selected_client_pet_id = client_entries[_cidx].pet_id;
                    selected_client_visit_id = "";
                    client_visit_scroll = 0;
                }
            }
        }

        // История визитов выбранного клиента
        if (client_history_x2 > client_history_x1 && client_history_y2 > client_history_y1) {
            var _hist_row_h = 54;
            var _hist_row_top = client_history_y1 + 28;
            var _hist_visible_rows = max(1, floor((client_history_y2 - _hist_row_top - 8) / _hist_row_h));
            var _hist_max_scroll = max(0, array_length(client_visit_entries) - _hist_visible_rows);

            client_visit_scroll = clamp(client_visit_scroll, 0, _hist_max_scroll);

            if (point_in_rectangle(_mx, _my, client_history_x1, client_history_y1, client_history_x2, client_history_y2)) {
                if (mouse_wheel_down()) client_visit_scroll = min(_hist_max_scroll, client_visit_scroll + 1);
                if (mouse_wheel_up())   client_visit_scroll = max(0, client_visit_scroll - 1);
            }

            for (var _hj = 0; _hj < _hist_visible_rows; _hj++) {
                var _hidx = client_visit_scroll + _hj;
                if (_hidx >= array_length(client_visit_entries)) break;

                var _hry1 = _hist_row_top + _hj * _hist_row_h;
                var _hry2 = _hry1 + (_hist_row_h - 6);
                var _hrx1 = client_history_x1 + 8;
                var _hrx2 = client_history_x2 - 8;

                if (point_in_rectangle(_mx, _my, _hrx1, _hry1, _hrx2, _hry2)) {
                    client_visit_row_hover = _hidx;

                    if (mouse_check_button_pressed(mb_left)) {
                        selected_client_visit_id = client_visit_entries[_hidx].visit_id;
                    }
                }
            }
        }
    } else {
        var _fu_visible_rows = max(1, floor((_cl_list_y2 - _cl_row_top) / _cl_row_h));
        var _fu_max_scroll = max(0, array_length(followup_entries) - _fu_visible_rows);

        followup_scroll = clamp(followup_scroll, 0, _fu_max_scroll);

        if (point_in_rectangle(_mx, _my, _cl_list_x1, _cl_list_y1, _cl_list_x2, _cl_list_y2)) {
            if (mouse_wheel_down()) followup_scroll = min(_fu_max_scroll, followup_scroll + 1);
            if (mouse_wheel_up())   followup_scroll = max(0, followup_scroll - 1);
        }

        for (var _fj = 0; _fj < _fu_visible_rows; _fj++) {
            var _fidx = followup_scroll + _fj;
            if (_fidx >= array_length(followup_entries)) break;

            var _fry1 = _cl_row_top + _fj * _cl_row_h;
            var _fry2 = _fry1 + (_cl_row_h - 6);
            var _frx1 = _cl_list_x1 + 8;
            var _frx2 = _cl_list_x2 - 8;

            if (point_in_rectangle(_mx, _my, _frx1, _fry1, _frx2, _fry2)) {
                followup_row_hover = _fidx;

                if (mouse_check_button_pressed(mb_left)) {
                    selected_followup_id = followup_entries[_fidx].scheduled_visit_id;
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// ПРОКРУТКА И ВЫБОР БОЛЕЗНИ В СПРАВОЧНИКЕ (пакет №69)
// ─────────────────────────────────────────────
handbook_row_hover = -1;

if (
    handbook_open
    && variable_global_exists("med_db")
    && is_struct(global.med_db)
    && variable_struct_exists(global.med_db, "disease_ids")
) {
    handbook_init();

    var _hb_list_x1 = handbook_panel_x1 + 20;
    var _hb_list_y1 = handbook_panel_y1 + 62;
    var _hb_list_x2 = _hb_list_x1 + 360;
    var _hb_list_y2 = handbook_panel_y2 - 20;

    var _hb_row_h = 46;
    var _hb_visible_rows = max(1, floor((_hb_list_y2 - _hb_list_y1) / _hb_row_h));
    var _hb_max_scroll = max(0, array_length(global.med_db.disease_ids) - _hb_visible_rows);

    handbook_scroll = clamp(handbook_scroll, 0, _hb_max_scroll);

    if (point_in_rectangle(_mx, _my, _hb_list_x1, _hb_list_y1, _hb_list_x2, _hb_list_y2)) {
        if (mouse_wheel_down()) handbook_scroll = min(_hb_max_scroll, handbook_scroll + 1);
        if (mouse_wheel_up())   handbook_scroll = max(0, handbook_scroll - 1);
    }

    for (var _hj = 0; _hj < _hb_visible_rows; _hj++) {
        var _hidx = handbook_scroll + _hj;
        if (_hidx >= array_length(global.med_db.disease_ids)) break;

        var _hry1 = _hb_list_y1 + _hj * _hb_row_h;
        var _hry2 = _hry1 + (_hb_row_h - 4);

        if (point_in_rectangle(_mx, _my, _hb_list_x1, _hry1, _hb_list_x2, _hry2)) {
            handbook_row_hover = _hidx;

            if (mouse_check_button_pressed(mb_left)) {
                selected_handbook_disease = global.med_db.disease_ids[_hidx];
            }
        }
    }
}

// ─────────────────────────────────────────────
// ДИАЛОГ ПОДТВЕРЖДЕНИЯ УВОЛЬНЕНИЯ
// ─────────────────────────────────────────────
hover_fire_yes = false;
hover_fire_no = false;

if (fire_confirm_open && instance_exists(fire_confirm_target)) {
    fire_confirm_x1 = staff_panel_x1 + 210;
    fire_confirm_x2 = staff_panel_x2 - 210;
    fire_confirm_y1 = staff_panel_y1 + 140;
    fire_confirm_y2 = fire_confirm_y1 + 120;

    fire_yes_x1 = fire_confirm_x1 + 22;
    fire_yes_x2 = fire_yes_x1 + 110;
    fire_yes_y1 = fire_confirm_y2 - 42;
    fire_yes_y2 = fire_yes_y1 + 24;

    fire_no_x2 = fire_confirm_x2 - 22;
    fire_no_x1 = fire_no_x2 - 110;
    fire_no_y1 = fire_yes_y1;
    fire_no_y2 = fire_yes_y2;

    hover_fire_yes = point_in_rectangle(_mx, _my, fire_yes_x1, fire_yes_y1, fire_yes_x2, fire_yes_y2);
    hover_fire_no  = point_in_rectangle(_mx, _my, fire_no_x1, fire_no_y1, fire_no_x2, fire_no_y2);
} else {
    fire_confirm_open = false;
    fire_confirm_target = noone;
}

// ─────────────────────────────────────────────
// УВЕДОМЛЕНИЯ-СТОПКА: ХОВЕР (пакет №101)
// ─────────────────────────────────────────────
var _notice_hover = false;

if (
    variable_instance_exists(id, "notice_stack")
    && is_array(notice_stack)
) {
    var _ncount = array_length(notice_stack);
    for (var _ni = _ncount - 1; _ni >= 0; _ni--) {
        var _nt = notice_stack[_ni];
        if (_nt.state == "fading") continue;
        if (
            _nt.x2 > _nt.x1
            && point_in_rectangle(
                _mx, _my,
                _nt.x1, _nt.y1,
                _nt.x2, _nt.y2
            )
        ) {
            _notice_hover = true;
            break;
        }
    }
}

// ─────────────────────────────────────────────
// БЛОКИРОВКА КЛИКОВ ПО МИРУ
// ─────────────────────────────────────────────
global.ui_block_world_click =
    point_in_rectangle(_mx, _my, topbar_x1, topbar_y1, topbar_x2, topbar_y2)
    || point_in_rectangle(_mx, _my, bottombar_x1, bottombar_y1, bottombar_x2, bottombar_y2)
    || (staff_panel_open && point_in_rectangle(_mx, _my, staff_panel_x1, staff_panel_y1, staff_panel_x2, staff_panel_y2))
    || (clients_panel_open && point_in_rectangle(_mx, _my, clients_panel_x1, clients_panel_y1, clients_panel_x2, clients_panel_y2))
    || (clinic_panel_open && point_in_rectangle(_mx, _my, main_panel_x1, main_panel_y1, main_panel_x2, main_panel_y2))
    || (finance_panel_open && point_in_rectangle(_mx, _my, main_panel_x1, main_panel_y1, main_panel_x2, main_panel_y2))
    || (hiring_panel_open && point_in_rectangle(_mx, _my, candidate_x1, candidate_y1, candidate_x2, candidate_y2))
    || (handbook_open && point_in_rectangle(_mx, _my, handbook_panel_x1, handbook_panel_y1, handbook_panel_x2, handbook_panel_y2))
    || (fire_confirm_open && point_in_rectangle(_mx, _my, fire_confirm_x1, fire_confirm_y1, fire_confirm_x2, fire_confirm_y2))
    || _notice_hover;

// ─────────────────────────────────────────────
// КЛИКИ
// ─────────────────────────────────────────────
if (mouse_check_button_pressed(mb_left)) {
    // Клик по уведомлению — закрыть его и больше ничего не делать (пакет №101).
    if (_notice_hover) {
        if (is_array(notice_stack)) {
            var _nc2 = array_length(notice_stack);
            for (var _ni2 = _nc2 - 1; _ni2 >= 0; _ni2--) {
                var _nt2 = notice_stack[_ni2];
                if (_nt2.state == "fading") continue;
                if (
                    point_in_rectangle(
                        _mx, _my,
                        _nt2.x1, _nt2.y1,
                        _nt2.x2, _nt2.y2
                    )
                ) {
                    _nt2.state = "fading";
                    _nt2.timer = 0;
                    break;
                }
            }
        }
    }
    // Если открыт диалог увольнения — обрабатываем только его
    else if (fire_confirm_open && instance_exists(fire_confirm_target)) {
        if (hover_fire_yes) {
            if (instance_exists(fire_confirm_target)) {
                if (fire_confirm_target.object_index != obj_player) {
                    with (fire_confirm_target) {
                        instance_destroy();
                    }
                }
            }

            if (selected_staff_id == fire_confirm_target) {
                selected_staff_id = noone;
            }

            fire_confirm_target = noone;
            fire_confirm_open = false;
        }
        else if (hover_fire_no) {
            fire_confirm_target = noone;
            fire_confirm_open = false;
        }
    }
    else {
        // Верхняя панель
        if (hover_pause) {
            global.time_paused = !global.time_paused;
        }
        else if (hover_1x) {
            global.time_paused = false;
            global.time_speed = 1;
        }
        else if (hover_2x) {
            global.time_paused = false;
            global.time_speed = 2;
        }
        else if (hover_4x) {
            global.time_paused = false;
            global.time_speed = 4;
        }

        // Нижнее меню
        else if (hover_clinic) {
            if (selected_sidebar_tab == "clinic" && clinic_panel_open) {
                clinic_panel_open = false;
            } else {
                selected_sidebar_tab = "clinic";
                clinic_panel_open = true;
            }

            clients_panel_open = false;
            staff_panel_open = false;
            finance_panel_open = false;
            hiring_panel_open = false;
            handbook_open = false;
            client_search_active = false;
        }
        else if (hover_clients) {
            if (selected_sidebar_tab == "clients" && clients_panel_open) {
                clients_panel_open = false;
            } else {
                selected_sidebar_tab = "clients";
                clients_panel_open = true;
            }

            clinic_panel_open = false;
            staff_panel_open = false;
            finance_panel_open = false;
            hiring_panel_open = false;
            handbook_open = false;
        }
        else if (hover_staff) {
            if (selected_sidebar_tab == "staff" && staff_panel_open) {
                staff_panel_open = false;
            } else {
                selected_sidebar_tab = "staff";
                staff_panel_open = true;
            }

            clinic_panel_open = false;
            clients_panel_open = false;
            finance_panel_open = false;
            hiring_panel_open = false;
            handbook_open = false;
            client_search_active = false;
        }
        else if (hover_finance) {
            if (selected_sidebar_tab == "finance" && finance_panel_open) {
                finance_panel_open = false;
            } else {
                selected_sidebar_tab = "finance";
                finance_panel_open = true;
            }

            clinic_panel_open = false;
            clients_panel_open = false;
            staff_panel_open = false;
            hiring_panel_open = false;
            handbook_open = false;
            client_search_active = false;
        }
        else if (hover_handbook) {
            if (selected_sidebar_tab == "handbook" && handbook_open) {
                handbook_open = false;
            } else {
                selected_sidebar_tab = "handbook";
                handbook_open = true;
            }

            clinic_panel_open = false;
            clients_panel_open = false;
            staff_panel_open = false;
            finance_panel_open = false;
            hiring_panel_open = false;
            client_search_active = false;
        }

        // Вкладка и поиск клиентов
        if (clients_panel_open) {
            if (hover_clients_tab_all) {
                clients_subtab = "all";
                client_search_active = false;
            }
            else if (hover_clients_tab_followup) {
                clients_subtab = "followup";
                client_search_active = false;
            }
            else if (hover_client_search) {
                client_search_active = true;
                keyboard_string = client_search_text;
            }
            else if (hover_client_clear) {
                client_search_text = "";
                keyboard_string = "";
                client_search_active = false;
            }
            else {
                client_search_active = false;
            }
        }
// Подвкладки клиники
if (clinic_panel_open) {
    if (hover_clinic_tab_clinic) {
        clinic_subtab = "clinic";
    }
    else if (hover_clinic_tab_storage) {
        clinic_subtab = "storage";
    }
}

        // Крестик панели найма
        if (hiring_panel_open && hover_hiring_close) {
            hiring_panel_open = false;
        }

        // Крестик панели справочника (пакет №69)
        if (handbook_open && hover_handbook_close) {
            handbook_open = false;
        }

        // Кнопки кандидата
        if (hiring_panel_open && instance_exists(global.selected_candidate)) {
            var _cand = global.selected_candidate;

            if (_cand.candidate_state == "waiting_offer") {
                if (hover_hire) {
                    with (_cand) {
                        resolve_hire();
                    }
                    hiring_panel_open = false;
                }
                else if (hover_reject) {
                    with (_cand) {
                        resolve_reject();
                    }
                    hiring_panel_open = false;
                }
            }
        }

        // Кнопки персонала
        if (staff_panel_open && instance_exists(selected_staff_id)) {
            if (hover_staff_card) {
                if (instance_exists(obj_UI_Tablet)) {
                    with (obj_UI_Tablet) {
                        visible = true;
                        target_id = other.selected_staff_id;
                    }
                }

                staff_panel_open = false;
            }
            else if (hover_staff_focus) {
                if (instance_exists(obj_Render)) {
                    with (instance_find(obj_Render, 0)) {
                        camera_mode = "focus_staff";
                        camera_focus_target = other.selected_staff_id;
                        camera_focus_timer = room_speed * 3;
                    }
                }
            }
            else if (hover_staff_fire) {
                if (selected_staff_id.object_index != obj_player) {
                    fire_confirm_target = selected_staff_id;
                    fire_confirm_open = true;
                }
            }
        }
    }
}
