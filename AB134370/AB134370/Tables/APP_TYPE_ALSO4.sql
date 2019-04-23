CREATE TABLE ab134370.app_type_also4 (
  app_type_id NUMBER(10) NOT NULL,
  app_type NVARCHAR2(50) NOT NULL,
  created_by VARCHAR2(30 BYTE) NOT NULL,
  date_created TIMESTAMP NOT NULL,
  modified_by VARCHAR2(30 BYTE),
  date_modified TIMESTAMP,
  CONSTRAINT pk_apptype_also4 PRIMARY KEY (app_type)
);