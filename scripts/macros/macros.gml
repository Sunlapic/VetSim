#macro TILE_SIZE 64

enum TILE {
    SPRITE = 0,
    Z = 1
}
// --- 10 БАЗОВЫХ НАВЫКОВ ---
enum SKILL {
    THERAPY = 0,    // Терапия и диагностика
    SURGERY = 1,    // Хирургия
    STATIONARY = 2, // Стационар
    PROCEDURES = 3, // Процедуры
    LAB = 4,        // Лаборатория
    ULTRA = 5,      // УЗИ
    XRAY = 6,       // Рентген
    ANESTHESIA = 7, // Анестезия
    DERMA = 8,      // Дерматология
    DENTAL = 9      // Стоматология
}

// --- 12 ХАРАКТЕРОВ ---
enum TRAIT {
    CALM, AMBITIOUS, MENTOR, PERFECTIONIST, CONFLICT, KIND, 
    STRESS_RESISTANT, CHAOTIC, TEAM, RECLUSIVE, CAREERIST, TIRED
}
