function schedule_daily_random_visits() {
    // Теперь новые случайные клиенты НЕ планируются по игровым минутам заранее.
    // Они идут живым потоком по реальному таймеру 5-60 секунд.
    // Этот массив оставляем только для совместимости.
    global.daily_random_visits = [];
    global.daily_random_spawned_today = 0;
}