///Step par_animals

// 1. Подсветка теперь приходит только из obj_Render
is_hovered = (global.hover_target == id);

// 2. Клик по животному — открыть планшет
// Пакет №264: тап вместо момента касания (см. world_tap_input).
if (world_tap_on_me() && !global.ui_block_world_click && !(instance_exists(obj_UI_Tablet) && obj_UI_Tablet.visible)) {
    if (instance_exists(obj_UI_Tablet)) {
        obj_UI_Tablet.visible = true;
        obj_UI_Tablet.target_id = id;
    }
}

// 3. Если уже мёртв — ничего больше не делаем
if (is_dead) {
    depth = -y;
    exit;
}

// ─────────────────────────────────────────────
// 4. АНИМАЦИЯ ПРИ ДВИЖЕНИИ ПО PATH
// Для щенка анимацией управляет obj_dog_puppy End Step
// ─────────────────────────────────────────────
if (object_index != obj_dog_puppy) {

    if (path_index != -1 && path_position < 1) {
        image_speed = 1;

        var _nx = path_get_x(my_path, path_position + 0.02);

        if (_nx > x) pFacing = 1;
        if (_nx < x) pFacing = -1;

    } else {
        image_speed = 0;
        image_index = 0;
        is_walking = false;
    }

}

// ─────────────────────────────────────────────
// 5. СТЕЙТЫ ЖИВОТНОГО
// ─────────────────────────────────────────────
switch (state) {

    case "follow_owner":

        if (instance_exists(my_owner)) {

            if (!variable_instance_exists(id, "follow_offset_x")) follow_offset_x = 0;
            if (!variable_instance_exists(id, "follow_offset_y")) follow_offset_y = 0;

            var _tx = my_owner.x + follow_offset_x;
            var _ty = my_owner.y + follow_offset_y;

            x = lerp(x, _tx, 0.1);
            y = lerp(y, _ty, 0.1);

            if (abs(my_owner.x - x) > 3) {
                pFacing = (my_owner.x > x) ? 1 : -1;
            }
        }
    break;

    case "going_to_exam_floor":

        if (point_distance(x, y, exam_floor_x, exam_floor_y) <= 10) {
            path_end();
            is_walking = false;
            state = "jumping_to_table";
        }
    break;

    case "jumping_to_table":

        x = lerp(x, exam_table_x, table_jump_lerp);
        y = lerp(y, exam_table_y, table_jump_lerp);

        if (abs(exam_table_x - x) > 1) {
            pFacing = (exam_table_x > x) ? 1 : -1;
        }

        if (point_distance(x, y, exam_table_x, exam_table_y) <= 4) {
            x = exam_table_x;
            y = exam_table_y;
            state = "in_exam";
        }
    break;

    case "in_exam":
        path_end();
        is_walking = false;
        image_speed = 0;
        image_index = 0;

        // ═══════════════════════════════════════════════════════════
        // ПАКЕТ 277 (задача 4): СТРАХОВКА ОТ ЗАВИСАНИЯ НА СТОЛЕ
        //
        // Это состояние полностью пассивно: животное ждёт, пока его
        // уведёт кто-то снаружи. У персонала есть антизависатель, у
        // владельца — страховка из пакета 276, а у животных не было
        // ничего.
        //
        // Сейчас все штатные пути (оплата, уход домой, стационар)
        // уводят питомца сами. Но защита держится на том, что каждый
        // такой путь не забудет это сделать. Один забытый путь — и
        // животное остаётся на столе навсегда.
        //
        // ИСПРАВЛЕНО ПОСЛЕ ПРОВЕРКИ В ИГРЕ: первая версия выгоняла
        // пациентов из стационара и с операции. Разбор — ниже.
        // ═══════════════════════════════════════════════════════════

        if (!variable_instance_exists(id, "exam_orphan_timer")) {
            exam_orphan_timer = 0;
        }

        // ═══════════════════════════════════════════════════════════
        // ИСПРАВЛЕНИЕ: СНАЧАЛА ПРОВЕРЯЕМ, НЕ ЛЕЧИМСЯ ЛИ МЫ
        //
        // Первая версия этой страховки выгоняла пациентов из
        // стационара и с операции. Причина: при госпитализации игра
        // НАМЕРЕННО рвёт связь животного с владельцем
        // (_pet.my_owner = noone) и отправляет владельца домой — чтобы
        // его удаление не утащило за собой пациента.
        //
        // Для страховки это выглядело как «животное брошено», и она
        // добросовестно уводила его на выход. Отсюда и сбежавшие
        // из стационара, и уходящие с операции.
        //
        // Поэтому теперь сначала спрашиваем у самих систем, числится
        // ли животное за койкой или операционной. Отсутствие владельца
        // само по себе больше НЕ считается признаком брошенности.
        // ═══════════════════════════════════════════════════════════

        var _pet_in_treatment = false;

        // Лежит в стационаре?
        for (var _ward_index = 0; _ward_index < instance_number(obj_inpatient_controller); _ward_index++) {
            var _ward_check = instance_find(obj_inpatient_controller, _ward_index);

            if (
                instance_exists(_ward_check)
                && variable_instance_exists(_ward_check, "patient")
                && _ward_check.patient == id
            ) {
                _pet_in_treatment = true;
                break;
            }
        }

        // На операции или в послеоперационной?
        if (!_pet_in_treatment) {
            for (var _or_index = 0; _or_index < instance_number(obj_operating_controller); _or_index++) {
                var _or_check = instance_find(obj_operating_controller, _or_index);

                if (
                    instance_exists(_or_check)
                    && variable_instance_exists(_or_check, "or_pet")
                    && _or_check.or_pet == id
                ) {
                    _pet_in_treatment = true;
                    break;
                }
            }
        }

        // Флаг самой операции.
        if (
            variable_instance_exists(id, "or_in_surgery")
            && or_in_surgery
        ) {
            _pet_in_treatment = true;
        }

        // Лежим на стационарном или операционном столе.
        if (
            !_pet_in_treatment
            && variable_instance_exists(id, "assigned_table")
            && instance_exists(assigned_table)
        ) {
            var _table_object = assigned_table.object_index;

            if (
                _table_object == obj_inpatient_table
                || _table_object == obj_operating_table
            ) {
                _pet_in_treatment = true;
            }
        }

        var _pet_orphaned = false;

        // Признак брошенности теперь один: владелец ЕСТЬ, но он ушёл
        // заниматься своими делами, а мы всё ещё стоим на приёме.
        // Случай «владельца нет вовсе» намеренно НЕ трогаем: это и
        // есть штатная госпитализация.
        if (
            !_pet_in_treatment
            && instance_exists(my_owner)
            && variable_instance_exists(my_owner, "state")
        ) {
            _pet_orphaned = (
                my_owner.state == "leaving_clinic"
                || my_owner.state == "paying"
                || my_owner.state == "in_queue"
                || my_owner.state == "waiting"
            );
        }

        if (_pet_orphaned) {
            exam_orphan_timer += 1;

            // 5 секунд запаса, как у владельца в пакете 276.
            if (exam_orphan_timer >= room_speed * 5) {
                exam_orphan_timer = 0;

                assigned_doctor = noone;
                assigned_table = noone;

                // Только «иду за владельцем» — он существует, это
                // проверено выше. Ветку «ухожу из клиники сам» я убрал:
                // именно она выгоняла пациентов стационара, а без
                // владельца животное теперь и не считается брошенным.
                state = "follow_owner";
                follow_offset_x = 30;
                follow_offset_y = 20;
            }
        }
        else {
            exam_orphan_timer = 0;
        }
    break;

    case "leaving_clinic":

        if (point_distance(x, y, leave_target_x, leave_target_y) <= 16) {
            instance_destroy();
        }
    break;
}

// ─────────────────────────────────────────────
// 6. ОБНОВЛЕНИЕ ВОЗРАСТА И СОСТОЯНИЯ
// ─────────────────────────────────────────────

// ═════════════════════════════════════════════════════════════════
// СТРАХОВКА РАЗМЕРА (добавлено после «огромной собаки в палате»)
//
// Размер животного пересчитывается ниже, но только внутри ветки
// «если владелец существует». У пациента стационара владельца
// намеренно нет — значит, размер ему не назначит никто, и он
// останется равным 1, то есть спрайт во всю величину.
//
// Здесь только аварийный случай: масштаб явно не задан (близок к 1
// или к нулю). Нормальные значения — 0.2 / 0.4 / 0.6 / 0.9, поэтому
// живого животного эта проверка не касается.
// ═════════════════════════════════════════════════════════════════
if (image_xscale >= 0.99 || image_xscale <= 0.01) {

    var _fix_scale = 0.6;

    if (pet_age_days < 30)       _fix_scale = 0.2;
    else if (pet_age_days < 60)  _fix_scale = 0.4;
    else if (pet_age_days < 365) _fix_scale = 0.6;
    else                         _fix_scale = 0.9;

    // Знак сохраняем: он отвечает за разворот животного.
    image_xscale = (image_xscale < 0) ? -_fix_scale : _fix_scale;
    image_yscale = _fix_scale;
}

if (instance_exists(my_owner)) {

    if (variable_instance_exists(my_owner, "pet_birth_day")) {
        pet_age_days = global.game_day - my_owner.pet_birth_day;
    }

    if (pet_age_days < 30) {
        life_stage = PET_STAGE.PUPPY;
        image_xscale = 0.2;
        image_yscale = 0.2;
    } else if (pet_age_days < 60) {
        life_stage = PET_STAGE.TEEN;
        image_xscale = 0.4;
        image_yscale = 0.4;
    } else if (pet_age_days < 365) {
        life_stage = PET_STAGE.ADULT;
        image_xscale = 0.6;
        image_yscale = 0.6;
    } else {
        life_stage = PET_STAGE.SENIOR;
        image_xscale = 0.9;
        image_yscale = 0.9;
    }

    // ─────────────────────────────────────────
    // ВРЕМЕННОЕ ПРАВИЛО:
    // здоровье падает ТОЛЬКО пока пациент ждёт,
    // и НЕ падает в пути / в очереди / на приёме
    // ─────────────────────────────────────────
    var _allow_condition_drop = false;

    if (variable_instance_exists(my_owner, "state")) {
        switch (my_owner.state) {
            case "waiting":
                _allow_condition_drop = true;
            break;
        }
    }

    if (_allow_condition_drop && hidden_disease_id != "" && condition > 0) {

        condition_decay_counter += max(1, global.time_speed);

        if (condition_decay_counter >= condition_decay_interval) {
            condition_decay_counter -= condition_decay_interval;

            var _severity = 1;
            if (is_struct(current_case)) {
                if (variable_struct_exists(current_case, "severity_level")) {
                    _severity = current_case.severity_level;
                }
            }

            var _dec = 0.10; // лёгкий случай
            switch (_severity) {
                case 1: _dec = 0.10; break;
                case 2: _dec = 0.18; break;
                case 3: _dec = 0.30; break;
            }

            condition = max(0, condition - _dec);

            if (is_struct(current_case)) {
                current_case.condition = condition;
            }

            if (condition <= 0) {
                pet_die("illness");
            }
        }

    } else {
        condition_decay_counter = 0;
    }
}
// ─────────────────────────────────────────────
// 7. DEPTH
// Если животное на столе — рисуем его чуть ПОВЕРХ стола
// ─────────────────────────────────────────────
if ((state == "jumping_to_table" || state == "in_exam") && instance_exists(assigned_table)) {
    depth = assigned_table.depth - 1;
} else {
    depth = -y;
}