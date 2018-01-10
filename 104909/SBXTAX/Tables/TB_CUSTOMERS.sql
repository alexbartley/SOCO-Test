CREATE TABLE sbxtax.tb_customers (
  customer_id NUMBER NOT NULL,
  customer_comment VARCHAR2(2000 CHAR),
  contact_fax VARCHAR2(20 CHAR),
  customer_group_id NUMBER NOT NULL,
  cust_number VARCHAR2(100 CHAR) NOT NULL,
  cust_name VARCHAR2(100 CHAR) NOT NULL,
  dba_name VARCHAR2(100 CHAR),
  address_1 VARCHAR2(60 CHAR),
  address_2 VARCHAR2(60 CHAR),
  address_3 VARCHAR2(60 CHAR),
  address_4 VARCHAR2(60 CHAR),
  city VARCHAR2(60 CHAR),
  st_code VARCHAR2(2 CHAR),
  zip_code VARCHAR2(50 CHAR),
  county_code VARCHAR2(3 CHAR),
  business_phone VARCHAR2(20 CHAR),
  contact_name VARCHAR2(60 CHAR),
  contact_email VARCHAR2(60 CHAR),
  contact_phone VARCHAR2(20 CHAR),
  contact_title VARCHAR2(100 CHAR),
  contact_department VARCHAR2(100 CHAR),
  created_by NUMBER NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER,
  last_update_date DATE,
  file_id NUMBER,
  fully_exempt VARCHAR2(1 CHAR),
  country VARCHAR2(3 CHAR),
  province VARCHAR2(50 CHAR),
  district VARCHAR2(50 CHAR),
  "STATE" VARCHAR2(50 CHAR),
  county VARCHAR2(50 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax
LOB (customer_comment) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);