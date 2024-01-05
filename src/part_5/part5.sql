DROP FUNCTION IF EXISTS form_personal_offers_2(TIMESTAMP WITHOUT TIME ZONE,
                            TIMESTAMP WITHOUT TIME ZONE,
                            INTEGER,NUMERIC,NUMERIC,NUMERIC,NUMERIC);
CREATE OR REPLACE FUNCTION form_personal_offers_2(
                st TIMESTAMP DEFAULT '2010-01-01', 
                fin TIMESTAMP DEFAULT '21.08.2022 13:10:46', 
                tr_num INT DEFAULT 1, 
                avg_coeff NUMERIC DEFAULT 1.15, 
                max_churn_ind NUMERIC DEFAULT 3, 
                max_disc_share NUMERIC DEFAULT 70, 
                allow_share NUMERIC DEFAULT 30)
RETURNS TABLE (
    "Customer_ID" BIGINT,
    "Start_Date" TIMESTAMP,
    "End_Date" TIMESTAMP,
    "Required_Transactions_Count" NUMERIC,
    "Group_Name" TEXT,
    "Offer_Discount_Depth" NUMERIC
) AS $$
BEGIN       
    RETURN QUERY
    SELECT fpo."Customer_ID", st::TIMESTAMP, fin::TIMESTAMP, cm."Required_Transactions_Count",
    fpo."Group_Name", fpo."Offer_Discount_Depth" 
    FROM form_personal_offers(avg_coeff := avg_coeff, 
                            max_churn_ind := max_churn_ind, 
                            max_disc_share := max_disc_share, 
                            allow_share := allow_share) AS fpo
    JOIN
    (SELECT customers."Customer_ID",
    round(EXTRACT(DAYS FROM (fin::TIMESTAMP - st::TIMESTAMP))::NUMERIC 
    / "Customer_Frequency") + tr_num AS "Required_Transactions_Count"
    FROM customers) AS cm
    ON fpo."Customer_ID" = cm."Customer_ID";
END;
$$ LANGUAGE plpgsql;


SELECT * FROM form_personal_offers_2(st := '18.08.2022 00:00:00'::TIMESTAMP,
                                    fin := '18.08.2022 00:00:00'::TIMESTAMP,
                                    tr_num := 1);
