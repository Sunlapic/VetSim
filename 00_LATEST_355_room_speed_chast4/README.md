# ПАКЕТ №355 — УБРАН УСТАРЕВШИЙ room_speed (GM1024), ЧАСТЬ 4 из 4

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

- operating_system_FULL.gml
- reception_finish_owner_payment_FULL.gml
- reception_recover_orphaned_registration_FULL.gml
- runtime_resource_cleanup_FULL.gml
- secondary_skill_system_FULL.gml
- tablet_draw_animal_card_FULL.gml
- tablet_draw_candidate_skills_FULL.gml
- tablet_draw_staff_card_FULL.gml
- tablet_draw_staff_skills_FULL.gml
- ui_spawn_flying_plus_FULL.gml
