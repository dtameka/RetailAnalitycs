CREATE EXTENSION plperlu;

CREATE FUNCTION valid_email(text)
  RETURNS boolean
  LANGUAGE plperlu
  IMMUTABLE LEAKPROOF STRICT AS
$$
  use Email::Valid;
  my $email = shift;
  Email::Valid->address($email) or die "Invalid email address: $email\n";
  return 'true';
$$;

CREATE DOMAIN validemail AS text NOT NULL
  CONSTRAINT validemail_check CHECK (valid_email(VALUE));

CREATE DOMAIN validname AS varchar NOT NULL
  CONSTRAINT validname_check CHECK (VALUE ~ '^([А-Я]{1}[а-яё]+|[A-Z]{1}[a-z]+)$');

CREATE DOMAIN validphone AS varchar NOT NULL
  CONSTRAINT validphone_check CHECK (VALUE ~ '^(\+7)[0-9]{10}$');
-----------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS personalInfo (
  customer_id bigint NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
  customer_name validname NOT NULL,
  customer_surname validname NOT NULL,
  customer_primary_email validemail NOT NULL,
  customer_primary_phone validphone NOT NULL
);

-----------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cards (
  customer_card_id bigint NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
  customer_id bigint REFERENCES personalInfo (customer_id)
);

ALTER DATABASE dtdb SET datestyle TO 'SQL, DMY';
-----------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS skuGroup (
  group_id bigint NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
  group_name text NOT NULL
);

-----------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS productGrid (
  sku_id bigint NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
  sku_name text NOT NULL,
  group_id bigint REFERENCES skuGroup(group_id)
);

-----------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stores (
  transaction_store_id bigint NOT NULL,
  sku_id bigint NOT NULL REFERENCES productGrid(sku_id),
  sku_purchase_price numeric NOT NULL CHECK (sku_purchase_price >= 0),
  sku_retail_price numeric NOT NULL CHECK (sku_retail_price >= 0)
);

-----------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS transactions (
  transaction_id bigint NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
  customer_card_id bigint REFERENCES cards (customer_card_id),
  transaction_summ numeric NOT NULL,
  transaction_datetime timestamp NOT NULL,
  transaction_store_id bigint NOT NULL
);


-----------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS checks (
  transaction_id bigint NOT NULL REFERENCES transactions(transaction_id),
  sku_id bigint NOT NULL REFERENCES productGrid(sku_id),
  sku_amount numeric NOT NULL,
  sku_summ numeric NOT NULL,
  sku_summ_paid numeric NOT NULL,
  sku_discount numeric NOT NULL
);


-----------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS support_gr_view (
    transaction_id bigint,
    customer_id bigint,
    sku_id bigint,
    group_id bigint,
    transaction_datetime timestamp,
    transaction_summ numeric,
    sku_discount numeric,
    sku_summ numeric,
    sku_summ_paid numeric,
    sku_purchase_price NUMERIC,
    sku_amount NUMERIC,
    "Sku_Self_Cost" NUMERIC
);


CREATE TABLE IF NOT EXISTS supp_periods_view (
    customer_id bigint,
    group_id bigint,
    "First_Group_Purchase_Date" timestamp,
    "Last_Group_Purchase_Date" timestamp,
    "Group_Purchase" bigint,
    "Group_Frequency" numeric,
    "Group_Minimum_Discount" numeric
);

-----------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dateOfAnalysisFormation (
  Analysis_Formation timestamp NOT NULL
);
-----------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_import_data_from_tsv(IN tablename text, IN input_path text)
LANGUAGE 'plpgsql'
AS $$ 
BEGIN
EXECUTE format('COPY %s FROM %L WITH (FORMAT text)', tablename, input_path);
END;
$$;
-----------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_export_data_from_tsv(IN tablename text, IN output_path text)
LANGUAGE 'plpgsql'
AS $$ 
BEGIN
EXECUTE format('COPY %s TO %L WITH (FORMAT text)', tablename, output_path);
END;
$$;
-----------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE export_table_to_csv(in table_name TEXT, in file_name TEXT, in delimiter TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('COPY %I TO %L WITH CSV DELIMITER %L', table_name, file_name, delimiter);
END;
$$;
-----------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE import_csv_to_table(in table_name TEXT, in file_name TEXT, in delimiter TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('COPY %I FROM %L WITH CSV DELIMITER %L', table_name, file_name, delimiter);
END;
$$;


COMMENT ON COLUMN personalInfo.customer_id IS 'Идентификатор клиента';
COMMENT ON COLUMN personalInfo.customer_name IS 'Имя';
COMMENT ON COLUMN personalInfo.customer_surname IS 'Фамилия';
COMMENT ON COLUMN personalInfo.customer_primary_email IS 'E-mail клиента';
COMMENT ON COLUMN personalInfo.customer_primary_phone IS 'Телефон клиента';

COMMENT ON COLUMN cards.customer_card_id IS 'Идентификатор карты';
COMMENT ON COLUMN cards.customer_id IS 'Идентификатор клиента';

COMMENT ON COLUMN skuGroup.group_id IS 'Группа SKU';
COMMENT ON COLUMN skuGroup.group_name IS 'Название группы';

COMMENT ON COLUMN productGrid.sku_id IS 'Идентификатор товара';
COMMENT ON COLUMN productGrid.sku_name IS 'Название товара';
COMMENT ON COLUMN productGrid.group_id IS 'Группа SKU';

COMMENT ON COLUMN stores.transaction_store_id IS 'Торговая точка';
COMMENT ON COLUMN stores.sku_id IS 'Идентификатор товара';
COMMENT ON COLUMN stores.sku_purchase_price IS 'Закупочная стоимость товара';
COMMENT ON COLUMN stores.sku_retail_price IS 'Розничная стоимость товара';

COMMENT ON COLUMN transactions.transaction_id IS 'Идентификатор транзакции';
COMMENT ON COLUMN transactions.customer_card_id IS 'Идентификатор карты';
COMMENT ON COLUMN transactions.transaction_summ IS 'Сумма транзакции';
COMMENT ON COLUMN transactions.transaction_datetime IS 'Дата транзакции';
COMMENT ON COLUMN transactions.transaction_store_id IS 'Торговая точка';

COMMENT ON COLUMN checks.transaction_id IS 'Идентификатор транзакции';
COMMENT ON COLUMN checks.sku_id IS 'Позиция в чеке';
COMMENT ON COLUMN checks.sku_amount IS 'Количество штук или килограмм';
COMMENT ON COLUMN checks.sku_summ IS 'Сумма, на которую был куплен товар';
COMMENT ON COLUMN checks.sku_summ_paid IS 'Оплаченная стоимость покупки товара';
COMMENT ON COLUMN checks.sku_discount IS 'Предоставленная скидка';


