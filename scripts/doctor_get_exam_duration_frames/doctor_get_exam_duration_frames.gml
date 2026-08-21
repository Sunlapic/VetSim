/// doctor_get_exam_duration_frames.gml
/// @description Единая врачебная шкала скорости: Lv.1 = 12 сек., Lv.10 = 4 сек.

function doctor_get_exam_duration_frames(_level) {
    _level = clamp(round(_level), 1, 10);

    var _fps = max(1, game_get_speed(gamespeed_fps));
    var _ratio = (_level - 1) / 9;
    return round(lerp(_fps * 12, _fps * 4, _ratio));
}
