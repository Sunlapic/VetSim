// ─────────────────────────────────────────────
// Табличка в стиле «КАНДИДАТ» с прогресс-полоской под текстом (совместима со всеми версиями GM)
// ─────────────────────────────────────────────
function actor_draw_action_progress() {
    var _is_candidate = (object_index == obj_staff_candidate);

    var _label    = "";
    var _ratio    = 0;
    var _has_bar  = false;
    var _bar_color= make_color_rgb(90, 130, 74);

    if (_is_candidate) {
        _label = "КАНДИДАТ";

        // Пакет №66: пока кандидат стоит на точке ожидания,
        // под словом «КАНДИДАТ» рисуется шкала оставшегося времени.
        if (
            variable_instance_exists(id, "candidate_state")
            && candidate_state == "waiting_offer"
        ) {
            _ratio = candidate_wait_ratio(id);
            _has_bar = true;

            // Цвет от зелёного (полный час) к красному (скоро уйдёт).
            _bar_color = merge_color(
                make_color_rgb(196, 74, 62),
                make_color_rgb(88, 154, 82),
                _ratio
            );
        }
        else {
            _ratio = 0;
            _has_bar = false;
        }
    } else {
        var _state = "";
        if (variable_instance_exists(id, "doctor_state"))    _state = doctor_state;
        if (variable_instance_exists(id, "assistant_state")) _state = assistant_state;
        if (variable_instance_exists(id, "reception_state")) _state = reception_state;

        if (variable_instance_exists(id, "action_progress_active") && action_progress_active) {
            _label = variable_instance_exists(id, "action_progress_label") ? action_progress_label : "...";
            _has_bar = true;
            if (variable_instance_exists(id, "action_progress_color")) {
                _bar_color = action_progress_color;
            }
            var _cur = variable_instance_exists(id, "action_progress_timer") ? action_progress_timer : 0;
            var _max = variable_instance_exists(id, "action_progress_timer_max") ? max(1, action_progress_timer_max) : 1;
            _ratio = clamp((_max - _cur) / max(0.01, _max), 0, 1);
        } else {
            switch (_state) {
                case "going_to_owner":
				
                case "going_to_doctor_point":
				 _label    = "";
                    _has_bar  = false;
                    break;
                case "going_to_assistant_point":
				 _label    = "";
                    _has_bar  = false;
                    break;
                case "going_to_patient":
				 _label    = "";
                    _has_bar  = false;
                    break;
                case "waiting_positions":
                    _label    = "ЖДЁТ ПАЦИЕНТА";
                    _has_bar  = false;
                    break;
                case "restock_going_to_storage":
				 _label    = "ПОПОЛНЕНИЕ";
                    _has_bar  = false;
                    break;
                case "restock_going_to_cabinet":
                    _label    = "ПОПОЛНЕНИЕ";
                    _has_bar  = false;
                    break;
                case "inpatient_waiting_stock":
                    // Пакет №80: ассистент ждёт препарат для стационара.
                    _label = "НЕТ ПРЕПАРАТА";

                    if (
                        variable_instance_exists(id, "inpatient_missing_item_name")
                        && string(inpatient_missing_item_name) != ""
                    ) {
                        _label = "НЕТ: " + string(inpatient_missing_item_name);
                    }

                    _has_bar = false;
                    break;
                case "going_to_register_spot":
                case "returning":
    
                case "idle":
                default:
                    _label    = "";
                    _has_bar  = false;
                    break;
            }
        }
    }

    if (_label == "") exit;

    // ── Палитра как у «КАНДИДАТ» ──
    var _wood_dark   = make_color_rgb(74, 49, 31);
    var _wood_light  = make_color_rgb(150, 107, 73);
    var _paper       = make_color_rgb(242, 232, 214);
    var _line_dark   = make_color_rgb(58, 39, 24);
    var _text_dark   = make_color_rgb(50, 38, 28);
    var _bar_bg      = make_color_rgb(200, 184, 160);

    var _pad_x = 12;
    var _pad_y = 6;
    var _bar_h = 6;
    var _bar_gap = 5; // отступ между текстом и полоской

    if (font_exists(fnt_main)) draw_set_font(fnt_main);

    var _text_w = string_width(_label);
    var _text_h = string_height(_label);
    var _tw = max(_text_w + _pad_x * 2 + 8, 100); // минимальная ширина, чтобы полоска была видна
    var _th = _text_h + _pad_y * 2 + 4;
    if (_has_bar) _th += _bar_gap + _bar_h;

    var _bx1 = x - (_tw * 0.5);
    var _by1 = y - 180;
    var _bx2 = _bx1 + _tw;
    var _by2 = _by1 + _th;

    var _in_x1 = _bx1 + 5;
    var _in_y1 = _by1 + 5;
    var _in_x2 = _bx2 - 5;
    var _in_y2 = _by2 - 5;

    // Тень
    draw_set_alpha(0.18);
    draw_set_color(c_black);
    draw_roundrect_ext(_bx1 + 2, _by1 + 3, _bx2 + 2, _by2 + 3, 8, 8, false);
    draw_set_alpha(1);

    // Двойная коричневая рамка
    draw_set_color(_wood_dark);
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, false);
    draw_set_color(_wood_light);
    draw_roundrect_ext(_bx1 + 2, _by1 + 2, _bx2 - 2, _by2 - 2, 6, 6, false);

    // Бумага
    draw_set_color(_paper);
    draw_roundrect_ext(_in_x1, _in_y1, _in_x2, _in_y2, 5, 5, false);

    // Контур
    draw_set_color(_line_dark);
    draw_roundrect_ext(_bx1, _by1, _bx2, _by2, 8, 8, true);

    // Текст (всегда тёмный, читаемый)
    draw_set_color(_text_dark);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text((_bx1 + _bx2) * 0.5, _by1 + _pad_y + 1, _label);

    // Прогресс-полоска под текстом (если есть активное действие)
    if (_has_bar) {
        var _bar_x1 = _in_x1 + 6;
        var _bar_x2 = _in_x2 - 6;
        var _bar_y1 = _by1 + _pad_y + _text_h + _bar_gap;
        var _bar_y2 = _bar_y1 + _bar_h;

        // Фон полоски
        draw_set_color(_bar_bg);
        draw_roundrect_ext(_bar_x1, _bar_y1, _bar_x2, _bar_y2, 2, 2, false);
        // Заполнение
        var _fill_x2 = _bar_x1 + (_bar_x2 - _bar_x1) * _ratio;
        if (_ratio > 0.02) {
            draw_set_color(_bar_color);
            draw_roundrect_ext(_bar_x1, _bar_y1, _fill_x2, _bar_y2, 2, 2, false);
        }
        // Рамка полоски
        draw_set_color(_line_dark);
        draw_roundrect_ext(_bar_x1, _bar_y1, _bar_x2, _bar_y2, 2, 2, true);
    }

    // Сброс
    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
