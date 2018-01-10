CREATE OR REPLACE TRIGGER sbxtax2."INS_A_AUTHORITY_REQUIREMENTS" 
AFTER INSERT ON sbxtax2.TB_AUTHORITY_REQUIREMENTS
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
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
    'CREATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS WHERE MERCHANT_ID = :NEW.MERCHANT_ID),
    SYSDATE);
END;
/