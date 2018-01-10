CREATE TABLE content_repo.gis_zone_auth_counts_stage (
  unique_area VARCHAR2(1000 CHAR),
  zone_3_name VARCHAR2(50 CHAR),
  zone_4_name VARCHAR2(50 CHAR),
  zone_5_name VARCHAR2(50 CHAR),
  rangecnt NUMBER,
  zip4count NUMBER,
  zippct NUMBER,
  authority_name VARCHAR2(100 CHAR)
) 
TABLESPACE content_repo;