/// Cleanup obj_reception_desk
/// @description Очистка стойки

if (ds_exists(queue_list, ds_type_list)) {
    ds_list_destroy(queue_list);
}