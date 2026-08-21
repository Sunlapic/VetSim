/// staff_apply_role(_role)
/// @description Применяет роль и генерирует навыки и специальность.
/// Пакет №77: у ассистентов специальность не заполняется.

function staff_apply_role(_role) {
    role = _role;

    skills = array_create(10, 1);
    skills_sum = 0;

    var _best_value = -1;
    var _best_index = 0;

    for (var i = 0; i < 10; i++) {
        var _value = irandom_range(1, 7);

        switch (_role) {
            case "doctor":
                if (i == 0 || i == 1) _value += 3;
            break;

            case "assistant":
                if (i == 2 || i == 3) _value += 2;
            break;

            case "admin":
                if (i == 4 || i == 5) _value += 3;
            break;
        }

        _value = clamp(_value, 1, 10);
        skills[i] = _value;
        skills_sum += _value;

        if (_value > _best_value) {
            _best_value = _value;
            _best_index = i;
        }
    }

    var _titles = [
        "ТЕРАПЕВТ",
        "ХИРУРГ",
        "ВРАЧ СТАЦИОНАРА",
        "ФЕЛЬДШЕР",
        "ЛАБОРАНТ",
        "ВРАЧ УЗИ",
        "РЕНТГЕНОЛОГ",
        "АНЕСТЕЗИОЛОГ",
        "ДЕРМАТОЛОГ",
        "СТОМАТОЛОГ"
    ];

    if (_role == "admin") {
        specialty_title = "АДМИНИСТРАТОР";
    } else if (_role == "assistant") {
        // Пакет №77: у ассистентов специализации нет.
        specialty_title = "";
    } else {
        // Для врача: выбираем по самому высокому навыку,
        // при равенстве — случайно.
        if (_role == "doctor") {
            var _doctor_best = [];

            for (var _d = 0; _d < 10; _d++) {
                if (skills[_d] == _best_value) {
                    array_push(_doctor_best, _d);
                }
            }

            if (array_length(_doctor_best) > 0) {
                _best_index = _doctor_best[
                    irandom_range(0, array_length(_doctor_best) - 1)
                ];
            }
        }

        specialty_title = _titles[_best_index];
    }
}
