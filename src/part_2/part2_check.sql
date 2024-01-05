--------------------------------------------------------
--check 1 (200 rows)
select * from get_periods(mod := 1, 
                        st := '2010-01-01'::timestamp, 
                        fin := '2030-02-02'::timestamp,
                        count:= 5);
--------------------------------------------------------
--check 2 (should not be changed)
select * from get_periods(mod := 2, 
                        st := '2010-01-01'::timestamp, 
                        fin := '2030-02-02'::timestamp);
--------------------------------------------------------
--check 1 (should be cut)
select * from get_periods(mod := 2, 
                        st := '2010-01-01'::timestamp, 
                        fin := '2030-02-02'::timestamp,
                        count:= 5);
--------------------------------------------------------
--check 1 (should be cut)
select * from get_periods(mod := 2, 
                        st := '2010-01-01'::timestamp, 
                        fin := '2030-02-02'::timestamp,
                        count:= 1);

--------------------------------------------------------
--check 1 (should be empty)
select * from get_periods(mod := 1, 
                        st := '2030-01-01'::timestamp, 
                        fin := '2010-02-02'::timestamp,
                        count:= 1);
--------------------------------------------------------
--check 1 (should not be empty)
select * from get_periods(mod := 1, 
                        st := '2018-01-01'::timestamp, 
                        fin := '2020-02-02'::timestamp,
                        count:= 1);
--check 1 (should be cut)
select * from get_periods(mod := 1, 
                        st := '2018-01-01'::timestamp, 
                        fin := '2019-02-02'::timestamp,
                        count:= 1);

--check (should be 200 rows)
select * from Periods_View;

--************************************************************************************************
-- 2_3
--************************************************************************************************
select * from fnc_create_params_View(mod := 1, 
                                    st := '2010-01-01', 
                                    fin := '21-08-2022 13:10:46', 
                                    count := 10000000);
-- 1	7	0.66666666666666666667	12.7716535433070866	0.98425196850393700787
-- 3	1	0.57142857142857142857	0.00271923861318830727	0.92250169952413324165
--------------------------------------------------------
--check 1 (should not be changed)
select * from fnc_create_params_View(mod := 2, 
                                    st := '2010-01-01', 
                                    fin := '21-08-2022 13:10:46', 
                                    count := 10000000);

--------------------------------------------------------
--check 1 (u1-g7 dissapears)
select * from fnc_create_params_View(mod := 2, 
                                    st := '2010-01-01', 
                                    fin := '21-08-2022 13:10:46', 
                                    count := 10);
--------------------------------------------------------
--check 1 (not changed)
select * from fnc_create_params_View(mod := 2, 
                                    st := '2022-01-01', 
                                    fin := '21-08-2022 13:10:46', 
                                    count := 10);
--------------------------------------------------------
--check 1 (cut)
select * from fnc_create_params_View(mod := 1, 
                                    st := '2022-01-01', 
                                    fin := '21-08-2022 13:10:46', 
                                    count := 10);
--------------------------------------------------------
--check 1 (empty)
select * from fnc_create_params_View(mod := 1, 
                                    st := '2023-01-01', 
                                    fin := '21-08-2022 13:10:46', 
                                    count := 5);
--check 1 (empty)
select * from fnc_create_params_View(mod := 1, 
                                    st := '2020-01-01', 
                                    fin := '21-08-2018 13:10:46', 
                                    count := 5);

-- 2_4
--************************************************************************************************
--------------------------------------------------------
--check 1
select * from fnc_create_margin_View();
select * from fnc_create_margin_View(mo := 1);
select * from fnc_create_margin_View(mo := 2, last_trans := 1000000);
select * from fnc_create_margin_View(mo := 2, last_trans := 10);
select * from fnc_create_margin_View(mo := 2, last_trans := 5);
select * from fnc_create_margin_View(mo := 2, last_trans := 1);
select * from fnc_create_margin_View(mo := 2, last_trans := 0);
--check  (full)
select * from fnc_create_margin_View(mo := 1, last_trans := 0);
select * from fnc_create_margin_View(mo := 1, last_trans := 10);
--check  (full)
select * from fnc_create_margin_View(mo := 1, fin:= '2030-01-01'::timestamp, last_trans := 10);

--check  (the same)
select * from fnc_create_margin_View(mo := 1, fin:= '2020-01-01'::timestamp, intrvl := '60 days'::interval);
select * from fnc_create_margin_View(fin:= '2020-01-01'::timestamp, intrvl := '60 days'::interval);
--check  (changed)
select * from fnc_create_margin_View(mo := 1, fin:= '2020-01-01'::timestamp, intrvl := '160 days'::interval);
--check  (changed)
select * from fnc_create_margin_View(mo := 1, fin:= '2022-01-01'::timestamp, intrvl := '160 days'::interval);
--check  (empty)
select * from fnc_create_margin_View(mo := 1, fin:= '2024-01-01'::timestamp, intrvl := '160 days'::interval);
--check  (full)
select * from fnc_create_margin_View(mo := 1, fin:= '2024-01-01'::timestamp, last_trans := 30);
--check  (small)
select * from fnc_create_margin_View(mo := 2, fin:= '2024-01-01'::timestamp, last_trans := 30);
--check  (smaller)
select * from fnc_create_margin_View(mo := 2, fin:= '2024-01-01'::timestamp, last_trans := 10);
--check  (one row)
select * from fnc_create_margin_View(mo := 2, fin:= '2024-01-01'::timestamp, last_trans := 1);




 --------------------------------------------------------
select * from fnc_create_Groups_View(mod := 2, margin_mod := 1, intrvl := '100 days'::interval);
 --------------------------------------------------------
select * from fnc_create_Groups_View(mod := 2, margin_mod := 1, intrvl := '150 days'::interval);
 --------------------------------------------------------
select * from fnc_create_Groups_View(mod := 2, margin_mod := 1, intrvl := '200 days'::interval);
 --------------------------------------------------------
select * from fnc_create_Groups_View(mod := 2, last_trans := 10, margin_mod := 1, intrvl := '200 days'::interval);
 --------------------------------------------------------
select * from fnc_create_Groups_View(mod := 2, last_trans := 10, margin_mod := 1, intrvl := '400 days'::interval);
 --------------------------------------------------------
select * from fnc_create_Groups_View(mod := 2, last_trans := 10, margin_mod := 1, intrvl := '900 days'::interval);
 --------------------------------------------------------
select * from fnc_create_Groups_View(mod := 2, last_trans := 10, margin_mod := 1, intrvl := '2400 days'::interval);