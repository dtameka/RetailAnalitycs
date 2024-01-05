--  --------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_max_date()
RETURNS TIMESTAMP AS $$
DECLARE
    max_date TIMESTAMP;
BEGIN
    SELECT max(transaction_datetime) INTO max_date FROM transactions;
    RETURN max_date;
END;
$$ LANGUAGE plpgsql;

--  --------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_min_date()
RETURNS TIMESTAMP AS $$
DECLARE
    max_date TIMESTAMP;
BEGIN
    SELECT min(transaction_datetime) INTO max_date FROM transactions;
    RETURN max_date;
END;
$$ LANGUAGE plpgsql;

--****************************************************************************************************
--****************************************************************************************************
drop FUNCTION IF exists form_personal_offers(INT, TIMESTAMP WITHOUT TIME ZONE,
                            TIMESTAMP WITHOUT TIME ZONE,
                            INTEGER, NUMERIC, NUMERIC, NUMERIC, NUMERIC);
CREATE OR REPLACE FUNCTION form_personal_offers(
                mod INT DEFAULT 1,
                st TIMESTAMP DEFAULT '2010-01-01', 
                fin TIMESTAMP DEFAULT '21.08.2022 13:10:46', 
                tr_num INT DEFAULT 100, 
                avg_coeff NUMERIC DEFAULT 1.15, 
                max_churn_ind NUMERIC DEFAULT 3, 
                max_disc_share NUMERIC DEFAULT 70, 
                allow_share NUMERIC DEFAULT 30)
RETURNS TABLE (
    "Customer_ID" BIGINT,
    "Customer_Average_Check" NUMERIC,
    "Group_Name" TEXT,
    "Offer_Discount_Depth" NUMERIC
) AS $$
BEGIN       
    IF (st > fin) THEN
        raise exception 'invalid interval';
    END IF;
    IF (fin > (SELECT * FROM get_max_date())) THEN
        fin = (SELECT * FROM get_max_date());
    END IF;
    IF (st < (SELECT * FROM get_min_date())) THEN
        st = (SELECT * FROM get_min_date());
    END IF;
    IF (tr_num < 0) THEN
        raise exception 'invalid num of transactions';
    END IF;

    CALL fill_support_gr_table(mod, st, fin, tr_num);
    CALL fill_support_periods_table(mod, st, fin, tr_num);

RETURN QUERY
    WITH cte_tbl AS (
        SELECT 
        fcgv.customer_id,
        fcgv.group_id,
        fcgv."Group_Margin",
        fcgv."Group_Minimum_Discount",
        fcgv."Group_Affinity_Index",
        gib_2."Average_Check",
        sg.group_name,
    --маржа заморожена на подсчет по методу 1
        ("Group_Minimum_Discount" * 100 + (5 - (("Group_Minimum_Discount" * 100)%5))) AS "misha_discount"
    FROM fnc_create_Groups_View(mod, 
                                st::TIMESTAMP, 
                                fin::TIMESTAMP, 
                                tr_num, 1, 
                                (fin::TIMESTAMP - st::TIMESTAMP)::interval, 
                                tr_num) AS fcgv
    JOIN (SELECT 
        gib.customer_id,
        avg(gib.transaction_summ) * avg_coeff AS "Average_Check"
        FROM support_gr_view AS gib
        GROUP BY gib.customer_id
    ) AS gib_2
    ON fcgv.customer_id = gib_2.customer_id
    JOIN skugroup sg ON sg.group_id = fcgv.group_id
    WHERE fcgv."Group_Discount_Share" * 100 < max_disc_share AND fcgv."Group_Churn_Rate" <= max_churn_ind
    ORDER BY 1, 2
    ), cte_dbg AS (
        SELECT 
                cte_tbl.customer_id, 
                cte_tbl.group_name, 
                cte_tbl.group_id,
                (cte_tbl."Group_Margin" / cv."cnt_of_trans" * allow_share / 100)::NUMERIC(10,4) AS "Avg_with_coeff",
                (cte_tbl."Group_Margin" * allow_share / 100)::NUMERIC(10,4) AS "Avg_with_coeff_2",
                ("Average_Check" * "misha_discount" / 100.0)::NUMERIC(10,4) AS "sum_from_avg",
                cte_tbl."misha_discount"::NUMERIC(10,4),
                cte_tbl."Average_Check"::NUMERIC(10,4), cte_tbl."Group_Affinity_Index"::NUMERIC(10,4)
        FROM cte_tbl
        JOIN (SELECT 
                customer_id, 
                group_id, 
                count(*) AS "cnt_of_trans" 
            FROM support_gr_view AS sgv 
            GROUP BY sgv.customer_id, sgv.group_id
        ) AS cv
        ON cv.customer_id = cte_tbl.customer_id AND cv.group_id = cte_tbl.group_id
    ), cte_filered AS (
        SELECT * FROM cte_dbg
        WHERE "Avg_with_coeff_2" > "misha_discount"
        ORDER BY customer_id
    )
    SELECT 
        cf.customer_id, 
        cf."Average_Check", 
        cf.group_name, 
        cf.misha_discount AS "Discount" 
    FROM cte_filered AS cf
    JOIN (SELECT fc.customer_id, max("Group_Affinity_Index") AS mx
            FROM cte_filered AS fc GROUP BY fc.customer_id) AS fcc
    ON cf.customer_id = fcc.customer_id
    WHERE mx = cf."Group_Affinity_Index";
END;
$$ LANGUAGE plpgsql;

select * from form_personal_offers();