CREATE TABLE crapp_admin.test_tests (
  "ID" NUMBER(11) NOT NULL,
  full_name VARCHAR2(15 CHAR),
  "TYPE" VARCHAR2(9 CHAR) NOT NULL,
  test_name VARCHAR2(20 CHAR) NOT NULL,
  PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE crapp_admin
) 
TABLESPACE crapp_admin;
COMMENT ON COLUMN crapp_admin.test_tests."TYPE" IS 'Selenium, PHPUnit';