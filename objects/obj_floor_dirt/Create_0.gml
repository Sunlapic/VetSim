/// Create obj_floor_dirt
/// @description Процедурное пятно грязи на полу.

sprite_index = -1;
visible = true;

// Поверх напольного tile layer, но позади людей и мебели с depth = -y.
depth = -1;

is_hovered = false;
visual_ready = false;
traffic_direction = random(360);

visual_blobs = [];
visual_specks = [];
visual_prints = [];
visual_streaks = [];

dirt_variant = 0;
dirt_rotation = random(360);
dirt_scale = 1;
dirt_value = 3;
hit_radius = 30;

dirt_color_base = make_color_rgb(100, 75, 50);
dirt_color_dark = make_color_rgb(65, 50, 38);
dirt_color_light = make_color_rgb(145, 115, 80);

targeted_by_player = false;
target_player = noone;
interact_x = x;
interact_y = y + 28;
interact_path_built = false;

// Отдельное автоматическое задание NPC-ассистента.
targeted_by_assistant = false;
target_assistant = noone;
assistant_interact_x = x;
assistant_interact_y = y + 28;
assistant_cleaning_active = false;
assistant_clean_timer = 0;
assistant_clean_timer_max = room_speed * 10;

cleaning_active = false;
clean_after_arrival = false;
clean_timer = 0;
clean_timer_max = room_speed * 3;
cleaned_successfully = false;

dirt_generate_visual(id);

if (!variable_global_exists("clinic_cleanliness")) {
    global.clinic_cleanliness = 100;
}

global.clinic_cleanliness = clamp(
    global.clinic_cleanliness - dirt_value,
    0,
    100
);
