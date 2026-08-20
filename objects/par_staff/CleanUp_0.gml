/// Cleanup par_staff
/// @description Освобождает динамические ресурсы и удаляет ссылки на сотрудника.

runtime_cleanup_actor_references(id);
runtime_cleanup_detach_staff(id);

if (variable_instance_exists(id, "my_path") && path_exists(my_path)) {
    path_delete(my_path);
    my_path = -1;
}

if (
    variable_instance_exists(id, "my_baked_portrait")
    && my_baked_portrait != -1
    && sprite_exists(my_baked_portrait)
) {
    sprite_delete(my_baked_portrait);
    my_baked_portrait = -1;
}
