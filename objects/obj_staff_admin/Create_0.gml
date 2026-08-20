/// Create obj_staff_admin
/// @description Администратор: регистрация и касса. Ходьба и выносливость наследуются из общих навыков par_staff.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 1. ВНЕШНОСТЬ И РОЛЬ
// ═══════════════════════════════════════════════════════════════

staff_generate_appearance();
staff_apply_role("admin");
portrait_bake();

// Старое случайное блуждание через Alarm 1 не используется.
alarm[1] = -1;

home_x = x;
home_y = y;

// Зона свободного гуляния администратора около регистратуры.
wander_x1 = 1700;
wander_y1 = 950;
wander_x2 = 2000;
wander_y2 = 1200;
wander_idle_timer = room_speed * 2;
wander_walking = false;


// ═══════════════════════════════════════════════════════════════
// 2. СОСТОЯНИЕ РЕГИСТРАТУРЫ
// ═══════════════════════════════════════════════════════════════

reception_desk = instance_exists(obj_reception_desk)
    ? instance_find(obj_reception_desk, 0)
    : noone;

reception_client = noone;
reception_state = "idle";
reception_timer = 0;
reception_duration = room_speed * 4;

admin_idle_timer = 0;


// ═══════════════════════════════════════════════════════════════
// 3. ШКАЛА ДЕЙСТВИЯ
// ═══════════════════════════════════════════════════════════════

action_progress_active = false;
action_progress_timer = 0;
action_progress_timer_max = 0;
action_progress_label = "";
action_progress_color = make_color_rgb(80, 170, 90);


// ═══════════════════════════════════════════════════════════════
// 4. АДМИНИСТРАТИВНЫЕ НАВЫКИ
// Скорость ходьбы удалена отсюда и находится в ОБЩИХ НАВЫКАХ.
// ═══════════════════════════════════════════════════════════════

skill_level = [
    irandom_range(1, 2), // Регистрация
    irandom_range(1, 2)  // Касса
];

skill_xp = [0, 0];
skill_xp_needed = [30, 30];

register_duration = room_speed * 10;
payment_duration = room_speed * 10;
registration_skill_value = skill_level[0];


// ═══════════════════════════════════════════════════════════════
// 5. ПЕРЕСЧЁТ АДМИНИСТРАТИВНЫХ НАВЫКОВ
// Используются глобальные скрипты admin_recalc_skills и admin_add_skill_xp.
// ═══════════════════════════════════════════════════════════════

admin_recalc_skills(id);
