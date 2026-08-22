/// tablet_draw_staff_card.gml
/// @description Карточка сотрудника: левая треть — фото и данные, правая — навыки.
/// Пакет №77: специализация показывается только у врачей, у ассистентов — нет.
/// Пакет №110: в «Месте работы» — роли операционной (Хирург / Анестезиолог / Ассистент).
/// Пакет №159: специализация = самый прокачанный навык врача; кнопка места работы ×2.
/// Пакет №160: подпись «Место работы» выше, чтобы кнопка не закрывала низ букв.
/// Пакет №184: имя, роль, возраст и характер крупнее (каждая строка — своя
/// полоса с автоподгонкой масштаба), характер вынесен под фото на всю ширину,
/// подпись «Место работы» стоит в собственной полосе над кнопкой и больше
/// не подрезается ею снизу.


// ═══════════════════════════════════════════════════════════════
// 1. ВЫПУКЛАЯ ПАНЕЛЬ И СЛОИ ПОРТРЕТА
// ═══════════════════════════════════════════════════════════════

function tablet_staff_draw_portrait_part(
    _sprite,
    _x,
    _y,
    _width,
    _height,
    _zoom,
    _source_x,
    _source_y,
    _color
) {
    if (!sprite_exists(_sprite)) return;

    var _safe_zoom = max(0.01, _zoom);
    var _source_width = _width / _safe_zoom;
    var _source_height = _height / _safe_zoom;

    draw_sprite_general(
        _sprite,
        0,
        _source_x,
        _source_y,
        _source_width,
        _source_height,
        _x,
        _y,
        _safe_zoom,
        _safe_zoom,
        0,
        _color,
        _color,
        _color,
        _color,
        1
    );
}

function tablet_staff_draw_panel(_x1, _y1, _x2, _y2) {
    var _fill = make_color_rgb(246, 239, 226);
    var _line = make_color_rgb(180, 160, 140);
    var _highlight = make_color_rgb(255, 252, 242);

    draw_set_color(c_black);

    draw_set_alpha(0.025);
    draw_roundrect_ext(_x1 - 5, _y1 - 3, _x2 + 7, _y2 + 9, 12, 12, false);

    draw_set_alpha(0.040);
    draw_roundrect_ext(_x1 - 3, _y1 - 2, _x2 + 5, _y2 + 7, 11, 11, false);

    draw_set_alpha(0.065);
    draw_roundrect_ext(_x1 - 1, _y1, _x2 + 3, _y2 + 5, 10, 10, false);

    draw_set_alpha(1);
    draw_set_color(_fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, false);

    draw_set_color(_line);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 10, 10, true);

    draw_set_alpha(0.65);
    draw_set_color(_highlight);
    draw_line(_x1 + 10, _y1 + 2, _x2 - 10, _y1 + 2);

    draw_set_alpha(1);
    draw_set_color(c_white);
}


// ═══════════════════════════════════════════════════════════════
// 1.1 КРУПНЫЙ ТЕКСТ В ПОЛОСЕ (пакет №184)
// Карточка планшета живёт в своих мелких единицах, поэтому общий
// ui_fit_scale здесь не подходит: у него нижний порог UI_FS_MIN 0.72,
// а тут рабочие масштабы меньше единицы. Своя подгонка без порога:
// текст рисуется максимально крупно, но точно не вылезает за колонку
// и не выходит за высоту своей полосы.
// ═══════════════════════════════════════════════════════════════

function tablet_staff_fit_scale(_text, _max_w, _base) {
    var _str = string(_text);

    if (_str == "") return _base;
    if (_max_w <= 0) return _base;

    var _w = string_width(_str) * _base;

    if (_w <= _max_w) return _base;

    return max(_base * 0.42, _base * (_max_w / _w));
}

/// Одна строка данных: своя полоса высотой _row_h, текст по центру полосы.
/// Возвращает низ полосы — следующая строка начинается ровно с него.
function tablet_staff_text_row(_x, _row_y, _row_h, _text, _max_w, _base) {
    var _str = string(_text);

    if (_str != "") {
        var _scale = tablet_staff_fit_scale(_str, _max_w, _base);

        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_text_transformed(
            _x,
            _row_y + _row_h * 0.5,
            _str,
            _scale,
            _scale,
            0
        );
        draw_set_valign(fa_top);
    }

    return _row_y + _row_h;
}


// ═══════════════════════════════════════════════════════════════
// 2. ДАННЫЕ СОТРУДНИКА
// ═══════════════════════════════════════════════════════════════

function tablet_staff_get_role_name(_target) {
    if (!instance_exists(_target)) return "СОТРУДНИК";
    if (_target.object_index == obj_player) return "ГЛАВНЫЙ ВРАЧ";

    var _role = variable_instance_exists(_target, "role")
        ? string(_target.role)
        : "";

    switch (_role) {
        case "doctor": return "ВРАЧ";
        case "assistant": return "АССИСТЕНТ";
        case "admin": return "АДМИНИСТРАТОР";
    }

    return "СОТРУДНИК";
}

function tablet_staff_get_trait_name(_target) {
    var _traits = [
        "Спокойный",
        "Амбициозный",
        "Наставник",
        "Перфекционист",
        "Конфликтный",
        "Добрый",
        "Стрессоустойчивый",
        "Хаотичный",
        "Командный",
        "Замкнутый",
        "Карьерист",
        "Уставший"
    ];

    var _trait_index = variable_instance_exists(_target, "character_trait")
        ? clamp(round(_target.character_trait), 0, array_length(_traits) - 1)
        : 0;

    return _traits[_trait_index];
}


// ═══════════════════════════════════════════════════════════════
// 2.1 СПЕЦИАЛИЗАЦИЯ ВРАЧА (пакет №159)
// Самый прокачанный врачебный навык: сначала уровень, при равенстве XP.
// «Процедуры» в карточке скрыты — в специализацию не входят.
// У ассистента и администратора строки нет.
// ═══════════════════════════════════════════════════════════════

function doctor_get_specialty_title(_target) {
    if (!instance_exists(_target)) return "";

    var _is_player = (_target.object_index == obj_player);
    var _role = variable_instance_exists(_target, "role")
        ? string(_target.role)
        : "";

    if (!_is_player && _role != "doctor") return "";

    doctor_ensure_inpatient_skill(_target, false);

    var _names = doctor_get_skill_names();
    var _levels = variable_instance_exists(_target, "skills")
        ? _target.skills
        : array_create(array_length(_names), 1);
    var _xp = variable_instance_exists(_target, "skill_xp")
        ? _target.skill_xp
        : array_create(array_length(_levels), 0);

    var _best_index = 0;
    var _best_level = -1;
    var _best_xp = -1;
    var _count = min(array_length(_names), array_length(_levels));

    for (var _i = 0; _i < _count; _i++) {
        // Индекс 1 = ПРОЦЕДУРЫ — в карточке врача скрыт.
        if (_i == 1) continue;

        var _lv = clamp(round(_levels[_i]), 1, 10);
        var _cur_xp = (_i < array_length(_xp)) ? max(0, _xp[_i]) : 0;

        if (
            _lv > _best_level
            || (_lv == _best_level && _cur_xp > _best_xp)
        ) {
            _best_level = _lv;
            _best_xp = _cur_xp;
            _best_index = _i;
        }
    }

    if (_best_level < 0) return "";
    return string(_names[_best_index]);
}


// ═══════════════════════════════════════════════════════════════
// 3. ОСНОВНАЯ КАРТОЧКА СОТРУДНИКА
// ═══════════════════════════════════════════════════════════════

function tablet_draw_staff_card(
    _tablet,
    _target,
    _center_x,
    _center_y,
    _ui_scale,
    _frame_x,
    _frame_y,
    _photo_w,
    _photo_h
) {
    if (!instance_exists(_tablet)) return false;
    if (!instance_exists(_target)) return false;

    var _wood_dark = make_color_rgb(74, 49, 31);
    var _text = make_color_rgb(50, 38, 28);
    var _text_soft = make_color_rgb(84, 68, 54);
    var _blue = make_color_rgb(72, 112, 145);
    var _green = make_color_rgb(62, 112, 74);
    var _red = make_color_rgb(148, 74, 64);
    var _gold = make_color_rgb(180, 140, 64);


    // ═══════════════════════════════════════════════════════════
    // 3.1 СЕТКА: 1/3 ДАННЫЕ, 2/3 НАВЫКИ
    // ═══════════════════════════════════════════════════════════

    var _font_ui = _ui_scale * 1.16;
    var _gap = 7 * _ui_scale;
    var _padding = 8 * _ui_scale;

    // Верхние панели стоят на том же отступе от заголовка,
    // что и остальные панели друг от друга.
    var _content_top = _frame_y + 22 * _ui_scale;
    var _content_bottom = _frame_y + 304 * _ui_scale;

    // Подсказка остаётся внутри светлого листа.
    var _help_y1 = _content_bottom + _gap;
    var _help_y2 = _help_y1 + 65 * _ui_scale;

    var _card_x1 = _frame_x;
    var _card_x2 = _center_x + 260 * _ui_scale;
    var _total_width = _card_x2 - _card_x1;

    var _left_x1 = _card_x1;
    var _left_x2 = _card_x1 + _total_width * 0.34;
    var _right_x1 = _left_x2 + _gap;
    var _right_x2 = _card_x2;

    // Закрываем старую универсальную разметку планшета.
    draw_set_color(make_color_rgb(252, 250, 246));
    draw_rectangle(
        _card_x1 - 8 * _ui_scale,
        _frame_y - 12 * _ui_scale,
        _card_x2 + 8 * _ui_scale,
        _help_y2 + 8 * _ui_scale,
        false
    );


    // ═══════════════════════════════════════════════════════════
    // 3.2 ЗАГОЛОВОК
    // ═══════════════════════════════════════════════════════════

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(_wood_dark);
    draw_text_transformed(
        _center_x,
        _frame_y - 6 * _ui_scale,
        (_target.object_index == obj_player)
            ? "КАРТОЧКА ИГРОКА"
            : "КАРТОЧКА СОТРУДНИКА",
        0.78 * _font_ui,
        0.84 * _font_ui,
        0
    );

    draw_set_halign(fa_left);


    // ═══════════════════════════════════════════════════════════
    // 3.3 ЛЕВАЯ ВЕРХНЯЯ ПАНЕЛЬ: ФОТО И ДАННЫЕ
    // Пакет №159: панель чуть выше, чтобы влезла крупная кнопка места работы.
    // ═══════════════════════════════════════════════════════════

    var _info_x1 = _left_x1;
    var _info_y1 = _content_top;
    var _info_x2 = _left_x2;
    var _info_y2 = _info_y1 + 198 * _ui_scale;

    tablet_staff_draw_panel(_info_x1, _info_y1, _info_x2, _info_y2);

    // Полароид.
    var _portrait_x = _info_x1 + _padding;
    var _portrait_y = _info_y1 + 13 * _ui_scale;
    var _portrait_w = _photo_w;
    var _portrait_h = _photo_h;

    draw_set_color(make_color_rgb(255, 252, 210));
    draw_rectangle(
        _portrait_x,
        _portrait_y,
        _portrait_x + _portrait_w,
        _portrait_y + _portrait_h,
        false
    );

    draw_set_color(_wood_dark);
    draw_rectangle(
        _portrait_x,
        _portrait_y,
        _portrait_x + _portrait_w,
        _portrait_y + _portrait_h,
        true
    );

    var _portrait_inner_x = _portrait_x + 5 * _ui_scale;
    var _portrait_inner_y = _portrait_y + 5 * _ui_scale;
    var _portrait_inner_w = _portrait_w - 10 * _ui_scale;
    var _portrait_inner_h = _portrait_inner_w * 1.15;

    draw_set_color(make_color_rgb(180, 180, 180));
    draw_rectangle(
        _portrait_inner_x,
        _portrait_inner_y,
        _portrait_inner_x + _portrait_inner_w,
        _portrait_inner_y + _portrait_inner_h,
        false
    );

    if (
        variable_instance_exists(_target, "my_baked_portrait")
        && _target.my_baked_portrait != -1
        && sprite_exists(_target.my_baked_portrait)
    ) {
        draw_sprite_stretched(
            _target.my_baked_portrait,
            0,
            _portrait_inner_x,
            _portrait_inner_y,
            _portrait_inner_w,
            _portrait_inner_h
        );
    } else {
        // Главный игрок может не иметь baked portrait — рисуем его слоями.
        var _portrait_zoom = variable_instance_exists(_target, "portrait_zoom")
            ? _target.portrait_zoom
            : 1;
        var _portrait_source_x = variable_instance_exists(_target, "portrait_x")
            ? _target.portrait_x
            : 150;
        var _portrait_source_y = variable_instance_exists(_target, "portrait_y")
            ? _target.portrait_y
            : 50;

        tablet_staff_draw_portrait_part(
            spr_human_FR_walk,
            _portrait_inner_x,
            _portrait_inner_y,
            _portrait_inner_w,
            _portrait_inner_h,
            _portrait_zoom,
            _portrait_source_x,
            _portrait_source_y,
            c_white
        );

        if (variable_instance_exists(_target, "my_nose")) {
            tablet_staff_draw_portrait_part(_target.my_nose, _portrait_inner_x, _portrait_inner_y, _portrait_inner_w, _portrait_inner_h, _portrait_zoom, _portrait_source_x, _portrait_source_y, c_white);
        }

        if (variable_instance_exists(_target, "my_eyes")) {
            tablet_staff_draw_portrait_part(_target.my_eyes, _portrait_inner_x, _portrait_inner_y, _portrait_inner_w, _portrait_inner_h, _portrait_zoom, _portrait_source_x, _portrait_source_y, c_white);
        }

        if (variable_instance_exists(_target, "my_mouth")) {
            tablet_staff_draw_portrait_part(_target.my_mouth, _portrait_inner_x, _portrait_inner_y, _portrait_inner_w, _portrait_inner_h, _portrait_zoom, _portrait_source_x, _portrait_source_y, c_white);
        }

        if (variable_instance_exists(_target, "my_hair")) {
            var _portrait_hair_color = variable_instance_exists(_target, "hair_color")
                ? _target.hair_color
                : c_white;

            tablet_staff_draw_portrait_part(_target.my_hair, _portrait_inner_x, _portrait_inner_y, _portrait_inner_w, _portrait_inner_h, _portrait_zoom, _portrait_source_x, _portrait_source_y, _portrait_hair_color);
        }
    }

    draw_set_color(_wood_dark);
    draw_rectangle(
        _portrait_inner_x,
        _portrait_inner_y,
        _portrait_inner_x + _portrait_inner_w,
        _portrait_inner_y + _portrait_inner_h,
        true
    );

    var _tape_color = c_blue;
    var _role = variable_instance_exists(_target, "role") ? _target.role : "";

    if (_role == "assistant") _tape_color = make_color_rgb(110, 170, 110);
    if (_role == "admin") _tape_color = c_fuchsia;

    draw_set_color(_tape_color);
    draw_set_alpha(0.75);
    draw_line_width(
        _portrait_x - 3,
        _portrait_y + 8 * _ui_scale,
        _portrait_x + 15 * _ui_scale,
        _portrait_y - 3,
        4 * _ui_scale
    );
    draw_line_width(
        _portrait_x + _portrait_w - 15 * _ui_scale,
        _portrait_y + _portrait_h + 3,
        _portrait_x + _portrait_w + 3,
        _portrait_y + _portrait_h - 8 * _ui_scale,
        4 * _ui_scale
    );
    draw_set_alpha(1);

    // Текст справа от фотографии.
    var _data_x = _portrait_x + _portrait_w + 9 * _ui_scale;
    var _data_w = _info_x2 - _data_x - _padding;

    var _name = variable_instance_exists(_target, "char_name")
        ? string(_target.char_name)
        : "Сотрудник";
    var _age = variable_instance_exists(_target, "age")
        ? string(_target.age)
        : "?";
    var _role_name = tablet_staff_get_role_name(_target);
    var _specialty = doctor_get_specialty_title(_target);
    var _trait = tablet_staff_get_trait_name(_target);

    _target.specialty_title = _specialty;

    // ───────────────────────────────────────────────────────────
    // Пакет №184: данные крупнее и разложены по полосам.
    //
    // Справа от фотографии колонка узкая (примерно 84 юнита), поэтому
    // там живут только короткие строки: имя, роль (у врача сразу с его
    // профилем) и возраст. Длинная строка характера переехала ПОД фото,
    // на всю ширину панели: места вдвое больше, значит и шрифт крупнее.
    //
    // Масштаб каждой строки подбирается по её ширине, так что даже самое
    // длинное имя или «Стрессоустойчивый» не вылезут за панель.
    // ───────────────────────────────────────────────────────────

    var _col_y = _info_y1 + 12 * _ui_scale;

    draw_set_color(_blue);
    _col_y = tablet_staff_text_row(
        _data_x,
        _col_y,
        30 * _ui_scale,
        string_upper(_name),
        _data_w,
        0.95 * _font_ui
    );

    // Роль, а у врача сразу и его профиль: «ВРАЧ - ХИРУРГИЯ».
    var _role_line = _role_name;

    if (
        (_role == "doctor" || _target.object_index == obj_player)
        && _specialty != ""
    ) {
        _role_line += " - " + string_upper(_specialty);
    }

    draw_set_color(_text_soft);
    _col_y = tablet_staff_text_row(
        _data_x,
        _col_y,
        24 * _ui_scale,
        _role_line,
        _data_w,
        0.85 * _font_ui
    );

    draw_set_color(_text);
    _col_y = tablet_staff_text_row(
        _data_x,
        _col_y,
        22 * _ui_scale,
        "Возраст: " + _age,
        _data_w,
        0.80 * _font_ui
    );


    // ═══════════════════════════════════════════════════════════
    // 3.3.1 ХАРАКТЕР — ВО ВСЮ ШИРИНУ ПАНЕЛИ
    // Колонка справа от фото узкая, длинное слово вроде
    // «Стрессоустойчивый» там ужималось почти вдвое. Под фотографией
    // ширины ровно вдвое больше, поэтому строка читается крупно.
    // ═══════════════════════════════════════════════════════════

    var _energy_x1 = _info_x1 + _padding;
    var _energy_x2 = _info_x2 - _padding;
    var _wide_w = _energy_x2 - _energy_x1;

    draw_set_color(_text_soft);
    tablet_staff_text_row(
        _energy_x1,
        _info_y1 + 104 * _ui_scale,
        18 * _ui_scale,
        "Характер: " + _trait,
        _wide_w,
        0.72 * _font_ui
    );


    // ═══════════════════════════════════════════════════════════
    // 3.4 ЭНЕРГИЯ, ЗАРПЛАТА И ЛОЯЛЬНОСТЬ
    // ═══════════════════════════════════════════════════════════

    var _energy_current = variable_instance_exists(_target, "stat_energy")
        ? _target.stat_energy
        : 100;
    var _energy_max = variable_instance_exists(_target, "energy_max")
        ? max(1, _target.energy_max)
        : 100;
    var _energy_ratio = clamp(_energy_current / _energy_max, 0, 1);

    // Энергия всегда стоит на одном месте, независимо от того,
    // была ли строка специализации.
    var _energy_y = _info_y1 + 124 * _ui_scale;
    var _energy_color = _green;

    if (_energy_ratio <= 0.10) _energy_color = _red;
    else if (_energy_ratio <= 0.30) _energy_color = _gold;

    draw_set_color(_text_soft);
    tablet_staff_text_row(
        _energy_x1,
        _energy_y,
        14 * _ui_scale,
        "ЭНЕРГИЯ " + string(floor(_energy_current)) + "/" + string(round(_energy_max)),
        _wide_w,
        0.60 * _font_ui
    );

    var _energy_bar_y = _energy_y + 15 * _ui_scale;

    draw_set_color(make_color_rgb(220, 216, 207));
    draw_roundrect_ext(_energy_x1, _energy_bar_y, _energy_x2, _energy_bar_y + 7 * _ui_scale, 7, 7, false);

    draw_set_color(_energy_color);
    draw_roundrect_ext(
        _energy_x1,
        _energy_bar_y,
        _energy_x1 + (_energy_x2 - _energy_x1) * _energy_ratio,
        _energy_bar_y + 7 * _ui_scale,
        7,
        7,
        false
    );

    draw_set_color(_wood_dark);
    draw_roundrect_ext(_energy_x1, _energy_bar_y, _energy_x2, _energy_bar_y + 7 * _ui_scale, 7, 7, true);

    var _salary = variable_instance_exists(_target, "salary")
        ? _target.salary
        : (
            variable_instance_exists(_target, "skills_sum")
            ? _target.skills_sum * 10
            : 0
        );
    var _loyalty = variable_instance_exists(_target, "loyalty")
        ? _target.loyalty
        : 75;

    // Врач и ассистент получают раскрывающееся поле «Место работы»
    // в первом прямоугольнике. Администратор сохраняет зарплату и лояльность.
    var _has_workplace_menu = (
        _target.object_index != obj_player
        && (_role == "doctor" || _role == "assistant")
        && _target.object_index != obj_staff_candidate
    );

    if (_has_workplace_menu) {
        staff_workplace_init(_target);

        if (!variable_instance_exists(_tablet, "staff_workplace_menu_open")) {
            _tablet.staff_workplace_menu_open = false;
            _tablet.staff_workplace_menu_target = noone;
        }

        // Пакет №184: подпись «Место работы» больше не прячется под кнопкой.
        // Она рисуется от НИЗА своей полосы (valign по центру полосы),
        // а кнопка начинается только после этой полосы — хвосты букв
        // «р» и «б» всегда остаются на виду.
        var _workplace_caption_y = _info_y1 + 150 * _ui_scale;
        var _workplace_caption_h = 16 * _ui_scale;

        var _workplace_y1 = _workplace_caption_y + _workplace_caption_h;
        var _workplace_y2 = _info_y1 + 196 * _ui_scale;
        var _workplace_x1 = _energy_x1;
        var _workplace_x2 = _energy_x2;
        var _workplace_hover = point_in_rectangle(
            device_mouse_x_to_gui(0),
            device_mouse_y_to_gui(0),
            _workplace_x1,
            _workplace_y1,
            _workplace_x2,
            _workplace_y2
        );

        draw_set_color(_text);
        tablet_staff_text_row(
            _energy_x1,
            _workplace_caption_y,
            _workplace_caption_h,
            "Место работы:",
            _wide_w,
            0.62 * _font_ui
        );

        draw_set_color(_workplace_hover
            ? make_color_rgb(236, 226, 208)
            : make_color_rgb(246, 239, 226));
        draw_roundrect_ext(
            _workplace_x1,
            _workplace_y1,
            _workplace_x2,
            _workplace_y2,
            8,
            8,
            false
        );
        draw_set_color(_wood_dark);
        draw_roundrect_ext(
            _workplace_x1,
            _workplace_y1,
            _workplace_x2,
            _workplace_y2,
            8,
            8,
            true
        );

        var _workplace_label = staff_workplace_label_for(_target);

        if (_target.workplace_pending != "") {
            _workplace_label += " *";
        }

        // Текст кнопки: крупно, но с автоподгонкой — длинное
        // «ОПЕРАЦИОННАЯ: АНЕСТЕЗИОЛОГ» само ужмётся по ширине кнопки.
        var _workplace_scale = tablet_staff_fit_scale(
            _workplace_label,
            (_workplace_x2 - _workplace_x1) - 10 * _ui_scale,
            0.78 * _font_ui
        );

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(_blue);
        draw_text_transformed(
            (_workplace_x1 + _workplace_x2) * 0.5,
            (_workplace_y1 + _workplace_y2) * 0.5,
            _workplace_label,
            _workplace_scale,
            _workplace_scale,
            0
        );
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

        _tablet.staff_workplace_button_x1 = _workplace_x1;
        _tablet.staff_workplace_button_y1 = _workplace_y1;
        _tablet.staff_workplace_button_x2 = _workplace_x2;
        _tablet.staff_workplace_button_y2 = _workplace_y2;

        if (
            _workplace_hover
            && _tablet.tablet_click_lock <= 0
            && mouse_check_button_pressed(mb_left)
        ) {
            _tablet.tablet_click_lock = 5;

            if (
                _tablet.staff_workplace_menu_open
                && _tablet.staff_workplace_menu_target == _target
            ) {
                _tablet.staff_workplace_menu_open = false;
                _tablet.staff_workplace_menu_target = noone;
            } else {
                _tablet.staff_workplace_menu_open = true;
                _tablet.staff_workplace_menu_target = _target;
            }
        }
    }
    else if (_target.object_index != obj_player) {
        // Пакет №184: зарплата и лояльность — двумя строками во всю
        // ширину панели и крупно. В одну строку они не помещались
        // и рисовались вдвое мельче остального текста.
        draw_set_color(_text);
        tablet_staff_text_row(
            _energy_x1,
            _info_y1 + 152 * _ui_scale,
            20 * _ui_scale,
            "Зарплата: $ " + string(_salary),
            _wide_w,
            0.72 * _font_ui
        );

        tablet_staff_text_row(
            _energy_x1,
            _info_y1 + 172 * _ui_scale,
            20 * _ui_scale,
            "Лояльность: " + string(_loyalty) + "/100",
            _wide_w,
            0.72 * _font_ui
        );
    }


    // ═══════════════════════════════════════════════════════════
    // 3.5 ЛЕВАЯ НИЖНЯЯ ПАНЕЛЬ: ПОСЛЕДНИЕ НАВЫКИ
    // ═══════════════════════════════════════════════════════════

    var _log_x1 = _left_x1;
    var _log_y1 = _info_y2 + _gap;
    var _log_x2 = _left_x2;
    var _log_y2 = _content_bottom;

    tablet_staff_draw_panel(_log_x1, _log_y1, _log_x2, _log_y2);

    draw_set_color(_wood_dark);
    draw_text_transformed(
        _log_x1 + _padding,
        _log_y1 + 8 * _ui_scale,
        "ПОСЛЕДНИЕ НАВЫКИ:",
        0.47 * _font_ui,
        0.52 * _font_ui,
        0
    );

    var _log_entries = variable_instance_exists(_target, "xp_log")
        ? _target.xp_log
        : [];

    if (array_length(_log_entries) <= 0) {
        draw_set_color(make_color_rgb(120, 110, 95));
        draw_text_transformed(
            _log_x1 + _padding,
            _log_y1 + 28 * _ui_scale,
            "Нет записей",
            0.42 * _font_ui,
            0.47 * _font_ui,
            0
        );
    } else {
        for (var _log_index = 0; _log_index < min(5, array_length(_log_entries)); _log_index++) {
            var _entry = _log_entries[_log_index];
            var _entry_text = "";

            if (is_struct(_entry) && variable_struct_exists(_entry, "txt")) {
                _entry_text = string(_entry.txt);
            } else {
                _entry_text = string(_entry);
            }

            if (_entry_text == "") continue;

            draw_set_alpha(1 - _log_index * 0.12);
            draw_set_color(make_color_rgb(40, 110, 50));
            draw_text_ext_transformed(
                _log_x1 + _padding,
                _log_y1 + (26 + _log_index * 12) * _ui_scale,
                _entry_text,
                12 * _ui_scale,
                _log_x2 - _log_x1 - _padding * 2,
                0.42 * _font_ui,
                0.47 * _font_ui,
                0
            );
        }
    }

    draw_set_alpha(1);


    // ═══════════════════════════════════════════════════════════
    // 3.6 ПРАВАЯ ПАНЕЛЬ: ВСЕ НАВЫКИ
    // ═══════════════════════════════════════════════════════════

    tablet_staff_draw_panel(
        _right_x1,
        _content_top,
        _right_x2,
        _content_bottom
    );

    tablet_draw_staff_skills(
        _target,
        _right_x1 + _padding,
        _content_top + _padding,
        _right_x2 - _right_x1 - _padding * 2,
        _ui_scale,
        _tablet
    );


    // ═══════════════════════════════════════════════════════════
    // 3.7 НИЖНЯЯ ПОДСКАЗКА К ВЫБРАННОМУ НАВЫКУ
    // ═══════════════════════════════════════════════════════════

    tablet_staff_draw_panel(
        _card_x1,
        _help_y1,
        _card_x2,
        _help_y2
    );

    var _help_id = variable_instance_exists(_tablet, "staff_skill_help_id")
        ? string(_tablet.staff_skill_help_id)
        : "";
    var _help = tablet_get_staff_skill_help(_help_id);

    if (_help_id == "") {
        var _empty_help_scale_x = 0.56 * _font_ui;
        var _empty_help_scale_y = 0.63 * _font_ui;
        var _empty_help_width = (
            _card_x2 - _card_x1 - _padding * 2
        ) / max(0.01, _empty_help_scale_x);

        draw_set_color(make_color_rgb(120, 110, 95));
        draw_text_ext_transformed(
            _card_x1 + _padding,
            _help_y1 + 10 * _ui_scale,
            "Нажмите на навык, чтобы увидеть его описание.",
            7 * _ui_scale,
            _empty_help_width,
            _empty_help_scale_x,
            _empty_help_scale_y,
            0
        );
    } else {
        // Заголовок и описание используют один общий текстовый блок.
        var _help_full_text = _help.title + "\n" + _help.text;
        var _help_draw_x = _card_x1 + _padding;
        var _help_available_width = _card_x2 - _card_x1 - _padding * 2;
        var _help_scale_x = 0.60 * _font_ui;
        var _help_scale_y = 0.68 * _font_ui;

        // В draw_text_ext_transformed ширина переноса задаётся ДО масштабирования.
        // Поэтому реальную ширину окна делим на горизонтальный масштаб текста.
        var _help_wrap_width = _help_available_width / max(0.01, _help_scale_x);

        draw_set_color(_text_soft);
        draw_text_ext_transformed(
            _help_draw_x,
            _help_y1 + 6 * _ui_scale,
            _help_full_text,
            7 * _ui_scale,
            _help_wrap_width,
            _help_scale_x,
            _help_scale_y,
            0
        );
    }


    // ═══════════════════════════════════════════════════════════
    // 3.8 РАСКРЫВАЮЩИЙСЯ СПИСОК МЕСТА РАБОТЫ
    // Рисуется последним, поэтому находится поверх нижней левой панели.
    // ═══════════════════════════════════════════════════════════

    if (
        _has_workplace_menu
        && variable_instance_exists(_tablet, "staff_workplace_menu_open")
        && _tablet.staff_workplace_menu_open
        && _tablet.staff_workplace_menu_target == _target
    ) {
        // Пакет №110: у врача — роли ХИРУРГ / АНЕСТЕЗИОЛОГ, у ассистента — ОПЕРАЦИОННАЯ.
        var _option_ids;
        var _option_labels;

        if (_role == "doctor") {
            _option_ids = ["reception", "inpatient", "op_surgeon", "op_anesthetist"];
            _option_labels = ["НА ПРИЁМЕ", "СТАЦИОНАР", "ОПЕРАЦИОННАЯ: ХИРУРГ", "ОПЕРАЦИОННАЯ: АНЕСТЕЗИОЛОГ"];
        } else {
            _option_ids = ["reception", "inpatient", "op_assistant"];
            _option_labels = ["НА ПРИЁМЕ", "СТАЦИОНАР", "ОПЕРАЦИОННАЯ"];
        }
        var _option_x1 = _tablet.staff_workplace_button_x1;
        var _option_x2 = _tablet.staff_workplace_button_x2;
        var _option_h = 36 * _ui_scale;
        var _option_y = _tablet.staff_workplace_button_y2 + 2 * _ui_scale;
        var _menu_clicked = false;
        var _menu_mouse_x = device_mouse_x_to_gui(0);
        var _menu_mouse_y = device_mouse_y_to_gui(0);

        for (var _option_index = 0; _option_index < array_length(_option_ids); _option_index++) {
            var _option_y1 = _option_y + _option_index * _option_h;
            var _option_y2 = _option_y1 + _option_h;
            var _option_hover = point_in_rectangle(
                _menu_mouse_x,
                _menu_mouse_y,
                _option_x1,
                _option_y1,
                _option_x2,
                _option_y2
            );
            var _option_id = _option_ids[_option_index];
            var _option_role = staff_operating_role_of(_option_id);
            var _option_selected = (_option_role != "")
                ? (
                    _target.workplace_id == "operating"
                    && variable_instance_exists(_target, "operating_role")
                    && _target.operating_role == _option_role
                )
                : (_target.workplace_id == _option_id);

            // Допуск к роли (пакет №110): серым, если навык ниже 3.
            var _option_allowed = (_option_role == "")
                || staff_operating_role_allowed(_target, _option_role);

            draw_set_color(_option_hover && _option_allowed
                ? make_color_rgb(224, 236, 218)
                : (_option_selected
                    ? make_color_rgb(232, 240, 248)
                    : (_option_allowed
                        ? make_color_rgb(246, 239, 226)
                        : make_color_rgb(214, 208, 196))));
            draw_rectangle(
                _option_x1,
                _option_y1,
                _option_x2,
                _option_y2,
                false
            );
            draw_set_color(_wood_dark);
            draw_rectangle(
                _option_x1,
                _option_y1,
                _option_x2,
                _option_y2,
                true
            );

            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(_option_allowed
                ? (_option_selected ? _blue : _text)
                : make_color_rgb(150, 140, 126));
            draw_text_transformed(
                (_option_x1 + _option_x2) * 0.5,
                (_option_y1 + _option_y2) * 0.5,
                _option_labels[_option_index],
                0.68 * _font_ui,
                0.78 * _font_ui,
                0
            );

            if (
                _option_hover
                && _tablet.tablet_click_lock <= 0
                && mouse_check_button_pressed(mb_left)
            ) {
                if (_option_allowed) {
                    _tablet.tablet_click_lock = 5;
                    staff_workplace_request(_target, _option_id);
                    _tablet.staff_workplace_menu_open = false;
                    _tablet.staff_workplace_menu_target = noone;
                } else {
                    // Нет допуска — уведомление, меню закрываем.
                    _tablet.tablet_click_lock = 5;

                    if (instance_exists(obj_UI_HUD)) {
                        var _hud_skill = instance_find(obj_UI_HUD, 0);

                        if (
                            instance_exists(_hud_skill)
                            && variable_instance_exists(_hud_skill, "show_notice")
                        ) {
                            with (_hud_skill) {
                                show_notice(
                                    "НУЖЕН НАВЫК 3+",
                                    staff_operating_role_skill_name(_option_role)
                                        + " не ниже 3 уровня.",
                                    room_speed * 3
                                );
                            }
                        }
                    }

                    _tablet.staff_workplace_menu_open = false;
                    _tablet.staff_workplace_menu_target = noone;
                }

                _menu_clicked = true;
            }
        }

        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

        if (
            !_menu_clicked
            && _tablet.tablet_click_lock <= 0
            && mouse_check_button_pressed(mb_left)
        ) {
            var _menu_bottom = _option_y + array_length(_option_ids) * _option_h;
            var _inside_menu = point_in_rectangle(
                _menu_mouse_x,
                _menu_mouse_y,
                _option_x1,
                _option_y,
                _option_x2,
                _menu_bottom
            );
            var _inside_button = point_in_rectangle(
                _menu_mouse_x,
                _menu_mouse_y,
                _tablet.staff_workplace_button_x1,
                _tablet.staff_workplace_button_y1,
                _tablet.staff_workplace_button_x2,
                _tablet.staff_workplace_button_y2
            );

            if (!_inside_menu && !_inside_button) {
                _tablet.staff_workplace_menu_open = false;
                _tablet.staff_workplace_menu_target = noone;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 3.9 СБРОС DRAW
    // ═══════════════════════════════════════════════════════════

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);

    return true;
}
