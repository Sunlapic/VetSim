/// Cleanup par_animals
/// @description Освобождает путь, возможный baked-портрет и внешние ссылки.

runtime_cleanup_actor_references(id);

if (variable_instance_exists(id, "my_path") && path_exists(my_path)) {
    path_delete(my_path);
    my_path = -1;
}

// Сейчас большинство животных не запекают отдельный портрет,
// но защита нужна для будущих видов и повторного использования portrait_bake().
if (
    variable_instance_exists(id, "my_baked_portrait")
    && my_baked_portrait != -1
    && sprite_exists(my_baked_portrait)
) {
    sprite_delete(my_baked_portrait);
    my_baked_portrait = -1;
}
