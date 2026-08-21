function db_get_diagnostic_name(_diag_id) {

    if (!variable_global_exists("med_db")) return "Неизвестная диагностика";
    if (!is_struct(global.med_db)) return "Неизвестная диагностика";
    if (!variable_struct_exists(global.med_db, "diagnostics")) return "Неизвестная диагностика";
    if (!variable_struct_exists(global.med_db.diagnostics, _diag_id)) return "Неизвестная диагностика";

    var _d = variable_struct_get(global.med_db.diagnostics, _diag_id);

    if (variable_struct_exists(_d, "name_ru")) {
        return string(_d.name_ru);
    }

    return "Неизвестная диагностика";
}