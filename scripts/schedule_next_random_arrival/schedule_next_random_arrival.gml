function schedule_next_random_arrival() {
    random_arrival_cooldown = irandom_range(global.random_arrival_min_frames, global.random_arrival_max_frames);
    random_arrival_pending = true;
}