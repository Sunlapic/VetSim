/// Step obj_owner
/// @description Очередь, ожидание, приём, терпение и уход владельца.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 0. ВОССТАНОВЛЕНИЕ ПРЕРВАННОЙ РЕГИСТРАЦИИ ИЛИ ОПЛАТЫ
// Если администратора уволили во время работы, владелец автоматически
// возвращается в начало очереди и снова становится доступен игроку.
// ═══════════════════════════════════════════════════════════════

reception_recover_orphaned_registration(id, false);


// ═══════════════════════════════════════════════════════════════
// 1. ДОВОДКА ДВИЖЕНИЯ БЕЗ PATH
// Используется после резервного move_towards_point().
// ═══════════════════════════════════════════════════════════════

if (is_walking && path_index < 0) {
    var _at_target = false;
    var _destination_x = x;
    var _destination_y = y;
    var _destination_state = "";

    if (state == "going_to_exam" && variable_instance_exists(id, "exam_target_x")) {
        _destination_x = exam_target_x;
        _destination_y = exam_target_y;
        _destination_state = "in_exam";

        if (point_distance(x, y, _destination_x, _destination_y) <= 12) {
            _at_target = true;
        } else {
            move_towards_point(_destination_x, _destination_y, p_move_speed);
        }
    }
    else if (
        state == "going_to_waiting"
        && variable_global_exists("wait_spots")
        && wait_spot_index >= 0
        && wait_spot_index < array_length(global.wait_spots)
    ) {
        var _wait_spot = global.wait_spots[wait_spot_index];

        _destination_x = _wait_spot.x;
        _destination_y = _wait_spot.y;
        _destination_state = "waiting";

        if (point_distance(x, y, _destination_x, _destination_y) <= 12) {
            _at_target = true;
        } else {
            move_towards_point(_destination_x, _destination_y, p_move_speed);
        }
    }
    else if (state == "leaving_clinic") {
        _destination_x = leave_target_x;
        _destination_y = leave_target_y;

        if (point_distance(x, y, _destination_x, _destination_y) <= 16) {
            path_end();
            speed = 0;
            is_walking = false;
            instance_destroy();
            exit;
        } else {
            move_towards_point(_destination_x, _destination_y, p_move_speed);
        }
    }
    else {
        is_walking = false;
        move_towards_point(x, y, 0);
    }

    if (_at_target) {
        path_end();
        speed = 0;
        is_walking = false;
        move_towards_point(x, y, 0);

        if (_destination_state != "") {
            state = _destination_state;
        }

        exit;
    }
}


// ═══════════════════════════════════════════════════════════════
// 2. СОСТОЯНИЯ ВЛАДЕЛЬЦА
// ═══════════════════════════════════════════════════════════════

switch (state) {
    case "going_to_queue":
        if (point_distance(x, y, queue_target_x, queue_target_y) <= 10) {
            path_end();
            is_walking = false;
            state = "in_queue";
        }
    break;

    case "registering":
        path_end();
        is_walking = false;
    break;

    case "going_to_waiting":
        if (
            variable_global_exists("wait_spots")
            && wait_spot_index >= 0
            && wait_spot_index < array_length(global.wait_spots)
        ) {
            var _spot = global.wait_spots[wait_spot_index];

            if (point_distance(x, y, _spot.x, _spot.y) <= 10) {
                path_end();
                is_walking = false;
                state = "waiting";
            }
        }
    break;

    case "waiting":
        image_speed = 0;
        image_index = 0;
        is_walking = false;
    break;

    case "going_to_exam":
        // ПАКЕТ №341: владелец, пришедший забрать пациента из
        // стационара, не доводится напрямую и не телепортируется —
        // его ведёт контроллер палаты маршрутом по сетке.
        var _is_returning = (
            variable_instance_exists(id, "inpatient_returning")
            && inpatient_returning
        );
        // ═══════════════════════════════════════════════════════════
        // ПАКЕТ 283: ЗАВИСАНИЕ НА ПОДХОДЕ К СТОЛУ
        //
        // Путь строится через mp_grid_path по сетке с клеткой 16 px,
        // поэтому конец пути ложится в центр клетки и может отстоять
        // от exam_target на 11 px. Проверка прибытия требовала 10 px —
        // в эту щель владелец и проваливался.
        //
        // Выйти было некуда. Доводка в блоке 1 ждёт «is_walking &&
        // path_index < 0», а par_visitors при доходе пути ставит
        // is_walking = false, не вызывая path_end(): флаг уже снят,
        // а path_index ещё живой. Оба условия ложны одновременно.
        //
        // Страховка 276 тоже не срабатывала: она живёт в ветке
        // "in_exam", а владелец застревал шагом раньше. Ассистент
        // ждёт в "waiting_positions" ровно состояния "in_exam", а
        // антизависатель par_staff считает "going_to_exam" штатным
        // состоянием и не вмешивается. Отсюда картинка: собака
        // на столе, ассистент рядом, и все трое стоят вечно.
        // ═══════════════════════════════════════════════════════════

        if (!variable_instance_exists(id, "exam_walk_timer")) {
            exam_walk_timer = 0;
        }

        // Пакет №291: сколько раз уже перестраивали маршрут.
        if (!variable_instance_exists(id, "exam_walk_retries")) {
            exam_walk_retries = 0;
        }

        // Допуск поднят с 10 до 18 px: половина диагонали клетки
        // сетки плюс запас. На вид владелец стоит там же.
        if (point_distance(x, y, exam_target_x, exam_target_y) <= 18) {
            path_end();
            speed = 0;
            is_walking = false;
            exam_walk_timer = 0;

            if (!_is_returning) state = "in_exam";
            break;
        }

        // Путь уже закончился, а мы не дошли — доводим напрямую.
        // path_end() гасит path_index, и со следующего шага ведёт
        // штатный блок доводки из раздела 1.
        if (!_is_returning && (path_index == -1 || path_position >= 1)) {
            path_end();
            is_walking = true;
            move_towards_point(exam_target_x, exam_target_y, p_move_speed);
        }

        // ПАКЕТ №341: возвратника доводит палата — таймеры и телепорт
        // после трёх попыток ему не нужны.
        if (_is_returning) break;

        // ═══════════════════════════════════════════════════════════
        // ПАКЕТ №291: ВЛАДЕЛЕЦ ХОДИТ, А НЕ ЛЕТАЕТ
        //
        // В пакете 290 я заменил телепорт «подтягиванием» через прямое
        // изменение x и y. Это оказалось хуже телепорта, и вот почему.
        //
        // Первое: сдвиг координат ничего не знает о стенах. Сетка
        // global.ai_grid обходит препятствия только при построении
        // пути, а прибавление к x и y ведёт напрямую — владелец
        // проходил сквозь стену.
        //
        // Второе: анимация ходьбы у посетителей живёт в par_visitors и
        // включается ровно при условии «path_index != -1 && path_position
        // < 1». Я путь закрывал через path_end(), поэтому условие было
        // ложным, image_speed оставался нулевым — и владелец ехал одним
        // застывшим кадром.
        //
        // Правильное решение — не двигать персонажа руками, а заново
        // построить ему путь по сетке. Тогда работает и обход стен, и
        // анимация, потому что всё идёт штатным механизмом.
        // ═══════════════════════════════════════════════════════════

        exam_walk_timer += 1;

        // Раз в 6 секунд пробуем проложить маршрут заново. Обычно
        // помогает с первого раза: то, что мешало (чужая собака,
        // посетитель в дверях), к этому моменту уже отошло.
        if (exam_walk_timer >= room_speed * 6) {
            exam_walk_timer = 0;
            exam_walk_retries += 1;

            path_end();
            speed = 0;
            is_walking = false;

            if (mp_grid_path(
                global.ai_grid,
                my_path,
                x,
                y,
                exam_target_x,
                exam_target_y,
                true
            )) {
                path_set_kind(my_path, 1);
                path_start(my_path, p_move_speed, path_action_stop, true);
                is_walking = true;
            }
            else {
                // Сетка маршрута не нашла — идём напрямую. Здесь это
                // безопасно: move_towards_point ведёт штатная доводка
                // из раздела 1, и владелец остаётся видимо идущим.
                move_towards_point(exam_target_x, exam_target_y, p_move_speed);
                is_walking = true;
            }

            // Три попытки не помогли — значит, точка недостижима
            // по-настоящему (её загородили мебелью). Только тогда
            // ставим на место, чтобы приём не завис навсегда.
            if (exam_walk_retries >= 3) {
                exam_walk_retries = 0;

                path_end();
                speed = 0;
                is_walking = false;

                x = exam_target_x;
                y = exam_target_y;

                state = "in_exam";
            }
        }
    break;

    case "in_exam":
        // Пакет 283: дошли — готовим таймер к следующему визиту.
        exam_walk_timer = 0;

        // Пакет №291: и счётчик попыток тоже.
        exam_walk_retries = 0;

        image_speed = 0;
        image_index = 0;
        is_walking = false;

        // ═══════════════════════════════════════════════════════════
        // ПАКЕТ 276: СТРАХОВКА ОТ ЗАВИСАНИЯ У СТОЛА
        //
        // Владелец мог остаться в "in_exam" навсегда: персонал сбросил
        // свою задачу (кончился препарат, сработал антизависатель в
        // par_staff, ушла смена), стол освободился, а владелец так и
        // стоял у стола — из этого состояния нет выхода по таймеру.
        //
        // Триггер намеренно узкий: стол ЕСТЬ, но он больше не считает
        // нас своим клиентом. Это значит, что персонал ушёл, а нас
        // забыли. Если стола нет вовсе (assigned_table == noone) —
        // это стационар или операционная, туда не лезем.
        // ═══════════════════════════════════════════════════════════

        if (!variable_instance_exists(id, "exam_orphan_timer")) {
            exam_orphan_timer = 0;
        }

        var _orphaned = (
            instance_exists(assigned_table)
            && assigned_table.assigned_owner != id
        );

        // Кто-то из персонала всё ещё занимается нами — не сироты.
        //
        // Проверяем циклом, а не через with: внутри with нельзя
        // присвоить локальную переменную вызывающего через other,
        // локальные var там не видны.
        if (_orphaned) {
            var _staff_count = instance_number(par_staff);

            for (var _staff_index = 0; _staff_index < _staff_count; _staff_index++) {
                var _staff = instance_find(par_staff, _staff_index);

                if (
                    instance_exists(_staff)
                    && variable_instance_exists(_staff, "assigned_owner")
                    && _staff.assigned_owner == id
                ) {
                    _orphaned = false;
                    break;
                }
            }
        }

        // Игрок тоже может вести приём.
        if (_orphaned && instance_exists(obj_player)) {
            var _player_inst = instance_find(obj_player, 0);

            if (
                instance_exists(_player_inst)
                && variable_instance_exists(_player_inst, "assigned_owner")
                && _player_inst.assigned_owner == id
            ) {
                _orphaned = false;
            }
        }

        if (_orphaned) {
            exam_orphan_timer += 1;

            // 5 секунд запаса: за это время нормальная передача
            // пациента между врачом и ассистентом успевает пройти.
            if (exam_orphan_timer >= room_speed * 5) {
                exam_orphan_timer = 0;

                assigned_doctor = noone;
                assigned_table = noone;

                // Есть что оплатить — идём платить, иначе просто домой.
                var _has_bill = (
                    variable_instance_exists(id, "pending_payment_total")
                    && pending_payment_total > 0
                );

                if (_has_bill && instance_exists(obj_reception_desk)) {
                    reception_enqueue_priority_payment(id);
                }
                else {
                    owner_start_leaving(id);
                }
            }
        }
        else {
            exam_orphan_timer = 0;
        }
    break;

    case "leaving_clinic":
        if (point_distance(x, y, leave_target_x, leave_target_y) <= 16) {
            path_end();
            speed = 0;
            is_walking = false;
            instance_destroy();
            exit;
        }
    break;
}


// ═══════════════════════════════════════════════════════════════
// 3. ПОЛОСКА РЕГИСТРАЦИИ И ОПЛАТЫ
// ═══════════════════════════════════════════════════════════════

if (state != "registering" && registration_in_progress) {
    registration_in_progress = false;
    registration_timer = 0;
    registration_timer_max = 0;
    registration_actor_name = "";
}


// ═══════════════════════════════════════════════════════════════
// 4. РАЗВОРОТ К СТОЛУ И РЕГИСТРАТУРЕ
// Направления FR/B оставлены в соответствии с текущими спрайтами проекта.
// ═══════════════════════════════════════════════════════════════

if (state == "in_exam" && instance_exists(assigned_table)) {

    // ═══════════════════════════════════════════════════════════
    // Пакет 263: ВЛАДЕЛЕЦ НА ПРИЁМЕ — ЖИВАЯ IDLE-ПОЗА
    //
    // В 262 здесь жёстко ставился спрайт ходьбы с image_speed = 0
    // и image_index = 0. Получался застывший первый кадр ходьбы.
    //
    // Теперь этот блок НЕ трогает спрайт вообще: он только
    // разворачивает владельца по горизонтали к столу. Позу ставит
    // par_visitors -> End Step, ветка простоя, и ставит она
    // анимированный spr_human_FR_idle (13 кадров).
    //
    // Поза только фронтальная: спрайта idle со спины в проекте нет,
    // есть единственный spr_human_FR_idle. Поэтому владелец стоит
    // лицом вперёд и повёрнут в сторону стола — как и просили.
    //
    // image_speed и image_index здесь не задаются намеренно:
    // любое присвоение снова заморозило бы анимацию.
    // ═══════════════════════════════════════════════════════════

    var _table_dx = assigned_table.x - x;

    // Спрайт фронтальный, поэтому зеркалим по горизонтали:
    // стол слева — смотрим влево, стол справа — вправо.
    pFacing = (abs(_table_dx) > 1 && _table_dx < 0) ? -1 : 1;

    is_walking = false;
}
else if (
    (
        state == "registering"
        || state == "paying"
        || (state == "in_queue" && queue_slot == 0)
    )
    && instance_exists(assigned_desk)
) {
    // Нужна только горизонталь: поза фронтальная, по вертикали
    // разворачивать нечем (спрайта idle со спины в проекте нет).
    var _look_x = assigned_desk.x;

    if (
        variable_instance_exists(assigned_desk, "reception_staff_point")
        && instance_exists(assigned_desk.reception_staff_point)
    ) {
        _look_x = assigned_desk.reception_staff_point.x;
    }
    else if (variable_instance_exists(assigned_desk, "admin_spot_x")) {
        _look_x = assigned_desk.admin_spot_x;
    }

    var _look_dx = _look_x - x;
    // Пакет 263: у стойки та же история — только поворот, без
    // подмены спрайта. Анимированный idle ставит End Step.

    // Спрайт фронтальный: зеркалим в сторону администратора.
    pFacing = (abs(_look_dx) > 1 && _look_dx < 0) ? -1 : 1;

    is_walking = false;
}


// ═══════════════════════════════════════════════════════════════
// 5. СКОРОСТЬ ХОДЬБЫ И ТЕРПЕНИЕ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "owner_walk_speed_level")) {
    owner_generate_walk_speed(id);
}
else if (!variable_instance_exists(id, "owner_walk_speed_percent")) {
    owner_apply_walk_speed_level(id, owner_walk_speed_level);
}

// Терпение: уровень 1 = 15 секунд, уровень 10 = 87 секунд.
if (!variable_instance_exists(id, "patience_level")) {
    patience_level = irandom_range(1, 10);
    stat_patience = patience_level * 10;
}

if (!variable_instance_exists(id, "patience_success_progress")) {
    patience_success_progress = 0;
}

if (!variable_instance_exists(id, "patience_wait_xp_timer")) {
    patience_wait_xp_timer = 0;
}

if (!variable_instance_exists(id, "patience_xp_awarded_this_visit")) {
    patience_xp_awarded_this_visit = false;
}

if (!variable_instance_exists(id, "action_progress_active")) action_progress_active = false;
if (!variable_instance_exists(id, "action_progress_timer")) action_progress_timer = 0;
if (!variable_instance_exists(id, "action_progress_timer_max")) action_progress_timer_max = 1;
if (!variable_instance_exists(id, "action_progress_label")) action_progress_label = "";
if (!variable_instance_exists(id, "action_progress_color")) action_progress_color = c_white;

// Время ожидания увеличено в 2 раза: Lv.1 = 30 сек., Lv.10 = 174 сек.
var _wait_seconds = 30 + (patience_level - 1) * 16;
var _patience_max_frames = round(_wait_seconds * room_speed);

if (!variable_instance_exists(id, "patience_current")) {
    patience_current = _patience_max_frames;
    patience_max = _patience_max_frames;
}

if (!variable_instance_exists(id, "patience_max")) {
    patience_max = _patience_max_frames;
}


// ═══════════════════════════════════════════════════════════════
// 6. ОЖИДАНИЕ И ОКОНЧАНИЕ ТЕРПЕНИЯ
// ═══════════════════════════════════════════════════════════════

var _is_waiting = (state == "waiting" || state == "in_queue");

if (_is_waiting) {
    // За 10 секунд ожидания владелец получает 1/5 прогресса терпения.
    // За один визит награда выдаётся только один раз.
    if (!patience_xp_awarded_this_visit) {
        patience_wait_xp_timer += 1;

        if (patience_wait_xp_timer >= room_speed * 10) {
            var _old_patience_max = _patience_max_frames;
            var _patience_level_up = owner_patience_add_wait_progress(id);

            patience_xp_awarded_this_visit = true;

            if (_patience_level_up) {
                var _new_wait_seconds = 30 + (patience_level - 1) * 16;
                var _new_patience_max = round(_new_wait_seconds * room_speed);

                // Новый уровень сразу добавляет полученное время к текущему ожиданию.
                patience_current += max(0, _new_patience_max - _old_patience_max);
                patience_max = _new_patience_max;
                _patience_max_frames = _new_patience_max;

                if (instance_exists(obj_UI_HUD)) {
                    var _patience_hud = instance_find(obj_UI_HUD, 0);

                    if (
                        instance_exists(_patience_hud)
                        && variable_instance_exists(_patience_hud, "show_notice")
                    ) {
                        with (_patience_hud) {
                            show_notice(
                                "ТЕРПЕНИЕ ПОВЫШЕНО",
                                other.char_name + ": уровень " + string(other.patience_level),
                                room_speed * 3
                            );
                        }
                    }
                }
            }
        }
    }

    patience_current -= 1;

    // Первый клиент у стойки нервничает немного быстрее.
    if (queue_slot == 0) {
        patience_current -= 0.25;
    }

    action_progress_active = true;
    action_progress_timer = patience_current;
    action_progress_timer_max = patience_max;
    action_progress_label = "ОЖИДАНИЕ";
    action_progress_color = make_color_rgb(200, 140, 60);

    if (patience_current <= 0) {
        action_progress_active = false;
        action_progress_timer = 0;

        // Неудачное ожидание уменьшает только прогресс лояльности.
        owner_loyalty_apply_wait_failure(id);

        // Удаляем владельца из очереди стойки.
        if (instance_exists(assigned_desk) && variable_instance_exists(assigned_desk, "queue_list")) {
            var _queue_index = ds_list_find_index(assigned_desk.queue_list, id);

            if (_queue_index != -1) {
                ds_list_delete(assigned_desk.queue_list, _queue_index);
                assigned_desk.alarm[0] = 1;
            }
        }

        // Освобождаем место ожидания.
        if (
            variable_global_exists("wait_spots")
            && wait_spot_index >= 0
            && wait_spot_index < array_length(global.wait_spots)
        ) {
            global.wait_spots[wait_spot_index].occupied_by = noone;
            wait_spot_index = -1;
        }

        // Освобождаем смотровой стол.
        if (instance_exists(assigned_table)) {
            with (assigned_table) {
                table_busy = false;
                assigned_owner = noone;
                assigned_doctor = noone;
                assigned_pet = noone;
            }
        }

        assigned_table = noone;
        assigned_doctor = noone;
        assigned_pet = noone;

        if (variable_struct_exists(global, "speech_say")) {
            global.speech_say(id, "Слишком долго!", 2.4);
        }

        owner_start_leaving(id);

        if (instance_exists(obj_UI_HUD)) {
            var _hud = instance_find(obj_UI_HUD, 0);

            if (instance_exists(_hud) && variable_instance_exists(_hud, "show_notice")) {
                _hud.show_notice(
                    "КЛИЕНТ УШЁЛ",
                    "Не дождался приёма",
                    room_speed * 2
                );
            }
        }

        if (variable_global_exists("clinic_reputation")) {
            global.clinic_reputation = max(0, global.clinic_reputation - 1);
        }

        exit;
    }
} else {
    // Для следующего этапа обслуживания ожидание начинается с полного запаса.
    patience_current = _patience_max_frames;
    patience_max = _patience_max_frames;
    action_progress_active = false;
    action_progress_timer = 0;
}


// ═══════════════════════════════════════════════════════════════
// 7. ЗАЩИТА ОТ ЗАВИСАНИЯ ПРИ УХОДЕ
// ═══════════════════════════════════════════════════════════════

if (!variable_instance_exists(id, "leave_stuck_timer")) {
    leave_stuck_timer = 0;
}

if (state == "leaving_clinic") {
    var _exit_distance = point_distance(x, y, leave_target_x, leave_target_y);

    if (_exit_distance <= 16) {
        path_end();
        speed = 0;
        is_walking = false;
        instance_destroy();
        exit;
    }

    if (!is_walking) {
        leave_stuck_timer += 1;
    } else {
        leave_stuck_timer = 0;
    }

    if (leave_stuck_timer >= room_speed * 4) {
        leave_stuck_timer = 0;

        show_debug_message(
            "[OWNER EXIT] Повторный маршрут к выходу, id=" + string(id)
        );

        path_end();
        speed = 0;
        is_walking = false;

        if (mp_grid_path(
            global.ai_grid,
            my_path,
            x,
            y,
            leave_target_x,
            leave_target_y,
            true
        )) {
            path_set_kind(my_path, 1);
            path_start(my_path, p_move_speed, path_action_stop, true);
            is_walking = true;
        } else {
            move_towards_point(leave_target_x, leave_target_y, p_move_speed);
            is_walking = true;
        }
    }
} else {
    leave_stuck_timer = 0;
}


// ═══════════════════════════════════════════════════════════════
// 8. ГЛУБИНА
// ═══════════════════════════════════════════════════════════════

depth = -y;
