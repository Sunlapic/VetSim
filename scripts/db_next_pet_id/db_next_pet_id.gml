function db_next_pet_id() {
    global.pet_uid += 1;
    return "pet_" + string(global.pet_uid);
}