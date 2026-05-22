DELETE FROM product_categories WHERE id NOT IN (SELECT MIN(id) FROM product_categories GROUP BY name);
DELETE FROM suppliers WHERE id NOT IN (SELECT MIN(id) FROM suppliers GROUP BY name);
UPDATE stock SET quantity = 0 WHERE quantity < 0;
UPDATE stock SET reserved_quantity = 0 WHERE reserved_quantity < 0;
UPDATE stock SET reserved_quantity = quantity WHERE reserved_quantity > quantity;
DELETE FROM transfers WHERE from_warehouse = to_warehouse;
UPDATE stocktaking SET difference = actual_quantity - system_quantity;
