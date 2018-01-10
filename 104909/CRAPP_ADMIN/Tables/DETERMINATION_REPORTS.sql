CREATE TABLE crapp_admin.determination_reports (
  "ID" NUMBER(*,0),
  "NAME" VARCHAR2(255 BYTE),
  status NUMBER(*,0) DEFAULT 1,
  "QUERY" VARCHAR2(4000 BYTE),
  "INSTANCE" VARCHAR2(20 BYTE),
  fields VARCHAR2(255 BYTE)
) 
TABLESPACE crapp_admin;