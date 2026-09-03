function db_pick_random_disease_for_species(_species_id) {

    // ══════════════════════════════════════════════════
    // Пакет №268: болезни теперь фильтруются по открытым помещениям.
    //
    // Пока нет операционной — не приходят болезни, требующие операции.
    // Пока не куплена ни одна койка — не приходят болезни, требующие
    // стационара. Вся логика живёт в новом скрипте clinic_case_gate.
    //
    // Старое тело функции оставлено ниже как запасной путь: если
    // скрипт clinic_case_gate вдруг не создан в IDE, игра продолжит
    // работать по-старому, а не упадёт.
    // ══════════════════════════════════════════════════

    if (script_exists(asset_get_index("clinic_case_pick_disease_for_species"))) {
        return clinic_case_pick_disease_for_species(_species_id);
    }

    var _pool = [];

    for (var i = 0; i < array_length(global.med_db.disease_ids); i++) {

        var _id = global.med_db.disease_ids[i];
        var _d = variable_struct_get(global.med_db.diseases, _id);

        if (db_species_match(_d.species, _species_id)) {
            array_push(_pool, _id);
        }
    }

    if (array_length(_pool) <= 0) {
        return "";
    }

    return _pool[irandom(array_length(_pool) - 1)];
}