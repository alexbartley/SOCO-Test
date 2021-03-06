CREATE OR REPLACE TRIGGER sbxtax."INS_A_REFERENCE_VALUES"
AFTER INSERT ON sbxtax.TB_REFERENCE_VALUES
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
BEGIN
  INSERT INTO A_REFERENCE_VALUES (
REFERENCE_VALUE_ID,
REFERENCE_LIST_ID,
VALUE,
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
:NEW.REFERENCE_VALUE_ID,
:NEW.REFERENCE_LIST_ID,
:NEW.VALUE,
:NEW.START_DATE,
:NEW.END_DATE,
:NEW.CREATED_BY,
:NEW.CREATION_DATE,
:NEW.LAST_UPDATED_BY,
:NEW.LAST_UPDATE_DATE,
--:NEW.SYNCHRONIZATION_TIMESTAMP,
    'CREATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M, TB_REFERENCE_LISTS RL WHERE M.MERCHANT_ID = RL.MERCHANT_ID AND RL.REFERENCE_LIST_ID = :NEW.REFERENCE_LIST_ID),
    SYSDATE);
END;
/