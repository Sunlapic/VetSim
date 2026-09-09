# ПАКЕТ №353 — УБРАН УСТАРЕВШИЙ room_speed (GM1024), ЧАСТЬ 2 из 4

Правка разбита на 4 маленькие части по 10–11 файлов, чтобы установку
было легко проверять. Ставьте по порядку: 352 → 353 → 354 → 355.

Суть: каждое чтение room_speed в коде заменено на
game_get_speed(gamespeed_fps) — рекомендуемая замена, и проект уже
пользуется ею в obj_Render (game_set_speed(60, gamespeed_fps)).
Поведение то же (скорость фиксирована 60), предупреждения GM1024
исчезнут. Записей в room_speed не было. Комментарии не тронуты.

## Файлы этой части (11)

Каждый *_FULL.gml кладётся целиком на своё место:
- obj_..._FULL.gml → событие объекта;
- имя скрипта _FULL.gml → скрипт целиком.

- obj_player_Create_0_FULL.gml
- obj_player_Step_0_FULL.gml
- obj_speech_bubble_Create_0_FULL.gml
- obj_staff_admin_CleanUp_0_FULL.gml
- obj_staff_admin_Create_0_FULL.gml
- obj_staff_admin_Step_0_FULL.gml
- obj_staff_assistant_Create_0_FULL.gml
- obj_staff_assistant_Step_0_FULL.gml
- obj_staff_assistant_Step_2_FULL.gml
- obj_table_Create_0_FULL.gml
- obj_table_1_Create_0_FULL.gml
