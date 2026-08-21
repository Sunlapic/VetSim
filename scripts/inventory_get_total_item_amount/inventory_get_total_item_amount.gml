function inventory_get_total_item_amount(_item_id) {
    var _total = 0;

    if (variable_global_exists("inventory_main")) {
        _total += inventory_get_amount(global.inventory_main, _item_id);
    }

    if (instance_exists(obj_storage_cabinet)) {
        for (var i = 0; i < instance_number(obj_storage_cabinet); i++) {
            var _cab = instance_find(obj_storage_cabinet, i);

            if (!instance_exists(_cab)) continue;

            if (variable_instance_exists(_cab, "storage_inventory")) {
                _total += inventory_get_amount(_cab.storage_inventory, _item_id);
            }
        }
    }

    return _total;
}