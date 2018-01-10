CREATE TABLE crapp_admin.maintenance_routes (
  "ID" NUMBER,
  route VARCHAR2(255 CHAR) NOT NULL,
  "ROLES" VARCHAR2(255 CHAR) NOT NULL,
  status NUMBER DEFAULT 0
) 
TABLESPACE crapp_admin;