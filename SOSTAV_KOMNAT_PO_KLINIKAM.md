# Что ставить в каждую клинику

Четыре комнаты, имена должны совпадать точно: `rm_clinic_1`,
`rm_clinic_2`, `rm_clinic_3`, `rm_clinic_4`.

`exam_slot_id` и `reception_slot_id` задаются в Creation Code каждого
объекта. Строка «без слота» означает, что Creation Code не нужен.

---

# КЛИНИКА 1 — комната `rm_clinic_1`
### «Каморка на окраине» · 2 кабинета · коек нет · операционной нет · склад малый · найм 4

**Система — без слота**

| Объект | Штук |
|---|---|
| `obj_Render` | 1 |
| `obj_UI_HUD` | 1 |
| `obj_UI_Tablet` | 1 |
| `obj_player` | 1 |
| `obj_monitor` | 1 |
| `obj_storage_main` | 1 |
| `obj_candidate_spot` | 1 |

**Чистота и раковины — без слота**

| Объект | Штук |
|---|---|
| `obj_cleanliness_controller` | 1 |
| `obj_cleanliness_area_start` | 1 |
| `obj_cleanliness_area_end` | 1 |
| `obj_cleanliness_area_start_2` | 1 |
| `obj_cleanliness_area_end_2` | 1 |
| `obj_sink` | 1 |
| `obj_sink_1` | 3 |

**Регистратура**

| Объект | Штук | Слот |
|---|---|---|
| `obj_reception_desk` | 1 | `reception_slot_id = 1` |
| `obj_reception_point_staff` | 1 | `reception_slot_id = 1` |
| `obj_reception_point_owner` | 1 | `reception_slot_id = 1` |
| `obj_reception_desk` | 1 | `reception_slot_id = 2` |
| `obj_reception_point_staff` | 1 | `reception_slot_id = 2` |
| `obj_reception_point_owner` | 1 | `reception_slot_id = 2` |

**Зал ожидания — без слота**

| Объект | Штук |
|---|---|
| `obj_wait_spot` | 4 |

**Кабинет приёма 1** — у всех шести объектов `exam_slot_id = 1`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 2** — у всех шести объектов `exam_slot_id = 2`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Стационар:** нет. **Операционная:** нет.

**Итого объектов: 38**

---

# КЛИНИКА 2 — комната `rm_clinic_2`
### «Районная лечебница» · 3 кабинета · 2 койки · операционной нет · склад средний · найм 7

**Система — без слота**

| Объект | Штук |
|---|---|
| `obj_Render` | 1 |
| `obj_UI_HUD` | 1 |
| `obj_UI_Tablet` | 1 |
| `obj_player` | 1 |
| `obj_monitor` | 1 |
| `obj_storage_main` | 1 |
| `obj_candidate_spot` | 1 |

**Чистота и раковины — без слота**

| Объект | Штук |
|---|---|
| `obj_cleanliness_controller` | 1 |
| `obj_cleanliness_area_start` | 1 |
| `obj_cleanliness_area_end` | 1 |
| `obj_cleanliness_area_start_2` | 1 |
| `obj_cleanliness_area_end_2` | 1 |
| `obj_sink` | 1 |
| `obj_sink_1` | 3 |

**Регистратура**

| Объект | Штук | Слот |
|---|---|---|
| `obj_reception_desk` | 1 | `reception_slot_id = 1` |
| `obj_reception_point_staff` | 1 | `reception_slot_id = 1` |
| `obj_reception_point_owner` | 1 | `reception_slot_id = 1` |
| `obj_reception_desk` | 1 | `reception_slot_id = 2` |
| `obj_reception_point_staff` | 1 | `reception_slot_id = 2` |
| `obj_reception_point_owner` | 1 | `reception_slot_id = 2` |

**Зал ожидания — без слота**

| Объект | Штук |
|---|---|
| `obj_wait_spot` | 5 |

**Кабинет приёма 1** — у всех шести объектов `exam_slot_id = 1`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 2** — у всех шести объектов `exam_slot_id = 2`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 3** — у всех шести объектов `exam_slot_id = 3`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Общий набор стационара — без слота**

| Объект | Штук |
|---|---|
| `obj_inpatient_cabinet` | 1 |
| `obj_inpatient_doctor_chair` | 1 |
| `obj_inpatient_point_doctor_rest` | 1 |

**Койка 101** — у всех семи объектов `exam_slot_id = 101`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 102** — у всех семи объектов `exam_slot_id = 102`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Операционная:** нет.

**Итого объектов: 62**

---

# КЛИНИКА 3 — комната `rm_clinic_3`
### «Городской ветцентр» · 4 кабинета · 5 коек · операционной нет · склад средний · найм 10

**Система — без слота**

| Объект | Штук |
|---|---|
| `obj_Render` | 1 |
| `obj_UI_HUD` | 1 |
| `obj_UI_Tablet` | 1 |
| `obj_player` | 1 |
| `obj_monitor` | 1 |
| `obj_storage_main` | 1 |
| `obj_candidate_spot` | 1 |

**Чистота и раковины — без слота**

| Объект | Штук |
|---|---|
| `obj_cleanliness_controller` | 1 |
| `obj_cleanliness_area_start` | 1 |
| `obj_cleanliness_area_end` | 1 |
| `obj_cleanliness_area_start_2` | 1 |
| `obj_cleanliness_area_end_2` | 1 |
| `obj_sink` | 1 |
| `obj_sink_1` | 3 |

**Регистратура**

| Объект | Штук | Слот |
|---|---|---|
| `obj_reception_desk` | 1 | `reception_slot_id = 1` |
| `obj_reception_point_staff` | 1 | `reception_slot_id = 1` |
| `obj_reception_point_owner` | 1 | `reception_slot_id = 1` |
| `obj_reception_desk` | 1 | `reception_slot_id = 2` |
| `obj_reception_point_staff` | 1 | `reception_slot_id = 2` |
| `obj_reception_point_owner` | 1 | `reception_slot_id = 2` |

**Зал ожидания — без слота**

| Объект | Штук |
|---|---|
| `obj_wait_spot` | 6 |

**Кабинет приёма 1** — у всех шести объектов `exam_slot_id = 1`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 2** — у всех шести объектов `exam_slot_id = 2`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 3** — у всех шести объектов `exam_slot_id = 3`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 4** — у всех шести объектов `exam_slot_id = 4`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Общий набор стационара — без слота**

| Объект | Штук |
|---|---|
| `obj_inpatient_cabinet` | 1 |
| `obj_inpatient_doctor_chair` | 1 |
| `obj_inpatient_point_doctor_rest` | 1 |

**Койка 101** — у всех семи объектов `exam_slot_id = 101`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 102** — у всех семи объектов `exam_slot_id = 102`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 103** — у всех семи объектов `exam_slot_id = 103`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 104** — у всех семи объектов `exam_slot_id = 104`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 105** — у всех семи объектов `exam_slot_id = 105`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Операционная:** нет.

**Итого объектов: 90**

---

# КЛИНИКА 4 — комната `rm_clinic_4`
### «Клиника у парка» · 6 кабинетов · 8 коек · операционная есть · склад большой · найм 17

**Система — без слота**

| Объект | Штук |
|---|---|
| `obj_Render` | 1 |
| `obj_UI_HUD` | 1 |
| `obj_UI_Tablet` | 1 |
| `obj_player` | 1 |
| `obj_monitor` | 1 |
| `obj_storage_main` | 1 |
| `obj_candidate_spot` | 1 |

**Чистота и раковины — без слота**

| Объект | Штук |
|---|---|
| `obj_cleanliness_controller` | 1 |
| `obj_cleanliness_area_start` | 1 |
| `obj_cleanliness_area_end` | 1 |
| `obj_cleanliness_area_start_2` | 1 |
| `obj_cleanliness_area_end_2` | 1 |
| `obj_sink` | 1 |
| `obj_sink_1` | 3 |

**Регистратура**

| Объект | Штук | Слот |
|---|---|---|
| `obj_reception_desk` | 1 | `reception_slot_id = 1` |
| `obj_reception_point_staff` | 1 | `reception_slot_id = 1` |
| `obj_reception_point_owner` | 1 | `reception_slot_id = 1` |
| `obj_reception_desk` | 1 | `reception_slot_id = 2` |
| `obj_reception_point_staff` | 1 | `reception_slot_id = 2` |
| `obj_reception_point_owner` | 1 | `reception_slot_id = 2` |

**Зал ожидания — без слота**

| Объект | Штук |
|---|---|
| `obj_wait_spot` | 6 |

**Кабинет приёма 1** — у всех шести объектов `exam_slot_id = 1`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 2** — у всех шести объектов `exam_slot_id = 2`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 3** — у всех шести объектов `exam_slot_id = 3`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 4** — у всех шести объектов `exam_slot_id = 4`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 5** — у всех шести объектов `exam_slot_id = 5`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Кабинет приёма 6** — у всех шести объектов `exam_slot_id = 6`

| Объект | Штук |
|---|---|
| `obj_table` | 1 |
| `obj_exam_point_doctor` | 1 |
| `obj_exam_point_owner` | 1 |
| `obj_exam_point_pet_floor` | 1 |
| `obj_exam_point_pet_table` | 1 |
| `obj_storage_cabinet` | 1 |

**Общий набор стационара — без слота**

| Объект | Штук |
|---|---|
| `obj_inpatient_cabinet` | 1 |
| `obj_inpatient_doctor_chair` | 1 |
| `obj_inpatient_point_doctor_rest` | 1 |

**Койка 101** — у всех семи объектов `exam_slot_id = 101`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 102** — у всех семи объектов `exam_slot_id = 102`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 103** — у всех семи объектов `exam_slot_id = 103`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 104** — у всех семи объектов `exam_slot_id = 104`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 105** — у всех семи объектов `exam_slot_id = 105`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 106** — у всех семи объектов `exam_slot_id = 106`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 107** — у всех семи объектов `exam_slot_id = 107`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Койка 108** — у всех семи объектов `exam_slot_id = 108`

| Объект | Штук |
|---|---|
| `obj_inpatient_controller` | 1 |
| `obj_inpatient_table` | 1 |
| `obj_inpatient_point_doctor` | 1 |
| `obj_inpatient_point_owner` | 1 |
| `obj_inpatient_point_assistant` | 1 |
| `obj_inpatient_point_pet_table` | 1 |
| `obj_inpatient_point_pet_floor` | 1 |

**Операционная** — у всех шести объектов `exam_slot_id = 201`

| Объект | Штук |
|---|---|
| `obj_operating_controller` | 1 |
| `obj_operating_table` | 1 |
| `obj_operating_point_surgeon` | 1 |
| `obj_operating_point_assistant` | 1 |
| `obj_operating_point_anesthetist` | 1 |
| `obj_operating_point_pet` | 1 |

**Кровать восстановления после операции** — у всех трёх объектов `exam_slot_id = 202`

| Объект | Штук |
|---|---|
| `obj_or_recovery_bed` | 1 |
| `obj_or_recovery_point_assistant` | 1 |
| `obj_or_recovery_point_pet` | 1 |

**Итого объектов: 132**

---

## Замечания

- Игрок стартует с открытым **кабинетом приёма 1**. Остальные объекты
  можно расставить сразу: покупка в панели развития их открывает, а не
  создаёт.
- Лишние слоты в комнате не страшны — игра не откроет кабинет или койку
  сверх потолка клиники. Но слот, которого в комнате нет, купить
  нельзя: нечего открывать.
- Персонал в комнатах расставлять не нужно: он приходит из кармана
  клиники при переезде, стартовый набирается через найм.
- Декор (`obj_bench`, `obj_bench_1`, `obj_plants_07`, `obj_well*`) —
  по вкусу, в подсчёт не входит и на логику не влияет.
- Числа объектов посчитаны по таблицам выше: 38 / 62 / 90 / 132.
- Состав взят из рабочей комнаты `Room1` — там эти же объекты с теми же
  номерами слотов.
