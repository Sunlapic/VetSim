/// db_init_treatment_actions.gml
/// @description База лечебных действий. Пакет №68: добавлены действия для 50 болезней.
/// Пакет №108: добавлены 6 хирургических операций (операционная).

function db_init_treatment_actions() {
    global.med_db.treatment_actions = {};
    global.med_db.treatment_action_ids = [];
    var _treat = global.med_db.treatment_actions;

    // ══════════════════════════════════════
    // ОСНОВНЫЕ (правильные) ЛЕЧЕБНЫЕ ДЕЙСТВИЯ
    // ══════════════════════════════════════

    variable_struct_set(_treat, "treat_iv_drip", {
        id : "treat_iv_drip",
        name_ru : "Капельница",
        type : "procedure",
        room_id : "room_stationary",
        skill_id : "skill_stationary",
        price : 60,
        time_min : 30,
        condition_delta : 5,
        required_items : [
            { item_id : "item_iv_solution", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_iv_drip");

    variable_struct_set(_treat, "treat_antiprotozoal", {
        id : "treat_antiprotozoal",
        name_ru : "Противопротозойный укол",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 120,
        time_min : 15,
        condition_delta : 5,
        required_items : [
            { item_id : "item_antiprotozoal", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antiprotozoal");

    variable_struct_set(_treat, "treat_painkiller", {
        id : "treat_painkiller",
        name_ru : "Обезболивающее",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_procedures",
        price : 35,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_painkiller", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_painkiller");

    variable_struct_set(_treat, "treat_limb_fixation", {
        id : "treat_limb_fixation",
        name_ru : "Фиксация лапы",
        type : "procedure",
        room_id : "room_exam",
        skill_id : "skill_surgery",
        price : 140,
        time_min : 35,
        condition_delta : 8,
        required_items : [
            { item_id : "item_fixation_set", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_limb_fixation");

    // ── НОВЫЕ ДЕЙСТВИЯ ──

    variable_struct_set(_treat, "treat_antibiotic", {
        id : "treat_antibiotic",
        name_ru : "Антибиотик",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 60,
        time_min : 10,
        condition_delta : 4,
        required_items : [
            { item_id : "item_antibiotic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antibiotic");

    variable_struct_set(_treat, "treat_antipyretic", {
        id : "treat_antipyretic",
        name_ru : "Жаропонижающее",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 25,
        time_min : 8,
        condition_delta : 3,
        required_items : [
            { item_id : "item_antipyretic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antipyretic");

    variable_struct_set(_treat, "treat_bandage", {
        id : "treat_bandage",
        name_ru : "Перевязка раны",
        type : "procedure",
        room_id : "room_exam",
        skill_id : "skill_procedures",
        price : 40,
        time_min : 15,
        condition_delta : 4,
        required_items : [
            { item_id : "item_bandage", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_bandage");

    variable_struct_set(_treat, "treat_eye_drops", {
        id : "treat_eye_drops",
        name_ru : "Глазные капли",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 40,
        time_min : 8,
        condition_delta : 5,
        required_items : [
            { item_id : "item_eye_drops", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_eye_drops");

    variable_struct_set(_treat, "treat_ear_drops", {
        id : "treat_ear_drops",
        name_ru : "Ушные капли",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 35,
        time_min : 8,
        condition_delta : 5,
        required_items : [
            { item_id : "item_ear_drops", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_ear_drops");

    variable_struct_set(_treat, "treat_flea_treatment", {
        id : "treat_flea_treatment",
        name_ru : "Обработка от паразитов",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_procedures",
        price : 70,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_flea_drops", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_flea_treatment");

    variable_struct_set(_treat, "treat_nose_drops", {
        id : "treat_nose_drops",
        name_ru : "Капли в нос",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 30,
        time_min : 8,
        condition_delta : 5,
        required_items : [
            { item_id : "item_nose_drops", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_nose_drops");

    variable_struct_set(_treat, "treat_hemostatic", {
        id : "treat_hemostatic",
        name_ru : "Кровоостанавливающее",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_surgery",
        price : 50,
        time_min : 10,
        condition_delta : 6,
        required_items : [
            { item_id : "item_hemostatic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_hemostatic");

    variable_struct_set(_treat, "treat_sorbent", {
        id : "treat_sorbent",
        name_ru : "Сорбент",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 35,
        time_min : 8,
        condition_delta : 4,
        required_items : [
            { item_id : "item_sorbent", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_sorbent");

    variable_struct_set(_treat, "treat_serum", {
        id : "treat_serum",
        name_ru : "Сыворотка",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 220,
        time_min : 15,
        condition_delta : 6,
        required_items : [
            { item_id : "item_serum", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_serum");


    // ══════════════════════════════════════
    // ПАКЕТ №68: НОВЫЕ ЛЕЧЕБНЫЕ ДЕЙСТВИЯ
    // ══════════════════════════════════════

    variable_struct_set(_treat, "treat_anthelminthic", {
        id : "treat_anthelminthic",
        name_ru : "Антигельминтик",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 45,
        time_min : 10,
        condition_delta : 6,
        required_items : [
            { item_id : "item_anthelminthic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_anthelminthic");

    variable_struct_set(_treat, "treat_antifungal", {
        id : "treat_antifungal",
        name_ru : "Противогрибковое",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 60,
        time_min : 12,
        condition_delta : 6,
        required_items : [
            { item_id : "item_antifungal", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antifungal");

    variable_struct_set(_treat, "treat_antiseptic", {
        id : "treat_antiseptic",
        name_ru : "Антисептическая обработка",
        type : "procedure",
        room_id : "room_exam",
        skill_id : "skill_procedures",
        price : 30,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_antiseptic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antiseptic");

    variable_struct_set(_treat, "treat_gastroprotector", {
        id : "treat_gastroprotector",
        name_ru : "Гастропротектор",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 45,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_gastroprotector", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_gastroprotector");

    variable_struct_set(_treat, "treat_antiemetic", {
        id : "treat_antiemetic",
        name_ru : "Противорвотное",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 35,
        time_min : 8,
        condition_delta : 4,
        required_items : [
            { item_id : "item_antiemetic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antiemetic");

    variable_struct_set(_treat, "treat_probiotic", {
        id : "treat_probiotic",
        name_ru : "Пробиотик",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 40,
        time_min : 8,
        condition_delta : 5,
        required_items : [
            { item_id : "item_probiotic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_probiotic");

    variable_struct_set(_treat, "treat_diet_feed", {
        id : "treat_diet_feed",
        name_ru : "Диетический корм",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 50,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_diet_feed", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_diet_feed");

    variable_struct_set(_treat, "treat_insulin", {
        id : "treat_insulin",
        name_ru : "Инсулинотерапия",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 70,
        time_min : 12,
        condition_delta : 7,
        required_items : [
            { item_id : "item_insulin", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_insulin");

    variable_struct_set(_treat, "treat_thyroid_hormone", {
        id : "treat_thyroid_hormone",
        name_ru : "Гормон щитовидной железы",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 55,
        time_min : 10,
        condition_delta : 6,
        required_items : [
            { item_id : "item_thyroid", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_thyroid_hormone");

    variable_struct_set(_treat, "treat_hepatoprotector", {
        id : "treat_hepatoprotector",
        name_ru : "Гепатопротектор",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 55,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_hepatoprotector", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_hepatoprotector");

    variable_struct_set(_treat, "treat_kidney_support", {
        id : "treat_kidney_support",
        name_ru : "Поддержка почек",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 60,
        time_min : 12,
        condition_delta : 5,
        required_items : [
            { item_id : "item_kidney_support", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_kidney_support");

    variable_struct_set(_treat, "treat_iron_supplement", {
        id : "treat_iron_supplement",
        name_ru : "Препарат железа",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 45,
        time_min : 10,
        condition_delta : 6,
        required_items : [
            { item_id : "item_iron", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_iron_supplement");

    variable_struct_set(_treat, "treat_eye_ointment", {
        id : "treat_eye_ointment",
        name_ru : "Глазная мазь",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 45,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_eye_ointment", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_eye_ointment");

    variable_struct_set(_treat, "treat_ear_clean", {
        id : "treat_ear_clean",
        name_ru : "Чистка уха",
        type : "procedure",
        room_id : "room_exam",
        skill_id : "skill_procedures",
        price : 30,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_ear_cleaner", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_ear_clean");

    variable_struct_set(_treat, "treat_nasal_wash", {
        id : "treat_nasal_wash",
        name_ru : "Промывание носа",
        type : "procedure",
        room_id : "room_exam",
        skill_id : "skill_procedures",
        price : 30,
        time_min : 10,
        condition_delta : 4,
        required_items : [
            { item_id : "item_nasal_wash", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_nasal_wash");

    variable_struct_set(_treat, "treat_cough_syrup", {
        id : "treat_cough_syrup",
        name_ru : "Сироп от кашля",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 35,
        time_min : 8,
        condition_delta : 4,
        required_items : [
            { item_id : "item_cough_syrup", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_cough_syrup");

    variable_struct_set(_treat, "treat_dental_cleaning", {
        id : "treat_dental_cleaning",
        name_ru : "Ультразвуковая чистка зубов",
        type : "procedure",
        room_id : "room_exam",
        skill_id : "skill_procedures",
        price : 80,
        time_min : 15,
        condition_delta : 7,
        required_items : [
            { item_id : "item_dental_paste", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_dental_cleaning");

    variable_struct_set(_treat, "treat_oxygen_therapy", {
        id : "treat_oxygen_therapy",
        name_ru : "Кислородотерапия",
        type : "procedure",
        room_id : "room_stationary",
        skill_id : "skill_stationary",
        price : 70,
        time_min : 15,
        condition_delta : 6,
        required_items : [
            { item_id : "item_oxygen", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_oxygen_therapy");

    variable_struct_set(_treat, "treat_antiviral", {
        id : "treat_antiviral",
        name_ru : "Противовирусная терапия",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 65,
        time_min : 12,
        condition_delta : 5,
        required_items : [
            { item_id : "item_antiviral", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antiviral");

    variable_struct_set(_treat, "treat_immunostimulant", {
        id : "treat_immunostimulant",
        name_ru : "Иммуностимулятор",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 55,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_immunostimulant", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_immunostimulant");

    variable_struct_set(_treat, "treat_colloid", {
        id : "treat_colloid",
        name_ru : "Коллоидный раствор",
        type : "procedure",
        room_id : "room_stationary",
        skill_id : "skill_stationary",
        price : 75,
        time_min : 20,
        condition_delta : 7,
        required_items : [
            { item_id : "item_colloid", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_colloid");

    variable_struct_set(_treat, "treat_antispasmodic", {
        id : "treat_antispasmodic",
        name_ru : "Спазмолитик",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 35,
        time_min : 8,
        condition_delta : 4,
        required_items : [
            { item_id : "item_antispasmodic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antispasmodic");

    variable_struct_set(_treat, "treat_uroseptic", {
        id : "treat_uroseptic",
        name_ru : "Уросептик",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 50,
        time_min : 10,
        condition_delta : 6,
        required_items : [
            { item_id : "item_uroseptic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_uroseptic");

    variable_struct_set(_treat, "treat_laxative", {
        id : "treat_laxative",
        name_ru : "Слабительное",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 30,
        time_min : 8,
        condition_delta : 5,
        required_items : [
            { item_id : "item_laxative", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_laxative");

    variable_struct_set(_treat, "treat_antiparasitic", {
        id : "treat_antiparasitic",
        name_ru : "Противопаразитарное",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 50,
        time_min : 10,
        condition_delta : 6,
        required_items : [
            { item_id : "item_antiparasitic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antiparasitic");

    variable_struct_set(_treat, "treat_pressure_drops", {
        id : "treat_pressure_drops",
        name_ru : "Капли от давления",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 60,
        time_min : 10,
        condition_delta : 6,
        required_items : [
            { item_id : "item_pressure_drops", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_pressure_drops");

    variable_struct_set(_treat, "treat_skin_cream", {
        id : "treat_skin_cream",
        name_ru : "Заживляющий крем",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 45,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_skin_cream", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_skin_cream");

    variable_struct_set(_treat, "treat_antihistamine", {
        id : "treat_antihistamine",
        name_ru : "Антигистаминное",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 40,
        time_min : 10,
        condition_delta : 5,
        required_items : [
            { item_id : "item_antihistamine", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_antihistamine");


    // ══════════════════════════════════════
    // ПАКЕТ №108: ХИРУРГИЧЕСКИЕ ОПЕРАЦИИ (операционная)
    // type = "surgery", room_id = "room_operating", is_surgery = true.
    // Длительность операции считается по сумме навыков бригады
    // (хирург + анестезиолог + ассистент) — см. operating_system (позже).
    // ══════════════════════════════════════

    variable_struct_set(_treat, "treat_osteosynthesis", {
        id : "treat_osteosynthesis",
        name_ru : "Остеосинтез",
        type : "surgery",
        room_id : "room_operating",
        skill_id : "skill_surgery",
        is_surgery : true,
        price : 250,
        time_min : 40,
        condition_delta : 20,
        required_items : [
            { item_id : "item_anesthetic", amount : 1 },
            { item_id : "item_surgical_kit", amount : 1 },
            { item_id : "item_fixation_set", amount : 1 },
            { item_id : "item_bandage", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_osteosynthesis");

    variable_struct_set(_treat, "treat_wound_surgery", {
        id : "treat_wound_surgery",
        name_ru : "Хирургическая обработка раны",
        type : "surgery",
        room_id : "room_operating",
        skill_id : "skill_surgery",
        is_surgery : true,
        price : 150,
        time_min : 25,
        condition_delta : 14,
        required_items : [
            { item_id : "item_anesthetic", amount : 1 },
            { item_id : "item_surgical_kit", amount : 1 },
            { item_id : "item_antiseptic", amount : 1 },
            { item_id : "item_bandage", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_wound_surgery");

    variable_struct_set(_treat, "treat_surgical_hemostasis", {
        id : "treat_surgical_hemostasis",
        name_ru : "Хирургический гемостаз",
        type : "surgery",
        room_id : "room_operating",
        skill_id : "skill_surgery",
        is_surgery : true,
        price : 180,
        time_min : 30,
        condition_delta : 18,
        required_items : [
            { item_id : "item_anesthetic", amount : 1 },
            { item_id : "item_surgical_kit", amount : 1 },
            { item_id : "item_hemostatic", amount : 1 },
            { item_id : "item_iv_solution", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_surgical_hemostasis");

    variable_struct_set(_treat, "treat_foreign_body_removal", {
        id : "treat_foreign_body_removal",
        name_ru : "Удаление инородного тела",
        type : "surgery",
        room_id : "room_operating",
        skill_id : "skill_surgery",
        is_surgery : true,
        price : 200,
        time_min : 30,
        condition_delta : 15,
        required_items : [
            { item_id : "item_anesthetic", amount : 1 },
            { item_id : "item_surgical_kit", amount : 1 },
            { item_id : "item_antiseptic", amount : 1 },
            { item_id : "item_bandage", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_foreign_body_removal");

    variable_struct_set(_treat, "treat_cystotomy", {
        id : "treat_cystotomy",
        name_ru : "Цистотомия",
        type : "surgery",
        room_id : "room_operating",
        skill_id : "skill_surgery",
        is_surgery : true,
        price : 350,
        time_min : 45,
        condition_delta : 22,
        required_items : [
            { item_id : "item_anesthetic", amount : 1 },
            { item_id : "item_surgical_kit", amount : 1 },
            { item_id : "item_uroseptic", amount : 1 },
            { item_id : "item_iv_solution", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_cystotomy");

    variable_struct_set(_treat, "treat_tooth_extraction", {
        id : "treat_tooth_extraction",
        name_ru : "Удаление зуба",
        type : "surgery",
        room_id : "room_operating",
        skill_id : "skill_surgery",
        is_surgery : true,
        price : 120,
        time_min : 20,
        condition_delta : 12,
        required_items : [
            { item_id : "item_anesthetic", amount : 1 },
            { item_id : "item_surgical_kit", amount : 1 },
            { item_id : "item_antiseptic", amount : 1 },
            { item_id : "item_hemostatic", amount : 1 }
        ]
    });
    array_push(global.med_db.treatment_action_ids, "treat_tooth_extraction");


    // ══════════════════════════════════════
    // ОТВЛЕКАЮЩИЕ / НЕПРАВИЛЬНЫЕ ВАРИАНТЫ (без расхода предметов, 0 к состоянию)
    // ══════════════════════════════════════

    variable_struct_set(_treat, "treat_antiinflammatory", {
        id : "treat_antiinflammatory",
        name_ru : "Противовоспалительное",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_therapy_diag",
        price : 45,
        time_min : 10,
        condition_delta : 0,
        required_items : []
    });
    array_push(global.med_db.treatment_action_ids, "treat_antiinflammatory");

    variable_struct_set(_treat, "treat_vitamins", {
        id : "treat_vitamins",
        name_ru : "Витаминная инъекция",
        type : "therapy",
        room_id : "room_exam",
        skill_id : "skill_procedures",
        price : 40,
        time_min : 8,
        condition_delta : 0,
        required_items : []
    });
    array_push(global.med_db.treatment_action_ids, "treat_vitamins");
}
