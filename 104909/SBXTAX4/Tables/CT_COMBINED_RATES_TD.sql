CREATE GLOBAL TEMPORARY TABLE sbxtax4.ct_combined_rates_td (
  "STATE" VARCHAR2(50 BYTE) NOT NULL,
  county VARCHAR2(100 BYTE) NOT NULL,
  city VARCHAR2(100 BYTE) NOT NULL,
  zip VARCHAR2(5 BYTE) NOT NULL,
  state_rate NUMBER,
  state_authority VARCHAR2(100 BYTE),
  county_rate NUMBER,
  county_authority VARCHAR2(100 BYTE),
  city_rate NUMBER,
  city_authority VARCHAR2(100 BYTE),
  zip_rate NUMBER,
  zip_authority VARCHAR2(100 BYTE)
)
ON COMMIT PRESERVE ROWS;