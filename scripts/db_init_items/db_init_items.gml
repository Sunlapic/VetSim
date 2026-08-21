/// db_init_items.gml
/// @description База препаратов. Пакет №68: добавлены препараты для 50 болезней.
/// Пакет №108: добавлены препараты для операционной (анестетик, хирургический набор).

function db_init_items() {
    global.item_db = {};
    global.item_ids = [];

    var _db = global.item_db;

    variable_struct_set(_db, "item_painkiller", {
        id : "item_painkiller",
        name_ru : "Обезболивающее",
        buy_price : 35,
        unit_ru : "амп."
    });
    array_push(global.item_ids, "item_painkiller");

    variable_struct_set(_db, "item_iv_solution", {
        id : "item_iv_solution",
        name_ru : "Раствор для капельницы",
        buy_price : 40,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_iv_solution");

    variable_struct_set(_db, "item_antiprotozoal", {
        id : "item_antiprotozoal",
        name_ru : "Противопротозойный препарат",
        buy_price : 120,
        unit_ru : "доз."
    });
    array_push(global.item_ids, "item_antiprotozoal");

    variable_struct_set(_db, "item_fixation_set", {
        id : "item_fixation_set",
        name_ru : "Материал для фиксации",
        buy_price : 90,
        unit_ru : "компл."
    });
    array_push(global.item_ids, "item_fixation_set");

    // ─────────────────────────────────────────────
    // НОВЫЕ ПРЕПАРАТЫ (для разных болезней)
    // ─────────────────────────────────────────────
    variable_struct_set(_db, "item_bandage", {
        id : "item_bandage",
        name_ru : "Бинт стерильный",
        buy_price : 20,
        unit_ru : "уп."
    });
    array_push(global.item_ids, "item_bandage");

    variable_struct_set(_db, "item_antibiotic", {
        id : "item_antibiotic",
        name_ru : "Антибиотик широкого спектра",
        buy_price : 65,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_antibiotic");

    variable_struct_set(_db, "item_antipyretic", {
        id : "item_antipyretic",
        name_ru : "Жаропонижающее",
        buy_price : 30,
        unit_ru : "таб."
    });
    array_push(global.item_ids, "item_antipyretic");

    variable_struct_set(_db, "item_eye_drops", {
        id : "item_eye_drops",
        name_ru : "Глазные капли",
        buy_price : 45,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_eye_drops");

    variable_struct_set(_db, "item_ear_drops", {
        id : "item_ear_drops",
        name_ru : "Ушные капли",
        buy_price : 40,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_ear_drops");

    variable_struct_set(_db, "item_flea_drops", {
        id : "item_flea_drops",
        name_ru : "Капли от блох и клещей",
        buy_price : 80,
        unit_ru : "пип."
    });
    array_push(global.item_ids, "item_flea_drops");

    variable_struct_set(_db, "item_nose_drops", {
        id : "item_nose_drops",
        name_ru : "Капли в нос",
        buy_price : 35,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_nose_drops");

    variable_struct_set(_db, "item_hemostatic", {
        id : "item_hemostatic",
        name_ru : "Кровоостанавливающее",
        buy_price : 55,
        unit_ru : "амп."
    });
    array_push(global.item_ids, "item_hemostatic");

    variable_struct_set(_db, "item_sorbent", {
        id : "item_sorbent",
        name_ru : "Сорбент при отравлении",
        buy_price : 50,
        unit_ru : "уп."
    });
    array_push(global.item_ids, "item_sorbent");

    variable_struct_set(_db, "item_serum", {
        id : "item_serum",
        name_ru : "Иммунная сыворотка",
        buy_price : 180,
        unit_ru : "доз."
    });
    array_push(global.item_ids, "item_serum");


    // ═══════════════════════════════════════════════════════════
    // ПАКЕТ №68: НОВЫЕ ПРЕПАРАТЫ
    // ═══════════════════════════════════════════════════════════

    variable_struct_set(_db, "item_anthelminthic", {
        id : "item_anthelminthic",
        name_ru : "Антигельминтик",
        buy_price : 40,
        unit_ru : "таб."
    });
    array_push(global.item_ids, "item_anthelminthic");

    variable_struct_set(_db, "item_antifungal", {
        id : "item_antifungal",
        name_ru : "Противогрибковый препарат",
        buy_price : 55,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_antifungal");

    variable_struct_set(_db, "item_antiseptic", {
        id : "item_antiseptic",
        name_ru : "Антисептик",
        buy_price : 25,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_antiseptic");

    variable_struct_set(_db, "item_gastroprotector", {
        id : "item_gastroprotector",
        name_ru : "Гастропротектор",
        buy_price : 40,
        unit_ru : "таб."
    });
    array_push(global.item_ids, "item_gastroprotector");

    variable_struct_set(_db, "item_antiemetic", {
        id : "item_antiemetic",
        name_ru : "Противорвотное",
        buy_price : 30,
        unit_ru : "амп."
    });
    array_push(global.item_ids, "item_antiemetic");

    variable_struct_set(_db, "item_probiotic", {
        id : "item_probiotic",
        name_ru : "Пробиотик",
        buy_price : 35,
        unit_ru : "уп."
    });
    array_push(global.item_ids, "item_probiotic");

    variable_struct_set(_db, "item_diet_feed", {
        id : "item_diet_feed",
        name_ru : "Диетический корм",
        buy_price : 45,
        unit_ru : "уп."
    });
    array_push(global.item_ids, "item_diet_feed");

    variable_struct_set(_db, "item_insulin", {
        id : "item_insulin",
        name_ru : "Инсулин",
        buy_price : 65,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_insulin");

    variable_struct_set(_db, "item_thyroid", {
        id : "item_thyroid",
        name_ru : "Гормон щитовидной железы",
        buy_price : 50,
        unit_ru : "таб."
    });
    array_push(global.item_ids, "item_thyroid");

    variable_struct_set(_db, "item_hepatoprotector", {
        id : "item_hepatoprotector",
        name_ru : "Гепатопротектор",
        buy_price : 50,
        unit_ru : "таб."
    });
    array_push(global.item_ids, "item_hepatoprotector");

    variable_struct_set(_db, "item_kidney_support", {
        id : "item_kidney_support",
        name_ru : "Препарат для почек",
        buy_price : 55,
        unit_ru : "уп."
    });
    array_push(global.item_ids, "item_kidney_support");

    variable_struct_set(_db, "item_iron", {
        id : "item_iron",
        name_ru : "Препарат железа",
        buy_price : 40,
        unit_ru : "амп."
    });
    array_push(global.item_ids, "item_iron");

    variable_struct_set(_db, "item_eye_ointment", {
        id : "item_eye_ointment",
        name_ru : "Глазная мазь",
        buy_price : 40,
        unit_ru : "туба"
    });
    array_push(global.item_ids, "item_eye_ointment");

    variable_struct_set(_db, "item_ear_cleaner", {
        id : "item_ear_cleaner",
        name_ru : "Раствор для чистки ушей",
        buy_price : 25,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_ear_cleaner");

    variable_struct_set(_db, "item_nasal_wash", {
        id : "item_nasal_wash",
        name_ru : "Раствор для промывания носа",
        buy_price : 25,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_nasal_wash");

    variable_struct_set(_db, "item_cough_syrup", {
        id : "item_cough_syrup",
        name_ru : "Сироп от кашля",
        buy_price : 30,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_cough_syrup");

    variable_struct_set(_db, "item_dental_paste", {
        id : "item_dental_paste",
        name_ru : "Средство для чистки зубов",
        buy_price : 70,
        unit_ru : "уп."
    });
    array_push(global.item_ids, "item_dental_paste");

    variable_struct_set(_db, "item_oxygen", {
        id : "item_oxygen",
        name_ru : "Кислородный баллон",
        buy_price : 60,
        unit_ru : "баллон"
    });
    array_push(global.item_ids, "item_oxygen");

    variable_struct_set(_db, "item_antiviral", {
        id : "item_antiviral",
        name_ru : "Противовирусный препарат",
        buy_price : 60,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_antiviral");

    variable_struct_set(_db, "item_immunostimulant", {
        id : "item_immunostimulant",
        name_ru : "Иммуностимулятор",
        buy_price : 50,
        unit_ru : "амп."
    });
    array_push(global.item_ids, "item_immunostimulant");

    variable_struct_set(_db, "item_colloid", {
        id : "item_colloid",
        name_ru : "Коллоидный раствор",
        buy_price : 65,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_colloid");

    variable_struct_set(_db, "item_antispasmodic", {
        id : "item_antispasmodic",
        name_ru : "Спазмолитик",
        buy_price : 30,
        unit_ru : "амп."
    });
    array_push(global.item_ids, "item_antispasmodic");

    variable_struct_set(_db, "item_uroseptic", {
        id : "item_uroseptic",
        name_ru : "Уросептик",
        buy_price : 45,
        unit_ru : "таб."
    });
    array_push(global.item_ids, "item_uroseptic");

    variable_struct_set(_db, "item_laxative", {
        id : "item_laxative",
        name_ru : "Слабительное",
        buy_price : 25,
        unit_ru : "уп."
    });
    array_push(global.item_ids, "item_laxative");

    variable_struct_set(_db, "item_antiparasitic", {
        id : "item_antiparasitic",
        name_ru : "Противопаразитарный препарат",
        buy_price : 45,
        unit_ru : "пип."
    });
    array_push(global.item_ids, "item_antiparasitic");

    variable_struct_set(_db, "item_pressure_drops", {
        id : "item_pressure_drops",
        name_ru : "Капли от глазного давления",
        buy_price : 55,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_pressure_drops");

    variable_struct_set(_db, "item_skin_cream", {
        id : "item_skin_cream",
        name_ru : "Заживляющий крем",
        buy_price : 40,
        unit_ru : "туба"
    });
    array_push(global.item_ids, "item_skin_cream");

    variable_struct_set(_db, "item_antihistamine", {
        id : "item_antihistamine",
        name_ru : "Антигистаминное",
        buy_price : 35,
        unit_ru : "таб."
    });
    array_push(global.item_ids, "item_antihistamine");


    // ═══════════════════════════════════════════════════════════
    // ПАКЕТ №108: ОПЕРАЦИОННАЯ
    // ═══════════════════════════════════════════════════════════

    variable_struct_set(_db, "item_anesthetic", {
        id : "item_anesthetic",
        name_ru : "Анестетик",
        buy_price : 70,
        unit_ru : "фл."
    });
    array_push(global.item_ids, "item_anesthetic");

    variable_struct_set(_db, "item_surgical_kit", {
        id : "item_surgical_kit",
        name_ru : "Хирургический набор",
        buy_price : 120,
        unit_ru : "компл."
    });
    array_push(global.item_ids, "item_surgical_kit");


    global.storage_buy_batch = 5;
}
