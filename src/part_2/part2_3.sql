DROP FUNCTION IF EXISTS get_group_discount_over_transaction() cascade;
CREATE OR REPLACE FUNCTION get_group_discount_over_transaction()
RETURNS TABLE (
    customer_id BIGINT,
    group_id BIGINT,
    "Group_Minimum_Discount" NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
    SELECT sgv.customer_id, sgv.group_id, 
        min(sgv.sku_discount / sgv.sku_summ) AS group_minimum_discount
    FROM support_gr_view AS sgv
    GROUP BY sgv.transaction_id, sgv.customer_id, sgv.group_id
    ORDER BY 1,2;
END;
$$ LANGUAGE plpgsql;
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS get_group_dates_and_count_data() cascade;
CREATE OR REPLACE FUNCTION get_group_dates_and_count_data()
RETURNS TABLE (
    customer_id BIGINT,
    group_id BIGINT,
    "First_Group_Purchase_Date" TIMESTAMP,
    "Last_Group_Purchase_Date" TIMESTAMP,
    "Group_Purchase" BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        sgv.customer_id,
        sgv.group_id,
        min(transaction_datetime),
        max(transaction_datetime),
        count(*)
    FROM
        (select sg.customer_id, sg.group_id, sg.transaction_id, sg.transaction_datetime 
        from support_gr_view as sg 
        group by sg.customer_id, sg.group_id, sg.transaction_id, sg.transaction_datetime) AS sgv
    GROUP BY
        sgv.customer_id,
        sgv.group_id;
END;
$$ LANGUAGE plpgsql;
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS get_periods(INT, TIMESTAMP, TIMESTAMP, BIGINT) cascade;
CREATE OR REPLACE FUNCTION get_periods(
    mod INT DEFAULT 1,
    st TIMESTAMP DEFAULT '1980-01-01'::TIMESTAMP, 
    fin TIMESTAMP DEFAULT '2050-01-01'::TIMESTAMP,
    count BIGINT DEFAULT 10000000)
RETURNS TABLE (
    customer_id BIGINT,
    group_id BIGINT,
    "First_Group_Purchase_Date" TIMESTAMP,
    "Last_Group_Purchase_Date" TIMESTAMP,
    "Group_Purchase" BIGINT,
    "Group_Frequency" NUMERIC,
    "Group_Minimum_Discount" NUMERIC
) AS $$
BEGIN
    CALL fill_support_gr_table(mod, st, fin, count); 
    RETURN query
        WITH cte_disc AS (
            select * from get_group_discount_over_transaction()
        ), cte_tbl AS (
            select * from get_group_dates_and_count_data()
        )
        SELECT
        cte_tbl.customer_id, 
        cte_tbl.group_id, 
        cte_tbl."First_Group_Purchase_Date", 
        cte_tbl."Last_Group_Purchase_Date", 
        cte_tbl."Group_Purchase", 
        ((to_char((cte_tbl."Last_Group_Purchase_Date" 
        - cte_tbl."First_Group_Purchase_Date"), 'dd'))::NUMERIC 
        + 1.0) / cte_tbl."Group_Purchase"::NUMERIC AS "Group_Frequency",
        cte_disc."Group_Minimum_Discount"
        FROM cte_tbl
        JOIN cte_disc
        ON cte_disc.customer_id = cte_tbl.customer_id
        AND cte_disc.group_id = cte_tbl.group_id
        ORDER BY 1,2;
END;
$$ LANGUAGE plpgsql;
--****************************************************************************************************
--****************************************************************************************************
--VERY IMPORTANT PROCEDURE. IT MUST BE PERFOMED BEFORE COUNTING DATA OF PARTS 4,5;
CREATE OR REPLACE PROCEDURE fill_support_periods_table
(
    mod INT DEFAULT 1,
    st TIMESTAMP DEFAULT '1980-01-01'::TIMESTAMP, 
    fin TIMESTAMP DEFAULT '2050-01-01'::TIMESTAMP,
    count BIGINT DEFAULT 10000000
)
AS $$
BEGIN
        DELETE FROM supp_periods_view;
        INSERT INTO supp_periods_view
        SELECT * FROM get_periods(mod, st, fin, count) WHERE mod = 1
        UNION ALL
        SELECT * FROM get_periods(mod, st, fin, count) WHERE mod = 2;
END;
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
DROP VIEW IF EXISTS Periods_View;
CREATE VIEW Periods_View AS
SELECT * FROM get_periods();