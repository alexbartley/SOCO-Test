CREATE TABLE sbxtax2.tb_authority_requirements (
  authority_requirement_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  "CONDITION" VARCHAR2(100 BYTE),
  "VALUE" VARCHAR2(100 BYTE),
  authority_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER NOT NULL,
  start_date DATE DEFAULT TO_DATE('01/01/1901 12:00 AM', 'mm/dd/yyyy hh:mi am') NOT NULL,
  end_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;