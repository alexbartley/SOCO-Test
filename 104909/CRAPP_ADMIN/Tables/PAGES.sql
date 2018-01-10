CREATE TABLE crapp_admin.pages (
  "ID" NUMBER,
  "NAME" VARCHAR2(255 CHAR),
  parent_id NUMBER,
  description VARCHAR2(1000 CHAR)
) 
TABLESPACE crapp_admin;