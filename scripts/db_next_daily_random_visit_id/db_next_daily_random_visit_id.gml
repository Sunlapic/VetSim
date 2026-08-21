function db_next_daily_random_visit_id() {
    global.daily_random_visit_uid += 1;
    return "daily_random_visit_" + string(global.daily_random_visit_uid);
}