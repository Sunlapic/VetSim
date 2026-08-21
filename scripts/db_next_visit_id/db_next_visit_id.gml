function db_next_visit_id() {
    global.visit_uid += 1;
    return "visit_" + string(global.visit_uid);
}