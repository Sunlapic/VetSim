/// animal_walk_system.gml
/// @description Ходьба животных по сетке путей. Пакет №323.
///
/// ── Зачем ──
///
/// Животное отправляли в путь так:
///
///     if (mp_grid_path(...)) { path_start(...); }
///     else { move_towards_point(...); }
///
/// Запасная ветка move_towards_point ведёт по ПРЯМОЙ — мимо сетки,
/// мимо стен. Именно она и давала собаку, идущую с приёма в стационар
/// сквозь стену.
///
/// Причём срабатывала она регулярно: путь не строится, если ЦЕЛЬ стоит
/// на закрытой клетке. Точка пола у койки лежит вплотную к мебели, а
/// mp_grid считает клетку с мебелью непроходимой целиком — 16 пикселей
/// сетки против сантиметра перекрытия.
///
/// Здесь та же логика, что у персонала (inpatient_walk_to): если в саму
/// точку пути нет, ищем ближайшую достижимую клетку рядом. И только
/// если не нашли вообще ничего — идём напрямик, но об этом пишем в
/// консоль, чтобы такие места было видно.


/// @function animal_walk_to(_animal, _target_x, _target_y)
/// @description Ведёт животное по сетке путей. Возвращает true, если
///              маршрут построен (а не прямая линия).
function animal_walk_to(_animal, _target_x, _target_y) {

    if (!instance_exists(_animal)) return false;
    if (!variable_instance_exists(_animal, "my_path")) return false;

    var _built = false;

    with (_animal) {
        path_end();
        speed = 0;
        hspeed = 0;
        vspeed = 0;
        is_walking = false;

        // Уже на месте — никуда не идём. Вызов move_towards_point с
        // нулевым расстоянием задал бы направление 0, и животное
        // поехало бы вправо (эти грабли уже описаны в inpatient_walk_to).
        if (point_distance(x, y, _target_x, _target_y) <= 6) {
            return true;
        }

        _built = mp_grid_path(
            global.ai_grid,
            my_path,
            x,
            y,
            _target_x,
            _target_y,
            true
        );

        // ── Цель на закрытой клетке: ищем проходимую рядом ──
        //
        // Кольцами от центра, чтобы найти ближайшую подходящую, а не
        // первую попавшуюся. Радиусы подобраны под сетку в 16 пикселей.
        if (!_built) {
            var _rings = [16, 24, 32, 48, 64];

            for (var _ring = 0; _ring < array_length(_rings); _ring++) {
                var _r = _rings[_ring];

                // Восемь направлений вокруг цели.
                var _dirs = [
                    [0, -_r], [0, _r], [-_r, 0], [_r, 0],
                    [-_r, -_r], [_r, -_r], [-_r, _r], [_r, _r]
                ];

                for (var _d = 0; _d < array_length(_dirs); _d++) {
                    var _cx = _target_x + _dirs[_d][0];
                    var _cy = _target_y + _dirs[_d][1];

                    if (mp_grid_path(
                        global.ai_grid,
                        my_path,
                        x,
                        y,
                        _cx,
                        _cy,
                        true
                    )) {
                        _built = true;
                        break;
                    }
                }

                if (_built) break;
            }
        }

        if (_built) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
        }
        else {
            // Совсем нет дороги. Идём напрямик — иначе животное
            // застрянет навсегда, — но сообщаем: такое место в комнате
            // стоит поправить.
            show_debug_message(
                "[ANIMAL] Нет пути к ("
                + string(_target_x) + "," + string(_target_y)
                + ") — иду напрямик. Проверьте проходимость."
            );

            move_towards_point(_target_x, _target_y, p_move_speed);
            is_walking = true;
        }
    }

    return _built;
}
