/// Create obj_operating_seat
/// @description Пакет №161. Стул ожидания бригады операционной.
/// Свободный сотрудник (operating_idle) приходит на свою точку и садится.
/// Ставится 3 инстанса; роль задаётся в Creation Code каждого инстанса:
///     or_seat_role = "surgeon";
///     or_seat_role = "anesthetist";
///     or_seat_role = "assistant";
/// Спрайт: нет (стулья вы подставите отдельными объектами мебели).
/// Родитель: нет. Solid: нет.

visible = false;
or_seat_role = "";
ward_slot_id = 0;
