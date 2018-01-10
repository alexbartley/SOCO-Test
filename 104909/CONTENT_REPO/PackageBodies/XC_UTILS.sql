CREATE OR REPLACE PACKAGE BODY content_repo."XC_UTILS" AS
       function fxvCommoditySeq(ph_code IN commodities.h_code%type) 
             RETURN commodities.h_code%TYPE IS
             h_code_upone commodities.h_code%TYPE;
       BEGIN
  IF (ph_code IS NOT NULL) THEN
    SELECT 
       REGEXP_REPLACE(h_code,'[^.]+',  
       LPAD(to_char(
       to_number(
       regexp_substr(h_code,'[^.]+',1, regexp_count(h_code,'[^.]+'))
       )+1)
       ,3,'0'),1,regexp_count(h_code,'[^.]+')) new_set
       INTO h_code_upone 
       FROM
       (
        SELECT 
        decode(max(h_code),NULL,ph_code||'000.',max(h_code)) h_code
        from
       (
         SELECT 
         h_code,
         FIRST_VALUE(regexp_count(h_code,'[^.]+')) OVER (ORDER BY h_code) AS oo_level,
         regexp_count(h_code,'[^.]+') cr,
         regexp_substr(h_code,'[^.]+',1, regexp_count(h_code,'[^.]+')) main
         FROM commodities
         WHERE REGEXP_INSTR(h_code,ph_code)>0
        )
       WHERE 
       regexp_count(h_code,'[^.]+')=oo_level+1
       );
     RETURN h_code_upone;
   ELSE
     RETURN '';
   END IF;
  END fxvCommoditySeq;
END XC_UTILS;
/