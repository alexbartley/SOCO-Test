CREATE TABLE sbxtax3.a_reference_lists (
  reference_list_id NUMBER(10),
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  description VARCHAR2(200 BYTE),
  start_date DATE,
  end_date DATE,
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  reference_list_id_o NUMBER(10),
  merchant_id_o NUMBER(10),
  name_o VARCHAR2(100 BYTE),
  description_o VARCHAR2(200 BYTE),
  start_date_o DATE,
  end_date_o DATE,
  created_by_o NUMBER(10),
  creation_date_o DATE,
  last_updated_by_o NUMBER(10),
  last_update_date_o DATE,
  change_type VARCHAR2(20 BYTE) NOT NULL,
  change_version VARCHAR2(250 BYTE),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;