/// End Step obj_staff_admin
/// @description Во время регистрации администратор всегда смотрит на клиента через стойку.

event_inherited();


// ═══════════════════════════════════════════════════════════════
// 1. ПРОВЕРКА РАБОЧЕГО СОСТОЯНИЯ
// ═══════════════════════════════════════════════════════════════

if (
    reception_state == "registering"
    && instance_exists(reception_desk)
) {
    if (
        variable_instance_exists(reception_desk, "reception_refresh_points")
    ) {
        with (reception_desk) {
            reception_refresh_points();
        }
    }


    // ═══════════════════════════════════════════════════════════
    // 2. ТОЧКА, НА КОТОРУЮ СМОТРИТ АДМИНИСТРАТОР
    // ═══════════════════════════════════════════════════════════

    var _look_x = reception_desk.x;
    var _look_y = reception_desk.y;

    if (
        variable_instance_exists(reception_desk, "reception_owner_point")
        && instance_exists(reception_desk.reception_owner_point)
    ) {
        _look_x = reception_desk.reception_owner_point.x;
        _look_y = reception_desk.reception_owner_point.y;
    }
    else if (variable_instance_exists(reception_desk, "queue_start_x")) {
        _look_x = reception_desk.queue_start_x;
        _look_y = reception_desk.queue_start_y;
    }

    var _look_dx = _look_x - x;
    var _look_dy = _look_y - y;


    // ═══════════════════════════════════════════════════════════
    // 3. РАБОЧИЙ СПРАЙТ И НАПРАВЛЕНИЕ
    // ═══════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════
    // Пакет 256: АНИМАЦИЯ РАБОТЫ АДМИНИСТРАТОРА
    //
    // Было две причины, почему админ стоял в 1-м кадре ХОДЬБЫ:
    //
    // 1) Позы "работа спиной" (spr_human_B_work) в проекте НЕТ.
    //    Ветка _has_back_work не срабатывала никогда, и админ,
    //    повёрнутый спиной, уходил в фолбэк spr_human_B_walk с
    //    жёстко прибитым image_index = 0 — застывал на первом
    //    кадре ходьбы. Все рабочие анимации в проекте фронтальные.
    //    Теперь спиной админ не работает: всегда разворачивается
    //    лицом и играет spr_human_FR_work. Клиент стоит по ту
    //    сторону стойки, лицом к нему — единственный верный вариант.
    //
    // 2) _work_anim_timer здесь ЧИТАЛСЯ, но нигде не рос.
    //    Его увеличивает par_staff -> End Step, но только в ветке
    //    "else if (_is_working && _sprite_work_exists)". Этот End Step
    //    админа идёт ПОСЛЕ event_inherited() и перезаписывает
    //    sprite_index / image_index своими значениями. Даже когда
    //    родитель таймер крутил, кадр тут считался от той же
    //    переменной, но ветка спиной его игнорировала.
    //    Теперь таймер увеличивается прямо здесь — источник один.
    // ═══════════════════════════════════════════════════════════

    if (!variable_instance_exists(id, "_work_anim_timer")) _work_anim_timer = 0;

    _work_anim_timer += 1;

    sprite_index = spr_human_FR_work;

    var _work_frames = max(1, sprite_get_number(spr_human_FR_work));
    var _work_speed  = 6;   // кадров игры на 1 кадр анимации (как в par_staff)

    image_speed = 0;
    image_index = floor(_work_anim_timer / _work_speed) mod _work_frames;

    // Разворот к клиенту. Спрайт фронтальный, поэтому зеркалим
    // по горизонтали — формула та же, что была во фронтальной ветке.
    pFacing = (abs(_look_dx) > 1 && _look_dx < 0) ? -1 : 1;


    // ═══════════════════════════════════════════════════════════
    // 4. ФИКСАЦИЯ У СТОЙКИ И ГЛУБИНА
    // ═══════════════════════════════════════════════════════════

    path_end();
    speed = 0;
    is_walking = false;

    image_xscale = abs(image_xscale) * pFacing;

    // Руки и рабочая анимация рисуются поверх стойки.
    depth = reception_desk.depth - 3;
}
