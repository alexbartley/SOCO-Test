CREATE OR REPLACE TRIGGER sbxtax2."DATAX_CO_UPDATE_TR" 
 BEFORE
  UPDATE
 ON sbxtax2.datax_check_output
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    :new.last_update_date := SYSDATE;
    --IF the REVIEWED_APPROVED value has changed set the APPROVED_DATE to LAST_UPDATE_DATE
    IF (NVL(:new.reviewed_approved,-1) !=  NVL(:old.reviewed_approved,-1)) THEN
        :new.approved_Date := :new.last_update_date;
    END IF;
    --IF the REVIEWED_APPROVED value has not been set or has been removed, set the APPROVED_DATE to NULL
    IF (:new.reviewed_approved IS NULL) THEN
        :new.approved_Date := NULL;
    END IF;
    --IF the VERIFIED value has changed set the APPROVED_DATE to LAST_UPDATE_DATE
    IF (NVL(:new.verified,-1) !=  NVL(:old.verified,-1)) THEN
        :new.verified_date := :new.last_update_date;
    END IF;
    --IF the VERIFIED value has not been set or has been removed, set the APPROVED_DATE to NULL
    IF (:new.verified IS NULL) THEN
        :new.approved_Date := NULL;
    END IF;
END;
/