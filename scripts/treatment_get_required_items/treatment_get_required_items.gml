function treatment_get_required_items(_action_id) {
    var _empty = [];

    if (!variable_global_exists("med_db")) return _empty;
    if (!is_struct(global.med_db)) return _empty;
    if (!variable_struct_exists(global.med_db, "treatment_actions")) return _empty;
    if (!variable_struct_exists(global.med_db.treatment_actions, _action_id)) return _empty;

    var _act = variable_struct_get(global.med_db.treatment_actions, _action_id);

    if (!variable_struct_exists(_act, "required_items")) return _empty;

    return _act.required_items;
}