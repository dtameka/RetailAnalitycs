select * from form_personal_offers();

select * from form_personal_offers(mod := 1, st := '2018-01-01'::timestamp);

select * from form_personal_offers(mod := 1, st := '2018-01-01'::timestamp, 
                                    fin := '21.08.2020 13:10:46'::timestamp);

-- should not be changed
select * from form_personal_offers(mod := 1, st := '2018-01-01'::timestamp, 
                                    fin := '21.08.2020 13:10:46'::timestamp,
                                    tr_num := 100);

select * from form_personal_offers(mod := 2, st := '2018-01-01'::timestamp, 
                                    fin := '21.08.2020 13:10:46'::timestamp,
                                    tr_num := 100);

select * from form_personal_offers(mod := 1);
--should not be changed
select * from form_personal_offers(mod := 2);

select * from form_personal_offers_2(st := '18.08.2022 00:00:00'::timestamp,
                                    fin := '18.08.2022 00:00:00'::timestamp,
                                    tr_num := 1);

select * from form_personal_offers_2(st := '18.08.2022 00:00:00'::timestamp,
                                    fin := '18.08.2022 00:00:00'::timestamp,
                                    tr_num := 2);


select * from form_personal_offers_2(st := '18.08.2022 00:00:00'::timestamp,
                                    fin := '18.10.2022 00:00:00'::timestamp,
                                    tr_num := 2);
--count should decrease
select * from form_personal_offers_2(st := '18.08.2022 00:00:00'::timestamp,
                                    fin := '18.10.2022 00:00:00'::timestamp,
                                    tr_num := 2, max_churn_ind := 1);

select * from form_personal_offers_2(st := '18.08.2022 00:00:00'::timestamp,
                                    fin := '18.10.2022 00:00:00'::timestamp,
                                    tr_num := 2, max_churn_ind := 1,
                                    max_disc_share := 60);
--decrease
select * from form_personal_offers_2(st := '18.08.2022 00:00:00'::timestamp,
                                    fin := '18.10.2022 00:00:00'::timestamp,
                                    tr_num := 2, max_churn_ind := 1,
                                    max_disc_share := 40);