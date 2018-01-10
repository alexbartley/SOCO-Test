CREATE TABLE sbxtax.a_app_errors (
  error_id NUMBER,
  error_num VARCHAR2(240 CHAR),
  error_severity VARCHAR2(25 CHAR),
  title VARCHAR2(80 CHAR),
  description VARCHAR2(2000 CHAR),
  cause VARCHAR2(2000 CHAR),
  "ACTION" VARCHAR2(2000 CHAR),
  created_by NUMBER,
  creation_date DATE,
  last_updated_by NUMBER,
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP,
  "CATEGORY" VARCHAR2(40 CHAR),
  merchant_id NUMBER,
  authority_id NUMBER,
  error_id_o NUMBER,
  error_num_o VARCHAR2(240 CHAR),
  error_severity_o VARCHAR2(25 CHAR),
  title_o VARCHAR2(80 CHAR),
  description_o VARCHAR2(2000 CHAR),
  cause_o VARCHAR2(2000 CHAR),
  action_o VARCHAR2(2000 CHAR),
  created_by_o NUMBER,
  creation_date_o DATE,
  last_updated_by_o NUMBER,
  last_update_date_o DATE,
  synchronization_timestamp_o TIMESTAMP,
  category_o VARCHAR2(40 CHAR),
  merchant_id_o NUMBER,
  authority_id_o NUMBER,
  change_type VARCHAR2(20 CHAR) NOT NULL,
  change_version VARCHAR2(50 CHAR),
  change_date DATE NOT NULL
) 
TABLESPACE ositax
LOB ("ACTION") STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (action_o) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (cause) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (cause_o) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (description_o) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);