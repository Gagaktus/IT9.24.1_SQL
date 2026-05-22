CREATE OR REPLACE VIEW stock_status AS
SELECT p.name,
       w.name AS warehouse_name,
       (s.quantity - COALESCE(s.reserved_quantity, 0)) AS available
FROM products p
JOIN stock s ON p.id = s.product_id
JOIN warehouses w ON s.warehouse_id = w.id;
