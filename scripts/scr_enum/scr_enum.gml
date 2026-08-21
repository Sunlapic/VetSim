// ════════════════════════════════════════════════════════════════
// scr_enum - Все константы проекта VetSim
// Пакет №139: скрипт ВОССТАНОВЛЕН. Enum PET_STAGE (и другие) используются
// живым кодом (par_animals → Create: life_stage = PET_STAGE.PUPPY) —
// удалять их нельзя.
// ════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════
// 1. СТАДИИ ЖИЗНИ ПИТОМЦА
// ════════════════════════════════════════════════════════════════
enum PET_STAGE {
    PUPPY = 0,
    TEEN = 1,
    ADULT = 2,
    SENIOR = 3
}

// ════════════════════════════════════════════════════════════════
// 2. ТИПЫ ЖИВОТНЫХ
// ════════════════════════════════════════════════════════════════
enum ANIMAL_TYPE {
    DOG = 0,
    CAT = 1,
    RABBIT = 2,
    HAMSTER = 3,
    BIRD = 4,
    TURTLE = 5
}

// ════════════════════════════════════════════════════════════════
// 3. СОСТОЯНИЕ ВЛАДЕЛЬЦА
// ════════════════════════════════════════════════════════════════
enum OWNER_STATE {
    IDLE = 0,
    WALKING_TO_CLINIC = 1,
    AT_CLINIC = 2,
    GOING_HOME = 3,
    WAITING_NEW_PET = 4
}

// ════════════════════════════════════════════════════════════════
// 4. ПРИЧИНА ВИЗИТА
// ════════════════════════════════════════════════════════════════
enum VISIT_REASON {
    CHECKUP = 0,
    VACCINATION = 1,
    ILLNESS = 2
}

// ════════════════════════════════════════════════════════════════
// 5. ФУНКЦИИ
// ════════════════════════════════════════════════════════════════
function get_pet_stage_name(_stage) {
    switch (_stage) {
        case PET_STAGE.PUPPY:  return "Щенок";
        case PET_STAGE.TEEN:   return "Подросток";
        case PET_STAGE.ADULT:  return "Взрослый";
        case PET_STAGE.SENIOR: return "Пожилой";
        default:               return "Неизвестно";
    }
}

function get_owner_state_name(_state) {
    switch (_state) {
        case OWNER_STATE.IDLE:              return "Гуляет";
        case OWNER_STATE.WALKING_TO_CLINIC: return "Идёт в клинику";
        case OWNER_STATE.AT_CLINIC:         return "В клинике";
        case OWNER_STATE.GOING_HOME:        return "Домой";
        case OWNER_STATE.WAITING_NEW_PET:   return "Ждёт питомца";
        default:                            return "Неизвестно";
    }
}

function get_visit_reason_name(_reason) {
    switch (_reason) {
        case VISIT_REASON.CHECKUP:    return "Осмотр";
        case VISIT_REASON.VACCINATION: return "Вакцинация";
        case VISIT_REASON.ILLNESS:    return "Болезнь";
        default:                       return "Неизвестно";
    }
}
