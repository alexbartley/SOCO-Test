CREATE OR REPLACE PACKAGE BODY content_repo.pull_etl
is

/*
**
     Date                  Jira                       Change
---------------------------------------------------------------------------------------------------------------
    10/28/2017          CRAPP-2808                  Check_taxability_rule_order, To see dependency for staging/publication process,
                                                    Making sure taxabaility trying to etl, has rule order associated to it all the times.

*/
    procedure refresh_mv(mv_name_i varchar2, refresh_type_i varchar2)
    is
        v_cnt number := 0;
    begin
            dbms_mview.refresh(mv_name_i, refresh_type_i);

    exception when others then
            v_cnt := v_cnt+1;
            if v_cnt > 1
            then
                raise_application_error(-20201, 'MV Refresh failed for '||mv_name_i);
            else
            dbms_mview.refresh(mv_name_i, 'C');
            end if;
    end;

    procedure clean_tmp_extract
    is
    begin
        execute immediate 'truncate table tdr_etl_extract_list';
    end;

    procedure refresh_qualifier_mappings(schema_name_i varchar2)
    is
        v_sql varchar2(32767);
    begin

        delete from TDR_ETL_MAP_JTA_RQ;

        v_sql := '
        INSERT INTO TDR_ETL_MAP_JTA_RQ
            WITH jta_1
                     AS (SELECT MAX (jta.rid) rid, jta.nkid
                           FROM juris_tax_applicabilities jta
                                JOIN mv_juris_tax_app_revisions jtr
                                    ON jta.nkid = jtr.nkid AND jta.rid <= jtr.id
                         GROUP BY jta.nkid),
                 ttq_1
                     AS (SELECT MAX (ttq.rid) rid, ttq.nkid
                           FROM tran_tax_qualifiers ttq
                                JOIN mv_juris_tax_app_revisions jtr
                                    ON     ttq.juris_tax_applicability_nkid = jtr.nkid
                                       AND ttq.rid <= jtr.id
                         GROUP BY ttq.nkid)
            SELECT DISTINCT
                   jurisdiction_nkid,
                   nkid,
                   LISTAGG (element_name || ''-'' || logical_qualifier || ''-'' || VALUE,
                            ''|'')
                   WITHIN GROUP (ORDER BY element_name, logical_qualifier, VALUE)
                       rqs,
                   start_date,
                   end_date
              FROM (SELECT DISTINCT
                           jta.jurisdiction_nkid,
                           jta.nkid,
                           te.element_name,
                           ttq.logical_qualifier, --  ttq.jurisdiction_nkid ttq_jurisdiction_nkid,
                           CASE
                               WHEN ttq.reference_group_nkid IS NOT NULL
                               THEN
                                   REPLACE (REPLACE (rg.name, '' (US Determination)''),
                                            '' (INTL Determination)'')
                               WHEN ttq.jurisdiction_nkid IS NOT NULL
                               THEN
                                   TRIM (ja.authority_uuid || '' '' || NVL (ttq.VALUE, ''''))
                               ELSE
                                   ttq.VALUE
                           END
                               VALUE,
                           ttq.start_date,
                           ttq.end_date
                      FROM content_repo.juris_tax_applicabilities jta
                           JOIN jta_1 ON jta_1.nkid = jta.nkid AND jta.rid = jta_1.rid
                           JOIN content_repo.tran_tax_qualifiers ttq
                               ON (ttq.juris_tax_applicability_nkid = jta.nkid)
                           JOIN ttq_1 ON ttq_1.nkid = ttq.nkid AND ttq_1.rid = ttq.rid
                           LEFT OUTER JOIN
                           (SELECT tr.name, mr.ref_group_nkid
                              FROM '||schema_name_i||'.mp_ref_lists mr
                                   JOIN '||schema_name_i||'.tb_reference_lists tr
                                       ON tr.reference_list_id = mr.reference_list_id) rg
                               ON rg.ref_group_nkid = ttq.reference_group_nkid -- and ttq.reference_group_id = rg.id
                           LEFT OUTER JOIN content_repo.jurisdictions j
                               ON (NVL (ttq.jurisdiction_nkid, -1) = j.nkid)
                           LEFT OUTER JOIN '||schema_name_i||'.mp_juris_auths ja ON (ja.nkid = j.nkid)
                           LEFT JOIN content_repo.taxability_elements te
                               ON (te.id = ttq.taxability_element_id))
            GROUP BY jurisdiction_nkid,
                     nkid,
                     start_date,
                     end_date
            order by nkid';

        tdr_etl_proc_log('PULL_ETL.REFRESH_QUALIFIER_MAPPINGS', 'REFRESH_QUALIFIER_MAPPINGS Query String:'||v_sql, 'REFRESH_QUALIFIER_MAPPINGS', null, null);
        execute immediate v_sql;

        commit;
    end;

    procedure pull_failed_records(entity_name_i varchar2, schema_name_i varchar2)
    is
    begin
        null;
    end;

    procedure refresh_comm4taxabilities(schema_name_i varchar2)
    is
    begin
            tdr_etl_proc_log('PULL_ETL.REFRESH_COMM4TAXABILITIES', 'Deleting old data from tdr_commodity_extract', 'REFRESH_COMM4TAXABILITIES', null, null);
            delete from tdr_commodity_extract;

            if upper(schema_name_i) like 'TMP%'
            then
                tdr_etl_proc_log('PULL_ETL.REFRESH_COMM4TAXABILITIES', 'Refreshing MV_PULL_COMM_STAGING', 'REFRESH_MV', null, null);
                refresh_mv('mv_pull_comm_staging', 'C');
                -- This table further used in materialized view to refresh the data.
               insert all into tdr_commodity_extract(nkid, id) select distinct nkid, max(id) from MV_PULL_COMM_STAGING group by nkid;
            else
                tdr_etl_proc_log('PULL_ETL.REFRESH_COMM4TAXABILITIES', 'Refreshing MV_PULL_COMM_PROD', 'REFRESH_MV', null, null);
                refresh_mv('mv_pull_comm_prod', 'C');
                insert all into tdr_commodity_extract(nkid, id) select distinct nkid, max(id) from MV_PULL_COMM_PROD group by nkid;
            end if;

         tdr_etl_proc_log('PULL_ETL.REFRESH_COMM4TAXABILITIES', 'Refreshing mv_commodity_revisions', 'MV_COMMODITY_REVISIONS', null, null);
         refresh_mv('mv_commodity_revisions', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_COMM4TAXABILITIES', 'Refreshing mv_commodities', 'MV_COMMODITIES', null, null);
         refresh_mv('mv_commodities', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_COMM4TAXABILITIES', 'Refreshing mvcommodities', 'MVCOMMODITIES', null, null);
         refresh_mv('mvcommodities', 'C');
         commit;
    end;

    procedure refresh_refgrps4taxabilities(schema_name_i varchar2)
    is
    begin
            tdr_etl_proc_log('PULL_ETL.REFRESH_REFGRPS4TAXABILITIES', 'Deleting old data from tdr_reference_group_extract', 'REFRESH_REFGRPS4TAXABILITIES', null, null);
            delete from tdr_reference_group_extract;

            if upper(schema_name_i) like 'TMP%'
            then
                tdr_etl_proc_log('PULL_ETL.REFRESH_REFGRPS4TAXABILITIES', 'Refreshing MV_PULL_REF_GRP_STAGING', 'MV_PULL_REF_GRP_STAGING', null, null);
                refresh_mv('MV_PULL_REF_GRP_STAGING', 'F');
               insert all into tdr_reference_group_extract(nkid, id) select distinct nkid, max(id) from mv_pull_ref_grp_staging group by nkid;
            else
                tdr_etl_proc_log('PULL_ETL.REFRESH_REFGRPS4TAXABILITIES', 'Refreshing MV_PUL_REF_GROUPS_PROD', 'MV_PUL_REF_GROUPS_PROD', null, null);
                refresh_mv('MV_PUL_REF_GROUPS_PROD', 'F');
                insert all into tdr_reference_group_extract(nkid, id) select distinct nkid, max(id) from mv_pull_ref_groups_prod group by nkid;
            end if;

            tdr_etl_proc_log('PULL_ETL.REFRESH_REFGRPS4TAXABILITIES', 'Refreshing MV_REF_GROUP_REVISIONS1', 'MV_REF_GROUP_REVISIONS1', null, null);
            refresh_mv('MV_REF_GROUP_REVISIONS1', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_REFGRPS4TAXABILITIES', 'Refreshing MV_REFERENCE_GROUPS1', 'MV_REFERENCE_GROUPS1', null, null);
            refresh_mv('MV_REFERENCE_GROUPS1', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_REFGRPS4TAXABILITIES', 'Refreshing MV_REFERENCE_ITEMS1', 'MV_REFERENCE_ITEMS1', null, null);
            refresh_mv('MV_REFERENCE_ITEMS1', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_REFGRPS4TAXABILITIES', 'Refreshing MVREFERENCE_GROUPS1', 'MVREFERENCE_GROUPS1', null, null);
            refresh_mv('MVREFERENCE_GROUPS1', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_REFGRPS4TAXABILITIES', 'Refreshing MVREFERENCE_ITEMS1', 'MVREFERENCE_ITEMS1', null, null);
            refresh_mv('MVREFERENCE_ITEMS1', 'C');

            commit;
    end;

    procedure remove_processed_data(schema_name_i varchar2, entity_name_i varchar2)
    is
        v_sql varchar2(4000);
    begin
        v_sql := 'delete from tdr_etl_extract_list a where exists ( select 1 from '||schema_name_i||'.extract_log b
                    where a.nkid = b.nkid and a.rid = b.rid and loaded is not null
                    and b.entity = '''||entity_name_i||''' )';

        tdr_etl_proc_log('PULL_ETL.REMOVE_PROCESSED_DATA', 'Calling remove_processed_data with schema_name:'||schema_name_i||', entiy:'||entity_name_i, entity_name_i, null, null);
        execute immediate v_sql;
    end;

    procedure pull_etl_data(tag_group_i varchar2, last_ext_date_i timestamp, entity_name_i varchar2, schema_name_i varchar2)
    is
        v_sql varchar2(10000);
        l_mv_name varchar2(100);
        l_ext_date timestamp(6);
        l_sub_query varchar2(2000);

    begin

        --clean_tmp_extract;

        l_ext_date:= last_ext_date_i;

        if schema_name_i in ( 'SBXTAX', 'TMPTAX' )
        then
            l_sub_query := l_sub_query||' where exists ( select 1 from tdr_etl_entity_status where etl_us is null and entity = '''||entity_name_i||''' and nkid = jt.nkid and rid = jt.id )';
        elsif schema_name_i in ( 'SBXTAX4', 'TMPTAX4' )
        then
            l_sub_query := l_sub_query||' where exists ( select 1 from tdr_etl_entity_status where etl_telco is null and entity = '''||entity_name_i||''' and nkid = jt.nkid and rid = jt.id )';
        elsif schema_name_i in ( 'SBXTAX2', 'TMPTAX2' )
        then
            l_sub_query := l_sub_query||' where exists ( select 1 from tdr_etl_entity_status where etl_intl is null and entity = '''||entity_name_i||''' and nkid = jt.nkid and rid = jt.id )';
        end if;

        tdr_etl_proc_log('PULL_ETL.PULL_ETL_DATA', 'Calling pull_etl_data with schema_name:'||schema_name_i||', entiy:'||entity_name_i, entity_name_i, null, null);

        l_mv_name :=
        CASE WHEN upper(schema_name_i) like 'TMP%' THEN
                            case when entity_name_i = 'TAXABILITY' THEN 'MV_PULL_TAXABILITIES_STG'
                                 when entity_name_i = 'REFERENCE GROUP' THEN 'MV_PULL_REF_GRP_STAGING'
                                 when entity_name_i = 'JURISDICTION' THEN 'MV_PULL_JURIS_STAGING'
                                 when entity_name_i = 'COMMODITY' THEN 'MV_PULL_COMM_STAGING'
                                 when entity_name_i = 'TAX' THEN 'MV_PULL_TAXES_STAGING'
                                 when entity_name_i = 'ADMINISTRATOR' THEN 'MV_PULL_ADMIN_STAGING'
                            END
        ELSE
                            case when entity_name_i = 'TAXABILITY' THEN 'MV_PULL_TAXABILITIES_PROD'
                                 when entity_name_i = 'JURISDICTION' THEN 'MV_PULL_JURIS_PROD'
                                 when entity_name_i = 'REFERENCE GROUP' THEN 'MV_PULL_REF_GROUPS_PROD'
                                 when entity_name_i = 'COMMODITY' THEN 'MV_PULL_COMM_PROD'
                                 when entity_name_i = 'TAX' THEN 'MV_PULL_TAXES_PROD'
                                 when entity_name_i = 'ADMINISTRATOR' THEN 'MV_PULL_ADMIN_PROD'
                            END
        END;

        if entity_name_i = 'COMMODITY'
        then
            l_ext_date := '01-Jan-2014 12:00:00.743775 AM';
            refresh_comm4taxabilities(upper(schema_name_i));
        /*
             l_ext_date := '01-Jan-2014 12:00:00.743775 AM';

            delete from tdr_commodity_extract;

            if upper(schema_name_i) like 'TMP%'
            then
                -- This table further used in materialized view to refresh the data.
               insert all into tdr_commodity_extract(nkid, id) select distinct nkid, max(id) from MV_PULL_COMM_STAGING group by nkid;
            else
                insert all into tdr_commodity_extract(nkid, id) select distinct nkid, max(id) from MV_PULL_COMM_PROD group by nkid;
            end if;
        */
        end if;

        if entity_name_i = 'REFERENCE GROUP'
        then
            l_ext_date := '01-Jan-2014 12:00:00.743775 AM';
            refresh_refgrps4taxabilities(upper(schema_name_i));
        end if;

        dbms_output.put_line('l_mv_name value is '||l_mv_name);
        v_sql := '
            INSERT ALL INTO content_repo.tdr_etl_extract_list (queue_id, extraction_id, entity, rid, nkid, tag_list)
            SELECT DISTINCT -1 queue_id, -1 extraction_id, '''||entity_name_i||''', JURIS.ID, juris.nkid, juris.tag_list
              FROM (SELECT a.id,
                           a.nkid,
                           LISTAGG (t.name, '','') WITHIN GROUP (ORDER BY t.name) tag_list
                      FROM (SELECT nkid, MAX (id) id, tag_id
                              FROM (SELECT jt.nkid, jt.id id, jt.tag_id
                                      FROM content_repo.'||l_mv_name||' jt
                                        '||l_sub_query||'
                                    )
                            GROUP BY nkid, tag_id) a
                           JOIN content_repo.tags t ON t.id = a.tag_id
                    GROUP BY a.id, a.nkid) juris
                   JOIN tag_group_tags b ON juris.tag_list = b.tag_list
             WHERE b.tag_group_name =  '''||tag_group_i||'''
             and not exists ( select 1 from content_repo.tdr_etl_extract_list b where b.nkid = juris.nkid and b.entity = '''||entity_name_i||'''
             and b.rid >= juris.id)'
             ;

        tdr_etl_proc_log('PULL_ETL.PULL_ETL_DATA', 'PULL_ETL_DATA Query String:'||v_sql, 'PULL_ETL_DATA', null, null);

        EXECUTE IMMEDIATE v_sql;

    end;

    procedure check_juris_admin(schema_name_i varchar2)
    is
        v_sql varchar2(4000);
    begin
        null;
    end;

    procedure check_taxes_jurisdiction(schema_name_i varchar2)
    is
        v_sql varchar2(2000);
    begin
        dbms_output.put_line('Checking whether the jurisdiction is already published dor not.');
        dbms_output.put_line('Start Check 1'||systimestamp);

        v_sql := 'insert into '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL(nkid, rid, entity, tag_list, message)
                  select distinct nkid, rid, ''Tax'', tag_list, ''Tax skipped due to Un-ETLed jurisdiction''
                    from tdr_etl_extract_list
                   where nkid not in (
                        select distinct tel.nkid from jurisdictions j join juris_tax_impositions jti on j.nkid = jti.jurisdiction_nkid
                          join tdr_etl_extract_list tel on tel.nkid = jti.nkid and tel.entity = ''TAX''
                          join '||schema_name_i||'.mp_juris_auths mp on mp.nkid = j.nkid
                          join '||schema_name_i||'.tb_authorities ta on mp.authority_uuid = ta.uuid
                          )
                   and entity = ''TAX''';
        tdr_etl_proc_log('PULL_ETL.CHECK_TAXES_JURISDICTION', 'CHECK_TAXES_JURISDICTION Query String1:'||v_sql, 'check_taxes_jurisdiction', null, null);
        execute immediate v_sql;

        dbms_output.put_line('End Check 1 '||systimestamp);

        v_sql := 'delete from content_repo.tdr_etl_extract_list where (upper(entity), nkid ) in (
                    select upper(entity), nkid from '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL where entity = ''TAX'')';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXES_JURISDICTION', 'CHECK_TAXES_JURISDICTION Query String2:'||v_sql, 'check_taxes_jurisdiction', null, null);
        execute immediate v_sql;

    end;

    procedure clear_unpublished_data(schema_name_i varchar2)
    is
        v_sql varchar2(2000);
    begin
        v_sql := 'delete from content_repo.tdr_etl_extract_list where (upper(entity), nkid ) in (
                    select upper(entity), nkid from '||schema_name_i||'.juris_tax_app_skip_etl)';
        tdr_etl_proc_log('PULL_ETL.CLEAR_UNPUBLISHED_DATA', 'CLEAR_UNPUBLISHED_DATA Query String:'||v_sql, 'CLEAR_UNPUBLISHED_DATA', null, null);
        execute immediate v_sql;
    end;

    procedure load_skipped_etl_records(schema_name_i varchar2)
    is
        v_sql varchar2(2000);
    begin
        dbms_output.put_line('Load previously skipped etl records started ');
        v_sql := 'insert into content_repo.tdr_etl_extract_list (entity, rid, nkid, tag_list, extraction_id, queue_id)
                    select distinct entity, rid, nkid, tag_list, -1, -1 from '||schema_name_i||'.juris_tax_app_skip_etl a
                    where not exists ( select 1 from tdr_etl_extract_list b where a.nkid = b.nkid and a.rid >= b.rid and a.entity = b.entity)';

        tdr_etl_proc_log('PULL_ETL.LOAD_SKIPPED_ETL_RECORDS', 'LOAD_SKIPPED_ETL_RECORDS Query String1:'||v_sql, 'LOAD_SKIPPED_ETL_RECORDS', null, null);

        execute immediate v_sql;
        v_sql := 'delete from '||schema_name_i||'.juris_tax_app_skip_etl a where ( nkid, rid, entity )
                  in
                  (select nkid, rid, entity from tdr_etl_extract_list)
                    ';

        tdr_etl_proc_log('PULL_ETL.LOAD_SKIPPED_ETL_RECORDS', 'LOAD_SKIPPED_ETL_RECORDS Query String2:'||v_sql, 'LOAD_SKIPPED_ETL_RECORDS', null, null);
        execute immediate v_sql;
    end;


    procedure check_taxability_juris(schema_name_i varchar2)
    is
        vcnt number;
        v_sql varchar2(4000);
    begin
        dbms_output.put_line('Checking whether the jurisdiction is already published dor not.');

        v_sql := 'insert into '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL(nkid, rid, entity, tag_list, message)
                  select distinct nkid, rid, ''Taxability'', tag_list, ''jurisdiction not published''
                    from tdr_etl_extract_list
                   where nkid not in (
                        select distinct tel.nkid from jurisdictions j join juris_tax_applicabilities jta on j.nkid = jta.jurisdiction_nkid
                          join tdr_etl_extract_list tel on tel.nkid = jta.nkid and tel.entity = ''TAXABILITY''
                          join '||schema_name_i||'.mp_juris_auths mp on mp.nkid = j.nkid
                          join '||schema_name_i||'.tb_authorities ta on mp.authority_uuid = ta.uuid
                          )
                   and entity = ''TAXABILITY''';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_JURIS', 'CHECK_TAXABILITY_JURIS Query String1:'||v_sql, 'CHECK_TAXABILITY_JURIS', null, null);

        execute immediate v_sql;

        v_sql := 'delete from content_repo.tdr_etl_extract_list where (upper(entity), nkid ) in (
                    select upper(entity), nkid from '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL where entity = ''TAXABILITY'')';


                    execute immediate v_sql;
        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_JURIS', 'CHECK_TAXABILITY_JURIS Query String2:'||v_sql, 'CHECK_TAXABILITY_JURIS', null, null);

    end;

    procedure check_taxability_taxes(schema_name_i varchar2)
    is
        vcnt number;
        v_sql varchar2(4000);
    begin
            dbms_output.put_line('Checking if taxes associated with taxabilities are published or not');

        -- Changes for CRAPP-3849
        v_sql := 'insert into '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL(nkid, rid, entity, tag_list, message)
                  select distinct nkid, rid, ''TAXABILITY'', tag_list, ''taxes not etled yet''
                    from tdr_etl_extract_list tl
                   where nkid not in (
                        select distinct tel.nkid from jurisdictions j join juris_tax_applicabilities jta on j.nkid = jta.jurisdiction_nkid
                          join tdr_etl_extract_list tel on tel.nkid = jta.nkid and tel.entity = ''TAXABILITY''
                          join '||schema_name_i||'.mp_juris_auths mp on mp.nkid = j.nkid
                          join '||schema_name_i||'.tb_authorities ta on mp.authority_uuid = ta.uuid
                          join tax_applicability_taxes tat on tat.juris_tax_applicability_nkid = jta.nkid
                          join juris_tax_impositions jti on tat.juris_tax_imposition_nkid = jti.nkid
                          join '||schema_name_i||'.tb_rates tr on tr.authority_id = ta.authority_id
                             and case when nvl(tr.is_local, ''N'') = ''Y'' then tr.rate_code||'' (Local)''
                                    else tr.rate_code  end = jti.reference_code
                          )
                   and entity = ''TAXABILITY''
                   and exists ( select 1 from juris_tax_applicabilities b where b.nkid = tl.nkid and b.applicability_type_id = 1)';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_TAXES', 'CHECK_TAXABILITY_TAXES Query String1:'||v_sql, 'CHECK_TAXABILITY_TAXES', null, null);

        execute immediate v_sql;

        v_sql := 'delete from content_repo.tdr_etl_extract_list where (upper(entity), nkid ) in (
                    select upper(entity), nkid from '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL where upper(entity) = ''TAXABILITY'')';

       tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_TAXES', 'CHECK_TAXABILITY_TAXES Query String2:'||v_sql, 'CHECK_TAXABILITY_TAXES', null, null);

        execute immediate v_sql;

    end;

    procedure check_taxability_comms(schema_name_i varchar2)
    is
        vcnt number;
        v_sql varchar2(4000);
    begin
        dbms_output.put_line('Checking if commodities associated with taxabilities are published or not');

        v_sql := 'insert into '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL(nkid, rid, entity, tag_list, message)
                  select distinct nkid, rid, ''Taxability'', tag_list, ''commodities not etled yet''
                    from tdr_etl_extract_list
                   where nkid not in (
                        select distinct tel.nkid from jurisdictions j join juris_tax_applicabilities jta on j.nkid = jta.jurisdiction_nkid
                          join tdr_etl_extract_list tel on tel.nkid = jta.nkid and tel.entity = ''TAXABILITY''
                          join '||schema_name_i||'.tb_authorities ta on ta.name = j.official_name
                          join commodities com on com.nkid = jta.commodity_nkid
                          join '||schema_name_i||'.tb_product_categories tpc on tpc.name = com.name and tpc.prodcode = com.commodity_code
                          )
                   and entity = ''TAXABILITY''';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_COMMS', 'CHECK_TAXABILITY_COMMS Query String1:'||v_sql, 'CHECK_TAXABILITY_COMMS', null, null);

        execute immediate v_sql;

        v_sql := 'delete from content_repo.tdr_etl_extract_list where (upper(entity), nkid ) in (
                    select upper(entity), nkid from '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL where entity = ''TAXABILITY'')';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_COMMS', 'CHECK_TAXABILITY_COMMS Query String2:'||v_sql, 'CHECK_TAXABILITY_COMMS', null, null);

        execute immediate v_sql;

    end;

    procedure check_taxability_ref_groups(schema_name_i varchar2)
    is
        vcnt number;
        v_sql varchar2(4000);
    begin

        v_sql := 'insert into '||schema_name_i||'.juris_tax_app_skip_etl(nkid, rid, entity, tag_list, message)
                  select distinct nkid, rid, ''Taxability'', tag_list, ''commodities not etled yet''
                    from tdr_etl_extract_list
                   where nkid not in (
                        select distinct tel.nkid from jurisdictions j join juris_tax_applicabilities jta on j.nkid = jta.jurisdiction_nkid
                          join tran_tax_qualifiers ttq on ttq.juris_tax_applicability_nkid = jta.nkid
                          join tdr_etl_extract_list tel on tel.nkid = jta.nkid and tel.entity = ''TAXABILITY''
                          join '||schema_name_i||'.mp_ref_lists ta on ta.ref_group_nkid = ttq.reference_group_nkid
                          )
                   and entity = ''TAXABILITY''';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_REF_GROUPS', 'CHECK_TAXABILITY_REF_GROUPS Query String1:'||v_sql, 'CHECK_TAXABILITY_REF_GROUPS', null, null);

        execute immediate v_sql;

        v_sql := 'delete from content_repo.tdr_etl_extract_list where (upper(entity), nkid ) in (
                    select upper(entity), nkid from '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL where entity = ''TAXABILITY'')';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_REF_GROUPS', 'CHECK_TAXABILITY_REF_GROUPS Query String2:'||v_sql, 'CHECK_TAXABILITY_REF_GROUPS', null, null);
        execute immediate v_sql;

    end;

    procedure check_taxability_ref_authority(schema_name_i varchar2)
    is
        vcnt number;
        v_sql varchar2(4000);
    begin

        v_sql := 'insert into '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL(nkid, rid, entity, tag_list, message)
                  select distinct nkid, rid, ''Taxability'', tag_list, ''commodities not etled yet''
                    from tdr_etl_extract_list
                   where nkid not in (
                        select distinct tel.nkid from jurisdictions j join juris_tax_applicabilities jta on j.nkid = jta.jurisdiction_nkid
                          join tran_tax_qualifiers ttq on ttq.juris_tax_applicability_nkid = jta.nkid
                          join tdr_etl_extract_list tel on tel.nkid = jta.nkid and tel.entity = ''TAXABILITY''
                          join '||schema_name_i||'.mp_juris_auths ta on ta.nkid = ttq.jurisdiction_nkid
                          )
                   and entity = ''TAXABILITY''';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_REF_AUTHORITY', 'CHECK_TAXABILITY_REF_AUTHORITY Query String1:'||v_sql, 'CHECK_TAXABILITY_REF_AUTHORITY', null, null);
        execute immediate v_sql;

        v_sql := 'delete from content_repo.tdr_etl_extract_list where (upper(entity), nkid ) in (
                    select upper(entity), nkid from '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL where entity = ''TAXABILITY'')';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_REF_AUTHORITY', 'CHECK_TAXABILITY_REF_AUTHORITY Query String2:'||v_sql, 'CHECK_TAXABILITY_REF_AUTHORITY', null, null);
        execute immediate v_sql;
        dbms_output.put_line('End Check 2 '||systimestamp);
    end;

    procedure check_taxability_ruleorder(schema_name_i varchar2)
    is
        vcnt number;
        v_sql varchar2(4000);
    begin

        v_sql := 'insert into '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL(nkid, rid, entity, tag_list, message)
                  select distinct nkid, rid, ''Taxability'', tag_list, ''Rule Order is missing''
                    from tdr_etl_extract_list
                   where nkid in (
                        select distinct tel.nkid from jurisdictions j join juris_tax_applicabilities jta on j.nkid = jta.jurisdiction_nkid
                          join tdr_etl_extract_list tel on tel.nkid = jta.nkid and tel.entity = ''TAXABILITY''
						  left join tax_applicability_taxes ttq on ttq.juris_tax_applicability_nkid = jta.nkid and ttq.rid <= tel.rid
                          where nvl(ttq.ref_rule_order, jta.ref_rule_order) is null
                            and jta.nkid = tel.nkid and jta.rid <= tel.rid
                          )
                   and entity = ''TAXABILITY''';

        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_RULEORDER', 'CHECK_TAXABILITY_RULEORDER Query String1:'||v_sql, 'CHECK_TAXABILITY_RULEORDER', null, null);
        dbms_output.put_line('v_sql value is '||v_sql);
        execute immediate v_sql;

        v_sql := 'delete from content_repo.tdr_etl_extract_list where (upper(entity), nkid ) in (
                    select upper(entity), nkid from '||schema_name_i||'.JURIS_TAX_APP_SKIP_ETL where upper(entity) = ''TAXABILITY'')';
        dbms_output.put_line('v_sql value is '||v_sql);
        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_RULEORDER', 'CHECK_TAXABILITY_RULEORDER Query String2:'||v_sql, 'CHECK_TAXABILITY_RULEORDER', null, null);
        execute immediate v_sql;
        dbms_output.put_line('End Check 2 '||systimestamp);
    end;

    PROCEDURE queue_date(tag_group_i varchar2, schema_name_i varcHAr2, entity_name_i varchar2)
    IS
        v_sql varchar2(4000);
    BEGIN

        v_sql := 'insert into '||schema_name_i||'.extract_log(tag_group, nkid, rid, entity )
                    select distinct '''||tag_group_i||''', nkid, rid, '''||entity_name_i||''' from tdr_etl_extract_list a where entity = '''||entity_name_i||'''
                    and not exists ( select 1 from '||schema_name_i||'.extract_log b where a.nkid = b.nkid and b.rid >= a.rid and b.entity = '''||entity_name_i||''')
                    --and not exists ( select 1 from content_repo.tdr_etl_extract_list c where a.nkid = c.nkid and c.rid >= a.rid and c.entity = '''||entity_name_i||''')
                    ';

         tdr_etl_proc_log('PULL_ETL.QUEUE_DATA', 'QUEUE_DATA Query String:'||v_sql, 'QUEUE_DATA', null, null);
         execute immediate v_sql;

    END;

    function get_last_extract_date (tag_group_i varchar2, entity_i varchar2 default 'ALL', schema_name_i varchar2)
    return timestamp
    is
        l_last_ext_date timestamp(6);
        l_tag_instance varchar2(50);
    begin

         tdr_etl_proc_log('PULL_ETL.GET_LAST_EXTRACT_DATE', 'GET_LAST_EXTRACT_DATE paramters are, tag_group_i:'||tag_group_i||', entity_i:'||entity_i||', schema:'||schema_name_i, 'GET_LAST_EXTRACT_DATE', null, null);

        if schema_name_i = 'TMPTAX' then l_tag_instance := 'STAGING:Determination US';
        elsif schema_name_i = 'TMPTAX4' then l_tag_instance := 'STAGING:Determination INDUSTRY(TELCO/HOT)';
        elsif schema_name_i = 'SBXTAX' then l_tag_instance := 'PROD:Determination US';
        elsif schema_name_i = 'SBXTAX4' then l_tag_instance := 'PROD:Determination INDUSTRY(TELCO/HOT)';
        end if;

        SELECT COALESCE(MAX(start_time),CAST('31-Mar-2017 12:00:00 AM' AS TIMESTAMP(6)))
        INTO l_last_ext_date
        FROM tdr_etl_log
        WHERE tag_group = tag_group_i
          AND upper(entity_name) = upper(entity_i)
          AND status  = 1
          AND tag_instance = l_tag_instance
          and instance_name = 'Prod';

        tdr_etl_proc_log('PULL_ETL.GET_LAST_EXTRACT_DATE', 'GET_LAST_EXTRACT_DATE value is '||NVL(l_last_ext_date, '01-Mar-2017'), 'GET_LAST_EXTRACT_DATE', null, null);
        return NVL(l_last_ext_date, '01-Mar-2017');
    end;

    procedure pull_authorities(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2)
    is
        l_last_ext timestamp(6);
        v_sql varchar2(2000);
        l_stag_or_prod varchar2(10);
    begin

       if schema_name_i like 'TMP%'
      then
            l_stag_or_prod := 'Staging';
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_JURIS_STAGING', 'AUTHORITIES', null, null);
            refresh_mv('MV_PULL_JURIS_STAGING', 'F');
      else
            l_stag_or_prod := 'Prod';
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_JURIS_PROD', 'AUTHORITIES', null, null);
            refresh_mv('MV_PULL_JURIS_PROD', 'F');
      end if;

        tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Calling get last extract date', 'AUTHORITIES', null, null);
        l_last_ext := get_last_extract_date(tag_group_i, 'JURISDICTION', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Last extract date is '||l_last_ext, 'AUTHORITIES', null, null);

        tdr_etl_proc_log('PULL_ETL.PULL_AUTHORITIES', 'Calling pull_etl_data for authorities.', 'AUTHORITIES', null, null);
        pull_etl_data(tag_group_i, l_last_ext, 'JURISDICTION', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_AUTHORITIES', 'Calling remove processed data.', 'AUTHORITIES', null, null);
        remove_processed_data(schema_name_i, 'JURISDICTION');
        tdr_etl_proc_log('PULL_ETL.PULL_AUTHORITIES', 'Calling queue data.', 'AUTHORITIES', null, null);
        queue_date(tag_group_i, schema_name_i, 'JURISDICTION');

        tdr_etl_proc_log('PULL_ETL.PULL_AUTHORITIES', 'Calling check jurisdiction administrator', 'AUTHORITIES', null, null);
        -- Check administrator for jurisdiction
        check_juris_admin(schema_name_i);

            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mvjurisdictions', 'AUTHORITIES', null, null);
            refresh_mv('mvjurisdictions', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mv_juris_tax_imps_juris', 'AUTHORITIES', null, null);
            refresh_mv('mv_juris_tax_imps_juris', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mvtax_juris_attributes', 'AUTHORITIES', null, null);
            refresh_mv('mvtax_juris_attributes', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mv_tax_adminstrator_juris', 'AUTHORITIES', null, null);
            refresh_mv('mv_tax_adminstrator_juris', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mvjurisdiction_attributes', 'AUTHORITIES', null, null);
            refresh_mv('mvjurisdiction_attributes', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mv_tax_relationships', 'AUTHORITIES', null, null);
            refresh_mv('mv_tax_relationships', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mv_tax_relationship_juris', 'AUTHORITIES', null, null);
            refresh_mv('mv_tax_relationship_juris', 'C');
            tdr_etl_proc_log('PULL_ETL.PULL_AUTHORITIES', 'Truncating etl_juris_tax_administrators', 'AUTHORITIES', null, null);
            execute immediate 'truncate table etl_juris_tax_administrators';

            if schema_name_i like 'TMP%'
            then
                tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mvtax_administrators_stg', 'AUTHORITIES', null, null);
                refresh_mv('mvtax_administrators_stg', 'C');
                insert into etl_juris_tax_administrators select * from mvtax_administrators_stg;
            else
                tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mvtax_administrators_prod', 'AUTHORITIES', null, null);
                refresh_mv('mvtax_administrators_prod', 'C');
                insert into etl_juris_tax_administrators select * from mvtax_administrators_prod;
            end if;
    end;

    procedure pull_taxes(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2)
    is
        l_last_ext timestamp(6);
        v_sql varchar2(4000);
        l_stag_or_prod varchar2(10);
    begin

          if schema_name_i like 'TMP%'
          then
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_TAXES_STAGING', 'TAXES', null, null);
            l_stag_or_prod := 'Staging';
             refresh_mv('MV_PULL_TAXES_STAGING', 'F');
          else
            l_stag_or_prod := 'Prod';
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_TAXES_PROD', 'TAXES', null, null);
            refresh_mv('MV_PULL_TAXES_PROD', 'F');
          end if;

        tdr_etl_proc_log('PULL_ETL.PULL_TAXES', 'Calling get last extract process', 'TAXES', null, null);
        l_last_ext := get_last_extract_date(tag_group_i, 'TAX', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_TAXES', 'Last extract date value is '||l_last_ext, 'TAXES', null, null);

        tdr_etl_proc_log('PULL_ETL.PULL_TAXES', 'Calling pull_etl_data for taxes', 'TAXES', null, null);
        pull_etl_data(tag_group_i, l_last_ext, 'TAX', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_TAXES', 'Calling remove processed data for taxes', 'TAXES', null, null);
        remove_processed_data(schema_name_i, 'TAX');
        tdr_etl_proc_log('PULL_ETL.PULL_TAXES', 'Load skipped etl records of taxes', 'TAXES', null, null);
        load_skipped_etl_records(schema_name_i);

        -- Dependency check for jurisdictions,
        tdr_etl_proc_log('PULL_ETL.PULL_TAXES', 'Calling check jurisdiction for taxes', 'TAXES', null, null);
        check_taxes_jurisdiction(schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_TAXES', 'Clean up unpublished data for taxes.', 'TAXES', null, null);
        clear_unpublished_data(schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_TAXES', 'Calling queue data.', 'TAXES', null, null);
        queue_date(tag_group_i, schema_name_i, 'TAX');
        dbms_output.put_line('Queue Data '||systimestamp);

         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_JURIS_TAX_IMPOSITIONS', 'TAXES', null, null);
         refresh_mv('MV_JURIS_TAX_IMPOSITIONS', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_TAX_OUTLINES', 'TAXES', null, null);
         refresh_mv('MV_TAX_OUTLINES', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_TAX_DEFINITIONS', 'TAXES', null, null);
         refresh_mv('MV_TAX_DEFINITIONS', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MVJURIS_TAX_IMPOSITIONS', 'TAXES', null, null);
         refresh_mv('MVJURIS_TAX_IMPOSITIONS', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MVTAX_OUTLINES', 'TAXES', null, null);
         refresh_mv('MVTAX_OUTLINES', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MVTAX_DEFINITIONS2', 'TAXES', null, null);
         refresh_mv('MVTAX_DEFINITIONS2', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_TAX_REF_RATE_CODE', 'TAXES', null, null);
         -- CHANGES FOR CRAPP-3850
         refresh_mv('MV_TAX_REF_RATE_CODE', 'C');

    end;

    procedure pull_reference_groups(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2)
    is
        l_last_ext timestamp(6);
        v_sql varchar2(4000);
        l_stag_or_prod varchar2(10);
    begin
        dbms_output.put_line('Refreshing Taxes Pull MV '||systimestamp);
          if schema_name_i like 'TMP%'
          then
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_REF_GRP_STAGING', 'REFERENCE GROUP', null, null);
            l_stag_or_prod := 'Staging';
             refresh_mv('MV_PULL_REF_GRP_STAGING', 'F');
          else
            l_stag_or_prod := 'Prod';
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_REF_GROUPS_PROD', 'REFERENCE GROUP', null, null);
            refresh_mv('MV_PULL_REF_GROUPS_PROD', 'F');
          end if;

        tdr_etl_proc_log('PULL_ETL.PULL_REFERENCE_GROUPS', 'Calling get last extract date procedure', 'REFERENCE GROUP', null, null);
        l_last_ext := get_last_extract_date(tag_group_i, 'REFERENCE GROUP', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_REFERENCE_GROUPS', 'Last extract date value is '||l_last_ext, 'REFERENCE GROUP', null, null);
        tdr_etl_proc_log('PULL_ETL.PULL_REFERENCE_GROUPS', 'Calling pull_etl_data.', 'REFERENCE GROUP', null, null);
        pull_etl_data(tag_group_i, l_last_ext, 'REFERENCE GROUP', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_REFERENCE_GROUPS', 'Calling remove already processed data.', 'REFERENCE GROUP', null, null);
        remove_processed_data(schema_name_i, 'REFERENCE GROUP');
        tdr_etl_proc_log('PULL_ETL.PULL_REFERENCE_GROUPS', 'Calling queue data.', 'REFERENCE GROUP', null, null);
        queue_date(tag_group_i, schema_name_i, 'REFERENCE GROUP');

         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_REF_GROUP_REVISIONS1', 'REFERENCE GROUP', null, null);
         refresh_mv('MV_REF_GROUP_REVISIONS1', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_REFERENCE_GROUPS1', 'REFERENCE GROUP', null, null);
         refresh_mv('MV_REFERENCE_GROUPS1', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_REFERENCE_ITEMS1', 'REFERENCE GROUP', null, null);
         refresh_mv('MV_REFERENCE_ITEMS1', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MVREFERENCE_GROUPS1', 'REFERENCE GROUP', null, null);
         refresh_mv('MVREFERENCE_GROUPS1', 'C');
         tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MVREFERENCE_ITEMS1', 'REFERENCE GROUP', null, null);
         refresh_mv('MVREFERENCE_ITEMS1', 'C');

    end;

    procedure pull_commodities(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2)
    is
        v_sql varchar2(5000);
        l_last_ext timestamp(6);
        l_stag_or_prod varchar2(10);
    begin

        -- Commodities does not have any dependency, hence we can run these whenever we needed.
        if upper(schema_name_i) like 'TMP%'
        then
            tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Refreshing mv_pull_comm_staging', 'COMMODITY', null, null);
            l_stag_or_prod := 'Staging';
            refresh_mv('mv_pull_comm_staging', 'C');
        else
            tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Refreshing mv_pull_comm_prod', 'COMMODITY', null, null);
            l_stag_or_prod := 'Prod';
            refresh_mv('mv_pull_comm_prod', 'C');
        end if;

        tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Calling get last extract date', 'COMMODITY', null, null);
        l_last_ext := get_last_extract_date(tag_group_i, 'COMMODITY', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Calling get last extract date', 'COMMODITY', null, null);

        --pull_failed_records(schema_name_i

        tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Calling pull_etl_data process', 'COMMODITY', null, null);
        pull_etl_data(tag_group_i, l_last_ext, 'COMMODITY', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Calling remove_processed_data', 'COMMODITY', null, null);
        remove_processed_data(schema_name_i, 'COMMODITY');
        tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Calling Queue data', 'COMMODITY', null, null);
        queue_date(tag_group_i, schema_name_i, 'COMMODITY');

         tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Refreshing mv_commodity_revisions', 'COMMODITY', null, null);
         refresh_mv('mv_commodity_revisions', 'C');
         tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Refreshing mv_commodities', 'COMMODITY', null, null);
         refresh_mv('mv_commodities', 'C');
         tdr_etl_proc_log('PULL_ETL.PULL_COMMODITIES', 'Refreshing mvcommodities', 'COMMODITY', null, null);
         refresh_mv('mvcommodities', 'C');
    end;

    procedure check_taxability_dependency(schema_name_i varchar2)
    is
    begin
        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_DEPENDENCY', 'Calling check_taxability_juris with schema:'||schema_name_i, 'TAXABILITY', null, null);
        check_taxability_juris(schema_name_i);
        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_DEPENDENCY', 'Calling check_taxability_taxes with schema:'||schema_name_i, 'TAXABILITY', null, null);
        check_taxability_taxes(schema_name_i);
        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_DEPENDENCY', 'Calling check_taxability_comms with schema:'||schema_name_i, 'TAXABILITY', null, null);
        check_taxability_comms(schema_name_i);
        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_DEPENDENCY', 'Calling check_taxability_ref_groups with schema:'||schema_name_i, 'TAXABILITY', null, null);
        check_taxability_ref_groups(schema_name_i);
        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_DEPENDENCY', 'Calling check_taxability_ref_authority with schema:'||schema_name_i, 'TAXABILITY', null, null);
        check_taxability_ref_authority(schema_name_i);
        tdr_etl_proc_log('PULL_ETL.CHECK_TAXABILITY_DEPENDENCY', 'Calling check_taxability_ruleorder with schema:'||schema_name_i, 'TAXABILITY', null, null);
        check_taxability_ruleorder(schema_name_i);
    end;

    procedure pull_taxabilities(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2)
    is
        v_sql varchar2(5000);
        l_last_ext timestamp(6);
        l_stag_or_prod varchar2(10);
    begin
        if upper(schema_name_i) like 'TMP%'
        then
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_TAXABILITIES_STG', 'TAXABILITY', null, null);
            l_stag_or_prod := 'Staging';
            refresh_mv('MV_PULL_TAXABILITIES_STG', 'F');
        else
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_TAXABILITIES_PROD', 'TAXABILITY', null, null);
            l_stag_or_prod := 'Prod';
            refresh_mv('MV_PULL_TAXABILITIES_PROD', 'F');
        end if;

        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Calling get last extract date process', 'TAXABILITY', null, null);
        l_last_ext := get_last_extract_date(tag_group_i, 'TAXABILITY', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Last extract date value is '||l_last_ext, 'TAXABILITY', null, null);

        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Calling pull_etl_data with tag_group:'||tag_group_i||', last_extract_date:'||l_last_ext||', schema:'||schema_name_i, 'TAXABILITY', null, null);
        pull_etl_data(tag_group_i, l_last_ext, 'TAXABILITY', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Callung remove_processed_data with schema:'||schema_name_i, 'TAXABILITY', null, null);
        remove_processed_data(schema_name_i, 'TAXABILITY');
        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Calling queue_date with schema:'||schema_name_i, 'TAXABILITY', null, null);
        queue_date(tag_group_i, schema_name_i, 'TAXABILITY');

        -- process previously skipped taxabilities due to "Missing commodity in Determination"

        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Calling queue_date with schema:'||schema_name_i, 'TAXABILITY', null, null);
        load_skipped_etl_records(schema_name_i);

        -- This is to extract all the available reference groups for taxabilities
        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Calling refresh_refgrps4taxabilities with schema:'||schema_name_i, 'TAXABILITY', null, null);
        refresh_refgrps4taxabilities(schema_name_i);
        -- This is to extract all the available commodities for taxabilities
        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Calling refresh_comm4taxabilities with schema:'||schema_name_i, 'TAXABILITY', null, null);
        refresh_comm4taxabilities(schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Calling check_taxability_dependency with schema:'||schema_name_i, 'TAXABILITY', null, null);
        check_taxability_dependency(schema_name_i);

        tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_JURIS_TAX_APP_REVISIONS', 'TAXABILITY', null, null);
        refresh_mv('MV_JURIS_TAX_APP_REVISIONS', 'C');
        tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_JURIS_TAX_APPLICABILITIES', 'TAXABILITY', null, null);
        refresh_mv('MV_JURIS_TAX_APPLICABILITIES', 'C');
        tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_TAXABILITY_OUTPUTS', 'TAXABILITY', null, null);
        refresh_mv('MV_TAXABILITY_OUTPUTS', 'C');
        tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_TAX_APPLICABILITY_TAXES', 'TAXABILITY', null, null);
        refresh_mv('MV_TAX_APPLICABILITY_TAXES', 'C');
        tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_TRAN_TAX_QUALIFIERS', 'TAXABILITY', null, null);
        refresh_mv('MV_TRAN_TAX_QUALIFIERS', 'C');
        tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_JURIS_TAX_APP_ATTRIBUTES', 'TAXABILITY', null, null);
        refresh_mv('MV_JURIS_TAX_APP_ATTRIBUTES', 'C');
        tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_TAXABILITIES_STG', 'TAXABILITY', null, null);
        refresh_qualifier_mappings(schema_name_i);

    delete from ETL_Taxability_Taxes;

    if upper(schema_name_i) like 'TMP%'
    then
        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Loading staging related data into etl_taxability_taxes table', 'TAXABILITY', null, null);
        insert all into ETL_Taxability_Taxes
        select distinct jti.id id, jti.nkid, jti.reference_code from mv_tax_applicability_taxes tat
        join juris_tax_impositions jti on tat.juris_tax_imposition_nkid = jti.nkid and tat.juris_tax_imposition_id = jti.id
        join jurisdiction_tax_revisions jtv on jtv.id = jti.rid and jtv.summ_ass_status in (2,5);
        --group by jti.nkid, jti.reference_code;
    else
        tdr_etl_proc_log('PULL_ETL.PULL_TAXABILITIES', 'Loading prod related data into etl_taxability_taxes table', 'TAXABILITY', null, null);
        insert all into ETL_Taxability_Taxes
        select distinct jti.id id, jti.nkid, jti.reference_code from mv_tax_applicability_taxes tat
        join juris_tax_impositions jti on tat.juris_tax_imposition_nkid = jti.nkid and tat.juris_tax_imposition_id = jti.id
        where jti.status = 2;
    end if;

    end;

    procedure pull_administrators(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2)
    is
        v_sql varchar2(5000);
        l_last_ext TIMESTAMP(6);
    begin

            delete from tdr_administrator_extract;

            if upper(schema_name_i) like 'TMP%'
            then
                tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_ADMIN_STAGING', 'TAXABILITY', null, null);
                refresh_mv('MV_PULL_ADMIN_STAGING', 'F');
               insert all into tdr_administrator_extract(nkid, id) select distinct nkid, max(id) from MV_PULL_ADMIN_STAGING group by nkid;
            else
                tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing MV_PULL_ADMIN_PROD', 'TAXABILITY', null, null);
                refresh_mv('MV_PULL_ADMIN_PROD', 'F');
                insert all into tdr_administrator_extract(nkid, id) select distinct nkid, max(id) from MV_PULL_ADMIN_PROD group by nkid;
            end if;

        begin
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mv_administrator_revisions', 'TAXABILITY', null, null);
            dbms_mview.refresh('mv_administrator_revisions', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mv_administrators', 'TAXABILITY', null, null);
            dbms_mview.refresh('mv_administrators', 'C');
            tdr_etl_proc_log('PULL_ETL.REFRESH_MV', 'Refreshing mvadministrators', 'TAXABILITY', null, null);
            --dbms_mview.refresh('mv_administrator_tags', 'C');
            dbms_mview.refresh('mvadministrators', 'C');
        end;

        tdr_etl_proc_log('PULL_ETL.PULL_ADMINISTRATORS', 'Calling pull_etl_data with schema:'||schema_name_i, 'TAXABILITY', null, null);
        pull_etl_data(tag_group_i, l_last_ext, 'ADMINISTRATOR', schema_name_i);
        tdr_etl_proc_log('PULL_ETL.PULL_ADMINISTRATORS', 'Calling remove_processed_data with schema:'||schema_name_i, 'TAXABILITY', null, null);
        remove_processed_data(schema_name_i, 'ADMINISTRATOR');
        tdr_etl_proc_log('PULL_ETL.PULL_ADMINISTRATORS', 'Calling queue_date with schema:'||schema_name_i, 'TAXABILITY', null, null);
        queue_date(tag_group_i, schema_name_i, 'ADMINISTRATOR');

    end;


    procedure set_etl_log(process_id_i number, entity_i varchar2, status_i number, log_id out number, tag_group_i varchar2, stag_or_prod varchar2, tag_instance_i varchar2)
    is
        pragma autonomous_transaction;
    begin
        tdr_etl_proc_log('PULL_ETL.STE_ETL_LOG', 'Paramters, process_id:'||process_id_i||', entity:'||entity_i||', status:'||status_i||', tag_group_i:'||tag_group_i||', tag_instance_i:'||tag_instance_i, null, null, null);
        insert into tdr_etl_log (process_id, entity_name, status, start_time, tag_group, instance_name, tag_instance )
          values (process_id_i, entity_i, status_i, systimestamp, tag_group_i, stag_or_prod, tag_instance_i )
          return id into log_id;
          commit;
    end;

    procedure update_etl_log(log_id number, status_i number)
    is
        pragma autonomous_transaction;
    begin
        tdr_etl_proc_log('PULL_ETL.UPDATE_ETL_LOG', 'Paramters, log_id:'||log_id||', Status:'||status_i, null, null, null);
        update tdr_etl_log set status = status_i, stop_time = systimestamp where id = log_id;
        commit;

    end;

end;
/