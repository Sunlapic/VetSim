/// storage_visible_items.gml
/// @description Какие препараты показывает склад и какого он размера.
///              Пакет №311.
///
/// Здесь две связанные вещи:
///
///   1. Список препаратов, которые имеет смысл держать в этой клинике.
///      Без операционной чисто хирургические позиции не нужны — они
///      только занимают ячейки и мусорят в закупке.
///
///   2. Размер стеллажа. Он зависит от того, сколько препаратов реально
///      показывается: в маленькой клинике их меньше, значит и полки
///      могут быть меньше.


// ═══════════════════════════════════════════════════════════════
// 1. ЧИСТО ОПЕРАЦИОННЫЕ ПРЕПАРАТЫ
// ═══════════════════════════════════════════════════════════════

/// @function storage_item_is_surgery_only(_item_id)
/// @description true — препарат нужен ТОЛЬКО для операций.
///
/// Список короткий и выверенный. Я разобрал все 49 лечебных действий
/// и сравнил составы: у большинства «хирургических» расходников есть
/// вторая жизнь в обычном приёме.
///
///   антисептик      — обработка ран, гингивит, анальные железы
///   бинт            — перевязки на приёме
///   набор фиксации   — вправление без операции
///   кровоостанавливающее — носовое кровотечение
///   раствор для инфузий  — капельница в стационаре
///
/// Прятать их нельзя: пациент останется без лечения. Поэтому в списке
/// ровно три позиции, которые вне операционной не используются нигде.
function storage_item_is_surgery_only(_item_id) {
    switch (string(_item_id)) {
        case "item_anesthetic":    return true;  // наркоз
        case "item_surgical_kit":  return true;  // хирургический набор
        case "item_dental_paste":  return true;  // паста для УЗ-чистки
    }

    return false;
}


/// @function storage_clinic_has_operating()
/// @description Есть ли в текущей клинике рабочая операционная.
function storage_clinic_has_operating() {

    // Функция гейта уже умеет это проверять с учётом купленных
    // помещений — не дублируем логику.
    if (script_exists(asset_get_index("clinic_case_operating_ready"))) {
        return clinic_case_operating_ready();
    }

    // Запасной путь: просто наличие операционного стола в комнате.
    return instance_exists(obj_operating_table);
}


// ═══════════════════════════════════════════════════════════════
// 2. СПИСОК ВИДИМЫХ ПРЕПАРАТОВ
// ═══════════════════════════════════════════════════════════════

/// @function storage_visible_item_ids()
/// @description global.item_ids за вычетом ненужных этой клинике.
///
/// Результат кэшируется: список перебирается при каждой отрисовке
/// склада, а меняется он только при покупке операционной.
function storage_visible_item_ids() {

    if (!variable_global_exists("item_ids") || !is_array(global.item_ids)) {
        return [];
    }

    var _has_operating = storage_clinic_has_operating();

    // Кэш: пересобираем, только если изменился состав клиники или
    // сам список препаратов.
    var _signature = string(array_length(global.item_ids))
        + "|" + string(_has_operating);

    if (
        variable_global_exists("storage_visible_cache")
        && variable_global_exists("storage_visible_signature")
        && global.storage_visible_signature == _signature
        && is_array(global.storage_visible_cache)
    ) {
        return global.storage_visible_cache;
    }

    var _result = [];

    for (var _index = 0; _index < array_length(global.item_ids); _index++) {
        var _item_id = global.item_ids[_index];

        if (!_has_operating && storage_item_is_surgery_only(_item_id)) {
            continue;
        }

        array_push(_result, _item_id);
    }

    global.storage_visible_cache = _result;
    global.storage_visible_signature = _signature;

    return _result;
}


/// @function storage_visible_item_count()
function storage_visible_item_count() {
    return array_length(storage_visible_item_ids());
}


// ═══════════════════════════════════════════════════════════════
// 3. АДАПТИВНЫЙ РАЗМЕР СТЕЛЛАЖА
//
// Раньше склад был жёстко 12x4 ячейки при размере ячейки 75x60 —
// около 1180x310 пикселей. В большой клинике это смотрелось, в
// комнате с одним кабинетом занимало половину помещения.
//
// Теперь размер зависит от клиники. Определяем её «величину» по
// числу открытых смотровых кабинетов: это самый честный признак —
// именно он растёт вместе с клиникой.
// ═══════════════════════════════════════════════════════════════

/// @function storage_clinic_scale_step()
/// @description 0 — маленькая клиника, 1 — средняя, 2 — большая.
function storage_clinic_scale_step() {

    // ПАКЕТ №316: считаем УНИКАЛЬНЫЕ слоты, а не столы.
    //
    // Раньше складывались все открытые столы подряд. Если в комнате
    // стоят два стола с одинаковым exam_slot_id (например, у второго
    // забыли прописать слот в Creation Code), кабинетов насчитывалось
    // два — и склад брал размер средней клиники вместо маленькой.
    //
    // Кабинет определяется слотом, а не числом столов, поэтому
    // повторы отбрасываем.
    var _seen_slots = [];
    var _rooms = 0;

    // Считаем открытые смотровые столы. Закрытый кабинет держит
    // table_busy и в комнате скрыт (пакет 173), поэтому опираемся
    // на clinic_room_is_open, а не на само число объектов.
    if (
        script_exists(asset_get_index("clinic_room_is_open"))
        && instance_exists(obj_table)
    ) {
        var _count = instance_number(obj_table);

        for (var _index = 0; _index < _count; _index++) {
            var _table = instance_find(obj_table, _index);

            if (!instance_exists(_table)) continue;

            var _slot = variable_instance_exists(_table, "exam_slot_id")
                ? _table.exam_slot_id
                : 1;

            if (!clinic_room_is_open(_slot)) continue;

            var _already_counted = false;

            for (var _seen = 0; _seen < array_length(_seen_slots); _seen++) {
                if (_seen_slots[_seen] == _slot) {
                    _already_counted = true;
                    break;
                }
            }

            if (_already_counted) continue;

            array_push(_seen_slots, _slot);
            _rooms += 1;
        }
    }

    if (_rooms >= 3) return 2;
    if (_rooms == 2) return 1;

    return 0;
}


/// @function storage_shelf_layout()
/// @description Раскладка стеллажа под текущую клинику:
///              { cols, rows, cell_w, cell_h, scale }.
///
/// Числа подобраны так, чтобы в маленькой клинике площадь упала
/// примерно в пять раз, но подписи и коробочки остались читаемыми.
/// Поэтому уменьшается не только масштаб, но и раскладка: колонок
/// меньше, рядов больше — стеллаж становится компактным блоком, а
/// не длинной стеной.
function storage_shelf_layout() {

    var _step = storage_clinic_scale_step();
    var _needed = max(1, storage_visible_item_count());

    // Большая клиника — ровно как было: 1032x314 пикселей.
    if (_step >= 2) {
        return {
            cols : 12,
            rows : 4,
            cell_w : 75,
            cell_h : 60,
            pad : 22,
            gap_x : 8,
            gap_y : 10,
            box : 4,
            label_scale : 0.52
        };
    }

    // Средняя клиника: 618x246, площадь меньше в 2.1 раза.
    if (_step == 1) {
        return {
            cols : 9,
            rows : 5,
            cell_w : 56,
            cell_h : 40,
            pad : 14,
            gap_x : 6,
            gap_y : 7,
            box : 3,
            label_scale : 0.42
        };
    }

    // Маленькая клиника: 292x204 — площадь меньше в 5.4 раза.
    //
    // 7x6 = 42 ячейки. Видимых препаратов без операционной 39, всё
    // помещается с запасом. Если препаратов станет больше, рядов
    // добавится автоматически.
    //
    // Уменьшены не только ячейки, но и рамка с зазорами: на маленьком
    // стеллаже рамка в 22 пикселя съедала бы четверть ширины.
    var _cols = 7;
    var _rows = max(6, ceil(_needed / _cols));

    return {
        cols : _cols,
        rows : _rows,
        cell_w : 36,
        cell_h : 28,
        pad : 8,
        gap_x : 4,
        gap_y : 4,
        box : 2,
        label_scale : 0.30
    };
}


/// @function storage_layout_value(_key, _default)
/// @description Одно поле раскладки. Обёртка, чтобы функции размеров
///              ниже читались в одну строку.
function storage_layout_value(_key, _default) {
    var _layout = storage_shelf_layout();

    if (variable_struct_exists(_layout, _key)) {
        return variable_struct_get(_layout, _key);
    }

    return _default;
}


/// @function storage_purchase_item_ids()
/// @description Список препаратов для панели закупки.
///
/// Отдельное имя, а не прямой вызов storage_visible_item_ids: панель
/// обращается к списку пять раз за кадр (заголовок, прокрутка, строки,
/// счётчик), и читаться это должно так же коротко, как прежнее
/// global.item_ids.
///
/// Внутри тот же кэш, поэтому пять вызовов подряд стоят столько же,
/// сколько один: список пересобирается, только когда меняется состав
/// клиники.
function storage_purchase_item_ids() {
    return storage_visible_item_ids();
}
