CREATE OR REPLACE TRIGGER sbxtax2."UPD_A_RULES" 
AFTER UPDATE OF
RULE_ORDER,
AUTH_REPORT_GROUP_ID,
ACTIVE,
PRODUCT_CATEGORY_ID,
MERCHANT_ID,
AUTHORITY_ID,
CODE,
EXEMPT_REASON_CODE,
CALCULATION_METHOD,
INVOICE_DESCRIPTION,
EXEMPT,
START_DATE,
END_DATE,
DELETED
ON sbxtax2.TB_RULES 
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
     WHEN (
(
decode(NEW.RULE_ORDER,OLD.RULE_ORDER,0,1) +
decode(NEW.AUTH_REPORT_GROUP_ID,OLD.AUTH_REPORT_GROUP_ID,0,1) +
decode(NEW.ACTIVE,OLD.ACTIVE,0,1) +
decode(NEW.PRODUCT_CATEGORY_ID,OLD.PRODUCT_CATEGORY_ID,0,1) +
decode(NEW.MERCHANT_ID,OLD.MERCHANT_ID,0,1) +
decode(NEW.AUTHORITY_ID,OLD.AUTHORITY_ID,0,1) +
decode(NEW.CODE,OLD.CODE,0,1) +
decode(NEW.EXEMPT_REASON_CODE,OLD.EXEMPT_REASON_CODE,0,1) +
decode(NEW.CALCULATION_METHOD,OLD.CALCULATION_METHOD,0,1) +
decode(NEW.INVOICE_DESCRIPTION,OLD.INVOICE_DESCRIPTION,0,1) +
decode(NEW.EXEMPT,OLD.EXEMPT,0,1) +
decode(NEW.START_DATE,OLD.START_DATE,0,1) +
decode(NEW.END_DATE,OLD.END_DATE,0,1) +
decode(NEW.DELETED,OLD.DELETED,0,1) +
decode(NEW.RATE_CODE,OLD.RATE_CODE,0,1) +
decode(NEW.BASIS_PERCENT,OLD.BASIS_PERCENT,0,1) +
decode(NEW.RULE_COMMENT,OLD.RULE_COMMENT,0,1) +
decode(NEW.TAX_TYPE,OLD.TAX_TYPE,0,1) +
decode(NEW.IS_LOCAL,OLD.IS_LOCAL,0,1) +
decode(NEW.LOCAL_AUTHORITY_TYPE_ID,OLD.LOCAL_AUTHORITY_TYPE_ID,0,1) +
decode(NEW.INPUT_RECOVERY_AMOUNT,OLD.INPUT_RECOVERY_AMOUNT,0,1) +
decode(NEW.INPUT_RECOVERY_PERCENT,OLD.INPUT_RECOVERY_PERCENT,0,1) +
decode(NEW.UNIT_OF_MEASURE,OLD.UNIT_OF_MEASURE,0,1) +
decode(NEW.NO_TAX,OLD.NO_TAX,0,1) +
decode(NEW.REPORTING_CATEGORY,OLD.REPORTING_CATEGORY,0,1) +
decode(NEW.TAX_TREATMENT,OLD.TAX_TREATMENT,0,1) +
decode(NEW.IS_DEPENDENT_PRODUCT,OLD.IS_DEPENDENT_PRODUCT,0,1) +
decode(NEW.MATERIAL_SET_LIST_ID,OLD.MATERIAL_SET_LIST_ID,0,1) +
decode(NEW.AUTHORITY_RATE_SET_ID,OLD.AUTHORITY_RATE_SET_ID,0,1)
) > 0
) BEGIN
  INSERT INTO A_RULES (
RULE_ID,
RULE_ORDER,
AUTH_REPORT_GROUP_ID,
ACTIVE,
PRODUCT_CATEGORY_ID,
MERCHANT_ID,
AUTHORITY_ID,
CODE,
EXEMPT_REASON_CODE,
CALCULATION_METHOD,
INVOICE_DESCRIPTION,
EXEMPT,
START_DATE,
END_DATE,
DELETED,
CREATED_BY,
CREATION_DATE,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
--SYNCHRONIZATION_TIMESTAMP,
RATE_CODE,
BASIS_PERCENT,
RULE_COMMENT,
TAX_TYPE,
IS_LOCAL,
LOCAL_AUTHORITY_TYPE_ID,
INPUT_RECOVERY_AMOUNT,
INPUT_RECOVERY_PERCENT,
UNIT_OF_MEASURE,
NO_TAX,
REPORTING_CATEGORY,
TAX_TREATMENT,
IS_DEPENDENT_PRODUCT,
MATERIAL_SET_LIST_ID,
AUTHORITY_RATE_SET_ID,
RULE_ID_O,
RULE_ORDER_O,
AUTH_REPORT_GROUP_ID_O,
ACTIVE_O,
PRODUCT_CATEGORY_ID_O,
MERCHANT_ID_O,
AUTHORITY_ID_O,
CODE_O,
EXEMPT_REASON_CODE_O,
CALCULATION_METHOD_O,
INVOICE_DESCRIPTION_O,
EXEMPT_O,
START_DATE_O,
END_DATE_O,
DELETED_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
--SYNCHRONIZATION_TIMESTAMP_O,
RATE_CODE_O,
BASIS_PERCENT_O,
RULE_COMMENT_O,
TAX_TYPE_O,
IS_LOCAL_O,
LOCAL_AUTHORITY_TYPE_ID_O,
INPUT_RECOVERY_AMOUNT_O,
INPUT_RECOVERY_PERCENT_O,
UNIT_OF_MEASURE_O,
NO_TAX_O,
REPORTING_CATEGORY_O,
TAX_TREATMENT_O,
IS_DEPENDENT_PRODUCT_O,
MATERIAL_SET_LIST_ID_O,
AUTHORITY_RATE_SET_ID_O,
CHANGE_TYPE,
--CHANGE_VERSION,
CHANGE_DATE
  ) VALUES (
:NEW.RULE_ID,
:NEW.RULE_ORDER,
:NEW.AUTH_REPORT_GROUP_ID,
:NEW.ACTIVE,
:NEW.PRODUCT_CATEGORY_ID,
:NEW.MERCHANT_ID,
:NEW.AUTHORITY_ID,
:NEW.CODE,
:NEW.EXEMPT_REASON_CODE,
:NEW.CALCULATION_METHOD,
:NEW.INVOICE_DESCRIPTION,
:NEW.EXEMPT,
:NEW.START_DATE,
:NEW.END_DATE,
:NEW.DELETED,
:NEW.CREATED_BY,
:NEW.CREATION_DATE,
:NEW.LAST_UPDATED_BY,
:NEW.LAST_UPDATE_DATE,
--:NEW.SYNCHRONIZATION_TIMESTAMP,
:NEW.RATE_CODE,
:NEW.BASIS_PERCENT,
:NEW.RULE_COMMENT,
:NEW.TAX_TYPE,
:NEW.IS_LOCAL,
:NEW.LOCAL_AUTHORITY_TYPE_ID,
:NEW.INPUT_RECOVERY_AMOUNT,
:NEW.INPUT_RECOVERY_PERCENT,
:NEW.UNIT_OF_MEASURE,
:NEW.NO_TAX,
:NEW.REPORTING_CATEGORY,
:NEW.TAX_TREATMENT,
:NEW.IS_DEPENDENT_PRODUCT,
:NEW.MATERIAL_SET_LIST_ID,
:NEW.AUTHORITY_RATE_SET_ID,
:OLD.RULE_ID,
:OLD.RULE_ORDER,
:OLD.AUTH_REPORT_GROUP_ID,
:OLD.ACTIVE,
:OLD.PRODUCT_CATEGORY_ID,
:OLD.MERCHANT_ID,
:OLD.AUTHORITY_ID,
:OLD.CODE,
:OLD.EXEMPT_REASON_CODE,
:OLD.CALCULATION_METHOD,
:OLD.INVOICE_DESCRIPTION,
:OLD.EXEMPT,
:OLD.START_DATE,
:OLD.END_DATE,
:OLD.DELETED,
:OLD.CREATED_BY,
:OLD.CREATION_DATE,
:OLD.LAST_UPDATED_BY,
:OLD.LAST_UPDATE_DATE,
--:OLD.SYNCHRONIZATION_TIMESTAMP,
:OLD.RATE_CODE,
:OLD.BASIS_PERCENT,
:OLD.RULE_COMMENT,
:OLD.TAX_TYPE,
:OLD.IS_LOCAL,
:OLD.LOCAL_AUTHORITY_TYPE_ID,
:OLD.INPUT_RECOVERY_AMOUNT,
:OLD.INPUT_RECOVERY_PERCENT,
:OLD.UNIT_OF_MEASURE,
:OLD.NO_TAX,
:OLD.REPORTING_CATEGORY,
:OLD.TAX_TREATMENT,
:OLD.IS_DEPENDENT_PRODUCT,
:OLD.MATERIAL_SET_LIST_ID,
:OLD.AUTHORITY_RATE_SET_ID,
    'UPDATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS WHERE MERCHANT_ID = :NEW.MERCHANT_ID),
    SYSDATE);
END;
/