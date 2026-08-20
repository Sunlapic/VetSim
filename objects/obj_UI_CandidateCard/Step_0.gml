/// Step obj_UI_CandidateCard

if (!variable_instance_exists(id, "_was_visible")) {
    _was_visible = false;
}

if (visible && !_was_visible) {
    click_lock = max(click_lock, 8);
}

_was_visible = visible;

if (click_lock > 0) click_lock -= 1;

if (!visible) {
    if (!instance_exists(obj_UI_Tablet) || !obj_UI_Tablet.visible) {
        global.ui_block_world_click = false;
    }
    exit;
}

if (!instance_exists(target_candidate)) {
    visible = false;
    target_candidate = noone;
    global.ui_block_world_click = false;
    exit;
}

global.ui_block_world_click = true;

if (keyboard_check_pressed(vk_escape)) {
    visible = false;
    global.ui_block_world_click = false;
    exit;
}

var _mouse_x = device_mouse_x_to_gui(0);
var _mouse_y = device_mouse_y_to_gui(0);

if (click_lock <= 0 && mouse_check_button_pressed(mb_left)) {
    if (point_in_rectangle(_mouse_x, _mouse_y, close_x1, close_y1, close_x2, close_y2)) {
        click_lock = 5;
        visible = false;
        global.ui_block_world_click = false;
        exit;
    }

    if (point_in_rectangle(_mouse_x, _mouse_y, reject_x1, reject_y1, reject_x2, reject_y2)) {
        click_lock = 5;
        var _candidate_reject = target_candidate;
        visible = false;
        target_candidate = noone;
        global.ui_block_world_click = false;

        if (instance_exists(_candidate_reject)) {
            with (_candidate_reject) {
                resolve_reject();
            }
        }
        exit;
    }

    if (point_in_rectangle(_mouse_x, _mouse_y, hire_x1, hire_y1, hire_x2, hire_y2)) {
        click_lock = 5;
        var _candidate_hire = target_candidate;
        visible = false;
        target_candidate = noone;
        global.ui_block_world_click = false;

        if (instance_exists(_candidate_hire)) {
            with (_candidate_hire) {
                resolve_hire();
            }
        }
        exit;
    }
}
