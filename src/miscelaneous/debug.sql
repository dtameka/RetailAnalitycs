-- Если что-то пошло не так, то это сотрет все таблицы

DO $$ DECLARE
    r RECORD;
BEGIN
    -- if the schema you operate on is not "current", you will want to
    -- replace current_schema() in query with 'schematodeletetablesfrom'
    -- *and* update the generate 'DROP...' accordingly.
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;

--выведет готовые фразы для удаления user-definded функций.
SELECT 'DROP FUNCTION ' || ns.nspname || '.' || p.proname || '(' || oidvectortypes(p.proargtypes) || ');'
FROM pg_proc p
JOIN pg_namespace ns ON p.pronamespace = ns.oid
WHERE ns.nspname NOT LIKE 'pg_%'
      AND ns.nspname != 'information_schema';

-- Стирает данные всех таблиц(DEBUG MOMENT)
CREATE OR REPLACE FUNCTION truncate_tables(username IN VARCHAR) RETURNS void AS $$
DECLARE
    statements CURSOR FOR
        SELECT tablename FROM pg_tables
        WHERE tableowner = username AND schemaname = 'public';
BEGIN
    FOR stmt IN statements LOOP
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(stmt.tablename) || ' CASCADE;';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- SELECT truncate_tables('postgres');

-- Импорт всех нужных данных(DEBUG MOMENT)
CREATE OR REPLACE PROCEDURE prc_import_all_data_from_tsv()
LANGUAGE 'plpgsql'
AS $$
BEGIN
CALL prc_import_data_from_tsv('personalinfo', '/docker-entrypoint-initdb.d/datasets/Personal_Data_Mini.tsv');
CALL prc_import_data_from_tsv('cards', '/docker-entrypoint-initdb.d/datasets/Cards_Mini.tsv');
CALL prc_import_data_from_tsv('skuGroup', '/docker-entrypoint-initdb.d/datasets/Groups_SKU_Mini.tsv');
CALL prc_import_data_from_tsv('productgrid', '/docker-entrypoint-initdb.d/datasets/SKU_Mini.tsv');
CALL prc_import_data_from_tsv('stores', '/docker-entrypoint-initdb.d/datasets/Stores_Mini.tsv');
CALL prc_import_data_from_tsv('transactions', '/docker-entrypoint-initdb.d/datasets/Transactions_Mini.tsv');
CALL prc_import_data_from_tsv('checks', '/docker-entrypoint-initdb.d/datasets/Checks_Mini.tsv');
CALL prc_import_data_from_tsv('dateofanalysisformation', '/docker-entrypoint-initdb.d/datasets/Date_Of_Analysis_Formation.tsv');

-- CALL prc_import_data_from_tsv('personalinfo', '/datasets/Personal_Data_Mini.tsv');
-- CALL prc_import_data_from_tsv('cards', '/datasets/Cards_Mini.tsv');
-- CALL prc_import_data_from_tsv('skuGroup', '/datasets/Groups_SKU_Mini.tsv');
-- CALL prc_import_data_from_tsv('productgrid', '/datasets/SKU_Mini.tsv');
-- CALL prc_import_data_from_tsv('stores', '/datasets/Stores_Mini.tsv');
-- CALL prc_import_data_from_tsv('transactions', '/datasets/Transactions_Mini.tsv');
-- CALL prc_import_data_from_tsv('checks', '/datasets/Checks_Mini.tsv');
-- CALL prc_import_data_from_tsv('dateofanalysisformation', '/datasets/Date_Of_Analysis_Formation.tsv')
END;
$$;

-- CALL prc_import_all_data_from_tsv();
