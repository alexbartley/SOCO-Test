CREATE OR REPLACE TRIGGER sbxtax3."UPD_A_AUTHORITY_REQUIREMENTS" 
AFTER UPDATE OF
  NAME,
  START_DATE,
  END_DATE,
  CONDITION,
  VALUE,
  AUTHORITY_ID,
  MERCHANT_ID
ON sbxtax3.TB_AUTHORITY_REQUIREMENTS
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
     WHEN (
(
decode(NEW.AUTHORITY_REQUIREMENT_ID,OLD.AUTHORITY_REQUIREMENT_ID,0,1) +
decode(NEW.NAME,OLD.NAME,0,1) +
decode(NEW.START_DATE,OLD.START_DATE,0,1) +
decode(NEW.END_DATE,OLD.END_DATE,0,1) +
decode(NEW.CONDITION,OLD.CONDITION,0,1) +
decode(NEW.VALUE,OLD.VALUE,0,1) +
decode(NEW.AUTHORITY_ID,OLD.AUTHORITY_ID,0,1) +
decode(NEW.MERCHANT_ID,OLD.MERCHANT_ID,0,1)
) > 0
) BEGIN
  INSERT INTO A_AUTHORITY_REQUIREMENTS (
  AUTHORITY_REQUIREMENT_ID,
NAME,
START_DATE,
END_DATE,
CONDITION,
VALUE,
AUTHORITY_ID,
MERCHANT_ID,
CREATED_BY,
CREATION_DATE,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
--SYNCHRONIZATION_TIMESTAMP,
AUTHORITY_REQUIREMENT_ID_O,
NAME_O,
START_DATE_O,
END_DATE_O,
CONDITION_O,
VALUE_O,
AUTHORITY_ID_O,
MERCHANT_ID_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
--SYNCHRONIZATION_TIMESTAMP_O,
CHANGE_TYPE,
--CHANGE_VERSION,
CHANGE_DATE
  ) VALUES (
:NEW.AUTHORITY_REQUIREMENT_ID,
:NEW.NAME,
:NEW.START_DATE,
:NEW.END_DATE,
:NEW.CONDITION,
:NEW.VALUE,
:NEW.AUTHORITY_ID,
:NEW.MERCHANT_ID,
:NEW.CREATED_BY,
:NEW.CREATION_DATE,
:NEW.LAST_UPDATED_BY,
:NEW.LAST_UPDATE_DATE,
--:NEW.SYNCHRONIZATION_TIMESTAMP,
:OLD.AUTHORITY_REQUIREMENT_ID,
:OLD.NAME,
:OLD.START_DATE,
:OLD.END_DATE,
:OLD.CONDITION,
:OLD.VALUE,
:OLD.AUTHORITY_ID,
:OLD.MERCHANT_ID,
:OLD.CREATED_BY,
:OLD.CREATION_DATE,
:OLD.LAST_UPDATED_BY,
:OLD.LAST_UPDATE_DATE,
--:OLD.SYNCHRONIZATION_TIMESTAMP,
    'UPDATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS WHERE MERCHANT_ID = :NEW.MERCHANT_ID),
    SYSDATE);
END;
/