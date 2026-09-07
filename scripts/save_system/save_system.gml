/// save_system.gml
/// @description Пакет №269: сохранение и загрузка игры.
///
/// ═══════════════════════════════════════════════════════════════
/// ЗАЧЕМ
///
/// До этого пакета в игре не было сохранений ВООБЩЕ — ни ini, ни файлов.
/// Всё жило в global.* и умирало при выходе. Для карты клиник это
/// критично: купленная за $10 000 клиника исчезала бы при перезапуске.
///
/// Этот пакет — фундамент под карту (пакеты 270+). Карты здесь ещё нет,
/// сохраняется текущая одна клиника.
///
/// ═══════════════════════════════════════════════════════════════
/// ЧТО СОХРАНЯЕТСЯ
///
///   деньги, баллы, репутация, чистота
///   дата и время (день, час, минута, календарь)
///   купленные комнаты и койки (global.clinic_rooms_open)
///   улучшения клиники (global.clinic_upgrades)
///   склад (global.inventory_main)
///   шкафы кабинетов (пакет 275, по exam_slot_id)
///   ВЕСЬ персонал: навыки, опыт, энергия, лояльность, характер,
///     рабочее место и ВНЕШНОСТЬ
///   игрок: навыки и опыт
///
/// ЧТО НЕ СОХРАНЯЕТСЯ (осознанно)
///
///   посетители и их питомцы в процессе приёма — при загрузке клиника
///     начинает день с чистого листа, недолеченные визиты пропадают
///   пациенты стационара — появятся в пакете 273 вместе с картой
///   кандидаты на найм — придут новые
///   пути, таймеры, состояния конечных автоматов
///
/// ═══════════════════════════════════════════════════════════════
/// ГЛАВНАЯ ЛОВУШКА: СПРАЙТЫ ВНЕШНОСТИ
///
/// Внешность персонажа (my_hair, my_nose, my_eyes, my_mouth,
/// my_hair_back) — это АССЕТЫ, то есть числовые id спрайтов. Эти id
/// GameMaker раздаёт при сборке проекта и они МЕНЯЮТСЯ, если добавить
/// или удалить хотя бы один спрайт.
///
/// Если сохранить число, то после добавления новых спрайтов одежды у
/// всех врачей поедут лица: нос станет ртом и так далее.
///
/// Поэтому спрайты сохраняются по ИМЕНИ через sprite_get_name(), а при
/// загрузке восстанавливаются через asset_get_index(). Имя стабильно.
/// ═══════════════════════════════════════════════════════════════


// Версия формата. Если поменяется структура — старые сейвы отбрасываются,
// а не читаются криво.
#macro SAVE_FORMAT_VERSION 1
#macro SAVE_FILE_NAME "vetsim_save.json"


// ═══════════════════════════════════════════════════════════════
// 1. ВСПОМОГАТЕЛЬНОЕ: СПРАЙТЫ ПО ИМЕНИ
// ═══════════════════════════════════════════════════════════════

/// Спрайт -> имя. Возвращает "" если спрайта нет.
function save_sprite_to_name(_sprite_id) {
    if (!sprite_exists(_sprite_id)) return "";

    return sprite_get_name(_sprite_id);
}


/// Имя -> спрайт. Возвращает -1 если такого спрайта в проекте больше нет.
function save_sprite_from_name(_name) {
    var _str = string(_name);

    if (_str == "") return -1;

    var _index = asset_get_index(_str);

    if (_index == -1) return -1;
    if (!sprite_exists(_index)) return -1;

    return _index;
}


/// Безопасное чтение поля структуры со значением по умолчанию.
function save_field(_struct, _key, _default) {
    if (!is_struct(_struct)) return _default;
    if (!variable_struct_exists(_struct, _key)) return _default;

    var _value = variable_struct_get(_struct, _key);

    if (is_undefined(_value)) return _default;

    return _value;
}


/// Безопасное чтение глобальной переменной по имени.
///
/// ВАЖНО: global НЕ является структурой — is_struct(global) возвращает
/// false, поэтому save_global(...) всегда отдавал бы значение по
/// умолчанию. Глобалки читаются только так.
function save_global(_key, _default) {
    if (!variable_global_exists(_key)) return _default;

    var _value = variable_global_get(_key);

    if (is_undefined(_value)) return _default;

    return _value;
}


/// Безопасное чтение поля объекта.
function save_inst_field(_inst, _key, _default) {
    if (!instance_exists(_inst)) return _default;
    if (!variable_instance_exists(_inst, _key)) return _default;

    var _value = variable_instance_get(_inst, _key);

    if (is_undefined(_value)) return _default;

    return _value;
}


/// Копия массива чисел КАК ЕСТЬ — длина сохраняется исходной.
///
/// ВАЖНО: у разных ролей массивы навыков РАЗНОЙ длины.
///   врач/ассистент  skills = 10 элементов
///   администратор   skills, skill_xp, skill_xp_needed = 2 элемента
///   ассистент       assistant_skill_levels/_xp = 3 элемента
///   игрок           player_admin_* = 2, player_assistant_* = 3
///
/// Выравнивать их до общей длины НЕЛЬЗЯ: раздутый до 10 элементов
/// массив админа ломает admin_recalc_skills.
///
/// Возвращает "" если массива нет, чтобы при загрузке отличить
/// «поля не было» от «поле пустое».
function save_copy_array_asis(_inst, _key) {
    if (!variable_instance_exists(_inst, _key)) return "";

    var _array = variable_instance_get(_inst, _key);

    if (!is_array(_array)) return "";

    var _result = [];

    for (var _i = 0; _i < array_length(_array); _i++) {
        array_push(_result, real(_array[_i]));
    }

    return _result;
}


/// Копия массива строк (журнал опыта xp_log в карточке).
/// Возвращает "" если поля нет.
function save_copy_struct_array(_inst, _key) {
    if (!variable_instance_exists(_inst, _key)) return "";

    var _array = variable_instance_get(_inst, _key);

    if (!is_array(_array)) return "";

    var _result = [];

    for (var _i = 0; _i < array_length(_array); _i++) {
        array_push(_result, string(_array[_i]));
    }

    return _result;
}


/// Восстановление массива, сохранённого через save_copy_array_asis.
/// Ничего не делает, если в сейве этого поля не было.
function save_restore_array_asis(_inst, _key, _value) {
    if (!instance_exists(_inst)) return false;
    if (!is_array(_value)) return false;

    var _copy = [];

    for (var _i = 0; _i < array_length(_value); _i++) {
        array_push(_copy, real(_value[_i]));
    }

    variable_instance_set(_inst, _key, _copy);

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 2. СЛЕПОК СОТРУДНИКА
// ═══════════════════════════════════════════════════════════════

/// Сворачивает сотрудника в структуру, пригодную для записи в файл.
function save_staff_snapshot(_staff) {
    if (!instance_exists(_staff)) return undefined;

    var _object_name = object_get_name(_staff.object_index);

    return {
        // ── кто это ──
        object_name : _object_name,
        char_name : string(save_inst_field(_staff, "char_name", "Сотрудник")),
        role : string(save_inst_field(_staff, "role", "assistant")),
        age : real(save_inst_field(_staff, "age", 25)),
        is_female : save_inst_field(_staff, "is_female", false),
        character_trait : real(save_inst_field(_staff, "character_trait", 0)),
        specialty_title : string(save_inst_field(_staff, "specialty_title", "")),

        // ── где стоит ──
        x : real(_staff.x),
        y : real(_staff.y),
        home_x : real(save_inst_field(_staff, "home_x", _staff.x)),
        home_y : real(save_inst_field(_staff, "home_y", _staff.y)),

        // ══ НАВЫКИ И ОПЫТ ══
        //
        // Массивы пишутся КАК ЕСТЬ, без выравнивания до 10 элементов:
        // у администратора skills/skill_xp/skill_xp_needed состоят из
        // ДВУХ элементов (Регистрация, Касса), и раздутый до десяти
        // массив сломал бы admin_recalc_skills.
        skills : save_copy_array_asis(_staff, "skills"),
        skill_xp : save_copy_array_asis(_staff, "skill_xp"),
        skill_xp_needed : save_copy_array_asis(_staff, "skill_xp_needed"),
        skills_sum : real(save_inst_field(_staff, "skills_sum", 0)),

        // ── админ: отдельный массив уровней ──
        // У obj_staff_admin прогресс живёт в skill_level = [Регистрация,
        // Касса], а НЕ в skills. Без него админ после загрузки
        // возвращался к случайным 1–2.
        skill_level : save_copy_array_asis(_staff, "skill_level"),

        // ── ассистент: вторичные навыки ──
        // Процедуры / Пополнение / Чистота. Именно эти поля показывает
        // карточка ассистента, и именно они «сбрасывались» после
        // загрузки, потому что assistant_extra_skills_init выдавал их
        // заново из случайных skills.
        assistant_skill_levels : save_copy_array_asis(_staff, "assistant_skill_levels"),
        assistant_skill_xp : save_copy_array_asis(_staff, "assistant_skill_xp"),

        // ── общие навыки ──
        walk_skill_level : real(save_inst_field(_staff, "walk_skill_level", 1)),
        walk_skill_xp : real(save_inst_field(_staff, "walk_skill_xp", 0)),
        walk_skill_xp_needed : real(save_inst_field(_staff, "walk_skill_xp_needed", 30)),
        stamina_level : real(save_inst_field(_staff, "stamina_level", 1)),
        stamina_xp : real(save_inst_field(_staff, "stamina_xp", 0)),
        stamina_xp_needed : real(save_inst_field(_staff, "stamina_xp_needed", 30)),

        // ── журнал опыта в карточке ──
        xp_log : save_copy_struct_array(_staff, "xp_log"),

        // ── состояние ──
        stat_energy : real(save_inst_field(_staff, "stat_energy", 100)),
        energy_max : real(save_inst_field(_staff, "energy_max", 100)),
        loyalty : real(save_inst_field(_staff, "loyalty", 75)),
        stat_loyalty : real(save_inst_field(_staff, "stat_loyalty", 75)),
        salary : real(save_inst_field(_staff, "salary", 0)),

        // ── ПАКЕТ 320: договорённости по зарплате ──
        //
        // hire_skill_sum — навыки на момент найма, по ним считается
        // рост. Без сохранения сотрудник после загрузки «забывал»,
        // сколько он вырос, и просил прибавку заново.
        hire_skill_sum : real(save_inst_field(_staff, "hire_skill_sum", 0)),
        staff_loyalty : real(save_inst_field(_staff, "staff_loyalty", 100)),
        raise_refusals : real(save_inst_field(_staff, "raise_refusals", 0)),
        raise_pending : save_inst_field(_staff, "raise_pending", false),
        raise_amount : real(save_inst_field(_staff, "raise_amount", 0)),
        raise_check_day : real(save_inst_field(_staff, "raise_check_day", 0)),

        // ── рабочее место ──
        workplace_id : string(save_inst_field(_staff, "workplace_id", "reception")),

        // ── ВНЕШНОСТЬ: только имена, не числа! ──
        my_hair : save_sprite_to_name(save_inst_field(_staff, "my_hair", -1)),
        my_hair_back : save_sprite_to_name(save_inst_field(_staff, "my_hair_back", -1)),
        my_eyes : save_sprite_to_name(save_inst_field(_staff, "my_eyes", -1)),
        my_nose : save_sprite_to_name(save_inst_field(_staff, "my_nose", -1)),
        my_mouth : save_sprite_to_name(save_inst_field(_staff, "my_mouth", -1)),
        hair_color : real(save_inst_field(_staff, "hair_color", c_white)),

        // ── ОДЕЖДА ──
        //
        // Эти переменные НЕ задаются в Create. Их лениво выдаёт Draw
        // при первом кадре отрисовки: `if (!variable_instance_exists(
        // id, "robe_color")) robe_color = staff_random_scrub_color();`
        //
        // Значит без сохранения после каждой загрузки Draw увидел бы
        // «переменной нет» и выдал НОВЫЙ случайный цвет — форма всего
        // штата меняла бы цвет при каждом запуске игры.
        //
        // -1 как маркер «не было» здесь не годится: -1 это валидный
        // цвет (c_white). Поэтому отсутствующие поля пишем строкой "",
        // а при загрузке восстанавливаем только непустые.
        robe_color : variable_instance_exists(_staff, "robe_color")
            ? real(_staff.robe_color) : "",
        scrub_pattern : variable_instance_exists(_staff, "scrub_pattern")
            ? real(_staff.scrub_pattern) : "",
        scrub_pat_size : variable_instance_exists(_staff, "scrub_pat_size")
            ? real(_staff.scrub_pat_size) : "",
        scrub_pat_phase : variable_instance_exists(_staff, "scrub_pat_phase")
            ? real(_staff.scrub_pat_phase) : "",
        crocs_color : variable_instance_exists(_staff, "crocs_color")
            ? real(_staff.crocs_color) : "",
        pants_style : variable_instance_exists(_staff, "pants_style")
            ? real(_staff.pants_style) : "",
        pants_color : variable_instance_exists(_staff, "pants_color")
            ? real(_staff.pants_color) : "",

        // ── портрет ──
        portrait_x : real(save_inst_field(_staff, "portrait_x", 150)),
        portrait_y : real(save_inst_field(_staff, "portrait_y", 50)),
        portrait_zoom : real(save_inst_field(_staff, "portrait_zoom", 1)),
        portrait_offset : real(save_inst_field(_staff, "portrait_offset", 35))
    };
}


/// Разворачивает слепок обратно в живого сотрудника.
function save_staff_restore(_data) {
    if (!is_struct(_data)) return noone;

    var _object_name = string(save_field(_data, "object_name", ""));
    var _object_index = asset_get_index(_object_name);

    if (_object_index == -1) {
        show_debug_message(
            "[SAVE] Неизвестный объект сотрудника: " + _object_name
        );
        return noone;
    }

    var _staff = instance_create_layer(
        save_field(_data, "x", 0),
        save_field(_data, "y", 0),
        "Instances",
        _object_index
    );

    if (!instance_exists(_staff)) return noone;

    with (_staff) {
        char_name = string(save_field(_data, "char_name", "Сотрудник"));
        role = string(save_field(_data, "role", "assistant"));
        age = save_field(_data, "age", 25);
        is_female = save_field(_data, "is_female", false);
        character_trait = save_field(_data, "character_trait", 0);
        specialty_title = string(save_field(_data, "specialty_title", ""));

        home_x = save_field(_data, "home_x", x);
        home_y = save_field(_data, "home_y", y);

        // ══ НАВЫКИ И ОПЫТ ══
        //
        // Восстанавливаем с ИСХОДНОЙ длиной массива. Каждое поле
        // ставится только если оно реально было в сейве, иначе
        // оставляем то, что выдал Create.
        save_restore_array_asis(id, "skills", save_field(_data, "skills", ""));
        save_restore_array_asis(id, "skill_xp", save_field(_data, "skill_xp", ""));
        save_restore_array_asis(id, "skill_xp_needed", save_field(_data, "skill_xp_needed", ""));
        save_restore_array_asis(id, "skill_level", save_field(_data, "skill_level", ""));
        save_restore_array_asis(id, "assistant_skill_levels",
            save_field(_data, "assistant_skill_levels", ""));
        save_restore_array_asis(id, "assistant_skill_xp",
            save_field(_data, "assistant_skill_xp", ""));

        skills_sum = save_field(_data, "skills_sum", 0);

        walk_skill_level = save_field(_data, "walk_skill_level", 1);
        walk_skill_xp = save_field(_data, "walk_skill_xp", 0);
        walk_skill_xp_needed = save_field(_data, "walk_skill_xp_needed", 30);
        stamina_level = save_field(_data, "stamina_level", 1);
        stamina_xp = save_field(_data, "stamina_xp", 0);
        stamina_xp_needed = save_field(_data, "stamina_xp_needed", 30);

        // Журнал опыта в карточке — массив строк.
        var _xp_log = save_field(_data, "xp_log", "");

        if (is_array(_xp_log)) {
            xp_log = [];

            for (var _l = 0; _l < array_length(_xp_log); _l++) {
                array_push(xp_log, string(_xp_log[_l]));
            }
        }

        stat_energy = save_field(_data, "stat_energy", 100);
        energy_max = save_field(_data, "energy_max", 100);
        energy = stat_energy;
        loyalty = save_field(_data, "loyalty", 75);
        stat_loyalty = save_field(_data, "stat_loyalty", 75);
        salary = save_field(_data, "salary", 0);

        // ПАКЕТ 320: договорённости по зарплате.
        //
        // Для старых сохранений hire_skill_sum придёт нулём — тогда
        // берём текущие навыки, иначе сотрудник сразу решит, что вырос
        // на весь свой уровень, и потребует прибавку в первый же день.
        hire_skill_sum = save_field(_data, "hire_skill_sum", 0);

        if (hire_skill_sum <= 0) {
            hire_skill_sum = variable_instance_exists(id, "skills_sum")
                ? skills_sum
                : 0;
        }

        staff_loyalty = save_field(_data, "staff_loyalty", 100);
        raise_refusals = save_field(_data, "raise_refusals", 0);
        raise_pending = save_field(_data, "raise_pending", false);
        raise_amount = save_field(_data, "raise_amount", 0);
        raise_check_day = save_field(_data, "raise_check_day", 0);

        workplace_id = string(save_field(_data, "workplace_id", "reception"));
        workplace_pending = "";

        // Внешность восстанавливается по именам спрайтов.
        my_hair = save_sprite_from_name(save_field(_data, "my_hair", ""));
        my_hair_back = save_sprite_from_name(save_field(_data, "my_hair_back", ""));
        my_eyes = save_sprite_from_name(save_field(_data, "my_eyes", ""));
        my_nose = save_sprite_from_name(save_field(_data, "my_nose", ""));
        my_mouth = save_sprite_from_name(save_field(_data, "my_mouth", ""));
        hair_color = save_field(_data, "hair_color", c_white);

        portrait_x = save_field(_data, "portrait_x", 150);
        portrait_y = save_field(_data, "portrait_y", 50);
        portrait_zoom = save_field(_data, "portrait_zoom", 1);
        portrait_offset = save_field(_data, "portrait_offset", 35);

        // ── ОДЕЖДА ──
        //
        // Восстанавливаем ТОЛЬКО реально сохранённые поля. Пустая
        // строка означает «этого поля у сотрудника не было» — тогда
        // переменную не создаём вовсе, и Draw выдаст цвет сам, как
        // при первом появлении персонажа.
        //
        // Проверяем именно is_real: пустая строка отсеется, а любой
        // валидный цвет (включая 0 и -1) пройдёт.
        var _robe = save_field(_data, "robe_color", "");
        if (is_real(_robe)) robe_color = _robe;

        var _pattern = save_field(_data, "scrub_pattern", "");
        if (is_real(_pattern)) scrub_pattern = _pattern;

        var _pat_size = save_field(_data, "scrub_pat_size", "");
        if (is_real(_pat_size)) scrub_pat_size = _pat_size;

        var _pat_phase = save_field(_data, "scrub_pat_phase", "");
        if (is_real(_pat_phase)) scrub_pat_phase = _pat_phase;

        var _crocs = save_field(_data, "crocs_color", "");
        if (is_real(_crocs)) crocs_color = _crocs;

        var _pants_style = save_field(_data, "pants_style", "");
        if (is_real(_pants_style)) pants_style = _pants_style;

        var _pants_color = save_field(_data, "pants_color", "");
        if (is_real(_pants_color)) pants_color = _pants_color;
    }

    // ═══════════════════════════════════════════════════════════
    // ПЕРЕПЕЧАТКА ПОРТРЕТА — ОБЯЗАТЕЛЬНО ПОСЛЕ ВОССТАНОВЛЕНИЯ
    //
    // instance_create_layer уже вызвал Create, а тот — portrait_bake()
    // со СЛУЧАЙНОЙ внешностью, ещё до того как мы подставили
    // сохранённые волосы, глаза и цвет формы.
    //
    // Ставить my_baked_portrait = -1 и «ждать, пока перепечётся сам»
    // нельзя: авто-перепечки в проекте нет, а карточка при -1 рисует
    // запасной путь слоями. Печатаем явно и здесь — уже с правильной
    // внешностью. with() нужен, потому что portrait_bake работает
    // через id вызывающего инстанса.
    // ═══════════════════════════════════════════════════════════
    with (_staff) {
        portrait_bake();
    }

    return _staff;
}


// ═══════════════════════════════════════════════════════════════
// 3. СБОРКА ПОЛНОГО СЕЙВА
// ═══════════════════════════════════════════════════════════════

/// Копия структуры-словаря с числовыми значениями (склад, комнаты).
function save_copy_struct(_source) {
    var _result = {};

    if (!is_struct(_source)) return _result;

    var _keys = variable_struct_get_names(_source);

    for (var _i = 0; _i < array_length(_keys); _i++) {
        var _key = _keys[_i];
        var _value = variable_struct_get(_source, _key);

        // В сейв идут только простые значения: числа, строки, флаги.
        // Вложенные структуры складов копируются на один уровень.
        if (is_real(_value) || is_string(_value) || is_bool(_value)) {
            variable_struct_set(_result, _key, _value);
        }
        else if (is_struct(_value)) {
            variable_struct_set(_result, _key, save_copy_struct(_value));
        }
    }

    return _result;
}


/// ═══════════════════════════════════════════════════════════════
/// ПАКЕТ 277 (задачи 6-8): ГЛУБОКОЕ КОПИРОВАНИЕ ДЛЯ СЕЙВА
///
/// save_copy_struct выше копирует только числа, строки, флаги и
/// вложенные структуры — МАССИВЫ он молча теряет. Для складов этого
/// хватало, но картотека клиентов, расписание визитов и карты
/// пациентов состоят из массивов (список питомцев, история визитов,
/// список назначений). Через save_copy_struct они бы обнулились.
///
/// Поэтому отдельная пара функций: save_deep_copy разбирает значение
/// любой вложенности, save_deep_restore собирает обратно. Undefined и
/// ссылки на инстансы отбрасываются: инстансы после перезапуска игры
/// всё равно другие, их восстанавливают отдельные функции.
///
/// Ограничение глубины — защита от закольцованных ссылок: если карта
/// пациента когда-нибудь сошлётся сама на себя, сохранение не уйдёт
/// в бесконечную рекурсию, а просто обрежет ветку.
function save_deep_copy(_value, _depth) {
    if (is_undefined(_depth)) _depth = 0;
    if (_depth > 12) return undefined;

    if (is_real(_value) || is_string(_value) || is_bool(_value)) {
        return _value;
    }

    if (is_array(_value)) {
        var _array_result = [];

        for (var _array_index = 0; _array_index < array_length(_value); _array_index++) {
            var _item = save_deep_copy(_value[_array_index], _depth + 1);

            // Пустые места в массиве заменяем нулём, а не выбрасываем:
            // иначе сдвинулись бы индексы и данные разъехались.
            array_push(_array_result, is_undefined(_item) ? 0 : _item);
        }

        return _array_result;
    }

    if (is_struct(_value)) {
        var _struct_result = {};
        var _keys = variable_struct_get_names(_value);

        for (var _key_index = 0; _key_index < array_length(_keys); _key_index++) {
            var _key = _keys[_key_index];
            var _copied = save_deep_copy(
                variable_struct_get(_value, _key),
                _depth + 1
            );

            if (!is_undefined(_copied)) {
                variable_struct_set(_struct_result, _key, _copied);
            }
        }

        return _struct_result;
    }

    // Метод, инстанс, undefined — в сейв не идёт.
    return undefined;
}


/// Восстановление: json_parse уже отдаёт готовые массивы и структуры,
/// поэтому достаточно проверить тип и вернуть значение по умолчанию.
function save_deep_value(_data, _key, _default) {
    if (!is_struct(_data)) return _default;
    if (!variable_struct_exists(_data, _key)) return _default;

    var _value = variable_struct_get(_data, _key);

    if (is_undefined(_value)) return _default;

    return _value;
}


/// ═══════════════════════════════════════════════════════════════
/// ПАКЕТ 277 (задача 7): СТАЦИОНАР
///
/// Койки — это инстансы obj_inpatient_controller, у каждого свой
/// exam_slot_id (101-108). Пациент в койке — инстанс животного,
/// владелец в это время из клиники удалён и живёт в виде снимка
/// (ward.owner_snapshot) — игра уже умеет разворачивать его обратно
/// в inpatient_spawn_returning_owner.
///
/// Именно на этом и строится сохранение: снимок владельца пишем как
/// есть, а пациента сохраняем набором полей и его картой лечения.
/// Ссылки на инстансы (ward_doctor, escort_doctor, player_actor) НЕ
/// сохраняем — после перезапуска это другие объекты. Персонал при
/// загрузке просто получит палату заново через обычный цикл работы.
///
/// Ключ — exam_slot_id, а не индекс инстанса: порядок создания
/// контроллеров в комнате не гарантирован, по индексу пациенты
/// разъехались бы по чужим койкам (та же ловушка, что со шкафами
/// в пакете 275).
function save_build_wards() {
    var _wards = [];

    for (var _ward_index = 0; _ward_index < instance_number(obj_inpatient_controller); _ward_index++) {
        var _ward = instance_find(obj_inpatient_controller, _ward_index);

        if (!instance_exists(_ward)) continue;

        // ПАКЕТ №309: объект мог быть создан, но его Create ещё не
        // отработал — тогда ни phase, ни patient не существует, и
        // прямое чтение роняет игру. Такое случается, когда
        // сохранение вызывается в момент смены комнаты: GameMaker
        // создаёт объекты по очереди, а CleanUp приходит ко всем
        // сразу.
        //
        // Койка без phase заведомо пустая — пропускаем её молча.
        if (!variable_instance_exists(_ward, "phase")) continue;
        if (!variable_instance_exists(_ward, "patient")) continue;

        // Пустые койки не пишем: при загрузке они и так пустые.
        if (_ward.phase == "empty") continue;
        if (!instance_exists(_ward.patient)) continue;

        var _patient = _ward.patient;

        var _entry = {
            slot_id : save_inst_field(_ward, "exam_slot_id", 0),
            phase : string(save_inst_field(_ward, "phase", "empty")),

            prescriptions_assigned : save_inst_field(_ward, "prescriptions_assigned", false),
            treatment_actions : save_deep_copy(
                save_inst_field(_ward, "treatment_actions", []), 0
            ),
            cycle_action_index : save_inst_field(_ward, "cycle_action_index", 0),
            cycle_active : save_inst_field(_ward, "cycle_active", false),
            next_treatment_minute : save_inst_field(_ward, "next_treatment_minute", -1),

            missing_item_id : string(save_inst_field(_ward, "missing_item_id", "")),
            missing_item_name : string(save_inst_field(_ward, "missing_item_name", "")),

            owner_snapshot : save_deep_copy(
                save_inst_field(_ward, "owner_snapshot", {}), 0
            ),

            // ── пациент ──
            pet_object : object_get_name(_patient.object_index),
            pet_name : string(save_inst_field(_patient, "char_name", "Питомец")),
            pet_species : string(save_inst_field(_patient, "species_id", "unknown")),
            pet_age_days : save_inst_field(_patient, "pet_age_days", 0),
            pet_life_stage : save_inst_field(_patient, "life_stage", 0),

            // Масштаб пациента сохраняем ОТДЕЛЬНО и обязательно.
            // Размер животного пересчитывается в par_animals -> Step,
            // но только в ветке "если владелец существует". У пациента
            // стационара владельца намеренно нет, поэтому пересчитать
            // размер после загрузки будет некому: собака осталась бы
            // в масштабе 1 и выглядела огромной.
            pet_scale_x : save_inst_field(_patient, "image_xscale", 0.6),
            pet_scale_y : save_inst_field(_patient, "image_yscale", 0.6),
            // У животного поле называется inpatient_pet_record_id
            // (проверено в par_animals -> Create), pet_record_id живёт
            // на владельце. Пишем то, что реально есть.
            pet_record_id : string(save_inst_field(_patient, "inpatient_pet_record_id", "")),
            pet_case_id : string(save_inst_field(_patient, "current_case_id", "")),
            pet_case : save_deep_copy(
                save_inst_field(_patient, "current_case", undefined), 0
            )
        };

        array_push(_wards, _entry);
    }

    return _wards;
}


/// Восстановление коек. Вызывается после загрузки картотеки: карта
/// пациента может ссылаться на записи из owner_db / pet_db.
function save_wards_restore(_wards) {
    if (!is_array(_wards)) return false;

    for (var _entry_index = 0; _entry_index < array_length(_wards); _entry_index++) {
        var _entry = _wards[_entry_index];

        if (!is_struct(_entry)) continue;

        var _slot_id = save_field(_entry, "slot_id", 0);

        if (_slot_id <= 0) continue;

        // Ищем койку с таким же номером.
        var _ward = noone;

        for (var _find_index = 0; _find_index < instance_number(obj_inpatient_controller); _find_index++) {
            var _candidate = instance_find(obj_inpatient_controller, _find_index);

            if (
                instance_exists(_candidate)
                && save_inst_field(_candidate, "exam_slot_id", -1) == _slot_id
            ) {
                _ward = _candidate;
                break;
            }
        }

        if (!instance_exists(_ward)) continue;

        // ── воссоздаём пациента ──
        var _pet_object_name = string(save_field(_entry, "pet_object", "obj_dog_puppy"));
        var _pet_object = asset_get_index(_pet_object_name);

        if (_pet_object == -1) _pet_object = obj_dog_puppy;

        // Кладём сразу на койку, если точка стола известна.
        var _spawn_x = _ward.x;
        var _spawn_y = _ward.y;

        if (instance_exists(_ward.pet_table_point)) {
            _spawn_x = _ward.pet_table_point.x;
            _spawn_y = _ward.pet_table_point.y;
        }

        var _pet = instance_create_layer(
            _spawn_x,
            _spawn_y,
            "Instances",
            _pet_object
        );

        if (!instance_exists(_pet)) continue;

        with (_pet) {
            char_name = string(save_field(_entry, "pet_name", "Питомец"));
            species_id = string(save_field(_entry, "pet_species", "unknown"));
            pet_age_days = save_field(_entry, "pet_age_days", 0);
            life_stage = save_field(_entry, "pet_life_stage", life_stage);

            // ВОЗВРАЩАЕМ РАЗМЕР. Без этой пары строк собака в палате
            // после загрузки становилась огромной: масштаб по умолчанию
            // равен 1, а пересчитать его некому — владельца у пациента
            // стационара нет.
            var _saved_scale_x = save_field(_entry, "pet_scale_x", 0);
            var _saved_scale_y = save_field(_entry, "pet_scale_y", 0);

            if (is_real(_saved_scale_x) && _saved_scale_x > 0) {
                image_xscale = _saved_scale_x;
            }

            if (is_real(_saved_scale_y) && _saved_scale_y > 0) {
                image_yscale = _saved_scale_y;
            }

            inpatient_pet_record_id = string(save_field(_entry, "pet_record_id", ""));
            current_case_id = string(save_field(_entry, "pet_case_id", ""));

            var _case = save_deep_value(_entry, "pet_case", undefined);

            if (is_struct(_case)) current_case = _case;

            // Владельца рядом нет — он лежит в снимке палаты.
            my_owner = noone;
            assigned_doctor = noone;
            assigned_table = _ward.ward_table;

            state = "in_exam";
            path_end();
            is_walking = false;
        }

        // ── восстанавливаем саму койку ──
        with (_ward) {
            patient = _pet;

            phase = string(save_field(_entry, "phase", "waiting_cycle"));

            prescriptions_assigned = save_field(_entry, "prescriptions_assigned", false);

            var _actions = save_deep_value(_entry, "treatment_actions", []);
            treatment_actions = is_array(_actions) ? _actions : [];

            cycle_action_index = save_field(_entry, "cycle_action_index", 0);
            cycle_active = save_field(_entry, "cycle_active", false);
            next_treatment_minute = save_field(_entry, "next_treatment_minute", -1);

            missing_item_id = string(save_field(_entry, "missing_item_id", ""));
            missing_item_name = string(save_field(_entry, "missing_item_name", ""));

            var _snapshot = save_deep_value(_entry, "owner_snapshot", {});
            owner_snapshot = is_struct(_snapshot) ? _snapshot : {};

            // Ссылки на живых людей не восстанавливаем: те инстансы
            // остались в прошлом запуске. Персонал разберёт койку
            // обратно обычным ходом работы.
            ward_doctor = noone;
            ward_assistant = noone;
            escort_doctor = noone;
            departing_owner = noone;
            returning_owner = noone;
            player_actor = noone;
            player_task = "";

            stock_retry_timer = 0;
            stock_wait_ticks = 0;
            stock_wait_notice_ticks = 0;

            // Фазы, завязанные на конкретного человека, продолжить
            // нельзя — он не пережил перезапуск. Возвращаем койку в
            // спокойное состояние, откуда лечение пойдёт своим чередом.
            if (
                phase == "admitting"
                || phase == "escort"
                || phase == "owner_returning"
                || phase == "player_going_assign"
                || phase == "player_assigning"
                || phase == "player_treating"
            ) {
                phase = "waiting_doctor";
            }
        }
    }

    return true;
}


/// ═══════════════════════════════════════════════════════════════
/// ПАКЕТ 277 (задача 8): ПОСЕТИТЕЛИ В КЛИНИКЕ
///
/// Самая осторожная часть пакета. Владелец связан с питомцем, столом,
/// врачом, местом в очереди и точкой ожидания — восстановить всю эту
/// паутину «как было» нельзя: половина ссылок указывает на инстансы
/// прошлого запуска.
///
/// Поэтому подход намеренно консервативный: сохраняем САМИХ людей и
/// их данные (кто пришёл, с каким питомцем, с какой болезнью, сколько
/// должен), но НЕ сохраняем незавершённое взаимодействие с персоналом.
/// После загрузки посетители встают в очередь или в зону ожидания, и
/// клиника разбирает их обычным ходом работы.
///
/// Так пациент не исчезает и не теряет диагноз — а именно это и
/// раздражало. Чуть менее точно, зато без риска получить владельца,
/// намертво привязанного к несуществующему врачу.
///
/// Кого НЕ сохраняем:
///   - тех, кто уже уходит (leaving_clinic) — им и так пора;
///   - тех, кто лежит в стационаре: их пишет save_build_wards.
function save_build_visitors() {
    var _visitors = [];

    for (var _owner_index = 0; _owner_index < instance_number(obj_owner); _owner_index++) {
        var _owner = instance_find(obj_owner, _owner_index);

        if (!instance_exists(_owner)) continue;

        var _state = string(save_inst_field(_owner, "state", ""));

        if (_state == "leaving_clinic") continue;

        // Владелец пациента стационара временно удалён из клиники, но
        // подстрахуемся: если такой всё же существует, пропускаем.
        if (save_inst_field(_owner, "in_inpatient_hold", false)) continue;

        var _pet = save_inst_field(_owner, "my_pet", noone);
        var _has_pet = instance_exists(_pet);

        var _entry = {
            // ── кто пришёл ──
            owner_record_id : string(save_inst_field(_owner, "owner_record_id", "")),
            pet_record_id : string(save_inst_field(_owner, "pet_record_id", "")),
            scheduled_visit_id : string(save_inst_field(_owner, "scheduled_visit_id", "")),

            char_name : string(save_inst_field(_owner, "char_name", "Владелец")),
            age : save_inst_field(_owner, "age", 30),
            is_female : save_inst_field(_owner, "is_female", false),
            character_trait : save_inst_field(_owner, "character_trait", 0),
            owner_trust : save_inst_field(_owner, "owner_trust", 60),
            loyalty_level : save_inst_field(_owner, "loyalty_level", 5),
            patience_level : save_inst_field(_owner, "patience_level", 1),
            owner_feature_id : string(save_inst_field(_owner, "owner_feature_id", "none")),
            owner_feature_name_ru : string(save_inst_field(_owner, "owner_feature_name_ru", "")),

            // ── внешность (иначе клиент сменил бы лицо) ──
            hair_color : save_inst_field(_owner, "hair_color", c_white),
            my_hair : save_sprite_to_name(save_inst_field(_owner, "my_hair", -1)),
            my_hair_back : save_sprite_to_name(save_inst_field(_owner, "my_hair_back", -1)),
            my_eyes : save_sprite_to_name(save_inst_field(_owner, "my_eyes", -1)),
            my_nose : save_sprite_to_name(save_inst_field(_owner, "my_nose", -1)),
            my_mouth : save_sprite_to_name(save_inst_field(_owner, "my_mouth", -1)),
            portrait_x : save_inst_field(_owner, "portrait_x", 150),
            portrait_y : save_inst_field(_owner, "portrait_y", 50),
            portrait_zoom : save_inst_field(_owner, "portrait_zoom", 1),

            // ── зачем пришёл ──
            visit_type_id : string(save_inst_field(_owner, "visit_type_id", "doctor_visit")),
            visit_type_name_ru : string(save_inst_field(_owner, "visit_type_name_ru", "Приём врача")),
            visit_reason_ru : string(save_inst_field(_owner, "visit_reason_ru", "")),
            service_queue_type : string(save_inst_field(_owner, "service_queue_type", "doctor")),
            queue_purpose : string(save_inst_field(_owner, "queue_purpose", "registration")),

            // ── деньги ──
            visit_price : save_inst_field(_owner, "visit_price", 0),
            pending_payment_total : save_inst_field(_owner, "pending_payment_total", 0),

            // ── прошёл ли регистрацию ──
            // В obj_owner поле называется registered (без is_).
            registered : save_inst_field(_owner, "registered", false),

            // ── питомец ──
            has_pet : _has_pet,
            pet_object : _has_pet ? object_get_name(_pet.object_index) : "",
            pet_name : _has_pet ? string(save_inst_field(_pet, "char_name", "Питомец")) : "",
            pet_species : _has_pet ? string(save_inst_field(_pet, "species_id", "unknown")) : "",
            pet_age_days : _has_pet ? save_inst_field(_pet, "pet_age_days", 0) : 0,
            pet_life_stage : _has_pet ? save_inst_field(_pet, "life_stage", 0) : 0,
            pet_scale_x : _has_pet ? save_inst_field(_pet, "image_xscale", 0.6) : 0.6,
            pet_scale_y : _has_pet ? save_inst_field(_pet, "image_yscale", 0.6) : 0.6,
            pet_case_id : _has_pet ? string(save_inst_field(_pet, "current_case_id", "")) : "",
            pet_case : _has_pet
                ? save_deep_copy(save_inst_field(_pet, "current_case", undefined), 0)
                : undefined
        };

        array_push(_visitors, _entry);
    }

    return _visitors;
}


/// Восстановление посетителей.
function save_visitors_restore(_visitors) {
    if (!is_array(_visitors)) return false;

    for (var _entry_index = 0; _entry_index < array_length(_visitors); _entry_index++) {
        var _entry = _visitors[_entry_index];

        if (!is_struct(_entry)) continue;

        // Появляются у входа — это штатная точка, оттуда работает вся
        // обычная логика (очередь, регистрация, ожидание).
        var _spawn_x = variable_global_exists("clinic_exit_x") ? global.clinic_exit_x : 100;
        var _spawn_y = variable_global_exists("clinic_exit_y") ? global.clinic_exit_y : 100;

        var _owner = instance_create_layer(_spawn_x, _spawn_y, "Instances", obj_owner);

        if (!instance_exists(_owner)) continue;

        with (_owner) {
            owner_record_id = string(save_field(_entry, "owner_record_id", ""));
            pet_record_id = string(save_field(_entry, "pet_record_id", ""));
            scheduled_visit_id = string(save_field(_entry, "scheduled_visit_id", ""));

            char_name = string(save_field(_entry, "char_name", "Владелец"));
            age = save_field(_entry, "age", 30);
            is_female = save_field(_entry, "is_female", false);
            character_trait = save_field(_entry, "character_trait", 0);
            owner_trust = save_field(_entry, "owner_trust", 60);
            loyalty_level = save_field(_entry, "loyalty_level", 5);
            patience_level = save_field(_entry, "patience_level", 1);
            owner_feature_id = string(save_field(_entry, "owner_feature_id", "none"));
            owner_feature_name_ru = string(save_field(_entry, "owner_feature_name_ru", ""));

            hair_color = save_field(_entry, "hair_color", c_white);
            my_hair = save_sprite_from_name(save_field(_entry, "my_hair", ""));
            my_hair_back = save_sprite_from_name(save_field(_entry, "my_hair_back", ""));
            my_eyes = save_sprite_from_name(save_field(_entry, "my_eyes", ""));
            my_nose = save_sprite_from_name(save_field(_entry, "my_nose", ""));
            my_mouth = save_sprite_from_name(save_field(_entry, "my_mouth", ""));
            portrait_x = save_field(_entry, "portrait_x", 150);
            portrait_y = save_field(_entry, "portrait_y", 50);
            portrait_zoom = save_field(_entry, "portrait_zoom", 1);

            visit_type_id = string(save_field(_entry, "visit_type_id", "doctor_visit"));
            visit_type_name_ru = string(save_field(_entry, "visit_type_name_ru", "Приём врача"));
            visit_reason_ru = string(save_field(_entry, "visit_reason_ru", ""));
            service_queue_type = string(save_field(_entry, "service_queue_type", "doctor"));
            queue_purpose = string(save_field(_entry, "queue_purpose", "registration"));

            visit_price = save_field(_entry, "visit_price", 0);
            pending_payment_total = save_field(_entry, "pending_payment_total", 0);
            registered = save_field(_entry, "registered", false);

            // Незавершённое взаимодействие не восстанавливаем.
            assigned_doctor = noone;
            assigned_table = noone;
            registration_in_progress = false;
            registration_timer = 0;
            registration_timer_max = 0;
            registration_actor_name = "";
        }

        // ── питомец ──
        if (save_field(_entry, "has_pet", false) && instance_exists(_owner.my_pet)) {
            var _pet = _owner.my_pet;

            with (_pet) {
                char_name = string(save_field(_entry, "pet_name", "Питомец"));
                species_id = string(save_field(_entry, "pet_species", "unknown"));
                pet_age_days = save_field(_entry, "pet_age_days", 0);
                life_stage = save_field(_entry, "pet_life_stage", life_stage);

                // Размер питомца посетителя — по той же причине,
                // что и у пациента стационара.
                var _vis_scale_x = save_field(_entry, "pet_scale_x", 0);
                var _vis_scale_y = save_field(_entry, "pet_scale_y", 0);

                if (is_real(_vis_scale_x) && _vis_scale_x > 0) {
                    image_xscale = _vis_scale_x;
                }

                if (is_real(_vis_scale_y) && _vis_scale_y > 0) {
                    image_yscale = _vis_scale_y;
                }
                current_case_id = string(save_field(_entry, "pet_case_id", ""));

                var _case = save_deep_value(_entry, "pet_case", undefined);

                if (is_struct(_case)) current_case = _case;

                assigned_doctor = noone;
                assigned_table = noone;
                state = "follow_owner";
                follow_offset_x = 30;
                follow_offset_y = 20;
            }
        }

        // ═══════════════════════════════════════════════════════
        // КУДА ВЛАДЕЛЕЦ ПОЙДЁТ ДАЛЬШЕ
        //
        // Create уже завёл alarm[0], который через полсекунды поставит
        // клиента в очередь на РЕГИСТРАЦИЮ. Для новичка это верно, но
        // для двух случаев — нет, и их нужно поправить отдельно:
        //
        //   1) клиент должен денег — его надо ставить в очередь на
        //      ОПЛАТУ, иначе долг потеряется, а он пойдёт по второму
        //      кругу оформляться;
        //   2) клиент уже зарегистрирован и ждал приёма — ему тоже
        //      незачем оформляться заново.
        //
        // Для первого случая есть готовая функция: она сама уберёт
        // клиента из обычной очереди и поставит в начало на оплату.
        // ═══════════════════════════════════════════════════════

        var _owes_money = (save_field(_entry, "pending_payment_total", 0) > 0);
        var _was_registered = save_field(_entry, "registered", false);

        if (_owes_money) {
            _owner.alarm[0] = -1;
            reception_enqueue_priority_payment(_owner);
        }
        else if (_was_registered) {
            // Уже оформлен: сажаем в зону ожидания той же функцией,
            // которой пользуется администратор в конце регистрации.
            //
            // Свой упрощённый вариант я сначала написал и убрал: он
            // ставил состояние "going_to_waiting", но не резервировал
            // кресло и не строил маршрут. Клиент встал бы столбом, а
            // двое могли занять одно место. Готовая функция делает и
            // то, и другое.
            _owner.alarm[0] = -1;

            if (!reception_finish_owner_registration(_owner, false)) {
                // Свободных кресел нет — пусть идёт в общую очередь,
                // как обычный посетитель. Это штатная перегрузка
                // клиники, а не ошибка.
                _owner.alarm[0] = 30;
            }
        }
    }

    return true;
}


function save_build_data() {
    var _data = {
        version : SAVE_FORMAT_VERSION,

        // ── деньги и репутация ──
        clinic_money : save_global("clinic_money", 100000),
        clinic_points : save_global("clinic_points", 300),
        clinic_reputation : save_global("clinic_reputation", 35),
        clinic_cleanliness : save_global("clinic_cleanliness", 100),
        clinic_name : string(save_global("clinic_name", "VetSim Clinic")),

        // ── время ──
        game_day : save_global("game_day", 1),
        game_hour : save_global("game_hour", 8),
        game_minute : save_global("game_minute", 0),
        week_day_index : save_global("week_day_index", 0),
        calendar_day : save_global("calendar_day", 1),
        calendar_month : save_global("calendar_month", 1),
        calendar_year : save_global("calendar_year", 1),

        // ── что построено ──
        clinic_rooms_open : save_copy_struct(
            save_global("clinic_rooms_open", {})
        ),
        clinic_upgrades : save_copy_struct(
            save_global("clinic_upgrades", {})
        ),

        // ── склад ──
        inventory_main : save_copy_struct(
            save_global("inventory_main", {})
        ),

        // ── ПАКЕТ 301: СЕТЬ КЛИНИК ──
        //
        // clinics хранит, какие клиники куплены, clinic_state — карманы
        // с персоналом и складом каждой, active_clinic — где игрок.
        //
        // Раньше global.clinics не сохранялся вовсе: после загрузки
        // купленные клиники снова становились чужими.
        //
        // save_deep_copy, а не save_copy_struct: внутри clinics массив
        // структур, а внутри clinic_state — массивы снимков персонала.
        // Поверхностная копия потеряла бы вложенные массивы.
        clinics : save_deep_copy(
            save_global("clinics", [])
        ),
        clinic_state : save_deep_copy(
            save_global("clinic_state", {})
        ),
        active_clinic : save_global("active_clinic", 1),

        // ── ПАКЕТ 287: история финансов по дням ──
        //
        // Массив плоских структур, до 30 штук. Вложенных
        // массивов внутри нет, поэтому save_copy_struct здесь не
        // нужен — finance_history_to_save сама собирает копию.
        //
        // SAVE_FORMAT_VERSION НЕ поднимается: старые сохранения
        // без этого ключа грузятся как раньше и просто дают
        // пустую историю.
        finance_history : finance_history_to_save(),

        // ── ПАКЕТ 275: шкафы в кабинетах ──
        //
        // Раньше сохранялся только главный склад. Шкафы кабинетов —
        // это storage_inventory отдельных инстансов obj_storage_cabinet,
        // и они пропадали при загрузке: шкаф заново набивался стартовым
        // запасом по 3 единицы, а всё, что туда наносили ассистенты,
        // исчезало.
        //
        // Ключ — exam_slot_id (номер кабинета), а НЕ индекс инстанса:
        // порядок создания инстансов в комнате не гарантирован, и по
        // индексу содержимое разъехалось бы по чужим кабинетам.
        cabinets : [],

        // ── персонал ──
        // ═══════════════════════════════════════════════════════
        // ПАКЕТ 277 (задача 6): КАРТОТЕКА И РАСПИСАНИЕ
        //
        // Ничего этого в сейве не было. Терялась вся история клиентов
        // и, что важнее, назначенные повторные визиты: записали
        // пациента на завтра, сохранились — и он не пришёл.
        //
        // Копируем глубоко: внутри массивы (список питомцев у
        // владельца, история визитов, список назначений).
        // ═══════════════════════════════════════════════════════
        owner_db : save_deep_copy(save_global("owner_db", {}), 0),
        pet_db : save_deep_copy(save_global("pet_db", {}), 0),
        visit_db : save_deep_copy(save_global("visit_db", {}), 0),

        owner_list : save_deep_copy(save_global("owner_list", []), 0),
        pet_list : save_deep_copy(save_global("pet_list", []), 0),
        visit_list : save_deep_copy(save_global("visit_list", []), 0),

        // Счётчики идентификаторов. Без них после загрузки новые записи
        // получили бы уже занятые номера и перезаписали старые.
        owner_uid : save_global("owner_uid", 0),
        pet_uid : save_global("pet_uid", 0),
        visit_uid : save_global("visit_uid", 0),

        scheduled_visits : save_deep_copy(save_global("scheduled_visits", []), 0),
        scheduled_visit_uid : save_global("scheduled_visit_uid", 0),

        daily_random_visits : save_deep_copy(save_global("daily_random_visits", []), 0),
        daily_random_visit_uid : save_global("daily_random_visit_uid", 0),

        // Статистика дня — мелочь, но обнулялась при загрузке.
        daily_stats : save_deep_copy(save_global("daily_stats", {}), 0),

        // ── ПАКЕТ 277 (задачи 7-8): стационар и посетители ──
        wards : save_build_wards(),
        visitors : save_build_visitors(),

        staff : []
    };

    // Собираем шкафы кабинетов.
    for (var _c = 0; _c < instance_number(obj_storage_cabinet); _c++) {
        var _cab = instance_find(obj_storage_cabinet, _c);

        if (!instance_exists(_cab)) continue;
        if (!variable_instance_exists(_cab, "exam_slot_id")) continue;
        if (_cab.exam_slot_id <= 0) continue;
        if (!variable_instance_exists(_cab, "storage_inventory")) continue;
        if (!is_struct(_cab.storage_inventory)) continue;

        array_push(_data.cabinets, {
            slot : _cab.exam_slot_id,
            inventory : save_copy_struct(_cab.storage_inventory)
        });
    }

    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ №305: ПЕРСОНАЛ СОХРАНЯЕТСЯ ПО КЛИНИКАМ
    //
    // Список _data.staff ниже — общий на всю игру: в него попадают
    // все, кто СЕЙЧАС в комнате. Пока клиника была одна, это работало.
    //
    // С сетью клиник получилось так: автосохранение застаёт игрока,
    // например, в тестовой клинике №4, кладёт в staff девять её
    // сотрудников — и при следующей загрузке они появлялись в любой
    // клинике, куда бы игрок ни приехал. Карманы клиник (clinic_state)
    // сохранялись отдельно и правильно, но общий staff их перекрывал:
    // загрузка сначала сносит весь персонал, а потом разворачивает
    // именно этот список.
    //
    // Решение: перед сборкой сохранения сворачиваем текущую клинику в
    // её карман. Тогда clinic_state содержит актуальный состав ВСЕХ
    // клиник, включая ту, в которой игрок стоит прямо сейчас.
    //
    // Сам _data.staff оставлен и продолжает писаться. Он нужен для
    // двух вещей: совместимости со старыми сохранениями (формат не
    // поднимаем) и как состав текущей комнаты при загрузке.
    // ═══════════════════════════════════════════════════════════════

    if (script_exists(asset_get_index("clinic_network_store_current"))) {
        clinic_network_store_current();
    }

    // Весь персонал клиники, кроме игрока и кандидатов.
    for (var _i = 0; _i < instance_number(par_staff); _i++) {
        var _staff = instance_find(par_staff, _i);

        if (!instance_exists(_staff)) continue;
        if (_staff.object_index == obj_player) continue;
        if (_staff.object_index == obj_staff_candidate) continue;

        var _snapshot = save_staff_snapshot(_staff);

        if (is_struct(_snapshot)) {
            array_push(_data.staff, _snapshot);
        }
    }

    // Игрок сохраняется отдельно: его объект уже стоит в комнате,
    // пересоздавать не нужно — только вернуть навыки.
    if (instance_exists(obj_player)) {
        var _player = instance_find(obj_player, 0);

        _data.player = {
            x : real(_player.x),
            y : real(_player.y),

            // Массивы как есть — длину не навязываем.
            skills : save_copy_array_asis(_player, "skills"),
            skill_xp : save_copy_array_asis(_player, "skill_xp"),
            skill_xp_needed : save_copy_array_asis(_player, "skill_xp_needed"),

            // Вторичные навыки игрока: админские (2) и
            // ассистентские (3) — player_extra_skills_init.
            player_admin_skill_levels :
                save_copy_array_asis(_player, "player_admin_skill_levels"),
            player_admin_skill_xp :
                save_copy_array_asis(_player, "player_admin_skill_xp"),
            player_assistant_skill_levels :
                save_copy_array_asis(_player, "player_assistant_skill_levels"),
            player_assistant_skill_xp :
                save_copy_array_asis(_player, "player_assistant_skill_xp"),

            xp_log : save_copy_struct_array(_player, "xp_log"),

            walk_skill_level : real(save_inst_field(_player, "walk_skill_level", 1)),
            walk_skill_xp : real(save_inst_field(_player, "walk_skill_xp", 0)),
            walk_skill_xp_needed : real(save_inst_field(_player, "walk_skill_xp_needed", 30)),
            stamina_level : real(save_inst_field(_player, "stamina_level", 1)),
            stamina_xp : real(save_inst_field(_player, "stamina_xp", 0)),
            stamina_xp_needed : real(save_inst_field(_player, "stamina_xp_needed", 30)),
            stat_energy : real(save_inst_field(_player, "stat_energy", 100)),
            energy_max : real(save_inst_field(_player, "energy_max", 100))
        };
    }

    return _data;
}


// ═══════════════════════════════════════════════════════════════
// 4. ЗАПИСЬ И ЧТЕНИЕ ФАЙЛА
// ═══════════════════════════════════════════════════════════════

function vetsim_save() {
    var _data = save_build_data();
    var _json = json_stringify(_data);

    // Пишем через буфер, а НЕ через file_text_write_string.
    //
    // Причина: file_text_* работает построчно и на длинных строках
    // ведёт себя непредсказуемо (исторический лимит на длину строки).
    // JSON со всем персоналом легко перевалит за несколько килобайт,
    // поэтому буфер — единственный надёжный способ.
    var _size = string_byte_length(_json) + 1;
    var _buffer = buffer_create(_size, buffer_fixed, 1);

    buffer_write(_buffer, buffer_string, _json);
    buffer_save(_buffer, SAVE_FILE_NAME);
    buffer_delete(_buffer);

    show_debug_message(
        "[SAVE] Сохранено: день " + string(save_field(_data, "game_day", 1))
        + ", $" + string(save_field(_data, "clinic_money", 0))
        + ", сотрудников " + string(array_length(_data.staff))
    );

    return true;
}


function vetsim_save_exists() {
    return file_exists(SAVE_FILE_NAME);
}


function vetsim_save_delete() {
    if (!file_exists(SAVE_FILE_NAME)) return false;

    file_delete(SAVE_FILE_NAME);
    show_debug_message("[SAVE] Сохранение удалено.");

    return true;
}


/// Читает файл и возвращает структуру или undefined.
function vetsim_save_read() {
    if (!file_exists(SAVE_FILE_NAME)) return undefined;

    var _buffer = buffer_load(SAVE_FILE_NAME);

    if (_buffer < 0) return undefined;

    var _json = "";

    // Чтение тоже через буфер — парный к записи способ.
    try {
        _json = buffer_read(_buffer, buffer_string);
    }
    catch (_read_error) {
        _json = "";
    }

    buffer_delete(_buffer);

    if (_json == "") return undefined;

    // Битый файл не должен ронять игру.
    try {
        var _data = json_parse(_json);

        if (!is_struct(_data)) return undefined;

        var _version = save_field(_data, "version", 0);

        if (_version != SAVE_FORMAT_VERSION) {
            show_debug_message(
                "[SAVE] Версия сейва " + string(_version)
                + " не совпадает с текущей " + string(SAVE_FORMAT_VERSION)
                + " — сохранение проигнорировано."
            );
            return undefined;
        }

        return _data;
    }
    catch (_error) {
        show_debug_message("[SAVE] Файл сохранения повреждён.");
        return undefined;
    }
}


// ═══════════════════════════════════════════════════════════════
// 5. ЗАГРУЗКА
//
// Вызывается ОДИН раз из obj_Render → Alarm 1 (через шаг после Create),
// когда комната полностью собрана: столы, койки и точки ожидания
// уже существуют.
// ═══════════════════════════════════════════════════════════════

function vetsim_load() {
    var _data = vetsim_save_read();

    if (!is_struct(_data)) return false;

    // ── деньги и репутация ──
    global.clinic_money = save_field(_data, "clinic_money", save_global("clinic_money", 100000));
    global.clinic_points = save_field(_data, "clinic_points", save_global("clinic_points", 300));
    global.clinic_reputation = save_field(
        _data, "clinic_reputation", save_global("clinic_reputation", 35)
    );

    if (variable_global_exists("clinic_cleanliness")) {
        global.clinic_cleanliness = save_field(
            _data, "clinic_cleanliness", save_global("clinic_cleanliness", 100)
        );
    }

    global.clinic_name = string(save_field(_data, "clinic_name", save_global("clinic_name", "VetSim Clinic")));

    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ 277 (задача 6): КАРТОТЕКА И РАСПИСАНИЕ
    //
    // Восстанавливаем только то, что реально лежит в файле. Если ключа
    // нет (сейв сделан до этого пакета), оставляем то, что уже создал
    // db_clients_init — старые сохранения продолжают грузиться.
    // ═══════════════════════════════════════════════════════════════

    if (is_struct(save_deep_value(_data, "owner_db", undefined))) {
        global.owner_db = save_deep_value(_data, "owner_db", {});
    }

    if (is_struct(save_deep_value(_data, "pet_db", undefined))) {
        global.pet_db = save_deep_value(_data, "pet_db", {});
    }

    if (is_struct(save_deep_value(_data, "visit_db", undefined))) {
        global.visit_db = save_deep_value(_data, "visit_db", {});
    }

    if (is_array(save_deep_value(_data, "owner_list", undefined))) {
        global.owner_list = save_deep_value(_data, "owner_list", []);
    }

    if (is_array(save_deep_value(_data, "pet_list", undefined))) {
        global.pet_list = save_deep_value(_data, "pet_list", []);
    }

    if (is_array(save_deep_value(_data, "visit_list", undefined))) {
        global.visit_list = save_deep_value(_data, "visit_list", []);
    }

    global.owner_uid = save_field(_data, "owner_uid", save_global("owner_uid", 0));
    global.pet_uid = save_field(_data, "pet_uid", save_global("pet_uid", 0));
    global.visit_uid = save_field(_data, "visit_uid", save_global("visit_uid", 0));

    if (is_array(save_deep_value(_data, "scheduled_visits", undefined))) {
        global.scheduled_visits = save_deep_value(_data, "scheduled_visits", []);
    }

    global.scheduled_visit_uid = save_field(
        _data, "scheduled_visit_uid", save_global("scheduled_visit_uid", 0)
    );

    if (is_array(save_deep_value(_data, "daily_random_visits", undefined))) {
        global.daily_random_visits = save_deep_value(_data, "daily_random_visits", []);
    }

    global.daily_random_visit_uid = save_field(
        _data, "daily_random_visit_uid", save_global("daily_random_visit_uid", 0)
    );

    if (is_struct(save_deep_value(_data, "daily_stats", undefined))) {
        global.daily_stats = save_deep_value(_data, "daily_stats", {});
    }

    // ── время ──
    global.game_day = save_field(_data, "game_day", save_global("game_day", 1));
    global.game_hour = save_field(_data, "game_hour", save_global("game_hour", 8));
    global.game_minute = save_field(_data, "game_minute", save_global("game_minute", 0));
    global.week_day_index = save_field(_data, "week_day_index", save_global("week_day_index", 0));
    global.calendar_day = save_field(_data, "calendar_day", save_global("calendar_day", 1));
    global.calendar_month = save_field(_data, "calendar_month", save_global("calendar_month", 1));
    global.calendar_year = save_field(_data, "calendar_year", save_global("calendar_year", 1));

    // ── что построено ──
    var _rooms = save_field(_data, "clinic_rooms_open", undefined);

    if (is_struct(_rooms)) {
        global.clinic_rooms_open = save_copy_struct(_rooms);
    }

    var _upgrades = save_field(_data, "clinic_upgrades", undefined);

    if (is_struct(_upgrades)) {
        global.clinic_upgrades = save_copy_struct(_upgrades);
    }

    // ── склад ──
    // ── ПАКЕТ 301: сеть клиник ──
    //
    // Восстанавливаем ДО персонала и склада: clinic_network_restore
    // ниже по цепочке опирается на active_clinic, а карманы клиник
    // должны быть на месте раньше, чем кто-то в них полезет.
    var _clinics = save_field(_data, "clinics", undefined);

    if (is_array(_clinics) && array_length(_clinics) > 0) {
        global.clinics = save_deep_copy(_clinics);
    }

    var _clinic_state = save_field(_data, "clinic_state", undefined);

    if (is_struct(_clinic_state)) {
        global.clinic_state = save_deep_copy(_clinic_state);
    }

    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ №307: ЛЕЧЕНИЕ СТАРЫХ ИСПОРЧЕННЫХ СОХРАНЕНИЙ
    //
    // До пакета 306 игра при запуске в тестовой комнате считала её
    // персонал штатом клиники №1 и складывала девять тестовых
    // сотрудников в её карман. Такие сохранения уже существуют, и
    // одной правкой механики их не вылечить: испорченные данные
    // лежат в файле.
    //
    // Признак порчи простой и надёжный: у клиники, которую игрок
    // никогда не покупал (owned = false), в кармане не может быть
    // персонала. И у клиники №1 в самом начале игры штата быть не
    // должно — игрок нанимает всех сам.
    //
    // Поэтому: карманы НЕ купленных клиник очищаются. Это безопасно —
    // в купленную клинику персонал попадает только после визита туда.
    // ═══════════════════════════════════════════════════════════════

    if (
        variable_global_exists("clinic_state")
        && is_struct(global.clinic_state)
        && variable_global_exists("clinics")
        && is_array(global.clinics)
    ) {
        for (var _c = 0; _c < array_length(global.clinics); _c++) {
            var _clinic_ref = global.clinics[_c];

            if (!is_struct(_clinic_ref)) continue;
            if (_clinic_ref.owned) continue;

            var _dirty_key = "clinic_" + string(_clinic_ref.id);

            if (!variable_struct_exists(global.clinic_state, _dirty_key)) {
                continue;
            }

            var _dirty = variable_struct_get(
                global.clinic_state,
                _dirty_key
            );

            if (
                is_struct(_dirty)
                && variable_struct_exists(_dirty, "staff")
                && is_array(_dirty.staff)
                && array_length(_dirty.staff) > 0
            ) {
                show_debug_message(
                    "[SAVE] Клиника " + string(_clinic_ref.id)
                    + " не куплена, но в кармане "
                    + string(array_length(_dirty.staff))
                    + " сотрудников — очищено."
                );

                _dirty.staff = [];
                _dirty.visited = false;
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ №307: КОМНАТА ГЛАВНЕЕ СОХРАНЁННОГО НОМЕРА
    //
    // Здесь стояло безусловное присваивание из сейва, и оно ломало всё
    // то, что пакет 306 чинил парой шагов раньше.
    //
    // Порядок при запуске такой: Room Start вызывает clinic_sync_active
    // и ставит верный номер по открытой комнате, а потом Alarm 1
    // загружает сохранение и перезатирает его старым значением.
    // Игрок стоит в комнате клиники №4, а игра считает, что он в №1 —
    // и достаёт персонал не из того кармана.
    //
    // Загрузка комнату не меняет (room_goto в ней нет — проверено),
    // поэтому источником правды должна быть именно комната. Значение
    // из сейва берётся только если комната ничьей клинике не
    // принадлежит.
    // ═══════════════════════════════════════════════════════════════

    var _room_clinic = 0;

    if (script_exists(asset_get_index("clinic_room_owner"))) {
        _room_clinic = clinic_room_owner();
    }

    if (_room_clinic > 0) {
        global.active_clinic = _room_clinic;
    }
    else {
        global.active_clinic = save_field(_data, "active_clinic", 1);
    }

    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ №317: КАБИНЕТЫ ТОЙ КЛИНИКИ, ГДЕ ИГРОК
    //
    // Выше clinic_rooms_open и clinic_upgrades уже восстановлены из
    // сохранения — но это общая запись, состояние клиники, в которой
    // игра сохранялась. А игрок может стоять в другой.
    //
    // Теперь у каждой клиники свои кабинеты, они лежат в её кармане
    // (clinic_state). Карман восстановлен парой строк выше, номер
    // клиники определён только что — самое время подменить общие
    // значения на местные.
    //
    // Порядок здесь важен и проверен: rooms грузятся на строке ~1462,
    // clinic_state на ~1486, active_clinic — тут. Раньше этого места
    // подменять было нечем.
    // ═══════════════════════════════════════════════════════════════

    if (
        variable_global_exists("clinic_state")
        && is_struct(global.clinic_state)
    ) {
        var _rooms_key = "clinic_" + string(global.active_clinic);

        if (variable_struct_exists(global.clinic_state, _rooms_key)) {
            var _here_pocket = variable_struct_get(
                global.clinic_state,
                _rooms_key
            );

            if (
                is_struct(_here_pocket)
                && variable_struct_exists(_here_pocket, "rooms")
                && is_struct(_here_pocket.rooms)
            ) {
                global.clinic_rooms_open = save_copy_struct(
                    _here_pocket.rooms
                );

                show_debug_message(
                    "[SAVE] Кабинеты взяты из кармана клиники "
                    + string(global.active_clinic)
                );
            }

            if (
                is_struct(_here_pocket)
                && variable_struct_exists(_here_pocket, "upgrades")
                && is_struct(_here_pocket.upgrades)
            ) {
                global.clinic_upgrades = save_copy_struct(
                    _here_pocket.upgrades
                );
            }
        }
    }

    var _inventory = save_field(_data, "inventory_main", undefined);

    if (is_struct(_inventory)) {
        global.inventory_main = save_copy_struct(_inventory);
    }

    // ── ПАКЕТ 287: история финансов ──
    //
    // Массив читается через save_restore_array_asis: элементы —
    // структуры с числами, глубокое восстановление не нужно.
    // Сама finance_history_from_save фильтрует мусор и обрезает
    // длину до 30 дней, так что чужой формат её не сломает.
    var _fin_history = save_field(_data, "finance_history", undefined);

    if (is_array(_fin_history)) {
        finance_history_from_save(_fin_history);
    }

    // ── ПАКЕТ 275: шкафы в кабинетах ──
    //
    // Раскладываем содержимое по exam_slot_id. Шкаф, которого нет в
    // сейве (например, сейв сделан до этого пакета), остаётся со своим
    // стартовым запасом — старые сохранения продолжают грузиться.
    var _cabinets = save_field(_data, "cabinets", undefined);

    if (is_array(_cabinets)) {
        for (var _ci = 0; _ci < array_length(_cabinets); _ci++) {
            var _rec = _cabinets[_ci];

            if (!is_struct(_rec)) continue;

            var _slot = save_field(_rec, "slot", 0);
            var _inv = save_field(_rec, "inventory", undefined);

            if (_slot <= 0 || !is_struct(_inv)) continue;

            for (var _cj = 0; _cj < instance_number(obj_storage_cabinet); _cj++) {
                var _cab = instance_find(obj_storage_cabinet, _cj);

                if (!instance_exists(_cab)) continue;
                if (!variable_instance_exists(_cab, "exam_slot_id")) continue;
                if (_cab.exam_slot_id != _slot) continue;

                _cab.storage_inventory = save_copy_struct(_inv);

                // Метка для obj_storage_cabinet -> Step: содержимое
                // пришло из сейва, стартовый запас по 3 единицы
                // досыпать НЕ нужно.
                //
                // Важно: сам _cabinet_inited здесь НЕ трогаем. Внутри
                // того же if шкаф задаёт interact_x/interact_y — точку,
                // к которой подходит ассистент. Подняв флаг заранее, мы
                // оставили бы шкаф без точки подхода, и пополнение
                // сломалось бы.
                _cab._cabinet_from_save = true;
                break;
            }
        }
    }

    // ── персонал ──
    //
    // Сначала убираем тех, кто расставлен в комнате вручную: иначе к
    // загруженным добавятся стартовые и штат удвоится.
    var _to_remove = [];

    for (var _i = 0; _i < instance_number(par_staff); _i++) {
        var _existing = instance_find(par_staff, _i);

        if (!instance_exists(_existing)) continue;
        if (_existing.object_index == obj_player) continue;
        if (_existing.object_index == obj_staff_candidate) continue;

        array_push(_to_remove, _existing);
    }

    for (var _r = 0; _r < array_length(_to_remove); _r++) {
        if (instance_exists(_to_remove[_r])) {
            instance_destroy(_to_remove[_r]);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ №305: БЕРЁМ ПЕРСОНАЛ ИЗ КАРМАНА ТЕКУЩЕЙ КЛИНИКИ
    //
    // Раньше здесь безусловно разворачивался общий список staff —
    // и в клинику приходили сотрудники той клиники, где игрока застало
    // автосохранение.
    //
    // Теперь сначала смотрим в карман клиники, в которой игрок сейчас
    // (active_clinic восстановлен выше по коду). Если карман есть и
    // непустой — берём персонал оттуда.
    //
    // Общий список остаётся запасным путём: для старых сохранений,
    // где карманов ещё не было, и для случая, когда карман пуст.
    // ═══════════════════════════════════════════════════════════════

    var _staff_list = save_field(_data, "staff", []);
    var _staff_from_pocket = false;

    if (
        variable_global_exists("clinic_state")
        && is_struct(global.clinic_state)
    ) {
        var _active_id = variable_global_exists("active_clinic")
            ? global.active_clinic
            : 1;

        var _pocket_key = "clinic_" + string(_active_id);

        if (variable_struct_exists(global.clinic_state, _pocket_key)) {
            var _pocket = variable_struct_get(
                global.clinic_state,
                _pocket_key
            );

            if (
                is_struct(_pocket)
                && variable_struct_exists(_pocket, "staff")
                && is_array(_pocket.staff)
                && array_length(_pocket.staff) > 0
            ) {
                for (var _p = 0; _p < array_length(_pocket.staff); _p++) {
                    save_staff_restore(_pocket.staff[_p]);
                }

                _staff_from_pocket = true;

                show_debug_message(
                    "[SAVE] Персонал взят из кармана клиники "
                    + string(_active_id)
                    + ": " + string(array_length(_pocket.staff))
                );
            }
        }
    }

    if (!_staff_from_pocket && is_array(_staff_list)) {
        for (var _s = 0; _s < array_length(_staff_list); _s++) {
            save_staff_restore(_staff_list[_s]);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // ПАКЕТ 277 (задачи 7-8): СТАЦИОНАР И ПОСЕТИТЕЛИ
    //
    // Порядок важен:
    //   1) картотека уже восстановлена выше — карты пациентов могут
    //      ссылаться на записи клиентов;
    //   2) сначала убираем посетителей, расставленных в комнате при
    //      старте, иначе к загруженным добавятся лишние;
    //   3) затем койки, затем посетители.
    // ═══════════════════════════════════════════════════════════════

    var _visitors_list = save_field(_data, "visitors", undefined);
    var _wards_list = save_field(_data, "wards", undefined);

    // Чистим только если в сейве вообще есть эти разделы. У сохранений,
    // сделанных до пакета 277, их нет — и тогда мы ничего не трогаем,
    // чтобы не сломать загрузку старого файла.
    if (is_array(_visitors_list) || is_array(_wards_list)) {
        var _old_visitors = [];

        for (var _v = 0; _v < instance_number(obj_owner); _v++) {
            var _old_owner = instance_find(obj_owner, _v);

            if (instance_exists(_old_owner)) {
                array_push(_old_visitors, _old_owner);
            }
        }

        for (var _d = 0; _d < array_length(_old_visitors); _d++) {
            if (!instance_exists(_old_visitors[_d])) continue;

            // Питомца убираем вместе с владельцем, иначе он остался бы
            // бродить по клинике без хозяина.
            var _old_pet = save_inst_field(_old_visitors[_d], "my_pet", noone);

            if (instance_exists(_old_pet)) {
                with (_old_pet) instance_destroy();
            }

            with (_old_visitors[_d]) instance_destroy();
        }

        // Освобождаем койки от прежних привязок.
        for (var _w = 0; _w < instance_number(obj_inpatient_controller); _w++) {
            var _old_ward = instance_find(obj_inpatient_controller, _w);

            if (!instance_exists(_old_ward)) continue;

            with (_old_ward) {
                if (instance_exists(patient)) {
                    with (patient) instance_destroy();
                }

                patient = noone;
                phase = "empty";
                ward_doctor = noone;
                ward_assistant = noone;
                escort_doctor = noone;
                departing_owner = noone;
                returning_owner = noone;
                player_actor = noone;
            }
        }
    }

    if (is_array(_wards_list)) {
        save_wards_restore(_wards_list);
    }

    if (is_array(_visitors_list)) {
        save_visitors_restore(_visitors_list);
    }

    // ── игрок ──
    var _player_data = save_field(_data, "player", undefined);

    if (is_struct(_player_data) && instance_exists(obj_player)) {
        var _player = instance_find(obj_player, 0);

        with (_player) {
            save_restore_array_asis(id, "skills",
                save_field(_player_data, "skills", ""));
            save_restore_array_asis(id, "skill_xp",
                save_field(_player_data, "skill_xp", ""));
            save_restore_array_asis(id, "skill_xp_needed",
                save_field(_player_data, "skill_xp_needed", ""));

            save_restore_array_asis(id, "player_admin_skill_levels",
                save_field(_player_data, "player_admin_skill_levels", ""));
            save_restore_array_asis(id, "player_admin_skill_xp",
                save_field(_player_data, "player_admin_skill_xp", ""));
            save_restore_array_asis(id, "player_assistant_skill_levels",
                save_field(_player_data, "player_assistant_skill_levels", ""));
            save_restore_array_asis(id, "player_assistant_skill_xp",
                save_field(_player_data, "player_assistant_skill_xp", ""));

            var _p_xp_log = save_field(_player_data, "xp_log", "");

            if (is_array(_p_xp_log)) {
                xp_log = [];

                for (var _pl = 0; _pl < array_length(_p_xp_log); _pl++) {
                    array_push(xp_log, string(_p_xp_log[_pl]));
                }
            }

            walk_skill_level = save_field(_player_data, "walk_skill_level", 1);
            walk_skill_xp = save_field(_player_data, "walk_skill_xp", 0);
            walk_skill_xp_needed = save_field(_player_data, "walk_skill_xp_needed", 30);
            stamina_level = save_field(_player_data, "stamina_level", 1);
            stamina_xp = save_field(_player_data, "stamina_xp", 0);
            stamina_xp_needed = save_field(_player_data, "stamina_xp_needed", 30);
            stat_energy = save_field(_player_data, "stat_energy", 100);
            energy_max = save_field(_player_data, "energy_max", 100);
            energy = stat_energy;
        }
    }

    show_debug_message(
        "[SAVE] Загружено: день " + string(global.game_day)
        + ", $" + string(global.clinic_money)
        + ", сотрудников " + string(
            is_array(_staff_list) ? array_length(_staff_list) : 0
        )
    );

    return true;
}


// ═══════════════════════════════════════════════════════════════
// 6. АВТОСОХРАНЕНИЕ
//
// Раз в игровой день + при выходе из игры. Вызывается из obj_Render.
// ═══════════════════════════════════════════════════════════════

function save_autosave_check() {
    var _day = save_global("game_day", 1);

    if (!variable_global_exists("save_last_day")) {
        global.save_last_day = _day;
        return false;
    }

    if (_day == global.save_last_day) return false;

    global.save_last_day = _day;

    return vetsim_save();
}
