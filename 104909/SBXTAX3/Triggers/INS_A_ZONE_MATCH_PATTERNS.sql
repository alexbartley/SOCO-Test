CREATE OR REPLACE TRIGGER sbxtax3."INS_A_ZONE_MATCH_PATTERNS" 
AFTER INSERT ON sbxtax3.TB_ZONE_MATCH_PATTERNS
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
  INSERT INTO A_ZONE_MATCH_PATTERNS (
 ZONE_MATCH_PATTERN_ID, 
    PATTERN, 
    VALUE, 
    TYPE, 
    MERCHANT_ID, 
    CREATED_BY, 
    CREATION_DATE, 
    LAST_UPDATED_BY, 
    LAST_UPDATE_DATE, 
    --SYNCHRONIZATION_TIMESTAMP,
    CHANGE_TYPE,
    --CHANGE_VERSION,
    CHANGE_DATE
  ) VALUES (
   :NEW.ZONE_MATCH_PATTERN_ID, 
  :NEW.PATTERN, 
  :NEW.VALUE, 
  :NEW.TYPE, 
  :NEW.MERCHANT_ID, 
  :NEW.CREATED_BY, 
  :NEW.CREATION_DATE, 
  :NEW.LAST_UPDATED_BY, 
  :NEW.LAST_UPDATE_DATE,
    --:NEW.SYNCHRONIZATION_TIMESTAMP,

    'CREATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M, TB_RATES R WHERE M.MERCHANT_ID = R.MERCHANT_ID AND R.RATE_ID = :NEW.RATE_ID),
    SYSDATE);
END;
/