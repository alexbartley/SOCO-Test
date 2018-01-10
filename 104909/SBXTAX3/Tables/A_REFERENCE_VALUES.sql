CREATE TABLE sbxtax3.a_reference_values (
  reference_value_id NUMBER(10),
  reference_list_id NUMBER(10),
  "VALUE" VARCHAR2(200 BYTE),
  start_date DATE,
  end_date DATE,
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  reference_value_id_o NUMBER(10),
  reference_list_id_o NUMBER(10),
  value_o VARCHAR2(200 BYTE),
  start_date_o DATE,
  end_date_o DATE,
  created_by_o NUMBER(10),
  creation_date_o DATE,
  last_updated_by_o NUMBER(10),
  last_update_date_o DATE,
  change_type VARCHAR2(20 BYTE) NOT NULL,
  change_version VARCHAR2(50 BYTE),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;