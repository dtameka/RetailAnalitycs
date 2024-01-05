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
END;
$$;

CALL prc_import_all_data_from_tsv();
