function db_next_owner_id() {
    global.owner_uid += 1;
    return "owner_" + string(global.owner_uid);
}