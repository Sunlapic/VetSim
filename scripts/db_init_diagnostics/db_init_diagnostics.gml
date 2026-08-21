/// db_init_diagnostics.gml
/// @description База обследований. Пакет №68: добавлены обследования для 50 болезней.

function db_init_diagnostics() {
    var _diagnostics = global.med_db.diagnostics;


    // ═══════════════════════════════════════════════════════════
    // 1. БАЗОВЫЕ ОБСЛЕДОВАНИЯ
    // ═══════════════════════════════════════════════════════════

    variable_struct_set(_diagnostics, "diag_physical_exam", {
        id : "diag_physical_exam",
        name_ru : "Первичный осмотр",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 20,
        time_min : 10,
        unlocks_reveal_level : 1
    });
    array_push(global.med_db.diagnostic_ids, "diag_physical_exam");

    variable_struct_set(_diagnostics, "diag_blood_smear", {
        id : "diag_blood_smear",
        name_ru : "Микроскопия мазка крови",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 80,
        time_min : 20,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_blood_smear");

    variable_struct_set(_diagnostics, "diag_blood_test", {
        id : "diag_blood_test",
        name_ru : "Общий анализ крови",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 60,
        time_min : 20,
        unlocks_reveal_level : 4
    });
    array_push(global.med_db.diagnostic_ids, "diag_blood_test");

    variable_struct_set(_diagnostics, "diag_xray", {
        id : "diag_xray",
        name_ru : "Рентген",
        room_id : "room_xray",
        skill_id : "skill_xray",
        price : 120,
        time_min : 25,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_xray");

    variable_struct_set(_diagnostics, "diag_otoscope", {
        id : "diag_otoscope",
        name_ru : "Отоскопия (осмотр уха)",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 40,
        time_min : 8,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_otoscope");


    // ═══════════════════════════════════════════════════════════
    // 2. ДОПОЛНИТЕЛЬНЫЕ ОБСЛЕДОВАНИЯ
    // Пока они служат ложными вариантами для текущих тестовых болезней.
    // Позднее их можно связать с новыми болезнями через disease_diagnostics.
    // ═══════════════════════════════════════════════════════════

    variable_struct_set(_diagnostics, "diag_urinalysis", {
        id : "diag_urinalysis",
        name_ru : "Общий анализ мочи",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 55,
        time_min : 15,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_urinalysis");

    variable_struct_set(_diagnostics, "diag_ultrasound", {
        id : "diag_ultrasound",
        name_ru : "УЗИ брюшной полости",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 100,
        time_min : 20,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_ultrasound");

    variable_struct_set(_diagnostics, "diag_skin_scraping", {
        id : "diag_skin_scraping",
        name_ru : "Соскоб кожи",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 45,
        time_min : 12,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_skin_scraping");


    // ═══════════════════════════════════════════════════════════
    // ПАКЕТ №68: НОВЫЕ ОБСЛЕДОВАНИЯ
    // ═══════════════════════════════════════════════════════════

    variable_struct_set(_diagnostics, "diag_biochemistry", {
        id : "diag_biochemistry",
        name_ru : "Биохимия крови",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 90,
        time_min : 20,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_biochemistry");

    variable_struct_set(_diagnostics, "diag_fecal_test", {
        id : "diag_fecal_test",
        name_ru : "Анализ кала",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 40,
        time_min : 15,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_fecal_test");

    variable_struct_set(_diagnostics, "diag_urine_culture", {
        id : "diag_urine_culture",
        name_ru : "Бакпосев мочи",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 70,
        time_min : 25,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_urine_culture");

    variable_struct_set(_diagnostics, "diag_skin_cytology", {
        id : "diag_skin_cytology",
        name_ru : "Цитология кожи",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 60,
        time_min : 18,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_skin_cytology");

    variable_struct_set(_diagnostics, "diag_allergy_test", {
        id : "diag_allergy_test",
        name_ru : "Аллергопроба",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 80,
        time_min : 20,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_allergy_test");

    variable_struct_set(_diagnostics, "diag_ophthalmoscopy", {
        id : "diag_ophthalmoscopy",
        name_ru : "Офтальмоскопия",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 55,
        time_min : 12,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_ophthalmoscopy");

    variable_struct_set(_diagnostics, "diag_tonometry", {
        id : "diag_tonometry",
        name_ru : "Тонометрия глаза",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 50,
        time_min : 10,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_tonometry");

    variable_struct_set(_diagnostics, "diag_fluorescein_test", {
        id : "diag_fluorescein_test",
        name_ru : "Флуоресцеиновый тест",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 45,
        time_min : 10,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_fluorescein_test");

    variable_struct_set(_diagnostics, "diag_dental_exam", {
        id : "diag_dental_exam",
        name_ru : "Осмотр полости рта",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 30,
        time_min : 8,
        unlocks_reveal_level : 1
    });
    array_push(global.med_db.diagnostic_ids, "diag_dental_exam");

    variable_struct_set(_diagnostics, "diag_ecg", {
        id : "diag_ecg",
        name_ru : "ЭКГ",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 60,
        time_min : 15,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_ecg");

    variable_struct_set(_diagnostics, "diag_pcr", {
        id : "diag_pcr",
        name_ru : "ПЦР-тест",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 130,
        time_min : 30,
        unlocks_reveal_level : 4
    });
    array_push(global.med_db.diagnostic_ids, "diag_pcr");

    variable_struct_set(_diagnostics, "diag_bacterial_culture", {
        id : "diag_bacterial_culture",
        name_ru : "Бактериологический посев",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 110,
        time_min : 30,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_bacterial_culture");

    variable_struct_set(_diagnostics, "diag_serology", {
        id : "diag_serology",
        name_ru : "Серологический тест",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 100,
        time_min : 25,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_serology");

    variable_struct_set(_diagnostics, "diag_glucose_test", {
        id : "diag_glucose_test",
        name_ru : "Тест на глюкозу",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 35,
        time_min : 10,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_glucose_test");

    variable_struct_set(_diagnostics, "diag_trichoscopy", {
        id : "diag_trichoscopy",
        name_ru : "Трихоскопия шерсти",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 50,
        time_min : 15,
        unlocks_reveal_level : 2
    });
    array_push(global.med_db.diagnostic_ids, "diag_trichoscopy");

    variable_struct_set(_diagnostics, "diag_endoscopy", {
        id : "diag_endoscopy",
        name_ru : "Эндоскопия",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 150,
        time_min : 25,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_endoscopy");

    variable_struct_set(_diagnostics, "diag_xray_contrast", {
        id : "diag_xray_contrast",
        name_ru : "Рентген с контрастом",
        room_id : "room_xray",
        skill_id : "skill_xray",
        price : 140,
        time_min : 25,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_xray_contrast");

    variable_struct_set(_diagnostics, "diag_thyroid_test", {
        id : "diag_thyroid_test",
        name_ru : "Тест щитовидной железы",
        room_id : "room_laboratory",
        skill_id : "skill_laboratory",
        price : 80,
        time_min : 20,
        unlocks_reveal_level : 3
    });
    array_push(global.med_db.diagnostic_ids, "diag_thyroid_test");
}
