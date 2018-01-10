CREATE TABLE sbxtax3.tb_location_tax_categories (
  location_tax_category_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(200 BYTE),
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE
) 
TABLESPACE ositax;