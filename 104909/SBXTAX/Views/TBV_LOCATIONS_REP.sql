CREATE OR REPLACE FORCE VIEW sbxtax.tbv_locations_rep (merchant_id,company,"NAME","ACTIVE",active_flag,country,country_code,province,"STATE",county,city,district,postcode,geocode,poo_usage_flag,poa_usage_flag,ship_from_usage_flag,ship_to_usage_flag,bill_to_usage_flag,supply_usage_flag,middleman_usage_flag,poo_flag,poa_flag,ship_from_flag,ship_to_flag,bill_to_flag,supply_flag,middleman_flag) AS
SELECT m.merchant_id
      ,M.NAME COMPANY
      ,L.NAME
      ,L.ACTIVE
      ,l.active active_flag
      ,c.NAME COUNTRY
      ,COUNTRY COUNTRY_CODE
      ,PROVINCE
      ,STATE
      ,COUNTY
      ,CITY
      ,DISTRICT
      ,POSTCODE
      ,GEOCODE
      ,POO_USAGE_FLAG
      ,POA_USAGE_FLAG
      ,SHIP_FROM_USAGE_FLAG
      ,SHIP_TO_USAGE_FLAG
      ,BILL_TO_USAGE_FLAG
      ,SUPPLY_USAGE_FLAG
      ,MIDDLEMAN_USAGE_FLAG
      ,POO_FLAG
      ,POA_FLAG
      ,SHIP_FROM_FLAG
      ,SHIP_TO_FLAG
      ,BILL_TO_FLAG
      ,SUPPLY_FLAG
      ,MIDDLEMAN_FLAG
  FROM
       TB_LOCATIONS L
      ,TB_MERCHANTS M
      ,tb_countries c
 WHERE
       L.MERCHANT_ID = M.MERCHANT_ID
   AND L.COUNTRY = C.CODE_2CHAR (+)
 
 
 ;