// ═══════════════════════════════════════════════════════════════
// people_traffic_system — обход людей стороной (пакет 260)
//
// ПОЛНАЯ ЗАМЕНА скрипта из 258/259.
//
// ── Почему 258 и 259 не работали ──
//
// Все 40 вызовов path_start в проекте идут с absolute = true:
//     path_start(my_path, p_move_speed, path_action_stop, true);
//
// При absolute-пути движок КАЖДЫЙ шаг заново вычисляет позицию
// прямо из path_position:
//     x = path_get_x(my_path, path_position);
//     y = path_get_y(my_path, path_position);
//
// То есть любой сдвиг вбок, который делала система, стирался уже
// на следующем кадре. Люди физически не могли отойти в сторону —
// они утыкались, топтались на месте, а через 2 секунды срабатывал
// аварийный таймер и они проходили насквозь.
//
// ── Как сделано сейчас ──
//
// Обход строится ПУТЁМ, а не сдвигом. Когда впереди человек,
// система перестраивает маршрут через ту же mp_grid, временно
// пометив клетки под встречным как занятые. mp_grid_path сам
// проводит дорогу с краю, в обход.
//
// Двигает персонажа при этом по-прежнему движок, по нормальному
// пути. Поэтому анимация работает штатно: image_speed = 1, кадры
// листаются, спрайт направления выбирается как обычно. Проблем
// «едет в одном спрайте» и «едет спиной» тут возникнуть не может
// в принципе — мы вообще не трогаем ни координаты, ни path_speed.
// ═══════════════════════════════════════════════════════════════


// ───────────────────────────────────────────────────────────────
// НАСТРОЙКИ
// ───────────────────────────────────────────────────────────────

/// @function people_traffic_defaults()
function people_traffic_defaults() {

    // Радиус личного места, пиксели.
    global.traffic_radius = 17;

    // На сколько пикселей вперёд человек смотрит, выбирая,
    // не пора ли обходить.
    global.traffic_look_ahead = 46;

    // Как часто разрешено перестраивать маршрут, в шагах.
    // Чаще — суетливее и тяжелее, реже — позже реагируют.
    global.traffic_detour_cooldown = 18;

    // Сколько шагов ждать, если обойти негде, прежде чем
    // разрешить медленно разойтись вплотную. 180 ≈ 3 сек.
    global.traffic_squeeze_steps = 180;

    // Сколько клеток сетки занимает человек в каждую сторону.
    // Сетка 16px, радиус человека 17px → 1 клетка.
    global.traffic_cell_pad = 1;

    global.traffic_priority_player = 100;
    global.traffic_priority_working = 80;
    global.traffic_priority_staff = 50;
    global.traffic_priority_visitor = 30;
}


/// @function people_traffic_priority(_inst)
function people_traffic_priority(_inst) {

    if (!instance_exists(_inst)) return 0;

    if (_inst.object_index == obj_player) return global.traffic_priority_player;

    if (people_traffic_is_anchored(_inst)) return global.traffic_priority_working;

    if (object_is_ancestor(_inst.object_index, par_staff)
        || _inst.object_index == par_staff) {
        return global.traffic_priority_staff;
    }

    return global.traffic_priority_visitor;
}


/// @function people_traffic_is_anchored(_inst)
/// @description Человек стоит на рабочей точке — его нельзя ни
///              двигать, ни просить уступить.
function people_traffic_is_anchored(_inst) {

    if (!instance_exists(_inst)) return true;

    if (variable_instance_exists(_inst, "reception_state")) {
        if (_inst.reception_state == "registering") return true;
    }

    if (variable_instance_exists(_inst, "doctor_state")) {
        var _ds = _inst.doctor_state;

        if (_ds == "manual_exam"
            || _ds == "manual_procedure"
            || _ds == "manual_registering"
            || _ds == "manual_payment"
            || _ds == "exam"
            || _ds == "procedure"
            || _ds == "operating"
            || _ds == "inpatient") return true;
    }

    if (variable_instance_exists(_inst, "_is_sitting")) {
        if (_inst._is_sitting) return true;
    }

    return false;
}


/// @function people_traffic_is_moving(_inst)
function people_traffic_is_moving(_inst) {

    if (!instance_exists(_inst)) return false;

    return (_inst.path_index != -1 && _inst.path_position < 1);
}


// ───────────────────────────────────────────────────────────────
// ГЛАВНЫЙ ШАГ
// ───────────────────────────────────────────────────────────────

/// @function people_traffic_step()
function people_traffic_step() {

    with (par_staff)    people_traffic_handle(id);
    with (par_visitors) people_traffic_handle(id);
}


/// @function people_traffic_handle(_inst)
/// @description Разбирает одного человека: свободно — идёт,
///              занято — обходит, обойти негде — ждёт.
function people_traffic_handle(_inst) {

    if (!instance_exists(_inst)) return;

    with (_inst) {

        if (!variable_instance_exists(id, "traffic_wait")) traffic_wait = 0;
        if (!variable_instance_exists(id, "traffic_cd")) traffic_cd = 0;
        if (!variable_instance_exists(id, "traffic_ppos")) traffic_ppos = -1;

        if (traffic_cd > 0) traffic_cd -= 1;

        if (!variable_instance_exists(id, "my_path")) exit;
        if (!path_exists(my_path)) exit;

        // Идёт ли он сейчас.
        if (path_index == -1 || path_position >= 1) {
            traffic_wait = 0;
            traffic_ppos = -1;
            exit;
        }

        // Запоминаем продвижение вдоль пути — понадобится,
        // чтобы честно стоять на месте, если придётся ждать.
        var _ppos_prev = traffic_ppos;
        traffic_ppos = path_position;

        // ── Кто впереди ──
        var _blocker = people_traffic_scan_ahead(id);

        if (_blocker == noone) {
            traffic_wait = 0;
            exit;
        }

        // ── ПОПУТЧИК: идёт туда же, куда и мы ──
        //
        // Это главный случай для очереди у стойки. Когда первый
        // уходит, вся очередь сдвигается на место вперёд, и каждый
        // видит перед собой спину соседа в 50 пикселях
        // (queue_step_x = -50 в obj_reception_desk).
        //
        // Ждать попутчика НЕЛЬЗЯ: он сам уходит вперёд и место
        // освобождает. Если ждать — вся очередь встаёт в цепочку и
        // топчется на месте, пока первый не отойдёт далеко. Именно
        // это и выглядело как «идут на месте 1-2 секунды».
        //
        // Обходить его тоже не надо: люди в очереди должны идти
        // друг за другом, а не обгонять соседа по краю.
        if (people_traffic_is_moving(_blocker)) {

            if (people_traffic_same_direction(id, _blocker)) {
                traffic_wait = 0;
                exit;
            }
        }

        // Встречный идёт и он младше по приоритету — пусть уступает он.
        var _his_pr = people_traffic_priority(_blocker);
        var _my_pr = people_traffic_priority(id);

        if (people_traffic_is_moving(_blocker) && _his_pr < _my_pr) {
            traffic_wait = 0;
            exit;
        }

        var _dest_x = path_get_x(my_path, 1);
        var _dest_y = path_get_y(my_path, 1);

        // ── МОЯ ТОЧКА СВОБОДНА — ИДУ, НЕ ОСТАНАВЛИВАЯСЬ ──
        //
        // Второй случай из той же истории с очередью. Место в очереди
        // отстоит от соседнего на 50 пикселей (queue_step_x = -50),
        // а человек замечает препятствие за 69 пикселей. То есть,
        // подходя к своему законному месту, он всегда «видит» спину
        // стоящего впереди — и вставал ждать, хотя его собственная
        // точка свободна.
        //
        // Проверяем прямо: если тот, кто мешает, стоит НЕ на моей
        // цели, значит цель свободна и надо спокойно дойти.
        var _blocker_on_my_spot =
            (point_distance(_dest_x, _dest_y, _blocker.x, _blocker.y)
                < global.traffic_radius * 1.5);

        var _near_my_spot =
            (point_distance(x, y, _dest_x, _dest_y)
                < global.traffic_look_ahead + global.traffic_radius);

        if (_near_my_spot && !_blocker_on_my_spot) {
            traffic_wait = 0;
            exit;
        }

        // ── Очередь: обходить нельзя, надо стоять ──
        // Если мы идём примерно туда же, где стоит встречный, это
        // очередь у стойки или сбор у стола. Обход тут выглядел бы
        // как лезущий без очереди.
        var _dest_is_his_spot =
            (point_distance(_dest_x, _dest_y, _blocker.x, _blocker.y) < 56);

        // ── Попытка обойти стороной ──
        if (!_dest_is_his_spot && traffic_cd <= 0) {

            traffic_cd = global.traffic_detour_cooldown;

            if (people_traffic_detour(id, _dest_x, _dest_y)) {
                traffic_wait = 0;
                exit;
            }
        }

        // ── Обойти негде: ждём, перебирая ногами ──
        traffic_wait += 1;

        // Совсем безвыходный затор — расходимся вплотную, чтобы
        // клиника не встала намертво.
        if (traffic_wait > global.traffic_squeeze_steps) exit;

        // Стоим на месте. Координаты возвращаем в те, что были до
        // шага движка, и откатываем продвижение по пути — иначе
        // при освобождении прохода человека бросит рывком вперёд.
        //
        // Путь при этом остаётся активным, поэтому image_speed = 1
        // сохраняется и ноги продолжают перебирать.
        x = xprevious;
        y = yprevious;

        if (_ppos_prev >= 0 && _ppos_prev < path_position) {
            path_position = _ppos_prev;
            traffic_ppos = _ppos_prev;
        }
    }
}


/// @function people_traffic_scan_ahead(_inst)
/// @description Кто мешает пройти. noone — свободно.
function people_traffic_scan_ahead(_inst) {

    var _r = global.traffic_radius;
    var _ahead = global.traffic_look_ahead;

    var _sx = _inst.x;
    var _sy = _inst.y;

    // Направление берём из пути — там, куда движок поведёт дальше.
    var _nx = path_get_x(_inst.my_path, min(1, _inst.path_position + 0.03));
    var _ny = path_get_y(_inst.my_path, min(1, _inst.path_position + 0.03));

    var _dx = _nx - _sx;
    var _dy = _ny - _sy;
    var _len = point_distance(0, 0, _dx, _dy);

    if (_len < 0.001) return noone;

    _dx /= _len;
    _dy /= _len;

    var _found = noone;
    var _best = 999999;

    // Проверяем две точки по курсу: под ногами впереди и дальше.
    var _steps = 2;

    for (var _s = 1; _s <= _steps; _s++) {

        var _px = _sx + (_dx * _ahead * (_s / _steps));
        var _py = _sy + (_dy * _ahead * (_s / _steps));

        var _hit = people_traffic_at_point(_px, _py, _inst, _r * 1.35);

        if (_hit != noone) {
            var _d = point_distance(_sx, _sy, _hit.x, _hit.y);

            if (_d < _best) {
                _best = _d;
                _found = _hit;
            }
        }
    }

    return _found;
}


/// @function people_traffic_at_point(_x, _y, _ignore, _rad)
function people_traffic_at_point(_x, _y, _ignore, _rad) {

    var _found = noone;

    with (par_staff) {
        if (id == _ignore) continue;
        if (point_distance(x, y, _x, _y) < _rad) { _found = id; break; }
    }

    if (_found != noone) return _found;

    with (par_visitors) {
        if (id == _ignore) continue;
        if (point_distance(x, y, _x, _y) < _rad) { _found = id; break; }
    }

    return _found;
}


// ───────────────────────────────────────────────────────────────
// ОБХОД ЧЕРЕЗ ПЕРЕСТРОЕНИЕ МАРШРУТА
// ───────────────────────────────────────────────────────────────

/// @function people_traffic_detour(_inst, _dest_x, _dest_y)
/// @description Строит новый маршрут до той же цели, обводя людей
///              стороной. Возвращает true, если обход найден.
///
///              ВАЖНО: работает на ОТДЕЛЬНОЙ сетке global.traffic_grid,
///              а не на global.ai_grid.
///
///              Почему так. Если помечать людей прямо в ai_grid, а
///              потом снимать пометки через mp_grid_clear_cell, то у
///              человека, стоящего вплотную к мебели, снятие пометки
///              РАЗБЛОКИРУЕТ клетку стены. Сетка испортилась бы
///              навсегда, и весь поиск пути в игре начал бы водить
///              людей сквозь мебель. Своя сетка эту опасность
///              убирает полностью: ai_grid не трогается вообще.
function people_traffic_detour(_inst, _dest_x, _dest_y) {

    // Проверяем флаг, а не сетку: функции mp_grid_exists в GML НЕТ.
    // Именно её вызов и ронял игру — компилятор принимал выдуманное
    // имя за несуществующую переменную.
    if (!variable_global_exists("traffic_grid_ready")) return false;
    if (!global.traffic_grid_ready) return false;

    var _grid = global.traffic_grid;
    var _cell = global.traffic_cell_size;
    var _pad = global.traffic_cell_pad;

    var _sx = _inst.x;
    var _sy = _inst.y;

    // 1. Статику и людей пересобираем не чаще одного раза за шаг:
    //    mp_grid_add_instances по всей мебели — самая дорогая
    //    операция здесь, и делать её на каждого пешехода незачем.
    people_traffic_refresh_grid();

    // 2. Клетки под людьми уже помечены в refresh. Свои снимаем ниже.

    // 3. Освобождаем клетки под собой и вокруг цели, иначе путь
    //    не сможет ни стартовать, ни финишировать. Здесь снятие
    //    безопасно: это наша временная сетка, а не ai_grid.
    people_traffic_clear_around(_grid, _cell, _sx, _sy, _pad + 1);
    people_traffic_clear_around(_grid, _cell, _dest_x, _dest_y, _pad);

    // 4. Строим обход.
    var _ok = mp_grid_path(
        _grid,
        _inst.my_path,
        _sx,
        _sy,
        _dest_x,
        _dest_y,
        true
    );

    // Возвращаем пометки людей, снятые вокруг себя и цели, чтобы
    // следующий пешеход на этом же шаге видел актуальную картину.
    people_traffic_mark_people(_grid, _cell, _pad, noone);

    if (!_ok) {
        // Обойти негде. Возвращаем обычный прямой маршрут по
        // штатной сетке, чтобы человек не остался с испорченным
        // путём и дошёл, когда проход освободится.
        mp_grid_path(global.ai_grid, _inst.my_path,
                     _sx, _sy, _dest_x, _dest_y, true);
        return false;
    }

    // 5. Запускаем маршрут с прежней скоростью.
    with (_inst) {
        var _spd = p_move_speed;

        if (path_speed > 0) _spd = path_speed;

        path_start(my_path, _spd, path_action_stop, true);
    }

    return true;
}


/// @function people_traffic_mark_people(_grid, _cell, _pad, _ignore)
/// @description Помечает занятыми клетки под всеми людьми, кроме себя.
function people_traffic_mark_people(_grid, _cell, _pad, _ignore) {

    with (par_staff) {
        if (id == _ignore) continue;
        people_traffic_mark_one(_grid, _cell, _pad, x, y);
    }

    with (par_visitors) {
        if (id == _ignore) continue;
        people_traffic_mark_one(_grid, _cell, _pad, x, y);
    }
}


/// @function people_traffic_mark_one(_grid, _cell, _pad, _x, _y)
function people_traffic_mark_one(_grid, _cell, _pad, _x, _y) {

    var _h = floor(_x / _cell);
    var _v = floor(_y / _cell);

    var _hmax = floor(room_width / _cell) - 1;
    var _vmax = floor(room_height / _cell) - 1;

    for (var _i = -_pad; _i <= _pad; _i++) {
        for (var _j = -_pad; _j <= _pad; _j++) {

            var _ch = clamp(_h + _i, 0, _hmax);
            var _cv = clamp(_v + _j, 0, _vmax);

            mp_grid_add_cell(_grid, _ch, _cv);
        }
    }
}


/// @function people_traffic_clear_around(_grid, _cell, _x, _y, _pad)
/// @description Освобождает клетки вокруг точки на временной сетке.
function people_traffic_clear_around(_grid, _cell, _x, _y, _pad) {

    var _h = floor(_x / _cell);
    var _v = floor(_y / _cell);

    var _hmax = floor(room_width / _cell) - 1;
    var _vmax = floor(room_height / _cell) - 1;

    for (var _i = -_pad; _i <= _pad; _i++) {
        for (var _j = -_pad; _j <= _pad; _j++) {

            var _ch = clamp(_h + _i, 0, _hmax);
            var _cv = clamp(_v + _j, 0, _vmax);

            mp_grid_clear_cell(_grid, _ch, _cv);
        }
    }
}


/// @function people_traffic_refresh_grid()
/// @description Пересобирает сетку обходов: статика + люди.
///              Выполняется не чаще одного раза за шаг игры.
function people_traffic_refresh_grid() {

    if (!global.traffic_grid_ready) return;

    // Один и тот же шаг — второй раз не пересобираем.
    if (global.traffic_grid_frame == global.traffic_frame) return;

    global.traffic_grid_frame = global.traffic_frame;

    var _grid = global.traffic_grid;

    mp_grid_clear_all(_grid);
    mp_grid_add_instances(_grid, par_objects, true);

    people_traffic_mark_people(
        _grid,
        global.traffic_cell_size,
        global.traffic_cell_pad,
        noone
    );
}


/// @function people_traffic_same_direction(_a, _b)
/// @description Идут ли двое примерно в одну сторону.
///
///              Нужно для очереди: сосед впереди, который уходит
///              туда же, куда идём мы, — не препятствие, а
///              попутчик. Его нельзя ни ждать, ни обходить.
///
///              Сравниваем направления движения по путям. Если угол
///              между ними меньше 70 градусов — считаем попутчиком.
function people_traffic_same_direction(_a, _b) {

    if (!instance_exists(_a) || !instance_exists(_b)) return false;

    var _a_dir = people_traffic_dir_raw(_a);
    var _b_dir = people_traffic_dir_raw(_b);

    var _adx = _a_dir[0];
    var _ady = _a_dir[1];

    var _bdx = _b_dir[0];
    var _bdy = _b_dir[1];

    // Кто-то стоит на месте — не попутчик.
    if (_adx == 0 && _ady == 0) return false;
    if (_bdx == 0 && _bdy == 0) return false;

    // Скалярное произведение единичных векторов = косинус угла.
    // cos(70°) ≈ 0.34
    var _dot = (_adx * _bdx) + (_ady * _bdy);

    return (_dot > 0.34);
}


/// @function people_traffic_dir_raw(_inst)
/// @description Возвращает [dx, dy] — куда человек движется сейчас.
function people_traffic_dir_raw(_inst) {

    if (!instance_exists(_inst)) return [0, 0];

    with (_inst) {

        if (!variable_instance_exists(id, "my_path")) return [0, 0];
        if (!path_exists(my_path)) return [0, 0];
        if (path_index == -1 || path_position >= 1) return [0, 0];

        var _nx = path_get_x(my_path, min(1, path_position + 0.03));
        var _ny = path_get_y(my_path, min(1, path_position + 0.03));

        var _dx = _nx - x;
        var _dy = _ny - y;

        var _len = point_distance(0, 0, _dx, _dy);

        if (_len < 0.001) return [0, 0];

        return [_dx / _len, _dy / _len];
    }

    return [0, 0];
}
