CREATE OR REPLACE TRIGGER sbxtax2.DT_APP_ERRORS_BEFORE_INSERT 
 BEFORE 
 INSERT
 ON sbxtax2.TB_APP_ERRORS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DISABLE DECLARE

    v_merchant_name VARCHAR2(200);
    ASM_OVERRIDE_DISALLOWED EXCEPTION;
BEGIN
    --06/17/2016 Steve Martindale
    --I am not sure why this was created, but after talking with Anil we have decided to disable it as is impeding INTL Contents ability to get their job done.
    
    SELECT m.name
    INTO v_merchant_name
    FROM tb_merchants m
    WHERE m.merchant_id = :NEW.merchant_id;

    IF (:NEW.authority_id != -1 AND v_merchant_name IN ('Sabrix Canada Tax Data','Sabrix INTL Tax Data','QA001')) THEN
        RAISE ASM_OVERRIDE_DISALLOWED;
    ELSE
        v_merchant_name := null;
    
    END IF;
    
    EXCEPTION WHEN ASM_OVERRIDE_DISALLOWED THEN
        raise_application_error(-20001, 'ASMs must not be created under this company, please use a different company or submit a Jira to QAE.');
    
END dt_app_errors_before_insert;
/