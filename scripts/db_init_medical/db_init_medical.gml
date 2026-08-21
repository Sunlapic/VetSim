/// db_init_medical.gml
/// @description Создаёт базу med_db и запускает инициализацию всех справочников.
/// Пакет №137: убраны вызовы удалённых db_init_skills/db_init_rooms и мёртвые
/// поля rooms/skills (нигде не читались).

function db_init_medical() {

    global.med_db = {
        diseases : {},
        disease_ids : [],

        symptoms : {},
        symptom_ids : [],

        diagnostics : {},
        diagnostic_ids : [],

        treatment_actions : {},
        treatment_action_ids : [],

        disease_symptoms : [],
        disease_diagnostics : [],
        disease_treatment : [],
        disease_skills : []
    };

    global.case_uid = 0;

    db_init_symptoms();
    db_init_diagnostics();
    db_init_treatment_actions();
    db_init_diseases();
    db_init_disease_links();
}
