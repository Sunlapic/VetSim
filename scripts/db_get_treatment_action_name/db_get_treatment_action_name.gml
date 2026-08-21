function db_get_treatment_action_name(_action_id) {

    if (!variable_global_exists("med_db")) return "Неизвестное лечение";
    if (!is_struct(global.med_db)) return "Неизвестное лечение";
    if (!variable_struct_exists(global.med_db, "treatment_actions")) return "Неизвестное лечение";
    if (!variable_struct_exists(global.med_db.treatment_actions, _action_id)) return "Неизвестное лечение";

    var _a = variable_struct_get(global.med_db.treatment_actions, _action_id);

    if (variable_struct_exists(_a, "name_ru")) {
        return string(_a.name_ru);
    }

    return "Неизвестное лечение";
}