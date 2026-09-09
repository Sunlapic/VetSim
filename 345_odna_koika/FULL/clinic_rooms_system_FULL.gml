/// clinic_rooms_system.gml
/// @description Помещения клиники за деньги: кабинеты приёма, койки
///              стационара, операционная.
/// Пакет №72, №104, №109, №173, №212.
/// ПАКЕТ №325: у каждой клиники СВОИ потолки. Что можно построить,
/// решают данные клиники (exam_max, bed_max, has_operating), а не
/// общий на всю сеть список. Панель РАЗВИТИЕ строит ветки отсюда же,
/// поэтому пункта сверх потолка в ней не появляется.


// ═══════════════════════════════════════════════════════════════
// 1. СОСТОЯНИЕ ПОМЕЩЕНИЙ
//
// global.clinic_rooms_open — это состояние ОДНОЙ клиники: той, в
// которой игрок стоит. Её подменяет clinic_apply_current из кармана
// клиники (global.clinic_state), поэтому покупка кабинета во второй
// клинике не открывает его в первой.
//
// Ключи структуры:
//   "1".."N"     кабинеты приёма (1 открыт всегда);
//   "ward"       палата стационара — открывает койки 101 и 102;
//   "bed_103"..  койки, которые докупаются по одной;
//   "operating"  операционная.
// ═══════════════════════════════════════════════════════════════

/// @function clinic_rooms_reset_default()
/// @description Стартовый набор помещений клиники: один кабинет
///              приёма и больше ничего. Палату, койки, остальные
///              кабинеты и операционную игрок покупает в развитии.
function clinic_rooms_reset_default() {
    global.clinic_rooms_open = {};

    variable_struct_set(global.clinic_rooms_open, "1", true);

    return true;
}


function clinic_rooms_init() {
    if (!variable_global_exists("clinic_rooms_open")) {
        clinic_rooms_reset_default();
    }
}


// ═══════════════════════════════════════════════════════════════
// 2. ПЕРЕКЛЮЧАТЕЛИ ФИЛЬТРА БОЛЕЗНЕЙ
//
// Болезни, требующие операционной или стационара, не приходят в
// клинику, пока соответствующего помещения нет (см. clinic_case_gate).
//
//   CLINIC_CASE_GATE_ENABLED
//     false — фильтр полностью выключен, болезни идут как раньше.
//
//   CLINIC_GATE_IGNORE_TESTING_UNLOCK
//     true — фильтр смотрит на реальную покупку операционной, даже
//     если включена тестовая поблажка ниже.
//
//   CLINIC_OPERATING_FREE_WHILE_TESTING
//     ПАКЕТ №325: поставлено в false. Раньше операционная считалась
//     открытой бесплатно во всех клиниках, из-за чего хирургические
//     случаи приходили даже туда, где операционной нет вовсе. Теперь
//     операционная — помещение клиники №4, и его нужно купить.
// ═══════════════════════════════════════════════════════════════

#macro CLINIC_OPERATING_FREE_WHILE_TESTING false
#macro CLINIC_CASE_GATE_ENABLED true
#macro CLINIC_GATE_IGNORE_TESTING_UNLOCK false

// Койки стационара: 101 идёт в комплекте с палатой (пакет №345),
// остальные докупаются по одной.
#macro CLINIC_BED_FIRST 101
#macro CLINIC_BED_LAST 108

// Номер ключа палаты.
#macro CLINIC_WARD_KEY "ward"


// ═══════════════════════════════════════════════════════════════
// 3. ЧТО ОТКРЫТО
// ═══════════════════════════════════════════════════════════════

/// Операционная куплена по-настоящему, без тестовой поблажки.
function clinic_operating_is_purchased() {
    clinic_rooms_init();

    if (variable_struct_exists(global.clinic_rooms_open, "operating")) {
        return variable_struct_get(global.clinic_rooms_open, "operating");
    }

    return false;
}


/// Операционная работает.
///
/// ПАКЕТ №325: сначала проверяем, есть ли операционная у ЭТОЙ клиники
/// вообще. Только у клиники №4 она предусмотрена проектом — в
/// остальных трёх её нет ни за какие деньги.
function clinic_operating_is_open() {
    clinic_rooms_init();

    if (
        script_exists(asset_get_index("clinic_has_operating_room"))
        && !clinic_has_operating_room()
    ) {
        return false;
    }

    if (CLINIC_OPERATING_FREE_WHILE_TESTING) return true;

    return clinic_operating_is_purchased();
}


/// Палата стационара куплена.
function clinic_ward_is_open() {
    clinic_rooms_init();

    if (variable_struct_exists(global.clinic_rooms_open, CLINIC_WARD_KEY)) {
        return variable_struct_get(global.clinic_rooms_open, CLINIC_WARD_KEY);
    }

    return false;
}


/// Койка доступна.
///
/// ПАКЕТ №325: койка существует, только если у клиники есть
/// стационар (bed_max > 0) и номер койки не выше её потолка.
/// ПАКЕТ №345: с палатой открывается только койка 101, остальные
/// (включая 102) докупаются по одной.
function clinic_bed_is_open(_slot_id) {
    clinic_rooms_init();

    var _slot = round(_slot_id);

    if (_slot < CLINIC_BED_FIRST || _slot > CLINIC_BED_LAST) return false;

    var _limit = script_exists(asset_get_index("clinic_bed_limit"))
        ? clinic_bed_limit()
        : CLINIC_BED_LAST - CLINIC_BED_FIRST + 1;

    if (_limit <= 0) return false;
    if (_slot - CLINIC_BED_FIRST + 1 > _limit) return false;

    // Койка 101 — часть палаты. 102 и далее — отдельные покупки.
    if (_slot == 101) return clinic_ward_is_open();

    var _key = "bed_" + string(_slot);

    if (variable_struct_exists(global.clinic_rooms_open, _key)) {
        return variable_struct_get(global.clinic_rooms_open, _key);
    }

    return false;
}


/// Кабинет приёма открыт.
function clinic_exam_room_is_open(_slot_num) {
    clinic_rooms_init();

    var _slot = round(_slot_num);

    if (_slot <= 0) return false;

    var _limit = script_exists(asset_get_index("clinic_exam_room_limit"))
        ? clinic_exam_room_limit()
        : 1;

    if (_slot > _limit) return false;

    // Первый кабинет открыт всегда — с него клиника начинает.
    if (_slot == 1) return true;

    if (variable_struct_exists(global.clinic_rooms_open, string(_slot))) {
        return variable_struct_get(global.clinic_rooms_open, string(_slot));
    }

    return false;
}


/// Универсальная проверка по слоту. Именно её зовут мебель, фильтр
/// болезней, склад и панель развития — поэтому все потолки клиники
/// действуют сразу во всей игре, а не только в панели.
function clinic_room_is_open(_slot_id) {
    clinic_rooms_init();

    // Операционная и её мебель (столы 201/202).
    if (string(_slot_id) == "operating") return clinic_operating_is_open();

    var _slot_num = round(_slot_id);

    if (_slot_num == 201 || _slot_num == 202) return clinic_operating_is_open();

    // Койки стационара.
    if (
        _slot_num >= CLINIC_BED_FIRST
        && _slot_num <= CLINIC_BED_LAST
    ) {
        return clinic_bed_is_open(_slot_num);
    }

    // Шкаф палаты и прочее общее оборудование стационара (слот 100).
    if (_slot_num >= 100) return true;

    // Кабинеты приёма.
    if (_slot_num >= 1) return clinic_exam_room_is_open(_slot_num);

    // Слот 0 — мебель без привязки к помещению, её не прячем.
    return true;
}


// ═══════════════════════════════════════════════════════════════
// 4. ЦЕНЫ И НАЗВАНИЯ
// ═══════════════════════════════════════════════════════════════

function clinic_operating_price() {
    return 8000;
}


function clinic_ward_price() {
    return 2500;
}


function clinic_bed_price(_slot_id) {
    switch (round(_slot_id)) {
        // ПАКЕТ №345: вторая койка теперь покупается отдельно.
        case 102: return 1200;
        case 103: return 1600;
        case 104: return 2000;
        case 105: return 2600;
        case 106: return 3200;
        case 107: return 4000;
        case 108: return 5000;
    }

    return 0;
}


function clinic_exam_room_price(_slot_id) {
    switch (round(_slot_id)) {
        case 2: return 1500;
        case 3: return 3000;
        case 4: return 4500;
        case 5: return 6500;
        case 6: return 9000;
    }

    return 0;
}


function clinic_room_price(_slot_id) {
    if (string(_slot_id) == "operating") return clinic_operating_price();
    if (string(_slot_id) == CLINIC_WARD_KEY) return clinic_ward_price();

    var _slot_num = round(_slot_id);

    if (
        _slot_num >= CLINIC_BED_FIRST
        && _slot_num <= CLINIC_BED_LAST
    ) {
        return clinic_bed_price(_slot_num);
    }

    return clinic_exam_room_price(_slot_num);
}


function clinic_room_name(_slot_id) {
    if (string(_slot_id) == "operating") return "Операционная";
    if (string(_slot_id) == CLINIC_WARD_KEY) return "Палата стационара";

    var _slot_num = round(_slot_id);

    if (
        _slot_num >= CLINIC_BED_FIRST
        && _slot_num <= CLINIC_BED_LAST
    ) {
        return "Койка " + string(_slot_num - 100);
    }

    return "Кабинет " + string(_slot_num);
}


function clinic_room_description(_slot_id) {
    if (string(_slot_id) == "operating") {
        return "Операционный блок: хирургические операции";
    }

    if (string(_slot_id) == CLINIC_WARD_KEY) {
        return "Палата на две койки: тяжёлые пациенты";
    }

    var _slot_num = round(_slot_id);

    if (
        _slot_num >= CLINIC_BED_FIRST
        && _slot_num <= CLINIC_BED_LAST
    ) {
        return "Ещё одно место в стационаре";
    }

    if (_slot_num <= 1) {
        return "Смотровый кабинет (стартовый)";
    }

    return "Смотровый кабинет: +1 стол осмотра";
}


/// @function clinic_rooms_entries()
/// @description Список помещений текущей клиники для панели. Собирается
///              от её потолков: кабинет сверх exam_max сюда не попадёт,
///              у клиники без стационара не будет ни палаты, ни коек.
function clinic_rooms_entries() {
    clinic_rooms_init();

    var _entries = [];

    // ── Кабинеты приёма ──
    var _exam_limit = script_exists(asset_get_index("clinic_exam_room_limit"))
        ? clinic_exam_room_limit()
        : 1;

    for (var _slot = 1; _slot <= _exam_limit; _slot++) {
        array_push(_entries, {
            slot : _slot,
            name : clinic_room_name(_slot),
            description : clinic_room_description(_slot),
            price : clinic_room_price(_slot),
            open : clinic_room_is_open(_slot)
        });
    }

    // ── Стационар ──
    var _bed_limit = script_exists(asset_get_index("clinic_bed_limit"))
        ? clinic_bed_limit()
        : 0;

    if (_bed_limit > 0) {
        array_push(_entries, {
            slot : CLINIC_WARD_KEY,
            name : clinic_room_name(CLINIC_WARD_KEY),
            description : clinic_room_description(CLINIC_WARD_KEY),
            price : clinic_room_price(CLINIC_WARD_KEY),
            open : clinic_ward_is_open()
        });

        for (var _bed = CLINIC_BED_FIRST + 2; _bed < CLINIC_BED_FIRST + _bed_limit; _bed++) {
            array_push(_entries, {
                slot : _bed,
                name : clinic_room_name(_bed),
                description : clinic_room_description(_bed),
                price : clinic_room_price(_bed),
                open : clinic_bed_is_open(_bed)
            });
        }
    }

    // ── Операционная ──
    if (
        script_exists(asset_get_index("clinic_has_operating_room"))
        && clinic_has_operating_room()
    ) {
        array_push(_entries, {
            slot : "operating",
            name : clinic_room_name("operating"),
            description : clinic_room_description("operating"),
            price : clinic_room_price("operating"),
            open : clinic_operating_is_open()
        });
    }

    return _entries;
}


// ═══════════════════════════════════════════════════════════════
// 5. ПОКУПКА ПОМЕЩЕНИЯ
// ═══════════════════════════════════════════════════════════════

/// @function clinic_room_purchase_blocked_reason(_slot_id)
/// @description Почему это помещение купить нельзя: "" если можно.
function clinic_room_purchase_blocked_reason(_slot_id) {
    clinic_rooms_init();

    var _is_operating = (string(_slot_id) == "operating");
    var _is_ward = (string(_slot_id) == CLINIC_WARD_KEY);
    var _slot = (_is_operating || _is_ward) ? 0 : round(_slot_id);

    if (_is_operating) {
        if (
            script_exists(asset_get_index("clinic_has_operating_room"))
            && !clinic_has_operating_room()
        ) {
            return "В этой клинике операционная не предусмотрена.";
        }

        if (clinic_operating_is_open()) return "Операционная уже открыта.";

        return "";
    }

    if (_is_ward) {
        if (
            script_exists(asset_get_index("clinic_bed_limit"))
            && clinic_bed_limit() <= 0
        ) {
            return "В этой клинике стационар не предусмотрен.";
        }

        if (clinic_ward_is_open()) return "Палата уже открыта.";

        return "";
    }

    if (
        _slot >= CLINIC_BED_FIRST
        && _slot <= CLINIC_BED_LAST
    ) {
        var _bed_limit = script_exists(asset_get_index("clinic_bed_limit"))
            ? clinic_bed_limit()
            : 0;

        if (_bed_limit <= 0) return "В этой клинике стационар не предусмотрен.";

        if (_slot - CLINIC_BED_FIRST + 1 > _bed_limit) {
            return "Больше коек в этой клинике быть не может.";
        }

        if (!_is_ward && !clinic_ward_is_open()) {
            return "Сначала откройте палату.";
        }

        if (clinic_bed_is_open(_slot)) return "Койка уже открыта.";

        return "";
    }

    var _exam_limit = script_exists(asset_get_index("clinic_exam_room_limit"))
        ? clinic_exam_room_limit()
        : 1;

    if (_slot > _exam_limit) {
        return "Больше кабинетов в этой клинике быть не может.";
    }

    if (_slot >= 3 && !clinic_exam_room_is_open(_slot - 1)) {
        return "Сначала откройте предыдущий кабинет.";
    }

    if (clinic_exam_room_is_open(_slot)) return "Кабинет уже открыт.";

    return "";
}


function clinic_room_purchase(_slot_id) {
    clinic_rooms_init();

    var _blocked = clinic_room_purchase_blocked_reason(_slot_id);

    if (_blocked != "") {
        clinic_room_notice("НЕ ПОЛУЧИТСЯ", _blocked);
        show_debug_message("[ROOMS] Отказ: " + _blocked);
        return false;
    }

    var _is_operating = (string(_slot_id) == "operating");
    var _is_ward = (string(_slot_id) == CLINIC_WARD_KEY);
    var _slot = (_is_operating || _is_ward) ? 0 : round(_slot_id);

    var _price = clinic_room_price(_slot_id);

    if (_price <= 0) return false;

    if (global.clinic_money < _price) {
        clinic_room_notice(
            "НЕ ХВАТАЕТ ДЕНЕГ",
            "Нужно $" + string(_price) + "."
        );

        return false;
    }

    global.clinic_money -= _price;

    if (_is_operating) {
        variable_struct_set(global.clinic_rooms_open, "operating", true);
    }
    else if (_is_ward) {
        variable_struct_set(global.clinic_rooms_open, CLINIC_WARD_KEY, true);

        // ПАКЕТ №345: палата открывает только первую койку.
        variable_struct_set(global.clinic_rooms_open, "bed_101", true);

        clinic_room_free_beds([101]);
    }
    else if (_slot >= CLINIC_BED_FIRST && _slot <= CLINIC_BED_LAST) {
        variable_struct_set(global.clinic_rooms_open, "bed_" + string(_slot), true);

        clinic_room_free_beds([_slot]);
    }
    else {
        variable_struct_set(global.clinic_rooms_open, string(_slot), true);

        clinic_room_free_tables(_slot);
    }

    var _room_name = clinic_room_name(_slot_id);

    clinic_room_notice(
        "ПОМЕЩЕНИЕ ОТКРЫТО",
        _room_name + " теперь работает."
    );

    show_debug_message("[ROOMS] Открыт " + _room_name + " за $" + string(_price));

    return true;
}


/// @function clinic_room_free_tables(_slot)
/// @description Освобождает столы открытого кабинета: теперь их найдут
///              игрок, врачи и ассистенты в поиске свободного стола.
function clinic_room_free_tables(_slot) {
    var _table_types = [obj_table, obj_table_1];

    for (var _type_index = 0; _type_index < array_length(_table_types); _type_index++) {
        var _object = _table_types[_type_index];

        for (var _table_index = 0; _table_index < instance_number(_object); _table_index++) {
            var _table = instance_find(_object, _table_index);

            if (
                instance_exists(_table)
                && variable_instance_exists(_table, "exam_slot_id")
                && _table.exam_slot_id == _slot
            ) {
                _table.table_busy = false;
                _table.assigned_owner = noone;
                _table.assigned_doctor = noone;
                _table.assigned_pet = noone;
            }
        }
    }

    return true;
}


/// @function clinic_room_free_beds(_slots)
/// @description Освобождает койки, которые только что стали доступны.
function clinic_room_free_beds(_slots) {
    for (var _slot_index = 0; _slot_index < array_length(_slots); _slot_index++) {
        var _slot = _slots[_slot_index];

        for (var _bed_index = 0; _bed_index < instance_number(obj_inpatient_table); _bed_index++) {
            var _bed = instance_find(obj_inpatient_table, _bed_index);

            if (
                instance_exists(_bed)
                && variable_instance_exists(_bed, "exam_slot_id")
                && _bed.exam_slot_id == _slot
            ) {
                _bed.table_busy = false;
                _bed.assigned_owner = noone;
                _bed.assigned_doctor = noone;
                _bed.assigned_pet = noone;
            }
        }
    }

    return true;
}


/// @function clinic_room_notice(_title, _text)
/// @description Уведомление в HUD. Вынесено, чтобы покупка помещения не
///              тащила пять строк проверки инстанса в каждом месте.
function clinic_room_notice(_title, _text) {
    if (!instance_exists(obj_UI_HUD)) return false;

    var _hud = instance_find(obj_UI_HUD, 0);

    if (
        !instance_exists(_hud)
        || !variable_instance_exists(_hud, "show_notice")
    ) {
        return false;
    }

    with (_hud) {
        show_notice(
            _title,
            _text,
            max(1, game_get_speed(gamespeed_fps)) * 3
        );
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 6. ЛЕВАЯ КОЛОНКА «ПОМЕЩЕНИЯ (деньги)» В ПАНЕЛИ РАЗВИТИЕ
// ═══════════════════════════════════════════════════════════════

function hud_draw_rooms_column(_hud, _x1, _y1, _x2, _y2, _mx, _my) {
    if (!instance_exists(_hud)) return;

    clinic_rooms_init();

    with (_hud) {
        // Состояние прокрутки (переживает кадры на инстансе HUD).
        if (!variable_instance_exists(id, "rooms_scroll")) rooms_scroll = 0;
        if (!variable_instance_exists(id, "rooms_touch_active")) rooms_touch_active = false;
        if (!variable_instance_exists(id, "rooms_touch_last_y")) rooms_touch_last_y = 0;
        if (!variable_instance_exists(id, "rooms_touch_accum")) rooms_touch_accum = 0;

        var _wood_light = make_color_rgb(150, 107, 73);
        var _line_dark  = make_color_rgb(58, 39, 24);
        var _text_dark  = make_color_rgb(50, 38, 28);
        var _text_soft  = make_color_rgb(84, 68, 54);

        var _entries = clinic_rooms_entries();
        var _row_h = 150;
        var _list_y1 = _y1 + 40;
        var _list_y2 = _y2 - 8;
        var _visible = max(1, floor((_list_y2 - _list_y1) / _row_h));
        var _max_scroll = max(0, array_length(_entries) - _visible);

        rooms_scroll = clamp(rooms_scroll, 0, _max_scroll);

        // Прокрутка: колесо + touch.
        var _in_rect = point_in_rectangle(_mx, _my, _x1, _y1, _x2, _y2);

        if (_in_rect) {
            if (mouse_wheel_down()) {
                rooms_scroll = min(_max_scroll, rooms_scroll + 1);
            }
            if (mouse_wheel_up()) {
                rooms_scroll = max(0, rooms_scroll - 1);
            }
        }

        var _pressed = mouse_check_button_pressed(mb_left)
            || device_mouse_check_button_pressed(0, mb_left);
        var _down = mouse_check_button(mb_left)
            || device_mouse_check_button(0, mb_left);
        var _released = mouse_check_button_released(mb_left)
            || device_mouse_check_button_released(0, mb_left);

        if (_pressed && _in_rect) {
            rooms_touch_active = true;
            rooms_touch_last_y = _my;
            rooms_touch_accum = 0;
        }

        if (rooms_touch_active) {
            if (_down) {
                var _delta = _my - rooms_touch_last_y;
                rooms_touch_accum += _delta;

                while (rooms_touch_accum <= -30) {
                    rooms_scroll = min(_max_scroll, rooms_scroll + 1);
                    rooms_touch_accum += 30;
                }

                while (rooms_touch_accum >= 30) {
                    rooms_scroll = max(0, rooms_scroll - 1);
                    rooms_touch_accum -= 30;
                }

                rooms_touch_last_y = _my;
            }

            if (_released || !_down) {
                rooms_touch_active = false;
                rooms_touch_accum = 0;
            }
        }

        // ── Карточки помещений ──
        for (var _vi = 0; _vi < _visible; _vi++) {
            var _idx = rooms_scroll + _vi;
            if (_idx >= array_length(_entries)) break;

            var _entry = _entries[_idx];
            var _cy1 = _list_y1 + _vi * _row_h;
            var _cy2 = _cy1 + (_row_h - 8);
            var _cx1 = _x1 + 10;
            var _cx2 = _x2 - 10;

            draw_set_color(make_color_rgb(246, 240, 228));
            draw_roundrect_ext(_cx1, _cy1, _cx2, _cy2, 8, 8, false);
            draw_set_color(make_color_rgb(200, 188, 170));
            draw_roundrect_ext(_cx1, _cy1, _cx2, _cy2, 8, 8, true);

            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_set_color(_text_dark);
            draw_text_transformed(
                _cx1 + 12,
                _cy1 + 8,
                _entry.name,
                1.35,
                1.35,
                0
            );
            draw_set_color(_text_soft);
            draw_text_transformed(
                _cx1 + 12,
                _cy1 + 40,
                _entry.description,
                1.15,
                1.15,
                0
            );

            // Кнопка на всю ширину карточки.
            var _btn_x1 = _cx1 + 12;
            var _btn_x2 = _cx2 - 12;
            var _btn_y1 = _cy1 + 88;
            var _btn_y2 = _btn_y1 + 48;
            var _btn_hover = point_in_rectangle(
                _mx, _my,
                _btn_x1, _btn_y1,
                _btn_x2, _btn_y2
            );

            var _can_afford = (
                !_entry.open
                && global.clinic_money >= _entry.price
            );

            var _label = _entry.open
                ? "ОТКРЫТО"
                : ("ОТКРЫТЬ ЗА $" + string(_entry.price));

            var _fill = _entry.open
                ? make_color_rgb(205, 224, 193)
                : (_can_afford
                    ? (_btn_hover
                        ? make_color_rgb(220, 235, 208)
                        : make_color_rgb(205, 224, 193))
                    : (_btn_hover
                        ? make_color_rgb(236, 226, 214)
                        : make_color_rgb(226, 216, 199)));
            var _line = _entry.open
                ? make_color_rgb(104, 137, 91)
                : (_can_afford
                    ? make_color_rgb(104, 137, 91)
                    : make_color_rgb(150, 132, 112));
            var _tcol = _entry.open
                ? make_color_rgb(45, 60, 40)
                : (_can_afford
                    ? make_color_rgb(45, 60, 40)
                    : make_color_rgb(148, 74, 64));

            draw_set_color(_fill);
            draw_roundrect_ext(_btn_x1, _btn_y1, _btn_x2, _btn_y2, 8, 8, false);
            draw_set_color(_line);
            draw_roundrect_ext(_btn_x1, _btn_y1, _btn_x2, _btn_y2, 8, 8, true);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(_tcol);
            draw_text_transformed(
                (_btn_x1 + _btn_x2) * 0.5,
                (_btn_y1 + _btn_y2) * 0.5,
                _label,
                1.2,
                1.2,
                0
            );
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);

            if (
                _btn_hover
                && tablet_click_lock <= 0
                && mouse_check_button_pressed(mb_left)
            ) {
                tablet_click_lock = 5;
                clinic_room_purchase(_entry.slot);
            }
        }

        // ── Бегунок ──
        if (_max_scroll > 0) {
            var _track_x = _x2 - 8;
            var _track_h = max(1, _list_y2 - _list_y1);
            var _thumb_h = max(
                24,
                _track_h * (_visible / array_length(_entries))
            );
            var _travel = max(1, _track_h - _thumb_h);
            var _thumb_y = _list_y1 + _travel * (rooms_scroll / _max_scroll);

            draw_set_color(make_color_rgb(212, 200, 182));
            draw_roundrect_ext(_track_x, _list_y1, _track_x + 6, _list_y2, 3, 3, false);
            draw_set_color(_wood_light);
            draw_roundrect_ext(_track_x, _thumb_y, _track_x + 6, _thumb_y + _thumb_h, 3, 3, false);
            draw_set_color(_line_dark);
            draw_roundrect_ext(_track_x, _thumb_y, _track_x + 6, _thumb_y + _thumb_h, 3, 3, true);
        }
    }
}
