/// Alarm 2 obj_Render
/// @description Пакет №329: проверка состава комнаты клиники.
///
/// Ставится в Room Start (Other 4) с задержкой 3 шага — к этому
/// моменту объекты комнаты выполнили Create и Creation Code, и у
/// столов, шкафов и коек уже проставлены exam_slot_id /
/// ward_slot_id.
///
/// Печатает, чего не хватает в КАЖДОМ кабинете, койке, операционной
/// и послеоперационной — с номером клиники и именем комнаты:
///
///   [ПРОВЕРКА] Клиника №3 «Городской ветцентр» · rm_clinic_3 ·
///              койка 104: нет объекта точка ассистента стационара
///              (obj_inpatient_point_assistant). Поставь объект и
///              пропиши ward_slot_id = 104; в Creation Code инстанса.
///
/// В технической комнате (Room1 — база объектов) проверка молчит:
/// clinic_room_clinic_id() возвращает 0, и clinic_room_audit()
/// сразу выходит.

alarm[2] = -1;

if (!variable_global_exists("clinic_room_audited")) {
    global.clinic_room_audited = {};
}

var _room_key = string(room);

if (variable_struct_exists(global.clinic_room_audited, _room_key)) exit;

variable_struct_set(global.clinic_room_audited, _room_key, true);

if (script_exists(asset_get_index("clinic_room_audit"))) {
    clinic_room_audit();
}
else {
    show_debug_message(
        "[ПРОВЕРКА] Скрипт clinic_diagnostics не создан в проекте — "
        + "состав комнаты не проверен."
    );
}
