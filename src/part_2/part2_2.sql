--****************************************************************************************************
--****************************************************************************************************
CREATE OR REPLACE VIEW new_support_view AS
SELECT
            tr.transaction_id, 
            pi.customer_id,
            pg.sku_id, 
            pg.group_id,
            tr.transaction_datetime,
            tr.transaction_summ,
            ch.sku_discount,
            ch.sku_summ,
            ch.sku_summ_paid,
            s.sku_purchase_price,
            ch.sku_amount,
            ch.sku_amount * s.sku_purchase_price AS "Sku_Self_Cost"
FROM 
            transactions AS tr
            JOIN cards AS c ON tr.customer_card_id = c.customer_card_id
            JOIN personalInfo pi ON pi.customer_id = c.customer_id
            JOIN checks ch ON ch.transaction_id = tr.transaction_id
            JOIN productGrid pg ON pg.sku_id = ch.sku_id
            JOIN stores AS s ON pg.sku_id = s.sku_id 
                AND tr.transaction_store_id = s.transaction_store_id;

--****************************************************************************************************
--****************************************************************************************************
-- gets info for all users bordered by st - start, fin - end - transaction times
DROP FUNCTION IF EXISTS get_info_by_date_temp(st TIMESTAMP, fin TIMESTAMP) cascade;
CREATE OR REPLACE FUNCTION get_info_by_date_temp(
    st TIMESTAMP default '2000-01-01 00:00:00'::TIMESTAMP, 
    fin TIMESTAMP default '2030-01-01 00:00:00'::TIMESTAMP)
RETURNS TABLE (
    transaction_id BIGINT,
    customer_id BIGINT,
    sku_id BIGINT,
    group_id BIGINT,
    transaction_datetime TIMESTAMP,
    transaction_summ NUMERIC,
    sku_discount NUMERIC,
    sku_summ NUMERIC,
    sku_summ_paid NUMERIC,
    sku_purchase_price NUMERIC,
    sku_amount NUMERIC,
    "Sku_Self_Cost" NUMERIC
) AS $$
BEGIN
    return query
        SELECT * FROM new_support_view AS nsv
        WHERE nsv.transaction_datetime >= st AND nsv.transaction_datetime <= fin;
END;
$$ LANGUAGE plpgsql;

--****************************************************************************************************
--****************************************************************************************************
--gets info by count for certain user
DROP FUNCTION IF EXISTS get_info_by_count_support(BIGINT, BIGINT);
CREATE OR REPLACE FUNCTION get_info_by_count_support(cust_id BIGINT, trans_count BIGINT)
RETURNS TABLE (
    transaction_id BIGINT,
    customer_id BIGINT,
    sku_id BIGINT,
    group_id BIGINT,
    transaction_datetime TIMESTAMP,
    transaction_summ NUMERIC,
    sku_discount NUMERIC,
    sku_summ NUMERIC,
    sku_summ_paid NUMERIC,
    sku_purchase_price NUMERIC,
    sku_amount NUMERIC,
    "Sku_Self_Cost" NUMERIC
) AS $$
BEGIN
    return query
        SELECT * FROM new_support_view AS nsv
        WHERE nsv.customer_id = cust_id
        ORDER BY nsv.transaction_datetime DESC LIMIT trans_count;
END;
$$ LANGUAGE plpgsql;
------------------------------------------------------------------------------------------------------
-- gets info for all users bordered by trans_count for each user
DROP FUNCTION IF EXISTS get_info_by_count_trans_temp(BIGINT);
CREATE OR REPLACE FUNCTION get_info_by_count_trans_temp(trans_count BIGINT)
RETURNS TABLE (
    transaction_id BIGINT,
    customer_id BIGINT,
    sku_id BIGINT,
    group_id BIGINT,
    transaction_datetime TIMESTAMP,
    transaction_summ NUMERIC,
    sku_discount NUMERIC,
    sku_summ NUMERIC,
    sku_summ_paid NUMERIC,
    sku_purchase_price NUMERIC,
    sku_amount NUMERIC,
    "Sku_Self_Cost" NUMERIC
) 
AS $$
DECLARE
    i BIGINT;
BEGIN
    CREATE TEMPORARY TABLE output_table
        (
            transaction_id BIGINT,
            customer_id BIGINT,
            sku_id BIGINT,
            group_id BIGINT,
            transaction_datetime TIMESTAMP,
            transaction_summ NUMERIC,
            sku_discount NUMERIC,
            sku_summ NUMERIC,
            sku_summ_paid NUMERIC,
            sku_purchase_price NUMERIC,
            sku_amount NUMERIC,
            "Sku_Self_Cost" NUMERIC
        );

    FOR i IN (SELECT pers.customer_id FROM personalinfo AS pers)
    LOOP
        INSERT INTO output_table
        SELECT *
        FROM get_info_by_count_support(i, trans_count);
    END LOOP;

    RETURN QUERY
        SELECT * FROM output_table;

    DROP TABLE IF EXISTS output_table;

END;
$$ LANGUAGE plpgsql;

--****************************************************************************************************
--****************************************************************************************************
--VERY IMPORTANT PROCEDURE. IT MUST BE PERFOMED BEFORE COUNTING DATA OF PARTS 4,5;
CREATE OR REPLACE PROCEDURE fill_support_gr_table
(
    mod INT DEFAULT 1,
    st TIMESTAMP DEFAULT '1980-01-01'::TIMESTAMP, 
    fin TIMESTAMP DEFAULT '2050-01-01'::TIMESTAMP,
    count BIGINT DEFAULT 10000000
)
AS $$
BEGIN
        DELETE FROM support_gr_view;
        INSERT INTO support_gr_view
        SELECT * FROM get_info_by_date_temp(st::TIMESTAMP, fin::TIMESTAMP) WHERE mod = 1
        UNION ALL
        SELECT * FROM get_info_by_count_trans_temp(count) WHERE mod = 2;
END;
$$ LANGUAGE plpgsql;

--****************************************************************************************************
--****************************************************************************************************
DROP FUNCTION IF EXISTS get_purchase_history();
CREATE OR REPLACE FUNCTION get_purchase_history()
RETURNS TABLE (
    "Customer_ID" BIGINT,
    "Transaction_ID" BIGINT,
    "Transaction_DateTime" TIMESTAMP,
    "Group_ID" BIGINT,
    "Group_Cost" NUMERIC,
    "Group_Summ" NUMERIC,
    "Group_Summ_Paid" NUMERIC
) 
AS $$
BEGIN
    RETURN QUERY
    SELECT
        customer_id,
        transaction_id,
        transaction_datetime,
        group_id,
        SUM("Sku_Self_Cost"),
        SUM(sku_summ),
        SUM(sku_summ_paid)
    FROM new_support_view AS nsv
    GROUP BY nsv.customer_id, nsv.transaction_id, nsv.transaction_datetime, nsv.group_id;
END;
$$ LANGUAGE plpgsql;

--****************************************************************************************************
--****************************************************************************************************
DROP VIEW IF EXISTS purchase_history;
CREATE VIEW purchase_history AS
SELECT * FROM get_purchase_history();

