function treatment_get_condition_delta(_action_id) {
    switch (_action_id) {
        case "treat_iv_drip":       return 5;
        case "treat_antiprotozoal": return 5;
        case "treat_painkiller":    return 5;
        case "treat_limb_fixation": return 8;
    }

    return 0;
}