function staff_generate_appearance() {
    portrait_x = 150;
    portrait_y = 50;
    portrait_zoom = 1;

    var _m_h = [spr_fr_walk_hair_01, spr_fr_walk_hair_02, spr_fr_walk_hair_03, spr_fr_walk_hair_04, spr_fr_walk_hair_05];
    var _m_h_b = [spr_b_walk_hair_01, spr_b_walk_hair_02, spr_b_walk_hair_03, spr_b_walk_hair_04, spr_b_walk_hair_05];

    var _f_h = [spr_fr_walk_hair_06, spr_fr_walk_hair_07, spr_fr_walk_hair_08, spr_fr_walk_hair_09, spr_fr_walk_hair_10, spr_fr_walk_hair_11];
    var _f_h_b = [spr_b_walk_hair_06, spr_b_walk_hair_07, spr_b_walk_hair_08, spr_b_walk_hair_09, spr_b_walk_hair_10, spr_b_walk_hair_11];

    var _n_l = [spr_fr_walk_nose_01, spr_fr_walk_nose_02, spr_fr_walk_nose_03, spr_fr_walk_nose_04, spr_fr_walk_nose_05, spr_fr_walk_nose_06, spr_fr_walk_nose_07, spr_fr_walk_nose_08, spr_fr_walk_nose_09, spr_fr_walk_nose_10, spr_fr_walk_nose_11, spr_fr_walk_nose_12];
    var _e_l = [spr_fr_walk_eyes_01, spr_fr_walk_eyes_02];
    var _m_l = [spr_fr_walk_mouths_01, spr_fr_walk_mouths_02, spr_fr_walk_mouths_03, spr_fr_walk_mouths_04, spr_fr_walk_mouths_05];

    is_female = choose(false, true);
    char_name = get_random_name(is_female);
    age = irandom_range(23, 60);

    if (is_female) {
        var _idx = irandom(array_length(_f_h) - 1);
        my_hair = _f_h[_idx];
        my_hair_back = _f_h_b[_idx];
    } else {
        var _idx = irandom(array_length(_m_h) - 1);
        my_hair = _m_h[_idx];
        my_hair_back = _m_h_b[_idx];
    }

    my_nose  = _n_l[irandom(array_length(_n_l) - 1)];
    my_eyes  = _e_l[irandom(array_length(_e_l) - 1)];
    my_mouth = _m_l[irandom(array_length(_m_l) - 1)];

    hair_color = choose(
        c_white,
        c_yellow,
        c_orange,
        make_color_rgb(180, 100, 50),
        make_color_rgb(200, 200, 200)
    );

    character_trait = irandom(11);
    stat_energy = irandom_range(70, 100);
    p_move_speed = random_range(2.5, 3.5);
}


// ═══════════════════════════════════════════════════════════════
// Пакет 222: МЯГКАЯ ОКРАСКА ХАЛАТА ВРАЧА
// Пастельные тона почти без контраста — база халата светлая,
// image_blend лишь слегка подцвечивает. Персонаж носит свой
// оттенок постоянно (цвет генерируется один раз при найме).
// ═══════════════════════════════════════════════════════════════


// Цвет одежды НЕ назначается здесь (см. примечание пакета 225 ниже)
function staff_random_scrub_color() {
    // Пакет 227: расширенная палитра скрабов ассистентов — 24 цвета
    return choose(
        // синие/голубые
        make_color_rgb( 70, 130, 195),   // медицинский синий
        make_color_rgb( 35,  60, 130),   // тёмно-синий
        make_color_rgb(110, 180, 230),   // небесный
        make_color_rgb(120, 150, 170),   // серо-голубой
        // бирюзовые/зелёные
        make_color_rgb(  0, 168, 160),   // бирюзовый
        make_color_rgb(  0, 130, 140),   // тёмная бирюза
        make_color_rgb( 90, 200, 220),   // аква
        make_color_rgb(150, 220, 190),   // мятный
        make_color_rgb( 90, 175, 120),   // хирургический зелёный
        make_color_rgb(  0, 150, 110),   // изумрудный
        make_color_rgb(130, 190,  80),   // лаймовый
        make_color_rgb(140, 140,  80),   // оливковый
        // розовые/малиновые/красные
        make_color_rgb(230, 110, 160),   // малиновый
        make_color_rgb(250, 150, 190),   // розовый
        make_color_rgb(200,  60, 110),   // фуксия
        make_color_rgb(210,  70,  70),   // красный
        // фиолетовые/сиреневые
        make_color_rgb(150, 120, 200),   // фиолетовый
        make_color_rgb(110,  80, 170),   // тёмный аметист
        make_color_rgb(180, 160, 230),   // лавандовый
        // тёплые/жёлтые/оранжевые
        make_color_rgb(240, 130, 100),   // коралловый
        make_color_rgb(245, 150,  60),   // оранжевый
        make_color_rgb(235, 190,  70),   // горчичный
        make_color_rgb(250, 210,  90),   // жёлтый
        // нейтральные
        make_color_rgb(130, 135, 145)    // графитовый серый
    );
}

function staff_random_robe_color() {
    return choose(
        make_color_rgb(245, 245, 245),   // почти белый
        make_color_rgb(248, 228, 230),   // розоватый
        make_color_rgb(236, 230, 248),   // сиреневатый
        make_color_rgb(226, 236, 248),   // синеватый
        make_color_rgb(228, 244, 232),   // зеленоватый
        make_color_rgb(230, 244, 242),   // мятно-бирюзовый
        make_color_rgb(247, 240, 226),   // песочный
        make_color_rgb(238, 238, 240)    // жемчужно-серый
    );
}


// ═══════════════════════════════════════════════════════════════
// Пакет 225: ВНИМАНИЕ — цвет одежды здесь НЕ назначается.
// Скрипт зовётся в Create раньше role/id и даже без контекста
// инстанса (глобальный вызов) — там ничего нельзя читать.
// Цвет robe_color и узор scrub_pattern выдаёт Draw при первом
// кадре отрисовки персонажа (par_staff / obj_staff_assistant).
// ═══════════════════════════════════════════════════════════════


// Пакет 228: повседневная палитра ШТАНОВ посетителей/владельцев
function staff_random_pants_color() {
    return choose(
        make_color_rgb( 62,  82, 122),   // тёмный деним
        make_color_rgb(112, 142, 182),   // светлый деним
        make_color_rgb(112, 112, 118),   // серый
        make_color_rgb(188, 168, 138),   // бежевый
        make_color_rgb(142, 146, 112),   // хаки
        make_color_rgb(122,  92,  72),   // коричневый
        make_color_rgb( 62,  62,  66),   // чёрный
        make_color_rgb(102, 112,  92)    // болотный
    );
}


// Пакет 228: тёмная «врачева» палитра штанов под халат
function staff_random_doctor_pants_color() {
    return choose(
        make_color_rgb( 52,  62,  92),   // тёмно-синий
        make_color_rgb( 62,  62,  66),   // чёрный
        make_color_rgb( 85,  85,  90),   // тёмно-серый
        make_color_rgb(120, 118, 112),   // серый антрацит
        make_color_rgb( 92,  88,  62)    // тёмный хаки
    );
}


// Пакет 229: палитра КРОКСОВ сотрудникам
function staff_random_crocs_color() {
    return choose(
        make_color_rgb(245, 245, 245),   // белый
        make_color_rgb( 55,  55,  58),   // чёрный
        make_color_rgb(205,  60,  60),   // красный
        make_color_rgb( 60, 110, 200),   // синий
        make_color_rgb(110, 180, 230),   // голубой
        make_color_rgb( 80, 180, 110),   // зелёный
        make_color_rgb(240, 140, 180),   // розовый
        make_color_rgb(245, 140,  60),   // оранжевый
        make_color_rgb(150, 110, 200),   // фиолетовый
        make_color_rgb(  0, 170, 160)    // бирюзовый
    );
}

// Пакет 229: палитра БОТИНОК посетителям
function staff_random_boots_color() {
    return choose(
        make_color_rgb( 55,  50,  48),   // чёрные
        make_color_rgb( 90,  65,  45),   // тёмно-коричневые
        make_color_rgb(140, 105,  75),   // светло-коричневые
        make_color_rgb(120, 118, 115),   // серые
        make_color_rgb( 95,  55,  50)    // бордовые
    );
}