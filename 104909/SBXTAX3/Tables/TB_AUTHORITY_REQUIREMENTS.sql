CREATE TABLE sbxtax3.tb_authority_requirements (
  authority_requirement_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  "CONDITION" VARCHAR2(100 BYTE),
  "VALUE" VARCHAR2(100 BYTE),
  authority_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;