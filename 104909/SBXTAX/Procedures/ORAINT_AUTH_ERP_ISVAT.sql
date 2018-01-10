CREATE OR REPLACE PROCEDURE sbxtax."ORAINT_AUTH_ERP_ISVAT" (taxDataProvider IN VARCHAR2) is

ftype utl_file.file_type;
contentType VARCHAR2(10);

BEGIN

SELECT content_type
INTO contentType
FROM tb_merchants
WHERE name = taxDataProvider;

ftype := UTL_FILE.fopen('C:\TEMP', contentType||'_sabrix_stage_authorities.dat', 'W');
UTL_FILE.put_line(ftype, '"UUID","ERPTaxCode","AuthorityName","IsVAT","IsCustomAuthority","LastUpdateDate","ContentType","MerchantID","AuthorityType"');
--sabrix_stage_authorities.dat
--UUID,ERPTaxCode,AuthorityName,IsVAT,IsCustomAuthority,LastUpdateDate,ContentType,MerchantID,AuthorityType
--Example: "4fbbe3d5-0e96-4d6e-a01b-d011a17c370d","USCO","CO - TWIN LAKES, LAKE COUNTY SALES TAX","N","N","07-Jan-2010","US",103,"County Sales/Use"

IF (contentType = 'INTL') THEN
    FOR c IN (
        SELECT '"'||a.uuid||'","'||a.erp_tax_code||'","'||a.name||'","'||NVL(ab.is_bidirectional,'N')||'","N","'||
            to_char(a.last_update_date,'dd-Mon-yyyy')||'","'||a.content_type||'","'||m.name||'","'||aty.name||'"' line
        FROM tb_authorities a
        JOIN tb_merchants m ON (m.merchant_id = a.merchant_id)
        LEFT OUTER JOIN ct_authority_bidirectionality ab ON (ab.authority_uuid = a.uuid)
        JOIN tb_authority_types aty ON (aty.authority_type_id = a.authority_type_id)
        JOIN tb_authority_requirements ar ON (ar.authority_id = a.authority_id AND a.merchant_id = ar.merchant_id AND ar.name = 'TOJ')
        WHERE m.name = taxDataProvider
        AND NVL(a.is_template,'N') = 'N'
        AND NVL(ar.value,'N') = 'N'
        AND ar.end_date IS NULL
    ) LOOP
        UTL_FILE.put_line(ftype, c.line);
    END LOOP;
ELSE
    FOR c IN (
        SELECT '"'||a.uuid||'","'||a.erp_tax_code||'","'||a.name||'","N","N","'||
            TO_CHAR(a.last_update_date,'dd-Mon-yyyy')||'","'||a.content_type||'","'||m.name||'","'||aty.name||'"' line
        FROM tb_authorities a
        JOIN tb_merchants m ON (m.merchant_id = a.merchant_id)
        JOIN tb_authority_types aty ON (aty.authority_type_id = a.authority_type_id)
        JOIN tb_authority_requirements ar ON (ar.authority_id = a.authority_id AND a.merchant_id = ar.merchant_id AND ar.name = 'TOJ')
        WHERE m.name = taxDataProvider
        AND NVL(a.is_template,'N') = 'N'
        AND NVL(ar.value,'N') = 'N'
        AND ar.end_date IS NULL
    ) LOOP
        UTL_FILE.put_line(ftype, c.line);
    END LOOP;
END IF;
UTL_FILE.fflush(ftype);
UTL_FILE.fclose(ftype);
END;


 
 
/