CREATE TABLE sbxtax.combined_rates_td (
  zone_3_name VARCHAR2(50 CHAR),
  zone_4_name VARCHAR2(50 CHAR) NOT NULL,
  zone_5_name VARCHAR2(50 CHAR) NOT NULL,
  zone_6_name VARCHAR2(50 CHAR) NOT NULL,
  state_auth NUMBER NOT NULL,
  state_rate NUMBER,
  county_auth NUMBER,
  county_rate NUMBER,
  city_auth NUMBER,
  city_rate NUMBER,
  zip_auth NUMBER,
  zip_rate NUMBER
) 
TABLESPACE ositax;