/// db_init_disease_links.gml
/// @description Связи болезней: симптомы, диагностика, лечение, навыки. Пакет №68: 50 болезней.
/// Пакет №108: 6 болезней переведены на хирургическое лечение (операционная).

function db_init_disease_links() {
    global.med_db.disease_symptoms = [];
    global.med_db.disease_diagnostics = [];
    global.med_db.disease_treatment = [];
    global.med_db.disease_skills = [];

    // ─────────────────────────────────────────
    // PIROPLASMOSIS -> SYMPTOMS
    // ─────────────────────────────────────────
    array_push(global.med_db.disease_symptoms, {
        disease_id : "disease_piroplasmosis",
        symptom_id : "symptom_weakness",
        weight : 3,
        visible_on_start : true
    });

    array_push(global.med_db.disease_symptoms, {
        disease_id : "disease_piroplasmosis",
        symptom_id : "symptom_high_temp",
        weight : 3,
        visible_on_start : true
    });

    array_push(global.med_db.disease_symptoms, {
        disease_id : "disease_piroplasmosis",
        symptom_id : "symptom_dark_urine",
        weight : 3,
        visible_on_start : false
    });

    array_push(global.med_db.disease_symptoms, {
        disease_id : "disease_piroplasmosis",
        symptom_id : "symptom_no_appetite",
        weight : 2,
        visible_on_start : true
    });

    // ─────────────────────────────────────────
    // FRACTURE -> SYMPTOMS
    // ─────────────────────────────────────────
    array_push(global.med_db.disease_symptoms, {
        disease_id : "disease_limb_fracture",
        symptom_id : "symptom_lameness",
        weight : 3,
        visible_on_start : true
    });

    array_push(global.med_db.disease_symptoms, {
        disease_id : "disease_limb_fracture",
        symptom_id : "symptom_pain",
        weight : 3,
        visible_on_start : true
    });

    array_push(global.med_db.disease_symptoms, {
        disease_id : "disease_limb_fracture",
        symptom_id : "symptom_swelling",
        weight : 2,
        visible_on_start : false
    });

    array_push(global.med_db.disease_symptoms, {
        disease_id : "disease_limb_fracture",
        symptom_id : "symptom_not_weight_bearing",
        weight : 3,
        visible_on_start : false
    });

    // ─────────────────────────────────────────
    // PIROPLASMOSIS -> DIAGNOSTICS
    // ─────────────────────────────────────────
    array_push(global.med_db.disease_diagnostics, {
        disease_id : "disease_piroplasmosis",
        diagnostic_id : "diag_physical_exam",
        required_to_confirm : false,
        priority : 1,
        unlocks_reveal_level : 1
    });

    array_push(global.med_db.disease_diagnostics, {
        disease_id : "disease_piroplasmosis",
        diagnostic_id : "diag_blood_smear",
        required_to_confirm : true,
        priority : 2,
        unlocks_reveal_level : 3
    });

    array_push(global.med_db.disease_diagnostics, {
        disease_id : "disease_piroplasmosis",
        diagnostic_id : "diag_blood_test",
        required_to_confirm : false,
        priority : 3,
        unlocks_reveal_level : 4
    });

    // ─────────────────────────────────────────
    // FRACTURE -> DIAGNOSTICS
    // ─────────────────────────────────────────
    array_push(global.med_db.disease_diagnostics, {
        disease_id : "disease_limb_fracture",
        diagnostic_id : "diag_physical_exam",
        required_to_confirm : false,
        priority : 1,
        unlocks_reveal_level : 1
    });

    array_push(global.med_db.disease_diagnostics, {
        disease_id : "disease_limb_fracture",
        diagnostic_id : "diag_xray",
        required_to_confirm : true,
        priority : 2,
        unlocks_reveal_level : 3
    });

    // ─────────────────────────────────────────
    // PIROPLASMOSIS -> TREATMENT
    // ─────────────────────────────────────────
    array_push(global.med_db.disease_treatment, {
        disease_id : "disease_piroplasmosis",
        action_id : "treat_antiprotozoal",
        count : 1,
        days : 1,
        reveal_level : 3,
        required : true,
        severity_or_condition : "any",
        notes : "Основной укол по пироплазмозу, делается один раз.",
        repeat_until_recovered : false,
        per_visit_limit : 1
    });

    array_push(global.med_db.disease_treatment, {
        disease_id : "disease_piroplasmosis",
        action_id : "treat_iv_drip",
        count : 1,
        days : 1,
        reveal_level : 1,
        required : true,
        severity_or_condition : "any",
        notes : "Одна капельница за визит, повторять до 100% состояния.",
        repeat_until_recovered : true,
        per_visit_limit : 1
    });

    // ─────────────────────────────────────────
    // FRACTURE -> TREATMENT
    // ─────────────────────────────────────────
    array_push(global.med_db.disease_treatment, {
        disease_id : "disease_limb_fracture",
        action_id : "treat_osteosynthesis",
        count : 1,
        days : 1,
        reveal_level : 3,
        required : true,
        severity_or_condition : "any",
        notes : "Операция: остеосинтез (операционная).",
        repeat_until_recovered : false,
        per_visit_limit : 1
    });

    array_push(global.med_db.disease_treatment, {
        disease_id : "disease_limb_fracture",
        action_id : "treat_painkiller",
        count : 1,
        days : 1,
        reveal_level : 1,
        required : true,
        severity_or_condition : "any",
        notes : "Одно обезболивающее за визит, повторять до 100% состояния.",
        repeat_until_recovered : true,
        per_visit_limit : 1
    });

    // ─────────────────────────────────────────
    // SKILL REQUIREMENTS
    // ─────────────────────────────────────────
    array_push(global.med_db.disease_skills, {
        disease_id : "disease_piroplasmosis",
        skill_id : "skill_therapy_diag",
        min_level : 5,
        importance : "main"
    });

    array_push(global.med_db.disease_skills, {
        disease_id : "disease_piroplasmosis",
        skill_id : "skill_laboratory",
        min_level : 4,
        importance : "support"
    });

    array_push(global.med_db.disease_skills, {
        disease_id : "disease_piroplasmosis",
        skill_id : "skill_stationary",
        min_level : 4,
        importance : "support"
    });

    array_push(global.med_db.disease_skills, {
        disease_id : "disease_limb_fracture",
        skill_id : "skill_surgery",
        min_level : 7,
        importance : "main"
    });

    array_push(global.med_db.disease_skills, {
        disease_id : "disease_limb_fracture",
        skill_id : "skill_xray",
        min_level : 5,
        importance : "support"
    });


    // ══════════════════════════════════════════
    // НОВЫЕ БОЛЕЗНИ (пакеты до №67: rhinitis…hemorrhage)
    // ══════════════════════════════════════════

    // ── РИНИТ (насморк) ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_rhinitis", symptom_id : "symptom_sneezing",       weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_rhinitis", symptom_id : "symptom_no_appetite",    weight : 1, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_rhinitis", symptom_id : "symptom_nasal_discharge", weight : 3, visible_on_start : false });

    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_rhinitis", diagnostic_id : "diag_physical_exam", required_to_confirm : true,  priority : 1, unlocks_reveal_level : 1 });

    array_push(global.med_db.disease_treatment, { disease_id : "disease_rhinitis", action_id : "treat_nose_drops", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Капли в нос 3-5 дней.", repeat_until_recovered : false, per_visit_limit : 1 });

    array_push(global.med_db.disease_skills, { disease_id : "disease_rhinitis", skill_id : "skill_therapy_diag", min_level : 1, importance : "main" });

    // ── БЛОХИ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_fleas", symptom_id : "symptom_itching",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_fleas", symptom_id : "symptom_skin_redness", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_fleas", symptom_id : "symptom_restlessness", weight : 2, visible_on_start : true  });

    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_fleas", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });

    array_push(global.med_db.disease_treatment, { disease_id : "disease_fleas", action_id : "treat_flea_treatment", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Однократная обработка от блох.", repeat_until_recovered : false, per_visit_limit : 1 });

    array_push(global.med_db.disease_skills, { disease_id : "disease_fleas", skill_id : "skill_therapy_diag", min_level : 1, importance : "main" });

    // ── ОТИТ (ушной клещ) ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_otitis", symptom_id : "symptom_ear_shake", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_otitis", symptom_id : "symptom_pain",      weight : 2, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_otitis", symptom_id : "symptom_ear_discharge", weight : 3, visible_on_start : false });

    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_otitis", diagnostic_id : "diag_physical_exam", required_to_confirm : true,  priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_otitis", diagnostic_id : "diag_otoscope",     required_to_confirm : false, priority : 2, unlocks_reveal_level : 2 });

    array_push(global.med_db.disease_treatment, { disease_id : "disease_otitis", action_id : "treat_ear_drops", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Ушные капли курсом 7 дней.", repeat_until_recovered : false, per_visit_limit : 1 });

    array_push(global.med_db.disease_skills, { disease_id : "disease_otitis", skill_id : "skill_therapy_diag", min_level : 2, importance : "main" });

    // ── КОНЪЮНКТИВИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_conjunctivitis", symptom_id : "symptom_eye_discharge", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_conjunctivitis", symptom_id : "symptom_eye_redness",   weight : 3, visible_on_start : false });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_conjunctivitis", symptom_id : "symptom_eye_swelling",  weight : 2, visible_on_start : false });

    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_conjunctivitis", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });

    array_push(global.med_db.disease_treatment, { disease_id : "disease_conjunctivitis", action_id : "treat_eye_drops", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Глазные капли курсом 5-7 дней.", repeat_until_recovered : false, per_visit_limit : 1 });

    array_push(global.med_db.disease_skills, { disease_id : "disease_conjunctivitis", skill_id : "skill_therapy_diag", min_level : 1, importance : "main" });

    // ── РВАНАЯ РАНА ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_wound", symptom_id : "symptom_lameness",  weight : 2, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_wound", symptom_id : "symptom_pain",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_wound", symptom_id : "symptom_bleeding",  weight : 2, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_wound", symptom_id : "symptom_swelling",  weight : 2, visible_on_start : false });

    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_wound", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });

    array_push(global.med_db.disease_treatment, { disease_id : "disease_wound", action_id : "treat_wound_surgery", count : 1, days : 1, reveal_level : 3, required : true, severity_or_condition : "any", notes : "Операция: хирургическая обработка раны.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_wound", action_id : "treat_painkiller", count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Обезболивающее до заживления.", repeat_until_recovered : true,  per_visit_limit : 1 });

    array_push(global.med_db.disease_skills, { disease_id : "disease_wound", skill_id : "skill_procedures", min_level : 3, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_wound", skill_id : "skill_surgery",    min_level : 2, importance : "support" });

    // ── БАКТЕРИАЛЬНАЯ ИНФЕКЦИЯ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_infection", symptom_id : "symptom_high_temp",   weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_infection", symptom_id : "symptom_weakness",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_infection", symptom_id : "symptom_no_appetite",  weight : 2, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_infection", symptom_id : "symptom_coughing",     weight : 2, visible_on_start : false });

    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_infection", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_infection", diagnostic_id : "diag_blood_test",    required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });

    array_push(global.med_db.disease_treatment, { disease_id : "disease_infection", action_id : "treat_antibiotic",  count : 1, days : 1, reveal_level : 2, required : true,  severity_or_condition : "any", notes : "Антибиотик широкого спектра.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_infection", action_id : "treat_antipyretic", count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Жаропонижающее при температуре.", repeat_until_recovered : true,  per_visit_limit : 1 });

    array_push(global.med_db.disease_skills, { disease_id : "disease_infection", skill_id : "skill_therapy_diag", min_level : 3, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_infection", skill_id : "skill_laboratory",  min_level : 2, importance : "support" });

    // ── ОТРАВЛЕНИЕ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_poisoning", symptom_id : "symptom_vomiting",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_poisoning", symptom_id : "symptom_diarrhea",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_poisoning", symptom_id : "symptom_weakness",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_poisoning", symptom_id : "symptom_dehydration",  weight : 3, visible_on_start : false });

    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_poisoning", diagnostic_id : "diag_physical_exam", required_to_confirm : true,  priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_poisoning", diagnostic_id : "diag_blood_test",    required_to_confirm : false, priority : 2, unlocks_reveal_level : 3 });

    array_push(global.med_db.disease_treatment, { disease_id : "disease_poisoning", action_id : "treat_sorbent", count : 1, days : 1, reveal_level : 2, required : true, severity_or_condition : "any", notes : "Сорбент нейтрализует яд.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_poisoning", action_id : "treat_iv_drip", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Капельница при обезвоживании.", repeat_until_recovered : true,  per_visit_limit : 1 });

    array_push(global.med_db.disease_skills, { disease_id : "disease_poisoning", skill_id : "skill_therapy_diag", min_level : 5, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_poisoning", skill_id : "skill_stationary",  min_level : 4, importance : "support" });

    // ── ВИРУСНАЯ ИНФЕКЦИЯ (энтерит) ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_viral_infection", symptom_id : "symptom_vomiting",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_viral_infection", symptom_id : "symptom_high_temp",    weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_viral_infection", symptom_id : "symptom_weakness",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_viral_infection", symptom_id : "symptom_diarrhea",     weight : 3, visible_on_start : false });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_viral_infection", symptom_id : "symptom_dehydration",  weight : 2, visible_on_start : false });

    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_viral_infection", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_viral_infection", diagnostic_id : "diag_blood_test",    required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });

    array_push(global.med_db.disease_treatment, { disease_id : "disease_viral_infection", action_id : "treat_serum",      count : 1, days : 1, reveal_level : 3, required : true,  severity_or_condition : "any", notes : "Сыворотка против вируса.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_viral_infection", action_id : "treat_antibiotic", count : 1, days : 1, reveal_level : 3, required : true,  severity_or_condition : "any", notes : "Антибиотик от вторичной инфекции.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_viral_infection", action_id : "treat_iv_drip",    count : 1, days : 1, reveal_level : 1, required : true,  severity_or_condition : "any", notes : "Капельница от обезвоживания.", repeat_until_recovered : true, per_visit_limit : 1 });

    array_push(global.med_db.disease_skills, { disease_id : "disease_viral_infection", skill_id : "skill_therapy_diag", min_level : 7, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_viral_infection", skill_id : "skill_laboratory",  min_level : 5, importance : "support" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_viral_infection", skill_id : "skill_stationary",  min_level : 6, importance : "support" });

    // ── КРОВОТЕЧЕНИЕ (травма, критическое) ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hemorrhage", symptom_id : "symptom_bleeding",        weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hemorrhage", symptom_id : "symptom_pale_gums",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hemorrhage", symptom_id : "symptom_weakness",        weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hemorrhage", symptom_id : "symptom_pain",            weight : 2, visible_on_start : true  });

    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_hemorrhage", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });

    array_push(global.med_db.disease_treatment, { disease_id : "disease_hemorrhage", action_id : "treat_surgical_hemostasis", count : 1, days : 1, reveal_level : 3, required : true, severity_or_condition : "any", notes : "Операция: хирургический гемостаз.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_hemorrhage", action_id : "treat_iv_drip",    count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Капельница для восстановления объёма крови.", repeat_until_recovered : true, per_visit_limit : 1 });

    array_push(global.med_db.disease_skills, { disease_id : "disease_hemorrhage", skill_id : "skill_surgery",    min_level : 6, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_hemorrhage", skill_id : "skill_stationary", min_level : 5, importance : "support" });


    // ══════════════════════════════════════════
    // ПАКЕТ №68: НОВЫЕ БОЛЕЗНИ (только собаки)
    // ══════════════════════════════════════════

    // ── ГАСТРИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_gastritis", symptom_id : "symptom_vomiting",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_gastritis", symptom_id : "symptom_no_appetite",   weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_gastritis", symptom_id : "symptom_abdominal_pain",weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_gastritis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_gastritis", diagnostic_id : "diag_endoscopy",     required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_gastritis", action_id : "treat_gastroprotector", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Защита слизистой желудка.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_gastritis", action_id : "treat_antiemetic",      count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Снимает рвоту.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_gastritis", action_id : "treat_diet_feed",      count : 1, days : 1, reveal_level : 2, required : true, severity_or_condition : "any", notes : "Щадящая диета.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_gastritis", skill_id : "skill_therapy_diag", min_level : 2, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_gastritis", skill_id : "skill_laboratory",  min_level : 2, importance : "support" });

    // ── ПАНКРЕАТИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_pancreatitis", symptom_id : "symptom_abdominal_pain", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_pancreatitis", symptom_id : "symptom_vomiting",       weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_pancreatitis", symptom_id : "symptom_weakness",       weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_pancreatitis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_pancreatitis", diagnostic_id : "diag_biochemistry",  required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_pancreatitis", action_id : "treat_antispasmodic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Снимает боль и спазм.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_pancreatitis", action_id : "treat_diet_feed",     count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Диета при панкреатите.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_pancreatitis", action_id : "treat_iv_drip",      count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Капельница при рвоте.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_pancreatitis", skill_id : "skill_therapy_diag", min_level : 5, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_pancreatitis", skill_id : "skill_laboratory",  min_level : 4, importance : "support" });

    // ── ДИАБЕТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_diabetes", symptom_id : "symptom_thirst",         weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_diabetes", symptom_id : "symptom_frequent_urine", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_diabetes", symptom_id : "symptom_weight_loss",    weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_diabetes", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_diabetes", diagnostic_id : "diag_glucose_test",  required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_diabetes", action_id : "treat_insulin",   count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Инсулин до стабилизации.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_diabetes", action_id : "treat_diet_feed", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Диета при диабете.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_diabetes", skill_id : "skill_therapy_diag", min_level : 6, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_diabetes", skill_id : "skill_laboratory",  min_level : 4, importance : "support" });

    // ── ГИПОТИРЕОЗ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hypothyroidism", symptom_id : "symptom_weakness",    weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hypothyroidism", symptom_id : "symptom_weight_gain",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hypothyroidism", symptom_id : "symptom_dull_coat",    weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_hypothyroidism", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_hypothyroidism", diagnostic_id : "diag_thyroid_test",  required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_hypothyroidism", action_id : "treat_thyroid_hormone", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Заместительная терапия.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_hypothyroidism", action_id : "treat_diet_feed",       count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "Контроль веса.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_hypothyroidism", skill_id : "skill_therapy_diag", min_level : 5, importance : "main" });

    // ── ПЕЧЁНОЧНАЯ НЕДОСТАТОЧНОСТЬ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_liver_failure", symptom_id : "symptom_jaundice",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_liver_failure", symptom_id : "symptom_weakness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_liver_failure", symptom_id : "symptom_ascites",   weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_liver_failure", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_liver_failure", diagnostic_id : "diag_biochemistry",  required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_liver_failure", action_id : "treat_hepatoprotector", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Поддержка печени.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_liver_failure", action_id : "treat_iv_drip",         count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Детоксикация.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_liver_failure", skill_id : "skill_therapy_diag", min_level : 7, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_liver_failure", skill_id : "skill_stationary",  min_level : 5, importance : "support" });

    // ── ПОЧЕЧНАЯ НЕДОСТАТОЧНОСТЬ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_kidney_failure", symptom_id : "symptom_thirst",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_kidney_failure", symptom_id : "symptom_no_appetite", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_kidney_failure", symptom_id : "symptom_dark_urine",  weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_kidney_failure", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_kidney_failure", diagnostic_id : "diag_biochemistry",  required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_kidney_failure", action_id : "treat_kidney_support", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Поддержка почек.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_kidney_failure", action_id : "treat_iv_drip",        count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Инфузионная терапия.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_kidney_failure", action_id : "treat_diet_feed",      count : 1, days : 1, reveal_level : 2, required : true, severity_or_condition : "any", notes : "Почечная диета.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_kidney_failure", skill_id : "skill_therapy_diag", min_level : 7, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_kidney_failure", skill_id : "skill_stationary",  min_level : 5, importance : "support" });

    // ── АНЕМИЯ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_anemia", symptom_id : "symptom_pale_gums", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_anemia", symptom_id : "symptom_weakness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_anemia", symptom_id : "symptom_fatigue",   weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_anemia", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_anemia", diagnostic_id : "diag_blood_test",    required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_anemia", action_id : "treat_iron_supplement", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Восполнение железа.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_anemia", action_id : "treat_diet_feed",       count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "Питание при анемии.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_anemia", skill_id : "skill_therapy_diag", min_level : 4, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_anemia", skill_id : "skill_laboratory",  min_level : 4, importance : "support" });

    // ── ОЖИРЕНИЕ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_obesity", symptom_id : "symptom_weight_gain", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_obesity", symptom_id : "symptom_panting",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_obesity", symptom_id : "symptom_fatigue",     weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_obesity", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_obesity", action_id : "treat_diet_feed", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Диета и контроль порций.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_obesity", skill_id : "skill_therapy_diag", min_level : 2, importance : "main" });

    // ── ТЕПЛОВОЙ УДАР ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_heatstroke", symptom_id : "symptom_panting",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_heatstroke", symptom_id : "symptom_hot_skin", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_heatstroke", symptom_id : "symptom_collapse", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_heatstroke", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_heatstroke", action_id : "treat_oxygen_therapy", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Кислород при перегреве.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_heatstroke", action_id : "treat_iv_drip",        count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Охлаждённая капельница.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_heatstroke", skill_id : "skill_stationary",  min_level : 6, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_heatstroke", skill_id : "skill_therapy_diag", min_level : 4, importance : "support" });

    // ── БРОНХИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_bronchitis", symptom_id : "symptom_cough",    weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_bronchitis", symptom_id : "symptom_weakness", weight : 2, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_bronchitis", symptom_id : "symptom_fever",     weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_bronchitis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_bronchitis", diagnostic_id : "diag_xray",         required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_bronchitis", action_id : "treat_cough_syrup", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Смягчает кашель.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_bronchitis", action_id : "treat_antibiotic",  count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "При бактериальной природе.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_bronchitis", skill_id : "skill_therapy_diag", min_level : 4, importance : "main" });

    // ── ПНЕВМОНИЯ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_pneumonia", symptom_id : "symptom_high_temp",           weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_pneumonia", symptom_id : "symptom_difficulty_breathing", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_pneumonia", symptom_id : "symptom_weakness",             weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_pneumonia", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_pneumonia", diagnostic_id : "diag_xray",         required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_pneumonia", action_id : "treat_antibiotic",      count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Основной курс антибиотика.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_pneumonia", action_id : "treat_oxygen_therapy", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Кислород при дыхательной недостаточности.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_pneumonia", action_id : "treat_cough_syrup",   count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "Симптоматическая помощь.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_pneumonia", skill_id : "skill_therapy_diag", min_level : 6, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_pneumonia", skill_id : "skill_stationary",  min_level : 5, importance : "support" });

    // ── ПИТОМНИКОВЫЙ КАШЕЛЬ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_kennel_cough", symptom_id : "symptom_coughing", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_kennel_cough", symptom_id : "symptom_sneezing", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_kennel_cough", symptom_id : "symptom_fever",     weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_kennel_cough", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_kennel_cough", action_id : "treat_cough_syrup",     count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Смягчает кашель.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_kennel_cough", action_id : "treat_immunostimulant", count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Поддержка иммунитета.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_kennel_cough", skill_id : "skill_therapy_diag", min_level : 4, importance : "main" });

    // ── КЕРАТИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_keratitis", symptom_id : "symptom_eye_redness", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_keratitis", symptom_id : "symptom_tearing",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_keratitis", symptom_id : "symptom_cloudy_eye",  weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_keratitis", diagnostic_id : "diag_physical_exam",    required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_keratitis", diagnostic_id : "diag_fluorescein_test", required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_keratitis", action_id : "treat_eye_ointment", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Мазь для роговицы.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_keratitis", action_id : "treat_eye_drops",    count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Увлажняющие капли.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_keratitis", skill_id : "skill_therapy_diag", min_level : 5, importance : "main" });

    // ── БЛЕФАРИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_blepharitis", symptom_id : "symptom_eye_swelling", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_blepharitis", symptom_id : "symptom_eye_redness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_blepharitis", symptom_id : "symptom_tearing",      weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_blepharitis", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_blepharitis", action_id : "treat_eye_ointment", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Мазь для век.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_blepharitis", action_id : "treat_antiseptic",   count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Обработка края век.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_blepharitis", skill_id : "skill_therapy_diag", min_level : 3, importance : "main" });

    // ── ГЛАУКОМА ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_glaucoma", symptom_id : "symptom_eye_pain",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_glaucoma", symptom_id : "symptom_eye_redness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_glaucoma", symptom_id : "symptom_cloudy_eye",   weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_glaucoma", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_glaucoma", diagnostic_id : "diag_tonometry",     required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_glaucoma", action_id : "treat_pressure_drops", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Снижение глазного давления.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_glaucoma", skill_id : "skill_therapy_diag", min_level : 7, importance : "main" });

    // ── СУХОЙ ГЛАЗ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_dry_eye", symptom_id : "symptom_eye_redness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_dry_eye", symptom_id : "symptom_tearing",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_dry_eye", symptom_id : "symptom_eye_swelling", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_dry_eye", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_dry_eye", action_id : "treat_eye_drops", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Увлажняющие капли.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_dry_eye", skill_id : "skill_therapy_diag", min_level : 2, importance : "main" });

    // ── СИНУСИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_sinusitis", symptom_id : "symptom_nasal_discharge", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_sinusitis", symptom_id : "symptom_sneezing",        weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_sinusitis", symptom_id : "symptom_nasal_crust",     weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_sinusitis", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_sinusitis", action_id : "treat_nasal_wash", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Промывание носовых ходов.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_sinusitis", action_id : "treat_antibiotic", count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "При бактериальном синусите.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_sinusitis", skill_id : "skill_therapy_diag", min_level : 4, importance : "main" });

    // ── ИНОРОДНОЕ ТЕЛО В УХЕ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_foreign_body_ear", symptom_id : "symptom_ear_shake",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_foreign_body_ear", symptom_id : "symptom_restlessness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_foreign_body_ear", symptom_id : "symptom_ear_discharge",  weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_foreign_body_ear", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_foreign_body_ear", diagnostic_id : "diag_otoscope",      required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_foreign_body_ear", action_id : "treat_foreign_body_removal", count : 1, days : 1, reveal_level : 3, required : true, severity_or_condition : "any", notes : "Операция: удаление инородного тела.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_foreign_body_ear", action_id : "treat_ear_drops", count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "Профилактика воспаления.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_foreign_body_ear", skill_id : "skill_therapy_diag", min_level : 5, importance : "main" });

    // ── СРЕДНИЙ ОТИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_otitis_media", symptom_id : "symptom_ear_shake",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_otitis_media", symptom_id : "symptom_ear_discharge", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_otitis_media", symptom_id : "symptom_head_tilt",     weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_otitis_media", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_otitis_media", diagnostic_id : "diag_otoscope",      required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_otitis_media", action_id : "treat_ear_clean",  count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Чистка уха.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_otitis_media", action_id : "treat_antibiotic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Курс антибиотика.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_otitis_media", action_id : "treat_ear_drops",  count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "Местная терапия.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_otitis_media", skill_id : "skill_therapy_diag", min_level : 5, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_otitis_media", skill_id : "skill_laboratory",  min_level : 3, importance : "support" });

    // ── ДЕРМАТИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_dermatitis", symptom_id : "symptom_itching",       weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_dermatitis", symptom_id : "symptom_skin_redness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_dermatitis", symptom_id : "symptom_skin_flaking",  weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_dermatitis", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_dermatitis", action_id : "treat_skin_cream", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Заживляющий крем.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_dermatitis", action_id : "treat_antiseptic", count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Обработка поражённых мест.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_dermatitis", skill_id : "skill_therapy_diag", min_level : 3, importance : "main" });

    // ── КОЖНАЯ АЛЛЕРГИЯ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_allergy_skin", symptom_id : "symptom_itching",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_allergy_skin", symptom_id : "symptom_hives",        weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_allergy_skin", symptom_id : "symptom_skin_redness", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_allergy_skin", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_allergy_skin", diagnostic_id : "diag_allergy_test",  required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_allergy_skin", action_id : "treat_antihistamine", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Снимает аллергию.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_allergy_skin", action_id : "treat_skin_cream",    count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Успокаивает кожу.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_allergy_skin", skill_id : "skill_therapy_diag", min_level : 4, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_allergy_skin", skill_id : "skill_laboratory",  min_level : 3, importance : "support" });

    // ── МОКНУЩАЯ ЭКЗЕМА ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hot_spot", symptom_id : "symptom_skin_redness", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hot_spot", symptom_id : "symptom_itching",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hot_spot", symptom_id : "symptom_restlessness", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_hot_spot", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_hot_spot", action_id : "treat_antiseptic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Обработка мокнущего пятна.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_hot_spot", action_id : "treat_antibiotic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Антибиотик от инфекции.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_hot_spot", action_id : "treat_skin_cream", count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "Заживление кожи.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_hot_spot", skill_id : "skill_therapy_diag", min_level : 4, importance : "main" });

    // ── ДЕМОДЕКОЗ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_demodicosis", symptom_id : "symptom_hair_loss",    weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_demodicosis", symptom_id : "symptom_itching",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_demodicosis", symptom_id : "symptom_skin_flaking", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_demodicosis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_demodicosis", diagnostic_id : "diag_skin_scraping", required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_demodicosis", action_id : "treat_antiparasitic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Против клеща-железницы.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_demodicosis", action_id : "treat_skin_cream",    count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "Восстановление кожи.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_demodicosis", skill_id : "skill_therapy_diag", min_level : 5, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_demodicosis", skill_id : "skill_laboratory",  min_level : 4, importance : "support" });

    // ── ЛИШАЙ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_ringworm", symptom_id : "symptom_circular_bald", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_ringworm", symptom_id : "symptom_itching",       weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_ringworm", symptom_id : "symptom_dandruff",      weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_ringworm", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_ringworm", diagnostic_id : "diag_trichoscopy",   required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_ringworm", action_id : "treat_antifungal", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Противогрибковый курс.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_ringworm", skill_id : "skill_therapy_diag", min_level : 4, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_ringworm", skill_id : "skill_laboratory",  min_level : 4, importance : "support" });

    // ── КЛЕЩИ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_ticks", symptom_id : "symptom_ticks_visible", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_ticks", symptom_id : "symptom_restlessness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_ticks", symptom_id : "symptom_itching",       weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_ticks", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_ticks", action_id : "treat_antiparasitic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Снятие клещей и обработка.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_ticks", skill_id : "skill_therapy_diag", min_level : 2, importance : "main" });

    // ── ЛЕПТОСПИРОЗ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_leptospirosis", symptom_id : "symptom_high_temp",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_leptospirosis", symptom_id : "symptom_jaundice",   weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_leptospirosis", symptom_id : "symptom_dark_urine", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_leptospirosis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_leptospirosis", diagnostic_id : "diag_serology",      required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_leptospirosis", action_id : "treat_antibiotic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Антибиотик курсом.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_leptospirosis", action_id : "treat_iv_drip",    count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Поддержка почек и печени.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_leptospirosis", skill_id : "skill_therapy_diag", min_level : 7, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_leptospirosis", skill_id : "skill_laboratory",  min_level : 5, importance : "support" });

    // ── ЧУМА ПЛОТОЯДНЫХ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_distemper", symptom_id : "symptom_high_temp",       weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_distemper", symptom_id : "symptom_nasal_discharge", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_distemper", symptom_id : "symptom_seizures",        weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_distemper", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_distemper", diagnostic_id : "diag_pcr",           required_to_confirm : true,  priority : 2, unlocks_reveal_level : 4 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_distemper", action_id : "treat_antiviral",       count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Противовирусная терапия.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_distemper", action_id : "treat_immunostimulant", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Поддержка иммунитета.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_distemper", action_id : "treat_iv_drip",         count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Инфузионная поддержка.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_distemper", skill_id : "skill_therapy_diag", min_level : 8, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_distemper", skill_id : "skill_stationary",  min_level : 6, importance : "support" });

    // ── ИНФЕКЦИОННЫЙ ГЕПАТИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hepatitis_infectious", symptom_id : "symptom_jaundice",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hepatitis_infectious", symptom_id : "symptom_weakness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_hepatitis_infectious", symptom_id : "symptom_high_temp", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_hepatitis_infectious", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_hepatitis_infectious", diagnostic_id : "diag_serology",      required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_hepatitis_infectious", action_id : "treat_hepatoprotector", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Поддержка печени.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_hepatitis_infectious", action_id : "treat_antiviral",       count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Противовирусная поддержка.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_hepatitis_infectious", action_id : "treat_iv_drip",         count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Детоксикация.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_hepatitis_infectious", skill_id : "skill_therapy_diag", min_level : 6, importance : "main" });

    // ── ГЕЛЬМИНТОЗ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_helminthiasis", symptom_id : "symptom_no_appetite", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_helminthiasis", symptom_id : "symptom_weight_loss", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_helminthiasis", symptom_id : "symptom_mucus_stool", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_helminthiasis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_helminthiasis", diagnostic_id : "diag_fecal_test",    required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_helminthiasis", action_id : "treat_anthelminthic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Дегельминтизация.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_helminthiasis", action_id : "treat_probiotic",    count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "Восстановление микрофлоры.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_helminthiasis", skill_id : "skill_therapy_diag", min_level : 3, importance : "main" });

    // ── ЭРЛИХИОЗ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_ehrlichiosis", symptom_id : "symptom_high_temp", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_ehrlichiosis", symptom_id : "symptom_weakness",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_ehrlichiosis", symptom_id : "symptom_pale_gums", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_ehrlichiosis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_ehrlichiosis", diagnostic_id : "diag_pcr",           required_to_confirm : true,  priority : 2, unlocks_reveal_level : 4 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_ehrlichiosis", action_id : "treat_antibiotic",     count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Антибиотик длительным курсом.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_ehrlichiosis", action_id : "treat_iron_supplement", count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "При анемии.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_ehrlichiosis", skill_id : "skill_therapy_diag", min_level : 6, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_ehrlichiosis", skill_id : "skill_laboratory",  min_level : 5, importance : "support" });

    // ── СЕПСИС ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_sepsis", symptom_id : "symptom_high_temp", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_sepsis", symptom_id : "symptom_collapse",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_sepsis", symptom_id : "symptom_fast_pulse", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_sepsis", diagnostic_id : "diag_physical_exam",     required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_sepsis", diagnostic_id : "diag_bacterial_culture", required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_sepsis", action_id : "treat_colloid",         count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Восполнение объёма крови.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_sepsis", action_id : "treat_antibiotic",      count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Антибиотик широкого спектра.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_sepsis", action_id : "treat_oxygen_therapy", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Кислородная поддержка.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_sepsis", skill_id : "skill_stationary",  min_level : 8, importance : "main" });
    array_push(global.med_db.disease_skills, { disease_id : "disease_sepsis", skill_id : "skill_therapy_diag", min_level : 7, importance : "support" });

    // ── ЗУБНОЙ КАМЕНЬ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_tartar", symptom_id : "symptom_plaque",      weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_tartar", symptom_id : "symptom_bad_breath",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_tartar", symptom_id : "symptom_gum_redness", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_tartar", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_tartar", diagnostic_id : "diag_dental_exam",   required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_tartar", action_id : "treat_dental_cleaning", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Ультразвуковая чистка.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_tartar", skill_id : "skill_procedures", min_level : 3, importance : "main" });

    // ── ГИНГИВИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_gingivitis", symptom_id : "symptom_gum_redness", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_gingivitis", symptom_id : "symptom_bad_breath",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_gingivitis", symptom_id : "symptom_drooling",    weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_gingivitis", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_gingivitis", action_id : "treat_antiseptic",      count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Обработка дёсен.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_gingivitis", action_id : "treat_dental_cleaning", count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Чистка зубов.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_gingivitis", skill_id : "skill_procedures", min_level : 3, importance : "main" });

    // ── ПАРОДОНТИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_periodontitis", symptom_id : "symptom_tooth_loosening", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_periodontitis", symptom_id : "symptom_bad_breath",       weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_periodontitis", symptom_id : "symptom_tooth_pain",       weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_periodontitis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_periodontitis", diagnostic_id : "diag_dental_exam",   required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_periodontitis", action_id : "treat_tooth_extraction", count : 1, days : 1, reveal_level : 3, required : true, severity_or_condition : "any", notes : "Операция: удаление зуба.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_periodontitis", action_id : "treat_antibiotic",      count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Антибиотик при инфекции.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_periodontitis", skill_id : "skill_procedures", min_level : 5, importance : "main" });

    // ── СТОМАТИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_stomatitis", symptom_id : "symptom_mouth_ulcers", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_stomatitis", symptom_id : "symptom_drooling",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_stomatitis", symptom_id : "symptom_no_appetite",  weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_stomatitis", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_stomatitis", action_id : "treat_antiseptic",       count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Обработка полости рта.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_stomatitis", action_id : "treat_immunostimulant", count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Поддержка иммунитета.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_stomatitis", skill_id : "skill_procedures", min_level : 4, importance : "main" });

    // ── ЦИСТИТ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_cystitis", symptom_id : "symptom_pain_urinate",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_cystitis", symptom_id : "symptom_frequent_urine", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_cystitis", symptom_id : "symptom_bloody_urine",  weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_cystitis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_cystitis", diagnostic_id : "diag_urinalysis",    required_to_confirm : true,  priority : 2, unlocks_reveal_level : 2 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_cystitis", action_id : "treat_uroseptic",     count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Уросептик курсом.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_cystitis", action_id : "treat_antispasmodic", count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Снимает спазм.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_cystitis", skill_id : "skill_therapy_diag", min_level : 4, importance : "main" });

    // ── МОЧЕКАМЕННАЯ БОЛЕЗНЬ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_urolithiasis", symptom_id : "symptom_bloody_urine", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_urolithiasis", symptom_id : "symptom_pain_urinate", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_urolithiasis", symptom_id : "symptom_back_pain",    weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_urolithiasis", diagnostic_id : "diag_physical_exam", required_to_confirm : false, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_urolithiasis", diagnostic_id : "diag_xray",         required_to_confirm : true,  priority : 2, unlocks_reveal_level : 3 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_urolithiasis", action_id : "treat_cystotomy", count : 1, days : 1, reveal_level : 3, required : true, severity_or_condition : "any", notes : "Операция: цистотомия (удаление камней).", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_urolithiasis", action_id : "treat_antispasmodic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Снимает боль.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_urolithiasis", action_id : "treat_diet_feed",     count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Спецдиета растворяет камни.", repeat_until_recovered : true, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_urolithiasis", action_id : "treat_uroseptic",    count : 1, days : 1, reveal_level : 2, required : false, severity_or_condition : "any", notes : "Профилактика инфекции.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_urolithiasis", skill_id : "skill_therapy_diag", min_level : 6, importance : "main" });

    // ── ЗАПОР ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_constipation", symptom_id : "symptom_constipation",  weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_constipation", symptom_id : "symptom_straining",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_constipation", symptom_id : "symptom_abdominal_pain", weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_constipation", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_constipation", action_id : "treat_laxative",  count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Слабительное.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_constipation", action_id : "treat_diet_feed", count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Клетчатка в рационе.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_constipation", skill_id : "skill_procedures", min_level : 2, importance : "main" });

    // ── АНАЛЬНЫЕ ЖЕЛЕЗЫ ──
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_anal_glands", symptom_id : "symptom_scooting",     weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_anal_glands", symptom_id : "symptom_restlessness", weight : 3, visible_on_start : true  });
    array_push(global.med_db.disease_symptoms, { disease_id : "disease_anal_glands", symptom_id : "symptom_pain",         weight : 2, visible_on_start : false });
    array_push(global.med_db.disease_diagnostics, { disease_id : "disease_anal_glands", diagnostic_id : "diag_physical_exam", required_to_confirm : true, priority : 1, unlocks_reveal_level : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_anal_glands", action_id : "treat_antiseptic", count : 1, days : 1, reveal_level : 1, required : true, severity_or_condition : "any", notes : "Обработка и чистка желёз.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_treatment, { disease_id : "disease_anal_glands", action_id : "treat_painkiller", count : 1, days : 1, reveal_level : 1, required : false, severity_or_condition : "any", notes : "Снятие боли.", repeat_until_recovered : false, per_visit_limit : 1 });
    array_push(global.med_db.disease_skills, { disease_id : "disease_anal_glands", skill_id : "skill_procedures", min_level : 2, importance : "main" });
}
