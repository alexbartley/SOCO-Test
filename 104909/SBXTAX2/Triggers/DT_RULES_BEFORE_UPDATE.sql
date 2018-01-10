CREATE OR REPLACE TRIGGER sbxtax2."DT_RULES_BEFORE_UPDATE" 
 BEFORE 
 UPDATE
 ON sbxtax2.TB_RULES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
    WHEN ((NEW.rule_comment IS NULL
OR NEW.rule_comment NOT LIKE '%ORACLE[%]%')
OR (NEW.invoice_description IS NULL)
) DECLARE
    v_erp_code varchar2(50) := NULL;
    v_authority_type varchar2(50) := NULL;
    v_authority_name varchar2(100) := NULL;
    v_prod_name varchar2(100) := '';
    v_state_code varchar2(2) := NULL;
    v_rate_code varchar2(50) := NULL;
    v_rate_desc varchar2(100) := NULL;
    v_merchant_name varchar2(50) := 'XYZ';
    v_rate number(31,10) := 0;
    v_standard_rate number(31,10) := 0;

BEGIN
    SELECT m.name
    INTO v_merchant_name
    FROM tb_merchants m
    WHERE m.merchant_id = :NEW.merchant_id;

    IF (v_merchant_name = 'Sabrix US Tax Data') THEN
        /*
        --no need to populate rule comment anymore because integrations no longer depend on it 09/24/2014
        --set rule comment
        SELECT substr(a.name, 0, 2)
        INTO v_state_code
        FROM tb_authorities a
        WHERE a.authority_id = :NEW.authority_id;

        
        :NEW.rule_comment := 'ORACLE[US'||v_state_code||']';
        */
        --set invoice description
        IF (nvl(:NEW.exempt,'N') = 'Y') THEN
            :NEW.invoice_description := 'Exempt';
        ELSIF (nvl(:NEW.no_tax,'N') = 'Y') THEN
            :NEW.invoice_description := 'No Tax';
        ELSE
            v_rate_code := :NEW.rate_code;
            SELECT CASE
                    WHEN (v_rate_code = 'CU') THEN 'Consumer''s Use Tax'
                    WHEN (v_rate_code = 'SU') THEN 'Seller''s Use Tax'
                    WHEN (v_rate_code = 'ST') THEN 'Sales Tax'
                    WHEN (v_rate_code LIKE 'AP%') THEN 'Apparel ? Partial Exemption'
                    WHEN (v_rate_code LIKE 'GR%') THEN 'Food Rate' ELSE v_rate_code END
            INTO v_rate_desc
            FROM dual;
            :NEW.invoice_description := v_rate_desc;
        END IF;


    ELSIF (v_merchant_name = 'Sabrix INTL Tax Data' OR v_merchant_name = 'Sabrix Canada Tax Data' ) THEN

        SELECT nvl(a.erp_tax_code,''), aty.name --check for No Vat
        INTO v_erp_code, v_authority_type
        FROM tb_authorities a, tb_authority_types aty
        WHERE a.authority_id = :NEW.authority_id
        and a.authority_type_id = aty.authority_type_id;

        /*
        --no need to populate rule comment anymore because integrations no longer depend on it 09/24/2014
        --set rule comment
        :NEW.rule_comment := 'ORACLE['||v_erp_code||']';
        */
        --set invoice description
        --SELECT this.rate, standard_rate.rate
        --INTO v_rate, v_standard_rate
        --FROM tb_rates this, tb_rates standard_rate
        --WHERE this.rate_code = :NEW.rate_code
        --AND this.authority_id = :NEW.authority_id
        --AND nvl(this.end_date, '31-dec-9999') > sysdate
        --AND standard_rate.authority_id = this.authority_id
        --AND standard_rate.rate_code = 'SR';

        v_rate_code := nvl(:NEW.rate_code,'EXEMPT='||nvl(:NEW.exempt,'N'));

        IF (v_rate_code NOT LIKE 'EXEMPT%') THEN
            SELECT rate, standard_rate
            INTO v_rate, v_standard_rate
            FROM (
                    SELECT this.rate, NVL(standard_rate.rate,this.rate) standard_rate
                    FROM tb_rates this
                    LEFT OUTER JOIN tb_rates standard_rate ON (standard_rate.authority_id = :NEW.authority_id AND standard_rate.rate_code = 'SR')
                    WHERE this.rate_code = :NEW.rate_code
                    AND this.authority_id = :NEW.authority_id
                    AND nvl(standard_rate.end_date, '31-dec-9999') > sysdate
                    AND nvl(this.end_date, '31-dec-9999') = (
                        SELECT nvl(max(end_Date),'31-dec-9999')
                        FROM tb_rates
                        WHERE authority_id = this.authority_id
                        AND rate_code = this.rate_Code
                        )
                    ORDER BY nvl(standard_rate.end_date, '31-dec-9999') DESC, nvl(this.end_date, '31-dec-9999') DESC
                    )
            WHERE rownum = 1;
        END IF;
        select name into v_authority_name from tb_authorities
            where authority_id = :NEW.authority_id;
        IF (v_authority_name not like 'Brazil%') THEN
            IF (:NEW.rule_order = 10000 AND v_rate_code != 'NV') THEN
                :NEW.invoice_description := v_authority_type;
            ELSIF (:NEW.rule_order = 10000 AND v_rate_code = 'NV') THEN
                :NEW.invoice_description := 'No VAT';
            ELSE
                SELECT CASE WHEN (v_rate_code = 'EXEMPT=Y') THEN 'Exempt'
                    WHEN (v_rate_code = 'EXEMPT=N') THEN 'No Tax'
                    WHEN (v_rate_code = 'RR') THEN 'Reduced Rated'
                    WHEN (v_rate_code = 'SR') THEN 'Standard Rated'
                    WHEN (v_rate_code = 'IR') THEN 'Increased Rated'
                    WHEN (v_rate_code = 'SRR') THEN 'Super Reduced Rated'
                    WHEN (v_rate_code = 'ZR') THEN 'Zero Rated'
                    WHEN (v_rate_code = 'INT') THEN 'Intermediate Rated'
                    WHEN (v_rate_code = 'NL') THEN 'Not Liable'
                    WHEN (v_rate_code = 'NV') THEN 'No VAT'
                    WHEN (v_rate IS NULL) THEN 'Tiered Rated'
				    WHEN (v_rate < v_standard_rate) THEN 'Reduced Rated'
				    WHEN (v_rate = v_standard_rate) THEN 'Standard Rated'
				    WHEN (v_rate > v_standard_rate) THEN 'Increased Rated'
				    ELSE v_rate_code END
                INTO v_rate_desc
                FROM dual;

                IF (:NEW.product_category_id IS NOT NULL) THEN
                    SELECT substr(replace(pc.name,pc.prodcode),1,100) name
                    INTO v_prod_name
                    FROM tb_product_categories pc
                    WHERE pc.product_category_id = :NEW.product_category_id;
                END IF;
                :NEW.invoice_description := trim(v_rate_desc||' '||substr(v_prod_name,1,(100-length(v_rate_desc))-20));
            END IF;
        ELSE
            :NEW.invoice_description := NULL;
        END IF;
    END IF;

END DT_RULES_BEFORE_UPDATE;
/