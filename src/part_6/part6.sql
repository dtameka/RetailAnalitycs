
DROP VIEW IF EXISTS cross_selling_support;
CREATE OR REPLACE VIEW cross_selling_support AS
SELECT cards.Customer_ID,
       tr.transaction_ID,
       tr.transaction_DateTime,
       tr.transaction_Store_ID,
       pg.Group_ID,
       ch.SKU_Amount,
       stores.SKU_ID,
       stores.SKU_Retail_Price,
       stores.SKU_Purchase_Price,
       ch.SKU_Summ_Paid,
       ch.SKU_Summ,
       ch.SKU_Discount
FROM transactions AS tr
JOIN cards ON cards.customer_card_id = tr.Customer_Card_id
JOIN personalinfo AS pi ON pi.Customer_id = cards.Customer_id
JOIN checks AS ch ON tr.transaction_id = ch.transaction_id
JOIN productgrid AS pg ON pg.sku_id = ch.sku_id
JOIN stores ON pg.sku_id = stores.sku_id
AND tr.transaction_store_id = stores.transaction_store_id;

DROP FUNCTION IF EXISTS fnc_cross_selling(integer, numeric, numeric, numeric, numeric);
CREATE FUNCTION fnc_cross_selling(
    IN count_groups integer,
    IN max_churn_index numeric,
    IN max_stability_index numeric,
    IN max_sku_share numeric,
    IN allow_margin_share numeric
)
RETURNS TABLE
        (
            Customer_ID          bigint,
            SKU_Name             text,
            Offer_Discount_Depth integer
        )
AS $$
BEGIN
RETURN QUERY
    WITH SKU_with_maximum_margin AS (
        SELECT dense_rank() OVER (PARTITION BY gv.customer_id ORDER BY gv.group_id) AS dense_rank_each_groups,
            first_value(pg.sku_name) OVER ( PARTITION BY gv.customer_id, gv.group_id ORDER BY (cs_supp.sku_retail_price - cs_supp.sku_purchase_price) DESC) AS sku_maximum_margin,
            gv.group_id, gv.customer_id, gv."Group_Minimum_Discount", cs_supp.sku_retail_price, cs_supp.sku_purchase_price
        FROM groups_view AS gv
        JOIN cross_selling_support AS cs_supp ON cs_supp.customer_id = gv.customer_id AND cs_supp.group_id = gv.group_id
        JOIN customers ON customers."Customer_ID" = gv.customer_id
        JOIN productgrid as pg ON pg.group_id = gv.group_id AND pg.sku_id = cs_supp.sku_id WHERE customers."Customer_Primary_Store" = cs_supp.transaction_store_id
            AND gv."Group_Churn_Rate" <= max_churn_index AND gv."Group_Stability_Index" < max_stability_index),
        sku_count_share AS (
            SELECT count(*) FILTER ( WHERE pg.sku_name = sku_max_marg.sku_maximum_margin)::numeric / NULLIF(count(*),0)
            FROM cross_selling_support AS cs_supp
            JOIN SKU_with_maximum_margin AS sku_max_marg ON sku_max_marg.customer_id = cs_supp.customer_id
            JOIN productgrid AS pg ON pg.sku_id = cs_supp.sku_id
            WHERE (cs_supp.customer_id = sku_max_marg.customer_id) AND cs_supp.group_id = sku_max_marg.group_id)
    SELECT DISTINCT sku_max_marg.customer_id, sku_max_marg.sku_maximum_margin,
        CASE
           WHEN (sku_max_marg."Group_Minimum_Discount"*1.05*100)::integer = 0 THEN 5
           ELSE (sku_max_marg."Group_Minimum_Discount"*1.05*100)::integer
        END
    FROM SKU_with_maximum_margin AS sku_max_marg
    WHERE dense_rank_each_groups <= count_groups
      AND (SELECT * FROM sku_count_share) < max_sku_share
      AND (sku_max_marg.sku_retail_price - sku_max_marg.sku_purchase_price) * allow_margin_share / 100.0 / sku_max_marg.sku_retail_price >= sku_max_marg."Group_Minimum_Discount" * 1.05;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM fnc_cross_selling(5, 3, 0.5, 100, 30);