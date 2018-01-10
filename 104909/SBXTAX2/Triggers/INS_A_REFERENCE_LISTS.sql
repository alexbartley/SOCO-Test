CREATE OR REPLACE TRIGGER sbxtax2."INS_A_REFERENCE_LISTS" 
AFTER INSERT ON sbxtax2.TB_REFERENCE_LISTS
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
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
    'CREATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS WHERE MERCHANT_ID = :NEW.MERCHANT_ID),
    SYSDATE);
END;
/