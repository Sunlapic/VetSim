/// Step obj_cleanliness_controller
/// @description Чистота и редкая очистка накопившихся ссылок на уничтоженные instances.

cleanliness_controller_step(id);
runtime_cleanup_prune_stale_references(id);
