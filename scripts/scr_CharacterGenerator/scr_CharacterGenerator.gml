function generate_random_character(_id) {
    randomize();
    
    // 1. Личные данные
    var _names = ["Виктор", "Анна", "Сергей", "Ольга", "Максим", "Елена", "Денис"];
    var _surnames = ["Орлов", "Морозова", "Новиков", "Романова", "Лебедев", "Соколова"];
    _id.char_name = _names[irandom(array_length(_names)-1)] + " " + _surnames[irandom(array_length(_surnames)-1)];
    _id.age = irandom_range(23, 60);
    
    // 2. Генерация ХАРАКТЕРА
    _id.character_trait = irandom(11); // Один из 12 типов
    
    // 3. Генерация НАВЫКОВ (1-10)
    _id.skills = array_create(10);
    _id.skills_sum = 0;
    
    // Генерируем навыки (в среднем 3-6, для примера)
    for (var i = 0; i < 10; i++) {
        _id.skills[i] = irandom_range(1, 10);
        _id.skills_sum += _id.skills[i];
    }
    
    // 4. Динамические статы (0-100)
    _id.stat_energy = irandom_range(70, 100);
    _id.stat_stress = irandom_range(0, 30);
    _id.stat_loyalty = irandom_range(50, 100);
    _id.stat_morale = irandom_range(60, 90);
    
    // 5. Роль и Зарплата (зависит от суммы навыков)
    if (_id.skills_sum < 35) _id.role_rus = "Ассистент";
    else if (_id.skills_sum < 65) _id.role_rus = "Врач";
    else _id.role_rus = "Специалист";
}