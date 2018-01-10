CREATE OR REPLACE TRIGGER sbxtax2."DEL_A_REFERENCE_LISTS" 
BEFORE DELETE ON sbxtax2.TB_REFERENCE_LISTS
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
  INSERT INTO A_REFERENCE_LISTS (
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
    'DELETED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS WHERE MERCHANT_ID = :OLD.MERCHANT_ID),
    SYSDATE);
END;
/