CREATE OR REPLACE FUNCTION update_last_count_date() RETURNS TRIGGER AS $$
BEGIN
    UPDATE stock SET last_count_date = NEW.date
    WHERE warehouse_id = NEW.warehouse_id AND product_id = NEW.product_id;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_stocktaking_update_stock ON stocktaking;
CREATE TRIGGER trg_stocktaking_update_stock AFTER INSERT ON stocktaking
FOR EACH ROW EXECUTE FUNCTION update_last_count_date();

CREATE OR REPLACE FUNCTION check_stock_before_outgoing() RETURNS TRIGGER AS $$
DECLARE available_qty INT;
BEGIN
    SELECT quantity - reserved_quantity INTO available_qty
    FROM stock WHERE warehouse_id = NEW.from_warehouse AND product_id = NEW.product_id;
    IF available_qty < NEW.quantity THEN
        RAISE EXCEPTION 'Not enough stock: available %, required %', available_qty, NEW.quantity;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_outgoing_check_stock ON outgoing_shipments;
CREATE TRIGGER trg_outgoing_check_stock BEFORE INSERT ON outgoing_shipments
FOR EACH ROW EXECUTE FUNCTION check_stock_before_outgoing();

CREATE OR REPLACE FUNCTION log_stock_changes() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.quantity != NEW.quantity THEN
        INSERT INTO inventory_log (product_id, warehouse_id, change_type, old_quantity, new_quantity)
        VALUES (NEW.product_id, NEW.warehouse_id, 'UPDATE', OLD.quantity, NEW.quantity);
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO inventory_log (product_id, warehouse_id, change_type, old_quantity, new_quantity)
        VALUES (NEW.product_id, NEW.warehouse_id, 'INSERT', 0, NEW.quantity);
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_stock_log_changes ON stock;
CREATE TRIGGER trg_stock_log_changes AFTER INSERT OR UPDATE OF quantity ON stock
FOR EACH ROW EXECUTE FUNCTION log_stock_changes();
