function db_next_scheduled_visit_id() {
    global.scheduled_visit_uid += 1;
    return "scheduled_visit_" + string(global.scheduled_visit_uid);
}