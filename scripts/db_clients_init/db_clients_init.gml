function db_clients_init() {

    global.owner_db = {};
    global.pet_db = {};
    global.visit_db = {};

    global.owner_list = [];
    global.pet_list = [];
    global.visit_list = [];

    global.owner_uid = 0;
    global.pet_uid = 0;
    global.visit_uid = 0;

    // Follow-up
    global.scheduled_visits = [];
    global.scheduled_visit_uid = 0;

    // Новые случайные визиты по дню
    global.daily_random_visits = [];
    global.daily_random_visit_uid = 0;
}