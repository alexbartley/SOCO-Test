CREATE TABLE sbxtax.ok_zip4_all_other (
  zip4 VARCHAR2(4000 CHAR),
  state_fips VARCHAR2(4000 CHAR),
  county_fips VARCHAR2(4000 CHAR)
) 
TABLESPACE ositax
LOB (county_fips) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (state_fips) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (zip4) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);