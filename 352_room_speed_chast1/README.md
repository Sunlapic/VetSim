# ПАКЕТ №352 — УБРАН УСТАРЕВШИЙ room_speed (GM1024), ЧАСТЬ 1 из 4

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

- obj_Render_Step_0_FULL.gml
- obj_UI_HUD_Step_1_FULL.gml
- obj_UI_Tablet_Create_0_FULL.gml
- obj_UI_Tablet_Draw_64_FULL.gml
- obj_cleanliness_controller_Create_0_FULL.gml
- obj_dog_puppy_Alarm_1_FULL.gml
- obj_dog_puppy_Create_0_FULL.gml
- obj_dog_puppy_Step_2_FULL.gml
- obj_float_text_Create_0_FULL.gml
- obj_floor_dirt_Create_0_FULL.gml
- obj_owner_Step_0_FULL.gml
