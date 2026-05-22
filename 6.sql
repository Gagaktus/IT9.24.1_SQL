CREATE OR REPLACE PROCEDURE transfer_product(p_product_id INT, p_from_warehouse INT, p_to_warehouse INT, p_quantity INT)
LANGUAGE plpgsql AS $$
DECLARE avail INT;
BEGIN
    IF p_from_warehouse = p_to_warehouse THEN
        RAISE EXCEPTION 'same warehouse';
    END IF;
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'bad quantity';
    END IF;
    SELECT quantity - reserved_quantity INTO avail
    FROM stock
    WHERE product_id = p_product_id AND warehouse_id = p_from_warehouse;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'no product on source';
    END IF;
    IF avail < p_quantity THEN
        RAISE EXCEPTION 'not enough';
    END IF;
    UPDATE stock SET quantity = quantity - p_quantity
    WHERE product_id = p_product_id AND warehouse_id = p_from_warehouse;
    INSERT INTO stock (warehouse_id, product_id, quantity, reserved_quantity)
    VALUES (p_to_warehouse, p_product_id, p_quantity, 0)
    ON CONFLICT (warehouse_id, product_id) DO UPDATE
    SET quantity = stock.quantity + excluded.quantity;
    INSERT INTO transfers (product_id, from_warehouse, to_warehouse, quantity, transfer_date, status)
    VALUES (p_product_id, p_from_warehouse, p_to_warehouse, p_quantity, CURRENT_DATE, 'completed');
END;
$$;
