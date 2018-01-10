CREATE TABLE sbxtax.tb_location_tax_categories (
  location_tax_category_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(200 CHAR),
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE
) 
TABLESPACE ositax;