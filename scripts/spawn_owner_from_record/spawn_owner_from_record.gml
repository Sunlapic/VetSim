/// spawn_owner_from_record(_owner_id, _pet_id, _scheduled_visit)
/// @description Создаёт повторного клиента из базы и восстанавливает medical case.

function spawn_owner_from_record(_owner_id, _pet_id, _scheduled_visit) {
    if (!variable_struct_exists(global.owner_db, _owner_id)) return noone;
    if (!variable_struct_exists(global.pet_db, _pet_id)) return noone;
    if (!is_struct(_scheduled_visit)) return noone;

    var _owner_record = variable_struct_get(global.owner_db, _owner_id);
    var _pet_record = variable_struct_get(global.pet_db, _pet_id);


    // ═══════════════════════════════════════════════════════════
    // 1. СОЗДАНИЕ И ВОССТАНОВЛЕНИЕ ВЛАДЕЛЬЦА
    // ═══════════════════════════════════════════════════════════

    var _owner = instance_create_layer(spawn_x, spawn_y, "Instances", obj_owner);

    if (!instance_exists(_owner)) return noone;

    db_apply_owner_record_to_instance(_owner_record, _owner);

    _owner.owner_record_id = _owner_id;
    _owner.pet_record_id = _pet_id;
    _owner.scheduled_visit_id = variable_struct_exists(_scheduled_visit, "scheduled_visit_id")
        ? _scheduled_visit.scheduled_visit_id
        : "";

    _owner.visit_type_id = variable_struct_exists(_scheduled_visit, "visit_type_id")
        ? _scheduled_visit.visit_type_id
        : "followup_doctor";

    _owner.visit_type_name_ru = variable_struct_exists(_scheduled_visit, "visit_type_name_ru")
        ? _scheduled_visit.visit_type_name_ru
        : "Повторный приём";

    _owner.visit_reason_ru = variable_struct_exists(_scheduled_visit, "reason")
        ? _scheduled_visit.reason
        : "Повторный визит";

    _owner.service_queue_type = (_owner.visit_type_id == "procedure_visit")
        ? "procedure"
        : "doctor";


    // ═══════════════════════════════════════════════════════════
    // 2. ВОССТАНОВЛЕНИЕ ПИТОМЦА
    // ═══════════════════════════════════════════════════════════

    if (instance_exists(_owner.my_pet)) {
        var _pet = _owner.my_pet;

        db_apply_pet_record_to_instance(_pet_record, _pet);
        _pet.my_owner = _owner;


        // ═══════════════════════════════════════════════════════
        // 3. ВОССТАНОВЛЕНИЕ МЕДИЦИНСКОГО СЛУЧАЯ
        // ═══════════════════════════════════════════════════════

        var _disease_id = variable_struct_exists(_scheduled_visit, "disease_id")
            ? _scheduled_visit.disease_id
            : "";

        var _case = case_create_from_disease(_disease_id, _pet.species_id);

        if (is_struct(_case)) {
            if (variable_struct_exists(_scheduled_visit, "case_id")) {
                _case.case_id = _scheduled_visit.case_id;
            }

            if (variable_struct_exists(_scheduled_visit, "severity_level")) {
                _case.severity_level = _scheduled_visit.severity_level;
            }

            if (variable_struct_exists(_scheduled_visit, "severity_name_ru")) {
                _case.severity_name_ru = _scheduled_visit.severity_name_ru;
            }

            var _start_reveal = variable_struct_exists(_scheduled_visit, "start_reveal_level")
                ? _scheduled_visit.start_reveal_level
                : 1;

            _case.reveal_level = max(_case.reveal_level, _start_reveal);

            _case.confirmed = variable_struct_exists(_scheduled_visit, "confirmed")
                ? _scheduled_visit.confirmed
                : false;

            _case.condition = variable_struct_exists(_scheduled_visit, "start_condition")
                ? _scheduled_visit.start_condition
                : _pet.condition;

            if (variable_struct_exists(_case, "initial_condition")) {
                _case.initial_condition = _case.condition;
            }

            if (variable_struct_exists(_scheduled_visit, "completed_diagnostics")) {
                _case.completed_diagnostics = _scheduled_visit.completed_diagnostics;
            }

            if (variable_struct_exists(_scheduled_visit, "treatment_progress")) {
                _case.treatment_progress = _scheduled_visit.treatment_progress;
            }

            if (variable_struct_exists(_scheduled_visit, "visible_symptoms")) {
                _case.visible_symptoms = _scheduled_visit.visible_symptoms;
            }

            if (variable_struct_exists(_scheduled_visit, "planned_treatment")) {
                _case.planned_treatment = _scheduled_visit.planned_treatment;
            }

            _case.prescribed_treatment_ids = variable_struct_exists(
                _scheduled_visit,
                "prescribed_treatment_ids"
            ) ? _scheduled_visit.prescribed_treatment_ids : [];

            _case.pending_procedure_actions = variable_struct_exists(
                _scheduled_visit,
                "pending_procedure_actions"
            ) ? _scheduled_visit.pending_procedure_actions : [];

            _case.case_status = variable_struct_exists(_scheduled_visit, "case_status")
                ? _scheduled_visit.case_status
                : "followup";

            // Данные нового визита всегда начинаются пустыми.
            _case.visit_diagnostics_done = [];
            _case.visit_treatments_done = [];
            _case.visit_procedure_log = [];
            _case.visit_prescribed_actions = [];
            _case.visit_treatment_feedback_ok_ids = [];
            _case.visit_treatment_feedback_bad_ids = [];

            animal_apply_case(_pet, _case);
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 4. РЕГИСТРАЦИЯ АКТИВНОГО ПОСЕТИТЕЛЯ
    // ═══════════════════════════════════════════════════════════

    array_push(global.city_pet_owners, _owner);
    array_push(global.active_visitors, _owner);

    var _pet_name = instance_exists(_owner.my_pet)
        ? _owner.my_pet.char_name
        : "Питомец";

    show_debug_message(
        "[FOLLOWUP SPAWN] Владелец: "
        + _owner.char_name
        + " | Питомец: "
        + _pet_name
    );

    return _owner;
}
