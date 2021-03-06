CREATE OR REPLACE TRIGGER sbxtax3."INS_A_COMP_AREA_AUTHORITIES" 
AFTER INSERT ON sbxtax3.TB_COMP_AREA_AUTHORITIES
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
  INSERT INTO A_COMP_AREA_AUTHORITIES (
 AUTHORITY_ID,
COMPLIANCE_AREA_AUTH_ID,
COMPLIANCE_AREA_ID,
CREATED_BY,
CREATION_DATE,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
--SYNCHRONIZATION_TIMESTAMP,
CHANGE_TYPE,
--CHANGE_VERSION,
CHANGE_DATE
  ) VALUES (
 :NEW.AUTHORITY_ID,
:NEW.COMPLIANCE_AREA_AUTH_ID,
:NEW.COMPLIANCE_AREA_ID,
:NEW.CREATED_BY,
:NEW.CREATION_DATE,
:NEW.LAST_UPDATED_BY,
:NEW.LAST_UPDATE_DATE,
--:NEW.SYNCHRONIZATION_TIMESTAMP,
    'CREATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M, TB_AUTHORITIES A WHERE A.AUTHORITY_ID = :NEW.AUTHORITY_ID AND M.MERCHANT_ID = A.MERCHANT_ID),
    SYSDATE);

END;
/