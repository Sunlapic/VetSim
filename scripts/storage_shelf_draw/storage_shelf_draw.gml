/// storage_shelf_draw.gml
/// @description Главный склад — объёмный стеллаж: 4 ряда × 12 шкафчиков.
/// Каждый шкафчик — углубление-кубик (вид сверху-справа): видна часть левой
/// стенки, часть задней стенки и пол. Кубики — светлые 3D-коробочки (верхняя,
/// правая и передняя грани), с тенью; заполняются слоями: сначала задний,
/// потом ближе к переднему. Подпись — на отдельной табличке (2 строки).
/// Пакет №99: болтики (кружки) в углах табличек.
/// Пакет №117: сетка на блоках ровная (обе грани каждой коробочки).
/// Пакет №143: возвращён полный склад (5 слоёв, тени) + кэш переноса названий.


// ═══════════════════════════════════════════════════════════════
// 1. РАЗМЕРЫ (все настраиваемые)
// ═══════════════════════════════════════════════════════════════

function storage_shelf_cell_w() { return 75; }   // ширина шкафчика
function storage_shelf_cell_h() { return 60; }   // высота шкафчика (−40%)
function storage_shelf_cols() { return 12; }     // шкафчиков в ряду
function storage_shelf_rows() { return 4; }      // рядов
function storage_shelf_gap_x() { return 8; }
function storage_shelf_gap_y() { return 10; }
function storage_shelf_pad() { return 22; }      // рамка корпуса
function storage_shelf_box() { return 4; }       // сторона коробочки
function storage_shelf_box_gap() { return 2; }   // отступ коробочек
function storage_shelf_box_cols() { return 10; } // коробочек в ряду
function storage_shelf_box_rows() { return 5; }  // рядов
function storage_shelf_box_layers() { return 5; }      // слоёв вглубь
function storage_shelf_box_layer_depth() { return 3; } // сдвиг слоя (px)
function storage_shelf_box_max() {
    return storage_shelf_box_cols()
        * storage_shelf_box_rows()
        * storage_shelf_box_layers();
}
function storage_shelf_label_scale() { return 0.52; } // масштаб подписи (подобран пользователем)
function storage_shelf_depth() { return 30; }     // глубина КОРПУСА (×3)
function storage_shelf_cell_depth() { return 18; } // глубина УГЛУБЛЕНИЯ
function storage_shelf_box_depth() { return 4; }   // глубина самой коробочки


// ═══════════════════════════════════════════════════════════════
// 2. ГЕОМЕТРИЯ
// ═══════════════════════════════════════════════════════════════

function storage_shelf_unit_width() {
    return storage_shelf_pad() * 2
        + storage_shelf_cols() * storage_shelf_cell_w()
        + (storage_shelf_cols() - 1) * storage_shelf_gap_x();
}

function storage_shelf_unit_height() {
    return storage_shelf_pad() * 2
        + storage_shelf_rows() * storage_shelf_cell_h()
        + (storage_shelf_rows() - 1) * storage_shelf_gap_y();
}

function storage_shelf_unit_rect(_st) {
    var _w = storage_shelf_unit_width();
    var _h = storage_shelf_unit_height();
    var _d = storage_shelf_depth();

    return {
        x1 : _st.x - _w * 0.5,
        y1 : (_st.y - _h) - _d,
        x2 : _st.x + _w * 0.5 + _d,
        y2 : _st.y
    };
}

function storage_main_hit_at_point(_mx, _my) {
    var _st = storage_find_main();

    if (!instance_exists(_st)) return noone;

    var _r = storage_shelf_unit_rect(_st);

    if (point_in_rectangle(_mx, _my, _r.x1, _r.y1, _r.x2, _r.y2)) {
        return _st;
    }

    return noone;
}


// ═══════════════════════════════════════════════════════════════
// 3. ОТРИСОВКА
// ═══════════════════════════════════════════════════════════════

function _shelf_draw_quad(_x1, _y1, _x2, _y2, _x3, _y3, _x4, _y4, _col) {
    draw_set_color(_col);
    draw_triangle(_x1, _y1, _x2, _y2, _x3, _y3, false);
    draw_triangle(_x1, _y1, _x3, _y3, _x4, _y4, false);
}

// Светлый 3D-кубик (вид сверху-справа, глубина вверх-вправо).
function _shelf_draw_box(
    _bx,
    _by,
    _size,
    _bd,
    _bg,
    _top,
    _right,
    _line
) {
    // Тень под кубиком.
    draw_set_color(c_black);
    draw_set_alpha(0.16);
    draw_roundrect_ext(
        _bx + 1, _by + 2,
        _bx + _size + 1, _by + _size + 2,
        1, 1, false
    );
    draw_set_alpha(1);

    // Верхняя грань (вверх-вправо), светлая.
    _shelf_draw_quad(
        _bx, _by,
        _bx + _size, _by,
        _bx + _size + _bd, _by - _bd,
        _bx + _bd, _by - _bd,
        _top
    );

    // Правая грань (вверх-вправо), светлая чуть темнее верха.
    _shelf_draw_quad(
        _bx + _size, _by,
        _bx + _size + _bd, _by - _bd,
        _bx + _size + _bd, _by + _size - _bd,
        _bx + _size, _by + _size,
        _right
    );

    // Передняя грань.
    draw_set_color(_bg);
    draw_roundrect_ext(
        _bx, _by,
        _bx + _size, _by + _size,
        1, 1, false
    );
    draw_set_color(_line);
    draw_roundrect_ext(
        _bx, _by,
        _bx + _size, _by + _size,
        1, 1, true
    );
}

// Пакет №115: полная полка рисуется ОДНИМ цельным блоком (сетка линий вместо
// 250 отдельных кубиков). Это убирает лаг при полностью забитом складе.
function _shelf_draw_full_box(
    _bx, _by, _w, _h, _d,
    _bg, _top, _right, _line
) {
    // Тень.
    draw_set_color(c_black);
    draw_set_alpha(0.16);
    draw_roundrect_ext(
        _bx + 1, _by + 2,
        _bx + _w + 1, _by + _h + 2,
        1, 1, false
    );
    draw_set_alpha(1);

    // Верхняя грань (вверх-вправо), светлая.
    _shelf_draw_quad(
        _bx, _by,
        _bx + _w, _by,
        _bx + _w + _d, _by - _d,
        _bx + _d, _by - _d,
        _top
    );

    // Правая грань.
    _shelf_draw_quad(
        _bx + _w, _by,
        _bx + _w + _d, _by - _d,
        _bx + _w + _d, _by + _h - _d,
        _bx + _w, _by + _h,
        _right
    );

    // Передняя грань.
    draw_set_color(_bg);
    draw_roundrect_ext(_bx, _by, _bx + _w, _by + _h, 1, 1, false);

    // Сетка линий — рисуем ОБЕ грани каждой коробочки (левую+правую,
    // верх+низ), чтобы ячейки были ровные: 4px коробка + 2px зазор,
    // как у настоящих кубиков (иначе последний ряд/колонка были уже).
    var _fcols = storage_shelf_box_cols();
    var _frows = storage_shelf_box_rows();
    var _fb = storage_shelf_box();
    var _fg = storage_shelf_box_gap();

    draw_set_color(_line);

    for (var _fc = 0; _fc < _fcols; _fc++) {
        var _fx = _bx + _fc * (_fb + _fg);
        draw_line(_fx, _by, _fx, _by + _h);             // левый край коробочки
        draw_line(_fx + _fb, _by, _fx + _fb, _by + _h); // правый край коробочки
    }

    for (var _fr = 0; _fr < _frows; _fr++) {
        var _fy = _by + _fr * (_fb + _fg);
        draw_line(_bx, _fy, _bx + _w, _fy);             // верхний край
        draw_line(_bx, _fy + _fb, _bx + _w, _fy + _fb); // нижний край
    }
}

// Палитра светлых «лекарственных» цветов — по одному на препарат (16 цветов).
// _seed — номер шкафчика (индекс препарата), поэтому у разных препаратов
// разные цвета, а соседние ячейки никогда не совпадают.
function _shelf_box_palette(_seed) {
    static _pal = [
        [206,224,193], [224,206,193], [193,216,224], [224,213,193],
        [212,193,224], [224,193,193], [193,224,213], [216,224,193],
        [224,199,206], [199,210,224], [224,224,193], [206,193,224],
        [224,203,193], [193,224,224], [224,193,214], [199,224,199]
    ];

    var _c = _pal[_seed mod array_length(_pal)];
    var _r = _c[0];
    var _g = _c[1];
    var _b = _c[2];

    return {
        bg    : make_color_rgb(_r, _g, _b),
        top   : make_color_rgb(min(255, _r + 24), min(255, _g + 24), min(255, _b + 24)),
        right : make_color_rgb(max(0, _r - 28), max(0, _g - 28), max(0, _b - 28)),
        line  : make_color_rgb(max(0, _r - 78), max(0, _g - 78), max(0, _b - 78))
    };
}

// Сдвиг яркости цвета на _d (от −255 до +255), с ограничением 0..255.
function _shelf_color_shift(_col, _d) {
    return make_color_rgb(
        clamp(color_get_red(_col)   + _d, 0, 255),
        clamp(color_get_green(_col) + _d, 0, 255),
        clamp(color_get_blue(_col)  + _d, 0, 255)
    );
}

// Перенос названия по ширине таблички (_max_px — в «натуральных» px шрифта).
// Возвращает массив строк. Важно: draw_text_ext НЕ переносит длинные слова без
// пробелов (например, «Кровоостанавливающее») — текст вылезает за табличку.
// Поэтому такие слова режем по буквам, а строки рисуем по одной (без «#»/«\n»).
function _shelf_wrap_lines(_str, _max_px) {
    var _lines = [];
    if (_str == "") return _lines;

    // 1. Разбиваем на слова.
    var _words = [];
    var _n = string_length(_str);
    var _w = "";
    for (var _i = 1; _i <= _n; _i++) {
        var _ch = string_char_at(_str, _i);
        if (_ch == " ") {
            if (_w != "") { array_push(_words, _w); _w = ""; }
        } else {
            _w += _ch;
        }
    }
    if (_w != "") array_push(_words, _w);

    // 2. Собираем строки.
    var _cur = "";
    var _wc = array_length(_words);

    for (var _j = 0; _j < _wc; _j++) {
        var _word = _words[_j];

        // Слово шире строки — режем по буквам.
        while (string_width(_word) > _max_px && string_length(_word) > 1) {
            var _part = "";
            var _wl = string_length(_word);
            var _k = 1;
            for (; _k <= _wl; _k++) {
                var _test = _part + string_char_at(_word, _k);
                if (string_width(_test) > _max_px) break;
                _part = _test;
            }
            if (_part == "") break;

            if (_cur != "") { array_push(_lines, _cur); _cur = ""; }
            array_push(_lines, _part);
            _word = string_copy(_word, _k, _wl - _k + 1);
        }

        // Оставшийся кусок слова кладём на текущую строку (или на новую).
        if (_word != "") {
            var _sep = (_cur == "") ? "" : " ";
            if (string_width(_cur + _sep + _word) <= _max_px) {
                _cur = _cur + _sep + _word;
            } else {
                if (_cur != "") array_push(_lines, _cur);
                _cur = _word;
            }
        }
    }
    if (_cur != "") array_push(_lines, _cur);

    return _lines;
}

// Пакет №143: кэш переноса названий. Названия препаратов не меняются во время
// игры, поэтому перенос считается один раз на препарат (дешевле при
// перерисовке поверхности после изменения запаса).
function _shelf_wrap_cached(_item_id, _name, _max_px) {
    if (!variable_global_exists("__shelf_wrap_cache")) {
        global.__shelf_wrap_cache = {};
    }

    var _key = string(_item_id);

    if (variable_struct_exists(global.__shelf_wrap_cache, _key)) {
        return variable_struct_get(global.__shelf_wrap_cache, _key);
    }

    var _lines = _shelf_wrap_lines(_name, _max_px);
    variable_struct_set(global.__shelf_wrap_cache, _key, _lines);
    return _lines;
}

// Маленький болтик в углу таблички: кружок «металл» + блик сверху-слева.
function _shelf_draw_bolt(_x, _y) {
    draw_set_color(make_color_rgb(92, 87, 78));            // тёмный металл
    draw_circle(_x, _y, 2, false);
    draw_set_color(make_color_rgb(168, 162, 148));         // блик
    draw_circle(_x - 0.7, _y - 0.7, 0.8, false);
}

function storage_draw_main_shelf_unit(_st) {
    if (!instance_exists(_st)) return;

    var _wood_dark  = make_color_rgb(74, 49, 31);
    var _wood_mid   = make_color_rgb(114, 77, 50);
    var _wood_top   = make_color_rgb(132, 92, 58);
    var _wood_side  = make_color_rgb(96, 64, 42);
    var _paper      = make_color_rgb(242, 232, 214);
    var _line_dark  = make_color_rgb(58, 39, 24);
    var _text_dark  = make_color_rgb(50, 38, 28);
    var _text_gray  = make_color_rgb(150, 140, 126);

    // Внутренние грани углубления (от светлого к тёмному).
    var _floor_col    = make_color_rgb(208, 198, 176);
    var _leftwall_col = make_color_rgb(176, 156, 130);
    var _backwall_col = make_color_rgb(148, 130, 106);

    // Цвета кубиков теперь выбираются по препарату: _shelf_box_palette(_index),
    // а лёгкий сдвиг яркости на каждый кубик даёт живую, не плоскую кучу.

    if (font_exists(fnt_main)) draw_set_font(fnt_main);

    var _w = storage_shelf_unit_width();
    var _h = storage_shelf_unit_height();
    var _d = storage_shelf_depth();

    var _fx1 = _st.x - _w * 0.5;
    var _fy1 = _st.y - _h;
    var _fx2 = _st.x + _w * 0.5;
    var _fy2 = _st.y;

    // ── Корпус: верхняя сторона и правая стенка ──
    _shelf_draw_quad(
        _fx1, _fy1,
        _fx2, _fy1,
        _fx2 + _d, _fy1 - _d,
        _fx1 + _d, _fy1 - _d,
        _wood_top
    );

    _shelf_draw_quad(
        _fx2, _fy1,
        _fx2 + _d, _fy1 - _d,
        _fx2 + _d, _fy2 - _d,
        _fx2, _fy2,
        _wood_side
    );

    // Лицевая грань.
    draw_set_color(_wood_dark);
    draw_roundrect_ext(_fx1, _fy1, _fx2, _fy2, 12, 12, false);
    draw_set_color(_wood_mid);
    draw_roundrect_ext(
        _fx1 + 5, _fy1 + 5,
        _fx2 - 5, _fy2 - 5,
        9, 9, false
    );

    draw_set_alpha(0.45);
    draw_set_color(c_white);
    draw_line(_fx1 + 10, _fy1 + 2, _fx2 - 10, _fy1 + 2);
    draw_set_alpha(1);

    var _cw = storage_shelf_cell_w();
    var _ch = storage_shelf_cell_h();
    var _gx = storage_shelf_gap_x();
    var _gy = storage_shelf_gap_y();
    var _pad = storage_shelf_pad();
    var _box = storage_shelf_box();
    var _bgap = storage_shelf_box_gap();
    var _cd = storage_shelf_cell_depth();
    var _bd = storage_shelf_box_depth();
    var _lbl_scale = storage_shelf_label_scale();

    var _box_cols = storage_shelf_box_cols();
    var _box_rows = storage_shelf_box_rows();
    var _box_layers = storage_shelf_box_layers();
    var _box_layer_d = storage_shelf_box_layer_depth();
    var _per_layer = _box_cols * _box_rows;
    var _grid_w = _box_cols * _box + (_box_cols - 1) * _bgap;
    var _grid_h = _box_rows * _box + (_box_rows - 1) * _bgap;

    var _ids = [];

    if (
        variable_global_exists("item_ids")
        && is_array(global.item_ids)
    ) {
        _ids = global.item_ids;
    }

    // Ряды рисуем снизу вверх, чтобы верхние перекрывали нижние.
    for (var _row = storage_shelf_rows() - 1; _row >= 0; _row--) {
        for (var _col = 0; _col < storage_shelf_cols(); _col++) {
            var _index = _row * storage_shelf_cols() + _col;

            var _cx = _fx1 + _pad + _col * (_cw + _gx);
            var _cy = _fy1 + _pad + _row * (_ch + _gy);

            // Углубление занимает верхнюю часть шкафчика.
            var _hx1 = _cx + 3;
            var _hy1 = _cy + 4;
            var _hx2 = _cx + _cw - 3;
            var _hy2 = _cy + 38;

            // ── Задняя стенка углубления (частично видна) ──
            _shelf_draw_quad(
                _hx1 + _cd, _hy1 - _cd,
                _hx2 + _cd, _hy1 - _cd,
                _hx2 + _cd, _hy2 - _cd,
                _hx1 + _cd, _hy2 - _cd,
                _backwall_col
            );

            // ── Пол углубления ──
            _shelf_draw_quad(
                _hx1, _hy2,
                _hx2, _hy2,
                _hx2 + _cd, _hy2 - _cd,
                _hx1 + _cd, _hy2 - _cd,
                _floor_col
            );

            // ── Левая внутренняя стенка ──
            _shelf_draw_quad(
                _hx1, _hy1,
                _hx1, _hy2,
                _hx1 + _cd, _hy2 - _cd,
                _hx1 + _cd, _hy1 - _cd,
                _leftwall_col
            );

            // ── Данные препарата ──
            var _item_id = "";
            var _name = "";
            var _amount = 0;

            if (_index < array_length(_ids)) {
                _item_id = _ids[_index];
                _name = item_get_name(_item_id);
                _amount = inventory_get_amount(
                    global.inventory_main,
                    _item_id
                );
            }

            // ── Кубики: слоями вглубь, заполняем сзади вперёд ──
            var _bxx = _hx1 + ((_hx2 - _hx1) - _grid_w) * 0.5;
            var _byy = _hy2 - 5 - _grid_h;
            var _pal = _shelf_box_palette(_index);

            // Пакет №116: каждый ПОЛНЫЙ слой рисуется одним цельным блоком,
            // отдельными кубиками — только частично заполненный слой (передний).
            // Полка 245 = 4 блока + 45 кубиков (вместо 245 кубиков) — не лагает.
            for (var _L = _box_layers - 1; _L >= 0; _L--) {
                var _back_index = (_box_layers - 1) - _L;

                var _layer_amt = clamp(
                    _amount - _back_index * _per_layer,
                    0,
                    _per_layer
                );

                if (_layer_amt <= 0) continue;

                var _off_x = _L * _box_layer_d;
                var _off_y = -_L * _box_layer_d;

                if (_layer_amt >= _per_layer) {
                    // Полный слой — цельный блок с сеткой линий.
                    _shelf_draw_full_box(
                        _bxx + _off_x, _byy + _off_y,
                        _grid_w, _grid_h, _bd,
                        _pal.bg, _pal.top, _pal.right, _pal.line
                    );
                } else {
                    // Частичный слой — отдельные кубики (заполняются снизу вверх).
                    for (var _b = 0; _b < _layer_amt; _b++) {
                        var _br = (_box_rows - 1) - (_b div _box_cols);
                        var _bc = _b mod _box_cols;

                        var _bx = _bxx + _bc * (_box + _bgap) + _off_x;
                        var _by = _byy + _br * (_box + _bgap) + _off_y;

                        // Лёгкий разброс яркости, чтобы кубики не сливались.
                        var _j = ((_b * 7 + _back_index * 13 + _index * 3) mod 9) - 4;

                        _shelf_draw_box(
                            _bx, _by, _box, _bd,
                            _shelf_color_shift(_pal.bg,    _j),
                            _shelf_color_shift(_pal.top,   _j),
                            _shelf_color_shift(_pal.right, _j),
                            _shelf_color_shift(_pal.line,  _j)
                        );
                    }
                }
            }

            // ── Табличка с подписью (2 строки, непрозрачная) ──
            if (_name != "") {
                var _lbl_y1 = _cy + 38;
                var _lbl_h  = 32;                 // высота таблички: 26 → 32, чтобы 3 строки (шрифт 0.52) влезали
                var _lbl_y2 = _lbl_y1 + _lbl_h;   // верх на месте, низ опущен (в пустой зазор между рядами)
                var _lbl_x1 = _cx - 2;            // табличка 80px: чуть выходит за ячейку в зазор
                var _lbl_x2 = _cx + _cw + 3;

                draw_set_alpha(0.20);
                draw_set_color(c_black);
                draw_roundrect_ext(
                    _lbl_x1 + 1, _lbl_y1 + 2,
                    _lbl_x2 + 1, _lbl_y2 + 2,
                    3, 3, false
                );
                draw_set_alpha(1);

                draw_set_color(_wood_dark);
                draw_roundrect_ext(
                    _lbl_x1, _lbl_y1,
                    _lbl_x2, _lbl_y2,
                    3, 3, false
                );
                draw_set_color(_paper);
                draw_roundrect_ext(
                    _lbl_x1 + 2, _lbl_y1 + 2,
                    _lbl_x2 - 2, _lbl_y2 - 2,
                    2, 2, false
                );

                // Болтики в четырёх углах.
                _shelf_draw_bolt(_lbl_x1 + 3, _lbl_y1 + 3);
                _shelf_draw_bolt(_lbl_x2 - 3, _lbl_y1 + 3);
                _shelf_draw_bolt(_lbl_x1 + 3, _lbl_y2 - 3);
                _shelf_draw_bolt(_lbl_x2 - 3, _lbl_y2 - 3);

                var _lbl_w = (_lbl_x2 - 2) - (_lbl_x1 + 2);
                var _wrap = _lbl_w / _lbl_scale;
                var _max_px = _wrap * 0.85;   // 85% ширины: запас от краёв, длинные слова переносятся

                var _lines = _shelf_wrap_cached(_item_id, _name, _max_px);
                var _lc = array_length(_lines);
                var _spacing = 11 * _lbl_scale;                   // межстрочный (как sep=11 раньше — нормально)
                var _glyph_h = string_height("Ду") * _lbl_scale; // полная высота строки (для точного центрирования)
                var _block_h = (_lc - 1) * _spacing + _glyph_h;  // общая высота блока текста
                var _ty = (_lbl_y1 + _lbl_y2) * 0.5 - _block_h * 0.5;  // верх блока: по центру по высоте

                draw_set_halign(fa_center);
                draw_set_valign(fa_top);
                draw_set_color(_amount <= 0 ? _text_gray : _text_dark);

                for (var _li = 0; _li < _lc; _li++) {
                    draw_text_transformed(
                        (_lbl_x1 + _lbl_x2) * 0.5,
                        _ty + _li * _spacing,
                        _lines[_li],
                        _lbl_scale,
                        _lbl_scale,
                        0
                    );
                }

                draw_set_halign(fa_left);
                draw_set_valign(fa_top);
            }
        }
    }

    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
