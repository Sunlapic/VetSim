function case_get_brief_complaint(_case) {

    var _names = case_get_visible_symptom_names(_case);

    if (array_length(_names) <= 0) {
        return "Жалобы неясны";
    }

    if (array_length(_names) == 1) {
        return _names[0];
    }

    return _names[0] + ", " + _names[1];
}