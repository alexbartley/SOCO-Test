CREATE OR REPLACE TRIGGER sbxtax2."UPD_A_REFERENCE_LISTS" 
AFTER UPDATE OF
MERCHANT_ID,
NAME,
DESCRIPTION,
START_DATE,
END_DATE
ON sbxtax2.TB_REFERENCE_LISTS
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
     WHEN (
(
decode(NEW.MERCHANT_ID,OLD.MERCHANT_ID,0,1) +
decode(NEW.NAME,OLD.NAME,0,1) +
decode(NEW.DESCRIPTION,OLD.DESCRIPTION,0,1) +
decode(NEW.START_DATE,OLD.START_DATE,0,1) +
decode(NEW.END_DATE,OLD.END_DATE,0,1)
) > 0
) BEGIN
  INSERT INTO A_REFERENCE_LISTS (
REFERENCE_LIST_ID,
MERCHANT_ID,
NAME,
DESCRIPTION,
START_DATE,
END_DATE,
CREATED_BY,
CREATION_DATE,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
--SYNCHRONIZATION_TIMESTAMP,
REFERENCE_LIST_ID_O,
MERCHANT_ID_O,
NAME_O,
DESCRIPTION_O,
START_DATE_O,
END_DATE_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
--SYNCHRONIZATION_TIMESTAMP_O,
CHANGE_TYPE,
--CHANGE_VERSION,
CHANGE_DATE
  ) VALUES (
:NEW.REFERENCE_LIST_ID,
:NEW.MERCHANT_ID,
:NEW.NAME,
:NEW.DESCRIPTION,
:NEW.START_DATE,
:NEW.END_DATE,
:NEW.CREATED_BY,
:NEW.CREATION_DATE,
:NEW.LAST_UPDATED_BY,
:NEW.LAST_UPDATE_DATE,
--:NEW.SYNCHRONIZATION_TIMESTAMP,
:OLD.REFERENCE_LIST_ID,
:OLD.MERCHANT_ID,
:OLD.NAME,
:OLD.DESCRIPTION,
:OLD.START_DATE,
:OLD.END_DATE,
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