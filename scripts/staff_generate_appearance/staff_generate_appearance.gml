function staff_generate_appearance() {
    portrait_x = 150;
    portrait_y = 50;
    portrait_zoom = 1;

    var _m_h = [spr_fr_walk_hair_01, spr_fr_walk_hair_02, spr_fr_walk_hair_03, spr_fr_walk_hair_04, spr_fr_walk_hair_05];
    var _m_h_b = [spr_b_walk_hair_01, spr_b_walk_hair_02, spr_b_walk_hair_03, spr_b_walk_hair_04, spr_b_walk_hair_05];

    var _f_h = [spr_fr_walk_hair_06, spr_fr_walk_hair_07, spr_fr_walk_hair_08, spr_fr_walk_hair_09, spr_fr_walk_hair_10, spr_fr_walk_hair_11];
    var _f_h_b = [spr_b_walk_hair_06, spr_b_walk_hair_07, spr_b_walk_hair_08, spr_b_walk_hair_09, spr_b_walk_hair_10, spr_b_walk_hair_11];

    var _n_l = [spr_fr_walk_nose_01, spr_fr_walk_nose_02, spr_fr_walk_nose_03, spr_fr_walk_nose_04, spr_fr_walk_nose_05, spr_fr_walk_nose_06, spr_fr_walk_nose_07, spr_fr_walk_nose_08, spr_fr_walk_nose_09, spr_fr_walk_nose_10, spr_fr_walk_nose_11, spr_fr_walk_nose_12];
    var _e_l = [spr_fr_walk_eyes_01, spr_fr_walk_eyes_02];
    var _m_l = [spr_fr_walk_mouths_01, spr_fr_walk_mouths_02, spr_fr_walk_mouths_03, spr_fr_walk_mouths_04, spr_fr_walk_mouths_05];

    is_female = choose(false, true);
    char_name = get_random_name(is_female);
    age = irandom_range(23, 60);

    if (is_female) {
        var _idx = irandom(array_length(_f_h) - 1);
        my_hair = _f_h[_idx];
        my_hair_back = _f_h_b[_idx];
    } else {
        var _idx = irandom(array_length(_m_h) - 1);
        my_hair = _m_h[_idx];
        my_hair_back = _m_h_b[_idx];
    }

    my_nose  = _n_l[irandom(array_length(_n_l) - 1)];
    my_eyes  = _e_l[irandom(array_length(_e_l) - 1)];
    my_mouth = _m_l[irandom(array_length(_m_l) - 1)];

    hair_color = choose(
        c_white,
        c_yellow,
        c_orange,
        make_color_rgb(180, 100, 50),
        make_color_rgb(200, 200, 200)
    );

    character_trait = irandom(11);
    stat_energy = irandom_range(70, 100);
    p_move_speed = random_range(2.5, 3.5);
}