CREATE OR REPLACE TRIGGER sbxtax3."DT_APP_ERRORS_BEFORE_INSERT" 
 BEFORE
  INSERT
 ON sbxtax3.tb_app_errors
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DISABLE DECLARE

    v_merchant_name VARCHAR2(200);
    ASM_OVERRIDE_DISALLOWED EXCEPTION;
BEGIN
    SELECT m.name
    INTO v_merchant_name
    FROM tb_merchants m
    WHERE m.merchant_id = :NEW.merchant_id;

    IF (v_merchant_name IN ('Sabrix Canada Tax Data','Sabrix INTL Tax Data','QA001','Administration')) THEN
        RAISE ASM_OVERRIDE_DISALLOWED;
    ELSE
        v_merchant_name := null;
    END IF;
    
    EXCEPTION WHEN ASM_OVERRIDE_DISALLOWED THEN
        raise_application_error(-20001, 'ASMs must not be created under this company, please use a different company or submit a Jira to QAE.');
END dt_app_errors_before_insert;
/