CREATE OR REPLACE PACKAGE BODY sbxtax.det_transform
IS

vstep number := 100;
/*
  10/10/2014 - CRAPP-797 - dlg
  --
  (Official_Name in tdr_etl_tb_authorities is populated from administrator name)
  Can always rename / or if Official name should be replaced with Determination Official Name?
  ALTER TABLE SBXTAX.tdr_etl_tb_authorities
  ADD (
  ATTR_OFFICIAL_NAME VARCHAR2 (100 CHAR),
  ATTR_DEFAULT_PRODUCT_GROUP VARCHAR2 (100 CHAR)
  )
  --/
  -- Additional attributes added
     , ab.official_name  -- attribute determination official name
     , ab.default_product_group -- determination default product group (conv id?)
*/
    TYPE product IS RECORD (product_id INTEGER, hlevel INTEGER);
    TYPE product_ids IS TABLE OF product;

    PROCEDURE set_transformed_date(entity_name_i varchar2)
    IS
    BEGIN
        etl_proc_log_p('DET_TRANSFORM.SET_TRANSFORMED_DATE','Setting transformed date for the entity '||entity_name_i,upper(entity_name_i),NULL,NULL);
        IF entity_name_i = 'RATES'
        THEN
            UPDATE extract_log
               SET transformed = SYSDATE
             WHERE     entity = 'TAX' and transformed is null
                   AND (nkid, rid) IN (SELECT nkid, rid FROM tdr_etl_tb_rates
                                       UNION
                                       SELECT nkid, rid from tdr_etl_tb_rate_tiers);
        ELSIF entity_name_i = 'AUTHORITIES'
        THEN
            UPDATE extract_log
               SET transformed = SYSDATE
             WHERE     entity = 'JURISDICTION' and transformed is null
                   AND (nkid, rid) IN (SELECT nkid, rid
                                         FROM tdr_etl_tb_authorities);
        ELSIF entity_name_i = 'RULES'
        THEN
            UPDATE extract_log
               SET transformed = SYSDATE
             WHERE     entity = 'TAXABILITY' and transformed is null
                   AND (nkid, rid) IN (SELECT nkid, rid FROM tdr_etl_tb_rules
                                       UNION
                                       SELECT nkid, rid FROM tdr_etl_tb_rule_qualifiers);
        ELSIF entity_name_i = 'PRODUCTS'
        THEN
            UPDATE extract_log
               SET transformed = SYSDATE
             WHERE     entity = 'COMMODITY' and transformed is null
                   AND (nkid, rid) IN (SELECT nkid, rid
                                         FROM tdr_etl_ct_product_tree);
        ELSIF entity_name_i = 'REFERENCE GROUP'
        THEN
            UPDATE extract_log
               SET transformed = SYSDATE
             WHERE     entity = 'REFERENCE GROUP' and transformed is null
                   AND (nkid, rid) IN (SELECT nkid, rid FROM tdr_etl_tb_reference_lists
                                       UNION
                                       SELECT nkid, rid FROM tdr_etl_tb_reference_values);
        END IF;
        etl_proc_log_p('DET_TRANSFORM.SET_TRANSFORMED_DATE','Transformed date has been set for  '||entity_name_i,upper(entity_name_i),NULL,NULL);

        COMMIT;
    END;

    procedure empty_tmp_sbx is
    begin
        execute immediate 'truncate table tdr_etl_tb_rules';
        execute immediate 'truncate table tdr_etl_tb_rule_qualifiers';
        execute immediate 'truncate table tdr_etl_tb_reference_values';
        execute immediate 'truncate table tdr_etl_tb_reference_lists';
        execute immediate 'truncate table tdr_etl_tb_rates';
        execute immediate 'truncate table tdr_etl_tb_rate_tiers';
        execute immediate 'truncate table tdr_etl_tb_contributing_auths';
        execute immediate 'truncate table tdr_etl_tb_authorities';
        execute immediate 'truncate table tdr_etl_tb_auth_logic_groups';
        execute immediate 'truncate table tdr_etl_tb_auth_logic_mapping';
        execute immediate 'truncate table tdr_etl_tb_auth_messages';
        execute immediate 'truncate table tdr_etl_ct_product_tree';
        execute immediate 'truncate table tdr_etl_prod_changes';
        execute immediate 'truncate table tdr_etl_product_categories';
        execute immediate 'truncate table tdr_etl_cntr_authorities';
        --execute immediate 'truncate table tdr_etl_product_exceptions';
    end;

    PROCEDURE map_rates IS
    BEGIN
        -- 09/14/16 CRAPP-3029, added JURIS_NKID and CREATION_DATE
        insert into mp_tax_rate (tax_nkid, outline_nkid, rate_id, juris_nkid, creation_date)
        (
         select distinct
                jti.nkid  tax_nkid
                , tou.nkid  outline_nkid
                , r.rate_id
                , j.nkid  juris_nkid
                , SYSDATE creation_date
         from content_repo.jurisdictions j
             join mp_juris_auths ja on (ja.nkid = j.nkid)
             join content_repo.mv_juris_tax_impositions jti on (jti.jurisdiction_id = j.id)
             join content_repo.mv_tax_outlines tou on (tou.juris_tax_imposition_id = jti.id and tou.next_rid is null)
             join tdr_etl_rates ttr on (ttr.nkid = jti.nkid and ttr.outline_nkid = tou.nkid)  -- crapp-3029, This should make the mapping table populated only for the NKID and Outline_NKID that we specified.
             join tb_authorities a on (a.uuid = ja.authority_uuid)
             join tb_rates r on (
                  r.authority_id = a.authority_id
                  and r.merchant_id = a.merchant_id
                  and (
                      (nvl(r.is_local,'N') = 'Y' and r.rate_code = replace(upper(jti.reference_Code),' (LOCAL)'))
                      or
                      (nvl(r.is_local,'N') = 'N' and r.rate_code = jti.reference_Code)
                      )
                  and tou.start_date = r.start_Date
                )
         -- 09/12/2016 CRAPP-3016 uncommented to remove duplciate authority mapping for rates
         where not exists (
                           select 1
                           from mp_tax_rate tr
                           where tr.rate_id = r.rate_id
                                 and jti.nkid = tr.tax_nkid
                                 and tou.nkid = tr.outline_nkid
                           )
        );
        commit;

    exception
    when TIMEOUT_ON_RESOURCE then
    etl_proc_log_p ('DET_TRANSFORM.MAP_RATES','MAP_RATES Failed with '||sqlerrm,'MAP_RATES',null,null);
    RAISE_APPLICATION_ERROR(-20001,'Map rates timeout.');
    when others then
    etl_proc_log_p ('DET_TRANSFORM.MAP_RATES','MAP_RATES Failed with '||sqlerrm,'MAP_RATES',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Map rates error.');

    END;

    function get_branch(search_prod_i IN NUMBER, top_prod_i IN NUMBER, updown_i IN VARCHAR2) RETURN product_ids
    IS
        l_product_line product_ids;
    BEGIN
        IF upper(updown_i) = 'UP' THEN
            etl_proc_log_p ('DET_TRANSFORM.GET_BRANCH','GET_BRANCH with search_prod_i:'||search_prod_i||', top_prod_i:'||top_prod_i||', updown_i:'||updown_i,'GET_BRANCH',null,null);
            SELECT nvl(product_category_id,top_prod_i), level
            BULK COLLECT INTO l_product_line
            FROM tb_product_categories
            start with product_category_id = nvl(search_prod_i,top_prod_i)
            connect by prior parent_product_category_id = product_category_id
            order by level;
        ELSIF lower(updown_i) = 'down' THEN
            etl_proc_log_p ('DET_TRANSFORM.GET_BRANCH','GET_BRANCH with search_prod_i:'||search_prod_i||', top_prod_i:'||top_prod_i||', updown_i:'||updown_i,'GET_BRANCH',null,null);
            SELECT nvl(product_category_id,top_prod_i), level
            BULK COLLECT INTO l_product_line
            FROM tb_product_categories
            start with product_category_id = nvl(search_prod_i,top_prod_i)
            connect by prior product_category_id = parent_product_category_id
            order by level desc;
        END IF;
        RETURN l_product_line;

    -- no data found is probably the only one that would be raised
    exception
    when others then
    etl_proc_log_p ('DET_TRANSFORM.GET_BRANCH','GET_BRANCH failed with '||sqlerrm,'GET_BRANCH',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Product category branch selection error.');
    END get_branch;


    PROCEDURE build_tb_product_categories
    IS
        cursor product_trees is
        select distinct product_Tree
        from tdr_etl_product_categories;

        cursor product_changes(prod_tree_i IN VARCHAR2) is
        select length(sort_key)/cr_extract.prod_level_token h_level, name, prodcode, el.nkid, el.rid, description, sort_key, product_tree
        from tdr_etl_prod_changes el
        join tdr_etl_product_categories pc on (el.nkid = pc.nkid)
        where sort_key is not null
        and product_Tree = prod_tree_i;

        l_p_name VARCHAR2(500);
        l_p_nkid number;
        l_update varchar2(768);
        l_affected NUMBER := 0;
    BEGIN
        FOR pt in product_trees LOOP
            etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_PRODUCT_CATEGORIES','transforming Product Category data, pt.product_Tree:'||pt.product_Tree,'PRODUCT CATEGORY',null,null);
           FOR p in product_changes(pt.product_Tree) LOOP

                insert into tdr_etl_ct_product_tree(name, prodcode, nkid, rid, description, sort_key, product_tree)
                values (substr(p.name,1,100) , substr(p.prodcode,1,50), p.nkid, p.rid, substr(p.description,1,250), p.sort_key, p.product_tree); --njv CRAPP-864
                for L in 1..p.h_level loop <<levels>>
                    BEGIN
                        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_PRODUCT_CATEGORIES','Extracting Name and NKID with L*cr_extract.prod_level_token:'||L*cr_extract.prod_level_token||', p.product_tree:'||p.product_tree ,'PRODUCT CATEGORY',null,null);
                        select name, nkid
                        into l_p_name, l_p_nkid
                        from tdr_etl_product_categories pc
                        where length(pc.sort_key) = L*cr_extract.prod_level_token
                        and instr(p.sort_key,pc.sort_key) = 1
                        and pc.product_tree = p.product_tree;
                        EXCEPTION
                            WHEN no_data_found THEN dbms_output.put_line(L||':'||p.sort_key);
                            RAISE;
                    END;

                    l_update := 'update tdr_etl_ct_product_tree set product_'||L||'_nkid = '||l_p_nkid||',  product_'||L||'_name = '''||replace(l_p_name,'''','''''')||
                        ''' where nkid = '||p.nkid; --njv CRAPP-864
                    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_PRODUCT_CATEGORIES','L_update query string is '||l_update,'PRODUCT CATEGORY',null,null);

                    execute immediate l_update;
                    commit;
                end loop levels;

               l_affected := l_affected+1;
               COMMIT;
           END LOOP;
        end loop;
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_PRODUCT_CATEGORIES','transformed '||l_affected||' Product Categories','PRODUCT CATEGORY',null,null);

       set_transformed_date('PRODUCTS');

       COMMIT;

    exception
    when TIMEOUT_ON_RESOURCE then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_PRODUCT_CATEGORIES','Process failed with '||sqlerrm,'PRODUCT CATEGORY',null,null);
    RAISE_APPLICATION_ERROR(-20001,'Temp product data timeout.');
    when others then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_PRODUCT_CATEGORIES','Process failed with '||sqlerrm,'PRODUCT CATEGORY',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Product category error.');

    END;

    PROCEDURE build_tb_reference_lists
    IS
        l_affected number := 0;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_REFERENCE_LISTS','transforming Reference List data','REFERENCE LIST',null,null);

        INSERT INTO tdr_etl_tb_reference_lists (reference_list_id, ref_group_nkid, nkid, rid, name, start_Date, end_date, description) (
        SELECT distinct mrl.reference_list_id, l.ref_group_nkid, l.ref_group_nkid, l.rid, l.name, l.list_start_date, l.list_end_Date, l.description   -- CRAPP-809 dlg
        FROM tdr_etl_reference_lists l
        LEFT OUTER JOIN mp_ref_lists mrl on (mrl.ref_group_nkid = l.ref_group_nkid)
        );

        INSERT INTO tdr_etl_tb_reference_values (reference_value_id, reference_list_id, ref_group_nkid, value, start_Date, end_date, item_nkid) (
        SELECT distinct mr.ref_value_id,  mr.ref_list_id, rl.ref_group_nkid, value, item_start_date, item_end_Date, rl.item_nkid
        FROM tdr_etl_reference_values rl
        LEFT OUTER JOIN mp_ref_values mr on (mr.ref_group_nkid = rl.ref_group_nkid and mr.ref_item_nkid = rl.item_nkid )
        );

        set_transformed_date('REFERENCE GROUP');

        l_affected := l_affected+sql%rowcount;

        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_REFERENCE_LISTS','transformed '||l_affected||' Reference List data','REFERENCE LIST',null,null);

        COMMIT;

    exception
    when others then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_REFERENCE_LISTS','Process failed with '||sqlerrm,'REFERENCE LIST',null,null);
    RAISE_APPLICATION_ERROR(-20001,'Reference list error.');

    END build_tb_reference_lists;

    PROCEDURE build_tb_reference_values
    IS
    BEGIN
        NULL;
    END build_tb_reference_values;

    PROCEDURE insert_rule_qualifiers(rule_id_i IN NUMBER, authority_uuid_i IN VARCHAR2, rule_order_i IN NUMBER, start_Date_i IN DATE, product_Category_id_i IN NUMBER, is_local_i IN VARCHAR2, jta_nkid_i number)
    IS
        CURSOR new_rule_qualifiers is
            SELECT rule_id_i, case when authority_uuid is not null then 'AUTHORITY' when reference_Group_name is not null then 'LIST' else 'CONDITION' end rule_qualifier_type,
            taxability_element, logical_qualifier, value, authority_uuid, reference_group_name, start_date, end_Date
            FROM tdr_etl_rule_qualifiers q
            WHERE jta_nkid = jta_nkid_i
              and taxability_element != 'TAX_CODE';
    BEGIN

        FOR n in new_rule_qualifiers LOOP
            etl_proc_log_p ('DET_TRANSFORM.INSERT_RULE_QUALIFIERS','INSERT_RULE_QUALIFIERS, Inside the loop with rule_order_i:'||rule_order_i||', authority_uuid_i:'||authority_uuid_i||', start_Date_i:'||start_Date_i,'INSERT_RULE_QUALIFIERS',null,null);
            INSERT INTO tdr_etl_tb_rule_qualifiers(rule_id, rule_authority_uuid, rule_order, rule_start_date, product_Category_id, is_local, rule_qualifier_type, element, operator, value, authority, reference_list_name, start_date, end_date)
            VALUES (rule_id_i, authority_uuid_i, rule_order_i, start_Date_i, product_Category_id_i, is_local_i, n.rule_qualifier_type, n.taxability_element, n.logical_qualifier, n.value, n.authority_uuid, n.reference_Group_name, n.start_date, n.end_date);
        END LOOP;

    exception
    when others then
    etl_proc_log_p ('DET_TRANSFORM.INSERT_RULE_QUALIFIERS','INSERT_RULE_QUALIFIERS Failed with error '||sqlerrm,'INSERT_RULE_QUALIFIERS',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Rule qualifier data procedure failed.');

    END;

    procedure Process_rule_Updates
    (
        auth_uuid_i IN VARCHAR2,
        rate_code_i IN VARCHAR2,
        calc_method_i IN NUMBER,
        tax_type_i IN VARCHAR2,
        exempt_i IN VARCHAR2,
        no_tax_i IN VARCHAR2,
        start_date_i IN DATE,
        end_date_i IN DATE,
        h_level_i IN NUMBER,
        prod_cat_id_i IN NUMBER,
        basis_percent_i IN NUMBER,
        recoverable_percent_i IN NUMBER,
        inv_desc_i IN VARCHAR2,
        sib_order_i IN NUMBER,
        rqs_i IN VARCHAR2,
        rq_order_i IN NUMBER,
        is_local_i IN VARCHAR2,
        code_i IN VARCHAR2,
        top_prod_i IN NUMBER,
        jta_nkid_i IN NUMBER,
        jta_rid_i IN NUMBER,
        ref_rule_order_i in number,
        tat_id_i in number,
        allocated_charge_i varchar2,
        related_charge_i varchar2,
        unit_of_measure_i varchar2,
        recoverable_amount_i number,
        rq_start_date_i date,
        rq_end_date_i date
    )
    is
        l_rate_code varchar2(20);
        l_rule_id number;

    begin
        etl_proc_log_p ('DET_TRANSFORM.PROCESS_RULE_UPDATES','PROCESS_RULE_UPDATES, with auth_uuid_i:'||auth_uuid_i||', ref_rule_order_i:'||ref_rule_order_i||', start_date_i:'||start_date_i,'PROCESS_RULE_UPDATES',null,null);
        begin
            -- CRAPP-3174, Removed schema reference
            select rule_id into l_rule_id from tb_rules r join tb_authorities a
                on ( r.authority_id = a.authority_id )
               where a.uuid =  auth_uuid_i
                 and r.rule_order = ref_rule_order_i
                 and nvl(r.rate_code, 'xx') = nvl(rate_code_i, 'xx')
                 and nvl(product_category_id, -999) = nvl(prod_cat_id_i, -999)
                 and start_date = start_date_i
                 and nvl(is_local, 'N') = nvl(is_local_i, 'N');
                 --and nvl(end_date, '31-Dec-9999') = nvl(end_date_i, '31-Dec-9999');
                 --and case when rate_code like '%ST%' and tax_type is null then 'SA' else nvl(tax_type,'xx') end  = nvl(tax_type_i, 'xx');

        exception
        when no_data_found
        then
            etl_proc_log_p ('DET_TRANSFORM.PROCESS_RULE_UPDATES','PROCESS_RULE_UPDATES, Inside no data found, with auth_uuid_i:'||auth_uuid_i||', rate_code_i:'||rate_code_i||', start_date_i:'||start_date_i,'PROCESS_RULE_UPDATES',null,null);
            begin
                select rule_id into l_rule_id from tb_rules r join tb_authorities a
                    on ( r.authority_id = a.authority_id )
                   where a.uuid =  auth_uuid_i
                     and nvl(r.rate_code, 'xx') = nvl(rate_code_i, 'xx')
                     and nvl(product_category_id, -999) = nvl(prod_cat_id_i, -999)
                     and start_date = start_date_i
                     and nvl(is_local, 'N') = nvl(is_local_i, 'N');
            exception
            when others then
                dbms_output.put_line('ref_rule_order value Inside second exception block is '||ref_rule_order_i);
                l_rule_id := null;
            end;
        end;

        etl_proc_log_p ('DET_TRANSFORM.PROCESS_RULE_UPDATES','PROCESS_RULE_UPDATES, Inserting data into tdr_etl_tb_rules table', 'PROCESS_RULE_UPDATES',null,null);
        INSERT INTO tdr_etl_tb_rules (rule_id, authority_uuid, rule_order, start_Date, end_date, rate_code, exempt, no_tax, basis_percent,
                    input_recovery_percent, invoice_description, product_category_id, tax_type, calculation_method, rule_qualifier_set, is_local, code,
                    nkid, rid, tat_nkid,
                    input_recovery_amount,
                    allocated_charge,
                    unit_of_measure,
                    related_charge
                )
        VALUES (l_rule_id, auth_uuid_i, ref_rule_order_i, start_date_i, end_Date_i, rate_code_i, nvl(exempt_i, 'N'), nvl(no_tax_i, 'N'),
                    basis_percent_i, recoverable_percent_i, inv_desc_i, prod_cat_id_i, tax_type_i, calc_method_i, rqs_i,
                    NVL(is_local_i, 'N'), code_i,
                    jta_nkid_i, jta_rid_i, tat_id_i,
                    recoverable_amount_i,
                    allocated_charge_i,
                    unit_of_measure_i,
                    related_charge_i
                    )
                ;
        -- Changes for CRAPP-2853
        etl_proc_log_p ('DET_TRANSFORM.PROCESS_RULE_UPDATES','PROCESS_RULE_UPDATES, Inserting data into insert_rule_qualifiers table', 'PROCESS_RULE_UPDATES',null,null);
        insert_rule_qualifiers(l_rule_id, auth_uuid_i, ref_rule_order_i, start_date_i, prod_cat_id_i, is_local_i, jta_nkid_i);

    exception
    when others then
    etl_proc_log_p ('DET_TRANSFORM.PROCESS_RULE_UPDATES','PROCESS_RULE_UPDATES, failed with error '||sqlerrm, 'PROCESS_RULE_UPDATES',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Rules updates error.');

    end;

    PROCEDURE build_tb_rules IS
        -- CRAPP-3174, Removed schema reference
        cursor authorities is
        select distinct authority_uuid uuid, a.name, a.content_type
        from tdr_etl_rules r
        join (
            select distinct authority_uuid uuid, name, content_type
            from tdr_etl_tb_authorities
            union
            select distinct uuid, name, content_type
            from tb_authorities
            ) a on (a.uuid = r.authority_uuid);

        --get distinct rules (minus product), and get the highest level product for each distinct rule
        cursor rule_types(auth_uuid_i IN VARCHAR2, content_type_i IN VARCHAR2) is
            select distinct r.rate_code, r.exempt, r.no_tax,
                case when r.tax_type is null then
                    case when content_type_i = 'US' then tra.tax_type else ttrq.value end
                 else r.tax_type
                 end tax_type,
                calculation_method, nvl(basis_percent,100) basis_percent, recoverable_percent, cp.product_category_id, rp.commodity_nkid,
                rp.hierarchy_level hierarchy_level,
                rp.lowest_level, rp.highest_level,
                r.start_date,
                r.end_date end_date,
                tid.invoice_description, rp.sibling_order, nvl(rp.product_Tree,'US') product_tree,
                tra.tat_nkid,
                r.rule_qualifier_set, r.is_local, rq.value code, r.rule_qual_order rq_order,
                r.nkid jta_nkid,
                r.rid jta_rid,
                r.ref_rule_order,
                r.unit_of_measure,
                r.allocated_charge,
                r.recoverable_amount,
                r.related_charge,
                r.default_taxability,
                nvl(trqd.start_date, rq.start_date) rq_start_date,
                nvl(trqd.end_date, rq.end_date) rq_end_date
            from tdr_etl_rules r  -- CRAPP-3174, Removed schema reference
            left join tdr_etl_rule_products rp on (
                    r.nkid = rp.nkid
                and nvl(r.rate_code, 'xx') = nvl(rp.rate_Code, 'xx')
                and rp.commodity_nkid = r.commodity_nkid
                )
            left join mp_comm_prods cp on (cp.commodity_nkid = r.commodity_nkid)
            left join tdr_etl_rule_app_diffs tra on ( tra.jta_nkid = r.nkid and nvl(r.rate_code, 'xx') = nvl(tra.rate_code, 'xx'))
            -- Changes for CRAPP-2790
            left join tdr_etl_jta_inv_desc tid on ( tid.nkid  = r.nkid and nvl(tra.tat_id, -999) = nvl(tid.tat_id, -999) )
            left join tdr_etl_rule_qual_diffs trqd on ( trqd.jta_nkid = r.nkid and trqd.element not in ( 'TAX_TYPE', 'TAX_CODE' ) )
            left outer join (
                select DISTINCT authority_uuid, l.code value, jta_nkid --, to_char(rule_qualifier_set) rule_qualifier_set
                from tdr_etl_rule_qualifiers q
                join tb_lookups l on (l.code_group = content_type_i||'_TAX_TYPE' and l.description = q.value)
                where q.taxability_element = 'TAX_TYPE'
                ) ttrq on (ttrq.jta_nkid = r.nkid)
            left outer join (
                select DISTINCT authority_uuid, value, jta_nkid, q.start_date, q.end_date --, to_char(rule_qualifier_set) rule_qualifier_set
                from tdr_etl_rule_qualifiers q
                where q.taxability_element = 'TAX_CODE'
                ) rq on (rq.jta_nkid = r.nkid)
            where r.authority_uuid = auth_uuid_i
            order by start_date, case when r.exempt = 'N' and r.no_tax = 'N' then 3 when r.exempt = 'Y' then 2 else 1 end,
                DET_TRANSFORM.tax_type_level(tax_type),
                 rate_code, basis_percent, recoverable_percent;

        -- Updated for
        cursor rule_products(jta_nkid_i IN VARCHAR2, rate_code_i IN VARCHAR2, hierarchy_level_i IN NUMBER, rule_qualifier_set_i IN VARCHAR2) IS
            select distinct rp.commodity_nkid, cp.product_category_id, rp.start_Date, rp.end_date, rp.hierarchy_level, rp.sibling_order,
                rp.no_tax, rp.exempt
            from tdr_etl_rule_products rp
            join mp_comm_prods cp on (cp.commodity_nkid = rp.commodity_nkid)
            WHERE rp.nkid = jta_nkid_i
            AND nvl(rp.rate_code,'xx') = nvl(rate_code_i,'xx')
            AND NVL(rule_qualifier_Set,'xx') = NVL(rule_qualifier_set_i,'xx')
            ;

        cursor product_exceptions (jta_nkid_i IN VARCHAR2, rate_code_i IN VARCHAR2, hierarchy_level_i IN NUMBER) IS
            select distinct cp.commodity_nkid, cp.product_category_id, rp.start_Date, rp.end_date, rp.hierarchy_level, rp.no_tax, rp.exempt,
                row_number() over (partition by rp.hierarchy_level order by cp.commodity_nkid)+sibling_order sibling_order
            from tdr_etl_product_exceptions rp  -- CRAPP-3174, Removed schema reference
            join mp_comm_prods cp on (cp.product_category_id = rp.product_category_id)
            WHERE rp.nkid = jta_nkid_i
            AND rp.rate_Code = rate_code_i
            AND rp.hierarchy_level = hierarchy_level_i
            AND rp.exempt = 'N'
            and rp.no_tax = 'N';

        new_rule_order number;
        l_lowest_level number;
        l_existing_parent_rule number;
        l_match NUMBER;
        l_has_overlaps number := 1;

        l_pe_rule tdr_etl_tb_rules%ROWTYPE;
        l_found number;
        l_top_prod number;
        l_affected number;
    BEGIN

            etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RULES','update Rule Qualifier mappings','RULE',null,null);
            map_rule_rq;
            etl_proc_log_p('DET_TRANSFORM.BUILD_TB_RULES','updated Taxability Qualifiers mappings','RULE',null,null);
            map_jta_rq;

        for a in authorities loop <<authorities_loop>>
            etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RULES','analyzing '||a.name,'RULE',null,null);
        for rt in rule_types(a.uuid, a.content_type) loop
            etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RULES','BUILD_TB_RULES Checking product category for authority UUID '||a.uuid, 'BUILD_TB_RULES',null,null);
            select pc.product_category_id
            into l_top_prod--, l_pg_count
            from tb_product_categories pc
            join tb_product_groups pg on (pg.product_group_id = pc.product_group_id)
            --join tb_product_Categories pc2 on (pc2.product_group_id = pg.product_Group_id and pc.merchant_id = pc2.merchant_id)
            where pg.name = rt.product_tree
            and pc.name = 'Product Categories'
            and pc.merchant_id = (select merchant_id from tb_merchants m where name like 'Sabrix%Tax Data');
            --group by pc.product_category_id;

            if rt.ref_rule_order is not null
            then
                etl_proc_log_p('DET_TRANSFORM.BUILD_TB_RULES','Performing rule updates for '||a.name||':'||rt.jta_nkid,'RULE',null,null);
                Process_rule_Updates(a.uuid, rt.rate_Code , rt.calculation_method, rt.tax_type, rt.exempt, rt.no_tax,
                    rt.start_Date, rt.end_Date, rt.hierarchy_level, rt.product_category_id,
                    rt.basis_percent, rt.recoverable_percent, rt.invoice_Description, rt.sibling_order,
                    rt.rule_qualifier_set,  rt.rq_order, rt.is_local, rt.code, rt.product_category_id, rt.jta_nkid, rt.jta_rid, rt.ref_rule_order,
                    rt.tat_nkid, rt.allocated_charge, rt.related_charge, rt.unit_of_measure, rt.recoverable_amount,
                    rt.rq_start_date, rt.rq_end_date
                    );
            end if;
        end loop;

            etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RULES','Setting up Parent Product Category '||a.name,'RULE',null,null);
            update tdr_etl_tb_rules
            set product_category_id = null
            where authority_uuid = a.uuid
            and product_category_id in (
                select product_category_id
                from tb_product_categories
                where name = 'Product Categories'
                );
        end loop authorities_loop;

        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RULES','Updating extract_log transformed date','RULE',null,null);
        set_transformed_date('RULES');
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RULES','transformed '||l_affected||' Taxabilities and Commodity Groups','RULE',null,null);

        COMMIT;

    exception
    when TIMEOUT_ON_RESOURCE then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RULES','BUILD_TB_RULES failed with '||sqlerrm,'RULE',null,null);
    RAISE_APPLICATION_ERROR(-20001,'Tb rules timeout.');
    when others then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RULES','BUILD_TB_RULES failed with '||sqlerrm,'RULE',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Tb rules error.');

    END build_tb_rules;

    PROCEDURE insert_rule(
        auth_uuid_i IN VARCHAR2,
        parent_rule_i IN NUMBER,
        rate_code_i IN VARCHAR2,
        exempt_i IN VARCHAR2,
        no_tax_i IN VARCHAR2,
        comm_nkid_i IN NUMBER,
        h_level_i IN NUMBER,
        tax_type_i IN VARCHAR2,
        start_date_i IN DATE,
        end_date_i IN DATE,
        basis_percent_i IN NUMBER,
        recoverable_percent_i IN NUMBER,
        inv_desc_i IN VARCHAR2,
        tas_nkid_i IN NUMBER)
    IS
        l_new_rule_order number :=  parent_rule_i;
        l_auth_id number;
        l_rate_code VARCHAR2(32);
        l_prod_cat_id NUMBER;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.INSERT_RULE','Inside INSERT_RULE process with auth_uuid_i:'||auth_uuid_i,'INSERT_RULE',null,null);
        SELECT authority_id
        INTO l_auth_id
        FROM tb_authorities
        WHERE uuid = auth_uuid_i;

        etl_proc_log_p ('DET_TRANSFORM.INSERT_RULE','Inside INSERT_RULE process l_auth_id value is '||l_auth_id,'INSERT_RULE',null,null);
        SELECT product_category_id
        INTO l_prod_cat_id
        FROM mp_comm_prods
        WHERE commodity_nkid = comm_nkid_i;

        etl_proc_log_p ('DET_TRANSFORM.INSERT_RULE','Inside INSERT_RULE process l_prod_cat_id value is '||l_prod_cat_id,'INSERT_RULE',null,null);
            IF exempt_i = 'N' and no_tax_i = 'N' THEN
                l_rate_code := rate_code_i;
            ELSE
                l_rate_code := NULL;
            END IF;

            etl_proc_log_p ('DET_TRANSFORM.INSERT_RULE','Inside INSERT_RULE process l_rate_code value is '||l_rate_code,'INSERT_RULE',null,null);
            INSERT INTO tdr_etl_tb_rules (rule_id, authority_id, rule_order, start_Date, end_date, rate_code, exempt, no_tax, basis_percent,
                input_recovery_percent, invoice_description, product_category_id, tax_type
            ) VALUES (pk_tb_rules.nextval, l_auth_id, l_new_rule_order, nvl(start_date_i, sysdate), end_Date_i, l_rate_code, exempt_i, no_tax_i,
                basis_percent_i,recoverable_percent_i, inv_desc_i, l_prod_cat_id, tax_type_i);
            COMMIT;

    exception
    when TIMEOUT_ON_RESOURCE then
    etl_proc_log_p ('DET_TRANSFORM.INSERT_RULE','INSERT_RULE process failed with '||sqlerrm,'INSERT_RULE',null,null);
    RAISE_APPLICATION_ERROR(-20001,'Temp tb rules timeout.');
    when others then
    etl_proc_log_p ('DET_TRANSFORM.INSERT_RULE','INSERT_RULE process failed with '||sqlerrm,'INSERT_RULE',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Inserting temp rules error.');

    END insert_rule;

    -- CRAPP-3104 function created to extract existing authority type

    FUNCTION get_authority_type (authority_uuid VARCHAR2)
        RETURN VARCHAR2
    IS
        vauthority_type   VARCHAR2 (100);
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.GET_AUTHORITY_TYPE','GET_AUTHORITY_TYPE with authority_uuid:'||authority_uuid, 'GET_AUTHORITY_TYPE',null,null);
        SELECT b.name
          INTO vauthority_type
          FROM tb_authorities a
               JOIN tb_authority_types b
                   ON (a.authority_type_id = b.authority_type_id)
         WHERE uuid = authority_uuid;

        etl_proc_log_p ('DET_TRANSFORM.GET_AUTHORITY_TYPE','GET_AUTHORITY_TYPE with vauthority_type value is :'||vauthority_type, 'GET_AUTHORITY_TYPE',null,null);
        RETURN vauthority_type;
    EXCEPTION
        WHEN OTHERS
        THEN
            etl_proc_log_p ('DET_TRANSFORM.GET_AUTHORITY_TYPE','GET_AUTHORITY_TYPE with vauthority_type value is :'||vauthority_type, 'GET_AUTHORITY_TYPE',null,null);
            RETURN '';
    END;

    PROCEDURE build_tb_authorities(package_i IN VARCHAR2)
    IS
        l_affected number;
        l_content_type VARCHAR2(50);
        vauthority_type varchar2(100);
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTHORITIES','transforming Authority data for '||package_i,'AUTHORITY',null,null);
        /* Changes for CRAPP-3975 */
        IF (upper(package_i) like '%INTERNATIONAL%' or upper(package_i) like '%CANADA%') THEN
            l_content_type := 'INTL';
            UPDATE tdr_etl_authority_base ab
            SET authority_type = (
                SELECT authority_type
                FROM   mp_taxtype_Authtypes ta
                WHERE  ta.taxation_type = ab.authority_type
                )
            WHERE authority_type IS NULL;

            COMMIT;
        ELSE
            -- Changes for CRAPP-3104, For the existing authorities, Authority Type should not get updated.
            -- Added for loop and update now will happen on each authority.
            FOR i IN (SELECT DISTINCT authority_uuid
                      FROM tdr_etl_authority_base)
            LOOP
                etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTHORITIES','Inside authority_uuid for loop, with i.authority_uuid:'||i.authority_uuid, 'AUTHORITY',null,null);

                vauthority_type := get_authority_type (i.authority_uuid);
                etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTHORITIES','vauthority_type value is '||vauthority_type, 'AUTHORITY',null,null);
                UPDATE tdr_etl_authority_base
                SET authority_type = replace(replace(authority_type,'Service Tax','Sales/Use'),'?',effective_zone_level)
                WHERE authority_type like '?%' --!= effective_zone_level||' '||replace(authority_type,'Service Tax','Sales/Use');
                  AND authority_uuid = i.authority_uuid;
            END LOOP;
            COMMIT;
            l_content_type := 'US';

        END IF;
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTHORITIES','Processing data into tdr_etl_tb_authorities table', 'AUTHORITY',null,null);
        INSERT INTO tdr_etl_tb_authorities (
            nkid,
            rid,
            authority_uuid,
            authority_type,
            location_code,
            official_name,
            authority_category,
            name,
            description,
            admin_zone_level,
            effective_zone_level,
            attr_official_name,
            attr_default_product_group,
            content_type,
            erp_tax_Code
        ) (
            SELECT DISTINCT
                ab.nkid,
                ab.rid,
                ab.authority_uuid,
                -- CRAPP-3720
                nvl(auth_type_id(ab.authority_type), auth_type_id(ab.effective_zone_level||' Sales/Use') ),
                case when l_content_type = 'US' then ab.location_code end location_code,

                a.official_name,
                ab.authority_category,
                ab.name,
                SUBSTR(ab.description,1,100) description,
                zone_level_id(nvl(ab.administrator_type,ab.effective_zone_level)) admin_level,
                zone_level_id(ab.effective_zone_level)
                , ab.official_name  -- attribute determination official name
                , ab.default_product_group -- determination default product group (conv id?)
                ,l_content_type, ab.erp_tax_code
            FROM tdr_etl_authority_base ab
            --left outer join mp_juris_auths ma on (ab.nkid = ma.jurisdiction_nkid and ab.authority_uuid = ma.authority_uuid)
            LEFT OUTER JOIN tb_authorities a ON (ab.authority_uuid = a.uuid)
        );
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTHORITIES','Calling build_tb_contributing_auths', 'BUILD_TB_CONTRIBUTING_AUTHS',null,null);
        build_tb_contributing_auths;
        build_tb_auth_logic;
        build_tb_auth_messages;
        set_transformed_date('AUTHORITIES');
        l_affected := l_affected+sql%rowcount;

        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTHORITIES','transformed '||l_affected||' Authorities for '||package_i,'AUTHORITY',null,null);
         COMMIT;

    exception
    when others then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTHORITIES','build_tb_authorities failed with '||sqlerrm,'AUTHORITY',null,null);
    RAISE_APPLICATION_ERROR(-20001,'TB authorities error.');

    END;

    PROCEDURE build_tb_contributing_auths
    IS
        l_affected NUMBER;
    BEGIN
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_CONTRIBUTING_AUTHS','transforming Contributing Authority data','CONTRIBUTING AUTHORITY',null,null);
        INSERT INTO tdr_etl_tb_contributing_auths (
            authority_uuid,
            this_authority_uuid,
            start_date,
            end_date
        ) (
            select distinct
                /*  3239
                contributee_uuid,
                contributor_uuid,
                */
                contributor_uuid,
                contributee_uuid,
                start_date,
                end_Date
            from tdr_etl_cntr_authorities ab

        );

        l_affected := sql%rowcount;

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_CONTRIBUTING_AUTHS','transformed '||l_affected||' Contriubting Authorities','CONTRIBUTING AUTHORITY',null,null);
         COMMIT;

    exception
    when others then
    etl_proc_log_p('DET_TRANSFORM.BUILD_TB_CONTRIBUTING_AUTHS','Contriubting Authorities failed with '||sqlerrm,'CONTRIBUTING AUTHORITY',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Tb contributing authorities error.');
    END build_tb_contributing_auths;

    FUNCTION auth_admin_level (
        admin_type_i IN VARCHAR2,
        loc_cat_i IN VARCHAR2
        ) RETURN NUMBER
    IS
        l_r NUMBER;
        l_admin_type VARCHAR2(30) := admin_type_i;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.AUTH_ADMIN_LEVEL','AUTH_ADMIN_LEVEL with admin_type_i:'||admin_type_i||', loc_cat_i:'||loc_cat_i, 'AUTH_ADMIN_LEVEL',null,null);
        IF (l_admin_type = 'Third-party') THEN
            l_admin_type := loc_cat_i;
        END IF;
        IF (l_admin_type = 'Country') THEN
            l_r := -1; --TB_ZONE_LEVELS: Country
        ELSIF (l_admin_type = 'State') THEN
            l_r := -4; --TB_ZONE_LEVELS: State
        ELSIF (l_admin_type = 'Province') THEN
            l_r := -2; --TB_ZONE_LEVELS: Province
        ELSIF (l_admin_type = 'District') THEN
            l_r := -3; --TB_ZONE_LEVELS: District
        ELSIF (l_admin_type = 'County') THEN
            l_r := -5; --TB_ZONE_LEVELS: County
        ELSIF (l_admin_type = 'City') THEN
            l_r := -6; --TB_ZONE_LEVELS: City
        END IF;
        etl_proc_log_p ('DET_TRANSFORM.AUTH_ADMIN_LEVEL','AUTH_ADMIN_LEVEL Returning l_r:'||l_r, 'AUTH_ADMIN_LEVEL',null,null);
        RETURN l_r;
    END auth_admin_level;

    PROCEDURE mod_TN_FL_STH
    IS
        cursor rates is
        select a.name, rt.*
        from (
            select uuid authority_uuid, name
            from tb_authorities
            where name like 'TN%' or name like 'FL%'
            union
            select authority_uuid, name
            from tdr_etl_tb_authorities
            where name like 'TN%' or name like 'FL%'
            ) a
        join tdr_etl_tb_rate_tiers rt on (rt.authority_uuid = a.authority_uuid)
        where ref_rate_Code is not null
        and rt.rate_code like 'TH%';

        cursor tiers(rate_id_i in number, low_i in number, high_i in number) is
        select greatest(low_i,nvl(amount_low,0)) amount_low, amount_high, nvl(r2.rate,rt.rate) rate
        from tb_rates r2
        left outer join tb_rate_tiers rt on (rt.rate_id = r2.rate_id)
        where r2.rate_id = rate_id_i
        and amount_low <= low_i
        and (amount_high is null or amount_high >= nvl(high_i,amount_high-1))
        order by amount_low;
        l_rate_id number;
        l_errcode number;
        l_errm varchar2(64);
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.MOD_TN_FL_STH','Inside MOD_TN_FL_STH', 'MOD_TN_FL_STH',null,null);
        for r in rates loop
            begin
                etl_proc_log_p ('DET_TRANSFORM.MOD_TN_FL_STH','Inside rates loop with r.ref_rate_Code:'||r.ref_rate_Code||', r.authority_uuid:'||r.authority_uuid||', r.start_date:'||r.start_date, 'MOD_TN_FL_STH',null,null);
                select r2.rate_id
                into l_rate_id
                from tb_rates r2
                join tb_authorities a on (a.uuid = r.authority_uuid and r2.authority_id = a.authority_id)
                where r2.rate_code = r.ref_rate_Code
                and r2.start_date <= r.start_date
                and nvl(r2.end_date,'31-Dec-9999') >= r.start_date
                and nvl(r2.is_local,'N') = nvl(r.is_local, 'N')
                and exists (
                    select 1
                    from tb_rate_tiers rt
                    where rt.rate_id = r2.rate_id
                    and nvl(rt.amount_low,0) <=nvl(r.amount_low,0)
                    and (rt.amount_high is null or rt.amount_high >= nvl(r.amount_high,rt.amount_high-1))
                );

                delete from tdr_etl_tb_rate_tiers rt
                where r.rate_code = rt.rate_code
                and rt.authority_uuid = r.authority_uuid
                and rt.start_date = r.start_Date
                and nvl(r.is_local, 'N') = nvl(rt.is_local, 'N')
                and rt.amount_low = r.amount_low;

                for t in tiers(l_rate_id, r.amount_low, r.amount_high) loop
                    etl_proc_log_p ('DET_TRANSFORM.MOD_TN_FL_STH','Inside tiers loop with l_rate_id:'||l_rate_id||', r.amount_low:'||r.amount_low||', r.amount_high:'||r.amount_high, 'MOD_TN_FL_STH',null,null);
                    INSERT INTO tdr_etl_tb_rate_tiers (
                        authority_uuid,
                        rate_code,
                        amount_low,
                        amount_high,
                        rate,
                        ref_rate_code,
                        flat_fee,
                        start_date,
                        is_local,
                        nkid,
                        rid
                    ) values (
                        r.authority_uuid,
                        r.rate_Code,
                        t.amount_low,
                        t.amount_high,
                        t.rate,
                        null,
                        null,
                        r.start_date,
                        r.is_local,
                        r.nkid,
                        r.rid  -- Adding NKID and RID for CRAPP-3164
                    );
                end loop;
            exception when no_data_found then
                --just ignore. If no tiered rate was found, then the Referenced Rate does not need to be changed to a constant rate value (from the referenced rate).
                null;
            end;
        end loop;
    exception when others then
         l_errcode := SQLCODE;
         l_errm := SUBSTR(SQLERRM, 1 , 64);

        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RATES',l_errcode||':'||l_errm,'RATE',null,null);

-- CRAPP-3218 Should the UI report this in its log?

    END mod_TN_FL_STH;

    PROCEDURE build_tb_rate_tiers
    IS
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RATE_TIERS','Started processing rate tiers','BUILD_TB_RATE_TIERS',null,null);
        INSERT INTO tdr_etl_tb_rate_tiers (
            authority_uuid,
            rate_code,
            amount_low,
            amount_high,
            rate,
            ref_rate_code,
            flat_fee,
            start_date,
            is_local,
            nkid,
            rid -- Adding NKID and RID for CRAPP-3164
        ) (
            SELECT DISTINCT
                ma.authority_uuid,
                tbr.rate_code,
                r.min_threshold,
                r.max_limit,
                CASE WHEN r.value_type = 'Rate' THEN TO_NUMBER(r.value)/100
                     WHEN r.value_type = 'Fee'  THEN TO_NUMBER(r.value)
                END rate,
                CASE --WHEN r.value_type = 'Referenced' THEN r.referenced_tax_ref_code
                     WHEN referenced_tax_ref_code IS NOT NULL THEN referenced_tax_ref_code
                END ref_rate_code,
                CASE WHEN r.value_type = 'Fee' THEN TO_NUMBER(r.value) END flat_fee, -- 05/18/16 crapp-2526 - changed value from "1"
                r.start_date,
                r.is_local,
                r.nkid,
                r.rid
            FROM tdr_etl_rates r
                JOIN mp_juris_auths ma ON (r.jurisdiction_nkid = ma.nkid)
                --JOIN tb_authorities a ON (a.uuid = ma.authority_uuid)
                JOIN tdr_etl_tb_rates tbr ON ( tbr.authority_uuid = ma.authority_uuid
                                           AND tbr.start_date = r.start_date
                                           AND tbr.rate_code  = r.reference_code
                                           AND NVL(tbr.is_local, 'N') = NVL(r.is_local, 'N')
                                         )
            WHERE r.tax_structure NOT IN ('Basic', 'Texas City/Cnty Max')
                AND tbr.split_type IS NOT NULL
        );
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RATE_TIERS','Calling mod_TN_FL_STH','BUILD_TB_RATE_TIERS',null,null);
        mod_TN_FL_STH;
        COMMIT;

    exception
    when others then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RATE_TIERS','BUILD_TB_RATE_TIERS failed with '||sqlerrm,'BUILD_TB_RATE_TIERS',null,null);
    RAISE_APPLICATION_ERROR(-20001,'Rate tiers error.');

    END;

    PROCEDURE rate_codes
    IS
        CURSOR new_rate_codes IS
            SELECT DISTINCT
                reference_code,
                specific_applicability_type,
                ja.authority_uuid
            FROM tdr_etl_rates r
            JOIN mp_juris_auths ja on (r.nkid = ja.nkid)
            WHERE NOT EXISTS (
                SELECT 1
                FROM mp_specapptype_rates sr
                WHERE sr.rate_code = r.reference_code
                AND sr.spec_applicability_type = specific_applicability_type
                AND sr.authority_uuid = ja.authority_uuid
            );
    BEGIN
        FOR nrc IN new_rate_codes LOOP
            etl_proc_log_p ('DET_TRANSFORM.RATE_CODES','Inside new_rate_codes loop with nrc.reference_code:'||nrc.reference_code||', nrc.specific_applicability_type:'
                ||nrc.specific_applicability_type
                        ||', nrc.authority_uuid:'||nrc.authority_uuid,'RATE_CODES',null,null);
            INSERT INTO mp_specapptype_rates (
                rate_code,
                spec_applicability_type,
                authority_uuid
            ) VALUES (
                nrc.reference_code,
                nrc.specific_applicability_type,
                nrc.authority_uuid
                );
        END LOOP;
    END rate_codes;

    PROCEDURE build_tb_rates
    IS
    cursor rates is
    select DISTINCT --NJV added to remove duplicates when tiers exist. 10/31/2014
        tr.rate_id,
        jurisdiction_nkid,
        ma.authority_uuid,
        r.reference_code rate_Code,
        r.start_date,
        r.end_date,
        /*CASE
            WHEN r.tax_structure = 'Basic' AND r.value_type = 'Rate' THEN r.value/100
            WHEN r.value_type = 'Fee' THEN r.value
        END  rate,*/
        stl.code split_type,
        satl.code split_amount_type,
        CASE WHEN r.value_type = 'Fee' THEN 1 END  flat_Fee,
        c.currency_id,
        is_local,
        'each' uom,
        r.description,   -- CRAPP-810 dlg
        r.nkid,  -- Adding NKID and RID for CRAPP-3164
        r.rid
    from tdr_etl_rates r
    left outer join mp_tax_Rate tr on (tr.tax_nkid = r.nkid and tr.outline_nkid = r.outline_nkid)
    left outer join tb_currencies c on (nvl(r.currency_code,'x') = c.currency_code)
    left outer join tb_lookups stl on (stl.code_group = 'SPLIT_TYPE' and stl.description = r.tax_structure)
    left outer join tb_lookups satl on (satl.code_group = 'SPLIT_AMT_TYPE' and satl.description = r.amount_type)
    join mp_juris_auths ma on (r.jurisdiction_nkid = ma.nkid);
    --join tb_authorities a on (a.uuid = ma.authority_uuid);
    l_rate number;
    l_affected number :=0;
    BEGIN
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_RATES','transforming Rate data','RATE',null,null);
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_RATES','update Tax to Rate mappings','RATE',null,null);
        --execute immediate 'truncate table mp_tax_rate'; --commented 05/05/2015, should fix CRAPP-1432, this allows for the retention of mappings even if the natural key has changed
        map_rates;
        FOR r IN rates LOOP
            l_rate := null;
            IF (r.split_type is null or nvl(r.split_type,'xx') = 'T') THEN
                BEGIN

                SELECT DISTINCT CASE
                    WHEN r2.tax_structure in ('Basic','Texas City/Cnty Max') AND r2.value_type = 'Rate' THEN to_number(r2.value)/100
                    WHEN r2.value_type = 'Fee' THEN to_number(r2.value)
                    END  rate
                INTO l_rate
                from tdr_etl_rates r2
                WHERE r2.jurisdiction_nkid = r.jurisdiction_nkid
                and r.rate_code = r2.reference_code
                and r.start_date = r2.start_date
                and nvl(r.is_local, 'N') = nvl(r2.is_local, 'N');
                EXCEPTION
                    WHEN others THEN
                    etl_proc_log_p('DET_TRANSFORM.BUILD_TB_RATES','inside rates loop, checking split type check failed for
                        JURISDICTION_NKID:'||r.jurisdiction_nkid||' RC:'||r.rate_code||' SD:'||r.start_Date||' IS_LOCAL:'||r.is_local, 'RATE',null,null);
                    RAISE;
                END;
            END IF;
            INSERT INTO tdr_etl_tb_rates
            (
                rate_id,
                authority_uuid,
                rate_code,
                is_local,
                start_date,
                end_date,
                rate,
                split_type,
                split_amount_type,
                flat_fee,
                currency_id,
                unit_of_measure_code,
                description,     -- CRAPP-810 dlg
                nkid,
                rid -- Adding NKID and RID for CRAPP-3164
            ) VALUES
                ( r.rate_id, r.authority_uuid, r.rate_code, r.is_local, r.start_Date, r.end_Date, l_rate, r.split_type, r.split_amount_type,
                  r.flat_fee, r.currency_id, r.uom, r.description, r.nkid, r.rid
                );
        COMMIT;
        END LOOP;
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RATES','Calling Rate Tiers','BUILD_TB_RATE_TIERS',null,null);
        build_tb_rate_tiers;
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RATES','Calling Rate Tiers completed','BUILD_TB_RATE_TIERS',null,null);

        set_transformed_date('RATES');

        COMMIT;

    exception
    when TIMEOUT_ON_RESOURCE then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RATES','Failed with '||sqlerrm,'RATE',null,null);
    RAISE_APPLICATION_ERROR(-20001,'TB rates timeout.');
    when others then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_RATES','Failed with '||sqlerrm,'RATE',null,null);
    RAISE_APPLICATION_ERROR(-20002,'TB rates error.');

    END;

    PROCEDURE auth_append_det_data
    IS
    BEGIN
        NULL;
        --Map Jurisdictions by State, Authority Type, and Effective Level to existing Authority Logic Mappings
        /*INSERT INTO tdr_etl_auth_logic_mapping (nkid, authority_logic_group_id, start_date, end_date, process_order) (
        SELECT ab.nkid, alg.authority_logic_group_id, alg.start_date, alg.end_Date, alg.process_order
        FROM map_authority_logic_groups alg
        JOIN tdr_etl_authority_base ab on (
            alg.state = substr(ab.name,1,2)
            and ab.effective_zone_level = alg.effective_zone_level
            and ab.authority_type = alg.authority_type)
        );
        COMMIT;*/
    END auth_append_det_data;

    PROCEDURE load_logic_mapping
    IS
    BEGIN
        NULL;
        /*DELETE FROM map_authority_logic_groups;
        COMMIT;
        INSERT INTO map_authority_logic_groups (state, authority_type, effective_zone_level, authority_logic_group_id, authority_logic_group, start_Date, end_date, process_order) (
        select distinct substr(a.name,1,2) state, aty.name authority_type, zl.name effective_zone_level, alg.authority_logic_group_id, alg.name authority_logic_group, algx.start_Date, algx.end_date, algx.process_order
        from tb_authority_logic_groups alg
        join tb_authority_logic_group_xref algx on (algx.authority_logic_group_id = alg.authority_logic_group_id)
        join tb_authorities a on (algx.authority_id = a.authority_id)
        join tb_zone_levels zl on (zl.zone_level_id = a.effective_zone_level_id)
        join tb_authority_types aty on (aty.authority_type_id = a.authority_type_id)
        );
        COMMIT;*/
    END load_logic_mapping;

    PROCEDURE build_tb_auth_logic
    IS

    BEGIN
        --execute immediate 'truncate table tdr_etl_auth_logic_mapping';
        etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTH_LOGIC','Calling auth_append_det_data','BUILD_TB_AUTH_LOGIC',null,null);
        auth_append_det_data;
        INSERT INTO tdr_etl_tb_auth_logic_groups (
            authority_uuid,
            authority_logic_group_id,
            start_date,
            end_date,
            process_order,
            nkid,
            rid
        ) (
        SELECT
            ma.authority_uuid,
            tal.authority_logic_group_id,
            start_date,
            end_date,
            process_order,
            alg.nkid,
            alg.rid
        FROM tdr_etl_auth_logic_mapping alg
        JOIN mp_juris_auths ma ON (alg.nkid = ma.nkid)
        JOIN tb_authority_logic_groups tal on tal.name = alg.logic_group_name
        where not exists ( select 1 from tdr_etl_tb_auth_logic_mapping t1
                            where t1.authority_uuid = ma.authority_uuid
                              and t1.authority_logic_group_id = tal.authority_logic_group_id
                              and t1.start_date = alg.start_date
                              and nvl(t1.end_date, '31-Dec-9999') = nvl(alg.end_date, '31-dec-9999')
                        )
        );
        COMMIT;

    -- most likely no data found if failed
    exception
    when no_data_found then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTH_LOGIC','BUILD_TB_AUTH_LOGIC failed with '||sqlerrm,'BUILD_TB_AUTH_LOGIC',null,null);
    RAISE_APPLICATION_ERROR(-20001,'TB Auth data not found.');
    when others then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTH_LOGIC','BUILD_TB_AUTH_LOGIC failed with '||sqlerrm,'BUILD_TB_AUTH_LOGIC',null,null);
    RAISE_APPLICATION_ERROR(-20002,'TB Authority error.');

    END;

    PROCEDURE build_tb_auth_messages
    IS
    BEGIN
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTH_MESSAGES','Calling auth_append_det_data','BUILD_TB_AUTH_MESSAGES',null,null);
    -- tb_app_errors.category -- always 'JURISDICTION DETERMINATION'
        INSERT INTO tdr_etl_tb_auth_messages (
             authority_uuid
            ,error_num
            ,error_severity
            ,title
            ,description
            ,start_date
            ,end_date
            ,nkid
            ,rid
        ) (
        SELECT
            ma.authority_uuid
           ,msg.error_msg
           ,tal.severity_code
           ,msg.error_msg
           ,msg.msg_description description
           ,msg.start_date
           ,msg.end_date
           ,msg.nkid
           ,msg.rid
        FROM tdr_etl_auth_error_messages msg
        JOIN mp_juris_auths ma ON (msg.nkid = ma.nkid)
        JOIN content_repo.juris_msg_severity_lookups tal on (tal.severity_id = msg.severity_id)
        where not exists ( select 1 from tdr_etl_tb_auth_messages t1
                            where t1.authority_uuid = ma.authority_uuid
                              and t1.error_num = msg.error_msg
                              and t1.start_date = msg.start_date
                              and nvl(t1.end_date, '31-Dec-9999') = nvl(msg.end_date, '31-dec-9999')
                        )
        );
        COMMIT;
    -- most likely no data found if failed
    exception
    when no_data_found then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTH_MESSAGES','BUILD_TB_AUTH_MESSAGES failed with '||sqlerrm,'BUILD_TB_AUTH_MESSAGES',null,null);
    RAISE_APPLICATION_ERROR(-20001,'TB Auth data not found.');
    when others then
    etl_proc_log_p ('DET_TRANSFORM.BUILD_TB_AUTH_MESSAGES','BUILD_TB_AUTH_MESSAGES failed with '||sqlerrm,'BUILD_TB_AUTH_MESSAGES',null,null);
    RAISE_APPLICATION_ERROR(-20002,'TB Authority error.');

    END;



    FUNCTION tax_type_us(rate_code_i IN VARCHAR2) RETURN VARCHAR2
    IS
        l_rv VARCHAR2(8) := NULL;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.TAX_TYPE_US','Inside TAX_TYPE_US process with rate code:'||rate_code_i,'TAX_TYPE_US',null,null);
        IF rate_code_i LIKE '%CU%' THEN
            l_rv := 'CU';
        ELSIF rate_code_i LIKE '%SU%' THEN
            l_rv := 'US';
        ELSIF rate_code_i LIKE '%RU' THEN
            l_rv := 'RU';
        ELSIF rate_code_i LIKE '%ST%' THEN
            l_rv := 'SA';
        ELSIF rate_code_i LIKE '%RS' THEN
            l_rv := 'RS';
        ELSIF rate_code_i LIKE 'TSP%' THEN
            l_rv := 'SV';
        ELSIF rate_code_i LIKE 'TUT%' THEN
            l_rv := 'UU';
        ELSIF rate_code_i LIKE 'TEX%' THEN
            l_rv := 'EXC';
        ELSIF rate_code_i LIKE 'TGR%' THEN
            l_rv := 'GR';
        ELSIF rate_code_i LIKE 'TS%'
            AND rate_code_i NOT LIKE 'TSP%'
            AND rate_code_i NOT LIKE 'TST%'
            AND rate_code_i NOT LIKE 'TSU%'
            THEN
            l_rv := 'SC';
        ELSIF rate_code_i LIKE 'TBO%' THEN
            l_rv := 'BO';
        ELSIF rate_code_i LIKE 'TLT%' THEN
            l_rv := 'LT';
        ELSIF
            rate_code_i NOT LIKE '%CU'
            AND rate_code_i NOT LIKE '%SU'
            AND rate_code_i NOT LIKE '%ST' THEN
            l_rv := 'SA';
        END IF;
        etl_proc_log_p ('DET_TRANSFORM.TAX_TYPE_US','Inside TAX_TYPE_US process returning l_rv:'||l_rv,'TAX_TYPE_US',null,null);
        RETURN l_rv;
    END tax_type_us;

    FUNCTION tax_type_intl(auth_uuid_i IN VARCHAR2, rate_code_i IN VARCHAR2) RETURN VARCHAR2
    IS
        l_rv VARCHAR2(100) := NULL;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.TAX_TYPE_INTL','Inside TAX_TYPE_INTL process with rate code:'||rate_code_i||', auth_uuid_i:'||auth_uuid_i,'TAX_TYPE_INTL',null,null);
        SELECT listagg(nvl(tax_type,'xx'),',') within group (order by tax_type)
        into l_rv
        from (
            select distinct tax_type
            from tb_authorities a
            join tb_rules r on (r.authority_id = a.authority_id and r.merchant_id = a.merchant_id)
            where uuid = auth_uuid_i
            and r.rule_order != 5000
            and (r.rate_code is null or r.rate_code = rate_code_i)
            );
        etl_proc_log_p ('DET_TRANSFORM.TAX_TYPE_INTL','Inside TAX_TYPE_INTL process returning l_rv:'||l_rv,'TAX_TYPE_INTL',null,null);
        RETURN l_rv;
    END tax_type_intl;

    FUNCTIOn tax_type(auth_uuid_i IN VARCHAR2, content_type_i IN VARCHAR2, rate_code_i IN VARCHAR2) RETURN VARCHAR2
    IS
        l_rv VARCHAR2(64) := NULL;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.TAX_TYPE','Inside TAX_TYPE process with auth_uuid_i:'||auth_uuid_i||', rate_code_i:'||rate_code_i||', content_type_i:'||content_type_i,
                'TAX_TYPE',null,null);
        IF (content_type_i = 'US') THEN
           l_rv := tax_type_us(rate_code_i);
        ELSE
            l_rv := tax_type_intl(auth_uuid_i, rate_code_i);
        END IF;
        etl_proc_log_p ('DET_TRANSFORM.TAX_TYPE','Inside TAX_TYPE process returning l_rv:'||l_rv, 'TAX_TYPE', null, null );
        RETURN l_rv;
    END tax_type;

    FUNCTION zone_level_id(name_i IN VARCHAR2) RETURN NUMBER
    IS
        ret_val NUMBER;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.ZONE_LEVEL_ID','Inside ZONE_LEVEL_ID process with name_i:'||name_i, 'ZONE_LEVEL_ID', null, null );
        SELECT zone_level_id
        INTO ret_val
        FROM tb_zone_levels
        WHERE name = name_i;
        etl_proc_log_p ('DET_TRANSFORM.ZONE_LEVEL_ID','Inside ZONE_LEVEL_ID process withreturning ret_val:'||ret_val, 'ZONE_LEVEL_ID', null, null );
        RETURN ret_val;
    END zone_level_id;

    FUNCTION tax_type_level(tax_type_i IN VARCHAR2) RETURN NUMBER
    IS
        l_rv NUMBER := 0;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.TAX_TYPE_LEVEL','Inside TAX_TYPE_LEVEL process with tax_type_i:'||tax_type_i,'TAX_TYPE_LEVEL',null,null);
        IF (tax_type_i IN ('SA','S')) THEN
            l_rv := 1;
        ELSIF (tax_type_i = 'US') THEN
            l_rv := 2;
        ELSIF (tax_type_i IN ('RS','ZE')) THEN
            l_rv := 3;
        ELSIF (tax_type_i IN ('RU','ZR')) THEN
            l_rv := 4;
        ELSIF (tax_type_i IN ( 'CU','RC')) THEN
            l_rv := 5;
        ELSIF (tax_type_i IN ('IM','IS','SV')) THEN
            l_rv := 6;
        ELSIF (tax_type_i IN ('EC','UU')) THEN
            l_rv := 7;
        ELSIF (tax_type_i = 'EXC') THEN
            l_rv := 8;
        ELSIF (tax_type_i IN ('GR','TR')) THEN
            l_rv := 9;
        ELSIF (tax_type_i IN ( 'SC','SN')) THEN
            l_rv := 10;
        ELSIF (tax_type_i IN ('BO','SI')) THEN
            l_rv := 11;
        ELSIF (tax_type_i IN ('LT','ZC')) THEN
            l_rv := 12;
        ELSIF (tax_type_i = 'VG') THEN
            l_rv := 13;
        ELSIF (tax_type_i = 'DS') THEN
            l_rv := 14;
        ELSIF (tax_type_i = 'MA') THEN
            l_rv := 15;
        ELSIF (tax_type_i = 'MP') THEN
            l_rv := 16;
        ELSIF (tax_type_i = 'MVT') THEN
            l_rv := 17;
        ELSIF (tax_type_i = 'UN') THEN
            l_rv := 18;
        ELSIF (tax_type_i = 'AC') THEN
            l_rv := 19;
        ELSIF (tax_type_i = 'ER') THEN
            l_rv := 20;
        ELSIF (tax_type_i = 'ES') THEN
            l_rv := 22;
        ELSIF (tax_type_i = 'IC') THEN
            l_rv := 23;
        ELSIF (tax_type_i = 'NR') THEN
            l_rv := 24;
        ELSIF (tax_type_i = 'TE') THEN
            l_rv := 25;
        ELSIF (tax_type_i = 'STK') THEN
            l_rv := 26;
        ELSIF (tax_type_i = 'NL') THEN
            l_rv := 27;
        END IF;
        etl_proc_log_p ('DET_TRANSFORM.TAX_TYPE_LEVEL','Inside TAX_TYPE_LEVEL process returning l_rv:'||l_rv,'TAX_TYPE_LEVEL',null,null);
        RETURN l_rv;
    END tax_type_level;

    FUNCTION auth_type_id(name_i IN VARCHAR2) RETURN NUMBER
    IS
        ret_val NUMBER;
        l_name VARCHAR2(100) := name_i;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.AUTH_TYPE_ID','Inside AUTH_TYPE_ID process with name_i:'||name_i,'AUTH_TYPE_ID',null,null);
        SELECT authority_type_id
        INTO ret_val
        FROM tb_authority_types
        WHERE name = l_name
        AND merchant_id = (select merchant_id from tb_merchants where name like 'Sabrix%Tax Data');
        etl_proc_log_p ('DET_TRANSFORM.AUTH_TYPE_ID','Inside AUTH_TYPE_ID process returning ret_val:'||ret_val,'AUTH_TYPE_ID',null,null);
        RETURN ret_val;
    END auth_type_id;

    FUNCTION auth_name(juris_name_i IN VARCHAR2) RETURN VARCHAR2
    IS
        ret_val VARCHAR2(100);
    BEGIN
        --Create logic to parse and build authority name for Determination standards
        --02/2/2015: Currently the translation of name is 1:1 Authority.Name=Jurisdiction.Official_Name
        --it's expected that one day Jurisdictions will be consolidated as appropriate
        --generating the Authority.Name will become more complex at that time
        ret_val := juris_name_i;
        RETURN ret_val;
    END auth_name;

    PROCEDURE map_reference_lists
    IS
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.MAP_REFERENCE_LISTS','Inside MAP_REFERENCE_LISTS process','MAP_REFERENCE_LISTS',null,null);
        execute immediate 'truncate table mp_ref_lists';
        INSERT INTO mp_ref_lists (ref_group_nkid, reference_list_id) (
        SELECT nkid, reference_list_id
        FROM content_repo.mvreference_groups r
        JOIN tb_reference_lists rl on (rl.name = replace(replace(r.name,' (US Determination)'),' (INTL Determination)') and rl.start_date = to_date(r.start_date,'MM/DD/YYYY'))
        );
        etl_proc_log_p ('DET_TRANSFORM.MAP_REFERENCE_LISTS','Inside MAP_REFERENCE_LISTS process, mapping completed','MAP_REFERENCE_LISTS',null,null);
        COMMIT;

    exception
    when TIMEOUT_ON_RESOURCE then
    etl_proc_log_p ('DET_TRANSFORM.MAP_REFERENCE_LISTS','Inside MAP_REFERENCE_LISTS process, failed with '||sqlerrm,'MAP_REFERENCE_LISTS',null,null);
    RAISE_APPLICATION_ERROR(-20001,'Map reference list timeout.');
    when others then
    etl_proc_log_p ('DET_TRANSFORM.MAP_REFERENCE_LISTS','Inside MAP_REFERENCE_LISTS process, failed with '||sqlerrm,'MAP_REFERENCE_LISTS',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Map reference list error.');

    END;

    PROCEDURE map_rule_rq
    IS
    cursor unique_rqs is
        select distinct authority_id, uuid,
            listagg(element||'-'||operator||'-'||value,'|') within group (order by element, operator, value, start_date, end_date) rqs, start_date, end_date,
            count(*) c
        from (
            select a.authority_id, a.uuid, rq.element, rq.operator,
                case rq.rule_qualifier_type
                    when 'CONDITION' then rq.value
                    when 'AUTHORITY' then trim(rqa.uuid||' '||nvl(rq.value,''))
                    when 'LIST' then l.name
                    else rq.value end value, r.rule_id,
                rq.start_date, rq.end_date
            from tb_authorities a
            join tb_rules r on (a.authority_id = r.authority_id)
            join tb_rule_qualifiers rq on (rq.rule_id = r.rule_id)
            left outer join tb_reference_lists l on (l.reference_list_id = nvl(rq.reference_list_id,-1))
            left outer join tb_authorities rqa on (rqa.authority_id = nvl(rq.authority_id,-2))
            union
            select a.authority_id, a.uuid, 'TAX_CODE', '=', r.code, r.rule_id, r.start_date, r.end_date
            from tb_authorities a
            join tb_rules r on (a.authority_id = r.authority_id)
            where r.code is not null
            union
            select a.authority_id, a.uuid, 'EXEMPT_REASON_CODE', '=', r.exempt_Reason_code, r.rule_id, r.start_date, r.end_date
            from tb_authorities a
            join tb_rules r on (a.authority_id = r.authority_id)
            where r.exempt_Reason_code is not null
            union
            select a.authority_id, a.uuid, 'TAX_TYPE', '=', tt.description, r.rule_id, r.start_date, r.end_date
            from tb_authorities a
            join tb_rules r on (a.authority_id = r.authority_id)
            join (
                select distinct code, description, replace(code_group,'_TAX_TYPE') content_type
                from tb_lookups l
                where l.code_group like '%TAX_TYPE'
                ) tt on (tt.code = r.tax_type and a.content_type = tt.content_type)
            where r.tax_type is not null
            and a.content_type = 'INTL'
            ) group by authority_id, uuid, rule_id, start_date, end_date;

    cursor rule_quals(uuid_i IN VARCHAR2, rqs_i IN VARCHAR2) is
    select distinct rule_id --, element, operator, value, c
    from (
        select distinct rule_id, listagg(element||'-'||operator||'-'||value,'|') within group (order by element, operator, value) over (partition by authority_id, uuid, rule_id) rqs
        from (
            select distinct a.authority_id, a.uuid, rq.element, rq.operator,
                case rq.rule_qualifier_type
                    when 'CONDITION' then rq.value
                    when 'AUTHORITY' then trim(rqa.uuid||' '||nvl(rq.value,''))
                    when 'LIST' then l.name
                    else rq.value end value, r.rule_id
            from tb_authorities a
            join tb_rules r on (a.authority_id = r.authority_id)
            join tb_rule_qualifiers rq on (rq.rule_id = r.rule_id)
            left outer join tb_reference_lists l on (l.reference_list_id = nvl(rq.reference_list_id,-1))
            left outer join tb_authorities rqa on (rqa.authority_id = nvl(rq.authority_id,-2))
            where a.uuid = uuid_i
            union
            select a.authority_id, a.uuid, 'TAX_CODE', '=', r.code, r.rule_id
            from tb_authorities a
            join tb_rules r on (a.authority_id = r.authority_id)
            where r.code is not null
            and a.uuid = uuid_i
        ) --group by rule_id
    ) s
    where s.rqs = rqs_i;

    begin
        execute immediate 'truncate table mp_rule_rq';

        for ur in unique_rqs loop
            for ru in rule_quals( ur.uuid,ur.rqs) loop
                begin
                    insert into mp_rule_rq (authority_uuid, rule_id, rule_qualifier_set, start_date, end_date)
                    values (ur.uuid, ru.rule_id, ur.rqs, ur.start_date, ur.end_date);
                exception
                when others then
                    etl_proc_log_p ('DET_TRANSFORM.MAP_RULE_RQ','Inside MAP_RULE_RQ process, ur.uuid:'||ur.uuid||', ur.rqs:'||ur.rqs||', failed with '||sqlerrm,'MAP_RULE_RQ',null,null);
                    RAISE_APPLICATION_ERROR(-20002,'Map rule error. Proc:map_rule_rq, failedd inside loop rule_quals');
                end;
            end loop;
        end loop;
        COMMIT;

    exception
    when others then
    etl_proc_log_p ('DET_TRANSFORM.MAP_RULE_RQ','Inside MAP_RULE_RQ process, failed with '||sqlerrm,'MAP_RULE_RQ',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Map rule error. Proc:map_rule_rq');

    END map_rule_rq;

    PROCEDURE map_jta_rq
    IS
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.MAP_JTA_RQ','Inside MAP_JTA_RQ process','MAP_JTA_RQ',null,null);

        delete from mp_jta_rq where jta_nkid in ( select nkid from content_repo.tdr_etl_map_jta_rq);

        insert all into mp_jta_rq select * from content_repo.tdr_etl_map_jta_rq;
        /*
        insert into mp_jta_rq(juris_nkid, jta_nkid, rule_qualifier_set, start_date, end_date) (
        select distinct jurisdiction_nkid, nkid, listagg(element_name||'-'||logical_qualifier||'-'||value,'|') within group (order by element_name, logical_qualifier, value) rqs,
            start_date, end_date
        from (
            select distinct jta.jurisdiction_nkid, jta.nkid, te.element_name, ttq.logical_qualifier,
                case when ttq.reference_group_nkid is not null then replace(replace(rg.name,' (US Determination)'),' (INTL Determination)')
                    when ttq.jurisdiction_nkid is not null then trim(ja.authority_uuid||' '||nvl(ttq.value,''))
                    else ttq.value end value, ttq.start_Date, ttq.end_date
            from crapp_extract.juris_tax_applicabilities jta
            join crapp_extract.tran_tax_qualifiers ttq on (ttq.juris_tax_applicability_nkid = jta.nkid and ttq.next_rid is null)
            left outer join crapp_extract.reference_groups rg on (nvl(ttq.reference_group_nkid,-1) = rg.nkid and rg.next_rid is null)
            left outer join crapp_extract.jurisdictions j on (nvl(ttq.jurisdiction_nkid,-1) = j.nkid and j.next_rid is null)
            left outer join mp_juris_auths ja on (ja.nkid = j.nkid)
            -- CRAPP_3033
            left join crapp_Extract.taxability_elements te on (te.id = ttq.taxability_element_id)
            where jta.next_rid is null
            ) group by jurisdiction_nkid, nkid, start_date, end_date
        );
        */
        commit;

    exception
    when others then
    etl_proc_log_p ('DET_TRANSFORM.MAP_JTA_RQ','Inside MAP_JTA_RQ process, failed with '||sqlerrm,'MAP_JTA_RQ',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Map jta error. Proc:Map_Jta_rq');

    END map_jta_rq;

    PROCEDURE map_commodities_products
    IS
        l_ptt number :=  cr_extract.prod_level_token;
    BEGIN

        -- Compare the existing table and create only new data
        -- there will be a new jira soon.

        execute immediate 'truncate table mp_comm_prods';

        etl_proc_log_p ('DET_TRANSFORM.MAP_COMMODITIES_PRODUCTS','Inside MAP_COMMODITIES_PRODUCTS proces.','MAP_COMMODITIES_PRODUCTS',null,null);
        insert into mp_comm_prods (commodity_nkid, product_category_id) (
        select distinct coalesce(p9.nkid,p8.nkid,p7.nkid,p6.nkid,p5.nkid,p4.nkid,p3.nkid,p2.nkid,p1.nkid) nkid, pt.primary_key
        from ct_product_tree pt
        join tb_product_groups pg on (pg.product_group_id = pt.product_group_id)
        join (
            select name, sort_key, product_tree, prodcode, description, nkid
            from tdr_etl_product_categories pc
            where length(sort_key) = l_ptt
            ) p1 on (p1.name = pt.product_1_name and pg.name = p1.product_tree)
        left outer join tdr_etl_product_categories p2 on (
            length(p2.sort_key) = l_ptt*2
            and instr(p2.sort_key,p1.sort_key) = 1
            and p1.product_tree = p2.product_tree
            and nvl(pt.product_2_name,'PRODUCT_2_NAME') = p2.name
            )
        left outer join tdr_etl_product_categories p3 on (
            length(p3.sort_key) = l_ptt*3
            and instr(p3.sort_key,p2.sort_key) = 1
            and p2.product_tree = p3.product_tree
            and nvl(pt.product_3_name,'PRODUCT_3_NAME') = p3.name
            )
        left outer join tdr_etl_product_categories p4 on (
            length(p4.sort_key) = l_ptt*4
            and instr(p4.sort_key,p3.sort_key) = 1
            and p3.product_tree = p4.product_tree
            and nvl(pt.product_4_name,'PRODUCT_4_NAME') = p4.name
            )
        left outer join tdr_etl_product_categories p5 on (
            length(p5.sort_key) = l_ptt*5
            and instr(p5.sort_key,p4.sort_key) = 1
            and p4.product_tree = p5.product_tree
            and nvl(pt.product_5_name,'PRODUCT_5_NAME') = p5.name
            )
        left outer join tdr_etl_product_categories p6 on (
            length(p6.sort_key) = l_ptt*6
            and instr(p6.sort_key,p5.sort_key) = 1
            and p5.product_tree = p6.product_tree
            and nvl(pt.product_6_name,'PRODUCT_6_NAME') = p6.name
            )
        left outer join tdr_etl_product_categories p7 on (
            length(p7.sort_key) = l_ptt*7
            and instr(p7.sort_key,p6.sort_key) = 1
            and p6.product_tree = p7.product_tree
            and nvl(pt.product_7_name,'PRODUCT_7_NAME') = p7.name
            )
        left outer join tdr_etl_product_categories p8 on (
            length(p8.sort_key) = l_ptt*8
            and instr(p8.sort_key,p7.sort_key) = 1
            and p7.product_tree = p8.product_tree
            and nvl(pt.product_8_name,'PRODUCT_8_NAME') = p8.name
            )
        left outer join tdr_etl_product_categories p9 on (
            length(p9.sort_key) = l_ptt*9
            and instr(p9.sort_key,p8.sort_key) = 1
            and p8.product_tree = p9.product_tree
            and nvl(pt.product_9_name,'PRODUCT_9_NAME') = p9.name
            )
        left outer join tdr_etl_product_categories p10 on (
            length(p10.sort_key) = l_ptt*10
            and instr(p10.sort_key,p9.sort_key) = 1
            and p9.product_tree = p10.product_tree
            and nvl(pt.product_10_name,'PRODUCT_10_NAME') = p10.name
            )
        );
        commit;

    exception
    when NO_DATA_FOUND then
    etl_proc_log_p ('DET_TRANSFORM.MAP_COMMODITIES_PRODUCTS','Inside MAP_COMMODITIES_PRODUCTS proces.','MAP_COMMODITIES_PRODUCTS',null,null);
    RAISE_APPLICATION_ERROR(-20001,'Map commodities no data.');
    when others then
    etl_proc_log_p ('DET_TRANSFORM.MAP_COMMODITIES_PRODUCTS','Inside MAP_COMMODITIES_PRODUCTS proces.','MAP_COMMODITIES_PRODUCTS',null,null);
    RAISE_APPLICATION_ERROR(-20002,'Map commodities error.');

    END map_commodities_products;

    FUNCTION add_tax_type(rule_order_i IN NUMBER, tax_type_i IN VARCHAR2, is_local_i IN VARCHAR2) RETURN NUMBER
    IS
        l_new_rule_order number := rule_order_i;
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.ADD_TAX_TYPE','Inside ADD_TAX_TYPE proces, with rule_order_i:'||rule_order_i||', tax_type_i:'||tax_type_i||', is_local_i:'||is_local_i,'ADD_TAX_TYPE',null,null);
        IF (tax_type_i IS NULL) THEN
            --a NULL or "catchall" tax_type must be the highest rule order
            IF (is_local_i = 'Y') THEN
                l_new_rule_order := l_new_rule_order-.0001;
            END IF;
        ELSE
            l_new_rule_order := l_new_rule_order-tax_type_level(tax_type_i)*.0002;
            --all other tax_types are peers and the order is arbitrary, but should be consistent
            IF (is_local_i = 'Y') THEN
                l_new_rule_order := l_new_rule_order-.0001;
            END IF;
        END IF;
        etl_proc_log_p ('DET_TRANSFORM.ADD_TAX_TYPE','Inside ADD_TAX_TYPE proces, returning l_new_rule_order:'||l_new_rule_order,'ADD_TAX_TYPE',null,null);
        return l_new_rule_order;
    END add_tax_type;

    FUNCTION gen_inv_desc(tax_desc_i IN VARCHAR2, exempt_i IN VARCHAR2, no_tax_i IN VARCHAR2) RETURN VARCHAR2
        IS
        l_rv VARCHAR2(250);
    BEGIN
        etl_proc_log_p ('DET_TRANSFORM.GEN_INV_DESC','Inside GEN_INV_DESC proces, with tax_desc_i:'||tax_desc_i||', exempt_i:'||exempt_i||', no_tax_i:'||no_tax_i,'GEN_INV_DESC',null,null);
        IF (exempt_i = 'Y')
            THEN l_rv := 'Exempt '||tax_desc_i;
        ELSIF (no_tax_i = 'Y')
            THEN l_rv := 'No Tax '||tax_desc_i;
        ELSE
            l_rv := tax_desc_i;
        END IF;
        etl_proc_log_p ('DET_TRANSFORM.GEN_INV_DESC','Inside GEN_INV_DESC proces, returning tax_desc_i:'||tax_desc_i||', exempt_i:'||exempt_i||', no_tax_i:'||no_tax_i,'GEN_INV_DESC',null,null);
        RETURN l_rv;
    END gen_inv_desc;


    PROCEDURE build_tb_zones IS   -- 03/24/17 - crapp-3363
        l_merch_id NUMBER;
        l_zone1_id NUMBER;

        CURSOR zone_deletes IS
            SELECT *
            FROM tdr_etl_us_zone_changes
            WHERE change_type = 'Delete'
            ORDER BY CASE WHEN county IS NULL THEN 1 WHEN city IS NULL THEN 2 WHEN postcode IS NULL THEN 3 ELSE 4 END;

        CURSOR zone_updates IS
            SELECT DISTINCT state, county, city, postcode, plus4, code_2char, code_3char, code_fips, reverse_flag, terminator_flag, default_flag
            FROM tdr_etl_us_zone_changes zc
                 JOIN tdr_etl_zone_attributes za ON (za.tmp_id = zc.id)
            WHERE change_type = 'Update';

        CURSOR zone_adds IS
            SELECT zc.*, za.*, CASE WHEN zc.plus4 IS NOT NULL THEN SUBSTR(zc.plus4,1,4) END range_min,
                   CASE WHEN zc.plus4 IS NOT NULL THEN SUBSTR(zc.plus4,6,4) END range_max
            FROM tdr_etl_us_zone_changes zc
                 JOIN tdr_etl_zone_attributes za ON (za.tmp_id = zc.id)
            WHERE change_type = 'Add';
    BEGIN

        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_ct_zone_tree DROP STORAGE';

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONES','Get existing CT Zone Tree - start','GIS',NULL,NULL);

        --pull in the existing zone tree for each zone in tdr_etl_us_zone_changes
        INSERT INTO tdr_etl_ct_zone_tree (MERCHANT_ID,PRIMARY_KEY,ZONE_1_ID,ZONE_1_NAME,ZONE_1_LEVEL_ID,ZONE_2_ID,
            ZONE_2_NAME,ZONE_2_LEVEL_ID,ZONE_3_ID,ZONE_3_NAME,ZONE_3_LEVEL_ID,ZONE_4_ID,ZONE_4_NAME,
            ZONE_4_LEVEL_ID,ZONE_5_ID,ZONE_5_NAME,ZONE_5_LEVEL_ID,ZONE_6_ID,ZONE_6_NAME,ZONE_6_LEVEL_ID,ZONE_7_ID,
            ZONE_7_NAME,ZONE_7_LEVEL_ID,TAX_PARENT_ZONE,EU_ZONE_AS_OF_DATE,CODE_2CHAR,CODE_3CHAR,CODE_ISO,CODE_FIPS,
            REVERSE_FLAG,TERMINATOR_FLAG,DEFAULT_FLAG,RANGE_MIN,RANGE_MAX,CREATION_DATE,ZONE_8_NAME,ZONE_8_ID,
            ZONE_8_LEVEL_ID,ZONE_9_NAME,ZONE_9_ID,ZONE_9_LEVEL_ID) (
        SELECT MERCHANT_ID,PRIMARY_KEY,ZONE_1_ID,ZONE_1_NAME,ZONE_1_LEVEL_ID,ZONE_2_ID,
            ZONE_2_NAME,ZONE_2_LEVEL_ID,ZONE_3_ID,ZONE_3_NAME,ZONE_3_LEVEL_ID,ZONE_4_ID,ZONE_4_NAME,
            ZONE_4_LEVEL_ID,ZONE_5_ID,ZONE_5_NAME,ZONE_5_LEVEL_ID,ZONE_6_ID,ZONE_6_NAME,ZONE_6_LEVEL_ID,ZONE_7_ID,
            ZONE_7_NAME,ZONE_7_LEVEL_ID,TAX_PARENT_ZONE,EU_ZONE_AS_OF_DATE,CODE_2CHAR,CODE_3CHAR,CODE_ISO,CODE_FIPS,
            REVERSE_FLAG,TERMINATOR_FLAG,DEFAULT_FLAG,RANGE_MIN,RANGE_MAX,CREATION_DATE,ZONE_8_NAME,ZONE_8_ID,
            ZONE_8_LEVEL_ID,ZONE_9_NAME,ZONE_9_ID,ZONE_9_LEVEL_ID
        FROM ct_zone_tree zt
        WHERE zt.zone_3_name IS NOT NULL
              AND EXISTS (
                          SELECT 1
                          FROM tdr_etl_us_zone_changes zc
                          WHERE zc.state = zt.zone_3_name
                          AND zc.state IS NOT NULL
                         )
        );
        commit;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONES','Get existing CT Zone Tree - end','GIS',NULL,NULL);

        SELECT MAX(merchant_id), MAX(zone_1_id)
        INTO l_merch_id, l_zone1_id
        FROM tdr_etl_ct_zone_tree;


        --delete first
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONES','Process deletes - start','GIS',NULL,NULL);
        for d in zone_deletes loop
            IF d.county IS NULL THEN
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_4_name IS NULL
                AND zone_3_name = d.state;
            ELSIF d.city IS NULL THEN
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_5_name IS NULL
                AND zone_4_name = d.county
                AND zone_3_name = d.state;
            ELSIF d.postcode IS NULL THEN
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_6_name IS NULL
                AND zone_5_name = d.city
                AND zone_4_name = d.county
                AND zone_3_name = d.state;
            ELSIF d.plus4 IS NULL THEN
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_7_name IS NULL
                AND zone_6_name = d.postcode
                AND zone_5_name = d.city
                AND zone_4_name = d.county
                AND zone_3_name = d.state;
            ELSE
                DELETE FROM tdr_etl_ct_zone_tree
                WHERE zone_7_name = d.plus4
                AND zone_6_name = d.postcode
                AND zone_5_name = d.city
                AND zone_4_name = d.county
                AND zone_3_name = d.state;
            END IF;
            COMMIT;
        end loop;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONES','Process deletes - end','GIS',NULL,NULL);


        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONES','Process updates - start','GIS',NULL,NULL);
        for u in zone_updates loop
            update tdr_etl_ct_zone_tree
            set code_2char = u.code_2char,
                code_3char = u.code_3char,
                code_fips = u.code_fips,
                reverse_flag = u.reverse_flag,
                terminator_flag = u.terminator_flag,
                default_flag = u.default_flag
            where zone_3_name = u.state
            and nvl(zone_4_name,'ZONE_4_NAME') = nvl(u.county,'ZONE_4_NAME')
            and nvl(zone_5_name,'ZONE_5_NAME') = nvl(u.city,'ZONE_5_NAME')
            and nvl(zone_6_name,'ZONE_6_NAME') = nvl(u.postcode,'ZONE_6_NAME')
            and nvl(zone_7_name,'ZONE_7_NAME') = nvl(u.plus4,'ZONE_7_NAME');
            COMMIT;
        end loop;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONES','Process updates - end','GIS',NULL,NULL);


        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONES','Process adds - start','GIS',NULL,NULL);
        for a in zone_adds loop
            INSERT INTO tdr_etl_ct_zone_tree (MERCHANT_ID,ZONE_1_ID,ZONE_1_NAME,ZONE_2_NAME,ZONE_3_NAME,ZONE_4_NAME,
                ZONE_5_NAME,ZONE_6_NAME,ZONE_7_NAME,TAX_PARENT_ZONE,CODE_2CHAR,CODE_3CHAR,CODE_FIPS,
                REVERSE_FLAG,TERMINATOR_FLAG,DEFAULT_FLAG,RANGE_MIN,RANGE_MAX)
            VALUES
                (l_merch_id,l_zone1_id,'WORLD','UNITED STATES',a.state,a.county,a.city,a.postcode,a.plus4,a.state,
                a.code_2char, a.code_3char, a.code_fips, a.reverse_flag, a.terminator_flag, a.default_flag,
                a.range_min, a.range_max);
            COMMIT;
        end loop;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONES','Process adds - end','GIS',NULL,NULL);

    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
            RAISE_APPLICATION_ERROR(-20001,'TB zones timeout.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002,'TB Zones error. See etl proc log.');
    END build_tb_zones;



    PROCEDURE build_tb_zone_authorities(make_changes_i IN NUMBER) IS  -- 03/24/17 - crapp-3363
        l_id  NUMBER;
        l_rec NUMBER := 0;
        vcurrent_schema varchar2(50);

        CURSOR detaches IS
            SELECT *
            FROM   tdr_etl_us_zone_authorities
            WHERE  change_type = 'Delete';

        CURSOR attaches IS
            SELECT zc.*
            FROM   tdr_etl_us_zone_authorities zc
            WHERE  change_type = 'Add';
    BEGIN
        -- CRAPP-3174, Dynamic extraction of schema name to reference tables where needed
        SELECT SYS_CONTEXT( 'userenv', 'current_schema' ) INTO vcurrent_schema FROM dual;

        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_ct_zone_authorities DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX tmp_ct_zone_auths_n1 UNUSABLE';  -- 07/07/16

        -- pull in the existing zone authorities for each zone in tdr_etl_ct_zone_authorities --
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONE_AUTHORITIES','Get existing CT Zone Authorities - start, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);

        INSERT INTO tdr_etl_ct_zone_authorities
            (merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_id, zone_2_name, zone_3_id, zone_3_name, zone_4_id, zone_4_name,
             zone_5_id, zone_5_name, zone_6_id, zone_6_name, zone_7_name, authority_name)   -- , creation_date - removed column 07/07/16
            (
            SELECT DISTINCT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_id, zone_2_name, zone_3_id, zone_3_name, zone_4_id, zone_4_name,
                   zone_5_id, zone_5_name, zone_6_id, zone_6_name, zone_7_name, authority_name   -- , creation_date - removed column 07/07/16
            FROM   ct_zone_authorities zt
            WHERE  zt.zone_3_name IS NOT NULL
                   AND EXISTS (
                                SELECT 1
                                FROM   tdr_etl_us_zone_authorities zc
                                WHERE  zc.state = zt.zone_3_name
                                       AND zc.state IS NOT NULL
                              )
            );
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX tmp_ct_zone_auths_n1 REBUILD';  -- 07/07/16
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'tdr_etl_ct_zone_authorities', cascade => TRUE);  -- CRAPP-3174
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONE_AUTHORITIES','Get existing CT Zone Authorities - end, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);


        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONE_AUTHORITIES','Process detaches - start, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);
        FOR d IN detaches LOOP
            DELETE FROM tdr_etl_ct_zone_authorities
            WHERE  zone_3_name = d.state
                   AND NVL(zone_4_name,'ZONE_4_NAME') = NVL(d.county,'ZONE_4_NAME')
                   AND NVL(zone_5_name,'ZONE_5_NAME') = NVL(d.city,'ZONE_5_NAME')
                   AND NVL(zone_6_name,'ZONE_6_NAME') = NVL(d.postcode,'ZONE_6_NAME')
                   AND NVL(zone_7_name,'ZONE_7_NAME') = NVL(d.plus4,'ZONE_7_NAME')
                   AND authority_name = d.authority;

            -- Added 07/07/16 --
            l_rec := l_rec + 1;
            IF l_rec = 25000 THEN
                etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONE_AUTHORITIES','  - Process detaches - commited '||l_rec||' records','GIS',NULL,NULL);
                COMMIT;
                l_rec := 0;
            END IF;

        END LOOP;
        COMMIT;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONE_AUTHORITIES','Process detaches - end, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);


        SELECT MAX(primary_key)
        INTO l_id
        FROM ct_zone_authorities;


        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONE_AUTHORITIES','Process attaches - start, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);
        EXECUTE IMMEDIATE 'ALTER INDEX tmp_ct_zone_auths_n1 UNUSABLE';  -- 07/07/16
        FOR a IN attaches LOOP

            IF (make_changes_i = 1) THEN
                -- Exclude any Invalid Authorities - crapp-2244 --
                INSERT INTO tdr_etl_ct_zone_authorities
                    (merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name)
                    (
                    SELECT merchant_id, NVL(primary_key, l_id+rownum) primary_key, zone_1_id, zone_1_name,
                           zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, a.authority
                    FROM (
                            SELECT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name,
                                   zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                            FROM   ct_zone_tree zt
                            WHERE  zt.zone_3_name = a.state
                                   AND zt.zone_3_name IS NOT NULL
                                   AND NVL(zt.zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                                   AND NVL(zt.zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                                   AND NVL(zt.zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                                   AND NVL(zt.zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                            UNION
                            SELECT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name,
                                   zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                            FROM   tdr_etl_ct_zone_tree zt
                            WHERE  zt.zone_3_name = a.state
                                   AND NVL(zt.zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                                   AND NVL(zt.zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                                   AND NVL(zt.zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                                   AND NVL(zt.zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                         )
                    WHERE a.authority NOT IN (SELECT DISTINCT gis_name FROM content_repo.gis_zone_juris_auths_tmp)  -- crapp-3363
                    );
            ELSE
                INSERT INTO tdr_etl_ct_zone_authorities
                    (merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name)
                    (
                    SELECT merchant_id, NVL(primary_key, l_id+rownum) primary_key, zone_1_id, zone_1_name,
                           zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, a.authority
                    FROM (
                            SELECT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name,
                                   zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                            FROM   ct_zone_tree zt
                            WHERE  zt.zone_3_name = a.state
                                   AND zt.zone_3_name IS NOT NULL
                                   AND NVL(zt.zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                                   AND NVL(zt.zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                                   AND NVL(zt.zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                                   AND NVL(zt.zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                            UNION
                            SELECT merchant_id, primary_key, zone_1_id, zone_1_name, zone_2_name,
                                   zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
                            FROM   tdr_etl_ct_zone_tree zt
                            WHERE  zt.zone_3_name = a.state
                                   AND NVL(zt.zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                                   AND NVL(zt.zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                                   AND NVL(zt.zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                                   AND NVL(zt.zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                         )
                    );
            END IF;

            SELECT MAX(primary_key)
            INTO l_id
            FROM tdr_etl_ct_zone_authorities;
        END LOOP;
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX tmp_ct_zone_auths_n1 REBUILD';  -- 07/07/16
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'tdr_etl_ct_zone_authorities', cascade => TRUE); -- CRAPP-3174

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_ZONE_AUTHORITIES','Process attaches - end, make_changes_i = '||make_changes_i,'GIS',NULL,NULL);

    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
            RAISE_APPLICATION_ERROR(-20001,'TB Zone authorities timeout.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002,'TB Zone Authority error.');
    END build_tb_zone_authorities;


    PROCEDURE build_tb_comp_areas IS  -- 03/24/17 - crapp-3363
        l_stcode   VARCHAR2(2 CHAR);
        l_fips     VARCHAR2(2 CHAR);
        l_userid   NUMBER := -204;
        l_merch_id NUMBER;

        CURSOR area_deletes is
            SELECT *
            FROM   tdr_etl_us_comp_area_changes
            WHERE  change_type = 'Delete';

        CURSOR area_updates is
            SELECT *
            FROM   tdr_etl_us_comp_area_changes
            WHERE  change_type = 'Update';

        CURSOR area_adds is
            SELECT *
            FROM   tdr_etl_us_comp_area_changes a
            WHERE  change_type = 'Add'
                   AND NOT EXISTS (SELECT 1
                                   FROM   tdr_etl_us_comp_area_changes u
                                   WHERE  u.change_type = 'Update'
                                          AND a.NAME = u.NAME
                                          AND a.area_uuid = u.area_uuid
                                  )
                   AND NOT EXISTS (SELECT 1
                                   FROM   tdr_etl_tb_compliance_areas ca
                                   WHERE  a.area_uuid = ca.compliance_area_uuid
                                          AND a.NAME  = ca.NAME
                                          AND a.start_date = ca.start_date
                                  )
            ORDER BY area_uuid, NAME, start_date;

    BEGIN
        --NULL;   -- 05/22/17

        SELECT DISTINCT state_code
        INTO   l_stcode
        FROM   content_repo.gis_tb_compliance_areas;    -- crapp-3363

        SELECT DISTINCT SUBSTR(area_id, 1, 2) fips
        INTO   l_fips
        FROM   content_repo.gis_tb_compliance_areas;    -- crapp-3363

        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_tb_compliance_areas DROP STORAGE';

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREAS','Get existing Compliance Areas - start, - '||l_stcode||'', 'GIS', NULL, NULL);

        -- pull in the existing Compliance Areas for each area in tdr_etl_us_comp_area_changes
        INSERT INTO tdr_etl_tb_compliance_areas
            (compliance_area_id, NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, merchant_id, start_date, end_date,
             created_by, creation_date)
            SELECT  compliance_area_id, NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, merchant_id, start_date, end_date,
                    created_by, creation_date
            FROM    tb_compliance_areas tca
            WHERE   SUBSTR(NAME, 1, 2) = l_fips;
        COMMIT;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREAS','Get existing Compliance Areas - end, - '||l_stcode||'', 'GIS', NULL, NULL);


        -- Deletes --

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREAS','Process Compliance Area deletes - start, - '||l_stcode||'', 'GIS', NULL, NULL);
        FOR d IN area_deletes LOOP
            DELETE FROM tdr_etl_tb_compliance_areas
            WHERE  NAME = d.NAME
                   AND compliance_area_uuid = d.area_uuid;
        END LOOP;
        COMMIT;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREAS','Process Compliance Area deletes - end, - '||l_stcode||'', 'GIS', NULL, NULL);


        -- Updates --

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREAS','Process Compliance Area updates - start, - '||l_stcode||'', 'GIS', NULL, NULL);
        FOR u IN area_updates LOOP
            UPDATE tdr_etl_tb_compliance_areas
                SET compliance_area_uuid    = u.area_uuid,
                    effective_zone_level_id = u.eff_zone_level_id,
                    associated_area_count   = u.area_count,
                    start_date              = u.start_date,
                    end_date                = u.end_date,
                    last_updated_by         = l_userid,
                    last_update_date        = SYSDATE
            WHERE   NAME = u.NAME;
        END LOOP;
        COMMIT;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREAS','Process Compliance Area updates - end, - '||l_stcode||'', 'GIS', NULL, NULL);


        -- Adds --

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREAS','Process Compliance Area adds - start, - '||l_stcode||'', 'GIS', NULL, NULL);
        SELECT merchant_id
        INTO   l_merch_id
        FROM   tb_merchants
        WHERE  name = 'Sabrix US Tax Data';

        FOR a IN area_adds LOOP
            INSERT INTO tdr_etl_tb_compliance_areas
                (compliance_area_id, NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, merchant_id, start_date
                 , end_date, created_by, creation_date)
            VALUES
                (a.id, a.NAME, a.area_uuid, a.eff_zone_level_id, a.area_count, l_merch_id, a.start_date, a.end_date, l_userid, SYSDATE);
        END LOOP;
        COMMIT;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREAS','Process Compliance Area adds - end, - '||l_stcode||'', 'GIS', NULL, NULL);

    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
            RAISE_APPLICATION_ERROR(-20001,'TB Comp areas timeout.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002,'TB Comp areas error - '||SQLERRM);
    END build_tb_comp_areas;


    PROCEDURE build_tb_comp_area_auths(make_changes_i IN NUMBER) IS -- 03/24/17 crapp-3363
        l_stcode  VARCHAR2(2 CHAR);
        l_fips    VARCHAR2(2 CHAR);  -- crapp-3055
        l_rec     NUMBER := 0;
        l_userid  NUMBER := -204;
        datax_177 EXCEPTION;         -- crapp-3055

        CURSOR auth_deletes IS
            SELECT *
            FROM   tdr_etl_us_comp_area_auth_chgs
            WHERE  change_type = 'Delete';

        CURSOR auth_adds IS -- NVL(a.compliance_area_id, tca.compliance_area_id) compliance_area_id -- crapp-3055, reversed columns
            SELECT DISTINCT aa.id, aa.area_uuid, aa.authority_name, ta.authority_id, NVL(tca.compliance_area_id, a.compliance_area_id) compliance_area_id
            FROM   tdr_etl_us_comp_area_auth_chgs aa
                   JOIN tb_authorities ta ON (aa.authority_name = ta.NAME)
                   LEFT JOIN tb_compliance_areas a ON (aa.area_uuid = a.compliance_area_uuid)
                   LEFT JOIN tdr_etl_tb_compliance_areas tca ON (aa.area_uuid = tca.compliance_area_uuid)
                   LEFT JOIN tdr_etl_tb_comp_area_auths tcaa ON (a.compliance_area_id = tcaa.compliance_area_id
                                                                   AND ta.authority_id = tcaa.authority_id)
            WHERE  change_type = 'Add'
                   AND tcaa.compliance_area_auth_id IS NULL
            ORDER BY compliance_area_id, authority_id;   -- crapp-2979, added DISTINCT and ORDER BY
    BEGIN
        --NULL;   -- 05/22/17

        SELECT DISTINCT state_code
        INTO   l_stcode
        FROM   content_repo.gis_tb_compliance_areas;    -- crapp-3363

        SELECT DISTINCT SUBSTR(area_id, 1, 2) fips
        INTO   l_fips
        FROM   content_repo.gis_tb_compliance_areas;    -- crapp-3363

        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_tb_comp_area_auths DROP STORAGE';

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREA_AUTHS','Get existing Compliance Area Athorities - start, - '||l_stcode||'', 'GIS', NULL, NULL);

        -- pull in the existing Compliance Area Authorities for each area in tdr_etl_us_comp_area_auth_chgs
        INSERT INTO tdr_etl_tb_comp_area_auths
            (compliance_area_auth_id, compliance_area_id, authority_id, created_by, creation_date, last_updated_by, last_update_date)
            SELECT  compliance_area_auth_id, compliance_area_id, authority_id, created_by, creation_date, last_updated_by, last_update_date
            FROM    tb_comp_area_authorities tca
            WHERE   compliance_area_id IN (SELECT compliance_area_id
                                           FROM   tb_compliance_areas
                                           WHERE  SUBSTR(NAME,1,2) = l_fips
                                          );
        COMMIT;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREA_AUTHS','Get existing Compliance Area Athorities - end, - '||l_stcode||'', 'GIS', NULL, NULL);


        -- Deletes --

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREA_AUTHS','Process Compliance Area Athority deletes - start, - '||l_stcode||'', 'GIS', NULL, NULL);
        FOR d IN auth_deletes LOOP
            DELETE FROM tdr_etl_tb_comp_area_auths
            WHERE  compliance_area_id = d.area_uuid
                   AND authority_id = d.authority_id;
        END LOOP;
        COMMIT;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREA_AUTHS','Process Compliance Area Athority deletes - end, - '||l_stcode||'', 'GIS', NULL, NULL);


        -- Adds --

        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREA_AUTHS','Process Compliance Area Athority adds - start, - '||l_stcode||'', 'GIS', NULL, NULL);
        FOR a IN auth_adds LOOP
            INSERT INTO tdr_etl_tb_comp_area_auths
                (compliance_area_auth_id, compliance_area_id, authority_id, created_by, creation_date, last_updated_by, last_update_date)
            VALUES
                (a.id, a.compliance_area_id, a.authority_id, l_userid, SYSDATE, l_userid, SYSDATE);  -- crapp-2979, replace compliance_area_id with area_uuid, crapp-3055 changed it back
        END LOOP;
        COMMIT;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREA_AUTHS','Process Compliance Area Athority adds - end, - '||l_stcode||'', 'GIS', NULL, NULL);


        -- Data Check for compliance areas which are not associated with any compliance authorities - Datax_TB_Compl_Areas_177 -- crapp-3055
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREA_AUTHS','Data Check for compliance areas which are not associated with any compliance authorities - start, - '||l_stcode||'', 'GIS', NULL, NULL);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_tb_comp_datax_177 DROP STORAGE';
        INSERT INTO tdr_etl_tb_comp_datax_177
            SELECT DISTINCT
                   l_stcode  state_code
                   , compliance_area_id
            FROM   tdr_etl_tb_compliance_areas tc1
            WHERE NOT EXISTS (SELECT 1
                              FROM  tdr_etl_tb_comp_area_auths tc2
                              WHERE tc1.compliance_area_id = tc2.compliance_area_id
                             );
        COMMIT;

        SELECT COUNT(*)
        INTO  l_rec
        FROM  tdr_etl_tb_comp_datax_177;

        IF l_rec != 0 THEN
            --gis_etl_p(pid=>l_pID, pstate=>l_stcode, ppart=>'  - Found '||l_rec||' compliance area(s) which are not associated with any compliance authorities - tdr_etl_tb_comp_datax_177', paction=>3, puser=>l_user);

            RAISE datax_177;
        END IF;
        etl_proc_log_p('DET_TRANSFORM.BUILD_TB_COMP_AREA_AUTHS','Data Check for compliance areas which are not associated with any compliance authorities - end, - '||l_stcode||'', 'GIS', NULL, NULL);

    -- crapp-3055 - added
    EXCEPTION
        WHEN datax_177 THEN
            --gis_etl_p(pid=>l_pID, pstate=>l_stcode, ppart=>' - build_tb_comp_area_auths - Failed datax_177 - ', paction=>3, puser=>l_user);
            content_repo.errlogger.report_and_stop(204,'GIS ETL found Compliance Areas which are not associated with any Compliance Authorities - tdr_etl_tb_comp_datax_177');
        WHEN TIMEOUT_ON_RESOURCE THEN
            RAISE_APPLICATION_ERROR(-20001,'TB Comp area auth timeout.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002,'TB Comp area auth error - '||SQLERRM);
    END build_tb_comp_area_auths;

END;
/