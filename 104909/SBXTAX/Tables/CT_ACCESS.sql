CREATE TABLE sbxtax.ct_access (
  username VARCHAR2(50 BYTE) NOT NULL,
  securekey VARCHAR2(300 BYTE) NOT NULL,
  access_id NUMBER,
  emp_id VARCHAR2(100 BYTE),
  authorize_type VARCHAR2(100 BYTE),
  real_name VARCHAR2(100 BYTE)
) 
TABLESPACE ositax;