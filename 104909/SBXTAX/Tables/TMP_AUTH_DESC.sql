CREATE TABLE sbxtax.tmp_auth_desc (
  nkid NUMBER NOT NULL,
  authority_type VARCHAR2(4000 CHAR),
  location_code VARCHAR2(1000 CHAR),
  admin_zone_level VARCHAR2(30 CHAR),
  authority_uuid VARCHAR2(36 CHAR),
  rid NUMBER
) 
TABLESPACE ositax
LOB (authority_type) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);