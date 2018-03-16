CREATE OR REPLACE TRIGGER sbxtax3."UPD_A_COMPLIANCE_AREAS" 
AFTER UPDATE of
NAME,
COMPLIANCE_AREA_UUID,
EFFECTIVE_ZONE_LEVEL_ID,
ASSOCIATED_AREA_COUNT,
MERCHANT_ID,
START_DATE,
END_DATE on sbxtax3.TB_COMPLIANCE_AREAS
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
     WHEN (
  ( decode(NEW.NAME,OLD.NAME,0,1) +
decode(NEW.COMPLIANCE_AREA_UUID,OLD.COMPLIANCE_AREA_UUID,0,1) +
decode(NEW.EFFECTIVE_ZONE_LEVEL_ID,OLD.EFFECTIVE_ZONE_LEVEL_ID,0,1) +
decode(NEW.ASSOCIATED_AREA_COUNT,OLD.ASSOCIATED_AREA_COUNT,0,1) +
decode(NEW.MERCHANT_ID,OLD.MERCHANT_ID,0,1) +
decode(NEW.START_DATE,OLD.START_DATE,0,1) +
decode(NEW.END_DATE,OLD.END_DATE,0,1) 
  ) > 0 

) BEGIN


  INSERT INTO A_COMPLIANCE_AREAS (
 COMPLIANCE_AREA_ID,
NAME,
COMPLIANCE_AREA_UUID,
EFFECTIVE_ZONE_LEVEL_ID,
ASSOCIATED_AREA_COUNT,
MERCHANT_ID,
CREATED_BY,
CREATION_DATE,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
START_DATE,
END_DATE,
 COMPLIANCE_AREA_ID_O,
NAME_O,
COMPLIANCE_AREA_UUID_O,
EFFECTIVE_ZONE_LEVEL_ID_O,
ASSOCIATED_AREA_COUNT_O,
MERCHANT_ID_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
START_DATE_O,
END_DATE_O,
    CHANGE_TYPE,
    --CHANGE_VERSION,
    CHANGE_DATE
  ) VALUES (
 :NEW.COMPLIANCE_AREA_ID,
:NEW.NAME,
:NEW.COMPLIANCE_AREA_UUID,
:NEW.EFFECTIVE_ZONE_LEVEL_ID,
:NEW.ASSOCIATED_AREA_COUNT,
:NEW.MERCHANT_ID,
:NEW.CREATED_BY,
:NEW.CREATION_DATE,
:NEW.LAST_UPDATED_BY,
:NEW.LAST_UPDATE_DATE,
:NEW.START_DATE,
:NEW.END_DATE,

 :OLD.COMPLIANCE_AREA_ID,
:OLD.NAME,
:OLD.COMPLIANCE_AREA_UUID,
:OLD.EFFECTIVE_ZONE_LEVEL_ID,
:OLD.ASSOCIATED_AREA_COUNT,
:OLD.MERCHANT_ID,
:OLD.CREATED_BY,
:OLD.CREATION_DATE,
:OLD.LAST_UPDATED_BY,
:OLD.LAST_UPDATE_DATE,
:OLD.START_DATE,
:OLD.END_DATE,
    'UPDATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS WHERE MERCHANT_ID = :NEW.MERCHANT_ID),
    SYSDATE);

END;
/