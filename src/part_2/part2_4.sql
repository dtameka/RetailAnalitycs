--CAUTION:
--IT IS RESPONSIBILITY OF THE USER TO CHECK THAT 
-- SUPPORT_GR_TABLE AND 
-- SUPPORT_PERIODS_TABLE ARE
--IN ACTUAL STATE.
DROP FUNCTION IF EXISTS calculate_group_affinity() cascade;
CREATE OR REPLACE FUNCTION calculate_group_affinity(fin TIMESTAMP)
RETURNS TABLE (
    customer_id BIGINT,
    group_id BIGINT,
    maxi TIMESTAMP,
    total_count BIGINT,
    "Group_Affinity_Index" NUMERIC,
    "Group_Frequency" NUMERIC,
    "Group_Churn_Rate" NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        tmp_2.customer_id,
        tmp_2.group_id,
        tmp_2.maxi,
        tmp_2.total_count,
        pw."Group_Purchase"::NUMERIC / tmp_2.total_count::NUMERIC AS "Group_Affinity_Index",
        pw."Group_Frequency",
        extract(DAY FROM (fin::TIMESTAMP - tmp_2.maxi)) / pw."Group_Frequency" AS "Group_Churn_Rate"
    FROM (
        SELECT *,
            (
                SELECT COUNT(*)
                FROM support_gr_view AS sgv_2
                WHERE transaction_datetime >= tmp.mini 
                AND transaction_datetime <= tmp.maxi
                AND tmp.customer_id = sgv_2.customer_id
            ) AS total_count
        FROM (
            SELECT sgv.customer_id, sgv.group_id,
                MIN(transaction_datetime) OVER (PARTITION BY sgv.customer_id, sgv.group_id) AS mini,
                MAX(transaction_datetime) OVER (PARTITION BY sgv.customer_id, sgv.group_id) AS maxi,
                transaction_datetime
            FROM support_gr_view AS sgv
        ) AS tmp
    ) AS tmp_2
    JOIN supp_periods_view AS pw
    ON pw.Customer_ID = tmp_2.customer_id AND pw.Group_ID = tmp_2.group_id
    ORDER BY 1, 2;
END;
$$ LANGUAGE plpgsql;

--****************************************************************************************************
--****************************************************************************************************
--CAUTION:
--IT IS RESPONSIBILITY OF THE USER TO CHECK THAT 
-- SUPPORT_GR_TABLE AND 
-- SUPPORT_PERIODS_TABLE ARE
--IN ACTUAL STATE.
DROP FUNCTION IF EXISTS calculate_stability_index() cascade;
CREATE OR REPLACE FUNCTION calculate_stability_index()
RETURNS TABLE (
        customer_id BIGINT, 
        group_id BIGINT, 
        "Group_Stability_Index" NUMERIC
) 
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tmp.customer_id, 
        tmp.group_id,
        COALESCE(AVG(tmp."Group_Stability_Index"), 0) AS "Group_Stability_Index"
        FROM (
            SELECT 
                sgv.customer_id, 
                sgv.group_id, 
                ABS((EXTRACT(DAYS FROM (transaction_datetime - (LAG(transaction_datetime)
                        OVER (PARTITION BY sgv.customer_id, sgv.group_id 
                        ORDER BY sgv.customer_id, sgv.transaction_datetime)))) 
                        - pw."Group_Frequency") / pw."Group_Frequency") AS "Group_Stability_Index"
            FROM support_gr_view AS sgv
            JOIN (
                SELECT DISTINCT 
                        supp_periods_view.customer_id, 
                        supp_periods_view.group_id, 
                        supp_periods_view."Group_Frequency" 
                FROM supp_periods_view
            ) AS pw
            ON pw.Customer_ID = sgv.customer_id AND pw.Group_ID = sgv.group_id
        ) AS tmp
    GROUP BY tmp.customer_id, tmp.group_id;
END;
$$ LANGUAGE plpgsql;

--****************************************************************************************************
--****************************************************************************************************
--CAUTION:
--IT IS RESPONSIBILITY OF THE USER TO CHECK THAT 
-- SUPPORT_GR_TABLE AND 
-- SUPPORT_PERIODS_TABLE ARE
--IN ACTUAL STATE.
DROP FUNCTION IF EXISTS create_params_View cascade;
CREATE OR REPLACE FUNCTION create_params_View(mod INT DEFAULT 1, 
                                            st TIMESTAMP DEFAULT '2010-01-01',
                                            fin TIMESTAMP DEFAULT '21-08-2022 13:10:46',
                                            count BIGINT DEFAULT 10000000)
    RETURNS TABLE (
        customer_id BIGINT, group_id BIGINT,
        "Group_Affinity_Index" NUMERIC,
        "Group_Churn_Rate" NUMERIC,
        "Group_Stability_Index" NUMERIC
    )
    AS $$
    BEGIN
    RETURN query
    WITH cte_aff_churn AS (
        SELECT * FROM calculate_group_affinity(fin)
    ), cte_stab AS (
        SELECT * FROM calculate_stability_index()
    )
    SELECT 
            cte_aff_churn.customer_id, 
            cte_aff_churn.group_id, 
            cte_aff_churn."Group_Affinity_Index", 
            cte_aff_churn."Group_Churn_Rate", 
            cte_stab."Group_Stability_Index" 
    FROM cte_aff_churn
    JOIN cte_stab
    ON cte_aff_churn.customer_id = cte_stab.customer_id AND cte_aff_churn.group_id = cte_stab.group_id
    ORDER BY 1,2;
    END;
    $$ LANGUAGE plpgsql;

--****************************************************************************************************
--CAUTION:
--IT IS RESPONSIBILITY OF THE USER TO CHECK THAT 
-- SUPPORT_GR_TABLE AND 
-- SUPPORT_PERIODS_TABLE ARE
--IN ACTUAL STATE.
DROP FUNCTION IF EXISTS create_margin_View cascade;
CREATE OR REPLACE FUNCTION create_margin_View(
                                            mo INT DEFAULT 1,
                                            fin TIMESTAMP DEFAULT '21.08.2022 13:10:46', 
                                            intrvl interval DEFAULT '100051 DAYS'::interval,
                                            last_trans INT DEFAULT 1000)
RETURNS TABLE (
    customer_id BIGINT, group_id BIGINT,
    margin NUMERIC
)
AS $$
BEGIN
RETURN QUERY
    WITH cte_aggr_2 AS (
        SELECT * FROM support_gr_view AS sgv
        WHERE sgv.transaction_datetime >= (fin - intrvl) AND mo = 1
        UNION ALL
        SELECT * FROM support_gr_view WHERE mo = 2
        ORDER BY transaction_datetime DESC LIMIT last_trans
    ), cte_aggr AS (
        SELECT DISTINCT ca.customer_id, ca.group_id,
        sum(ph."Group_Summ_Paid") OVER (PARTITION BY ca.customer_id, ca.group_id) AS paid,
        sum("Group_Cost") OVER (PARTITION BY ca.customer_id, ca.group_id) AS selfcost
        FROM cte_aggr_2 AS ca
        JOIN purchase_history AS ph
        ON ph."Transaction_DateTime" = ca.transaction_datetime
    )
    SELECT cte_aggr.customer_id, cte_aggr.group_id, (paid - selfcost) AS margin
    FROM cte_aggr
    ORDER BY 1, 2;
END;
$$ LANGUAGE plpgsql;

--****************************************************************************************************
--CAUTION:
--IT IS RESPONSIBILITY OF THE USER TO CHECK THAT 
-- SUPPORT_GR_TABLE AND 
-- SUPPORT_PERIODS_TABLE ARE
--IN ACTUAL STATE.
CREATE OR REPLACE VIEW gr_discount_share_view AS
    SELECT * FROM
    (SELECT customer_id, group_id,
    ((count(CASE WHEN sku_discount > 0 THEN 1 ELSE NULL END)
    OVER (PARTITION BY customer_id, group_id))::NUMERIC
    / (count(*) OVER (PARTITION BY customer_id, group_id))::NUMERIC) AS "Group_Discount_Share"
    FROM support_gr_view) AS tmp
    GROUP BY customer_id, group_id, "Group_Discount_Share"
    ORDER BY 1,2;

--****************************************************************************************************
--CAUTION:
--IT IS RESPONSIBILITY OF THE USER TO CHECK THAT 
-- SUPPORT_GR_TABLE AND 
-- SUPPORT_PERIODS_TABLE ARE
--IN ACTUAL STATE.
CREATE OR REPLACE VIEW gr_min_discount_view AS
    SELECT sgv.customer_id, sgv.group_id,
    min(pw."Group_Minimum_Discount") AS "Group_Minimum_Discount",
    sum(sku_summ_paid) / sum(sku_summ) AS "Group_Average_Discount"
    FROM support_gr_view sgv
    JOIN supp_periods_view AS pw
    ON pw.Customer_ID = sgv.customer_id AND pw.Group_ID = sgv.group_id
    WHERE pw."Group_Minimum_Discount"  > 0 AND sku_discount > 0
    GROUP BY sgv.customer_id, sgv.group_id
    ORDER BY 1,2;

--****************************************************************************************************
--AGGREGATION
DROP FUNCTION IF EXISTS fnc_create_Groups_View cascade;
CREATE OR REPLACE FUNCTION fnc_create_Groups_View(
                                                mod INT DEFAULT 1,
                                                st TIMESTAMP DEFAULT '2010-01-01',
                                                fin TIMESTAMP DEFAULT '21.08.2022 13:10:46',
                                                tr_count BIGINT DEFAULT 10000000,
                                                margin_mod INT DEFAULT 1, 
                                                intrvl interval DEFAULT '100051 DAYS'::interval,
                                                last_trans INT DEFAULT 1000000)
RETURNS TABLE (
    customer_id BIGINT,
    group_id BIGINT,
    "Group_Affinity_Index" NUMERIC,
    "Group_Churn_Rate" NUMERIC,
    "Group_Stability_Index" NUMERIC,
    "Group_Margin" NUMERIC,
    "Group_Discount_Share" NUMERIC,
    "Group_Minimum_Discount" NUMERIC,
    "Group_Average_Discount" NUMERIC
)
AS
$$
BEGIN
    CALL fill_support_gr_table(mod, st, fin, tr_count);
    CALL fill_support_periods_table(mod, st, fin, tr_count);

    RETURN query
        SELECT 
        caiaiv.customer_id, 
        caiaiv.group_id, 
        caiaiv."Group_Affinity_Index", 
        caiaiv."Group_Churn_Rate",
        caiaiv."Group_Stability_Index",
        mgn.margin AS "Group_Margin",
        gdsv."Group_Discount_Share",
        coalesce(gmdv."Group_Minimum_Discount", 0) AS "Group_Minimum_Discount",
        coalesce(gmdv."Group_Average_Discount", 0) AS "Group_Average_Discount"
        FROM create_params_View(mod, st, fin, tr_count) AS caiaiv
        LEFT JOIN (SELECT * FROM create_margin_View(margin_mod, fin::TIMESTAMP, 
                                                        intrvl::interval, last_trans)) AS mgn
        ON caiaiv.customer_id = mgn.customer_id AND caiaiv.group_id = mgn.group_id
        JOIN gr_discount_share_view AS gdsv
        ON caiaiv.customer_id = gdsv.customer_id AND caiaiv.group_id = gdsv.group_id
        LEFT JOIN gr_min_discount_view AS gmdv
        ON caiaiv.customer_id = gmdv.customer_id AND caiaiv.group_id = gmdv.group_id;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------
DROP VIEW IF EXISTS groups_view;
CREATE OR REPLACE VIEW groups_view AS
SELECT * FROM fnc_create_Groups_View();
--------------------------------------------------------






