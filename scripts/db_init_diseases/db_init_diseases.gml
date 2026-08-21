/// db_init_diseases.gml
/// @description База болезней. Пакет №68: 50 болезней (11 старых + 39 новых, только собаки).

function db_init_diseases() {

    var _dis = global.med_db.diseases;

    // ═══════════════════════════════════════════
    // СТАРЫЕ БОЛЕЗНИ (сохранены без изменений)
    // ═══════════════════════════════════════════

    variable_struct_set(_dis, "disease_piroplasmosis", {
        id : "disease_piroplasmosis",
        name_ru : "Пироплазмоз",
        species : ["dog"],
        difficulty : 5,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "spring",
        description : "Кровепаразитарная болезнь после укуса клеща."
    });
    array_push(global.med_db.disease_ids, "disease_piroplasmosis");

    variable_struct_set(_dis, "disease_limb_fracture", {
        id : "disease_limb_fracture",
        name_ru : "Перелом лапы",
        species : ["dog", "cat"],
        difficulty : 7,
        main_specialty_id : "skill_surgery",
        season_bonus : "none",
        description : "Перелом конечности с болью и хромотой."
    });
    array_push(global.med_db.disease_ids, "disease_limb_fracture");

    // ─────────────────────────────────────────────
    // ЛЁГКИЕ БОЛЕЗНИ (сложность 2-4)
    // ─────────────────────────────────────────────
    variable_struct_set(_dis, "disease_rhinitis", {
        id : "disease_rhinitis",
        name_ru : "Ринит (насморк)",
        species : ["dog", "cat"],
        difficulty : 2,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "autumn",
        description : "Воспаление слизистой носа, чихание, выделения из носа."
    });
    array_push(global.med_db.disease_ids, "disease_rhinitis");

    variable_struct_set(_dis, "disease_fleas", {
        id : "disease_fleas",
        name_ru : "Блошиная инвазия",
        species : ["dog", "cat"],
        difficulty : 2,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "summer",
        description : "Зуд, беспокойство, расчёсы на коже от укусов блох."
    });
    array_push(global.med_db.disease_ids, "disease_fleas");

    variable_struct_set(_dis, "disease_otitis", {
        id : "disease_otitis",
        name_ru : "Отит (ушной клещ)",
        species : ["dog", "cat"],
        difficulty : 3,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Воспаление уха, трясёт головой, выделения из уха."
    });
    array_push(global.med_db.disease_ids, "disease_otitis");

    variable_struct_set(_dis, "disease_conjunctivitis", {
        id : "disease_conjunctivitis",
        name_ru : "Конъюнктивит",
        species : ["dog", "cat"],
        difficulty : 2,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "spring",
        description : "Воспаление глаз, слезотечение, гнойные выделения."
    });
    array_push(global.med_db.disease_ids, "disease_conjunctivitis");

    // ─────────────────────────────────────────────
    // СРЕДНИЕ БОЛЕЗНИ (сложность 5-6)
    // ─────────────────────────────────────────────
    variable_struct_set(_dis, "disease_wound", {
        id : "disease_wound",
        name_ru : "Рваная рана",
        species : ["dog", "cat"],
        difficulty : 5,
        main_specialty_id : "skill_surgery",
        season_bonus : "none",
        description : "Открытая рана, хромота, риск инфицирования."
    });
    array_push(global.med_db.disease_ids, "disease_wound");

    variable_struct_set(_dis, "disease_infection", {
        id : "disease_infection",
        name_ru : "Бактериальная инфекция",
        species : ["dog", "cat"],
        difficulty : 5,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "winter",
        description : "Высокая температура, вялость, отказ от еды."
    });
    array_push(global.med_db.disease_ids, "disease_infection");

    // ─────────────────────────────────────────────
    // ТЯЖЁЛЫЕ БОЛЕЗНИ (сложность 7-8)
    // ─────────────────────────────────────────────
    variable_struct_set(_dis, "disease_poisoning", {
        id : "disease_poisoning",
        name_ru : "Отравление",
        species : ["dog", "cat"],
        difficulty : 8,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Рвота, диарея, слабость, обезвоживание. Нужна капельница."
    });
    array_push(global.med_db.disease_ids, "disease_poisoning");

    variable_struct_set(_dis, "disease_viral_infection", {
        id : "disease_viral_infection",
        name_ru : "Вирусная энтеритная инфекция",
        species : ["dog"],
        difficulty : 8,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Высокая температура, рвота, обезвоживание. Требует сыворотки."
    });
    array_push(global.med_db.disease_ids, "disease_viral_infection");

    // ─────────────────────────────────────────────
    // КРИТИЧЕСКИЕ (сложность 9-10, срочное лечение)
    // ─────────────────────────────────────────────
    variable_struct_set(_dis, "disease_hemorrhage", {
        id : "disease_hemorrhage",
        name_ru : "Кровотечение (травма)",
        species : ["dog", "cat"],
        difficulty : 9,
        main_specialty_id : "skill_surgery",
        season_bonus : "none",
        description : "Сильное кровотечение, бледность, угнетение. Срочно!"
    });
    array_push(global.med_db.disease_ids, "disease_hemorrhage");


    // ═══════════════════════════════════════════
    // ПАКЕТ №68: НОВЫЕ БОЛЕЗНИ (только собаки)
    // ═══════════════════════════════════════════

    // ── ТЕРАПИЯ: ЖКТ ──
    variable_struct_set(_dis, "disease_gastritis", {
        id : "disease_gastritis",
        name_ru : "Гастрит",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Воспаление слизистой желудка, рвота, отказ от еды."
    });
    array_push(global.med_db.disease_ids, "disease_gastritis");

    variable_struct_set(_dis, "disease_pancreatitis", {
        id : "disease_pancreatitis",
        name_ru : "Панкреатит",
        species : ["dog"],
        difficulty : 6,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Воспаление поджелудочной железы, сильная боль в животе, рвота."
    });
    array_push(global.med_db.disease_ids, "disease_pancreatitis");

    variable_struct_set(_dis, "disease_helminthiasis", {
        id : "disease_helminthiasis",
        name_ru : "Гельминтоз",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Глистная инвазия, плохой аппетит, потеря веса."
    });
    array_push(global.med_db.disease_ids, "disease_helminthiasis");

    variable_struct_set(_dis, "disease_constipation", {
        id : "disease_constipation",
        name_ru : "Запор",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_procedures",
        season_bonus : "none",
        description : "Затруднённая дефекация, натуживание, боль в животе."
    });
    array_push(global.med_db.disease_ids, "disease_constipation");

    variable_struct_set(_dis, "disease_anal_glands", {
        id : "disease_anal_glands",
        name_ru : "Воспаление анальных желёз",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_procedures",
        season_bonus : "none",
        description : "Закупорка анальных желёз, беспокойство, езда на попе."
    });
    array_push(global.med_db.disease_ids, "disease_anal_glands");

    // ── ТЕРАПИЯ: обмен веществ и внутренние органы ──
    variable_struct_set(_dis, "disease_diabetes", {
        id : "disease_diabetes",
        name_ru : "Сахарный диабет",
        species : ["dog"],
        difficulty : 7,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Нарушение обмена глюкозы, жажда, частое мочеиспускание."
    });
    array_push(global.med_db.disease_ids, "disease_diabetes");

    variable_struct_set(_dis, "disease_hypothyroidism", {
        id : "disease_hypothyroidism",
        name_ru : "Гипотиреоз",
        species : ["dog"],
        difficulty : 5,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Снижение функции щитовидной железы, вялость, набор веса."
    });
    array_push(global.med_db.disease_ids, "disease_hypothyroidism");

    variable_struct_set(_dis, "disease_obesity", {
        id : "disease_obesity",
        name_ru : "Ожирение",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Избыточный вес, одышка при нагрузке."
    });
    array_push(global.med_db.disease_ids, "disease_obesity");

    variable_struct_set(_dis, "disease_anemia", {
        id : "disease_anemia",
        name_ru : "Анемия",
        species : ["dog"],
        difficulty : 5,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Снижение эритроцитов, бледные дёсны, слабость."
    });
    array_push(global.med_db.disease_ids, "disease_anemia");

    variable_struct_set(_dis, "disease_liver_failure", {
        id : "disease_liver_failure",
        name_ru : "Печёночная недостаточность",
        species : ["dog"],
        difficulty : 8,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Нарушение работы печени, желтуха, интоксикация."
    });
    array_push(global.med_db.disease_ids, "disease_liver_failure");

    variable_struct_set(_dis, "disease_kidney_failure", {
        id : "disease_kidney_failure",
        name_ru : "Почечная недостаточность",
        species : ["dog"],
        difficulty : 8,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Нарушение работы почек, жажда, отказ от еды."
    });
    array_push(global.med_db.disease_ids, "disease_kidney_failure");

    variable_struct_set(_dis, "disease_heatstroke", {
        id : "disease_heatstroke",
        name_ru : "Тепловой удар",
        species : ["dog"],
        difficulty : 7,
        main_specialty_id : "skill_stationary",
        season_bonus : "summer",
        description : "Перегрев, учащённое дыхание, угнетение."
    });
    array_push(global.med_db.disease_ids, "disease_heatstroke");

    // ── ТЕРАПИЯ: дыхание ──
    variable_struct_set(_dis, "disease_bronchitis", {
        id : "disease_bronchitis",
        name_ru : "Бронхит",
        species : ["dog"],
        difficulty : 4,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "autumn",
        description : "Воспаление бронхов, кашель, слабость."
    });
    array_push(global.med_db.disease_ids, "disease_bronchitis");

    variable_struct_set(_dis, "disease_pneumonia", {
        id : "disease_pneumonia",
        name_ru : "Пневмония",
        species : ["dog"],
        difficulty : 7,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "winter",
        description : "Воспаление лёгких, температура, тяжёлое дыхание."
    });
    array_push(global.med_db.disease_ids, "disease_pneumonia");

    variable_struct_set(_dis, "disease_kennel_cough", {
        id : "disease_kennel_cough",
        name_ru : "Питомниковый кашель",
        species : ["dog"],
        difficulty : 4,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "autumn",
        description : "Инфекционный трахеобронхит, сухой кашель, чихание."
    });
    array_push(global.med_db.disease_ids, "disease_kennel_cough");

    // ── ОФТАЛЬМОЛОГИЯ ──
    variable_struct_set(_dis, "disease_keratitis", {
        id : "disease_keratitis",
        name_ru : "Кератит",
        species : ["dog"],
        difficulty : 5,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Воспаление роговицы, слезотечение, помутнение глаза."
    });
    array_push(global.med_db.disease_ids, "disease_keratitis");

    variable_struct_set(_dis, "disease_blepharitis", {
        id : "disease_blepharitis",
        name_ru : "Блефарит",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Воспаление век, отёк, покраснение глаз."
    });
    array_push(global.med_db.disease_ids, "disease_blepharitis");

    variable_struct_set(_dis, "disease_glaucoma", {
        id : "disease_glaucoma",
        name_ru : "Глаукома",
        species : ["dog"],
        difficulty : 8,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Повышенное внутриглазное давление, боль, покраснение."
    });
    array_push(global.med_db.disease_ids, "disease_glaucoma");

    variable_struct_set(_dis, "disease_dry_eye", {
        id : "disease_dry_eye",
        name_ru : "Синдром сухого глаза",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Недостаток слёзной жидкости, раздражение глаз."
    });
    array_push(global.med_db.disease_ids, "disease_dry_eye");

    // ── ЛОР ──
    variable_struct_set(_dis, "disease_sinusitis", {
        id : "disease_sinusitis",
        name_ru : "Синусит",
        species : ["dog"],
        difficulty : 4,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "winter",
        description : "Воспаление пазух носа, выделения, чихание."
    });
    array_push(global.med_db.disease_ids, "disease_sinusitis");

    variable_struct_set(_dis, "disease_foreign_body_ear", {
        id : "disease_foreign_body_ear",
        name_ru : "Инородное тело в ухе",
        species : ["dog"],
        difficulty : 5,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "summer",
        description : "Что-то попало в ухо, трясёт головой, беспокойство."
    });
    array_push(global.med_db.disease_ids, "disease_foreign_body_ear");

    variable_struct_set(_dis, "disease_otitis_media", {
        id : "disease_otitis_media",
        name_ru : "Средний отит",
        species : ["dog"],
        difficulty : 6,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Глубокое воспаление уха, боль, выделения."
    });
    array_push(global.med_db.disease_ids, "disease_otitis_media");

    // ── ДЕРМАТОЛОГИЯ ──
    variable_struct_set(_dis, "disease_dermatitis", {
        id : "disease_dermatitis",
        name_ru : "Дерматит",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Воспаление кожи, зуд, покраснение."
    });
    array_push(global.med_db.disease_ids, "disease_dermatitis");

    variable_struct_set(_dis, "disease_allergy_skin", {
        id : "disease_allergy_skin",
        name_ru : "Кожная аллергия",
        species : ["dog"],
        difficulty : 4,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "spring",
        description : "Аллергическая реакция, зуд, крапивница."
    });
    array_push(global.med_db.disease_ids, "disease_allergy_skin");

    variable_struct_set(_dis, "disease_hot_spot", {
        id : "disease_hot_spot",
        name_ru : "Мокнущая экзема",
        species : ["dog"],
        difficulty : 4,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "summer",
        description : "Горячее мокнущее пятно на коже, зуд."
    });
    array_push(global.med_db.disease_ids, "disease_hot_spot");

    variable_struct_set(_dis, "disease_demodicosis", {
        id : "disease_demodicosis",
        name_ru : "Демодекоз",
        species : ["dog"],
        difficulty : 6,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Поражение клещом-железницей, облысение, зуд."
    });
    array_push(global.med_db.disease_ids, "disease_demodicosis");

    variable_struct_set(_dis, "disease_ringworm", {
        id : "disease_ringworm",
        name_ru : "Дерматофития (лишай)",
        species : ["dog"],
        difficulty : 5,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Грибковое поражение кожи, округлые проплешины."
    });
    array_push(global.med_db.disease_ids, "disease_ringworm");

    variable_struct_set(_dis, "disease_ticks", {
        id : "disease_ticks",
        name_ru : "Клещи",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "spring",
        description : "Присосавшиеся клещи, беспокойство, зуд."
    });
    array_push(global.med_db.disease_ids, "disease_ticks");

    // ── ИНФЕКЦИИ / ТОКСИКОЛОГИЯ ──
    variable_struct_set(_dis, "disease_leptospirosis", {
        id : "disease_leptospirosis",
        name_ru : "Лептоспироз",
        species : ["dog"],
        difficulty : 8,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "summer",
        description : "Бактериальная инфекция, желтуха, лихорадка."
    });
    array_push(global.med_db.disease_ids, "disease_leptospirosis");

    variable_struct_set(_dis, "disease_distemper", {
        id : "disease_distemper",
        name_ru : "Чума плотоядных",
        species : ["dog"],
        difficulty : 9,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Тяжёлая вирусная инфекция, температура, нервные симптомы."
    });
    array_push(global.med_db.disease_ids, "disease_distemper");

    variable_struct_set(_dis, "disease_hepatitis_infectious", {
        id : "disease_hepatitis_infectious",
        name_ru : "Инфекционный гепатит",
        species : ["dog"],
        difficulty : 7,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Вирусное поражение печени, желтуха, вялость."
    });
    array_push(global.med_db.disease_ids, "disease_hepatitis_infectious");

    variable_struct_set(_dis, "disease_ehrlichiosis", {
        id : "disease_ehrlichiosis",
        name_ru : "Эрлихиоз",
        species : ["dog"],
        difficulty : 7,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "summer",
        description : "Кровепаразитарная инфекция после укуса клеща."
    });
    array_push(global.med_db.disease_ids, "disease_ehrlichiosis");

    variable_struct_set(_dis, "disease_sepsis", {
        id : "disease_sepsis",
        name_ru : "Сепсис",
        species : ["dog"],
        difficulty : 9,
        main_specialty_id : "skill_stationary",
        season_bonus : "none",
        description : "Заражение крови, высокая температура, коллапс."
    });
    array_push(global.med_db.disease_ids, "disease_sepsis");

    // ── СТОМАТОЛОГИЯ ──
    variable_struct_set(_dis, "disease_tartar", {
        id : "disease_tartar",
        name_ru : "Зубной камень",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_procedures",
        season_bonus : "none",
        description : "Налёт и камень на зубах, запах изо рта."
    });
    array_push(global.med_db.disease_ids, "disease_tartar");

    variable_struct_set(_dis, "disease_gingivitis", {
        id : "disease_gingivitis",
        name_ru : "Гингивит",
        species : ["dog"],
        difficulty : 3,
        main_specialty_id : "skill_procedures",
        season_bonus : "none",
        description : "Воспаление дёсен, покраснение, запах изо рта."
    });
    array_push(global.med_db.disease_ids, "disease_gingivitis");

    variable_struct_set(_dis, "disease_periodontitis", {
        id : "disease_periodontitis",
        name_ru : "Пародонтит",
        species : ["dog"],
        difficulty : 5,
        main_specialty_id : "skill_procedures",
        season_bonus : "none",
        description : "Глубокое поражение дёсен, шатающиеся зубы."
    });
    array_push(global.med_db.disease_ids, "disease_periodontitis");

    variable_struct_set(_dis, "disease_stomatitis", {
        id : "disease_stomatitis",
        name_ru : "Стоматит",
        species : ["dog"],
        difficulty : 4,
        main_specialty_id : "skill_procedures",
        season_bonus : "none",
        description : "Воспаление слизистой рта, язвочки, слюнотечение."
    });
    array_push(global.med_db.disease_ids, "disease_stomatitis");

    // ── УРОЛОГИЯ ──
    variable_struct_set(_dis, "disease_cystitis", {
        id : "disease_cystitis",
        name_ru : "Цистит",
        species : ["dog"],
        difficulty : 4,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Воспаление мочевого пузыря, боль при мочеиспускании."
    });
    array_push(global.med_db.disease_ids, "disease_cystitis");

    variable_struct_set(_dis, "disease_urolithiasis", {
        id : "disease_urolithiasis",
        name_ru : "Мочекаменная болезнь",
        species : ["dog"],
        difficulty : 7,
        main_specialty_id : "skill_therapy_diag",
        season_bonus : "none",
        description : "Камни в мочевом пузыре, кровь в моче, боль."
    });
    array_push(global.med_db.disease_ids, "disease_urolithiasis");
}
