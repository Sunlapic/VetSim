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

        // ── персонал ──
        staff : []
    };

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
    var _inventory = save_field(_data, "inventory_main", undefined);

    if (is_struct(_inventory)) {
        global.inventory_main = save_copy_struct(_inventory);
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

    var _staff_list = save_field(_data, "staff", []);

    if (is_array(_staff_list)) {
        for (var _s = 0; _s < array_length(_staff_list); _s++) {
            save_staff_restore(_staff_list[_s]);
        }
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
