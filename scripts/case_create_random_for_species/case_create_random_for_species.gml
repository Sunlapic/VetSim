function case_create_random_for_species(_species_id) {
    var _disease_id = db_pick_random_disease_for_species(_species_id);

    if (_disease_id == "") {
        return undefined;
    }

    return case_create_from_disease(_disease_id, _species_id);
}