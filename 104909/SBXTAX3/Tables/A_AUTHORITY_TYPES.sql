CREATE TABLE sbxtax3.a_authority_types (
  authority_type_id NUMBER,
  merchant_id NUMBER,
  "NAME" VARCHAR2(100 BYTE),
  description VARCHAR2(1000 BYTE),
  created_by NUMBER(10),
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP,
  authority_type_id_o NUMBER,
  merchant_id_o NUMBER,
  name_o VARCHAR2(100 BYTE),
  description_o VARCHAR2(1000 BYTE),
  created_by_o NUMBER(10),
  creation_date_o DATE,
  last_updated_by_o NUMBER(10),
  last_update_date_o DATE,
  synchronization_timestamp_o TIMESTAMP,
  change_type VARCHAR2(100 CHAR) NOT NULL,
  change_version VARCHAR2(50 CHAR),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;