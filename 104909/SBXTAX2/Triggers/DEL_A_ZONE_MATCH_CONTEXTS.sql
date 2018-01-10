CREATE OR REPLACE TRIGGER sbxtax2."DEL_A_ZONE_MATCH_CONTEXTS" 
BEFORE DELETE ON sbxtax2.TB_ZONE_MATCH_CONTEXTS
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
  INSERT INTO A_ZONE_MATCH_CONTEXTS (
ZONE_MATCH_CONTEXT_ID_O, 
ZONE_MATCH_PATTERN_ID_O, 
ZONE_LEVEL_ID_O, 
ZONE_ID_O, 
CREATED_BY_O, 
CREATION_DATE_O, 
LAST_UPDATED_BY_O, 
LAST_UPDATE_DATE_O, 
CHANGE_TYPE , 
CHANGE_DATE
  ) VALUES (
:OLD.ZONE_MATCH_CONTEXT_ID, 
:OLD.ZONE_MATCH_PATTERN_ID, 
:OLD.ZONE_LEVEL_ID, 
:OLD.ZONE_ID, 
:OLD.CREATED_BY, 
:OLD.CREATION_DATE, 
:OLD.LAST_UPDATED_BY, 
:OLD.LAST_UPDATE_DATE, 
    'DELETED',
    SYSDATE);
END;
/