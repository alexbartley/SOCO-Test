CREATE TABLE sbxtax4.tr_usps (
  zip CHAR(5 BYTE),
  city_key CHAR(6 BYTE),
  zip_class CHAR,
  city_name CHAR(28 BYTE),
  city_abbrev CHAR(13 BYTE),
  city_facility_code CHAR,
  mailing_indicator CHAR,
  preferred_last_city_key CHAR(6 BYTE),
  preferred_last_city_name CHAR(28 BYTE),
  delivery_indicator CHAR,
  carrier_route_rate CHAR,
  unique_zip CHAR,
  finance_number CHAR(6 BYTE),
  state_abbrev CHAR(2 BYTE),
  county_number CHAR(3 BYTE),
  county_name CHAR(25 BYTE)
) 
TABLESPACE ositax;