# ПАКЕТ №354 — УБРАН УСТАРЕВШИЙ room_speed (GM1024), ЧАСТЬ 3 из 4

Правка разбита на 4 маленькие части по 10–11 файлов, чтобы установку
было легко проверять. Ставьте по порядку: 352 → 353 → 354 → 355.

Суть: каждое чтение room_speed в коде заменено на
game_get_speed(gamespeed_fps) — рекомендуемая замена, и проект уже
пользуется ею в obj_Render (game_set_speed(60, gamespeed_fps)).
Поведение то же (скорость фиксирована 60), предупреждения GM1024
исчезнут. Записей в room_speed не было. Комментарии не тронуты.

## Файлы этой части (10)

Каждый *_FULL.gml кладётся целиком на своё место:
- obj_..._FULL.gml → событие объекта;
- имя скрипта _FULL.gml → скрипт целиком.

- par_animals_Create_0_FULL.gml
- par_animals_Step_0_FULL.gml
- par_staff_Create_0_FULL.gml
- par_staff_Step_1_FULL.gml
- par_staff_Step_2_FULL.gml
- admin_xp_needed_FULL.gml
- case_apply_treatment_action_FULL.gml
- clinic_cleanliness_system_FULL.gml
- doctor_add_therapy_xp_FULL.gml
- inpatient_system_FULL.gml
