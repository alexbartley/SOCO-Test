CREATE OR REPLACE PROCEDURE sbxtax2.CT_REP_AUTHPRODRULES
   ( filename IN VARCHAR2, taxDataProvider IN VARCHAR2, authKeyword IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    outputHeader VARCHAR2(4000) := 
    'Authority_Name,Effective_Rule_Order,Tax_Type,Rate_Code, Exempt, No_Tax, Commodity_Code, Product_Name,sort_key,';
    authTypeId NUMBER;
    zoneLevelId NUMBER;
    rateCode VARCHAR2(20);
    isExempt VARCHAR2(1);
    isNoTax VARCHAR2(1);
BEGIN
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');
    ct_analyze_product_taxability(taxDataProvider);

    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
        SELECT a.name Authority_Name, pt.effective_rule_order, pt.rate_code, NVL(pt.exempt,'N') is_exempt, NVL(pt.no_tax,'N') no_tax, 
            ts.prodcode commodity_Code, NVL(ts.product_name,'All Products') product_name, NVL(lt.description,'ANY') tax_type, ts.sort_key
        FROM tb_merchants m
        JOIN tb_authorities a ON (a.merchant_id = m.merchant_id AND a.name LIKE authKeyword||'%')
        JOIN pt_product_tree_sort ts ON (ts.merchant_id = a.merchant_id AND ts.product_group_id = a.product_group_id)
        LEFT OUTER JOIN pt_product_taxability pt ON (pt.authority_id = a.authority_id AND ts.primary_key = pt.primary_key)
        LEFT OUTER JOIN tb_lookups lt ON (lt.code_group LIKE '%TAX_TYPE' AND lt.code_group LIKE m.content_type||'%' AND lt.code = NVL(pt.tax_type,'ANY'))
        WHERE m.name = taxDataProvider
        ) LOOP
    --'Authority_Name,Effective_Rule_Order,Tax_Type,Rate_Code, Exempt, No_Tax, Commodity_Code, Product_Name,sort_key,'
        fileLine := 
            '"'||r.Authority_Name||'",'||
            '"'||r.effective_rule_order||'",'||
            '"'||r.tax_type||'",'||
            '"'||r.rate_code||'",'||
            '"'||r.is_exempt||'",'||
            '"'||r.no_tax||'",'||
            '="'||r.commodity_Code||'",'||
            '"'||r.product_name||'",'||
            '"'||r.sort_key||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_AUTHPRODRULES',SYSDATE,loggingMessage);
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