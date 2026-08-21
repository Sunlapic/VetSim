function db_next_case_id() {
    global.case_uid += 1;
    return "case_" + string(global.case_uid);
}