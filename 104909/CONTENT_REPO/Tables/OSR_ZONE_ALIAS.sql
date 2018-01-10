CREATE TABLE content_repo.osr_zone_alias (
  state_code VARCHAR2(2 CHAR),
  state_name VARCHAR2(25 CHAR),
  "TYPE" VARCHAR2(2 CHAR),
  "ALIAS" VARCHAR2(64 CHAR),
  zone_name VARCHAR2(64 CHAR),
  zone_level VARCHAR2(10 CHAR),
  zone_id NUMBER
) 
TABLESPACE content_repo;