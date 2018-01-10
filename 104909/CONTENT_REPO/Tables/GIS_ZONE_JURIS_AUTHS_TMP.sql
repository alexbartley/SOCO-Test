CREATE TABLE content_repo.gis_zone_juris_auths_tmp (
  state_code VARCHAR2(2 CHAR),
  nkid NUMBER,
  authority_uuid VARCHAR2(36 BYTE),
  gis_name VARCHAR2(100 CHAR),
  etl_name VARCHAR2(100 CHAR)
) 
TABLESPACE content_repo;