CREATE OR REPLACE TRIGGER sbxtax3."INS_A_ZONE_MATCH_CONTEXTS" 
AFTER INSERT ON sbxtax3.TB_ZONE_MATCH_CONTEXTS 
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
  INSERT INTO A_ZONE_MATCH_CONTEXTS (
ZONE_MATCH_CONTEXT_ID, 
ZONE_MATCH_PATTERN_ID, 
ZONE_LEVEL_ID, 
ZONE_ID, 
CREATED_BY, 
CREATION_DATE, 
LAST_UPDATED_BY, 
LAST_UPDATE_DATE, 
    CHANGE_TYPE,
    CHANGE_DATE
  ) VALUES (
:NEW.ZONE_MATCH_CONTEXT_ID, 
:NEW.ZONE_MATCH_PATTERN_ID, 
:NEW.ZONE_LEVEL_ID, 
:NEW.ZONE_ID, 
:NEW.CREATED_BY, 
:NEW.CREATION_DATE, 
:NEW.LAST_UPDATED_BY, 
:NEW.LAST_UPDATE_DATE, 
    'CREATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M, TB_RATES R WHERE M.MERCHANT_ID = R.MERCHANT_ID AND R.RATE_ID = :NEW.RATE_ID),
    SYSDATE);
END;
/