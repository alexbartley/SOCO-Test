CREATE OR REPLACE PACKAGE BODY sbxtax4.cr_extract
IS

/*

Date            Author            Comments
----------------------------------------------------------------------------------------------------------
11/01/2017      PMR               All GIS references have been removed from regular ETL processing,
                                  moved to GIS_ETL.


*/

/*
   Additional attributes -- 10/10/14 CRAPP-797 dlg

   ALTER TABLE tdr_etl_authority_base
   ADD (
   OFFICIAL_NAME VARCHAR2 (100), -- determination official name
   DEFAULT_PRODUCT_GROUP VARCHAR2(100) -- determination default product group
   )
   --/
*/
    g_prod_level_token number := 4;

    -- Changes for CRAPP-3953
    PROCEDURE set_extracted_date (entity_name_i VARCHAR2)
    IS
    BEGIN
        etl_proc_log_p('CR_EXTRACT.SET_EXTRACT_DATE','Setting extract date for the entity '||entity_name_i,upper(entity_name_i),NULL,NULL);
        IF entity_name_i = 'RATES'
        THEN
            UPDATE extract_log
               SET extract_date = SYSDATE
             WHERE     entity = 'TAX' and extract_date is null
                   AND (nkid, rid) IN (SELECT nkid, rid
                                         FROM tdr_etl_rates);
        ELSIF entity_name_i = 'AUTHORITIES'
        THEN
            UPDATE extract_log
               SET extract_date = SYSDATE
             WHERE     entity = 'JURISDICTION' and extract_date is null
                   AND (nkid, rid) IN (SELECT nkid, rid
                                         FROM tdr_etl_authority_base);
        ELSIF entity_name_i = 'RULES'
        THEN
            UPDATE extract_log
               SET extract_date = SYSDATE
             WHERE     entity = 'TAXABILITY' and extract_date is null
                   AND (nkid, rid) IN (SELECT nkid, rid FROM tdr_etl_rules
                                       UNION
                                       SELECT nkid, rid FROM tdr_etl_rule_qualifiers);
        ELSIF entity_name_i = 'PRODUCTS'
        THEN
            UPDATE extract_log
               SET extract_date = SYSDATE
             WHERE     entity = 'COMMODITY' and extract_date is null
                   AND (nkid, rid) IN (SELECT nkid, rid
                                         FROM tdr_etl_product_categories);
        ELSIF entity_name_i = 'REFERENCE GROUP'
        THEN
            UPDATE extract_log
               SET extract_date = SYSDATE
             WHERE     entity = 'REFERENCE GROUP' and extract_date is null
                   AND (nkid, rid) IN (SELECT nkid, rid FROM tdr_etl_reference_values
                                       UNION
                                       SELECT nkid, rid FROM tdr_etl_reference_lists);
        END IF;
        etl_proc_log_p('CR_EXTRACT.SET_EXTRACT_DATE','Extract date has been set for  '||entity_name_i,upper(entity_name_i),NULL,NULL);

        COMMIT;
    END;

    PROCEDURE unextract_commodities
    IS
    BEGIn
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.UNEXTRACT_COMMODITIES','mark all Commodities in tdr_etl_product_categories as UNextracted','COMMODITY',null,null);
        UPDATE extract_log el
        SET extract_Date = NULL
        WHERE entity = 'COMMODITY'
        and exists (
            select 1
            from tdr_etl_product_categories ab
            where ab.nkid = el.nkid
            and ab.rid = el.rid
            );
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.UNEXTRACT_COMMODITIES','remove Unextracted data from tmp_ tables','COMMODITY',null,null);
        DELETE FROM tdr_etl_rules r
        WHERE EXISTS (
            SELECT 1
            FROM tdr_etl_rule_products p
            JOIN tdr_etl_product_categories pc on (p.commodity_nkid = pc.nkid)
            JOIN tdr_etl_rules r2 on (r2.nkid = p.nkid)
            WHERE r.nkid = r2.nkid
            );
        DELETE FROM tdr_etl_rule_products p
        WHERE NOT EXISTS (
            SELECT 1
            FROM tdr_etl_rules r
            WHERE r.nkid = p.nkid
            );
        DELETE FROM tdr_etl_jta_inv_desc tid
        WHERE NOT EXISTS (
            SELECT 1
            FROM tdr_etl_rules r
            WHERE r.nkid = tid.nkid
            );
        DELETE FROM tdr_etl_rule_qualifiers q
       WHERE NOT EXISTS (
            SELECT 1
            FROM tdr_etl_rules r
            WHERE r.nkid = q.nkid
            );
        execute immediate 'truncate table tdr_etl_product_categories';
        execute immediate 'truncate table tdr_etl_prod_changes';
        commit;

    exception
    when TIMEOUT_ON_RESOURCE then
    RAISE_APPLICATION_ERROR(-20001,'Temp Commodity data timeout.');
    when others then
    RAISE_APPLICATION_ERROR(-20002,'Temp commodity error.');

    END unextract_commodities;

    PROCEDURE unextract_ref_groups
    IS
    BEGIn
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.UNEXTRACT_REF_GROUPS','mark all Reference Groups in tdr_etl_reference_lists as UNextracted','REFERENCE GROUP',null,null);
        UPDATE extract_log el
        SET extract_Date = NULL
        WHERE entity = 'REFERENCE GROUP'
        and exists (
            select 1
            from tdr_etl_reference_lists ab
            where ab.ref_group_nkid = el.nkid
            and ab.rid = el.rid
            );
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.UNEXTRACT_REF_GROUPS','remove UNextracted data from tmp_ tables','REFERENCE GROUP',null,null);
        DELETE FROM tdr_etl_rules r
        WHERE EXISTS (
            SELECT 1
            FROM tdr_etl_rule_qualifiers q
            JOIN tdr_etl_reference_lists l on (l.name = q.reference_group_name)
            JOIN tdr_etl_rules r2 on (r2.nkid = q.jta_nkid)
            WHERE q.reference_group_name IS NOT NULL
            AND r.nkid = r2.nkid
            );
        DELETE FROM tdr_etl_rule_products p
        WHERE NOT EXISTS (
            SELECT 1
            FROM tdr_etl_rules r
            WHERE r.nkid = p.nkid
            );
        DELETE FROM tdr_etl_jta_inv_desc tid
        WHERE NOT EXISTS (
            SELECT 1
            FROM tdr_etl_rules r
            WHERE r.nkid = tid.nkid
            );
        DELETE FROM tdr_etl_rule_qualifiers q
       WHERE NOT EXISTS (
            SELECT 1
            FROM tdr_etl_rules r
            WHERE r.nkid = q.jta_nkid
            );
        execute immediate 'truncate table tdr_etl_reference_lists';
        commit;

    exception
    when TIMEOUT_ON_RESOURCE then
    RAISE_APPLICATION_ERROR(-20001,'Tmp Reference group data timeout.');
    when others then
    RAISE_APPLICATION_ERROR(-20002,'Reference group error.');

    END unextract_ref_groups;

    PROCEDURE unextract_record(entity_i IN VARCHAR2, nkid_i IN NUMBER, rid_i IN NUMBER)
    IS
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.UNEXTRACT_RECORD','mark record as UNextracted',entity_i,nkid_i,rid_i);
        UPDATE extract_log
        SET extract_date = NULL
        WHERE entity = nvl(entity_i,'xx')
        AND nkid = nvl(nkid_i,-1)
        and rid = nvl(rid_i,-1);
        COMMIT;
    END;

    PROCEDURE unextract_jurisdictions
    IS
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.UNEXTRACT_JURISDICTIONS','mark all Jurisdictions in tdr_etl_authority_base as UNextracted',null,null,null);
        UPDATE extract_log el
        SET extract_Date = NULL
        WHERE entity = 'JURISDICTION'
        and exists (
            select 1
            from tdr_etl_authority_base ab
            where ab.nkid = el.nkid
            and ab.rid = el.rid
            );
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.UNEXTRACT_JURISDICTIONS','mark all Taxes in tdr_etl_rates as UNextracted',null,null,null);
        UPDATE extract_log el
        SET extract_Date = NULL
        WHERE entity = 'TAX'
        and EXISTS (
            SELECT 1
            FROM tdr_etl_rates r
            WHERE r.nkid = el.nkid
            and r.rid = el.rid
            );
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.UNEXTRACT_JURISDICTIONS','mark all Taxabilities in tdr_etl_rules as UNextracted',null,null,null);
        UPDATE extract_log el
        SET extract_Date = NULL
        WHERE entity = 'TAXABILITY'
        and EXISTS (
            SELECT 1
            FROM tdr_etl_rules r
            WHERE el.nkid = r.nkid
            and el.rid = r.rid
            );
        COMMIT;
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.UNEXTRACT_JURISDICTIONS','truncate tmp_ tables dependent on Jurisdictions',null,null,null);
        execute immediate 'truncate table tdr_etl_authority_base';
        execute immediate 'truncate table tdr_etl_rates';
        execute immediate 'truncate table tdr_etl_rules';
        execute immediate 'truncate table tdr_etl_rule_qualifiers';
        execute immediate 'truncate table tdr_etl_jta_inv_desc';
        execute immediate 'truncate table tdr_etl_rule_products';
        execute immediate 'truncate table tdr_etl_cntr_authorities';

    exception
    when TIMEOUT_ON_RESOURCE then
    RAISE_APPLICATION_ERROR(-20001,'Unextract jurisdiction timeout.');
    when others then
    RAISE_APPLICATION_ERROR(-20002,'Unextract jurisdiction error.');

    END unextract_jurisdictions;

    function prod_level_token RETURN number
    IS
    BEGIN
        return g_prod_level_token;
    END prod_level_token;

    procedure product_data
    IS

    BEGIN
        etl_proc_log_p('CR_EXTRACT.PRODUCT_DATA','Start loading product data','PRODUCT_DATA',NULL,NULL);

        etl_proc_log_p ('CR_EXTRACT.PRODUCT_DATA','truncate tdr_etl_product_categories and tdr_etl_prod_changes','COMMODITY',null,null);
        execute immediate 'truncate table tdr_etl_product_categories';
        execute immediate 'truncate table tdr_etl_prod_changes';

        etl_proc_log_p ('CR_EXTRACT.PRODUCT_DATA','get Product Category data for affected revisions','COMMODITY',null,null);

        INSERT INTO tdr_etl_product_categories (name, description, prodcode, sort_key, nkid, product_tree) (
        SELECT DISTINCT substr(c.name,1,100), substr(c.description, 1, 250), substr(c.commodity_code,1,50), c.h_code, c.nkid, c.product_tree_short_name --njv CRAPP-864
        FROM content_repo.mvcommodities c
        WHERE c.next_rid is null
        AND exists (
            SELECT 1
            FROM extract_log el
            WHERE entity = 'COMMODITY'
            and el.nkid = c.nkid
            --and el.extract_date is null
            )
        );

        etl_proc_log_p ('CR_EXTRACT.PRODUCT_DATA','get unique Commodity revisions','COMMODITY',null,null);

        --Changes for CRAPP-3907 and CRAPP-2478
        INSERT INTO tdr_etl_prod_changes (nkid, rid) (
        SELECT distinct nkid, rid
        FROM extract_log
        WHERE entity = 'COMMODITY'
        and loaded IS NULL
        );

        COMMIT;
        etl_proc_log_p('CR_EXTRACT.PRODUCT_DATA','End loading product data','PRODUCT_DATA',NULL,NULL);
    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.PRODUCT_DATA','Error loading product data, failed with '||sqlerrm,'PRODUCT_DATA',NULL,NULL);
    RAISE_APPLICATION_ERROR(-20001,'Function prod level error.');

    END;

    procedure reference_data
    IS
    BEGIN
        etl_proc_log_p('CR_EXTRACT.REFERENCE_DATA','Start loading referenced data','REFERENCE_DATA',NULL,NULL);
        INSERT INTO tdr_etl_reference_lists (ref_group_nkid, rid, name, value, list_start_date, list_end_date, item_start_Date, item_end_date, description, item_nkid)
        (
            SELECT distinct r.nkid, el.rid, name, value, to_date(r.start_Date,'MM/DD/YYYY') list_start_date, to_date(r.end_date,'MM/DD/YYYY') list_end_date,
                   to_date(i.start_Date,'MM/DD/YYYY') item_start_date,  to_date(i.end_date,'MM/DD/YYYY') item_end_date, SUBSTR(description, 1, 200) description, -- CRAPP-809 dlg
                   i.nkid item_nkid
            FROM content_repo.mvreference_groups1 r
            JOIN extract_log el on (el.nkid = r.nkid and el.rid = ref_grp_rid and el.entity = 'REFERENCE GROUP' and el.loaded is null)
            JOIN content_repo.mvreference_items1 i on (i.ref_grp_nkid = r.nkid)
            AND r.next_rid is null
            and i.next_rid is null
        );

        INSERT INTO tdr_etl_reference_values
        SELECT distinct r.nkid ref_group_nkid, i.nkid item_nkid, value, to_date(i.start_Date,'MM/DD/YYYY') item_start_date,
            to_date(i.end_date,'MM/DD/YYYY') item_end_date, SUBSTR(description, 1, 200) description
        FROM content_repo.mvreference_groups1 r
        JOIN extract_log el on (el.nkid = r.nkid and el.rid = ref_grp_rid and el.entity = 'REFERENCE GROUP' and el.loaded is null)
        JOIN content_repo.mvreference_items1 i on (i.ref_grp_nkid = r.nkid)
        AND r.next_rid is null
        and i.next_rid is null
        ;

        commit;
        etl_proc_log_p('CR_EXTRACT.REFERENCE_DATA','End loading referenced data','REFERENCE_DATA',NULL,NULL);
    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.REFERENCE_DATA','Reference Data failed with '||SQLERRM,'REFERENCE_DATA',NULL,NULL);
    RAISE_APPLICATION_ERROR(-20001,'Reference data error.');

    END reference_data;

    PROCEDURE get_product_exceptions IS

        cursor taxabilities is
        select distinct nkid jta_nkid
        from tdr_etl_rule_products;

        cursor prod_exceptions(jta_nkid_i IN NUMBER) is
        select distinct product_category_id, null, r.no_tax, r.exempt, r.authority_uuid, r.rate_code, r.start_date,
            r.end_date, length(c.h_code)/g_prod_level_token hierarchy_level, r.is_local
        from tdr_etl_rule_products r
        join content_repo.mvcommodities c on (c.product_tree_id = r.product_tree_id and c.next_rid is null)
        join mp_comm_prods cp on (cp.commodity_nkid = c.nkid)
        where r.nkid = jta_nkid_i
        and c.h_code like r.h_code||'%'
        and not exists (
            select 1
            from content_repo.mvcommodities c2
            where c2.product_tree_id = r.product_tree_id
            --and ja.authority_uuid = r.authority_uuid
            and to_date(c2.start_Date, 'mm/dd/yyyy') <= r.start_date
            and nvl(to_date(c2.end_Date, 'mm/dd/yyyy'), '31-dec-9999') >= r.start_date
            and c.nkid = c2.nkid
            --and tas.juris_tax_applicability_nkid = jta_nkid_i
            );

    BEGIN
    etl_proc_log_p('CR_EXTRACT.GET_PRODUCT_EXCEPTIONS','Started get_product_exceptions, Loop taxabilities','GET_PRODUCT_EXCEPTIONS',NULL,NULL);
    for t in taxabilities loop
        for pe in prod_exceptions(t.jta_nkid) loop
            etl_proc_log_p('CR_EXTRACT.GET_PRODUCT_EXCEPTIONS','Inside prod_exceptions loop','GET_PRODUCT_EXCEPTIONS',t.jta_nkid,NULL);
            insert into tdr_etl_product_exceptions (
                product_category_id,  no_tax, exempt, authority_uuid, rate_code, start_date ,end_date, hierarchy_level, is_local)
            values (
                pe.product_category_id,  pe.no_tax, pe.exempt, pe.authority_uuid, pe.rate_code, pe.start_Date, pe.end_date, pe.hierarchy_level, pe.is_local
                );
        end loop;

    end loop;
    commit;

    delete
    from tdr_etl_product_exceptions pe
    where exists (
        select 1
        from tdr_etl_rule_products rp
        join mp_comm_prods cp on (cp.commodity_nkid = rp.commodity_nkid)
        where rp.authority_uuid = pe.authority_uuid
        and rp.is_local = pe.is_local
        and cp.product_category_id = pe.product_category_id
        and rp.start_date = pe.start_date
        and nvl(rp.end_date,'31-dec-9999') = nvl(pe.end_date,'31-dec-9999')
        );
    commit;
    etl_proc_log_p('CR_EXTRACT.GET_PRODUCT_EXCEPTIONS','Completed get_product_exceptions, Loop taxabilities','GET_PRODUCT_EXCEPTIONS',NULL,NULL);


    END get_product_exceptions;


    procedure insert_authority(nkid_i IN NUMBER, rid_i IN NUMBER, content_type_i IN VARCHAR2)
    IS
        CURSOR current_data IS
        SELECT DISTINCT
             j.nkid,
             j.rid,
             j.official_name name,
             tath.authority_uuid,
             j.description,
             j.location_category,
             tac.value authority_category,

             -- Orig Location Code (reporting code)
             -- trc.value location_code,
             -- Location Code With Override
             CASE WHEN xrepcode.attribute_id = content_repo.fnjurisattribadmin(2) AND (trc.value = xrepcode.value)
                    THEN xrepcode.value
               WHEN xrepcode.attribute_id = content_repo.fnjurisattribadmin(2) AND (trc.value IS NULL)
                    THEN xrepcode.value
               WHEN xrepcode.attribute_id = content_repo.fnjurisattribadmin(2) AND (trc.value <> xrepcode.value)
                    THEN xrepcode.value -- crapp-2277 changed from trc.value
               WHEN xrepcode.attribute_id IS NULL
                    THEN trc.value
             END location_code,
             --
             dat.value att_auth_type,
             ti.reference_code,
             td.specific_applicability_type,
             td.taxation_type,
             td.transaction_type,

             -- Orig
             -- ta.administrator_name,
             -- ta.administrator_type,
             -- New Administrator With Override
             CASE WHEN xaon.attribute_id = content_repo.fnjurisattribadmin(1)
                  -- and (ta.has_possible_override=1 and ta.admin_nkid = xaon.nkid)
                  THEN TO_CHAR(content_repo.fnlookupadminbynkid(pnkid=> xaon.nkid))     -- NKID Default Admin
               --WHEN xaon.attribute_id = crapp_extract.fnjurisattribadmin(1) AND        -- 03/08/16 - removed per crapp-2377
               --     (ta.has_possible_override=1 and ta.admin_nkid <> xaon.nkid)
               --     THEN TO_CHAR(crapp_extract.fnlookupadminbynkid(pnkid=>ta.admin_nkid))
               --WHEN xaon.attribute_id = crapp_extract.fnjurisattribadmin(1) AND (ta.admin_nkid IS NULL)
               --     THEN TO_CHAR(crapp_extract.fnlookupadminbynkid(pnkid=> xaon.nkid))
               --WHEN crapp_extract.fnjurisattribadmin(1) IS NULL
               --     THEN TO_CHAR(crapp_extract.fnlookupadminbynkid(pnkid=>ta.admin_nkid))
               ELSE NULL -- defaults to jurisdiction's type
             END administrator_name,

             -- New Adminstrator_Type With Override
             CASE WHEN xaon.attribute_id = content_repo.fnjurisattribadmin(1)
                  -- and (ta.has_possible_override=1 and ta.admin_nkid = xaon.nkid)
                     THEN TO_CHAR(content_repo.fnlookupadmintypebynkid(pnkid=> xaon.nkid))  -- NKID Default Admin
               --WHEN xaon.attribute_id = crapp_extract.fnjurisattribadmin(1) AND            -- 03/08/16 - removed per crapp-2377
               --     (ta.has_possible_override=1 and ta.admin_nkid <> xaon.nkid)
               --     THEN TO_CHAR(crapp_extract.fnlookupadmintypebynkid(pnkid=>ta.admin_nkid))
               --WHEN xaon.attribute_id = crapp_extract.fnjurisattribadmin(1) AND (ta.admin_nkid IS NULL)
               --     THEN TO_CHAR(crapp_extract.fnlookupadminbynkid(pnkid=> xaon.nkid))
               --WHEN crapp_extract.fnjurisattribadmin(1) IS NULL
               --     THEN TO_CHAR(crapp_extract.fnlookupadmintypebynkid(pnkid=>ta.admin_nkid))
               ELSE NULL -- defaults to jurisdiction's type
             END administrator_type,

             aon.value official_name,
             CASE WHEN content_type_i = 'US' THEN 'US' ELSE dpg.value END default_product_group,
             erp.value erp_tax_code,
             tr.registration_mask
        FROM content_repo.mvjurisdictions j
             JOIN mp_juris_auths tath on (tath.nkid = j.nkid)
             JOIN content_repo.mv_juris_tax_imps_juris ti on (ti.jurisdiction_nkid = j.nkid)
             JOIN content_repo.vtax_descriptions td on (td.id = ti.tax_description_id)
             LEFT JOIN (  -- Determine Reporting Code value from most recent updated tax (used if no Default Reportin Code) -- crapp-2277
                        SELECT DISTINCT jurisdiction_nkid, CASE WHEN end_date IS NOT NULL THEN NULL ELSE value END value
                        FROM (
                              SELECT DISTINCT jti.jurisdiction_nkid, ta.juris_tax_nkid, ta.value, ta.next_rid, ta.start_date
                                     , ta.end_date, ta.status_modified_date, jti.reference_code, ta.id
                              FROM   content_repo.mvtax_juris_attributes ta
                                     JOIN content_repo.mv_juris_tax_imps_juris jti ON (ta.juris_tax_nkid = jti.nkid)
                              WHERE  jti.jurisdiction_nkid = nkid_i
                                     AND ta.attribute_name = 'Reporting Code'
                                     AND ta.next_rid IS NULL
                                     AND ta.end_date IS NULL
                                     AND ta.status_modified_date = (
                                                    SELECT DISTINCT MAX(ta.status_modified_date)
                                                    FROM   content_repo.mvtax_juris_attributes ta
                                                           JOIN content_repo.mv_juris_tax_imps_juris jti ON (ta.juris_tax_nkid = jti.nkid)
                                                    WHERE  jti.jurisdiction_nkid = nkid_i
                                                        AND ta.attribute_name = 'Reporting Code'
                                                        AND ta.next_rid IS NULL
                                                        AND ta.end_date IS NULL
                                                    )
                             )
                       ) trc on (trc.jurisdiction_nkid = j.nkid)
             LEFT JOIN content_repo.mvtax_juris_attributes dat on ( dat.attribute_name = 'Determination Authority Type'
                                                              AND dat.juris_tax_nkid = ti.nkid
                                                              AND dat.next_rid IS NULL
                                                              AND dat.end_date IS NULL)
             LEFT JOIN content_repo.mvjurisdiction_attributes erp on ( erp.attribute_name = 'Determination ERP Code'
                                                                       AND erp.juris_nkid = j.nkid
                                                                       AND erp.next_rid IS NULL
                                                                       AND erp.end_date IS NULL)
             LEFT JOIN content_repo.mvjurisdiction_attributes tac on ( tac.attribute_name = 'Determination Authority Category'
                                                                       AND tac.juris_nkid = j.nkid
                                                                       AND tac.next_rid IS NULL
                                                                       AND tac.end_date IS NULL)
             LEFT JOIN content_repo.mvjurisdiction_attributes aon on ( aon.attribute_name = 'Determination Official Name'
                                                                       AND aon.juris_nkid = j.nkid
                                                                       AND aon.next_rid IS NULL
                                                                       AND aon.end_date IS NULL)
             LEFT JOIN content_repo.mvjurisdiction_attributes dpg on ( dpg.attribute_name = 'Determination Default Product Group'
                                                                       AND dpg.juris_nkid = j.nkid
                                                                       AND dpg.next_rid IS NULL
                                                                       AND dpg.end_date IS NULL)
             LEFT JOIN ( SELECT aon.attribute_id,
                                aon.attribute_category,
                                aon.attribute_name,
                                aon.start_date,
                                aon.end_date,
                                aon.next_rid,
                                aon.juris_nkid,
                                aon.value
                         FROM content_repo.mvjurisdiction_attributes aon
                       ) xrepcode ON (xrepcode.attribute_id = content_repo.fnJurisAttribAdmin(2)
                                      AND xrepcode.juris_nkid = j.nkid
                                      AND xrepcode.next_rid IS NULL
                                      AND xrepcode.end_date IS NULL
                                     )
             LEFT JOIN ( SELECT DISTINCT
                                ta.juris_tax_nkid, ta.administrator_name, a.administrator_type,
                                a.nkid admin_nkid, 1 has_possible_override
                         FROM  content_repo.etl_juris_tax_administrators ta
                               JOIN content_repo.vadministrators a on (a.id = ta.admin_id)
                         WHERE ta.end_date IS NULL
                               AND ta.next_rid IS NULL
                       ) ta ON (ta.juris_tax_nkid = ti.nkid)
             LEFT JOIN ( SELECT aon.attribute_id,
                                aon.attribute_category,
                                aon.attribute_name,
                                aon.start_date,
                                aon.end_date,
                                aon.next_rid,
                                aon.juris_nkid,
                                aon.value,
                                aon.value_id,
                                lad.name,
                                lad.administrator_type,
                                lad.nkid -- 03/08/16 - crapp-2377
                         FROM content_repo.mvjurisdiction_attributes aon
                              JOIN content_repo.vadministrators lad on (lad.id = aon.value_id)  -- changed from "lad.nkid" -- 03/08/16 - crapp-2377
                       ) xaon ON (xaon.attribute_id = content_repo.fnJurisAttribAdmin(1)
                                  AND xaon.juris_nkid = j.nkid
                                  AND xaon.next_rid IS NULL
                                  AND xaon.end_date IS NULL
                                 )
             LEFT JOIN content_repo.vtax_registrations tr ON ( ta.admin_nkid = tr.admin_nkid
                                                                AND tr.next_rid IS NULL)
        WHERE j.nkid = nkid_i
              AND j.juris_next_rid IS NULL
              AND NOT EXISTS ( SELECT 1
                               FROM  tdr_etl_authority_base ab
                               WHERE ab.nkid = j.nkid
                             );

        l_authority_type VARCHAR2(100);
        l_erp_tax_code VARCHAR2(100);
    BEGIN
    etl_proc_log_p('CR_EXTRACT.INSERT_AUTHORITY','inside insert authority process, content_type_i:'||content_type_i,'INSERT_AUTHORITY',nkid_i,rid_i);

        FOR cd in current_data LOOP
            IF (content_type_i = 'US') THEN
                IF cd.att_auth_type IS NOT NULL THEN l_authority_type := cd.att_auth_type;
                   ELSIF cd.reference_code = 'TUT' THEN l_authority_type := 'Utility Users';
                   ELSIF SUBSTR(cd.reference_code,1,3) IN ('TCU','TSU','TST') THEN l_authority_type := 'Telecom';
                   ELSIF cd.reference_code = 'TBO' THEN l_authority_type := 'Business and Occupation';
                   ELSIF cd.reference_code = 'TSP' THEN l_authority_type := 'Service';
                   ELSIF cd.reference_code IN ('TS1','TS2') THEN l_authority_type := 'Surcharge';
                   ELSIF cd.reference_code = 'TLT' THEN l_authority_type := 'License';
                   ELSIF cd.reference_code = 'TGR' THEN l_authority_type := 'Gross Receipts';
                   ELSIF cd.reference_Code LIKE 'TEX%' THEN l_authority_type := 'EXC';
                   ELSIF cd.specific_applicability_type = 'Prepared Food' THEN l_authority_type := '? Food/Beverage';
                   ELSIF cd.specific_applicability_type = 'Hospitality'   THEN l_authority_type := '? Occupancy'; -- crapp-2997
                   ELSIF cd.taxation_type = 'Fees and Surcharges' AND cd.transaction_type <> 'Rental' THEN l_authority_type := '? Fees'; -- crapp-2345/2460
                   ELSIF cd.taxation_type = 'Use Tax'   AND cd.transaction_type <> 'Rental' THEN l_authority_type := '? Sales/Use';
                   ELSIF cd.taxation_type = 'Sales Tax' AND cd.transaction_type <> 'Rental' THEN l_authority_type := '? Sales/Use';
                   ELSIF cd.transaction_type = 'Rental' THEN l_authority_type := '? Rental' ;
                   ELSE l_authority_type := cd.taxation_type;
                END IF;
                l_erp_tax_code := 'US'||SUBSTR(cd.name,1,2);
            ELSIF (content_type_i = 'INTL') THEN
                IF cd.att_auth_type IS NOT NULL THEN
                    l_authority_type := cd.att_auth_type;
                ELSE
                    l_authority_type := cd.taxation_type;
                END IF;
                l_erp_tax_code := cd.erp_tax_code;
            END IF;
        etl_proc_log_p('CR_EXTRACT.INSERT_AUTHORITY','Inserting data into tdr_etl_authority_base','INSERT_AUTHORITY',nkid_i,rid_i);
        INSERT INTO tdr_etl_authority_base (
            nkid, rid, name, authority_uuid, description, effective_zone_level,
            authority_category, location_code, authority_type,
            administrator_name, administrator_type, official_name, default_product_group, erp_tax_code, registration_mask)
            VALUES (
                 nkid_i, rid_i, cd.name, cd.authority_uuid, cd.description, cd.location_category, cd.authority_category, cd.location_code,
                 l_authority_type, cd.administrator_name, cd.administrator_type, cd.official_name, cd.default_product_group, l_erp_tax_code,
                 cd.registration_mask
            );
        END LOOP;

    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.INSERT_AUTHORITY',sqlerrm,'INSERT_AUTHORITY',nkid_i,rid_i);
    RAISE_APPLICATION_ERROR(-20001,'Insert authority error.');

    END insert_authority;

    /* Changes for CRAPP-3239 */
    procedure insert_contributing_authority(nkid_i IN NUMBER, rid_i IN NUMBER)
    IS
    BEGIN
       etl_proc_log_p('CR_EXTRACT.INSERT_CONTRIBUTING_AUTHORITY','Started INSERT_CONTRIBUTING_AUTHORITY','INSERT_CONTRIBUTING_AUTHORITY',nkid_i,rid_i);
       INSERT INTO tdr_etl_cntr_authorities (nkid,
                                                     rid,
                                                     contributee_uuid,
                                                     contributor_uuid,
                                                     basis_percent,
                                                     start_date,
                                                     end_date)
        SELECT DISTINCT tr.jurisdiction_nkid,
                        tr.jurisdiction_rid,
                        this_auth.authority_uuid,
                        auth.authority_uuid,
                        basis_percent,
                        tr.start_date,
                        tr.end_date
          FROM content_repo.mv_tax_relationships tr
               JOIN content_repo.mv_tax_relationship_juris this_juris
                   ON (this_juris.nkid = tr.jurisdiction_nkid)
               JOIN content_repo.mv_tax_relationship_juris related_juris
                   ON (related_juris.nkid = tr.related_jurisdiction_nkid)
               JOIN mp_juris_auths auth
                   ON (auth.nkid = this_juris.nkid) -- CRAPP-3174, Removed schema reference
               JOIN mp_juris_auths this_auth -- CRAPP-3174, Removed schema reference
                   ON (this_auth.nkid = related_juris.nkid)
         WHERE (tr.jurisdiction_nkid = nkid_i AND tr.jurisdiction_rid = rid_i);
        etl_proc_log_p('CR_EXTRACT.INSERT_CONTRIBUTING_AUTHORITY','End INSERT_CONTRIBUTING_AUTHORITY','INSERT_CONTRIBUTING_AUTHORITY',nkid_i,rid_i);

    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.INSERT_CONTRIBUTING_AUTHORITY','INSERT_CONTRIBUTING_AUTHORITY failed with '||SQLERRM,'INSERT_CONTRIBUTING_AUTHORITY',nkid_i,rid_i);
    RAISE_APPLICATION_ERROR(-20001,'Insert of contributing authorities error.');

    END insert_contributing_authority;


    procedure get_auth_admin_changes(extract_Start_i IN TIMESTAMP, content_type_i IN VARCHAR2)
    IS
        cursor new_tax_admin_revisions is
        select distinct j.nkid, n.rid tax_extract_rid
        from content_repo.jurisdictions j
        join content_repo.mv_juris_tax_imps_juris jti on (jti.jurisdiction_id = j.id)
        join (
            select distinct tel.nkid, tel.rid, queued_date
            FROM extract_log tel
            JOIN content_repo.mv_jurisdiction_tax_admin ta ON (ta.rid = tel.rid)
            WHERE tel.entity = 'TAX'
            --Changes for CRAPP-3907 and CRAPP-2478
            and loaded is null
            union
            select distinct tel.nkid, tel.rid, queued_date
            FROM extract_log tel
            JOIN content_repo.mvtax_juris_attributes ta ON (ta.rid = tel.rid and attribute_name = 'Reporting Code')
            WHERE tel.entity = 'TAX'
            --Changes for CRAPP-3907 and CRAPP-2478
            and loaded is null
            ) n on (n.nkid = jti.nkid)
        where not exists (
            select 1
            from extract_log el
            where el.entity = 'JURISDICTION'
            and el.nkid = j.nkid
            and el.rid = j.rid
        --Changes for CRAPP-3907 and CRAPP-2478
            and el.loaded > extract_Start_i
            );
        l_other_changes number := 0;
        l_c number := 0;
    BEGIN
        etl_proc_log_p ('CR_EXTRACT.GET_AUTH_ADMIN_CHANGES','get Administrator details for new Authorities','JURISDICTION',null,null);
        for nta in new_tax_admin_revisions loop
            l_c := l_c+1;
            etl_proc_log_p('CR_EXTRACT.GET_AUTH_ADMIN_CHANGES','Calling Insert_Authority, with NKID:'||nta.nkid,'JURISDICTION',null,null);
            insert_authority(nta.nkid, null,content_type_i);
            l_other_changes := 0;

            etl_proc_log_p('CR_EXTRACT.GET_AUTH_ADMIN_CHANGES','Step 1: l_other_changes value is '||l_other_changes,'JURISDICTION',null,null);
            select count(*)
            into l_other_changes
            from content_repo.juris_tax_impositions
            where rid = nta.tax_extract_rid;

            etl_proc_log_p('CR_EXTRACT.GET_AUTH_ADMIN_CHANGES','Step 2: l_other_changes value is '||l_other_changes,'JURISDICTION',null,null);
            select count(*)+l_other_changes
            into l_other_changes
            from content_repo.tax_outlines
            where rid = nta.tax_extract_rid;

            etl_proc_log_p('CR_EXTRACT.GET_AUTH_ADMIN_CHANGES','Step 3: l_other_changes value is '||l_other_changes,'JURISDICTION',null,null);
            select count(*)+l_other_changes
            into l_other_changes
            from content_repo.tax_definitions
            where rid = nta.tax_extract_rid;

            etl_proc_log_p('CR_EXTRACT.GET_AUTH_ADMIN_CHANGES','Step 3: l_other_changes value is '||l_other_changes,'JURISDICTION',null,null);
            select count(*)+l_other_changes
            into l_other_changes
            from content_repo.tax_attributes
            where rid = nta.tax_extract_rid;

            IF (l_other_changes = 0) THEN
                --if there are no other Tax changes in this revision, mark it as extracted
                --otherwise, it still needs to be extracted by rate_data
                update extract_log
                set extract_date = NULL
                WHERE nkid = nta.nkid
                AND rid = nta.tax_extract_rid;
            END IF;

            COMMIT;
        END LOOP;
        etl_proc_log_p('CR_EXTRACT.GET_AUTH_ADMIN_CHANGES',l_c||' Authorities with Administrator update','JURISDICTION',null,null);
        COMMIT;

    END get_auth_admin_changes;

    procedure authorities_us
    is
        l_extract_start timestamp(6) := systimestamp;
        cursor new_revisions is
        select distinct tel.nkid, max(tel.rid) rid
        FROM extract_log tel
        --join crapp_extract.jurisdiction_revisions r on (r.nkid = tel.nkid and r.next_rid is null)
        WHERE tel.entity = 'JURISDICTION'
        --Changes for CRAPP-3907 and CRAPP-2478
        and loaded is null
        group by tel.nkid;

        /* Changes for CRAPP-3239 */
        cursor contributing_auths(nkid_i number, rid_i number) is
        select distinct tel.nkid, tel.rid rid
        from extract_log tel

        join content_repo.mv_tax_relationships tr on ( tr.jurisdiction_rid = tel.rid )
        WHERE tel.entity = 'JURISDICTION'
          and tel.nkid = nkid_i
          --Changes for CRAPP-3907 and CRAPP-2478
          and tel.rid = rid_i
          and loaded is null;
    begin
        etl_proc_log_p ('CR_EXTRACT.AUTHORITIES_US','get details for affected Authorities','JURISDICTION',null,null);

        FOR nr IN new_revisions LOOP
            etl_proc_log_p('CR_EXTRACT.AUTHORITIES_US','Calling insert_authority with NKID:'||nr.nkid||', RID:'||nr.rid,'JURISDICTION',null,null);
            insert_authority(nr.nkid, nr.rid,'US');
            etl_proc_log_p('CR_EXTRACT.AUTHORITIES_US','Calling contributing_auths lop with NKID:'||nr.nkid||', RID:'||nr.rid,'JURISDICTION',null,null);
            for ca in contributing_auths(nr.nkid, nr.rid)
            loop
                etl_proc_log_p('CR_EXTRACT.AUTHORITIES_US','Calling insert_contributing_authority with NKID:'||nr.nkid||', RID:'||nr.rid,'JURISDICTION',null,null);
                insert_contributing_authority(ca.nkid, ca.rid);
            end loop;

            COMMIT;
        END LOOP;
        etl_proc_log_p('CR_EXTRACT.AUTHORITIES_US','Calling get_auth_admin_changes with l_extract_start:'||l_extract_start,'JURISDICTION',null,null);
        get_auth_admin_changes(l_extract_start,'US');

    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.AUTHORITIES_US',sqlerrm,'JURISDICTION',null,null);
    RAISE_APPLICATION_ERROR(-20001,'US Authority ptocedure error.');

    end authorities_us;

    procedure authorities_intl
    is
        l_extract_start timestamp(6) := systimestamp;
        cursor new_revisions is
        select distinct r.nkid, r.id rid
        FROM extract_log tel
        join content_repo.jurisdiction_revisions r on (r.nkid = tel.nkid and r.next_rid is null)
        WHERE tel.entity = 'JURISDICTION'
        --Changes for CRAPP-3907 and CRAPP-2478
        and loaded is null;
    begin
        etl_proc_log_p ('CR_EXTRACT.AUTHORITIES_INTL','get details for affected Authorities','JURISDICTION',null,null);
        FOR nr IN new_revisions LOOP
            insert_authority(nr.nkid, nr.rid,'INTL');
            COMMIT;
        END LOOP;
        etl_proc_log_p('CR_EXTRACT.AUTHORITIES_US','Calling get_auth_admin_changes with l_extract_start:'||l_extract_start,'JURISDICTION',null,null);

        get_auth_admin_changes(l_extract_start,'INTL');

    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.AUTHORITIES_US','AUTHORITIES_US failed with '||sqlerrm,'JURISDICTION',null,null);
    RAISE_APPLICATION_ERROR(-20001,'INTL authority error.');

    end authorities_intl;


    procedure extract_auth_messages
    is
        cursor c001 is
        select nkid, max(rid) rid from tdr_etl_authority_base group by nkid;
    begin
        for i in c001
        loop
            INSERT INTO tdr_etl_auth_error_messages
            select i.nkid, i.rid, severity_id, SEVERITY_DESCRIPTION, ERROR_MSG, MSG_DESCRIPTION, start_date, end_date
            from content_repo.vjuris_error_messages where juris_rid = i.rid;
        end loop;
    end;

    procedure extract_auth_logic
    is
        cursor c001 is
        select nkid, max(rid) rid from tdr_etl_authority_base group by nkid;
    begin
        for i in c001
        loop
            INSERT INTO tdr_etl_auth_logic_mapping
            select i.nkid, i.rid, juris_logic_group_name, process_order, to_date(start_date, 'mm/dd/yyyy') start_date, to_date(end_date, 'mm/dd/yyyy')
            from content_repo.vjurisdiction_logicmapping where juris_rid = i.rid;
        end loop;
    end;

    procedure authority_data(package_i IN VARCHAR2)
    IS
        cursor new_juris_auths is
        SELECT nkid
        FROM extract_log
        WHERE entity = 'JURISDICTION'
        --Changes for CRAPP-3907 and CRAPP-2478
        and loaded IS NULL
        MINUS
        SELECT nkid
        FROM mp_juris_auths;
        /*    Changes for CRAPP-3239
        cursor contributing_auths is
        SELECT nkid
        FROM extract_log
        WHERE entity = 'JURISDICTION'
        and extract_date IS NULL
        union
        select j.nkid
        from crapp_extract.jurisdictions j
        where exists (
            select 1 from crapp_extract.tax_relationships tr
             where ( j.nkid = tr.jurisdiction_nkid
                        or j.nkid = tr.related_jurisdiction_nkid
                    )
            );
        */
        l_uuid varchar2(36);
    BEGIN
        etl_proc_log_p ('CR_EXTRACT.AUTHORITY_DATA','get UUID''s for new Authorities, with Package:'||package_i,null,null,null);
        FOR j IN new_juris_auths LOOP
            l_uuid := content_repo.consumer_key_map.get_key('Determination','JURISDICTION',j.nkid,'TB_AUTHORITIES','UUID');
            etl_proc_log_p('CR_EXTRACT.AUTHORITY_DATA','l_uuid:'||l_uuid||', nkid value:'||j.nkid,null,null,null);
            IF (l_uuid IS NULL) THEN
            l_uuid := sys_guid();
            l_uuid :=  lower(
                substr(l_uuid,1,8)||'-'||
                substr(l_uuid,9,4)||'-'||
                substr(l_uuid,13,4)||'-'||
                substr(l_uuid,17,4)||'-'||
                substr(l_uuid,21,12)
                );
            content_repo.consumer_key_map.set_key('Determination','JURISDICTION','TB_AUTHORITIES','UUID',j.nkid,l_uuid);
            END IF;
            etl_proc_log_p('CR_EXTRACT.AUTHORITY_DATA','l_uuid:'||l_uuid||', nkid value:'||j.nkid,null,null,null);
            insert into mp_juris_auths (nkid, authority_uuid) VALUEs (j.nkid,l_uuid);
            etl_proc_log_p('CR_EXTRACT.AUTHORITY_DATA','new Auth/Juris mapping '||l_uuid,'JURISDICTION',j.nkid,null);
        END LOOP;
        etl_proc_log_p ('CR_EXTRACT.AUTHORITY_DATA','extract Authority data for '||package_i,'JURISDICTION',null,null);

        /* Changes for CRAPP-3975 */
        IF (package_i like '%International%') THEN
            authorities_intl;
        ELSIF (package_i like '%Canada%') THEN
            etl_proc_log_p ('CR_EXTRACT.AUTHORITY_DATA','Calling authorities_intl','JURISDICTION',null,null);
            authorities_intl;
        ELSE
            authorities_us;
        END IF;

        update tdr_etl_authority_base ab
        set administrator_type = ab.effective_zone_level
        where administrator_name is not null
        and administrator_type = 'Third-party';

        extract_auth_logic;
        extract_auth_messages;

        COMMIT;
        etl_proc_log_p ('CR_EXTRACT.AUTHORITY_DATA','Finished execution','AUTHORITY DATA',null,null);
    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.AUTHORITY_DATA','Authority Data failed with '||sqlerrm,'AUTHORITY_DATA',NULL,NULL);
    RAISE_APPLICATION_ERROR(-20001,'Authority data error.');

    END authority_data;


    PROCEDURE rate_data
    IS
        cursor rates is
        select distinct nkid, max(rid) rid
        from extract_log tel
        WHERE tel.entity = 'TAX'
        AND loaded is null
        group by nkid;
    BEGIN
        etl_proc_log_p ('CR_EXTRACT.RATE_DATA','Start loading rates','RATE DATA',null,null);

        for r in rates loop
        INSERT INTO tdr_etl_rates (
            jurisdiction_nkid,
            nkid,
            rid,
            outline_nkid,
            reference_code,
            start_date,
            end_date,
            tax_structure,
            amount_type,
            specific_applicability_type,
            min_threshold,
            max_limit,
            value_type,
            value,
            ref_juris_tax_id,
            referenced_tax_Ref_code,
            currency_code,
            is_local,
            description         -- CRAPP-810 dlg
        ) (
        select distinct
            jti.jurisdiction_nkid,
            jti.nkid,
            r.rid,
            tou.nkid,
            case when upper(jti.reference_code) like '%(LOCAL)' then substr(jti.reference_code,1,instr(upper(jti.reference_code),'(LOCAL)')-2)
            else jti.reference_code end,
            to_date(tou.start_date,'MM/DD/YYYY'),
            to_date(tou.end_date,'MM/DD/YYYY'),
            tcs.tax_structure,
            tcs.amount_type,
            td.specific_applicability_type,
            td2.min_threshold,
            td2.max_limit,
            td2.value_type,
            td2.value,
            td2.ref_juris_tax_id,
            rjti.reference_code,
            case when td2.value_type = 'Fee' then c.currency_code end,
            case when ta.id is not null then 'Y' when upper(jti.reference_code) like '%(LOCAL)%' then 'Y' else 'N' end is_local,
            SUBSTR(jti.description, 1, 100)  description   -- CRAPP-810 dlg
        from content_repo.mvjuris_tax_impositions jti
        join content_repo.mvtax_outlines tou on (tou.juris_tax_nkid = jti.nkid and tou.juris_tax_rid = jti.juris_tax_entity_rid )
        join content_repo.vtax_calc_structures tcs on (tou.calculation_structure_id = tcs.id)
        join content_repo.vtax_descriptions td on (td.id = jti.tax_description_id)
        join content_repo.mvtax_definitions2 td2 on --(td2.juris_tax_nkid = jti.nkid and td2.rid = jti.juris_tax_entity_rid)
            (
             td2.juris_tax_nkid = jti.nkid
             AND td2.tax_outline_nkid = tou.nkid
             AND jti.juris_tax_entity_rid = td2.juris_tax_rid
             )
        -- Changes for CRAPP-3850
        left outer join content_repo.mv_tax_ref_rate_code rjti on (td2.ref_juris_tax_id = rjti.id)
        left outer join content_repo.currencies c on (nvl(td2.currency_id,-1) = c.id)
        left outer join content_repo.mvtax_attributes ta on (ta.juris_tax_nkid = jti.nkid and ta.attribute_name = 'Determination Cascading Rate')
        where jti.nkid = r.nkid
        and jti.juris_tax_next_rid is null

        );

    -- Changes for CRAPP-3164. This code moved to Det_Transform package to set the extract date value correctly.
    /*
        UPDATE extract_log
        SET extract_date = SYSTIMESTAMP
        WHERE entity = 'TAX'
        and nkid = r.nkid
        and rid <= r.rid
        AND extract_date is null;
    */
        commit;
        end loop;
        etl_proc_log_p ('CR_EXTRACT.RATE_DATA','End loading rates','RATE DATA',null,null);
    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.RATE_DATA',substr(sqlerrm,1000),'RATE_DATA',NULL,NULL);
    RAISE_APPLICATION_ERROR(-20001,'Rate data error.');

    END rate_data;

    procedure map_rule_jta
    is
    begin
        null;
        /*
        select distinct jta.nkid, a.uuid, r.rule_order, r.start_date, r.end_date, r.calculation_method, r.basis_percent, r.input_recovery_percent
        from crapp_Extract.juris_tax_applicabilities jta
        join mp_juris_auths ja on (ja.nkid = jta.jurisdiction_nkid)
        join tb_authorities a on (a.uuid = ja.authority_uuid)
        join tb_rules r on (r.authority_id = a.authority_id and r.merchant_id = a.merchant_id)
        join crapp_Extract.calculation_methods cm on (cm.id = jta.calculation_method_id)
        where r.calculation_method = cm.name
        and nvl(jta.basis_percent,100)/100 = nvl(r.basis_percent,1)
        and jta.recoverable_percent/100 = nvl(r.input_recovery_percent,1);
        */
    end map_rule_jta;

    PROCEDURE insert_pt_changes(nkid_i IN NUMBER , rid_i IN NUMBER, p_rid_i IN NUMBER, jta_nkid_i IN NUMBER, tas_nkid_i IN NUMBER)
    IS
        cursor rule_pt_changes is
        SELECT DISTINCT
           jta.nkid nkid,
           c.nkid commodity_nkid,
           GREATEST (nvl(to_date(c.start_date, 'mm/dd/yyyy'),'01-Jan-1900'), jta.start_date) start_date,
           CASE
               WHEN jta.end_date IS NULL AND to_date(c.end_date, 'mm/dd/yyyy') IS NOT NULL
               THEN
                   to_date(c.end_date, 'mm/dd/yyyy')
               WHEN to_date(c.end_date, 'mm/dd/yyyy') IS NULL AND jta.end_date IS NOT NULL
               THEN
                   jta.end_date
               WHEN to_date(c.end_date, 'mm/dd/yyyy') IS NOT NULL AND jta.end_date IS NOT NULL
               THEN
                   LEAST (to_date(c.end_date, 'mm/dd/yyyy'), jta.end_date)
               ELSE
                   NULL
           END
               end_date
      FROM content_repo.mvcommodities c
           JOIN content_repo.mv_juris_tax_applicabilities jta
               ON (jta.commodity_id = c.id )
     WHERE  c.nkid = nkid_i
           AND jta.nkid = jta_nkid_i
           AND jta.next_rid IS NULL
           AND c.rid <= NVL (rid_i, -1)
           AND NVL (c.next_rid, 9999999999) > NVL (rid_i, -1)
    MINUS
    SELECT DISTINCT
           jta.nkid nkid,
           c.nkid commodity_nkid,
           GREATEST (nvl(to_date(c.start_date, 'mm/dd/yyyy'),'01-Jan-1900'), jta.start_date) start_date,
           CASE
               WHEN jta.end_date IS NULL AND to_date(c.end_date, 'mm/dd/yyyy') IS NOT NULL
               THEN
                   to_date(c.end_date, 'mm/dd/yyyy')
               WHEN to_date(c.end_date, 'mm/dd/yyyy') IS NULL AND jta.end_date IS NOT NULL
               THEN
                   jta.end_date
               WHEN to_date(c.end_date, 'mm/dd/yyyy') IS NOT NULL AND jta.end_date IS NOT NULL
               THEN
                   LEAST (to_date(c.end_date, 'mm/dd/yyyy'), jta.end_date)
               ELSE
                   NULL
           END
               end_date
      FROM content_repo.mvcommodities c
           JOIN content_repo.mv_juris_tax_applicabilities jta
               ON (c.id = jta.commodity_id)
     WHERE     c.nkid = nkid_i
           AND jta.nkid = jta_nkid_i
           AND jta.next_rid IS NULL
           AND c.rid <= NVL (p_rid_i, -1)
           AND NVL (c.next_rid, 9999999999) > NVL (p_rid_i, -1)
           AND (   (    NVL (jta.end_date, '31-Dec-9999') >= c.start_date
                    AND jta.start_date <= c.start_date)
                OR (    NVL (jta.end_date, '31-Dec-9999') >=
                            NVL (c.end_date, '31-Dec-9999')
                    AND jta.start_date <= NVL (c.end_date, '31-Dec-9999'))
                OR (    c.start_date > jta.start_date
                    AND NVL (c.end_date, '31-Dec-9999') <
                            NVL (jta.end_date, '31-Dec-9999'))
                OR (    jta.start_date > c.start_date
                    AND NVL (jta.end_date, '31-Dec-9999') <
                            NVL (c.end_date, '31-Dec-9999')));

        cursor just_pt is
        SELECT DISTINCT
                   jta.nkid nkid,
                   c.nkid commodity_nkid,
                   GREATEST (nvl(to_date(c.start_date, 'mm/dd/yyyy'),'01-Jan-1900'), jta.start_date) start_date,
                   CASE
                       WHEN jta.end_date IS NULL AND to_date(c.end_date, 'mm/dd/yyyy') IS NOT NULL
                       THEN
                           to_date(c.end_date, 'mm/dd/yyyy')
                       WHEN to_date(c.end_date, 'mm/dd/yyyy') IS NULL AND jta.end_date IS NOT NULL
                       THEN
                           jta.end_date
                       WHEN to_date(c.end_date, 'mm/dd/yyyy') IS NOT NULL AND jta.end_date IS NOT NULL
                       THEN
                           LEAST (to_date(c.end_date, 'mm/dd/yyyy'), jta.end_date)
                       ELSE
                           NULL
                   END
                       end_date
              FROM content_repo.mvcommodities c
                   JOIN content_repo.mv_juris_tax_applicabilities jta
                       ON (c.id = jta.commodity_id)
             WHERE c.nkid = nkid_i
                   AND jta.nkid = jta_nkid_i
                   AND jta.next_rid IS NULL
                   AND c.rid <= NVL (rid_i, -1)
                   AND NVL (c.next_rid, 9999999999) > NVL (rid_i, -1);

    BEGIN

        etl_proc_log_p ('CR_EXTRACT.INSERT_PT_CHANGES','INSERT_PT_CHANGES Start ==>  with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i||', tas_nkid_i:'||tas_nkid_i,null,nkid_i,rid_i);
        if (p_rid_i is null) then
            for jpt in just_pt loop
            etl_proc_log_p ('CR_EXTRACT.INSERT_PT_CHANGES','INSERT_PT_CHANGES for inserts  with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i||', tas_nkid_i:'||tas_nkid_i,null,nkid_i,rid_i);
                INSERT INTO tdr_etl_rule_pt_diffs (jta_nkid,
                                                  commodity_nkid,
                                                  start_date,
                                                  end_date,
                                                  action)
                VALUES (jta_nkid_i,
                        jpt.commodity_nkid,
                        jpt.start_date,
                        jpt.end_date,
                        'Add');
            end loop;
        else
            for rp in rule_pt_changes loop
                etl_proc_log_p ('CR_EXTRACT.INSERT_PT_CHANGES','INSERT_PT_CHANGES for updates with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i||', tas_nkid_i:'||tas_nkid_i,null,nkid_i,rid_i);
                INSERT INTO tdr_etl_rule_pt_diffs (jta_nkid,
                                                  commodity_nkid,
                                                  start_date,
                                                  end_date,
                                                  action)
                VALUES (jta_nkid_i,
                        rp.commodity_nkid,
                        rp.start_date,
                        rp.end_date,
                        'Update');
            end loop;

        end if;
        etl_proc_log_p ('CR_EXTRACT.INSERT_PT_CHANGES','INSERT_PT_CHANGES End ==> ',null,null,null);

    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.INSERT_PT_CHANGES','INSERT_PT_CHANGES failed wiith '||sqlerrm,'INSERT_PT_CHANGES',NULL,NULL);
    RAISE_APPLICATION_ERROR(-20001,'Insert PT changes failed.');

    END insert_pt_changes;


procedure gen_calc_changes ( jta_nkid_i IN NUMBER, rid_i IN NUMBER, p_rid_i IN NUMBER )
is
        cursor rule_calc_changes(nkid_i IN NUMBER, rid_i IN NUMBER, p_rid_i IN NUMBER) is
        (select distinct r.nkid, to_number(cm.name) calculation_method_id, nvl(jta.basis_percent,100) basis_percent,
            jta.recoverable_percent, jta.start_date, jta.end_date,
            jta.recoverable_amount, jta.unit_of_measure, -- jta.allocated_charges, jta.related_charge,
            jta.charge_type_id,
            jta.ref_rule_order,
            jta.commodity_id, jta.commodity_nkid, case when jta.default_taxability = 'D' then 'Y' else 'N' end default_taxability,
            jta.applicability_type_id,
            rid_i rid
        from content_repo.mv_juris_tax_app_revisions r
        join content_repo.mv_juris_tax_applicabilities jta on (
            jta.nkid = r.nkid
            and jta.rid <= rid_i
            and nvl(jta.next_rid,9999999999) > rid_i)
        join content_repo.calculation_methods cm on (cm.id = jta.calculation_method_id)
        left join content_repo.charge_types c on ( c.id = jta.charge_type_id )
        where r.id = rid_i
        and r.nkid = nkid_i
        minus
        select r.nkid, jta.calculation_method_id, nvl(jta.basis_percent,100) basis_percent, jta.recoverable_percent, jta.start_date, jta.end_date,
        jta.recoverable_amount, jta.unit_of_measure, -- jta.allocated_charges, jta.related_charge,
        jta.ref_rule_order,
        jta.charge_type_id,
        jta.commodity_id, jta.commodity_nkid, case when jta.default_taxability = 'D' then 'Y' else 'N' end default_taxability,
        jta.applicability_type_id,
        rid_i rid
        from content_repo.mv_juris_tax_app_revisions r
        join content_repo.mv_juris_tax_applicabilities jta on (
            jta.nkid = r.nkid
            and jta.rid <= nvl(p_rid_i,-1)
            and nvl(jta.next_rid,9999999999) > nvl(p_rid_i,-1))
        left join content_repo.charge_types c on ( c.id = jta.charge_type_id )
        where r.id = nvl(p_rid_i,-1)
        and r.nkid = nkid_i)
        minus
        select d.jta_nkid, calculation_method, basis_percent, recoverable_percent, d.start_date, d.end_date,
           d.recoverable_amount, d.unit_of_measure, d.charge_type_id, -- d.allocated_charges, d.related_charge,
           d.ref_rule_order,
           commodity_id, commodity_nkid, default_taxability, applicability_type_id, rid
        from tdr_etl_rule_calc_diffs d;


begin
            etl_proc_log_p ('CR_EXTRACT.GEN_CALC_CHANGES','GEN_CALC_CHANGES Start ==>  with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i,'GEN_CALC_CHANGES',jta_nkid_i,rid_i);

            for rc in rule_calc_changes(jta_nkid_i, rid_i, p_rid_i) loop
                if (p_rid_i is null) then
                    etl_proc_log_p ('CR_EXTRACT.GEN_CALC_CHANGES','GEN_CALC_CHANGES for inserts, with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i,'GEN_CALC_CHANGES',jta_nkid_i,rid_i);
                --if p_rid is null, this is brand new to this instance
                    insert into tdr_etl_rule_calc_diffs (jta_nkid, calculation_method, basis_percent, recoverable_percent, start_date, end_date, action,
                    recoverable_amount, -- related_charge, allocated_charges,
                    charge_type_id,
                    unit_of_measure, ref_rule_order,
                    commodity_id, commodity_nkid, default_taxability, applicability_type_id,
                    rid
                    )
                    values (rc.nkid, rc.calculation_method_id, rc.basis_percent, rc.recoverable_percent, rc.start_date, rc.end_date , 'Add',
                    rc.recoverable_amount, -- rc.related_charge, rc.allocated_charges,
                    rc.charge_type_id,
                    rc.unit_of_measure, rc.ref_rule_order,
                    rc.commodity_id, rc.commodity_nkid, rc.default_taxability, rc.applicability_type_id,
                    rc.rid
                    );
                else
                    etl_proc_log_p ('CR_EXTRACT.GEN_CALC_CHANGES','GEN_CALC_CHANGES for updates, with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i,'GEN_CALC_CHANGES',jta_nkid_i,rid_i);
                --if p_rid is not null, this is an update
                    insert into tdr_etl_rule_calc_diffs (jta_nkid, calculation_method, basis_percent, recoverable_percent, start_date, end_date, action,
                    recoverable_amount, --related_charge, allocated_charges,
                    charge_type_id,
                    unit_of_measure,
                    ref_rule_order,
                    commodity_id, commodity_nkid, default_taxability, applicability_type_id,
                    rid
                    )
                    values (rc.nkid, rc.calculation_method_id, rc.basis_percent, rc.recoverable_percent, rc.start_date, rc.end_date , 'Update',
                    rc.recoverable_amount, -- rc.related_charge, rc.allocated_charges,
                    rc.charge_type_id,
                    rc.unit_of_measure, rc.ref_rule_order,
                    rc.commodity_id, rc.commodity_nkid, rc.default_taxability, rc.applicability_type_id,
                    rc.rid
                    );

                end if;
            end loop;
            etl_proc_log_p ('CR_EXTRACT.GEN_CALC_CHANGES','GEN_CALC_CHANGES for updates, with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i,'GEN_CALC_CHANGES',jta_nkid_i,rid_i);

    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.GEN_CALC_CHANGES','GEN_CALC_CHANGES failed with '||sqlerrm,'GEN_CALC_CHANGES',NULL,NULL);
    RAISE_APPLICATION_ERROR(-20001,'Calc changes failed.');

end;

Procedure gen_appl_changes ( jta_nkid_i IN NUMBER, rid_i IN NUMBER, p_rid_i IN NUMBER )
is

        cursor rule_app_changes(nkid_i IN NUMBER, rid_i IN NUMBER, p_rid_i IN NUMBER) is
        (
         select distinct r.nkid, aty.name applicability_type, replace(upper(jti.reference_code),' (LOCAL)') reference_code,
            greatest(jta.start_date, tat.start_date) start_date,
            -- Changes for CRAPP-2713
            case when jta.end_date is null and tat.end_date is null then null
                 when tat.end_date is null and jta.end_date is not null then jta.end_date
                 when jta.end_date is null and tat.end_date is not null then tat.end_date
                 when jta.end_date is not null and tat.end_date is not null then least ( jta.end_date, tat.end_date)
            end end_date,
            -- Changes for CRAPP-2790
            nvl(tot1.short_text, tot2.short_text) short_text,
            c.nkid commodity_nkid,
            nvl(tat.ref_rule_order, jta.ref_rule_order) ref_rule_order, tat.id tat_id, tat.nkid tat_nkid,
            --nvl(tat.tax_type, jta.tax_type) tax_type,
            tt.code tax_type,
            nvl(jta.default_taxability, 0 ) default_taxability
        from content_repo.mv_juris_tax_app_revisions r
        left join content_repo.mv_tax_applicability_taxes tat on (
            tat.juris_Tax_applicability_nkid = r.nkid
            and tat.rid <= rid_i
            and nvl(tat.next_rid,9999999999) > rid_i)
        left join content_repo.etl_taxability_taxes jti on (tat.juris_tax_imposition_nkid = jti.nkid --and jti.next_rid is null
             )
        left join content_repo.tax_types tt on ( tt.id = tat.tax_type_id )
        join content_repo.mv_juris_tax_applicabilities jta on (
            jta.nkid = r.nkid
            and jta.rid <= rid_i
            and nvl(jta.next_rid,9999999999) > rid_i
          )
        join content_repo.applicability_types aty on (aty.id = jta.applicability_type_id)
        left join content_repo.mvcommodities c on ( jta.commodity_id = c.id )
        -- Changes for CRAPP-2683
        -- Changes for CRAPP-2790
        left join content_repo.mv_taxability_outputs tot1 ON ( tat.nkid = tot1.tax_applicability_tax_nkid AND jti.id IS NOT NULL     -- Added this to fix CRAPP-2682
                                               AND content_repo.rev_join(tot1.rid, r.id, COALESCE (tot1.next_rid, 9999999999)) = 1
                                             ) -- added for taxable records
        left join content_repo.mv_taxability_outputs tot2 ON ( jta.nkid = tot2.juris_tax_applicability_nkid
                                               AND content_repo.rev_join (tot2.rid, r.id, COALESCE (tot2.next_rid, 9999999999)) = 1  -- CRAPP-2760
                                             )
        where r.id = rid_i
        and r.nkid = nkid_i
        minus
        select distinct r.nkid, aty.name applicability_type, replace(upper(jti.reference_code),' (LOCAL)') reference_code,
            greatest(jta.start_date, tat.start_date) start_date,
            -- Changes for CRAPP-2713
            case when jta.end_date is null and tat.end_date is null then null
                 when tat.end_date is null and jta.end_date is not null then jta.end_date
                 when jta.end_date is null and tat.end_date is not null then tat.end_date
                 when jta.end_date is not null and tat.end_date is not null then least ( jta.end_date, tat.end_date)
            end end_date,
            -- Changes for CRAPP-2790
            nvl(tot1.short_text, tot2.short_text) short_text,
            c.nkid commodity_nkid, nvl(tat.ref_rule_order, jta.ref_rule_order) ref_rule_order,
            tat.id, tat.nkid tat_nkid,
            --nvl(tat.tax_type, jta.tax_type) tax_type,
            tt.code tax_type,
            nvl(jta.default_taxability, 0 ) default_taxability
        from content_repo.mv_juris_tax_app_revisions r
        left join content_repo.mv_tax_applicability_taxes tat on (
            tat.juris_Tax_applicability_nkid = r.nkid
            and tat.rid <= nvl(p_rid_i, -1 )
            and nvl(tat.next_rid,9999999999) > nvl(p_rid_i, -1 ))
        left join content_repo.ETL_Taxability_Taxes jti on (tat.juris_tax_imposition_nkid = jti.nkid --and jti.next_rid is null
            )

        left join content_repo.tax_types tt on ( tt.id = tat.tax_type_id )
        join content_repo.mv_juris_tax_applicabilities jta on (
            jta.nkid = r.nkid
            and jta.rid <= nvl(p_rid_i, -1 )
            and nvl(jta.next_rid,9999999999) > nvl(p_rid_i, -1 )
          )
        left join content_repo.mvcommodities c on ( jta.commodity_id = c.id )
        join content_repo.applicability_types aty on (aty.id = jta.applicability_type_id)
        -- Chanages for CRAPP-2683
        -- Changes for CRAPP-2790
        left join content_repo.mv_taxability_outputs tot1 ON ( tat.nkid = tot1.tax_applicability_tax_nkid AND jti.id IS NOT NULL     -- Added this to fix CRAPP-2682
                                               AND content_repo.rev_join(tot1.rid, r.id, COALESCE (tot1.next_rid, 9999999999)) = 1
                                             ) -- added for taxable records
        left join content_repo.mv_taxability_outputs tot2 ON ( jta.nkid = tot2.juris_tax_applicability_nkid
                                               AND content_repo.rev_join (tot2.rid, r.id, COALESCE (tot2.next_rid, 9999999999)) = 1  -- CRAPP-2760
                                             )
        where r.id = nvl(p_rid_i, -1 )
        and r.nkid = nkid_i
        )
        minus
        select jta_nkid, app_type, rate_code, start_date, end_date, inv_desc, commodity_nkid, ref_rule_order, tat_id,
                tat_nkid, tax_type, default_taxability
        from tdr_etl_rule_app_diffs;

        -- Changes for CRAPP-2696
        cursor just_rule_appl (nkid_i IN NUMBER, rid_i IN NUMBER) is
         select distinct r.nkid, aty.name applicability_type, replace(upper(jti.reference_code),' (LOCAL)') reference_code,
            greatest(jta.start_date, tat.start_date) start_date,
            case when jta.end_date is null and tat.end_date is null then null
                 when tat.end_date is null and jta.end_date is not null then jta.end_date
                 when jta.end_date is null and tat.end_date is not null then tat.end_date
                 when jta.end_date is not null and tat.end_date is not null then least ( jta.end_date, tat.end_date)
            end end_date,
            -- Changes for CRAPP-2790
            nvl(tot1.short_text, tot2.short_text) short_text,
            c.nkid commodity_nkid,
            nvl(tat.ref_rule_order, jta.ref_rule_order) ref_rule_order, tat.id tat_id, tat.nkid tat_nkid,
            --nvl(tat.tax_type, jta.tax_type) tax_type,
            tt.code tax_type,
            nvl(jta.default_taxability, 0 ) default_taxability
        from content_repo.mv_juris_tax_app_revisions r
        left join content_repo.mv_tax_applicability_taxes tat on (
            tat.juris_Tax_applicability_nkid = r.nkid
            and tat.rid <= rid_i
            and nvl(tat.next_rid,9999999999) > rid_i)
        left join content_repo.ETL_Taxability_Taxes jti on (tat.juris_tax_imposition_nkid = jti.nkid --and jti.next_rid is null
                )
        left join content_repo.tax_types tt on ( tt.id = tat.tax_type_id)
        join content_repo.mv_juris_tax_applicabilities jta on (
            jta.nkid = r.nkid
            and jta.rid <= rid_i
            and nvl(jta.next_rid,9999999999) > rid_i
          )
        join content_repo.applicability_types aty on (aty.id = jta.applicability_type_id)
        left join content_repo.mvcommodities c on ( jta.commodity_id = c.id )
        -- Changes for CRAPP-2683
        -- Chnages for CRAPP-2790
        left join content_repo.mv_taxability_outputs tot1 ON ( tat.nkid = tot1.tax_applicability_tax_nkid AND jti.id IS NOT NULL     -- Added this to fix CRAPP-2682
                                               AND content_repo.rev_join(tot1.rid, r.id, COALESCE (tot1.next_rid, 9999999999)) = 1
                                             ) -- added for taxable records
        left join content_repo.mv_taxability_outputs tot2 ON ( jta.nkid = tot2.juris_tax_applicability_nkid
                                               AND content_repo.rev_join (tot2.rid, r.id, COALESCE (tot2.next_rid, 9999999999)) = 1  -- CRAPP-2760
                                             )
        where r.id = rid_i
        and r.nkid = nkid_i;

begin
            etl_proc_log_p ('CR_EXTRACT.GEN_APPL_CHANGES','GEN_APPL_CHANGES START =>, with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i,'GEN_APPL_CHANGES',jta_nkid_i,rid_i);
            for ra in rule_app_changes(jta_nkid_i, rid_i, p_rid_i) loop
                if (p_rid_i is null) then
                etl_proc_log_p ('CR_EXTRACT.GEN_APPL_CHANGES','GEN_APPL_CHANGES for inserts, with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i,'GEN_APPL_CHANGES',jta_nkid_i,rid_i);
                --if p_rid is null, that means there has been no previously extract revision, this record is brand new to this instance
                    insert into tdr_etl_rule_app_diffs (jta_nkid, app_type, rate_code, commodity_nkid, inv_desc, start_date, end_date, action,
                            ref_rule_order, tat_id, tat_nkid, default_taxability, tax_type)
                    values (ra.nkid, ra.applicability_type, ra.reference_code, ra.commodity_nkid , ra.short_text, ra.start_date, ra.end_date, 'Add',
                            ra.ref_rule_order, ra.tat_id, ra.tat_nkid, ra.default_taxability, ra.tax_type);
                else
                    etl_proc_log_p ('CR_EXTRACT.GEN_APPL_CHANGES','GEN_APPL_CHANGES for updates, with p_rid_i:'||p_rid_i||', jta_nkid_i:'||jta_nkid_i,'GEN_APPL_CHANGES',jta_nkid_i,rid_i);
                --if p_rid is not null, this is an update
                    insert into tdr_etl_rule_app_diffs (jta_nkid, app_type, rate_code, commodity_nkid, inv_desc, start_date, end_date, action,
                        ref_rule_order, tat_id, tat_nkid, default_taxability, tax_type)
                    values (ra.nkid, ra.applicability_type, ra.reference_code, ra.commodity_nkid , ra.short_text, ra.start_date, ra.end_date, 'Update',
                            ra.ref_rule_order, ra.tat_id, ra.tat_nkid, ra.default_taxability, ra.tax_type);
                end if;

            end loop;
            -- Changes for CRAPP-2696
            for nc in (
                select distinct jta_nkid
                from tdr_etl_rule_calc_diffs ad
                where not exists (
                    select 1
                    from tdr_etl_rule_app_diffs cd
                    where cd.jta_nkid = ad.jta_nkid
                    )
                --  and applicability_type_id = 1
                )
            loop
                for just_appl in just_rule_appl ( nc.jta_nkid, rid_i )
                loop
                    etl_proc_log_p ('CR_EXTRACT.GEN_APPL_CHANGES','GEN_APPL_CHANGES just_rule_appl cursor, with nc.jta_nkid:'||nc.jta_nkid||', rid:'||rid_i,'GEN_APPL_CHANGES',jta_nkid_i,rid_i);
                    -- Changes for CRAPP-3869, Added tax_type
                    insert into tdr_etl_rule_app_diffs (jta_nkid, app_type, rate_code, commodity_nkid, inv_desc, start_date, end_date, action,
                            ref_rule_order, tat_id, tat_nkid, default_taxability, tax_type)
                    values (just_appl.nkid, just_appl.applicability_type, just_appl.reference_code, just_appl.commodity_nkid , just_appl.short_text, just_appl.start_date,
                            just_appl.end_date, 'Add', just_appl.ref_rule_order, just_appl.tat_id, just_appl.tat_nkid, just_appl.default_taxability, just_appl.tax_type);
                end loop;
            end loop;
            etl_proc_log_p ('CR_EXTRACT.GEN_APPL_CHANGES','GEN_APP_CHANGES END ==>','GEN_APPL_CHANGES',jta_nkid_i,rid_i);

    Exception
    when others then
    etl_proc_log_p('CR_EXTRACT.GEN_APPL_CHANGES','GEN_APPL_CHANGES failed with '||sqlerrm,'GEN_CAPPL_CHANGES',NULL,NULL);
    RAISE_APPLICATION_ERROR(-20001,'Gen app error.');

end;


Procedure gen_qual_changes ( jta_nkid_i IN NUMBER, rid_i IN NUMBER, p_rid_i IN NUMBER )
is

        cursor rule_qual_changes(nkid_i IN NUMBER, rid_i IN NUMBER, p_rid_i IN NUMBER) is
        (select distinct r.nkid, nvl(te.element_name,'AUTHORITY') element_name, ttq.logical_qualifier, ttq.value, ttq.reference_group_nkid, ttq.jurisdiction_nkid, ttq.start_date, ttq.end_date
        from content_repo.mv_juris_tax_app_revisions r
        join content_repo.mv_tran_Tax_qualifiers ttq on (
            ttq.juris_tax_applicability_nkid = r.nkid
            and ttq.rid <= rid_i
            and nvl(ttq.next_rid,9999999999) > rid_i)
        left outer join content_repo.taxability_elements te on (te.id = ttq.taxability_element_id)
        where r.id = rid_i
        and ttq.juris_tax_applicability_nkid =nkid_i
        minus
        select distinct r.nkid, nvl(te.element_name,'AUTHORITY') element_name, ttq.logical_qualifier, ttq.value, ttq.reference_group_nkid, ttq.jurisdiction_nkid, ttq.start_date, ttq.end_date
        from content_repo.mv_juris_tax_app_revisions r
        join content_repo.mv_tran_Tax_qualifiers ttq on (
            ttq.juris_tax_applicability_nkid = r.nkid
            and ttq.rid <= nvl(p_rid_i,-1)
            and nvl(ttq.next_rid,9999999999) > nvl(p_rid_i,-1))
        left outer join content_repo.taxability_elements te on (te.id = ttq.taxability_element_id)
        where r.id = nvl(p_rid_i,-1)
        and ttq.juris_tax_applicability_nkid =nkid_i)
        minus
        select jta_nkid, element, operator, value, reference_group_nkid, jurisdiction_nkid, start_date, end_date
        from tdr_etl_rule_qual_diffs;

begin
            etl_proc_log_p ('CR_EXTRACT.GEN_QUAL_CHANGES','GEN_QUAL_CHANGES START =>, with jta_nkid_i:'||jta_nkid_i||', p_rid_i:'||p_rid_i,'GEN_QUAL_CHANGES',jta_nkid_i,rid_i);
            for rq in rule_qual_changes(jta_nkid_i, rid_i, p_rid_i) loop
                if (p_rid_i is null) then
                    etl_proc_log_p ('CR_EXTRACT.GEN_QUAL_CHANGES','GEN_QUAL_CHANGES adds, with jta_nkid_i:'||jta_nkid_i||', p_rid_i:'||p_rid_i,'GEN_QUAL_CHANGES',jta_nkid_i,rid_i);
                --if p_rid is null, that means there has been no previously extract revision, this record is brand new to this instance
                    insert into tdr_etl_rule_qual_diffs (jta_nkid, element, operator, value, reference_group_nkid, jurisdiction_nkid, start_date, end_date, action)
                    values (rq.nkid, rq.element_name, rq.logical_qualifier, rq.value, rq.reference_group_nkid, rq.jurisdiction_nkid, rq.start_date, rq.end_date , 'Add');
                else
                --if p_rid is not null, this is an update
                    etl_proc_log_p ('CR_EXTRACT.GEN_QUAL_CHANGES','GEN_QUAL_CHANGES updates, with jta_nkid_i:'||jta_nkid_i||', p_rid_i:'||p_rid_i,'GEN_QUAL_CHANGES',jta_nkid_i,rid_i);
                    insert into tdr_etl_rule_qual_diffs (jta_nkid, element, operator, value, reference_group_nkid, jurisdiction_nkid, start_date, end_date, action)
                    values (rq.nkid, rq.element_name, rq.logical_qualifier, rq.value, rq.reference_group_nkid, rq.jurisdiction_nkid, rq.start_date, rq.end_date , 'Update');
                end if;
            end loop;
            etl_proc_log_p('CR_EXTRACT.GEN_QUAL_CHANGES','GEN_QUAL_CHANGES Completed','GEN_QUAL_CHANGES',NULL,NULL);
	  exception
    when others then
    etl_proc_log_p('CR_EXTRACT.GEN_QUAL_CHANGES','GEN_QUAL_CHANGES Failed with '||sqlerrm,'GEN_QUAL_CHANGES',NULL,NULL);
    RAISE_APPLICATION_ERROR(-20001,'Rule qualifier changes failed.');

end;

procedure insert_rule_changes(jta_nkid_i IN NUMBER, rid_i IN NUMBER, p_rid_i IN NUMBER)
    IS
        cursor just_rule_calc(nkid_i IN NUMBER, rid_i IN NUMBER) is
        select distinct r.nkid, to_number(cm.name) calculation_method_id, nvl(jta.basis_percent,100) basis_percent, jta.recoverable_percent,
        jta.start_date, jta.end_date,
        rid_i rid
        from content_repo.mv_juris_tax_app_revisions r
        join content_repo.mv_juris_tax_applicabilities jta on (
            jta.nkid = r.nkid
            and jta.rid <= rid_i
            and nvl(jta.next_rid,9999999999) > rid_i)
        join content_repo.calculation_methods cm on (cm.id = jta.calculation_method_id)
        left join content_repo.charge_types c on ( c.id = jta.charge_type_id )
        left join content_repo.mvcommodities c on ( jta.commodity_nkid = c.nkid )
        where r.id = rid_i
        and r.nkid = nkid_i;

        cursor just_rule_qual(nkid_i IN NUMBER, rid_i IN NUMBER) is
        select distinct r.nkid, nvl(te.element_name,'AUTHORITY') element_name, ttq.logical_qualifier, ttq.value, ttq.reference_group_nkid,
        ttq.jurisdiction_nkid, ttq.start_date, ttq.end_date
        from content_repo.mv_juris_tax_app_revisions r
        join content_repo.mv_tran_Tax_qualifiers ttq on (
            ttq.juris_tax_applicability_nkid = r.nkid
            and ttq.rid <= rid_i
            and nvl(ttq.next_rid,9999999999) > rid_i)
        left outer join content_repo.taxability_elements te on (te.id = ttq.taxability_element_id)
        where r.id = rid_i
        and ttq.juris_tax_applicability_nkid =nkid_i;
    BEGIN
           etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start Insert Rule Changes procedure','INSERT_RULE_CHANGES',NULL,NULL);
           etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Calling gen_calc_changes with jta_nkid_i:'||jta_nkid_i||', rid_i:'||rid_i||', p_rid_i:'||p_rid_i,'INSERT_RULE_CHANGES',jta_nkid_i,rid_i);
           gen_calc_changes(jta_nkid_i, rid_i, p_rid_i);
           etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Calling gen_appl_changes with jta_nkid_i:'||jta_nkid_i||', rid_i:'||rid_i||', p_rid_i:'||p_rid_i,'INSERT_RULE_CHANGES',jta_nkid_i,rid_i);
           gen_appl_changes(jta_nkid_i, rid_i, p_rid_i);
           etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Calling gen_qual_changes with jta_nkid_i:'||jta_nkid_i||', rid_i:'||rid_i||', p_rid_i:'||p_rid_i,'INSERT_RULE_CHANGES',jta_nkid_i,rid_i);
           gen_qual_changes(jta_nkid_i, rid_i, p_rid_i);

             --for any app_diffs that don't have a record in calc_diffs, put records in calc_diffs for the app_diffs
            etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start NC Loop','INSERT_RULE_CHANGES',jta_nkid_i,rid_i);
            for nc in (
                select distinct jta_nkid
                from tdr_etl_rule_app_diffs ad
                where not exists (
                    select 1
                    from tdr_etl_rule_calc_diffs cd
                    where cd.jta_nkid = ad.jta_nkid
                    )
                ) loop
                for jrc in just_rule_calc(nc.jta_nkid, rid_i) loop
                    etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Inside just_rule_calc cursor loop with jta_nkid_i:'||nc.jta_nkid||', rid_i:'||rid_i,'INSERT_RULE_CHANGES',nc.jta_nkid,rid_i);
                    insert into tdr_etl_rule_calc_diffs (jta_nkid, calculation_method, basis_percent, recoverable_percent, start_date, end_date, action, rid)
                    values (jrc.nkid, jrc.calculation_method_id, jrc.basis_percent, jrc.recoverable_percent, jrc.start_date, jrc.end_date , 'Add', jrc.rid);
                end loop;
            end loop;

            --for any taxabilities that have Conditions/Qualifiers, put records in qual_diffs if current Conditions don't exist in qual_diffs
            etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start NQ Loop','INSERT_RULE_CHANGES',jta_nkid_i,rid_i);
            for nq in (
                select distinct jta_nkid
                from tdr_etl_rule_calc_diffs cd
                where exists (
                    select 1
                    from content_repo.mv_tran_tax_qualifiers q
                     left outer join content_repo.taxability_elements te on (te.id = nvl(q.taxability_element_id,-1))
                    where q.juris_tax_Applicability_nkid = cd.jta_nkid
                    and q.next_rid is null
                    and not exists (
                        select 1
                        from tdr_etl_rule_qual_diffs qd
                        where qd.jta_nkid = q.juris_tax_Applicability_nkid
                        and nvl(te.element_name,'AUTHORITY') = qd.element
                        and qd.operator = q.logical_qualifier
                        and qd.start_date = q.start_date
                        and nvl(qd.end_Date,'31-Dec-9999') = nvl(q.end_Date,'31-Dec-9999')
                        and ((qd.element = 'AUTHORITY' and qd.jurisdiction_nkid = q.jurisdiction_nkid)
                            or (qd.operator like '%EXISTS%' and qd.reference_Group_nkid = q.reference_Group_nkid)
                            or (qd.operator not like '%EXISTS%' and qd.element != 'AUTHORITY' and qd.value = q.value)
                            )
                        )
                )
            ) loop
                for jrq in just_rule_qual(nq.jta_nkid, rid_i) loop
                    etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Inside just_rule_qual cursor loop with jta_nkid_i:'||nq.jta_nkid||', rid_i:'||rid_i,'INSERT_RULE_CHANGES',nq.jta_nkid,rid_i);
                    insert into tdr_etl_rule_qual_diffs (jta_nkid, element, operator, value, reference_group_nkid, jurisdiction_nkid, start_date, end_date, action)
                    values (jrq.nkid, jrq.element_name, jrq.logical_qualifier, jrq.value, jrq.reference_group_nkid, jrq.jurisdiction_nkid, jrq.start_date, jrq.end_date , 'Update');

                end loop;
            end loop;
            etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','End Insert Rule Changes procedure','Rule Data',NULL,NULL);
    exception
    when others then
        etl_proc_log_p('CR_EXTRACT.INSERT_RULE_CHANGES','INSERT_RULE_CHANGES Failed with '||sqlerrm,'INSERT_RULE_CHANGES',NULL,NULL);
        RAISE_APPLICATION_ERROR(-20001,'Queue records failed.');

    END insert_rule_changes;

PROCEDURE product_taxability_data_2
    IS

        cursor new_revisions is
          SELECT el1.nkid,
                   MAX (el2.rid) rid,
                   el2.rid p_rid,
                   jta.nkid jta_nkid
              FROM content_repo.mv_juris_tax_applicabilities jta
                   JOIN content_repo.mvcommodities c
                       ON (c.id = jta.commodity_id AND jta.next_rid IS NULL)
                   JOIN extract_log el1  -- CRAPP-3174, Removed schema reference
                       ON (c.nkid = el1.nkid AND el1.entity = 'COMMODITY')
                   LEFT OUTER JOIN
                   (SELECT nkid, MAX (rid) rid
                      FROM extract_log  -- CRAPP-3174, Removed schema reference
                     WHERE entity = 'COMMODITY' AND loaded IS NOT NULL --Changes for CRAPP-3907 and CRAPP-2478
                    GROUP BY nkid) el2
                       ON (el1.nkid = el2.nkid)
             WHERE el1.entity = 'COMMODITY' AND el1.loaded IS NULL --Changes for CRAPP-3907 and CRAPP-2478
            GROUP BY el1.nkid, el2.rid, jta.nkid;

        cursor comm_for_new is
        SELECT cr.nkid, cr.id rid, d.jta_nkid
          FROM content_repo.mv_commodity_revisions cr
               JOIN tdr_etl_rule_app_diffs d  -- CRAPP-3174, Removed schema reference
                   ON (d.commodity_nkid = cr.nkid) AND cr.next_rid IS NULL
         WHERE d.action = 'Add'
        UNION
        SELECT cg.nkid, cg.id rid, d.jta_nkid
          FROM content_repo.mv_commodity_revisions cg
               JOIN tdr_etl_rule_app_diffs d  -- CRAPP-3174, Removed schema reference
                   ON (d.commodity_nkid = cg.nkid) AND cg.next_rid IS NULL
         WHERE     d.action = 'Update'
               AND NOT EXISTS
                       (SELECT 1
                          FROM tdr_etl_rule_pt_diffs pd  -- CRAPP-3174, Removed schema reference
                         WHERE pd.jta_nkid = d.jta_nkid);

        cursor missing_affected_taxability is
        select distinct pd.jta_nkid, r.id rid --, commodity_group_nkid, pd.tas_nkid
        from tdr_etl_rule_pt_diffs pd
        join content_repo.mv_juris_tax_app_revisions r on (r.nkid = pd.jta_nkid and r.next_rid is null)
        where not exists (
            select 1
            from tdr_etl_rule_calc_diffs cd
            where cd.jta_nkid = pd.jta_nkid
            );

    BEGIN

        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start Product Taxability','COMMODITY',null, null);
        for c in comm_for_new loop
            etl_proc_log_p('CR_EXTRACT.PRODUCT_TAXABILITY_DATA','get pt records for changes in taxability','COMMODITY',c.nkid,c.rid);
            insert_pt_changes(c.nkid,c.rid,null,c.jta_nkid, null);
        end loop;
        etl_proc_log_p('CR_EXTRACT.PRODUCT_TAXABILITY_DATA','Start New Revisions loop','COMMODITY',null, null);
        FOR nr in new_revisions loop
            etl_proc_log_p('CR_EXTRACT.PRODUCT_TAXABILITY_DATA','Inside new revisions loops with nr.p_rid:'||nr.p_rid||', nr.jta_nkid:'||nr.jta_nkid,'COMMODITY',nr.nkid,nr.rid);
            insert_pt_changes(nr.nkid,nr.rid,nr.p_rid,nr.jta_nkid,null);

            --end loop;
            commit;
        end loop;
        etl_proc_log_p('CR_EXTRACT.PRODUCT_TAXABILITY_DATA','Start Missing Effected Taxabilities','COMMODITY',null, null);
        FOR mat in missing_affected_taxability loop
			      etl_proc_log_p('CR_EXTRACT.PRODUCT_TAXABILITY_DATA','Missing Effected Taxabilities cursor loop','COMMODITY',mat.jta_nkid, mat.rid);
            insert_rule_changes(mat.jta_nkid,mat.rid,null);
        end loop;

        commit;
        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','End Product Taxability','COMMODITY',null, null);
    exception
    when others then
        etl_proc_log_p('CR_EXTRACT.PRODUCT_TAXABILITY','PRODUCT_TAXABILITY failed with '||sqlerrm,'PRODUCT_TAXABILITY',NULL,NULL);
        RAISE_APPLICATION_ERROR(-20001,'Product taxability failed.');

    END product_taxability_data_2;

    procedure update_levels is
        cursor rule_product_levels is
        select nkid, hierarchy_level hierarchy_level
        from tdr_etl_rule_products
        group by nkid, hierarchy_level;

    begin
        for rpl in rule_product_levels loop

            update tdr_etl_rule_products rp
            set highest_level = rpl.hierarchy_level, lowest_level = rpl.hierarchy_level
            where nkid = rpl.nkid;
            commit;

        end loop;

    exception
    when others then
        RAISE_APPLICATION_ERROR(-20001,'Update of levels failed.');

    end update_levels;

    procedure update_sibling_order
    is

        -- At each level provide the rankings based on the length(h_code)
        /*

        Length      Sibling Order
          4         1
          4         2
          4         3
          8         1
          8         2
          12        1
          12        2
        */

        cursor product_levels is
        select pt.name, length(h_code) hierarchy_level, c.nkid commodity_nkid,
            row_number() over (partition by pt.name, length(h_code) order by c.nkid)  sibling_order
        from content_repo.mvcommodities c
        join content_repo.product_trees pt on (pt.id = c.product_tree_id)
        where exists (
            select 1
            from tdr_etl_rule_products rp
            where rp.product_Tree_id = pt.id
            )
        group by pt.name, length(h_code) , c.nkid;
    begin
        for pl in product_levels loop

            update tdr_etl_rule_products rp
            set sibling_order = pl.sibling_order
            where rp.commodity_nkid = pl.commodity_nkid;

            update tdr_etl_product_exceptions rp
            set sibling_order = pl.sibling_order
            where exists (
                select 1
                from mp_comm_prods cp
                where cp.product_category_id = rp.product_category_id
                and cp.commodity_nkid = pl.commodity_nkid
                );

        end loop;
        commit;

    exception
    when others then
        RAISE_APPLICATION_ERROR(-20001,'Update order failed.');

    end update_sibling_order;

    procedure rule_data_2
    IS
        cursor new_revisions is
        select el.nkid, max(el.rid) rid, el2.rid p_rid
        from extract_log el
        left outer join (
            select nkid, max(rid) rid
            from extract_log
            where entity = 'TAXABILITY'
            --Changes for CRAPP-3907 and CRAPP-2478
            and loaded is not null
            group by nkid
            ) el2 on (el.nkid = el2.nkid)
        where el.entity = 'TAXABILITY'
        --Changes for CRAPP-3907 and CRAPP-2478
        and el.loaded is null
        group by el.nkid, el2.rid;

    BEGIN

        -- These are the new commodity related taxability related that didn't get pulled over.
        -- Checking again here to see if the commodities get ETLed, So that these taxabilities will get ETLed.
        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Starting Rule Extract','Rule Data',NULL,NULL);

        INSERT INTO extract_log (tag_group, entity,  nkid, rid) (
        select 'Determination (All versions), United States', 'TAXABILITY', nkid, rid from juris_tax_app_skip_etl a
            where not exists ( select 1 from extract_log b where b.nkid = a.nkid and a.rid > b.rid
            --Changes for CRAPP-3907 and CRAPP-2478
            and loaded is not null)
        MINUS
        SELECT 'Determination (All versions), United States', entity, nkid, rid
        FROM extract_log);

        execute immediate 'truncate table juris_tax_app_skip_etl';  -- CRAPP-3174, Removed schema reference
        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start Rule Qualifier Mapping','Rule Data',NULL,NULL);
        det_transform.map_jta_rq;

        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start New Revision Rules','Rule Data',NULL,NULL);
        FOR nr in new_revisions loop
            begin
                insert_rule_changes(nr.nkid,nr.rid,nr.p_rid);
            exception
            when others then
                etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Calling insert_rule_changes, with nr.p_rid:'||nr.p_rid,'Rule Data',nr.nkid,nr.rid);
                RAISE_APPLICATION_ERROR(-20001,'Rule data error, failed at new_revisions loop.');
            end;
        end loop;

        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start Product Taxability','Rule Data',NULL,NULL);
        product_taxability_data_2;

            etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start loading tdr_etl_rules table','Rule Data',NULL,NULL);
            INSERT INTO tdr_etl_rules (authority_uuid,
                                   nkid,
                                   calculation_method,
                                   basis_percent,
                                   recoverable_percent,
                                   start_date,
                                   end_date,
                                   rule_qualifier_set,
                                   exempt,
                                   no_tax,
                                   rate_code,
                                   is_local,
                                   rule_qual_order,
                                   ref_rule_order,
                                   allocated_charge,
                                   unit_of_measure,
                                   related_charge,
                                   recoverable_amount,
                                   commodity_id,
                                   commodity_nkid,
                                   tax_type,
                                   default_taxability,
                                   rid
                                   )
                (SELECT DISTINCT
                        ja.authority_uuid,
                        c.jta_nkid,
                        c.calculation_method,
                        c.basis_percent,
                        c.recoverable_percent,
                        coalesce(nvl(p.start_date,c.start_date), nvl(a.start_date,c.start_date)) start_date,
                        -- Changes for CRAPP-2713
                        case when a.end_date is null and p.end_date is null then null
                             when a.end_date is not null and p.end_date is null then a.end_date
                             when p.end_date is not null and a.end_date is null then p.end_date
                             when p.end_date is not null and a.end_date is not null then least ( p.end_date, a.end_date )
                        end end_date,
                        trq.rule_qualifier_set,
                        CASE WHEN a.app_type = 'Exempt' THEN 'Y' ELSE 'N' END exempt,
                        CASE WHEN a.app_type = 'No Tax' THEN 'Y' ELSE 'N' END no_tax,
                        a.rate_code,
                        nvl(jta.is_local, 'N') is_local,
                        NVL (trq.rq_order, 0) rq_order,
                        nvl(a.ref_rule_order, jta.ref_rule_order),
                        case when ct.ABBREVIATION = 'AC' then 'Y' else 'N' end allocated_charges,
                        c.unit_of_measure,
                        case when ct.ABBREVIATION = 'RC' then 'Y' else 'N' end related_charge,
                        c.recoverable_amount,
                        c.commodity_id,
                        c.commodity_nkid,
                        a.tax_type,
                        c.default_taxability,
                        c.rid
                   FROM tdr_etl_rule_calc_diffs c  -- CRAPP-3174, Removed schema reference
                        JOIN content_repo.mv_juris_tax_applicabilities jta on ( jta.nkid = c.jta_nkid )
                        JOIN mp_juris_auths ja ON (ja.nkid = jta.jurisdiction_nkid)
                        LEFT JOIN tdr_etl_rule_app_diffs a   ON (a.jta_nkid = c.jta_nkid)
                        LEFT JOIN tdr_etl_rule_pt_diffs p    ON (p.jta_nkid = a.jta_nkid )
                        LEFT JOIN content_repo.charge_types ct on ( ct.id = c.charge_type_id )
                        LEFT OUTER JOIN
                        (SELECT jta_nkid, rq_order, s.rule_qualifier_set
                           FROM (SELECT juris_nkid,
                                        rule_qualifier_set,
                                        ROW_NUMBER ()
                                        OVER (PARTITION BY juris_nkid
                                              ORDER BY rule_qualifier_set)
                                            rq_order
                                   FROM mp_jta_rq

                                 GROUP BY juris_nkid, rule_qualifier_set) s

                                JOIN mp_jta_rq mr

                                    ON (    mr.juris_nkid = s.juris_nkid
                                        AND mr.rule_qualifier_set = s.rule_qualifier_set)
                                      )trq
                            ON (trq.jta_nkid = a.jta_nkid)
                      );

     /* Changes for CRAPP-2788
            If the product is not yet created in Determination, Then don't create any rules associated with the new products.
            Try with the next ETL and do the same checks

            1) Check if the commodity has been already moved to Determination or not.
            2) If yes, process the taxability.
            3) If not, then remove from extract_log and temp tables
            4) Add into the queue for next ETL
            5) Process it with the next ETL
            6) Follow the same steps.
        */
        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start processing skipped records','Rule Data',NULL,NULL);
        INSERT INTO juris_tax_app_skip_etl  -- CRAPP-3174, Removed schema reference
        SELECT distinct tr.nkid, tr.rid, 'Taxability', 'Commodity Not Published', tl.tag_list
          FROM tdr_etl_rules tr join content_repo.tdr_etl_extract_list tl on tr.nkid = tl.nkid and tr.rid = tl.rid
         WHERE commodity_nkid IS NOT NULL
               AND NOT EXISTS
                       (SELECT 1
                          FROM mp_comm_prods mp
                         WHERE mp.commodity_nkid = tr.commodity_nkid);

        INSERT INTO juris_tax_app_skip_etl  -- CRAPP-3174, Removed schema reference
        SELECT distinct tr.nkid, tr.rid, 'Taxability', 'Missing rule order information', tl.tag_list
          FROM tdr_etl_rules tr join content_repo.tdr_etl_extract_list tl on tr.nkid = tl.nkid and tr.rid = tl.rid
          where ref_rule_order is null;

        -- Removing from this table will not transform the taxabilities
         DELETE FROM tdr_etl_rules tr  -- CRAPP-3174, Removed schema reference
          WHERE EXISTS
           (SELECT 1
              FROM juris_tax_app_skip_etl tn
             WHERE tn.nkid = tr.nkid AND tn.rid = tr.rid);

        -- Removing from this table will allow for the NEXT ETL.
          DELETE FROM extract_log tr
          WHERE EXISTS
           (SELECT 1
              FROM juris_tax_app_skip_etl tn
             WHERE tn.nkid = tr.nkid AND tn.rid = tr.rid);

        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','End processing skipped records','Rule Data',NULL,NULL);
        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start loading Invoice Description','Rule Data',NULL,NULL);
        INSERT INTO tdr_etl_jta_inv_desc (authority_uuid,
                                                end_date,
                                                invoice_description,
                                                nkid,
                                                rid,
                                                start_date,
                                                tat_id)
            (SELECT DISTINCT authority_uuid,
                             d.end_date,
                             inv_desc,
                             jta_nkid,
                             rid,
                             d.start_date,
                             tat_id
               FROM tdr_etl_rule_app_diffs d
                    JOIN content_repo.mv_juris_tax_applicabilities jta
                        ON (jta.nkid = d.jta_nkid)
                    JOIN mp_juris_auths ja ON (ja.nkid = jta.jurisdiction_nkid));

        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start loading qualifiers','Rule Data',NULL,NULL);
        INSERT INTO tdr_etl_rule_qualifiers (authority_uuid,
                                     end_date,
                                     jta_nkid,
                                     logical_qualifier,
                                     nkid,
                                     reference_group_name,
                                     reference_group_nkid,
                                     rid,
                                     rule_qualifier_set,
                                     start_date,
                                     taxability_element,
                                     VALUE)
        (SELECT DISTINCT authority_uuid,
                         d.end_date,
                         d.jta_nkid,
                         operator,
                         d.jta_nkid,
                         rg.name,
                         reference_group_nkid,
                         jta.rid,
                         rule_qualifier_set,
                         d.start_date,
                         element,
                         VALUE
           FROM tdr_etl_rule_qual_diffs d  -- CRAPP-3174, Removed schema reference
                JOIN mp_jta_rq rq ON (rq.jta_nkid = d.jta_nkid)
                JOIN content_repo.mv_juris_tax_applicabilities jta
                    ON (jta.nkid = d.jta_nkid AND jta.next_rid IS NULL)
                LEFT OUTER JOIN mp_juris_auths ja
                    ON (ja.nkid = NVL (d.jurisdiction_nkid, -1))
                LEFT OUTER JOIN content_repo.mvreference_groups1 rg
                    ON (rg.nkid = NVL (d.reference_group_nkid, -1))
          WHERE rq.jta_nkid = jta.nkid);

          etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start loading products','Rule Data',NULL,NULL);
            INSERT INTO tdr_etl_rule_products (authority_uuid,
                                   commodity_nkid,
                                   end_date,
                                   exempt,
                                   hierarchy_level,
                                   highest_level,
                                   h_code,
                                   is_local,
                                   lowest_level,
                                   nkid,
                                   no_tax,
                                   product_tree,
                                   product_tree_id,
                                   rate_code,
                                   rule_qualifier_set,
                                   sibling_order,
                                   start_date,

                                   tax_type)
             SELECT DISTINCT
                ja.authority_uuid,
                r.commodity_nkid,
                p.end_date,
                CASE WHEN a.app_type = 'Exempt' THEN 'Y' ELSE 'N' END exempt,
                LENGTH (h_code) / 4,
                -1,
                co.h_code,
                r.is_local is_local,
                10,
                c.jta_nkid,
                CASE WHEN a.app_type = 'No Tax' THEN 'Y' ELSE 'N' END no_tax,
                pt.name product_tree,
                pt.id,
                a.rate_code,
                r.rule_qualifier_set,
                0,
                p.start_date,
                a.tax_type
    --            a.tas_nkid
            FROM tdr_etl_rule_calc_diffs c
              LEFT JOIN tdr_etl_rule_app_diffs a ON (a.jta_nkid = c.jta_nkid)
                JOIN tdr_etl_rules r
                    ON (r.nkid = c.jta_nkid )
              LEFT JOIN tdr_etl_rule_pt_diffs p
                    ON (p.jta_nkid = a.jta_nkid )
              LEFT JOIN content_repo.mvcommodities co
                    ON (co.nkid = r.commodity_nkid AND co.next_rid IS NULL)
                JOIN content_repo.product_trees pt
                    ON (pt.id = co.product_tree_id)
                JOIN content_repo.mv_juris_tax_applicabilities jta
                    ON (jta.nkid = c.jta_nkid)
                JOIN mp_juris_auths ja ON (ja.nkid = jta.jurisdiction_nkid)
               /*
                LEFT OUTER JOIN
                (SELECT DISTINCT jta.juris_tax_applicability_nkid
                   FROM crapp_extract.juris_tax_app_attributes jta
                        JOIN crapp_extract.additional_attributes aa
                            ON (aa.id = jta.attribute_id)
                  WHERE aa.name LIKE '%Cascading%') il
                    ON (il.juris_tax_applicability_nkid = c.jta_nkid)
                */
                  ;

        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start deleteing unnecessary products','Rule Data',NULL,NULL);
        DELETE FROM tdr_etl_rule_products r
         WHERE     no_tax = 'N'
               AND exempt = 'N'
               AND EXISTS
                       (SELECT 1
                          FROM tdr_etl_rule_products r2
                         WHERE     r2.commodity_nkid = r.commodity_nkid
                               AND r.authority_uuid = r2.authority_uuid
                               AND r2.start_date = r.start_date
                               AND r.rate_code = r2.rate_code
                               AND NVL (r.rule_qualifier_set, 'xx') =
                                       NVL (r2.rule_qualifier_set, 'xx')
                               AND NVL (r.end_date, '31-dec-9999') =
                                       NVL (r2.end_date, '31-dec-9999')
                               AND r2.exempt = 'Y');

        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start update levels','Rule Data',NULL,NULL);
         update_levels;
        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start product exceptions','Rule Data',NULL,NULL);
        get_product_exceptions;
        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','Start sibling order','Rule Data',NULL,NULL);
        update_sibling_order;
        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','End Rule Extract','Rule Data',NULL,NULL);
    exception
    when others then
        etl_proc_log_p('CR_EXTRACT.RULE_DATA_2','RULE_DATA_2 failed with '||sqlerrm,'RULE_DATA_2',NULL,NULL);
        RAISE_APPLICATION_ERROR(-20001,'Rule data error.');

    END rule_data_2;

    PROCEDURE local_extract(package_i IN VARCHAR2, entity_i IN VARCHAR2)
    IS
    BEGIN
        etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','Start Local Extract.',entity_i,NULL,NULL);
        IF (entity_i = 'AUTHORITIES') THEN
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','executing CR_EXTRACT.AUTHORITY_DATA('||package_i||')',entity_i,NULL,NULL);
            authority_data(package_i);
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','executing CR_EXTRACT.AUTHORITY_DATA('||package_i||') finished',entity_i,NULL,NULL);
        ELSIF (entity_i = 'RATES') THEN
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','executing CR_EXTRACT.RATE_DATA('||package_i||')',entity_i,NULL,NULL);
            rate_data;
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','executing CR_EXTRACT.RATE_DATA('||package_i||') Finished',entity_i,NULL,NULL);
        ELSIF (entity_i = 'REFERENCE GROUP') THEN
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','executing CR_EXTRACT.REFERENCE_DATA)',entity_i,null,null);
            reference_data;
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','CR_EXTRACT.REFERENCE_DATA finished',entity_i,null,null);
        ELSIF (entity_i = 'RULES') THEN
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','executing CR_EXTRACT.RULE_DATA)',entity_i,null,null);
            rule_data_2;
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','CR_EXTRACT.RULE_DATA finished',entity_i,null,null);
        ELSIF (entity_i = 'PRODUCTS') THEN
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','executing CR_EXTRACT.PRODUCT_DATA)',entity_i,null,null);
            product_data;
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','CR_EXTRACT.PRODUCT_DATA finished',entity_i,null,null);
        /*
        ELSIF (entity_i = 'ZONES') THEN
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','executing CR_EXTRACT.ZONE_DATA)',entity_i,null,null);
            zone_data;
            etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','CR_EXTRACT.ZONE_DATA finished',entity_i,null,null);
            --zone_authority_data;
            INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
            VALUES ('CR_EXTRACT.LOCAL_EXTRACT','CR_EXTRACT.ZONE_DATA finished',entity_i,null,null);
        */
        END IF;
        set_extracted_date(upper(entity_i));

        COMMIT;

    exception
    when others then
    etl_proc_log_p('CR_EXTRACT.LOCAL_EXTRACT','CR_EXTRACT failed with '||sqlerrm,entity_i,null,null);
    RAISE_APPLICATION_ERROR(-20001,'Local extract failed.');

    END local_extract;


    PROCEDURE queue_records(package_i IN VARCHAR2)
    IS
        l_qc number;
    BEGIN
        etl_proc_log_p ('CR_EXTRACT.QUEUE_RECORDS','Process started','QUEUE_RECORDS',null,null);

        INSERT INTO extract_log (tag_group, entity,  nkid, rid) (
        SELECT package_i, entity, nkid, rid
        FROM  content_repo.tdr_etl_extract_list
        MINUS
        SELECT package_i, entity, nkid, rid
        FROM extract_log
        );
        l_qc := sql%rowcount;
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('CR_EXTRACT.QUEUE_RECORDS',l_qc||' new revisions',null,null,null);
        COMMIT;
        INSERT INTO etl_proc_log (action, message, entity) (
        SELECT 'CR_EXTRACT.QUEUE_RECORDS',count(*)||' unextracted revisions',entity
        from extract_log
        WHERE extract_date is null
        group by entity);
        COMMIT;

    exception
    when others then
        etl_proc_log_p ('CR_EXTRACT.QUEUE_RECORDS','Process failed with '||sqlerrm,'QUEUE_RECORDS',null,null);
        RAISE_APPLICATION_ERROR(-20001,'Queue records failed.');

    END;

    PROCEDURE empty_tmp
    IS
    BEGIN
        etl_proc_log_p ('CR_EXTRACT.EMPTY_TMP','truncating tmp_ tables',null,null,null);

        execute immediate 'truncate table tdr_etl_authority_base';
        execute immediate 'truncate table tdr_etl_cntr_authorities';
        execute immediate 'truncate table tdr_etl_rates';
        execute immediate 'truncate table tdr_etl_rules';
        execute immediate 'truncate table tdr_etl_rule_products';
        execute immediate 'truncate table tdr_etl_rule_qualifiers';
        execute immediate 'truncate table tdr_etl_product_exceptions';
        execute immediate 'truncate table tdr_etl_jta_inv_desc';
        execute immediate 'truncate table tdr_etl_rule_calc_diffs';
        execute immediate 'truncate table tdr_etl_rule_app_diffs';
        execute immediate 'truncate table tdr_etl_rule_pt_diffs';
        execute immediate 'truncate table tdr_etl_rule_qual_diffs';
        execute immediate 'truncate table tdr_etl_product_categories';
        execute immediate 'truncate table tdr_etl_ct_product_tree'; -- dlg
        execute immediate 'truncate table tdr_etl_prod_changes';
        execute immediate 'truncate table tdr_etl_reference_lists'; -- CRAPP-809 dlg
        execute immediate 'truncate table tdr_etl_reference_values';

    exception
    when timeout_on_resource then
        etl_proc_log_p('CR_EXTRACT.EMPTY_TMP','EMPTY_TMP failed with '||SQLERRM,'GIS',NULL,NULL);
        RAISE_APPLICATION_ERROR(-20001,'Temp tables timeout cleaning');

    END empty_tmp;

    procedure remove_local_extract(entity_i IN VARCHAR2, etl_id_i IN NUMBER)
    IS
    BEGIN

        IF (entity_i = 'AUTHORITIES') THEN
            delete from tdr_etl_authority_base WHERE extract_id = etl_id_i;
        ELSIF (entity_i = 'RATES') THEN
            delete from tdr_etl_rates WHERE extract_id = etl_id_i;
        ELSIF (entity_i = 'PRODUCTS') THEN
            delete from tdr_etl_product_categories WHERE extract_id = etl_id_i;
            delete from tdr_etl_prod_changes WHERE extract_id = etl_id_i;
        ELSIF (entity_i = 'RULES') THEN
            delete from tdr_etl_rules WHERE extract_id = etl_id_i;
            delete from tdr_etl_jta_inv_desc WHERE extract_id = etl_id_i;
            --delete from tdr_etl_rule_taxes WHERE extract_id = etl_id_i;
            delete from tdr_etl_rule_qualifiers WHERE extract_id = etl_id_i;
            delete from tdr_etl_rule_products WHERE extract_id = etl_id_i;
            delete from tdr_etl_reference_lists WHERE extract_id = etl_id_i;
        END IF;
        commit;


    exception
    when others then
        RAISE_APPLICATION_ERROR(-20001,'Removing local extract error.');

    END remove_local_extract;

    /*
    PROCEDURE zone_data IS  -- 03/24/17 - crapp-3363
        l_id NUMBER;
    BEGIN
        etl_proc_log_p('CR_EXTRACT.ZONE_DATA','Get Zone adds - start','GIS',NULL,NULL);

        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_us_zone_changes DROP STORAGE';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_zone_attributes DROP STORAGE';

        --get adds: Zones that exist in Content Repo but not in Determination
        insert into tdr_etl_us_zone_changes(id,  state, county, city, postcode, plus4, source_db, change_type)(
        select rownum, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name , 'CONTENT_REPO', 'Add'
        from (
            select distinct zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                   , code_2char, code_3char, code_fips, default_flag, reverse_flag, terminator_flag
            from content_repo.gis_ztree_tmp -- crapp-3363
            minus
            select zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                   , code_2char, code_3char, code_fips, default_flag, reverse_flag, terminator_flag
            from ct_zone_tree
            )
         );
        COMMIT;
        SELECT max(id)
        INTO l_id
        FROM tdr_etl_us_zone_changes;
        etl_proc_log_p('CR_EXTRACT.ZONE_DATA','Get Zone adds - end','GIS',NULL,NULL);


        -- get deletes --
        etl_proc_log_p('CR_EXTRACT.ZONE_DATA','Get Zone deletes - start','GIS',NULL,NULL);

        insert into tdr_etl_us_zone_changes(id,  state, county, city, postcode, plus4, source_db, change_type)(
        select l_id+rownum, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name ,'DETERMINATION','Delete'
        from (
             select zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
             from ct_zone_tree zt
             where zt.zone_3_name is not null
             and exists (
                 select 1
                 from content_repo.gis_ztree_tmp gz -- crapp-3363
                 where gz.zone_3_name = zt.zone_3_name
                 )
             minus
             select zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
             from content_repo.gis_ztree_tmp    -- crapp-3363
             )
         );
        COMMIT;
        SELECT max(id)
        into l_id
        FROM tdr_etl_us_zone_changes;
        etl_proc_log_p('CR_EXTRACT.ZONE_DATA','Get Zone deletes - end','GIS',NULL,NULL);


        -- get updates --
        etl_proc_log_p('CR_EXTRACT.ZONE_DATA','Get Zone updates - start','GIS',NULL,NULL);

        insert into tdr_etl_us_zone_changes(id,  state, county, city, postcode, plus4, source_db, change_type)(
        select l_id+rownum, det.zone_3_name, det.zone_4_name, det.zone_5_name, det.zone_6_name, det.zone_7_name,'DETERMINATION','Update'
        from   ct_zone_tree det
        join   content_repo.gis_ztree_tmp crt on (  -- crapp-3363
            det.zone_3_name = crt.zone_3_name
            and det.zone_4_name = crt.zone_4_name
            and nvl(det.zone_5_name,'NULL CITY') = nvl(crt.zone_5_name,'NULL CITY')
            and nvl(det.zone_6_name,'NULL ZIP') = nvl(crt.zone_6_name,'NULL ZIP')
            and nvl(det.zone_7_name,'NULL PLUS4') = nvl(crt.zone_7_name,'NULL PLUS4')
            )
        where nvl(det.code_2char,'xxx') !=  nvl(crt.code_2char,'xxx')
        or nvl(det.code_3char,'xxxx') !=  nvl(crt.code_3char,'xxxx')
        or nvl(det.code_fips,'xxx') !=  nvl(crt.code_fips,'xxx')
        or nvl(det.default_flag,'N') !=  nvl(crt.default_flag,'N')
        or nvl(det.reverse_flag,'N') !=  nvl(crt.reverse_flag,'N')
        or nvl(det.terminator_flag,'N') !=  nvl(crt.terminator_flag,'N')
         );
        COMMIT;
        etl_proc_log_p('CR_EXTRACT.ZONE_DATA','Get Zone updates - end','GIS',NULL,NULL);


        -- get attributes from Content Repo --
        etl_proc_log_p('CR_EXTRACT.ZONE_DATA','Get attributes - start','GIS',NULL,NULL);

        insert into tdr_etl_zone_attributes (tmp_id, code_2char , code_3char, code_fips, default_flag, reverse_flag, terminator_flag) (
        select distinct id, code_2char , code_3char, code_fips, default_flag, reverse_flag, terminator_flag
        from   content_repo.gis_ztree_tmp tz    -- crapp-3363
        join   tdr_etl_us_zone_changes usz on (
            usz.state = tz.zone_3_name
            and usz.county = tz.zone_4_name
            and nvl(usz.city,'NULL CITY') = nvl(tz.zone_5_name,'NULL CITY')
            and nvl(usz.postcode,'NULL ZIP') = nvl(tz.zone_6_name,'NULL ZIP')
            and nvl(usz.plus4,'NULL PLUS4') = nvl(tz.zone_7_name,'NULL PLUS4')
            )
        where usz.source_db = 'CONTENT_REPO'
        );
        COMMIT;

        -- get attributes from Determination --
        insert into tdr_etl_zone_attributes (tmp_id, code_2char , code_3char, code_fips, default_flag, reverse_flag, terminator_flag) (
        select distinct id, code_2char , code_3char, code_fips, default_flag, reverse_flag, terminator_flag
        from   content_repo.gis_ztree_tmp tz    -- crapp-3363
        join   tdr_etl_us_zone_changes usz on (
            usz.state = tz.zone_3_name
            and usz.county = tz.zone_4_name
            and nvl(usz.city,'NULL CITY') = nvl(tz.zone_5_name,'NULL CITY')
            and nvl(usz.postcode,'NULL ZIP') = nvl(tz.zone_6_name,'NULL ZIP')
            and nvl(usz.plus4,'NULL PLUS4') = nvl(tz.zone_7_name,'NULL PLUS4')
            )
        where usz.change_type = 'Update'
        );
        COMMIT;

        etl_proc_log_p('CR_EXTRACT.ZONE_DATA','Get attributes - end','GIS',NULL,NULL);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'Zone area data error.');
    END zone_data;


    PROCEDURE zone_authority_data(make_changes_i IN NUMBER) IS  -- 03/24/17 - crapp-3363
        l_id number;
    BEGIN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_us_zone_authorities DROP STORAGE';

        -- get adds: Zone Authorities that exist in Content Repo but not in Determination --
        etl_proc_log_p('CR_EXTRACT.ZONE_AUTHORITY_DATA','Get adds - start, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);

        IF (make_changes_i = 1) THEN
            -- Exclude any Invalid Authorities - crapp-2244 --
            INSERT INTO tdr_etl_us_zone_authorities(id, state, county, city, postcode, plus4, authority, source_db, change_type)
            (
            SELECT ROWNUM, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name , authority_name, 'CONTENT_REPO', 'Add'
            FROM (
                 SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                 FROM   content_repo.gis_authorities_tmp    -- crapp-3363
                 MINUS
                 SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                 FROM   ct_zone_authorities
                 ) a
            WHERE authority_name NOT IN (SELECT DISTINCT gis_name FROM content_repo.gis_zone_juris_auths_tmp)   -- crapp-3363
            );
        ELSE
            INSERT INTO tdr_etl_us_zone_authorities(id, state, county, city, postcode, plus4, authority, source_db, change_type)
            (
            SELECT ROWNUM, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name, 'CONTENT_REPO', 'Add'
            FROM (
                 SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                 FROM   content_repo.gis_authorities_tmp    -- crapp-3363
                 MINUS
                 SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                 FROM   ct_zone_authorities
                 )
            );
        END IF;
        COMMIT;
        SELECT MAX(id)
        INTO l_id
        FROM tdr_etl_us_zone_authorities;
        etl_proc_log_p('CR_EXTRACT.ZONE_AUTHORITY_DATA','Get adds - end, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);


        -- get deletes --
        etl_proc_log_p('CR_EXTRACT.ZONE_AUTHORITY_DATA','Get deletes - start, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);

        INSERT INTO tdr_etl_us_zone_authorities(id, state, county, city, postcode, plus4, authority, source_db, change_type)
        (
        SELECT l_id+ROWNUM, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name, 'DETERMINATION', 'Delete'
        FROM (
             SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name,authority_name
             FROM   ct_zone_authorities zt
             WHERE  zt.zone_3_name IS NOT NULL
             AND EXISTS (
                        SELECT 1
                        FROM   content_repo.gis_authorities_tmp gz  -- crapp-3363
                        WHERE  gz.zone_3_name = zt.zone_3_name
                        )
             MINUS
             SELECT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name,authority_name
             FROM   content_repo.gis_authorities_tmp    -- crapp-3363
             )
        );
        COMMIT;
        etl_proc_log_p('CR_EXTRACT.ZONE_AUTHORITY_DATA','Get deletes - end, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);

    -- build on this
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001,'Zone data error');
    END zone_authority_data;
    */
END;
/