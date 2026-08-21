/// tablet_draw_candidate_skills.gml
/// @description Точная копия таблицы навыков персонала с двумя открытыми навыками кандидата.


// ═══════════════════════════════════════════════════════════════
// 1. СКРЫТАЯ СТРОКА НАВЫКА
// Размеры, позиции и шрифты полностью совпадают с обычной строкой персонала.
// ═══════════════════════════════════════════════════════════════

function tablet_candidate_draw_hidden_skill_row(
    _x,
    _y,
    _width,
    _ui_scale
) {
    var _level_x = _x + 108 * _ui_scale;
    var _bar_x = _x + 124 * _ui_scale;
    var _bar_w = 92 * _ui_scale;
    var _bar_h = 9 * _ui_scale;
    var _row_h = 10.5 * _ui_scale;
    var _row_center_y = _y + _row_h * 0.5;
    var _bar_y1 = _row_center_y - _bar_h * 0.5;
    var _bar_y2 = _row_center_y + _bar_h * 0.5;

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);

    draw_set_color(make_color_rgb(50, 38, 28));
    draw_text_transformed(
        _x,
        _row_center_y,
        "???",
        0.52 * _ui_scale,
        0.58 * _ui_scale,
        0
    );

    draw_set_color(make_color_rgb(84, 68, 54));
    draw_text_transformed(
        _level_x,
        _row_center_y,
        "?",
        0.52 * _ui_scale,
        0.58 * _ui_scale,
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
        "???",
        0.44 * _ui_scale,
        0.50 * _ui_scale,
        0
    );

    draw_set_color(make_color_rgb(84, 68, 54));
    draw_text_transformed(
        _x + 242 * _ui_scale,
        _row_center_y,
        "?",
        0.52 * _ui_scale,
        0.58 * _ui_scale,
        0
    );

    draw_text_transformed(
        _x + 292 * _ui_scale,
        _row_center_y,
        "?",
        0.52 * _ui_scale,
        0.58 * _ui_scale,
        0
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ═══════════════════════════════════════════════════════════════
// 2. ГРУППА НАВЫКОВ
// Скопирована из карточки персонала; убраны только клики по подсказкам.
// ═══════════════════════════════════════════════════════════════

function tablet_candidate_draw_compact_skill_group(
    _x,
    _y,
    _width,
    _ui_scale,
    _title,
    _rows,
    _fill_color,
    _line_color,
    _best_uid_1,
    _best_uid_2
) {
    if (!is_array(_rows) || array_length(_rows) <= 0) return _y;

    var _header_h = 14 * _ui_scale;
    var _row_h = 10.5 * _ui_scale;
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
        0.58 * _ui_scale,
        0.64 * _ui_scale,
        0
    );

    for (var _row_index = 0; _row_index < array_length(_rows); _row_index++) {
        var _row_y = _y + _header_h + _row_index * _row_h;
        var _display_row_number = _row_index + 1;
        var _is_even_row = (_display_row_number mod 2 == 0);
        var _row = _rows[_row_index];
        var _is_revealed = (
            _row.uid == _best_uid_1
            || _row.uid == _best_uid_2
        );

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

        if (_is_revealed) {
            tablet_draw_compact_skill_row(
                _x + 7 * _ui_scale,
                _row_y,
                _width - 14 * _ui_scale,
                _ui_scale,
                _row
            );
        } else {
            tablet_candidate_draw_hidden_skill_row(
                _x + 7 * _ui_scale,
                _row_y,
                _width - 14 * _ui_scale,
                _ui_scale
            );
        }
    }

    return _y + _height;
}


// ═══════════════════════════════════════════════════════════════
// 3. ДАННЫЕ НАВЫКОВ КАНДИДАТА
// Набор строк совпадает с тем, который сотрудник увидит после найма.
// ═══════════════════════════════════════════════════════════════

function tablet_candidate_get_skill_data(_target) {
    var _doctor_rows = [];
    var _admin_rows = [];
    var _assistant_rows = [];
    var _common_rows = [];
    var _all_rows = [];

    var _role = variable_instance_exists(_target, "role")
        ? string(_target.role)
        : "";
    if (_role == "doctor") {
        doctor_ensure_inpatient_skill(_target, true);
    }

    var _skills = variable_instance_exists(_target, "skills")
        ? _target.skills
        : array_create(11, 1);


    // ───────────────────────────────────────────────────────────
    // 3.1 ВРАЧ
    // ───────────────────────────────────────────────────────────

    if (_role == "doctor") {
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

        for (var _doctor_index = 0; _doctor_index < min(array_length(_doctor_names), array_length(_skills)); _doctor_index++) {
            // Обычная карточка сотрудника сейчас выводит процедуры отдельно,
            // поэтому здесь сохраняется та же структура строк.
            if (_doctor_index == 1) continue;

            var _doctor_level = clamp(round(_skills[_doctor_index]), 1, 10);
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

            var _doctor_row = {
                uid : "doctor_" + string(_doctor_index),
                name : _doctor_names[_doctor_index],
                level : _doctor_level,
                xp : 0,
                need : _doctor_needed_xp,
                speed : string(_doctor_speed) + "С",
                quality : string(_doctor_quality) + "%",
                help_id : (_doctor_index < array_length(_doctor_help_ids))
                    ? _doctor_help_ids[_doctor_index]
                    : ""
            };

            array_push(_doctor_rows, _doctor_row);
            array_push(_all_rows, _doctor_row);
        }
    }


    // ───────────────────────────────────────────────────────────
    // 3.2 АДМИНИСТРАТОР
    // ───────────────────────────────────────────────────────────

    if (_role == "admin") {
        var _admin_names = ["РЕГИСТРАЦИЯ", "КАССА"];

        for (var _admin_index = 0; _admin_index < 2; _admin_index++) {
            var _admin_level = (_admin_index < array_length(_skills))
                ? clamp(round(_skills[_admin_index]), 1, 10)
                : 1;
            var _admin_seconds = round(
                lerp(10, 1, (_admin_level - 1) / 9) * 10
            ) / 10;

            var _admin_row = {
                uid : "admin_" + string(_admin_index),
                name : _admin_names[_admin_index],
                level : _admin_level,
                xp : 0,
                need : (_admin_level >= 10)
                    ? 1
                    : secondary_skill_xp_needed(_admin_level),
                speed : string(_admin_seconds) + "С",
                quality : "-",
                help_id : ""
            };

            array_push(_admin_rows, _admin_row);
            array_push(_all_rows, _admin_row);
        }
    }


    // ───────────────────────────────────────────────────────────
    // 3.3 АССИСТЕНТ
    // ───────────────────────────────────────────────────────────

    if (_role == "assistant") {
        var _assistant_indices = [1, 4, 7];
        var _assistant_names = ["ПРОЦЕДУРЫ", "ПОПОЛНЕНИЕ", "УБОРКА"];

        for (var _assistant_index = 0; _assistant_index < 3; _assistant_index++) {
            var _source_index = _assistant_indices[_assistant_index];
            var _assistant_level = (_source_index < array_length(_skills))
                ? clamp(round(_skills[_source_index]), 1, 10)
                : 1;
            var _assistant_seconds = 0;

            if (_assistant_index == 0) {
                _assistant_seconds = round(
                    lerp(5, 2, (_assistant_level - 1) / 9) * 10
                ) / 10;
            }
            else if (_assistant_index == 1) {
                _assistant_seconds = round(
                    lerp(2.0, 0.7, (_assistant_level - 1) / 9) * 10
                ) / 10;
            }
            else {
                _assistant_seconds = round(
                    cleaning_get_duration_frames(_assistant_level)
                    / room_speed
                    * 10
                ) / 10;
            }

            var _assistant_row = {
                uid : "assistant_" + string(_assistant_index),
                name : _assistant_names[_assistant_index],
                level : _assistant_level,
                xp : 0,
                need : (_assistant_level >= 10)
                    ? 1
                    : secondary_skill_xp_needed(_assistant_level),
                speed : string(_assistant_seconds) + "С",
                quality : "-",
                help_id : ""
            };

            array_push(_assistant_rows, _assistant_row);
            array_push(_all_rows, _assistant_row);
        }
    }


    // ───────────────────────────────────────────────────────────
    // 3.4 ОБЩИЕ НАВЫКИ
    // ───────────────────────────────────────────────────────────

    var _walk_level = variable_instance_exists(_target, "walk_skill_level")
        ? clamp(round(_target.walk_skill_level), 1, 10)
        : 1;
    var _stamina_level = variable_instance_exists(_target, "stamina_level")
        ? clamp(round(_target.stamina_level), 1, 10)
        : 1;

    var _walk_row = {
        uid : "common_walk",
        name : "СКОРОСТЬ ХОДЬБЫ",
        level : _walk_level,
        xp : 0,
        need : (_walk_level >= 10) ? 1 : doctor_xp_needed(_walk_level),
        speed : string(100 + (_walk_level - 1) * 10) + "%",
        quality : "-",
        help_id : ""
    };

    var _stamina_row = {
        uid : "common_stamina",
        name : "ВЫНОСЛИВОСТЬ",
        level : _stamina_level,
        xp : 0,
        need : (_stamina_level >= 10) ? 1 : doctor_xp_needed(_stamina_level),
        speed : "-",
        quality : "-",
        help_id : ""
    };

    array_push(_common_rows, _walk_row);
    array_push(_common_rows, _stamina_row);
    array_push(_all_rows, _walk_row);
    array_push(_all_rows, _stamina_row);


    // ───────────────────────────────────────────────────────────
    // 3.5 ДВА САМЫХ ВЫСОКИХ УРОВНЯ
    // ───────────────────────────────────────────────────────────

    var _best_index_1 = -1;
    var _best_index_2 = -1;

    for (var _skill_index = 0; _skill_index < array_length(_all_rows); _skill_index++) {
        if (
            _best_index_1 == -1
            || _all_rows[_skill_index].level > _all_rows[_best_index_1].level
        ) {
            _best_index_2 = _best_index_1;
            _best_index_1 = _skill_index;
        }
        else if (
            _best_index_2 == -1
            || _all_rows[_skill_index].level > _all_rows[_best_index_2].level
        ) {
            _best_index_2 = _skill_index;
        }
    }

    return {
        doctor_rows : _doctor_rows,
        admin_rows : _admin_rows,
        assistant_rows : _assistant_rows,
        common_rows : _common_rows,
        best_uid_1 : (_best_index_1 >= 0) ? _all_rows[_best_index_1].uid : "",
        best_uid_2 : (_best_index_2 >= 0) ? _all_rows[_best_index_2].uid : ""
    };
}


// ═══════════════════════════════════════════════════════════════
// 4. ОСНОВНАЯ ПАНЕЛЬ НАВЫКОВ
// Полностью повторяет размеры и шрифты tablet_draw_staff_skills.
// ═══════════════════════════════════════════════════════════════

function tablet_draw_candidate_skills(
    _target,
    _x,
    _y,
    _width,
    _ui_scale
) {
    if (!instance_exists(_target)) return;

    var _data = tablet_candidate_get_skill_data(_target);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(74, 49, 31));
    draw_text_transformed(
        _x,
        _y,
        "НАВЫКИ:",
        0.72 * _ui_scale,
        0.78 * _ui_scale,
        0
    );

    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(84, 68, 54));
    draw_text_transformed(
        _x + 249 * _ui_scale,
        _y + 3 * _ui_scale,
        "СКОРОСТЬ",
        0.52 * _ui_scale,
        0.58 * _ui_scale,
        0
    );

    draw_text_transformed(
        _x + 299 * _ui_scale,
        _y + 3 * _ui_scale,
        "КАЧЕСТВО",
        0.52 * _ui_scale,
        0.58 * _ui_scale,
        0
    );

    draw_set_halign(fa_left);

    var _group_y = _y + 20 * _ui_scale;
    var _group_gap = 4 * _ui_scale;

    if (array_length(_data.doctor_rows) > 0) {
        _group_y = tablet_candidate_draw_compact_skill_group(
            _x,
            _group_y,
            _width,
            _ui_scale,
            "ВРАЧ",
            _data.doctor_rows,
            make_color_rgb(232, 240, 248),
            make_color_rgb(104, 135, 160),
            _data.best_uid_1,
            _data.best_uid_2
        ) + _group_gap;
    }

    if (array_length(_data.admin_rows) > 0) {
        _group_y = tablet_candidate_draw_compact_skill_group(
            _x,
            _group_y,
            _width,
            _ui_scale,
            "АДМИНИСТРАТОР",
            _data.admin_rows,
            make_color_rgb(248, 235, 240),
            make_color_rgb(158, 108, 128),
            _data.best_uid_1,
            _data.best_uid_2
        ) + _group_gap;
    }

    if (array_length(_data.assistant_rows) > 0) {
        _group_y = tablet_candidate_draw_compact_skill_group(
            _x,
            _group_y,
            _width,
            _ui_scale,
            "АССИСТЕНТ",
            _data.assistant_rows,
            make_color_rgb(235, 246, 234),
            make_color_rgb(95, 140, 96),
            _data.best_uid_1,
            _data.best_uid_2
        ) + _group_gap;
    }

    tablet_candidate_draw_compact_skill_group(
        _x,
        _group_y,
        _width,
        _ui_scale,
        "ОБЩИЕ НАВЫКИ",
        _data.common_rows,
        make_color_rgb(246, 242, 226),
        make_color_rgb(145, 126, 84),
        _data.best_uid_1,
        _data.best_uid_2
    );

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
