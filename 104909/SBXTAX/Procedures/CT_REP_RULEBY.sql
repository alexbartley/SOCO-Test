CREATE OR REPLACE PROCEDURE sbxtax."CT_REP_RULEBY"
   ( filename IN VARCHAR2, taxDataProvider IN VARCHAR2, taxApplicability IN VARCHAR2, authKeyword IN VARCHAR2, commodityCode IN VARCHAR2, taxCode IN VARCHAR2, ruleDate IN DATE)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    outputHeader VARCHAR2(4000) :=
    'Authority_Name,Rule_Order,Start_Date, End_Date, Rate_Code, Exempt, No_Tax, Commodity_Code, Product_Name,'||
    'Tax_Type, Calculation_Method, Invoice_Description, Basis_Percent, Cascading, Tax_Code, Input_Recovery_Amount, Input_Recovery_Percent,';
    authTypeId NUMBER;
    zoneLevelId NUMBER;
    rateCode VARCHAR2(20);
    isExempt VARCHAR2(1);
    isNoTax VARCHAR2(1);
BEGIN
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');
    IF (taxApplicability = 'EXEMPT') THEN
        isExempt := 'Y';
    ELSIF (taxApplicability = 'NO_TAX') THEN
        isNoTax := 'Y';
    ELSE
        rateCode := taxApplicability;
    END IF;

    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
        SELECT a.name Authority_Name, r.rule_order, r.start_date, r.end_Date, r.rate_code, NVL(r.exempt,'N') is_exempt, NVL(r.no_tax,'N') no_tax,
            pc.prodcode commodity_Code, NVL(pc.name,'All Products') product_name, NVL(lt.description,'ANY') tax_type, lc.description calculation_method,
            r.invoice_Description, r.basis_percent*100 basis_percent, NVL(r.is_local,'N') cascading, r.Code tax_code, input_recovery_amount,
            CASE WHEN input_recovery_percent IS NOT NULL THEN input_recovery_percent*100 END input_recovery_percent
        FROM tb_merchants m
        JOIN tb_authorities a ON (a.merchant_id = m.merchant_id)
        JOIN tb_Rules r ON (r.authority_id = a.authority_id AND r.merchant_id = a.merchant_id)
        JOIN tb_lookups lc ON (lc.code_group = 'TBI_CALC_METH' AND lc.code = r.calculation_method)
        LEFT OUTER JOIN tb_lookups lt ON (lt.code_group LIKE '%TAX_TYPE' AND lt.code_group LIKE m.content_type||'%' AND lt.code = NVL(r.tax_type,'ANY'))
        LEFT OUTER JOIN tb_product_categories pc ON (r.product_Category_id = pc.product_Category_id)
        WHERE a.name LIKE authKeyword||'%'
        AND m.name = taxDataProvider
        AND COALESCE(r.rate_code,'NULL') LIKE COALESCE(rateCode,r.rate_code,'NULL')||'%'
        AND COALESCE(r.exempt,'N') = COALESCE(isExempt,r.exempt,'N')
        AND COALESCE(r.no_tax,'N') = COALESCE(isNoTax,r.no_tax,'N')
        AND COALESCE(r.code,'N/A') = COALESCE(taxCode,r.code,'N/A')
        AND COALESCE(r.end_Date,TO_DATE(ruleDate),SYSDATE+1) >= NVL(ruleDate,SYSDATE)
        ) LOOP
    --'Authority_Name,Rule_Order,Start_Date, Rate_Code, Exempt, No_Tax, Commodity_Code, Product_Name,'||
    --'Tax_Type, Calculation_Method, Invoice_Description, Basis_Percent, Cascading, Tax_Code, Input_Recovery_Amount, Input_Recovery_Percent,';
        fileLine :=
            '"'||r.Authority_Name||'",'||
            '"'||r.rule_order||'",'||
            '"'||r.start_date||'",'||
            '"'||r.end_date||'",'||
            '"'||r.rate_code||'",'||
            '"'||r.is_exempt||'",'||
            '"'||r.no_tax||'",'||
            '="'||r.commodity_Code||'",'||
            '"'||r.product_name||'",'||
            '"'||r.tax_type||'",'||
            '"'||r.calculation_method||'",'||
            '"'||r.invoice_description||'",'||
            '"'||r.basis_percent||'",'||
            '"'||r.cascading||'",'||
            '"'||r.tax_code||'",'||
            '"'||r.input_recovery_amount||'",'||
            '"'||r.input_recovery_percent||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_RULEBY',SYSDATE,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W',32000);
    UTL_FILE.put_line(ftype,'Report did not finish properly because Oracle encountered an error.');
    UTL_FILE.put_line(ftype,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED BUT FAILED');
END; -- Procedure


 
 
/