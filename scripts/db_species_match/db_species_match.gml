function db_species_match(_species_array, _species_id) {

    for (var i = 0; i < array_length(_species_array); i++) {
        if (_species_array[i] == _species_id) {
            return true;
        }
    }

    return false;
}