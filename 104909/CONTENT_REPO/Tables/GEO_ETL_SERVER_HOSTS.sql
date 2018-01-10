CREATE TABLE content_repo.geo_etl_server_hosts (
  "ID" NUMBER GENERATED AS IDENTITY,
  displayname VARCHAR2(5 CHAR),
  serverhost VARCHAR2(25 CHAR)
) 
TABLESPACE content_repo;