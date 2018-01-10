CREATE OR REPLACE TRIGGER sbxtax."INS_A_CONTRIBUTING_AUTHORITIES"
AFTER INSERT ON sbxtax.TB_CONTRIBUTING_AUTHORITIES
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
BEGIN
  INSERT INTO A_CONTRIBUTING_AUTHORITIES (
CONTRIBUTING_AUTHORITY_ID,
MERCHANT_ID,
AUTHORITY_ID,
THIS_AUTHORITY_ID,
BASIS_PERCENT,
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
:NEW.CONTRIBUTING_AUTHORITY_ID,
:NEW.MERCHANT_ID,
:NEW.AUTHORITY_ID,
:NEW.THIS_AUTHORITY_ID,
:NEW.BASIS_PERCENT,
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