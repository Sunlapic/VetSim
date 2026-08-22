/// tablet_draw_staff_skills(_target, _x, _y, _width, _ui_scale, _tablet)
/// @description Компактные группы навыков, прогресс текущего уровня и кликабельные пояснения.


// ═══════════════════════════════════════════════════════════════
// 0. ТЕКСТЫ ПОЯСНЕНИЙ К НАВЫКАМ
// ═══════════════════════════════════════════════════════════════

function tablet_get_staff_skill_help(_help_id) {
    switch (_help_id) {
        case "therapy":
            return { title : "ТЕРАПИЯ", text : "Уменьшает количество неверных обследований и назначений. Прокачивается за правильные назначения и успешные приёмы." };

        case "surgery":
            return { title : "ХИРУРГИЯ", text : "Влияет на качество лечения переломов, ран и кровотечений. Прокачивается за успешное лечение хирургических случаев." };

        case "ophthalmology":
            return { title : "ОФТАЛЬМОЛОГИЯ", text : "Влияет на диагностику и лечение болезней глаз. Прокачивается за успешное лечение глазных заболеваний." };

        case "otolaryngology":
            return { title : "ОТОЛАРИНГОЛОГИЯ", text : "Влияет на диагностику и лечение болезней ушей и носа. Прокачивается за успешные профильные случаи." };

        case "dermatology":
            return { title : "ДЕРМАТОЛОГИЯ", text : "Влияет на диагностику и лечение болезней кожи. Прокачивается за успешные дерматологические случаи." };

        case "infectious":
            return { title : "ИНФЕКЦИИ И ТОКСИКОЛОГИЯ", text : "Влияет на лечение инфекций и отравлений. Прокачивается за успешное лечение профильных случаев." };

        case "anesthesia":
            return { title : "АНЕСТЕЗИОЛОГИЯ", text : "Влияет на скорость подготовки и безопасность анестезии. Прокачивается при успешных процедурах с наркозом." };

        case "laboratory":
            return { title : "ЛАБОРАТОРИЯ", text : "Влияет на скорость и точность лабораторных обследований. Прокачивается за правильно выполненные анализы." };

        case "dentistry":
            return { title : "СТОМАТОЛОГИЯ", text : "Влияет на диагностику и лечение болезней зубов. Прокачивается за успешные стоматологические случаи." };

        case "inpatient":
            return { title : "СТАЦИОНАР", text : "Определяет скорость и качество врачебных назначений в стационаре. За полностью вылеченного стационарного пациента врач один раз получает 80 XP." };

        case "registration":
            return { title : "РЕГИСТРАЦИЯ", text : "Уменьшает время оформления клиента. Прокачивается за каждую успешно завершённую регистрацию." };

        case "cash":
            return { title : "КАССА", text : "Уменьшает время приёма оплаты. Прокачивается за каждую успешно принятую оплату." };

        case "procedures":
            return { title : "ПРОЦЕДУРЫ", text : "Уменьшает время выполнения назначенных процедур. Прокачивается за каждую успешно выполненную процедуру." };

        case "restock":
            return { title : "ПОПОЛНЕНИЕ", text : "Уменьшает время взятия и укладки препаратов. Увеличивает переносимый запас с 5 до 15 предметов. Прокачивается за успешное пополнение шкафа." };

        case "cleaning":
            return { title : "УБОРКА", text : "Уменьшает время очистки пятна с 10 секунд на первом уровне до 1 секунды на десятом. Прокачивается за каждое полностью убранное пятно." };

        case "walk_speed":
            return { title : "СКОРОСТЬ ХОДЬБЫ", text : "На 1 уровне персонаж движется со скоростью 100%. Каждый следующий уровень добавляет +10%. Прокачивается за каждые 30 секунд фактической ходьбы." };

        case "stamina":
            return { title : "ВЫНОСЛИВОСТЬ", text : "Увеличивает максимальный запас энергии на 10 за уровень. Прокачивается при наступлении усталости." };
    }

    return { title : "НАВЫК", text : "Выберите навык, чтобы увидеть его описание." };
}


// ═══════════════════════════════════════════════════════════════
// 1. СТРОКА НАВЫКА
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// 0. РАЗМЕРЫ ТАБЛИЦЫ НАВЫКОВ (пакет №197)
//
// Раньше строка навыка была жёстко 10.5 юнита, а шрифт 0.52 — на телефоне
// это самый мелкий текст в игре. Теперь размер считается от свободного
// места: сколько высоты есть, настолько крупными и будут строки.
// Больше строк (у главного игрока их 15) — чуть мельче, но всё влезает.
// ═══════════════════════════════════════════════════════════════

function tablet_skill_metrics(_ui_scale, _row_count, _group_count, _max_height, _min_row = 17) {
    var _rows = max(1, _row_count);
    var _groups = max(1, _group_count);

    // Высота в «юнитах» карточки (то есть без учёта общего масштаба).
    var _avail = (_max_height > 0)
        ? (_max_height / max(0.01, _ui_scale))
        : 999;

    // Постоянные траты: заголовок «НАВЫКИ», отступы и зазоры групп.
    var _fixed = 26 + _groups * 11;
    var _row_h = (_avail - _fixed) / (_rows + _groups);

    // Пакет №198: нижняя граница поднята — шрифт больше не мельчает под
    // количество строк. Если строки не влезают, включается прокрутка.
    _row_h = clamp(_row_h, _min_row, 21);

    var _font = clamp(_row_h * 0.052, _min_row * 0.052, 1.05);

    return {
        row_h : _row_h,
        header_h : _row_h + 4,
        font : _font,
        font_small : _font * 0.85,
        font_title : _font * 1.12
    };
}

/// Метрики по умолчанию, если вызывающий их не передал.
function tablet_skill_metrics_default(_ui_scale) {
    return tablet_skill_metrics(_ui_scale, 12, 2, 0);
}

/// Метрики для панели без прокрутки (карточка кандидата): там строки
/// обязаны поместиться целиком, поэтому разрешаем ужиматься сильнее.
function tablet_skill_metrics_fit(_ui_scale, _row_count, _group_count, _max_height) {
    return tablet_skill_metrics(
        _ui_scale,
        _row_count,
        _group_count,
        _max_height,
        10.5
    );
}


function tablet_draw_compact_skill_row(
    _x,
    _y,
    _width,
    _ui_scale,
    _row,
    _metrics = undefined
) {
    if (!is_struct(_metrics)) _metrics = tablet_skill_metrics_default(_ui_scale);

    var _level = clamp(round(_row.level), 1, 10);
    var _current_xp = max(0, _row.xp);
    var _needed_xp = max(1, _row.need);

    // Колонки заданы долями ширины — при любом шрифте ничего не наезжает.
    var _level_x = _x + _width * 0.32;
    var _bar_x = _x + _width * 0.37;
    var _bar_w = _width * 0.27;
    var _bar_h = min(_metrics.row_h * 0.72, 13) * _ui_scale;

    var _fill_ratio = (_level >= 10)
        ? 1
        : clamp(_current_xp / _needed_xp, 0, 1);

    var _fill_color = c_green;

    if (_level <= 5) {
        _fill_color = merge_color(c_red, c_orange, _level / 5);
    } else {
        _fill_color = merge_color(c_orange, c_lime, (_level - 5) / 5);
    }

    if (_level >= 10) {
        _fill_color = make_color_rgb(255, 215, 0);
    }

    // Все элементы строки используют один вертикальный центр.
    var _row_h = _metrics.row_h * _ui_scale;
    var _row_center_y = _y + _row_h * 0.5;
    var _bar_y1 = _row_center_y - _bar_h * 0.5;
    var _bar_y2 = _row_center_y + _bar_h * 0.5;

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);

    // Название навыка: крупно, но с автоподгонкой под ширину колонки,
    // чтобы «ОТОЛАРИНГОЛОГИЯ» не залезала на уровень.
    var _name_scale = tablet_staff_fit_scale(
        _row.name,
        (_level_x - _x) - 6 * _ui_scale,
        _metrics.font * _ui_scale
    );

    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text_transformed(
        _x,
        _row_center_y,
        _row.name,
        _name_scale,
        _name_scale,
        0
    );

    draw_set_color(make_color_rgb(84, 68, 54));
    draw_text_transformed(
        _level_x,
        _row_center_y,
        string(_level),
        _metrics.font * _ui_scale,
        _metrics.font * _ui_scale,
        0
    );

    draw_set_color(make_color_rgb(220, 216, 207));
    draw_roundrect_ext(
        _bar_x,
        _bar_y1,
        _bar_x + _bar_w,
        _bar_y2,
        6,
        6,
        false
    );

    if (_fill_ratio > 0) {
        draw_set_color(_fill_color);
        draw_roundrect_ext(
            _bar_x,
            _bar_y1,
            _bar_x + _bar_w * _fill_ratio,
            _bar_y2,
            6,
            6,
            false
        );
    }

    draw_set_color(make_color_rgb(58, 39, 24));
    draw_roundrect_ext(
        _bar_x,
        _bar_y1,
        _bar_x + _bar_w,
        _bar_y2,
        6,
        6,
        true
    );

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text_transformed(
        _bar_x + _bar_w * 0.5,
        _row_center_y,
        (_level >= 10)
            ? "МАКС"
            : string(floor(_current_xp)) + "/" + string(round(_needed_xp)),
        _metrics.font_small * _ui_scale,
        _metrics.font_small * _ui_scale,
        0
    );

    var _speed_text = variable_struct_exists(_row, "speed")
        ? string(_row.speed)
        : "-";
    var _quality_text = variable_struct_exists(_row, "quality")
        ? string(_row.quality)
        : "-";

    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(84, 68, 54));
    draw_text_transformed(
        _x + _width * 0.72,
        _row_center_y,
        _speed_text,
        _metrics.font * _ui_scale,
        _metrics.font * _ui_scale,
        0
    );

    draw_text_transformed(
        _x + _width * 0.90,
        _row_center_y,
        _quality_text,
        _metrics.font * _ui_scale,
        _metrics.font * _ui_scale,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ═══════════════════════════════════════════════════════════════
// 2. ГРУППА НАВЫКОВ
// ═══════════════════════════════════════════════════════════════

function tablet_draw_compact_skill_group(
    _x,
    _y,
    _width,
    _ui_scale,
    _title,
    _rows,
    _fill_color,
    _line_color,
    _tablet,
    _metrics = undefined
) {
    if (!is_array(_rows) || array_length(_rows) <= 0) return _y;
    if (!is_struct(_metrics)) _metrics = tablet_skill_metrics_default(_ui_scale);

    var _header_h = _metrics.header_h * _ui_scale;
    var _row_h = _metrics.row_h * _ui_scale;
    var _bottom_padding = 3 * _ui_scale;
    var _height = _header_h + array_length(_rows) * _row_h + _bottom_padding;

    draw_set_color(_fill_color);
    draw_roundrect_ext(
        _x,
        _y,
        _x + _width,
        _y + _height,
        8,
        8,
        false
    );

    draw_set_color(_line_color);
    draw_roundrect_ext(
        _x,
        _y,
        _x + _width,
        _y + _height,
        8,
        8,
        true
    );

    draw_set_color(_line_color);
    draw_text_transformed(
        _x + 6 * _ui_scale,
        _y + 3 * _ui_scale,
        _title,
        _metrics.font_title * _ui_scale,
        _metrics.font_title * _ui_scale,
        0
    );

    for (var _row_index = 0; _row_index < array_length(_rows); _row_index++) {
        var _row_y = _y + _header_h + _row_index * _row_h;
        var _display_row_number = _row_index + 1;
        var _is_even_row = (_display_row_number mod 2 == 0);

        // Полосатая таблица: чётные строки темнее, нечётные светлее.
        draw_set_alpha(_is_even_row ? 0.10 : 0.08);
        draw_set_color(_is_even_row ? _line_color : c_white);
        draw_roundrect_ext(
            _x + 4 * _ui_scale,
            _row_y,
            _x + _width - 4 * _ui_scale,
            _row_y + _row_h,
            4,
            4,
            false
        );
        draw_set_alpha(1);

        var _mouse_x = device_mouse_x_to_gui(0);
        var _mouse_y = device_mouse_y_to_gui(0);
        var _hovered = point_in_rectangle(
            _mouse_x,
            _mouse_y,
            _x + 4 * _ui_scale,
            _row_y,
            _x + _width - 4 * _ui_scale,
            _row_y + _row_h
        );

        var _help_id = variable_struct_exists(_rows[_row_index], "help_id")
            ? string(_rows[_row_index].help_id)
            : "";
        var _selected = (
            instance_exists(_tablet)
            && variable_instance_exists(_tablet, "staff_skill_help_id")
            && _tablet.staff_skill_help_id == _help_id
        );

        if (_hovered || _selected) {
            draw_set_alpha(_selected ? 0.22 : 0.12);
            draw_set_color(_line_color);
            draw_roundrect_ext(
                _x + 4 * _ui_scale,
                _row_y,
                _x + _width - 4 * _ui_scale,
                _row_y + _row_h,
                4,
                4,
                false
            );
            draw_set_alpha(1);
        }

        tablet_draw_compact_skill_row(
            _x + 7 * _ui_scale,
            _row_y,
            _width - 14 * _ui_scale,
            _ui_scale,
            _rows[_row_index],
            _metrics
        );

        if (
            _hovered
            && _help_id != ""
            && instance_exists(_tablet)
            && _tablet.tablet_click_lock <= 0
            && mouse_check_button_pressed(mb_left)
        ) {
            _tablet.tablet_click_lock = 5;
            _tablet.staff_skill_help_id = _help_id;
        }
    }

    return _y + _height;
}


// ═══════════════════════════════════════════════════════════════
// 3. ОСНОВНАЯ ПАНЕЛЬ НАВЫКОВ
// ═══════════════════════════════════════════════════════════════

function tablet_draw_staff_skills(
    _target,
    _x,
    _y,
    _width,
    _ui_scale,
    _tablet = noone,
    _max_height = 0
) {
    if (!instance_exists(_target)) return;

    if (instance_exists(_tablet)) {
        if (!variable_instance_exists(_tablet, "staff_skill_help_id")) {
            _tablet.staff_skill_help_id = "";
        }

        if (
            !variable_instance_exists(_tablet, "staff_skill_help_target")
            || _tablet.staff_skill_help_target != _target
        ) {
            _tablet.staff_skill_help_target = _target;
            _tablet.staff_skill_help_id = "";
        }
    }

    var _doctor_rows = [];
    var _admin_rows = [];
    var _assistant_rows = [];
    var _common_rows = [];
    var _is_player = (_target.object_index == obj_player);
    var _role = variable_instance_exists(_target, "role")
        ? string(_target.role)
        : "";


    // ═══════════════════════════════════════════════════════════
    // 3.1 ВРАЧЕБНЫЕ НАВЫКИ
    // ═══════════════════════════════════════════════════════════

    if (_role == "doctor" || _is_player) {
        var _doctor_names = doctor_get_skill_names();
        var _doctor_help_ids = [
            "therapy",
            "procedures",
            "surgery",
            "ophthalmology",
            "otolaryngology",
            "dermatology",
            "infectious",
            "anesthesia",
            "laboratory",
            "dentistry",
            "inpatient"
        ];
        doctor_ensure_inpatient_skill(_target, false);

        var _doctor_levels = variable_instance_exists(_target, "skills")
            ? _target.skills
            : array_create(11, 1);
        var _doctor_xp = variable_instance_exists(_target, "skill_xp")
            ? _target.skill_xp
            : array_create(array_length(_doctor_levels), 0);

        for (var _doctor_index = 0; _doctor_index < min(array_length(_doctor_names), array_length(_doctor_levels)); _doctor_index++) {
            // Процедуры выводятся в отдельном ассистентском блоке игрока.
            if (_doctor_index == 1) continue;

            var _doctor_level = clamp(round(_doctor_levels[_doctor_index]), 1, 10);
            var _doctor_current_xp = (_doctor_index < array_length(_doctor_xp))
                ? _doctor_xp[_doctor_index]
                : 0;
            var _doctor_needed_xp = (_doctor_level >= 10)
                ? 1
                : doctor_xp_needed(_doctor_level);

            var _doctor_quality = round(lerp(60, 100, (_doctor_level - 1) / 9));
            var _doctor_speed = round(lerp(12, 4, (_doctor_level - 1) / 9) * 10) / 10;

            if (_doctor_index == 0) {
                _doctor_quality = 100 - round(
                    doctor_get_therapy_error_chance(_doctor_level) * 100
                );
                _doctor_speed = round(
                    doctor_get_exam_duration_frames(_doctor_level)
                    / room_speed
                    * 10
                ) / 10;
            }

            array_push(_doctor_rows, {
                name : _doctor_names[_doctor_index],
                level : _doctor_level,
                xp : _doctor_current_xp,
                need : _doctor_needed_xp,
                speed : _is_player ? "-" : string(_doctor_speed) + "С",
                quality : string(_doctor_quality) + "%",
                help_id : (_doctor_index < array_length(_doctor_help_ids))
                    ? _doctor_help_ids[_doctor_index]
                    : ""
            });
        }

    }


    // ═══════════════════════════════════════════════════════════
    // 3.2 АДМИНИСТРАТИВНЫЕ НАВЫКИ
    // ═══════════════════════════════════════════════════════════

    if (_is_player) {
        player_extra_skills_init(_target);

        for (var _player_admin_index = 0; _player_admin_index < 2; _player_admin_index++) {
            var _player_admin_level = _target.player_admin_skill_levels[_player_admin_index];

            var _player_admin_seconds = round(
                lerp(10, 1, (_player_admin_level - 1) / 9) * 10
            ) / 10;

            array_push(_admin_rows, {
                name : (_player_admin_index == 0) ? "РЕГИСТРАЦИЯ" : "КАССА",
                level : _player_admin_level,
                xp : _target.player_admin_skill_xp[_player_admin_index],
                need : (_player_admin_level >= 10)
                    ? 1
                    : secondary_skill_xp_needed(_player_admin_level),
                speed : string(_player_admin_seconds) + "С",
                quality : "-",
                help_id : (_player_admin_index == 0) ? "registration" : "cash"
            });
        }
    }
    else if (_role == "admin") {
        var _admin_names = ["РЕГИСТРАЦИЯ", "КАССА"];
        var _admin_levels = variable_instance_exists(_target, "skill_level")
            ? _target.skill_level
            : [1, 1];
        var _admin_xp = variable_instance_exists(_target, "skill_xp")
            ? _target.skill_xp
            : [0, 0];

        for (var _admin_index = 0; _admin_index < min(2, array_length(_admin_levels)); _admin_index++) {
            var _admin_level = clamp(round(_admin_levels[_admin_index]), 1, 10);
            var _admin_meta = "";

            switch (_admin_index) {
                case 0:
                case 1:
                    _admin_meta = string(
                        round(lerp(10, 1, (_admin_level - 1) / 9) * 10) / 10
                    ) + "С";
                break;

                case 2:
                    _admin_meta = string(
                        round(lerp(1.4, 2.4, (_admin_level - 1) / 9) * 10) / 10
                    );
                break;
            }

            var _admin_needed_xp = secondary_skill_xp_needed(_admin_level);

            if (
                variable_instance_exists(_target, "skill_xp_needed")
                && _admin_index < array_length(_target.skill_xp_needed)
            ) {
                _admin_needed_xp = max(1, _target.skill_xp_needed[_admin_index]);
            }

            array_push(_admin_rows, {
                name : _admin_names[_admin_index],
                level : _admin_level,
                xp : (_admin_index < array_length(_admin_xp)) ? _admin_xp[_admin_index] : 0,
                need : (_admin_level >= 10) ? 1 : _admin_needed_xp,
                speed : _admin_meta,
                quality : "-",
                help_id : (_admin_index == 0) ? "registration" : "cash"
            });
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 3.3 АССИСТЕНТСКИЕ НАВЫКИ
    // ═══════════════════════════════════════════════════════════

    if (_is_player) {
        player_extra_skills_init(_target);

        for (var _player_assistant_index = 0; _player_assistant_index < 3; _player_assistant_index++) {
            var _player_assistant_level = _target.player_assistant_skill_levels[_player_assistant_index];

            var _player_assistant_names = [
                "ПРОЦЕДУРЫ",
                "ПОПОЛНЕНИЕ",
                "УБОРКА"
            ];
            var _player_assistant_help = [
                "procedures",
                "restock",
                "cleaning"
            ];
            var _player_assistant_speed = "-";

            if (_player_assistant_index == 2) {
                _player_assistant_speed = string(
                    round(
                        cleaning_get_duration_frames(_player_assistant_level)
                        / room_speed
                        * 10
                    ) / 10
                ) + "С";
            }

            array_push(_assistant_rows, {
                name : _player_assistant_names[_player_assistant_index],
                level : _player_assistant_level,
                xp : _target.player_assistant_skill_xp[_player_assistant_index],
                need : (_player_assistant_level >= 10)
                    ? 1
                    : secondary_skill_xp_needed(_player_assistant_level),
                speed : _player_assistant_speed,
                quality : "-",
                help_id : _player_assistant_help[_player_assistant_index]
            });
        }
    }
    else if (_role == "assistant") {
        assistant_extra_skills_init(_target);

        for (var _assistant_index = 0; _assistant_index < 3; _assistant_index++) {
            var _assistant_level = _target.assistant_skill_levels[_assistant_index];

            var _assistant_meta = "";

            if (_assistant_index == 0) {
                _assistant_meta = string(
                    round(lerp(5, 2, (_assistant_level - 1) / 9) * 10) / 10
                ) + "С";
            }
            else if (_assistant_index == 1) {
                _assistant_meta = string(
                    round(lerp(2.0, 0.7, (_assistant_level - 1) / 9) * 10) / 10
                ) + "С";
            }
            else {
                _assistant_meta = string(
                    round(
                        cleaning_get_duration_frames(_assistant_level)
                        / room_speed
                        * 10
                    ) / 10
                ) + "С";
            }

            var _assistant_names = [
                "ПРОЦЕДУРЫ",
                "ПОПОЛНЕНИЕ",
                "УБОРКА"
            ];
            var _assistant_help_ids = [
                "procedures",
                "restock",
                "cleaning"
            ];

            array_push(_assistant_rows, {
                name : _assistant_names[_assistant_index],
                level : _assistant_level,
                xp : _target.assistant_skill_xp[_assistant_index],
                need : (_assistant_level >= 10)
                    ? 1
                    : secondary_skill_xp_needed(_assistant_level),
                speed : (_assistant_meta == "") ? "-" : _assistant_meta,
                quality : "-",
                help_id : _assistant_help_ids[_assistant_index]
            });
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 3.4 ОБЩИЕ НАВЫКИ
    // Есть у главного игрока и у всех нанятых сотрудников.
    // ═══════════════════════════════════════════════════════════

    var _walk_level = variable_instance_exists(_target, "walk_skill_level")
        ? clamp(round(_target.walk_skill_level), 1, 10)
        : 1;
    var _walk_xp = variable_instance_exists(_target, "walk_skill_xp")
        ? _target.walk_skill_xp
        : 0;
    var _walk_need = variable_instance_exists(_target, "walk_skill_xp_needed")
        ? max(1, _target.walk_skill_xp_needed)
        : doctor_xp_needed(_walk_level);
    var _walk_speed_percent = 100 + (_walk_level - 1) * 10;

    array_push(_common_rows, {
        name : "СКОРОСТЬ ХОДЬБЫ",
        level : _walk_level,
        xp : _walk_xp,
        need : (_walk_level >= 10) ? 1 : _walk_need,
        speed : string(_walk_speed_percent) + "%",
        quality : "-",
        help_id : "walk_speed"
    });

    var _stamina_level = variable_instance_exists(_target, "stamina_level")
        ? clamp(round(_target.stamina_level), 1, 10)
        : 1;
    var _stamina_xp = variable_instance_exists(_target, "stamina_xp")
        ? _target.stamina_xp
        : 0;
    var _stamina_need = variable_instance_exists(_target, "stamina_xp_needed")
        ? max(1, _target.stamina_xp_needed)
        : doctor_xp_needed(_stamina_level);

    array_push(_common_rows, {
        name : "ВЫНОСЛИВОСТЬ",
        level : _stamina_level,
        xp : _stamina_xp,
        need : (_stamina_level >= 10) ? 1 : _stamina_need,
        speed : "-",
        quality : "-",
        help_id : "stamina"
    });


    // ═══════════════════════════════════════════════════════════
    // 3.5 ОТРИСОВКА С ПРОКРУТКОЙ (пакет №198)
    //
    // Шрифт больше не ужимается под количество строк: он всегда крупный.
    // Если строки не помещаются (у главного игрока их 15), список
    // прокручивается — колесом, перетягиванием пальцем и бегунком справа.
    // ═══════════════════════════════════════════════════════════

    // Плоский список: заголовки групп и строки навыков вперемешку,
    // ровно в том порядке, в котором они рисуются.
    var _items = [];

    if (array_length(_doctor_rows) > 0) {
        array_push(_items, {
            kind : "header",
            title : "ВРАЧ",
            fill : make_color_rgb(232, 240, 248),
            line : make_color_rgb(104, 135, 160)
        });

        for (var _di = 0; _di < array_length(_doctor_rows); _di++) {
            array_push(_items, {
                kind : "row",
                row : _doctor_rows[_di],
                fill : make_color_rgb(232, 240, 248),
                line : make_color_rgb(104, 135, 160)
            });
        }
    }

    if (array_length(_admin_rows) > 0) {
        array_push(_items, {
            kind : "header",
            title : "АДМИНИСТРАТОР",
            fill : make_color_rgb(248, 235, 240),
            line : make_color_rgb(158, 108, 128)
        });

        for (var _ai = 0; _ai < array_length(_admin_rows); _ai++) {
            array_push(_items, {
                kind : "row",
                row : _admin_rows[_ai],
                fill : make_color_rgb(248, 235, 240),
                line : make_color_rgb(158, 108, 128)
            });
        }
    }

    if (array_length(_assistant_rows) > 0) {
        array_push(_items, {
            kind : "header",
            title : "АССИСТЕНТ",
            fill : make_color_rgb(235, 246, 234),
            line : make_color_rgb(95, 140, 96)
        });

        for (var _si = 0; _si < array_length(_assistant_rows); _si++) {
            array_push(_items, {
                kind : "row",
                row : _assistant_rows[_si],
                fill : make_color_rgb(235, 246, 234),
                line : make_color_rgb(95, 140, 96)
            });
        }
    }

    if (array_length(_common_rows) > 0) {
        array_push(_items, {
            kind : "header",
            title : "ОБЩИЕ НАВЫКИ",
            fill : make_color_rgb(246, 242, 226),
            line : make_color_rgb(145, 126, 84)
        });

        for (var _ci = 0; _ci < array_length(_common_rows); _ci++) {
            array_push(_items, {
                kind : "row",
                row : _common_rows[_ci],
                fill : make_color_rgb(246, 242, 226),
                line : make_color_rgb(145, 126, 84)
            });
        }
    }

    var _item_count = array_length(_items);

    // Крупный фиксированный размер. Если места много — станет ещё крупнее.
    var _metrics = tablet_skill_metrics(_ui_scale, _item_count, 1, _max_height);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(74, 49, 31));
    draw_text_transformed(
        _x,
        _y,
        "НАВЫКИ:",
        _metrics.font_title * _ui_scale * 1.15,
        _metrics.font_title * _ui_scale * 1.15,
        0
    );

    var _bar_reserve = 16 * _ui_scale;
    var _list_w = _width - _bar_reserve;

    // Подписи двух правых столбцов.
    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(84, 68, 54));
    draw_text_transformed(
        _x + _list_w * 0.72,
        _y + 3 * _ui_scale,
        "СКОРОСТЬ",
        _metrics.font_small * _ui_scale,
        _metrics.font_small * _ui_scale,
        0
    );
    draw_text_transformed(
        _x + _list_w * 0.90,
        _y + 3 * _ui_scale,
        "КАЧЕСТВО",
        _metrics.font_small * _ui_scale,
        _metrics.font_small * _ui_scale,
        0
    );
    draw_set_halign(fa_left);

    var _list_y1 = _y + 24 * _ui_scale;
    var _list_y2 = (_max_height > 0)
        ? (_y + _max_height)
        : (_list_y1 + _item_count * _metrics.row_h * _ui_scale);
    var _row_h_px = _metrics.row_h * _ui_scale;
    var _header_h_px = _metrics.header_h * _ui_scale;

    // Сколько элементов видно (в среднем; заголовки чуть выше строк).
    var _visible_items = max(1, floor((_list_y2 - _list_y1) / _row_h_px));
    var _max_scroll = max(0, _item_count - _visible_items);

    // Позиция прокрутки живёт в планшете/панели, а без него — в глобальной.
    var _scroll = 0;

    if (instance_exists(_tablet)) {
        if (!variable_instance_exists(_tablet, "staff_skills_scroll")) {
            _tablet.staff_skills_scroll = 0;
            _tablet.staff_skills_scroll_target = _target;
            _tablet.staff_skills_drag = false;
            _tablet.staff_skills_drag_accum = 0;
        }

        // Сменили сотрудника — список снова сверху.
        if (
            !variable_instance_exists(_tablet, "staff_skills_scroll_target")
            || _tablet.staff_skills_scroll_target != _target
        ) {
            _tablet.staff_skills_scroll_target = _target;
            _tablet.staff_skills_scroll = 0;
        }

        _tablet.staff_skills_scroll = clamp(
            _tablet.staff_skills_scroll,
            0,
            _max_scroll
        );
        _scroll = _tablet.staff_skills_scroll;
    }
    else {
        if (!variable_global_exists("staff_skills_scroll_fallback")) {
            global.staff_skills_scroll_fallback = 0;
        }

        global.staff_skills_scroll_fallback = clamp(
            global.staff_skills_scroll_fallback,
            0,
            _max_scroll
        );
        _scroll = global.staff_skills_scroll_fallback;
    }

    var _mouse_gx = device_mouse_x_to_gui(0);
    var _mouse_gy = device_mouse_y_to_gui(0);
    var _inside_list = point_in_rectangle(
        _mouse_gx,
        _mouse_gy,
        _x,
        _list_y1,
        _x + _width,
        _list_y2
    );

    // Колесо мыши.
    if (_inside_list && _max_scroll > 0) {
        if (mouse_wheel_down()) _scroll = min(_max_scroll, _scroll + 1);
        if (mouse_wheel_up()) _scroll = max(0, _scroll - 1);
    }

    // Перетягивание пальцем и бегунок справа.
    var _bar_x1 = _x + _list_w + 4 * _ui_scale;
    var _bar_x2 = _x + _width;

    if (_max_scroll > 0) {
        var _track_h = _list_y2 - _list_y1;
        var _thumb_h = max(40 * _ui_scale, _track_h * (_visible_items / _item_count));
        var _thumb_y1 = _list_y1
            + (_track_h - _thumb_h) * (_scroll / max(1, _max_scroll));

        draw_set_color(make_color_rgb(232, 220, 198));
        draw_roundrect_ext(_bar_x1, _list_y1, _bar_x2, _list_y2, 5, 5, false);
        draw_set_color(make_color_rgb(180, 160, 140));
        draw_roundrect_ext(_bar_x1, _list_y1, _bar_x2, _list_y2, 5, 5, true);

        var _bar_hover = point_in_rectangle(
            _mouse_gx,
            _mouse_gy,
            _bar_x1,
            _list_y1,
            _bar_x2,
            _list_y2
        );

        draw_set_color(_bar_hover
            ? make_color_rgb(120, 86, 58)
            : make_color_rgb(150, 107, 73));
        draw_roundrect_ext(
            _bar_x1 + 1,
            _thumb_y1,
            _bar_x2 - 1,
            _thumb_y1 + _thumb_h,
            4,
            4,
            false
        );

        if (_bar_hover && hud_staff_manage_pointer_down()) {
            var _grab = clamp(
                (_mouse_gy - _list_y1 - _thumb_h * 0.5)
                    / max(1, _track_h - _thumb_h),
                0,
                1
            );

            _scroll = round(_grab * _max_scroll);
        }
    }

    if (instance_exists(_tablet)) {
        _tablet.staff_skills_scroll = clamp(_scroll, 0, _max_scroll);
    }
    else {
        global.staff_skills_scroll_fallback = clamp(_scroll, 0, _max_scroll);
    }

    // ── Сама отрисовка видимой части ──
    var _draw_y = _list_y1;

    for (var _item_index = _scroll; _item_index < _item_count; _item_index++) {
        var _item = _items[_item_index];
        var _item_h = (_item.kind == "header") ? _header_h_px : _row_h_px;

        if (_draw_y + _item_h > _list_y2) break;

        if (_item.kind == "header") {
            draw_set_color(_item.fill);
            draw_roundrect_ext(
                _x,
                _draw_y,
                _x + _list_w,
                _draw_y + _item_h,
                6,
                6,
                false
            );
            draw_set_color(_item.line);
            draw_roundrect_ext(
                _x,
                _draw_y,
                _x + _list_w,
                _draw_y + _item_h,
                6,
                6,
                true
            );

            draw_set_halign(fa_left);
            draw_set_valign(fa_middle);
            draw_set_color(_item.line);
            draw_text_transformed(
                _x + 8 * _ui_scale,
                _draw_y + _item_h * 0.5,
                _item.title,
                _metrics.font_title * _ui_scale,
                _metrics.font_title * _ui_scale,
                0
            );
            draw_set_valign(fa_top);

            _draw_y += _item_h;
            continue;
        }

        // Полоса строки.
        var _even = (_item_index mod 2 == 0);

        draw_set_alpha(_even ? 0.10 : 0.06);
        draw_set_color(_even ? _item.line : c_white);
        draw_roundrect_ext(
            _x + 2 * _ui_scale,
            _draw_y,
            _x + _list_w - 2 * _ui_scale,
            _draw_y + _item_h,
            4,
            4,
            false
        );
        draw_set_alpha(1);

        var _help_id = variable_struct_exists(_item.row, "help_id")
            ? string(_item.row.help_id)
            : "";
        var _row_hovered = point_in_rectangle(
            _mouse_gx,
            _mouse_gy,
            _x + 2 * _ui_scale,
            _draw_y,
            _x + _list_w - 2 * _ui_scale,
            _draw_y + _item_h
        );
        var _row_selected = (
            instance_exists(_tablet)
            && variable_instance_exists(_tablet, "staff_skill_help_id")
            && _tablet.staff_skill_help_id == _help_id
            && _help_id != ""
        );

        if (_row_selected || _row_hovered) {
            draw_set_alpha(_row_selected ? 0.30 : 0.16);
            draw_set_color(_item.line);
            draw_roundrect_ext(
                _x + 2 * _ui_scale,
                _draw_y,
                _x + _list_w - 2 * _ui_scale,
                _draw_y + _item_h,
                4,
                4,
                false
            );
            draw_set_alpha(1);
        }

        tablet_draw_compact_skill_row(
            _x + 8 * _ui_scale,
            _draw_y,
            _list_w - 16 * _ui_scale,
            _ui_scale,
            _item.row,
            _metrics
        );

        // Клик по строке открывает описание навыка внизу карточки.
        if (
            _row_hovered
            && _help_id != ""
            && instance_exists(_tablet)
            && hud_staff_manage_pointer_pressed()
        ) {
            if (
                variable_instance_exists(_tablet, "staff_skill_help_id")
                && _tablet.staff_skill_help_id == _help_id
            ) {
                _tablet.staff_skill_help_id = "";
            }
            else {
                _tablet.staff_skill_help_id = _help_id;
            }
        }

        _draw_y += _item_h;
    }

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
