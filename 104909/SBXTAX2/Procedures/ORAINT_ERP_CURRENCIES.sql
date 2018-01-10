CREATE OR REPLACE PROCEDURE sbxtax2.ORAINT_ERP_CURRENCIES(taxDataProvider IN VARCHAR2) IS

ftype utl_file.file_type;
contentType VARCHAR2(10);

BEGIN

SELECT content_type
INTO contentType
FROM tb_merchants
WHERE name = taxDataProvider;

ftype := UTL_FILE.fopen('C:\TEMP', contentType||'_sabrix_stage_config.dat', 'W');
UTL_FILE.put_line(ftype, '"CountryCode","CountryName","CurrencyCode","ExchangeRateType","ERPTaxCode","TaxDirection","OperatingUnitID","TaxRecoveryLiabilityO2C","TaxRecoveryLiabilityP2P","TaxExpense",');
    --sabrix_stage_config.dat
    --CountryCode,CountryName,CurrencyCode,ExchangeRateType,ERPTaxCode,TaxDirection,OperatingUnitID,TaxRecoveryLiabilityO2C,TaxRecoveryLiabilityP2P,TaxExpense,
    --Example: "AD","ANDORRA ","EUR","Corporate","ADIMI",
    
IF (contentType = 'INTL') THEN
    FOR c IN (
        SELECT DISTINCT '"'||ctry.code_2char||'","'||ctry.name||'","'||cc.alpha_code||'","Corporate","'||erp_tax_code||'",' line
        FROM tb_zones ctry, (
            SELECT CONNECT_BY_ROOT(zone_id) country_zone, zone_id, parent_zone_id, erp_tax_code, value
            FROM (  
                SELECT a.erp_tax_code, z.zone_id, z.parent_zone_id, z.zone_level_id , r.value
                FROM tb_authorities a, tb_zone_authorities za, tb_zones z, tb_merchants m, tb_authority_requirements r
                WHERE za.authority_id = a.authority_id
                AND z.zone_id = za.zone_id
                AND a.merchant_id = m.merchant_id
                AND m.name like 'Sabrix INTL%'
                AND a.merchant_id = z.merchant_id
                AND NVL(a.is_template,'N') = 'N'
                AND r.authority_id = a.authority_id
                AND r.merchant_id = a.merchant_id
                AND r.end_Date is null
                AND r.name = 'TOJ' 
                    )
                  z
          START WITH zone_level_id = -1
          CONNECT BY PRIOR zone_id = parent_zone_id    
           ) etc,
        ct_country_currencies cc
        WHERE ctry.zone_id = etc.country_zone
        AND cc.sabrix_country_zone = ctry.name
        AND cc.alpha_code IS NOT NULL
        and etc.value= 'N'
        and ctry.code_2char is not NULL
        order by line
    ) LOOP
    UTL_FILE.put_line(ftype, c.line);
    END LOOP;
ELSE
    FOR c IN (
        SELECT DISTINCT '"US","UNITED STATES","USD","Corporate","'||erp_tax_code||'",' line
        FROM tb_authorities a, tb_merchants m
        WHERE m.merchant_id = a.merchant_id
        AND m.name = taxDataProvider
        AND NVL(a.is_template,'N') = 'N'
        AND EXISTS (
            SELECT 1
            FROM tb_authority_requirements r
            WHERE r.authority_id = a.authority_id
            AND r.merchant_id = a.merchant_id
            AND r.end_Date is null
            AND r.name = 'TOJ'
            and r.value = 'N'
            )
    ) LOOP
    UTL_FILE.put_line(ftype, c.line);
    END LOOP;
END IF;
UTL_FILE.fflush(ftype);
UTL_FILE.fclose(ftype);
END ORAINT_ERP_CURRENCIES;
/