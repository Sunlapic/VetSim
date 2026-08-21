/// db_init_symptoms.gml
/// @description База симптомов. Пакет №68: добавлены симптомы для 50 болезней.

function db_init_symptoms() {
    var _sym = global.med_db.symptoms;

    // ── Общие ──
    variable_struct_set(_sym, "symptom_weakness",      { id: "symptom_weakness",      name_ru: "Вялость",                 category: "general" });
    variable_struct_set(_sym, "symptom_high_temp",     { id: "symptom_high_temp",     name_ru: "Высокая температура",     category: "general" });
    variable_struct_set(_sym, "symptom_no_appetite",   { id: "symptom_no_appetite",   name_ru: "Отказ от еды",            category: "general" });
    variable_struct_set(_sym, "symptom_fatigue",       { id: "symptom_fatigue",       name_ru: "Быстрая утомляемость",    category: "general" });
    variable_struct_set(_sym, "symptom_dehydration",   { id: "symptom_dehydration",   name_ru: "Обезвоживание",           category: "general" });
    variable_struct_set(_sym, "symptom_weight_loss",   { id: "symptom_weight_loss",   name_ru: "Потеря веса",             category: "general" });
    variable_struct_set(_sym, "symptom_fever",         { id: "symptom_fever",         name_ru: "Лихорадка",               category: "general" });
    variable_struct_set(_sym, "symptom_shivers",       { id: "symptom_shivers",       name_ru: "Дрожь",                   category: "general" });

    // ── Мочевыделение ──
    variable_struct_set(_sym, "symptom_dark_urine",    { id: "symptom_dark_urine",    name_ru: "Тёмная моча",             category: "urinary" });
    variable_struct_set(_sym, "symptom_bloody_urine",  { id: "symptom_bloody_urine",  name_ru: "Кровь в моче",            category: "urinary" });
    variable_struct_set(_sym, "symptom_frequent_urine",{ id: "symptom_frequent_urine",name_ru: "Частое мочеиспускание",   category: "urinary" });
    variable_struct_set(_sym, "symptom_pain_urinate",  { id: "symptom_pain_urinate",  name_ru: "Боль при мочеиспускании", category: "urinary" });

    // ── Конечности / опора ──
    variable_struct_set(_sym, "symptom_lameness",           { id: "symptom_lameness",           name_ru: "Хромота",                category: "limb" });
    variable_struct_set(_sym, "symptom_pain",               { id: "symptom_pain",               name_ru: "Боль",                   category: "limb" });
    variable_struct_set(_sym, "symptom_swelling",           { id: "symptom_swelling",           name_ru: "Отёк",                   category: "limb" });
    variable_struct_set(_sym, "symptom_not_weight_bearing", { id: "symptom_not_weight_bearing", name_ru: "Не наступает на лапу",   category: "limb" });
    variable_struct_set(_sym, "symptom_joint_pain",        { id: "symptom_joint_pain",        name_ru: "Боль в суставах",        category: "limb" });
    variable_struct_set(_sym, "symptom_fracture_visible",  { id: "symptom_fracture_visible",  name_ru: "Видимая деформация лапы",category: "limb" });
    variable_struct_set(_sym, "symptom_wound",             { id: "symptom_wound",             name_ru: "Рана",                   category: "limb" });
    variable_struct_set(_sym, "symptom_bleeding",          { id: "symptom_bleeding",          name_ru: "Кровотечение",           category: "limb" });

    // ── ЖКТ ──
    variable_struct_set(_sym, "symptom_vomiting",      { id: "symptom_vomiting",      name_ru: "Рвота",                   category: "digestive" });
    variable_struct_set(_sym, "symptom_diarrhea",      { id: "symptom_diarrhea",      name_ru: "Понос",                   category: "digestive" });
    variable_struct_set(_sym, "symptom_bloody_stool",  { id: "symptom_bloody_stool",  name_ru: "Кровь в кале",            category: "digestive" });
    variable_struct_set(_sym, "symptom_abdominal_pain",{ id: "symptom_abdominal_pain",name_ru: "Боль в животе",            category: "digestive" });
    variable_struct_set(_sym, "symptom_constipation",  { id: "symptom_constipation",  name_ru: "Запор",                   category: "digestive" });

    // ── Дыхание / нос / горло ──
    variable_struct_set(_sym, "symptom_cough",         { id: "symptom_cough",         name_ru: "Кашель",                  category: "respiratory" });
    variable_struct_set(_sym, "symptom_coughing",      { id: "symptom_coughing",      name_ru: "Кашель",                  category: "respiratory" });
    variable_struct_set(_sym, "symptom_sneezing",      { id: "symptom_sneezing",      name_ru: "Чихание",                 category: "respiratory" });
    variable_struct_set(_sym, "symptom_runny_nose",    { id: "symptom_runny_nose",    name_ru: "Выделения из носа",       category: "respiratory" });
    variable_struct_set(_sym, "symptom_nasal_discharge",{id: "symptom_nasal_discharge",name_ru: "Выделения из носа",       category: "respiratory" });
    variable_struct_set(_sym, "symptom_eye_discharge", { id: "symptom_eye_discharge", name_ru: "Выделения из глаз",       category: "respiratory" });
    variable_struct_set(_sym, "symptom_eye_redness",   { id: "symptom_eye_redness",   name_ru: "Покраснение глаз",        category: "respiratory" });
    variable_struct_set(_sym, "symptom_eye_swelling",  { id: "symptom_eye_swelling",  name_ru: "Отёк век",                category: "respiratory" });
    variable_struct_set(_sym, "symptom_difficulty_breathing", { id: "symptom_difficulty_breathing", name_ru: "Затруднённое дыхание", category: "respiratory" });

    // ── Кожа / шерсть / паразиты ──
    variable_struct_set(_sym, "symptom_itching",       { id: "symptom_itching",       name_ru: "Зуд",                     category: "skin" });
    variable_struct_set(_sym, "symptom_skin_redness",  { id: "symptom_skin_redness",  name_ru: "Покраснение кожи",        category: "skin" });
    variable_struct_set(_sym, "symptom_hair_loss",     { id: "symptom_hair_loss",     name_ru: "Облысение",               category: "skin" });
    variable_struct_set(_sym, "symptom_fleas_visible", { id: "symptom_fleas_visible", name_ru: "Видны блохи",             category: "skin" });
    variable_struct_set(_sym, "symptom_scratching",    { id: "symptom_scratching",    name_ru: "Постоянно расчёсывается", category: "skin" });
    variable_struct_set(_sym, "symptom_restlessness",  { id: "symptom_restlessness",  name_ru: "Беспокойство",            category: "skin" });

    // ── Неврология ──
    variable_struct_set(_sym, "symptom_seizures",      { id: "symptom_seizures",      name_ru: "Судороги",                category: "neuro" });
    variable_struct_set(_sym, "symptom_paralysis",     { id: "symptom_paralysis",     name_ru: "Паралич",                 category: "neuro" });
    variable_struct_set(_sym, "symptom_disorientation",{ id: "symptom_disorientation",name_ru: "Дезориентация",           category: "neuro" });
    variable_struct_set(_sym, "symptom_head_tilt",     { id: "symptom_head_tilt",     name_ru: "Наклон головы",           category: "neuro" });

    // ── Уши ──
    variable_struct_set(_sym, "symptom_ear_discharge", { id: "symptom_ear_discharge", name_ru: "Выделения из уха",        category: "ear" });
    variable_struct_set(_sym, "symptom_ear_redness",   { id: "symptom_ear_redness",   name_ru: "Покраснение уха",         category: "ear" });
    variable_struct_set(_sym, "symptom_head_shake",    { id: "symptom_head_shake",    name_ru: "Трясёт головой",          category: "ear" });
    variable_struct_set(_sym, "symptom_ear_shake",     { id: "symptom_ear_shake",     name_ru: "Трясёт головой",          category: "ear" });
    variable_struct_set(_sym, "symptom_ear_odor",      { id: "symptom_ear_odor",      name_ru: "Неприятный запах из уха", category: "ear" });

    // ── Рот / зубы ──
    variable_struct_set(_sym, "symptom_bad_breath",    { id: "symptom_bad_breath",    name_ru: "Неприятный запах изо рта",category: "mouth" });
    variable_struct_set(_sym, "symptom_drooling",      { id: "symptom_drooling",      name_ru: "Повышенное слюнотечение", category: "mouth" });
    variable_struct_set(_sym, "symptom_gum_redness",   { id: "symptom_gum_redness",   name_ru: "Покраснение дёсен",       category: "mouth" });
    variable_struct_set(_sym, "symptom_tooth_pain",    { id: "symptom_tooth_pain",    name_ru: "Боль при жевании",        category: "mouth" });
    variable_struct_set(_sym, "symptom_pale_gums",     { id: "symptom_pale_gums",     name_ru: "Бледные дёсны",           category: "mouth" });


    // ═══════════════════════════════════════════════════════════
    // ПАКЕТ №68: НОВЫЕ СИМПТОМЫ (для 39 новых болезней)
    // ═══════════════════════════════════════════════════════════

    // ── Общие (продолжение) ──
    variable_struct_set(_sym, "symptom_thirst",        { id: "symptom_thirst",        name_ru: "Повышенная жажда",        category: "general" });
    variable_struct_set(_sym, "symptom_weight_gain",   { id: "symptom_weight_gain",   name_ru: "Набор веса",              category: "general" });
    variable_struct_set(_sym, "symptom_jaundice",      { id: "symptom_jaundice",      name_ru: "Желтушность",             category: "general" });
    variable_struct_set(_sym, "symptom_collapse",      { id: "symptom_collapse",      name_ru: "Коллапс",                 category: "general" });
    variable_struct_set(_sym, "symptom_fast_pulse",    { id: "symptom_fast_pulse",    name_ru: "Учащённый пульс",         category: "general" });
    variable_struct_set(_sym, "symptom_scooting",      { id: "symptom_scooting",      name_ru: "Ездит на попе",           category: "general" });

    // ── Дыхание (продолжение) ──
    variable_struct_set(_sym, "symptom_panting",       { id: "symptom_panting",       name_ru: "Учащённое дыхание",       category: "respiratory" });
    variable_struct_set(_sym, "symptom_nasal_crust",   { id: "symptom_nasal_crust",   name_ru: "Корки в носу",            category: "respiratory" });

    // ── Глаза ──
    variable_struct_set(_sym, "symptom_tearing",       { id: "symptom_tearing",       name_ru: "Слезотечение",            category: "eye" });
    variable_struct_set(_sym, "symptom_cloudy_eye",    { id: "symptom_cloudy_eye",    name_ru: "Помутнение глаза",        category: "eye" });
    variable_struct_set(_sym, "symptom_eye_pain",      { id: "symptom_eye_pain",      name_ru: "Боль в глазу",            category: "eye" });

    // ── ЖКТ (продолжение) ──
    variable_struct_set(_sym, "symptom_ascites",       { id: "symptom_ascites",       name_ru: "Вздутие живота",          category: "digestive" });
    variable_struct_set(_sym, "symptom_mucus_stool",   { id: "symptom_mucus_stool",   name_ru: "Слизь в кале",            category: "digestive" });
    variable_struct_set(_sym, "symptom_straining",     { id: "symptom_straining",     name_ru: "Натуживание",             category: "digestive" });

    // ── Кожа / шерсть (продолжение) ──
    variable_struct_set(_sym, "symptom_dull_coat",     { id: "symptom_dull_coat",     name_ru: "Тусклая шерсть",          category: "skin" });
    variable_struct_set(_sym, "symptom_hot_skin",      { id: "symptom_hot_skin",      name_ru: "Горячая кожа",            category: "skin" });
    variable_struct_set(_sym, "symptom_skin_flaking",  { id: "symptom_skin_flaking",  name_ru: "Шелушение кожи",          category: "skin" });
    variable_struct_set(_sym, "symptom_hives",         { id: "symptom_hives",         name_ru: "Крапивница",              category: "skin" });
    variable_struct_set(_sym, "symptom_circular_bald", { id: "symptom_circular_bald", name_ru: "Округлые проплешины",     category: "skin" });
    variable_struct_set(_sym, "symptom_dandruff",      { id: "symptom_dandruff",      name_ru: "Перхоть",                 category: "skin" });
    variable_struct_set(_sym, "symptom_ticks_visible", { id: "symptom_ticks_visible", name_ru: "Видны клещи",             category: "skin" });

    // ── Рот / зубы (продолжение) ──
    variable_struct_set(_sym, "symptom_plaque",         { id: "symptom_plaque",         name_ru: "Налёт на зубах",       category: "mouth" });
    variable_struct_set(_sym, "symptom_tooth_loosening",{ id: "symptom_tooth_loosening",name_ru: "Шатающиеся зубы",      category: "mouth" });
    variable_struct_set(_sym, "symptom_mouth_ulcers",   { id: "symptom_mouth_ulcers",   name_ru: "Язвы во рту",          category: "mouth" });

    // ── Конечности (продолжение) ──
    variable_struct_set(_sym, "symptom_back_pain",     { id: "symptom_back_pain",     name_ru: "Боль в спине",            category: "limb" });


    // ═══════════════════════════════════════════
    // Собираем symptom_ids — все идентификаторы подряд
    // (вместо ручных array_push на каждый симптом, чтобы не забыть)
    // ═══════════════════════════════════════════
    global.med_db.symptom_ids = [];
    var _all_sym_ids = variable_struct_get_names(_sym);
    for (var _i = 0; _i < array_length(_all_sym_ids); _i++) {
        array_push(global.med_db.symptom_ids, _all_sym_ids[_i]);
    }
}
