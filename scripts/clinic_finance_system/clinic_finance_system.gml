/// clinic_finance_system.gml
/// @description Чек владельца, тарифы услуг, расчёт зарплат и ежедневная выплата.
/// Пакет №107: убрано английское item_id под названием препарата во вкладке ПРЕПАРАТЫ.
/// Пакет №118: пилот «матового стекла» на панели ФИНАНСЫ (имитация, без шейдера).
/// Исправление: дерево рисуется только рамкой, центр — стекло поверх мира.


// ═══════════════════════════════════════════════════════════════
// 1. РЕДАКТИРУЕМЫЙ ПРАЙС-ЛИСТ КЛИНИКИ
// ═══════════════════════════════════════════════════════════════

function finance_price_catalog_init() {
    if (!variable_global_exists("finance_service_prices")) {
        global.finance_service_prices = {
            diag_physical_exam : 50,
            diag_blood_smear : 80,
            diag_blood_test : 60,
            diag_xray : 120,
            diag_otoscope : 40,
            diag_urinalysis : 55,
            diag_ultrasound : 100,
            diag_skin_scraping : 45,

            // Это стоимость работы персонала. Использованные препараты
            // добавляются в чек отдельными строками.
            treat_painkiller : 20,
            treat_iv_drip : 40,
            treat_antiprotozoal : 50,
            treat_limb_fixation : 150,
            inpatient_stay : 150
        };
    }

    if (!variable_global_exists("finance_item_sale_prices")) {
        global.finance_item_sale_prices = {};
    }
}

function finance_service_price_get(_service_id, _fallback = 0) {
    finance_price_catalog_init();

    var _key = string(_service_id);

    if (variable_struct_exists(global.finance_service_prices, _key)) {
        return max(
            0,
            round(variable_struct_get(global.finance_service_prices, _key))
        );
    }

    var _value = max(0, round(_fallback));
    variable_struct_set(global.finance_service_prices, _key, _value);
    return _value;
}

function finance_service_price_set(_service_id, _value) {
    finance_price_catalog_init();

    var _key = string(_service_id);
    var _new_value = clamp(round(_value), 0, 9999);

    variable_struct_set(
        global.finance_service_prices,
        _key,
        _new_value
    );

    // Синхронизируем старые медицинские справочники, чтобы новая цена
    // отображалась и в существующих списках обследований/назначений.
    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
    ) {
        if (
            variable_struct_exists(global.med_db, "diagnostics")
            && variable_struct_exists(global.med_db.diagnostics, _key)
        ) {
            var _diagnostic = variable_struct_get(
                global.med_db.diagnostics,
                _key
            );
            _diagnostic.price = _new_value;
            variable_struct_set(
                global.med_db.diagnostics,
                _key,
                _diagnostic
            );
        }

        if (
            variable_struct_exists(global.med_db, "treatment_actions")
            && variable_struct_exists(global.med_db.treatment_actions, _key)
        ) {
            var _action = variable_struct_get(
                global.med_db.treatment_actions,
                _key
            );
            _action.price = _new_value;
            variable_struct_set(
                global.med_db.treatment_actions,
                _key,
                _action
            );
        }
    }

    return finance_service_price_get(_key, 0);
}

function finance_get_item_purchase_price(_item_id) {
    if (
        variable_global_exists("item_db")
        && is_struct(global.item_db)
        && variable_struct_exists(global.item_db, _item_id)
    ) {
        var _item = variable_struct_get(global.item_db, _item_id);
        var _field_names = [
            "purchase_price",
            "buy_price",
            "cost",
            "price"
        ];

        for (var _index = 0; _index < array_length(_field_names); _index++) {
            var _field = _field_names[_index];

            if (variable_struct_exists(_item, _field)) {
                return max(0, round(variable_struct_get(_item, _field)));
            }
        }
    }

    // Старые предметы без поля цены получают безопасную закупочную цену.
    return 10;
}

function finance_get_item_sale_price(_item_id) {
    finance_price_catalog_init();

    var _key = string(_item_id);

    if (!variable_struct_exists(global.finance_item_sale_prices, _key)) {
        var _purchase = finance_get_item_purchase_price(_key);
        var _default_sale = max(
            _purchase + 5,
            round(_purchase * 1.60)
        );

        variable_struct_set(
            global.finance_item_sale_prices,
            _key,
            _default_sale
        );
    }

    return max(
        0,
        round(variable_struct_get(global.finance_item_sale_prices, _key))
    );
}

function finance_set_item_sale_price(_item_id, _value) {
    finance_price_catalog_init();

    variable_struct_set(
        global.finance_item_sale_prices,
        string(_item_id),
        clamp(round(_value), 0, 9999)
    );

    return finance_get_item_sale_price(_item_id);
}

function finance_get_item_ids() {
    if (
        variable_global_exists("item_ids")
        && is_array(global.item_ids)
    ) {
        return global.item_ids;
    }

    if (
        variable_global_exists("item_db")
        && is_struct(global.item_db)
    ) {
        return variable_struct_get_names(global.item_db);
    }

    return [];
}

function finance_get_service_entries() {
    var _entries = [];
    var _diagnostic_ids = [
        "diag_physical_exam",
        "diag_blood_smear",
        "diag_blood_test",
        "diag_xray",
        "diag_otoscope",
        "diag_urinalysis",
        "diag_ultrasound",
        "diag_skin_scraping"
    ];

    for (var _index = 0; _index < array_length(_diagnostic_ids); _index++) {
        var _diagnostic_id = _diagnostic_ids[_index];

        array_push(_entries, {
            id : _diagnostic_id,
            name : finance_get_diagnostic_name(_diagnostic_id),
            group : "ОБСЛЕДОВАНИЕ"
        });
    }

    var _treatment_ids = [
        "treat_painkiller",
        "treat_iv_drip",
        "treat_antiprotozoal",
        "treat_limb_fixation"
    ];

    for (var _treatment_index = 0; _treatment_index < array_length(_treatment_ids); _treatment_index++) {
        var _action_id = _treatment_ids[_treatment_index];

        array_push(_entries, {
            id : _action_id,
            name : finance_get_treatment_name(_action_id),
            group : "РАБОТА"
        });
    }

    array_push(_entries, {
        id : "inpatient_stay",
        name : "Стационар",
        group : "СТАЦИОНАР"
    });

    return _entries;
}

function finance_get_diagnostic_price(_diagnostic_id) {
    var _fallback = 0;

    if (_diagnostic_id == "diag_physical_exam") {
        _fallback = 50;
    }
    else if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "diagnostics")
        && variable_struct_exists(global.med_db.diagnostics, _diagnostic_id)
    ) {
        var _diagnostic = variable_struct_get(
            global.med_db.diagnostics,
            _diagnostic_id
        );

        if (variable_struct_exists(_diagnostic, "price")) {
            _fallback = max(0, round(_diagnostic.price));
        }
    }

    return finance_service_price_get(_diagnostic_id, _fallback);
}

function finance_get_treatment_price(_action_id) {
    var _fallback = 0;

    // Пакет №67: цена работы берётся из медицинского справочника,
    // а не из хардкода. Это чинит новые действия («Сыворотка» 220,
    // «Антибиотик» 60 и т.д.), которые раньше шли по 50 долларов.
    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "treatment_actions")
        && variable_struct_exists(global.med_db.treatment_actions, _action_id)
    ) {
        var _action = variable_struct_get(
            global.med_db.treatment_actions,
            _action_id
        );

        if (variable_struct_exists(_action, "price")) {
            _fallback = max(0, round(_action.price));
        }
    }

    // Резерв для старых действий, если вдруг нет справочника.
    if (_fallback <= 0) {
        switch (string(_action_id)) {
            case "treat_painkiller": _fallback = 20; break;
            case "treat_iv_drip": _fallback = 40; break;
            case "treat_antiprotozoal": _fallback = 50; break;
            case "treat_limb_fixation": _fallback = 150; break;
            default: _fallback = 50; break;
        }
    }

    return finance_service_price_get(_action_id, _fallback);
}

function finance_get_diagnostic_name(_diagnostic_id) {
    if (_diagnostic_id == "diag_physical_exam") {
        return "Первичный приём";
    }

    return db_get_diagnostic_name(_diagnostic_id);
}

function finance_get_treatment_name(_action_id) {
    return db_get_treatment_action_name(_action_id);
}


// ═══════════════════════════════════════════════════════════════
// 2. СТРОКИ ЧЕКА
// ═══════════════════════════════════════════════════════════════

function finance_bill_add_item(
    _items,
    _key,
    _name,
    _unit_price,
    _kind,
    _quantity = 1
) {
    var _price = max(0, round(_unit_price));
    var _add_quantity = max(1, round(_quantity));

    for (var _index = 0; _index < array_length(_items); _index++) {
        var _item = _items[_index];

        if (_item.key == _key && _item.kind == _kind) {
            _item.quantity += _add_quantity;
            _item.total = _item.quantity * _item.unit_price;
            _items[_index] = _item;
            return _items;
        }
    }

    array_push(_items, {
        key : string(_key),
        kind : string(_kind),
        name : string(_name),
        quantity : _add_quantity,
        unit_price : _price,
        total : _price * _add_quantity
    });

    return _items;
}

function finance_bill_add_treatment_with_items(
    _items,
    _action_id,
    _kind
) {
    _items = finance_bill_add_item(
        _items,
        _action_id,
        finance_get_treatment_name(_action_id),
        finance_get_treatment_price(_action_id),
        _kind
    );

    // Препараты показываются в чеке отдельно от стоимости работы.
    // Пакет №67: к названию препарата добавлена пометка «(препарат)»,
    // чтобы строка препарата не путалась со строкой работы персонала
    // (например, «Кровоостанавливающее» 50$ и 88$ раньше выглядели
    // одинаково, хотя это разные позиции).
    var _required_items = treatment_get_required_items(_action_id);

    for (var _index = 0; _index < array_length(_required_items); _index++) {
        var _requirement = _required_items[_index];
        var _item_id = string(_requirement.item_id);
        var _quantity = variable_struct_exists(_requirement, "amount")
            ? max(1, round(_requirement.amount))
            : 1;

        _items = finance_bill_add_item(
            _items,
            "medicine_" + _item_id,
            item_get_name(_item_id) + " (препарат)",
            finance_get_item_sale_price(_item_id),
            "medicine",
            _quantity
        );
    }

    return _items;
}

function finance_bill_total(_items) {
    var _total = 0;

    for (var _index = 0; _index < array_length(_items); _index++) {
        _total += max(0, _items[_index].total);
    }

    return round(_total);
}

function finance_owner_get_case(_owner) {
    if (!instance_exists(_owner)) return undefined;
    if (!variable_instance_exists(_owner, "my_pet")) return undefined;
    if (!instance_exists(_owner.my_pet)) return undefined;

    var _pet = _owner.my_pet;

    if (!variable_instance_exists(_pet, "current_case")) return undefined;
    if (!is_struct(_pet.current_case)) return undefined;

    return _pet.current_case;
}

function finance_owner_rebuild_invoice(_owner) {
    if (!instance_exists(_owner)) {
        return { items : [], total : 0 };
    }

    var _items = [];
    var _case = finance_owner_get_case(_owner);

    if (is_struct(_case)) {
        // Обследования текущего визита. Старое completed_diagnostics
        // используется только как резерв для дел до появления visit-массива.
        var _diagnostics = [];

        if (
            variable_struct_exists(_case, "visit_diagnostics_done")
            && is_array(_case.visit_diagnostics_done)
        ) {
            _diagnostics = _case.visit_diagnostics_done;
        }
        else if (
            variable_struct_exists(_case, "completed_diagnostics")
            && is_array(_case.completed_diagnostics)
        ) {
            _diagnostics = _case.completed_diagnostics;
        }

        for (
            var _diagnostic_index = 0;
            _diagnostic_index < array_length(_diagnostics);
            _diagnostic_index++
        ) {
            var _diagnostic_id = string(_diagnostics[_diagnostic_index]);

            // Пакет №67: пропускаем неизвестные id (защита от старых
            // фиктивных записей вида "doctor_exam" в истории визитов).
            if (!finance_diagnostic_is_known(_diagnostic_id)) continue;

            _items = finance_bill_add_item(
                _items,
                _diagnostic_id,
                finance_get_diagnostic_name(_diagnostic_id),
                finance_get_diagnostic_price(_diagnostic_id),
                "diagnostic"
            );
        }

        // Лишнее обследование тоже выполнено фактически и оплачивается.
        if (
            variable_struct_exists(_case, "visit_wrong_diagnostics_done")
            && is_array(_case.visit_wrong_diagnostics_done)
        ) {
            for (
                var _wrong_index = 0;
                _wrong_index < array_length(_case.visit_wrong_diagnostics_done);
                _wrong_index++
            ) {
                var _wrong_id = string(
                    _case.visit_wrong_diagnostics_done[_wrong_index]
                );

                if (!finance_diagnostic_is_known(_wrong_id)) continue;

                _items = finance_bill_add_item(
                    _items,
                    "wrong_" + _wrong_id,
                    finance_get_diagnostic_name(_wrong_id)
                        + " (лишнее)",
                    finance_get_diagnostic_price(_wrong_id),
                    "diagnostic_wrong"
                );
            }
        }

        var _inpatient_log = [];

        if (
            variable_struct_exists(_case, "inpatient_treatment_log")
            && is_array(_case.inpatient_treatment_log)
        ) {
            _inpatient_log = _case.inpatient_treatment_log;
        }

        if (array_length(_inpatient_log) > 0) {
            _items = finance_bill_add_item(
                _items,
                "inpatient_stay",
                "Стационар",
                finance_service_price_get("inpatient_stay", 150),
                "inpatient"
            );

            // В стационаре журнал не очищается между двухчасовыми циклами.
            for (
                var _inpatient_index = 0;
                _inpatient_index < array_length(_inpatient_log);
                _inpatient_index++
            ) {
                var _log_entry = _inpatient_log[_inpatient_index];
                var _action_id = is_struct(_log_entry)
                    && variable_struct_exists(_log_entry, "action_id")
                        ? string(_log_entry.action_id)
                        : string(_log_entry);

                _items = finance_bill_add_treatment_with_items(
                    _items,
                    _action_id,
                    "inpatient_treatment"
                );
            }
        }
        else if (
            variable_struct_exists(_case, "visit_treatments_done")
            && is_array(_case.visit_treatments_done)
        ) {
            // Амбулаторные процедуры считаются по фактическому выполнению.
            for (
                var _treatment_index = 0;
                _treatment_index < array_length(_case.visit_treatments_done);
                _treatment_index++
            ) {
                var _treatment_id = string(
                    _case.visit_treatments_done[_treatment_index]
                );

                _items = finance_bill_add_treatment_with_items(
                    _items,
                    _treatment_id,
                    "treatment"
                );
            }
        }
    }

    var _total = finance_bill_total(_items);

    // Совместимость со старым завершением процедур, если медицинский case
    // ещё не содержит новых журналов.
    if (_total <= 0) {
        var _legacy_total = 0;

        if (variable_instance_exists(_owner, "pending_payment_total")) {
            _legacy_total = max(
                _legacy_total,
                _owner.pending_payment_total
            );
        }

        if (variable_instance_exists(_owner, "visit_price")) {
            _legacy_total = max(_legacy_total, _owner.visit_price);
        }

        if (_legacy_total > 0) {
            _items = finance_bill_add_item(
                _items,
                "legacy_medical_service",
                "Медицинские услуги",
                _legacy_total,
                "legacy"
            );
            _total = finance_bill_total(_items);
        }
    }

    _owner.finance_bill_items = _items;
    _owner.finance_bill_total = _total;
    _owner.visit_price = _total;

    if (
        !variable_instance_exists(_owner, "finance_bill_paid")
        || !_owner.finance_bill_paid
    ) {
        _owner.pending_payment_total = _total;
    }

    return { items : _items, total : _total };
}

function finance_diagnostic_is_known(_diagnostic_id) {
    if (_diagnostic_id == "diag_physical_exam") return true;

    if (
        variable_global_exists("med_db")
        && is_struct(global.med_db)
        && variable_struct_exists(global.med_db, "diagnostics")
    ) {
        return variable_struct_exists(
            global.med_db.diagnostics,
            _diagnostic_id
        );
    }

    return false;
}


// ═══════════════════════════════════════════════════════════════
// 3. ВКЛАДКИ И ЧЕК В КАРТОЧКЕ ВЛАДЕЛЬЦА
// ═══════════════════════════════════════════════════════════════

function finance_draw_tab_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _text,
    _selected,
    _hovered,
    _scale
) {
    var _fill = _selected
        ? make_color_rgb(205, 224, 193)
        : (_hovered
            ? make_color_rgb(236, 229, 214)
            : make_color_rgb(225, 216, 199));
    var _line = _selected
        ? make_color_rgb(104, 137, 91)
        : make_color_rgb(150, 132, 112);

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 6, 6, false);
    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 6, 6, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text_transformed(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5,
        _text,
        0.72 * _scale,
        0.78 * _scale,
        0
    );
}

function finance_owner_card_draw_tabs(
    _tablet,
    _owner,
    _center_x,
    _frame_x,
    _frame_y,
    _ui_scale,
    _mouse_x,
    _mouse_y
) {
    if (!variable_instance_exists(_tablet, "owner_card_tab")) {
        _tablet.owner_card_tab = "card";
        _tablet.owner_card_tab_target = noone;
    }

    if (_tablet.owner_card_tab_target != _owner) {
        _tablet.owner_card_tab = "card";
        _tablet.owner_card_tab_target = _owner;
    }

    var _x1 = _center_x + 18 * _ui_scale;
    var _x2 = _frame_x + 520 * _ui_scale;
    var _gap = 5 * _ui_scale;
    var _button_w = (_x2 - _x1 - _gap) * 0.5;
    var _y1 = _frame_y - 7 * _ui_scale;
    var _y2 = _frame_y + 19 * _ui_scale;
    var _card_x1 = _x1;
    var _card_x2 = _card_x1 + _button_w;
    var _bill_x1 = _card_x2 + _gap;
    var _bill_x2 = _x2;
    var _card_hover = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _card_x1,
        _y1,
        _card_x2,
        _y2
    );
    var _bill_hover = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _bill_x1,
        _y1,
        _bill_x2,
        _y2
    );

    finance_draw_tab_button(
        _card_x1,
        _y1,
        _card_x2,
        _y2,
        "КАРТОЧКА",
        _tablet.owner_card_tab == "card",
        _card_hover,
        _ui_scale
    );
    finance_draw_tab_button(
        _bill_x1,
        _y1,
        _bill_x2,
        _y2,
        "СТОИМОСТЬ",
        _tablet.owner_card_tab == "invoice",
        _bill_hover,
        _ui_scale
    );

    if (
        _tablet.tablet_click_lock <= 0
        && mouse_check_button_pressed(mb_left)
    ) {
        if (_card_hover) {
            _tablet.owner_card_tab = "card";
            _tablet.tablet_click_lock = 4;
        }
        else if (_bill_hover) {
            _tablet.owner_card_tab = "invoice";
            _tablet.tablet_click_lock = 4;
        }
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    return _tablet.owner_card_tab == "invoice";
}

function finance_owner_card_draw_invoice(
    _tablet,
    _owner,
    _x1,
    _y1,
    _x2,
    _y2,
    _ui_scale,
    _mouse_x,
    _mouse_y
) {
    var _invoice = finance_owner_rebuild_invoice(_owner);
    var _items = _invoice.items;
    var _item_count = array_length(_items);
    var _padding = 10 * _ui_scale;
    // Пакет №177: строки чека выше под крупный шрифт.
    var _row_h = 38 * _ui_scale;
    var _header_h = 38 * _ui_scale;
    var _footer_h = 49 * _ui_scale;
    var _rows_y1 = _y1 + _header_h;
    var _rows_y2 = _y2 - _footer_h;
    var _visible_rows = max(
        1,
        floor((_rows_y2 - _rows_y1) / _row_h)
    );
    var _max_scroll = max(0, _item_count - _visible_rows);

    if (!variable_instance_exists(_tablet, "owner_invoice_scroll")) {
        _tablet.owner_invoice_scroll = 0;
        _tablet.owner_invoice_touch_active = false;
        _tablet.owner_invoice_touch_last_y = 0;
        _tablet.owner_invoice_touch_accum = 0;
    }

    var _inside_rows = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _x1,
        _rows_y1,
        _x2,
        _rows_y2
    );

    if (_inside_rows) {
        if (mouse_wheel_down()) _tablet.owner_invoice_scroll += 1;
        if (mouse_wheel_up()) _tablet.owner_invoice_scroll -= 1;
    }

    var _pointer_pressed = mouse_check_button_pressed(mb_left)
        || device_mouse_check_button_pressed(0, mb_left);
    var _pointer_down = mouse_check_button(mb_left)
        || device_mouse_check_button(0, mb_left);
    var _pointer_released = mouse_check_button_released(mb_left)
        || device_mouse_check_button_released(0, mb_left);

    if (_pointer_pressed && _inside_rows) {
        _tablet.owner_invoice_touch_active = true;
        _tablet.owner_invoice_touch_last_y = _mouse_y;
        _tablet.owner_invoice_touch_accum = 0;
    }

    if (_tablet.owner_invoice_touch_active) {
        if (_pointer_down) {
            var _delta_y = _mouse_y - _tablet.owner_invoice_touch_last_y;
            _tablet.owner_invoice_touch_accum += _delta_y;

            while (_tablet.owner_invoice_touch_accum <= -24 * _ui_scale) {
                _tablet.owner_invoice_scroll += 1;
                _tablet.owner_invoice_touch_accum += 24 * _ui_scale;
            }

            while (_tablet.owner_invoice_touch_accum >= 24 * _ui_scale) {
                _tablet.owner_invoice_scroll -= 1;
                _tablet.owner_invoice_touch_accum -= 24 * _ui_scale;
            }

            _tablet.owner_invoice_touch_last_y = _mouse_y;
        }

        if (_pointer_released || !_pointer_down) {
            _tablet.owner_invoice_touch_active = false;
            _tablet.owner_invoice_touch_accum = 0;
        }
    }

    _tablet.owner_invoice_scroll = clamp(
        _tablet.owner_invoice_scroll,
        0,
        _max_scroll
    );

    tablet_owner_draw_panel(_x1, _y1, _x2, _y2);

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(74, 49, 31));
    draw_text_transformed(
        _x1 + _padding,
        _y1 + _header_h * 0.5,
        "ВЫПОЛНЕННЫЕ УСЛУГИ",
        0.84 * _ui_scale,
        0.90 * _ui_scale,
        0
    );

    draw_set_halign(fa_right);
    draw_set_color(make_color_rgb(84, 68, 54));
    draw_text_transformed(
        _x2 - _padding,
        _y1 + _header_h * 0.5,
        "КОЛ-ВО   ЦЕНА",
        0.68 * _ui_scale,
        0.74 * _ui_scale,
        0
    );

    if (_item_count <= 0) {
        draw_set_halign(fa_center);
        draw_set_color(make_color_rgb(120, 110, 95));
        draw_text_transformed(
            (_x1 + _x2) * 0.5,
            (_rows_y1 + _rows_y2) * 0.5,
            "Услуги ещё не выполнены",
            0.80 * _ui_scale,
            0.86 * _ui_scale,
            0
        );
    }
    else {
        var _draw_y = _rows_y1;
        var _last_index = min(
            _item_count,
            _tablet.owner_invoice_scroll + _visible_rows
        );

        for (
            var _item_index = _tablet.owner_invoice_scroll;
            _item_index < _last_index;
            _item_index++
        ) {
            var _item = _items[_item_index];
            var _row_y2 = _draw_y + _row_h - 3 * _ui_scale;
            var _row_fill = (_item_index mod 2 == 0)
                ? make_color_rgb(247, 241, 230)
                : make_color_rgb(239, 231, 216);

            draw_set_color(_row_fill);
            draw_roundrect_ext(
                _x1 + _padding,
                _draw_y + 2 * _ui_scale,
                _x2 - _padding,
                _row_y2,
                5,
                5,
                false
            );

            draw_set_halign(fa_left);
            draw_set_color(make_color_rgb(50, 38, 28));
            draw_text_ext_transformed(
                _x1 + _padding * 1.6,
                _draw_y + 7 * _ui_scale,
                _item.name,
                16 * _ui_scale,
                300 * _ui_scale,
                0.70 * _ui_scale,
                0.76 * _ui_scale,
                0
            );

            draw_set_halign(fa_center);
            draw_set_color(make_color_rgb(84, 68, 54));
            draw_text_transformed(
                _x2 - 95 * _ui_scale,
                _draw_y + _row_h * 0.5,
                string(_item.quantity),
                0.70 * _ui_scale,
                0.76 * _ui_scale,
                0
            );

            draw_set_halign(fa_right);
            draw_set_color(make_color_rgb(148, 74, 64));
            draw_text_transformed(
                _x2 - _padding * 1.6,
                _draw_y + _row_h * 0.5,
                "$ " + string(_item.total),
                0.76 * _ui_scale,
                0.82 * _ui_scale,
                0
            );

            _draw_y += _row_h;
        }
    }

    draw_set_color(make_color_rgb(180, 160, 140));
    draw_line(
        _x1 + _padding,
        _rows_y2 + 4 * _ui_scale,
        _x2 - _padding,
        _rows_y2 + 4 * _ui_scale
    );

    var _paid = variable_instance_exists(_owner, "finance_bill_paid")
        && _owner.finance_bill_paid;

    draw_set_halign(fa_left);
    draw_set_color(make_color_rgb(74, 49, 31));
    draw_text_transformed(
        _x1 + _padding,
        _y2 - 25 * _ui_scale,
        _paid ? "ОПЛАЧЕНО" : "К ОПЛАТЕ",
        0.92 * _ui_scale,
        0.98 * _ui_scale,
        0
    );

    draw_set_halign(fa_right);
    draw_set_color(_paid
        ? make_color_rgb(62, 112, 74)
        : make_color_rgb(148, 74, 64));
    draw_text_transformed(
        _x2 - _padding,
        _y2 - 25 * _ui_scale,
        "$ " + string(_invoice.total),
        1.14 * _ui_scale,
        1.20 * _ui_scale,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ═══════════════════════════════════════════════════════════════
// 4. ЗАРПЛАТА ПО НАВЫКАМ
// ═══════════════════════════════════════════════════════════════

function finance_average_levels(_levels) {
    if (!is_array(_levels)) return 1;
    if (array_length(_levels) <= 0) return 1;

    var _sum = 0;

    for (var _index = 0; _index < array_length(_levels); _index++) {
        _sum += clamp(real(_levels[_index]), 1, 10);
    }

    return _sum / array_length(_levels);
}

function finance_staff_professional_average(_staff) {
    if (!instance_exists(_staff)) return 1;

    var _role = variable_instance_exists(_staff, "role")
        ? string(_staff.role)
        : "";

    if (_role == "admin") {
        if (
            variable_instance_exists(_staff, "skill_level")
            && is_array(_staff.skill_level)
            && array_length(_staff.skill_level) >= 2
        ) {
            return finance_average_levels(_staff.skill_level);
        }

        if (
            variable_instance_exists(_staff, "skills")
            && is_array(_staff.skills)
            && array_length(_staff.skills) >= 2
        ) {
            return finance_average_levels([
                _staff.skills[0],
                _staff.skills[1]
            ]);
        }
    }

    if (_role == "assistant") {
        if (
            variable_instance_exists(_staff, "assistant_skill_levels")
            && is_array(_staff.assistant_skill_levels)
            && array_length(_staff.assistant_skill_levels) > 0
        ) {
            return finance_average_levels(_staff.assistant_skill_levels);
        }

        if (
            variable_instance_exists(_staff, "skills")
            && is_array(_staff.skills)
            && array_length(_staff.skills) >= 8
        ) {
            return finance_average_levels([
                _staff.skills[1],
                _staff.skills[4],
                _staff.skills[7]
            ]);
        }
    }

    if (
        variable_instance_exists(_staff, "skills")
        && is_array(_staff.skills)
        && array_length(_staff.skills) > 0
    ) {
        return finance_average_levels(_staff.skills);
    }

    return 1;
}

function finance_calculate_staff_salary(_staff) {
    if (!instance_exists(_staff)) return 0;
    if (_staff.object_index == obj_player) return 0;

    var _role = variable_instance_exists(_staff, "role")
        ? string(_staff.role)
        : "";
    var _professional = finance_staff_professional_average(_staff);
    var _walk = variable_instance_exists(_staff, "walk_skill_level")
        ? clamp(_staff.walk_skill_level, 1, 10)
        : 1;
    var _stamina = variable_instance_exists(_staff, "stamina_level")
        ? clamp(_staff.stamina_level, 1, 10)
        : 1;
    var _common_average = (_walk + _stamina) * 0.5;
    var _base = 70;
    var _professional_rate = 16;

    switch (_role) {
        case "doctor":
            _base = 120;
            _professional_rate = 28;
        break;

        case "admin":
            _base = 80;
            _professional_rate = 18;
        break;

        case "assistant":
            _base = 70;
            _professional_rate = 16;
        break;
    }

    var _salary = _base
        + _professional * _professional_rate
        + _common_average * 4;

    return max(0, round(_salary / 5) * 5);
}

function finance_refresh_staff_salary(_staff) {
    if (!instance_exists(_staff)) return 0;

    var _salary = finance_calculate_staff_salary(_staff);

    if (_staff.object_index == obj_staff_candidate) {
        _staff.salary_expected = _salary;
    }
    else if (_staff.object_index != obj_player) {
        _staff.salary = _salary;
    }

    return _salary;
}


// ═══════════════════════════════════════════════════════════════
// 5. ЕЖЕДНЕВНАЯ ВЫПЛАТА ЗАРПЛАТ
// ═══════════════════════════════════════════════════════════════

function finance_payroll_add_object(_object_type, _lines) {
    for (
        var _index = 0;
        _index < instance_number(_object_type);
        _index++
    ) {
        var _staff = instance_find(_object_type, _index);
        if (!instance_exists(_staff)) continue;
        if (_staff.object_index != _object_type) continue;

        var _salary = finance_refresh_staff_salary(_staff);

        array_push(_lines, {
            staff : _staff,
            name : variable_instance_exists(_staff, "char_name")
                ? string(_staff.char_name)
                : "Сотрудник",
            role : variable_instance_exists(_staff, "role")
                ? string(_staff.role)
                : "staff",
            amount : _salary
        });
    }

    return _lines;
}

function finance_payroll_process_day(_game_day) {
    if (!variable_global_exists("finance_last_payroll_day")) {
        global.finance_last_payroll_day = -1;
    }

    if (global.finance_last_payroll_day == _game_day) {
        return false;
    }

    global.finance_last_payroll_day = _game_day;

    var _lines = [];
    _lines = finance_payroll_add_object(obj_staff_doctor, _lines);
    _lines = finance_payroll_add_object(obj_staff_admin, _lines);
    _lines = finance_payroll_add_object(obj_staff_assistant, _lines);

    var _total = 0;

    for (var _index = 0; _index < array_length(_lines); _index++) {
        _total += _lines[_index].amount;
    }

    if (!variable_global_exists("clinic_money")) {
        global.clinic_money = 0;
    }

    // Зарплата выплачивается полностью; баланс может стать отрицательным.
    global.clinic_money -= _total;

    global.finance_last_payroll_total = _total;
    global.finance_last_payroll_lines = _lines;

    if (
        variable_global_exists("daily_stats")
        && is_struct(global.daily_stats)
    ) {
        if (!variable_struct_exists(global.daily_stats, "spent_money")) {
            global.daily_stats.spent_money = 0;
        }
        if (!variable_struct_exists(global.daily_stats, "salary_expense")) {
            global.daily_stats.salary_expense = 0;
        }

        global.daily_stats.spent_money += _total;
        global.daily_stats.salary_expense += _total;
    }

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 6. РЕДАКТИРУЕМЫЙ ПРАЙС-ЛИСТ В ПАНЕЛИ «ФИНАНСЫ»
// ═══════════════════════════════════════════════════════════════

function finance_frosted_fill(_x1, _y1, _x2, _y2, _radius) {
    // Пакет №118: имитация матового стекла — полупрозрачная холодная
    // заливка поверх мира + мягкий белый блик сверху (без шейдера).

    draw_set_alpha(0.55);
    draw_set_color(make_color_rgb(243, 246, 250));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, _radius, _radius, false);

    draw_set_alpha(0.30);
    draw_set_color(c_white);
    var _glow_h = max(6, min(26, (_y2 - _y1) * 0.25));
    draw_roundrect_ext(
        _x1 + 3, _y1 + 3,
        _x2 - 3, _y1 + 3 + _glow_h,
        _radius, _radius, false
    );

    draw_set_alpha(1);
}

// Деревянная рамка ТОЛЬКО по краю (круги в углах + полосы по сторонам).
// Центр остаётся прозрачным — через него виден мир, а не сплошное дерево.
function finance_draw_wood_frame(_x1, _y1, _x2, _y2, _th, _rad) {
    var _wd = make_color_rgb(74, 49, 31);
    var _wm = make_color_rgb(114, 77, 50);
    var _wl = make_color_rgb(150, 107, 73);

    draw_set_color(_wm);

    // Углы (четверти круга).
    draw_circle(_x1 + _th, _y1 + _th, _th, false);
    draw_circle(_x2 - _th, _y1 + _th, _th, false);
    draw_circle(_x1 + _th, _y2 - _th, _th, false);
    draw_circle(_x2 - _th, _y2 - _th, _th, false);

    // Полосы по сторонам.
    draw_rectangle(_x1 + _th, _y1, _x2 - _th, _y1 + _th, false);
    draw_rectangle(_x1 + _th, _y2 - _th, _x2 - _th, _y2, false);
    draw_rectangle(_x1, _y1 + _th, _x1 + _th, _y2 - _th, false);
    draw_rectangle(_x2 - _th, _y1 + _th, _x2, _y2 - _th, false);

    // Тёмная внешняя кромка.
    draw_set_color(_wd);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, _rad, _rad, true);

    // Светлая полоска по внутреннему краю.
    draw_set_color(_wl);
    draw_roundrect_ext(
        _x1 + _th, _y1 + _th,
        _x2 - _th, _y2 - _th,
        _th, _th, true
    );
}

function finance_ui_draw_outer_panel(_x1, _y1, _x2, _y2) {
    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(_x1 + 4, _y1 + 6, _x2 + 4, _y2 + 6, 18, 18, false);
    draw_set_alpha(1);

    // Пакет №118: матовое стекло ПОВЕРХ мира (центр прозрачный).
    finance_frosted_fill(_x1 + 12, _y1 + 12, _x2 - 12, _y2 - 12, 12);

    // Деревянная рамка только по краю.
    finance_draw_wood_frame(_x1, _y1, _x2, _y2, 12, 12);
}

function finance_ui_draw_button(
    _x1,
    _y1,
    _x2,
    _y2,
    _text,
    _selected,
    _hovered,
    _danger = false
) {
    var _fill = _danger
        ? (_hovered ? make_color_rgb(242, 211, 203) : make_color_rgb(229, 194, 185))
        : (_selected
            ? make_color_rgb(205, 224, 193)
            : (_hovered ? make_color_rgb(224, 238, 248) : make_color_rgb(225, 216, 199)));
    var _line = _danger
        ? make_color_rgb(148, 82, 72)
        : (_selected ? make_color_rgb(104, 137, 91) : make_color_rgb(104, 135, 160));

    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 7, 7, false);
    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 7, 7, true);
    // Пакет №177: крупный текст кнопки с автоподгонкой.
    draw_set_color(make_color_rgb(50, 38, 28));
    ui_text_fit_center(
        (_x1 + _x2) * 0.5,
        (_y1 + _y2) * 0.5,
        _text,
        (_x2 - _x1) - 16,
        UI_FS_BUTTON
    );
}

function finance_ui_pointer_pressed() {
    return mouse_check_button_pressed(mb_left)
        || device_mouse_check_button_pressed(0, mb_left);
}

function finance_ui_pointer_down() {
    return mouse_check_button(mb_left)
        || device_mouse_check_button(0, mb_left);
}

function finance_ui_pointer_released() {
    return mouse_check_button_released(mb_left)
        || device_mouse_check_button_released(0, mb_left);
}

function finance_ui_draw_overview(_hud, _x1, _y1, _x2, _y2) {
    var _balance = variable_global_exists("clinic_money")
        ? global.clinic_money
        : 0;
    var _earned = 0;
    var _spent = 0;
    var _salary = 0;

    if (variable_global_exists("daily_stats") && is_struct(global.daily_stats)) {
        if (variable_struct_exists(global.daily_stats, "earned_money")) {
            _earned = global.daily_stats.earned_money;
        }
        if (variable_struct_exists(global.daily_stats, "spent_money")) {
            _spent = global.daily_stats.spent_money;
        }
        if (variable_struct_exists(global.daily_stats, "salary_expense")) {
            _salary = global.daily_stats.salary_expense;
        }
    }

    var _gap = 12;
    var _card_w = (_x2 - _x1 - _gap * 2) / 3;
    var _labels = ["БАЛАНС КЛИНИКИ", "ДОХОД СЕГОДНЯ", "РАСХОД СЕГОДНЯ"];
    var _values = [_balance, _earned, _spent];

    for (var _index = 0; _index < 3; _index++) {
        var _cx1 = _x1 + _index * (_card_w + _gap);
        var _cx2 = _cx1 + _card_w;

        draw_set_color(make_color_rgb(248, 240, 224));
        draw_roundrect_ext(_cx1, _y1, _cx2, _y1 + 282, 10, 10, false);
        draw_set_color(make_color_rgb(180, 160, 140));
        draw_roundrect_ext(_cx1, _y1, _cx2, _y1 + 282, 10, 10, true);
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_set_color(make_color_rgb(84, 68, 54));
        ui_text_fit_center((_cx1 + _cx2) * 0.5, _y1 + 34, _labels[_index], _card_w - 24, UI_FS_HEADER);
        draw_set_color((_index == 2)
            ? make_color_rgb(148, 74, 64)
            : make_color_rgb(62, 112, 74));
        draw_text_transformed(
            (_cx1 + _cx2) * 0.5,
            _y1 + 96,
            "$ " + string(round(_values[_index])),
            2.60,
            2.60,
            0
        );
        // Дополнительные строки внутри карточек доход/расход
        if (_index == 1) {
            var _adm = max(0, round(_earned * 0.45));
            var _stat = max(0, round(_earned * 0.30));
            var _op = max(0, round(_earned - _adm - _stat));
            draw_set_halign(fa_left);
            draw_set_color(make_color_rgb(84, 68, 54));
            // Пакет №176: крупнее, шаг строк увеличен с 25 до 38.
            draw_text_transformed(_cx1 + 16, _y1 + 164, "Приём: $ " + string(_adm), UI_FS_VALUE, UI_FS_VALUE, 0);
            draw_text_transformed(_cx1 + 16, _y1 + 196, "Стационар: $ " + string(_stat), UI_FS_VALUE, UI_FS_VALUE, 0);
            draw_text_transformed(_cx1 + 16, _y1 + 228, "Операционная: $ " + string(_op), UI_FS_VALUE, UI_FS_VALUE, 0);
        }
        if (_index == 2) {
            var _projected_salary = 0;
            with (obj_staff_doctor) _projected_salary += finance_calculate_staff_salary(id);
            with (obj_staff_admin) _projected_salary += finance_calculate_staff_salary(id);
            with (obj_staff_assistant) _projected_salary += finance_calculate_staff_salary(id);
            var _pur = max(0, round(_spent - _salary));
            draw_set_halign(fa_left);
            draw_set_color(make_color_rgb(148, 74, 64));
            draw_text_transformed(_cx1 + 16, _y1 + 164, "Зарплаты: $ " + string(round(_projected_salary)), UI_FS_VALUE, UI_FS_VALUE, 0);
            draw_text_transformed(_cx1 + 16, _y1 + 196, "Закупка: $ " + string(round(_pur)), UI_FS_VALUE, UI_FS_VALUE, 0);
        }
    }

}
function finance_ui_draw_scrollbar(
    _hud,
    _right_x,
    _y1,
    _y2,
    _total,
    _visible,
    _mouse_x,
    _mouse_y
) {
    var _max_scroll = max(0, _total - _visible);
    if (_max_scroll <= 0) return;

    if (!variable_instance_exists(_hud, "finance_sb_drag")) {
        _hud.finance_sb_drag = false;
        _hud.finance_sb_grab_off = 0;
    }

    var _track_y1 = _y1 + 2;
    var _track_y2 = _y2 - 2;
    var _track_h = max(12, _track_y2 - _track_y1);
    var _thumb_h = max(36, _track_h * (_visible / _total));
    var _thumb_range = _track_h - _thumb_h;

    var _track_x1 = _right_x - 10;
    var _track_x2 = _right_x;

    var _thumb_y = _track_y1 + _thumb_range
        * (_hud.finance_price_scroll / _max_scroll);

    var _pressed = finance_ui_pointer_pressed();
    var _down = finance_ui_pointer_down();

    // Захват бегунка.
    if (
        _pressed
        && point_in_rectangle(
            _mouse_x, _mouse_y,
            _track_x1 - 4, _thumb_y,
            _track_x2 + 4, _thumb_y + _thumb_h
        )
    ) {
        _hud.finance_sb_drag = true;
        _hud.finance_sb_grab_off = _mouse_y - _thumb_y;
    }
    else if (
        _pressed
        && point_in_rectangle(
            _mouse_x, _mouse_y,
            _track_x1, _track_y1,
            _track_x2, _track_y2
        )
    ) {
        // Клик по треку — прыжок к месту.
        _hud.finance_sb_drag = true;
        _hud.finance_sb_grab_off = _thumb_h * 0.5;
    }

    if (_hud.finance_sb_drag) {
        if (_down) {
            var _new_top = _mouse_y - _hud.finance_sb_grab_off;
            var _ratio = clamp(
                (_new_top - _track_y1) / max(1, _thumb_range),
                0,
                1
            );
            _hud.finance_price_scroll = round(_ratio * _max_scroll);
        }
        else {
            _hud.finance_sb_drag = false;
        }
    }

    _hud.finance_price_scroll = clamp(
        _hud.finance_price_scroll,
        0,
        _max_scroll
    );

    var _thumb_y_final = _track_y1 + _thumb_range
        * (_hud.finance_price_scroll / max(1, _max_scroll));

    // Трек.
    draw_set_color(make_color_rgb(222, 210, 190));
    draw_roundrect_ext(_track_x1, _track_y1, _track_x2, _track_y2, 5, 5, false);
    draw_set_color(make_color_rgb(168, 150, 130));
    draw_roundrect_ext(_track_x1, _track_y1, _track_x2, _track_y2, 5, 5, true);

    // Бегунок.
    draw_set_color(make_color_rgb(150, 107, 73));
    draw_roundrect_ext(
        _track_x1 - 3, _thumb_y_final,
        _track_x2 + 3, _thumb_y_final + _thumb_h,
        6, 6, false
    );
    draw_set_color(make_color_rgb(74, 49, 31));
    draw_roundrect_ext(
        _track_x1 - 3, _thumb_y_final,
        _track_x2 + 3, _thumb_y_final + _thumb_h,
        6, 6, true
    );
}

function finance_ui_prepare_scroll(
    _hud,
    _entry_count,
    _visible_rows,
    _rows_x1,
    _rows_y1,
    _rows_x2,
    _rows_y2,
    _mouse_x,
    _mouse_y
) {
    if (!variable_instance_exists(_hud, "finance_price_scroll")) {
        _hud.finance_price_scroll = 0;
        _hud.finance_price_touch_active = false;
        _hud.finance_price_touch_last_y = 0;
        _hud.finance_price_touch_accum = 0;
    }

    var _inside_rows = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _rows_x1,
        _rows_y1,
        _rows_x2,
        _rows_y2
    );

    if (_inside_rows) {
        if (mouse_wheel_down()) _hud.finance_price_scroll += 1;
        if (mouse_wheel_up()) _hud.finance_price_scroll -= 1;
    }

    var _pressed = finance_ui_pointer_pressed();
    var _down = finance_ui_pointer_down();
    var _released = finance_ui_pointer_released();

    // Правая часть строк занята кнопками изменения цены.
    if (_pressed && _inside_rows && _mouse_x < _rows_x2 - 150) {
        _hud.finance_price_touch_active = true;
        _hud.finance_price_touch_last_y = _mouse_y;
        _hud.finance_price_touch_accum = 0;
    }

    if (_hud.finance_price_touch_active) {
        if (_down) {
            var _delta = _mouse_y - _hud.finance_price_touch_last_y;
            _hud.finance_price_touch_accum += _delta;

            while (_hud.finance_price_touch_accum <= -34) {
                _hud.finance_price_scroll += 1;
                _hud.finance_price_touch_accum += 34;
            }

            while (_hud.finance_price_touch_accum >= 34) {
                _hud.finance_price_scroll -= 1;
                _hud.finance_price_touch_accum -= 34;
            }

            _hud.finance_price_touch_last_y = _mouse_y;
        }

        if (_released || !_down) {
            _hud.finance_price_touch_active = false;
            _hud.finance_price_touch_accum = 0;
        }
    }

    _hud.finance_price_scroll = clamp(
        _hud.finance_price_scroll,
        0,
        max(0, _entry_count - _visible_rows)
    );
}

function finance_ui_draw_service_prices(
    _hud,
    _x1,
    _y1,
    _x2,
    _y2,
    _mouse_x,
    _mouse_y
) {
    var _entries = finance_get_service_entries();
    var _row_h = 86;
    var _font = 1.70;
    var _visible_rows = max(1, floor((_y2 - _y1 - 34) / _row_h));

    finance_ui_prepare_scroll(
        _hud,
        array_length(_entries),
        _visible_rows,
        _x1,
        _y1 + 34,
        _x2 - 22,
        _y2,
        _mouse_x,
        _mouse_y
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(84, 68, 54));
    draw_text_transformed(_x1 + 14, _y1 + 20, "УСЛУГА", 1.80, 1.80, 0);
    draw_set_halign(fa_right);
    draw_text_transformed(_x2 - 30, _y1 + 20, "ЦЕНА ДЛЯ КЛИЕНТА", 1.80, 1.80, 0);

    var _draw_y = _y1 + 34;
    var _last = min(
        array_length(_entries),
        _hud.finance_price_scroll + _visible_rows
    );
    var _pressed = finance_ui_pointer_pressed();

    for (var _index = _hud.finance_price_scroll; _index < _last; _index++) {
        var _entry = _entries[_index];
        var _price = finance_service_price_get(_entry.id, 0);

        // Правая зона: [−] [цена] [+] и бегунок у самого края.
        var _minus_x2 = _x2 - 190;
        var _minus_x1 = _minus_x2 - 40;
        var _plus_x2 = _x2 - 52;
        var _plus_x1 = _plus_x2 - 40;
        var _price_right = _plus_x1 - 10;

        var _button_y1 = _draw_y + 9;
        var _button_y2 = _draw_y + 49;

        var _minus_hover = point_in_rectangle(
            _mouse_x, _mouse_y,
            _minus_x1, _button_y1,
            _minus_x2, _button_y2
        );
        var _plus_hover = point_in_rectangle(
            _mouse_x, _mouse_y,
            _plus_x1, _button_y1,
            _plus_x2, _button_y2
        );

        draw_set_color((_index mod 2 == 0)
            ? make_color_rgb(248, 240, 224)
            : make_color_rgb(239, 231, 216));
        draw_roundrect_ext(
            _x1 + 4, _draw_y + 2,
            _x2 - 20, _draw_y + 55,
            7, 7, false
        );

        draw_set_halign(fa_left);
        draw_set_color(make_color_rgb(50, 38, 28));
        draw_text_transformed(
            _x1 + 18, _draw_y + 16,
            _entry.name,
            _font, _font, 0
        );
        draw_set_color(make_color_rgb(104, 135, 160));
        draw_text_transformed(
            _x1 + 18, _draw_y + 52,
            _entry.group,
            UI_FS_ROW, UI_FS_ROW, 0
        );

        draw_set_halign(fa_right);
        draw_set_color(make_color_rgb(148, 74, 64));
        draw_text_transformed(
            _price_right, _draw_y + 34,
            "$ " + string(_price),
            _font, _font, 0
        );

        finance_ui_draw_button(
            _minus_x1, _button_y1, _minus_x2, _button_y2,
            "-", false, _minus_hover
        );
        finance_ui_draw_button(
            _plus_x1, _button_y1, _plus_x2, _button_y2,
            "+", false, _plus_hover
        );

        if (_pressed) {
            if (_minus_hover) finance_service_price_set(_entry.id, _price - 5);
            if (_plus_hover) finance_service_price_set(_entry.id, _price + 5);
        }

        _draw_y += _row_h;
    }

    finance_ui_draw_scrollbar(
        _hud,
        _x2 - 6,
        _y1 + 34,
        _y2 - 4,
        array_length(_entries),
        _visible_rows,
        _mouse_x,
        _mouse_y
    );
}

function finance_ui_draw_medicine_prices(
    _hud,
    _x1,
    _y1,
    _x2,
    _y2,
    _mouse_x,
    _mouse_y
) {
    var _item_ids = finance_get_item_ids();
    var _row_h = 88;
    var _font = 1.70;
    var _visible_rows = max(1, floor((_y2 - _y1 - 34) / _row_h));

    finance_ui_prepare_scroll(
        _hud,
        array_length(_item_ids),
        _visible_rows,
        _x1,
        _y1 + 34,
        _x2 - 22,
        _y2,
        _mouse_x,
        _mouse_y
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(84, 68, 54));
    draw_text_transformed(_x1 + 14, _y1 + 20, "ПРЕПАРАТ", 1.80, 1.80, 0);
    draw_set_halign(fa_right);
    draw_text_transformed(_x2 - 30, _y1 + 20, "ЗАКУПКА / ПРОДАЖА", 1.80, 1.80, 0);

    var _draw_y = _y1 + 34;
    var _last = min(
        array_length(_item_ids),
        _hud.finance_price_scroll + _visible_rows
    );
    var _pressed = finance_ui_pointer_pressed();

    for (var _index = _hud.finance_price_scroll; _index < _last; _index++) {
        var _item_id = string(_item_ids[_index]);
        var _purchase = finance_get_item_purchase_price(_item_id);
        var _sale = finance_get_item_sale_price(_item_id);

        // Правая зона: [−] [цена продажи] [+] и бегунок у самого края.
        var _minus_x2 = _x2 - 190;
        var _minus_x1 = _minus_x2 - 40;
        var _plus_x2 = _x2 - 52;
        var _plus_x1 = _plus_x2 - 40;
        var _sale_right = _plus_x1 - 10;
        var _purchase_right = _minus_x1 - 12;

        var _button_y1 = _draw_y + 10;
        var _button_y2 = _draw_y + 50;

        var _minus_hover = point_in_rectangle(
            _mouse_x, _mouse_y,
            _minus_x1, _button_y1,
            _minus_x2, _button_y2
        );
        var _plus_hover = point_in_rectangle(
            _mouse_x, _mouse_y,
            _plus_x1, _button_y1,
            _plus_x2, _button_y2
        );

        draw_set_color((_index mod 2 == 0)
            ? make_color_rgb(248, 240, 224)
            : make_color_rgb(239, 231, 216));
        draw_roundrect_ext(
            _x1 + 4, _draw_y + 2,
            _x2 - 20, _draw_y + 57,
            7, 7, false
        );

        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(50, 38, 28));
        draw_text_transformed(
            _x1 + 18, _draw_y + 32,
            item_get_name(_item_id),
            _font, _font, 0
        );

        draw_set_halign(fa_right);
        draw_set_color(make_color_rgb(148, 74, 64));
        draw_text_transformed(
            _purchase_right, _draw_y + 34,
            "закупка $ " + string(_purchase),
            UI_FS_VALUE, UI_FS_VALUE, 0
        );
        draw_set_color(make_color_rgb(148, 74, 64));
        draw_text_transformed(
            _sale_right, _draw_y + 34,
            "$ " + string(_sale),
            _font, _font, 0
        );

        finance_ui_draw_button(
            _minus_x1, _button_y1, _minus_x2, _button_y2,
            "-", false, _minus_hover
        );
        finance_ui_draw_button(
            _plus_x1, _button_y1, _plus_x2, _button_y2,
            "+", false, _plus_hover
        );

        if (_pressed) {
            if (_minus_hover) finance_set_item_sale_price(_item_id, _sale - 5);
            if (_plus_hover) finance_set_item_sale_price(_item_id, _sale + 5);
        }

        _draw_y += _row_h;
    }

    finance_ui_draw_scrollbar(
        _hud,
        _x2 - 6,
        _y1 + 34,
        _y2 - 4,
        array_length(_item_ids),
        _visible_rows,
        _mouse_x,
        _mouse_y
    );
}

function hud_draw_finance_price_panel(_hud) {
    if (!instance_exists(_hud)) return;
    if (!_hud.visible) return;
    if (!variable_instance_exists(_hud, "finance_manage_panel_open")) return;
    if (!_hud.finance_manage_panel_open) return;

    finance_price_catalog_init();

    if (!variable_instance_exists(_hud, "finance_price_tab")) {
        _hud.finance_price_tab = "overview";
        _hud.finance_price_scroll = 0;
    }

    if (font_exists(fnt_main)) draw_set_font(fnt_main);

    var _mouse_x = device_mouse_x_to_gui(0);
    var _mouse_y = device_mouse_y_to_gui(0);
    var _gui_w = display_get_gui_width();
    var _gui_h = display_get_gui_height();
    var _top = variable_instance_exists(_hud, "hud_top_h")
        ? _hud.hud_top_h + 10
        : 14;
    var _bottom = (
        variable_instance_exists(_hud, "bottombar_y1")
        && _hud.bottombar_y1 > _top + 300
    ) ? _hud.bottombar_y1 - 10 : _gui_h - 14;
    var _panel_w = min(1120, _gui_w - 28);
    var _panel_h = min(720, _bottom - _top);
    var _x1 = (_gui_w - _panel_w) * 0.5;
    var _y1 = _top + (_bottom - _top - _panel_h) * 0.5;
    var _x2 = _x1 + _panel_w;
    var _y2 = _y1 + _panel_h;

    finance_ui_draw_outer_panel(_x1, _y1, _x2, _y2);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(74, 49, 31));
    draw_text_transformed(_x1 + 24, _y1 + 22, "ФИНАНСЫ И ПРАЙС-ЛИСТ", UI_FS_TITLE, UI_FS_TITLE, 0);

    var _tabs = [
        { id : "overview", text : "ОБЗОР" },
        { id : "services", text : "УСЛУГИ" },
        { id : "medicines", text : "ПРЕПАРАТЫ" }
    ];
    // Пакет №177: вкладки крупнее, места хватает.
    // Пакет №178: блок вкладок прижат влево и никогда не наезжает на крестик —
    // его правый край считается от кнопки закрытия, а не задан числом.
    // Пакет №180: размер и зазор — из UI-кита, как у вкладок КЛИНИКИ.
    var _tab_y1 = _y1 + 16;
    var _tab_y2 = _tab_y1 + UI_TAB_H;
    var _tab_w = UI_TAB_W;
    var _tab_gap = UI_TAB_GAP;

    var _tabs_total = 3 * _tab_w + 2 * _tab_gap;

    // Пакет №179: зазор до крестика = зазору между кнопками (_tab_gap).
    // Блок вкладок прижимается к кнопке закрытия, промежутки одинаковые:
    //   [ОБЗОР] 10 [УСЛУГИ] 10 [ПРЕПАРАТЫ] 10 [X]
    // Крестик такого же размера, как вкладка по высоте.
    var _close_size = UI_TAB_H;
    var _tab_x = (_x2 - 20 - _close_size) - _tab_gap - _tabs_total;

    // Но и на заголовок «ФИНАНСЫ И ПРАЙС-ЛИСТ» тоже не наезжаем.
    _tab_x = max(
        _x1 + 24 + string_width("ФИНАНСЫ И ПРАЙС-ЛИСТ") * UI_FS_TITLE + 30,
        _tab_x
    );
    var _pressed = finance_ui_pointer_pressed();

    for (var _tab_index = 0; _tab_index < array_length(_tabs); _tab_index++) {
        var _tab = _tabs[_tab_index];
        var _tx1 = _tab_x + _tab_index * (_tab_w + _tab_gap);
        var _tx2 = _tx1 + _tab_w;
        var _hover = point_in_rectangle(_mouse_x, _mouse_y, _tx1, _tab_y1, _tx2, _tab_y2);

        ui_draw_tab(
            _tx1,
            _tab_y1,
            _tx2,
            _tab_y2,
            _tab.text,
            _hud.finance_price_tab == _tab.id,
            _hover
        );

        if (_pressed && _hover) {
            _hud.finance_price_tab = _tab.id;
            _hud.finance_price_scroll = 0;
            _hud.finance_price_touch_active = false;
        }
    }

    var _close_x2 = _x2 - 20;
    var _close_x1 = _close_x2 - _close_size;
    var _close_y1 = _tab_y1;
    var _close_y2 = _close_y1 + _close_size;
    var _close_hover = point_in_rectangle(
        _mouse_x,
        _mouse_y,
        _close_x1,
        _close_y1,
        _close_x2,
        _close_y2
    );

    ui_draw_close_button(
        _close_x1,
        _close_y1,
        _close_x2,
        _close_y2,
        _close_hover
    );

    if (_pressed && _close_hover) {
        _hud.finance_manage_panel_open = false;
        _hud.finance_manage_draw_requested = false;
        _hud.finance_price_touch_active = false;
    }

    var _content_x1 = _x1 + 22;
    var _content_y1 = _y1 + 104;
    var _content_x2 = _x2 - 22;
    var _content_y2 = _y2 - 22;

    // Пакет №118: контентная область — матовое стекло (было — белая бумага).
    finance_frosted_fill(
        _content_x1,
        _content_y1,
        _content_x2,
        _content_y2,
        10
    );
    draw_set_color(make_color_rgb(180, 160, 140));
    draw_roundrect_ext(
        _content_x1,
        _content_y1,
        _content_x2,
        _content_y2,
        10,
        10,
        true
    );

    switch (_hud.finance_price_tab) {
        case "services":
            finance_ui_draw_service_prices(
                _hud,
                _content_x1 + 8,
                _content_y1 + 8,
                _content_x2 - 8,
                _content_y2 - 8,
                _mouse_x,
                _mouse_y
            );
        break;

        case "medicines":
            finance_ui_draw_medicine_prices(
                _hud,
                _content_x1 + 8,
                _content_y1 + 8,
                _content_x2 - 8,
                _content_y2 - 8,
                _mouse_x,
                _mouse_y
            );
        break;

        default:
            finance_ui_draw_overview(
                _hud,
                _content_x1 + 12,
                _content_y1 + 12,
                _content_x2 - 12,
                _content_y2 - 12
            );
    }

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);
}
