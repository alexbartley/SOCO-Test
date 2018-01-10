CREATE TABLE content_repo.gis_zone_auth_counts_tmp (
  authority_name VARCHAR2(100 CHAR),
  zone_3_name VARCHAR2(50 CHAR),
  zone_4_name VARCHAR2(50 CHAR),
  zone_5_name VARCHAR2(50 CHAR),
  zone_6_name VARCHAR2(50 CHAR),
  zone_7_name VARCHAR2(50 CHAR),
  unique_area VARCHAR2(1000 CHAR),
  rangecnt NUMBER,
  zipcount NUMBER,
  zippct NUMBER
) 
TABLESPACE content_repo;