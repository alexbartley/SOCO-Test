CREATE OR REPLACE PACKAGE BODY content_repo.tdr_etl_lib is
/*
/* TDR ETL Library Body
/*
*/

  -- Exceptions (Additional to ERRLOG/ERRNUMS)
  E_Process Exception;
  E_ETLRun Exception;

  /*****************************************************************************
  /* getschema
  /* ToDo: CONVERT TO LOOKUP TABLE
  /****************************************************************************/
  /*
  -- Added schema name into tdr_etl_instances table and to the view VETL_INSTANCE_GROUPS
  -- UI passes instance_group_id, DB extracts the schema name and tag_group_name directly from the view.

  /*****************************************************************************
  /* Procedure: add_params
  /* Purpose  : add submitted parameters
  /****************************************************************************/
  procedure add_params(vInstance in CLOB, dbProcessId OUT INT) is
    l_processid number:=0;
    pragma autonomous_transaction;
  begin
    Insert Into tdr_etl_process(etl_params)
    values(vInstance) returning processid into l_processid;
    commit;
    DBMS_OUTPUT.Put_Line( 'ETL entry added to tdr_etl_process table');
    dbProcessId := l_processid;
  end add_params;

  procedure empty_tmptables(schema_name_i varchar2) is
    l_processid number:=0;
    vexecString varchar2(200);
    pragma autonomous_transaction;
  begin
    vexecString := 'BEGIN '||schema_name_i||'.cr_extract.empty_tmp; END;';
    tdr_etl_proc_log('TDR_ETL_LIB.EMPTY_TMPTABLES', 'Calling EMPTY_TMPTABLES with schema:'||schema_name_i||', Query String:'||vexecString, 'EMPTY_TMPTABLES', null, null);
    execute immediate vexecString;
    vexecString := 'BEGIN '||schema_name_i||'.det_transform.empty_tmp_sbx; END;';
    tdr_etl_proc_log('TDR_ETL_LIB.EMPTY_TMPTABLES', 'Calling EMPTY_TMPTABLES with schema:'||schema_name_i||', Query String:'||vexecString, 'EMPTY_TMPTABLES', null, null);
    execute immediate vexecString;
  end empty_tmptables;


  procedure run_authorities(processid_i number, tag_group_i varchar2, schema_name_i varchar2, preview_i number, tag_instance_i varchar2)
  is
    vexecString varchar2(2000);
    v_etl_flag number := 0;
    l_etl_log_id number;
  begin
    v_etl_flag := 1;

      pull_etl.set_etl_log(processid_i, 'JURISDICTION', 0, l_etl_log_id, tag_group_i, case when schema_name_i like '%TMP%' then 'Staging' else 'Prod' end, tag_instance_i);

      -- Pull Authorities
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Calling pull authorities with tag_group:'||tag_group_i||', schema:'||schema_name_i, 'AUTHORITIES', null, null);
      vexecString :='BEGIN content_repo.pull_etl.pull_authorities(:x1, :x2, :x3); END;';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Query String:'||vexecString, 'AUTHORITIES', null, null);
      execute immediate (vexecString) USING tag_group_i, 'JURISDICTION', schema_name_i;
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'end pull authorities.', 'AUTHORITIES', null, null);

      -- Extract Authorities
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Calling extract authorities with tag_group:'||tag_group_i, 'AUTHORITIES', null, null);
      vexecString :='BEGIN '||schema_name_i||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Extract query string:'||vexecString, 'AUTHORITIES', null, null);
      execute immediate (vexecString) USING tag_group_i, 'AUTHORITIES';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'end extract authorities.', 'AUTHORITIES', null, null);

      -- Transform Authorities
      v_etl_flag := v_etl_flag + 1;
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Calling transform authorities with tag_group:'||tag_group_i, 'AUTHORITIES', null, null);
      vexecString:='BEGIN '||schema_name_i||'.DET_TRANSFORM.BUILD_TB_AUTHORITIES(:x1); END;';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'transform step 1 query string:'||vexecString, 'AUTHORITIES', null, null);
      execute immediate (vexecString) USING tag_group_i;
      vexecString:='BEGIN '||schema_name_i||'.DET_TRANSFORM.AUTH_APPEND_DET_DATA; END;';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'transform step 2 query string:'||vexecString, 'AUTHORITIES', null, null);
      execute immediate (vexecString);
      vexecString:='BEGIN '||schema_name_i||'.DET_TRANSFORM.BUILD_TB_AUTH_LOGIC; END;';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'transform step 3 query string:'||vexecString, 'AUTHORITIES', null, null);
      execute immediate (vexecString);
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'end transform authorities.', 'AUTHORITIES', null, null);

      -- Lload Authorities
      v_etl_flag := v_etl_flag + 1;
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Calling load authorities with preview:'||preview_i, 'AUTHORITIES', null, null);
      vexecString:='BEGIN '||schema_name_i||'.DET_UPDATE.COMPARE_AUTHORITIES('||preview_i||'); END;';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Load step 1 query string:'||vexecString, 'AUTHORITIES', null, null);
      execute immediate (vexecString);
      vexecString:='BEGIN '||schema_name_i||'.DET_UPDATE.COMPARE_AUTHORITY_LOGIC('||preview_i||'); END;';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Load step 2 query string:'||vexecString, 'AUTHORITIES', null, null);
      execute immediate (vexecString);
      vexecString:='BEGIN '||schema_name_i||'.DET_UPDATE.COMPARE_CONTRIBUTING_AUTHS('||preview_i||'); END;';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Load step 1 query string:'||vexecString, 'AUTHORITIES', null, null);
      execute immediate (vexecString);
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'end load authorities.', 'AUTHORITIES', null, null);

     tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Running update etl status for authorities with '||schema_name_i, 'AUTHORITIES', null, null);
     upd_etl_status(schema_name_i, 'AUTHORITIES');

      pull_etl.update_etl_log(l_etl_log_id, 1);

  end;

  procedure run_taxes(processid_i number, tag_group_i varchar2, schema_name_i varchar2, preview_i number, tag_instance_i varchar2)
  is
    l_etl_log_id number;
    vexecString varchar2(2000);
    l_etl_flag number;
  begin

     l_etl_flag := 1;

     pull_etl.set_etl_log(processid_i, 'TAX', 0, l_etl_log_id, tag_group_i, case when schema_name_i like '%TMP%' then 'Staging' else 'Prod' end , tag_instance_i );
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'Calling pull taxes with tag_group:'||tag_group_i||', schema:'||schema_name_i, 'RATES', null, null);
     vexecString :='BEGIN content_repo.pull_etl.pull_taxes(:x1, :x2, :x3); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'Query String:'||vexecString, 'RUN_TAXES', null, null);
     execute immediate (vexecString) USING tag_group_i, 'TAX', schema_name_i;
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'end pull taxes.', 'RUN_TAXES', null, null);

     vexecString :='BEGIN '||schema_name_i||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'Calling extract rates with tag_group:'||tag_group_i||', Query string:'||vexecString, 'RUN_TAXES', null, null);
     execute immediate (vexecString) USING tag_group_i, 'RATES';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'end extract taxes.', 'RUN_TAXES', null, null);

     vexecString:='BEGIN '||schema_name_i||'.DET_TRANSFORM.BUILD_TB_RATES; END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'transform query string:'||vexecString, 'RUN_TAXES', null, null);
     execute immediate (vexecString);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'end transform taxes.', 'RUN_TAXES', null, null);

     vexecString:='BEGIN '||schema_name_i||'.DET_UPDATE.COMPARE_RATES('||preview_i||'); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'Load taxes query string:'||vexecString, 'RUN_TAXES', null, null);
     execute immediate (vexecString);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'end load taxes.', 'RUN_TAXES', null, null);

     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'Running update etl status for rates', 'RATES', null, null);
     upd_etl_status(schema_name_i, 'RATES');

      pull_etl.update_etl_log(l_etl_log_id, 1);

  end;


  procedure run_commodities(processid_i number, tag_group_i varchar2, schema_name_i varchar2, preview_i number, tag_instance_i varchar2)
  is
    l_etl_log_id number;
    vexecString varchar2(2000);
    l_etl_flag number;
  begin
     pull_etl.set_etl_log(processid_i, 'COMMODITY', 0, l_etl_log_id, tag_group_i, case when schema_name_i like '%TMP%' then 'Staging' else 'Prod' end, tag_instance_i);

     vexecString :='BEGIN content_repo.pull_etl.pull_commodities(:x1, :x2, :x3); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'Calling pull commodities with tag_group:'||tag_group_i||', schema:'||schema_name_i, 'RUN_COMMODITIES', null, null);
     execute immediate (vexecString) USING tag_group_i, 'COMMODITY', schema_name_i;
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'end pull commmodities.', 'RUN_COMMODITIES', null, null);


     vexecString :='BEGIN '||schema_name_i||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'Extract query string:'||vexecString, 'RUN_COMMODITIES', null, null);
     execute immediate (vexecString) USING tag_group_i, 'PRODUCTS';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'end extract commodities.', 'RUN_COMMODITIES', null, null);


     vexecString:='BEGIN '||schema_name_i||'.DET_TRANSFORM.BUILD_TB_PRODUCT_CATEGORIES; END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'transform commodities, query string:'||vexecString, 'RUN_COMMODITIES', null, null);
     execute immediate (vexecString);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'end transform commodities.', 'RUN_COMMODITIES', null, null);


     vexecString:='BEGIN '||schema_name_i||'.DET_UPDATE.COMPARE_PRODUCTS(-2,'||preview_i||'); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'Load commodities query string:'||vexecString, 'RUN_COMMODITIES', null, null);
     execute immediate (vexecString);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'End loading commodities.', 'RUN_COMMODITIES', null, null);

     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'Running update etl status for products', 'PRODUCTS', null, null);
     upd_etl_status(schema_name_i, 'PRODUCTS');

    /*
     vexecString:='BEGIN '||schema_name_i||'.DET_UPDATE.truncate_tmp_table(''PRODUCTS''); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'Running truncate table:'||vexecString, 'RUN_COMMODITIES', null, null);
     execute immediate (vexecString);
     */

     pull_etl.update_etl_log(l_etl_log_id, 1);
  end;

  procedure run_reference_groups(processid_i number, tag_group_i varchar2, schema_name_i varchar2, preview_i number, tag_instance_i varchar2)
  is
    l_etl_log_id number;
    vexecString varchar2(2000);
    l_etl_flag number;
  begin
     pull_etl.set_etl_log(processid_i, 'REFERENCE GROUP', 0, l_etl_log_id, tag_group_i, case when schema_name_i like '%TMP%' then 'Staging' else 'Prod' end, tag_instance_i);

     vexecString :='BEGIN content_repo.pull_etl.pull_reference_groups(:x1, :x2, :x3); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'Pull Query String:'||vexecString, 'RUN_REFERENCE_GROUPS', null, null);
     execute immediate (vexecString) USING tag_group_i, 'REFERENCE GROUP', schema_name_i;
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'end pull authorities.', 'RUN_REFERENCE_GROUPS', null, null);

     vexecString :='BEGIN '||schema_name_i||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'Extract query string:'||vexecString, 'RUN_REFERENCE_GROUPS', null, null);
     execute immediate (vexecString) USING tag_group_i, 'REFERENCE GROUP';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'end extract reference groups.', 'RUN_REFERENCE_GROUPS', null, null);

     vexecString :='BEGIN '||schema_name_i||'.DET_TRANSFORM.BUILD_TB_REFERENCE_LISTS; END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'transform query string:'||vexecString, 'RUN_REFERENCE_GROUPS', null, null);
     execute immediate (vexecString);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'end transform reference groups.', 'RUN_REFERENCE_GROUPS', null, null);

     vexecString :='BEGIN '||schema_name_i||'.DET_UPDATE.COMPARE_REFERENCE_LISTS('||preview_i||'); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'Load query string:'||vexecString, 'RUN_REFERENCE_GROUPS', null, null);
     execute immediate (vexecString);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'end load reference groups.', 'RUN_REFERENCE_GROUPS', null, null);

     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'Running update etl status for reference groups', 'REFERENCE GROUP', null, null);
     upd_etl_status(schema_name_i, 'REFERENCE GROUP');

     pull_etl.update_etl_log(l_etl_log_id, 1);
  end;

  procedure run_taxabilities(processid_i number, tag_group_i varchar2, schema_name_i varchar2, preview_i number, tag_instance_i varchar2)
  is
    l_etl_log_id number;
    vexecString varchar2(2000);
    l_etl_flag number;
  begin
     pull_etl.set_etl_log(processid_i, 'TAXABILITY', 0, l_etl_log_id, tag_group_i, case when schema_name_i like '%TMP%' then 'Staging' else 'Prod' end, tag_instance_i);

     vexecString :='BEGIN content_repo.pull_etl.pull_taxabilities(:x1, :x2, :x3); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'Pull query string:'||vexecString, 'RUN_TAXABILITIES', null, null);
     execute immediate (vexecString) USING tag_group_i, 'TAXABILITY', schema_name_i;
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'end pull taxabilities.', 'RUN_TAXABILITIES', null, null);

     vexecString :='BEGIN '||schema_name_i||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'Extract query string:'||vexecString, 'RUN_TAXABILITIES', null, null);
     execute immediate (vexecString) USING tag_group_i, 'RULES';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'end extract taxabilities.', 'RUN_TAXABILITIES', null, null);

     vexecString:='BEGIN '||schema_name_i||'.DET_TRANSFORM.BUILD_TB_RULES; END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'transform query string:'||vexecString, 'RUN_TAXABILITIES', null, null);
     execute immediate (vexecString);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'end transform taxabilities.', 'RUN_TAXABILITIES', null, null);

     vexecString:='BEGIN '||schema_name_i||'.DET_UPDATE.COMPARE_RULES('||preview_i||'); END;';
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'Load query string:'||vexecString, 'RUN_TAXABILITIES', null, null);
     execute immediate (vexecString);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'end load taxabilities.', 'RUN_TAXABILITIES', null, null);

     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'Running update etl status for rules', 'RULES', null, null);
     upd_etl_status(schema_name_i, 'RULES');

     pull_etl.update_etl_log(l_etl_log_id, 1);
  end;

  procedure run_administrators(processid_i number, tag_group_i varchar2, schema_name_i varchar2, tag_instance_i varchar2)
  is
    l_etl_log_id number;
    vexecString varchar2(2000);
    l_etl_flag number;
  begin
      pull_etl.set_etl_log(processid_i, 'ADMINISTRATOR', 0, l_etl_log_id, tag_group_i, case when schema_name_i like '%TMP%' then 'Staging' else 'Prod' end, tag_instance_i );

      vexecString :='BEGIN content_repo.pull_etl.pull_administrators(:x1, :x2, :x3); END;';
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_ADMINISTRATORS', 'Query String:'||vexecString, 'RUN_ADMINISTRATORS', null, null);
      execute immediate (vexecString) USING tag_group_i, 'ADMINISTRATOR', schema_name_i;
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_ADMINISTRATORS', 'end pull administrators.', 'RUN_ADMINISTRATORS', null, null);
	  
	  execute immediate 'update '||schema_name_i||'.extract_log set extract_date = systimestamp, transformed = systimestamp, loaded = systimestamp
                          where entity = ''ADMINISTRATOR'' and extract_date is null';
      upd_etl_status(schema_name_i, 'ADMINISTRATOR');

      pull_etl.update_etl_log(l_etl_log_id, 1);
  end;

  /*****************************************************************************
  /* Procedure: tdretlprocess
  /* Purpose  : process ETL
  /*   Store in parameters,
  /*   Activate chain based on parameters
  /****************************************************************************/
  procedure tdretlprocess( instancegroupid number, preview_i number default 0, truncate_i number default 0
  ) is
    p1 pls_integer;
    p2 pls_integer;
    l_processid number;

    j_type number;
    j_instance varchar2(256);
    j_tag_group varchar2(256);
    j_truncate number;
    j_entities varchar2(512);
    l_preview number := 0;
    j_instance_group_id number;
    vInstance varchar(20);

    l_extract_id number;
    l_schema varchar2(30);
    execString varchar2(128);
    l_etl_log_id number;

    type t_ent is record(entity varchar2(30));
    type r_ent is table of t_ent;
    l_entities r_ent;
    l_pull_entities r_ent;
    l_ent varchar2(32);
    l_step varchar2(20);
    l_etl_flag number := 0;
    stag_or_prod varchar2(1);
    l_instance_name varchar2(50);

  begin

    tdr_etl_proc_log('TDR_ETL_LIB.TDRETLPROCESS', 'ETL Started', 'All', null, null);

    j_entities := 'ADMINISTRATORS,JURISDICTION,TAXES,TAXABILITY,COMMODITY,REFERENCE GROUP';

    j_entities := 'ALL';
    l_preview := 1;

      -- add parameters (reference)
      l_step := 'Step 01';

      tdr_etl_proc_log('TDR_ETL_LIB.TDRETLPROCESS', 'Calling Add Params, Instance Group ID '||instancegroupid, 'ALL', null, null);
      add_params(to_char(instancegroupid), l_processid);
      tdr_etl_proc_log('TDR_ETL_LIB.TDRETLPROCESS', 'End Add Params, Process ID '||l_processid, 'ALL', null, null);

      select schema_name, tag_group_name, instance_name into l_schema, j_tag_group, l_instance_name from vetl_instance_groups where instance_group_id = instancegroupid;

      stag_or_prod := case when l_schema like 'SBXTAX%' then 'P' else 'S' end;

      -- Set Determination to use for ETL
      l_step := 'Step 03';
      -- l_schema:=getSchema(j_tag_group, stag_or_prod);

      tdr_etl_proc_log('TDR_ETL_LIB.TDRETLPROCESS', 'Running ETL with, Process ID '||l_processid||', l_schema:'||l_schema||', j_tag_group:'||j_tag_group||', j_entities:'||j_entities, 'ALL', null, null);

/*
     -- Get entities
-- TODO: for now it is always 'All', mimic one button in UI using all entities
    SELECT upper(t2.column_value)
    bulk collect into l_entities
      FROM TDR_ETL_ENTITIES t1,
      TABLE(t1.transform_entitylist) t2
      where upper(entity) = upper(j_entities) ;--'All';

    SELECT upper(t2.column_value)
    bulk collect into l_pull_entities
      FROM TDR_ETL_ENTITIES t1,
      TABLE(t1.pull_entitylist) t2
      where upper(entity) = upper(j_entities);--'All';
*/
    -- DELETE FROM tdr_etl_log WHERE INSTANCE_NAME = 'Staging';

    l_step := 'Step 05';

    --pull_etl.set_etl_log(l_processid, j_entities, 0, l_etl_log_id, j_tag_group, stag_or_prod);

      --pull_etl.clean_tmp_extract;
      dbms_output.put_line('ETL Log time set up done');
        l_step := 'Step 06';

     -- Run Administrators First
      l_etl_flag := 1;


      tdr_etl_proc_log('TDR_ETL_LIB.TDRETLPROCESS', 'Parameters are process_id:'||l_processid||', tag_group:'||j_tag_group||', schema:'||l_schema||', instance_name:'||l_instance_name,'ALL', null, null);

      tdr_etl_proc_log('TDR_ETL_LIB.EMPTY_TMPTABLES', 'Truncate all temp tables and have these ready for ETL, Deleting old data from tdr_etl_extract_list table', 'EMPTY_TMPTABLES', null, null);

      begin
        pull_etl.clean_tmp_extract;
        empty_tmptables(l_schema);
      end;

      -- Run Administrators
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_ADMINISTRATORS', 'Calling Administrator process', 'ADMINISTRATOR', null, null);
      run_administrators(l_processid, j_tag_group, l_schema, l_instance_name);
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_ADMINISTRATORS', 'End running administrator.', 'ADMINISTRATOR', null, null);

      -- Run Jurisdictions

      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'Calling authorities process', 'AUTHORITIES', null, null);
      run_authorities(l_processid, j_tag_group, l_schema, l_preview, l_instance_name);
      tdr_etl_proc_log('TDR_ETL_LIB.RUN_AUTHORITIES', 'End running authorities.', 'RUN_AUTHORITIES', null, null);

     -- Run Taxes Now

    tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'Calling taxes process', 'TAXES', null, null);
    run_taxes(l_processid, j_tag_group, l_schema, l_preview, l_instance_name);
    tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXES', 'End running taxes.', 'TAXES', null, null);

     -- Run Commodities Now

     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'Calling commodities process', 'COMMODITIES', null, null);
     run_commodities(l_processid, j_tag_group, l_schema, l_preview, l_instance_name);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_COMMODITIES', 'End running commodities.', 'COMMODITIES', null, null);

     -- Run Reference Groups Now
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'Calling reference groups process', 'REFERENCE_GROUPS', null, null);
     run_reference_groups(l_processid, j_tag_group, l_schema, l_preview, l_instance_name);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_REFERENCE_GROUPS', 'End running reference groups', 'REFERENCE_GROUPS', null, null);

     -- Run Taxabilities Now
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'Calling taxabilities process', 'TAXABILITIES', null, null);
     run_taxabilities(l_processid, j_tag_group, l_schema, l_preview, l_instance_name);
     tdr_etl_proc_log('TDR_ETL_LIB.RUN_TAXABILITIES', 'End running taxabilities', 'TAXABILITIES', null, null);


    exception
    when E_Process then
      pull_etl.update_etl_log(l_processid, -1);
      tdr_etl_proc_log('TDR_ETL_LIB.TDRETLPROCESS', l_step||':'||substr(sqlerrm,1,980), null, null, null);
      errlogger.REPORT_AND_GO(err_in=> -30001, msg_in=> 'ETL Missing parameters for a run. Nothing processed, Step No:'||l_step);
      RAISE_APPLICATION_ERROR(-30001,'ETL Missing parameters for a run. Nothing processed, Step No: '||l_step);
    when E_ETLRun then
      pull_etl.update_etl_log(l_processid, -1);
      tdr_etl_proc_log('TDR_ETL_LIB.TDRETLPROCESS', l_step||':'||substr(sqlerrm,1,980), null, null, null);
      errlogger.REPORT_AND_GO(err_in=> -30002, msg_in=> 'ETL Process failed at Step '||l_step);
      RAISE_APPLICATION_ERROR(-30002,'Failed at '||l_step||'Database error '||SQLERRM);

  end tdretlprocess;

  procedure tdretlprocess_advanced(vInstance in CLOB--, dbProcess OUT CLOB,
            ,stag_or_prod varchar2 default 'P'
  ) is
    p1 pls_integer;
    p2 pls_integer;
    l_processid number;

    j_type number;
    j_instance varchar2(256);
    j_tag_group varchar2(256);
    j_truncate number;
    j_entities varchar2(512);
    j_pull_entities varchar2(512);
    j_extract_entities varchar2(512);
    j_transform_entities varchar2(512);
    j_load_entities varchar2(512);
    l_preview number := 0;
    j_instance_group_id number;

    l_extract_id number;
    l_schema varchar2(30);
    execString varchar2(128);
    l_etl_log_id number;

    type t_ent is record(entity varchar2(30));
    type r_ent is table of t_ent;
    l_entities r_ent;
    l_pull_entities r_ent;
    l_ent varchar2(32);
    l_step varchar2(20);
    l_etl_flag number := 0;
    l_instance_name varchar2(50);

  begin
    if vInstance is not null then
      -- add parameters (reference)
      l_step := 'Step 01';
      add_params(vInstance, l_processid);

      -- get Type, tag_group,
      l_step := 'Step 02';
      Select
        a.etl_params.pull.type     j_type
      , a.etl_params.instance      j_instance
      , a.etl_params.instance_group_id      j_instance_group_id
      , a.etl_params.tag_group     j_tag_group
      , a.etl_params.pull.truncate j_truncate
      --, REGEXP_REPLACE(a.etl_params.pull.entities,'(\[|\]|")','') j_entities
      , REGEXP_REPLACE(a.etl_params.pull.entities,'(\[|\]|")','') j_pull_entities
      , REGEXP_REPLACE(a.etl_params.extract.entities,'(\[|\]|")','') j_extract_entities
      , REGEXP_REPLACE(a.etl_params.transform.entities,'(\[|\]|")','') j_transform_entities
      , REGEXP_REPLACE(a.etl_params.load.entities,'(\[|\]|")','') j_load_entities
      , a.etl_params.preview l_preview
      Into j_type
         , j_instance
         , j_instance_group_id
         , j_tag_group
         , j_truncate
      --   , j_entities
         , j_pull_entities
         , j_extract_entities
         , j_transform_entities
         , j_load_entities
         , l_preview
      FROM  TDR_ETL_PROCESS a
      where processid = l_processid;

    begin
      select schema_name, tag_group_name into l_schema, j_tag_group from vetl_instance_groups where instance_group_id = j_tag_group;
    exception
    when no_data_found
    then
        raise_application_error(-20201, 'Instance Group ID does not exists.');
    end;

    l_preview := nvl(l_preview,1);

      -- Set Determination to use for ETL
      l_step := 'Step 03';
      -- l_schema:=getSchema(j_tag_group, stag_or_prod);
      DBMS_OUTPUT.Put_Line( l_schema );
      DBMS_OUTPUT.Put_Line( l_processid );
      DBMS_OUTPUT.Put_Line( j_tag_group );
      dbms_output.put_line('Entity List is '||j_pull_entities);

      l_step := 'Step 04';
      if j_truncate = 1 Then
        l_step := 'Step 04_01';
        execString :='BEGIN '||l_schema||'.CR_EXTRACT.EMPTY_TMP; END;';
        DBMS_OUTPUT.Put_Line( execString );
--todo: Execute immediate (execString);
        l_step := 'Step 04_02';
        execString :='BEGIN '||l_schema||'.DET_TRANSFORM.EMPTY_TMP_SBX; END;';
        DBMS_OUTPUT.Put_Line( execString );
--todo: Execute immediate (execString);

      end if;

/*
     -- Get entities
-- TODO: for now it is always 'All', mimic one button in UI using all entities
    SELECT upper(t2.column_value)
    bulk collect into l_entities
      FROM TDR_ETL_ENTITIES t1,
      TABLE(t1.transform_entitylist) t2
      where upper(entity) = upper(j_entities) ;--'All';

    SELECT upper(t2.column_value)
    bulk collect into l_pull_entities
      FROM TDR_ETL_ENTITIES t1,
      TABLE(t1.pull_entitylist) t2
      where upper(entity) = upper(j_entities);--'All';
*/
    --DELETE FROM tdr_etl_log WHERE INSTANCE_NAME = 'Staging';

    l_step := 'Step 05';
    if j_pull_entities = 'ALL'
    then
        l_step := 'Step 05_01';
        j_pull_entities := 'ADMINISTRATORS,JURISDICTION,TAXES,TAXABILITY,COMMODITY,REFERENCE GROUP';
        j_extract_entities := j_pull_entities;
        j_transform_entities := j_pull_entities;
        j_load_entities := j_pull_entities;
        l_step := 'Step 05_02';
        pull_etl.set_etl_log(l_processid, j_entities, 0, l_etl_log_id, j_tag_group, 'Staging', j_instance);
    end if;

        j_pull_entities := replace(replace(replace(j_pull_entities, ',Tax,', ',Taxes,'), 'Tax,', 'Taxes,'), ',Tax', 'Taxes');

        if j_pull_entities = 'Tax'
        then
            j_pull_entities := 'Taxes';
        end if;

      --pull_etl.clean_tmp_extract;
      dbms_output.put_line('ETL Log time set up done');
        l_step := 'Step 06';
     FOR ii in 1..6 LOOP

        --dbms_output.put_line('l_entities(ii).entity value is '||l_entities(ii).entity);
         case
             when ii =1
             then

                l_step := 'Step 07_01';
                if upper(j_pull_entities) like '%ADMINISTRATOR%'
                THEN
                    l_etl_flag := 1;
                    pull_etl.set_etl_log(l_processid, 'ADMINISTRATOR', 0, l_etl_log_id, j_tag_group, 'Staging', j_instance);
                    dbms_output.put_line('Administrator pull process started');
                    execString :='BEGIN content_repo.pull_etl.pull_administrators(:x1, :x2, :x3); END;';
                    execute immediate (execString) USING j_tag_group, 'ADMINISTRATOR', l_schema;
                    --pull_etl.pull_administrators(j_tag_group, 'All', l_schema);
                    dbms_output.put_line('Administrator pull process completed');
                    dbms_output.put_line('execString value is '||execString);
                end if;
             when ii = 2
             THEN
                l_step := 'Step 07_02';
                if upper(j_pull_entities) like '%JURISDICTION%'
                THEN
                    l_etl_flag := 1;
                    pull_etl.set_etl_log(l_processid, 'JURISDICTION', 0, l_etl_log_id, j_tag_group, 'Staging', j_instance);
                    dbms_output.put_line('JURISDICTION pull process started');
                    execString :='BEGIN content_repo.pull_etl.pull_authorities(:x1, :x2, :x3); END;';
                    execute immediate (execString) USING j_tag_group, 'JURISDICTION', l_schema;
                    -- pull_etl.pull_administrators(j_tag_group, 'All', l_schema);
                    dbms_output.put_line('JURISDICTION pull process completed');
                    dbms_output.put_line('execString value is '||execString);
                end if;
                l_step := 'Step 07_03';

                if upper(j_extract_entities) like '%AUTHORITIES%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString :='BEGIN '||l_schema||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
                    DBMS_OUTPUT.Put_Line(execString||' Tag Group '||j_tag_group||' Entity '||'AUTHORITIES');
                    execute immediate (execString) USING j_tag_group, 'AUTHORITIES';
                    dbms_output.put_line('execString value is '||execString);
                END IF;
                l_step := 'Step 07_04';
                if upper(j_transform_entities) like '%AUTHORITIES%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_TRANSFORM.BUILD_TB_AUTHORITIES(:x1); END;';
                    dbms_output.put_line('AUTHORITIES'||' '||execString);
                    execute immediate (execString) USING j_tag_group;
                    execString:='BEGIN '||l_schema||'.DET_TRANSFORM.AUTH_APPEND_DET_DATA; END;';
                    dbms_output.put_line('AUTHORITIES'||' '||execString);
                    execute immediate (execString);
                    execString:='BEGIN '||l_schema||'.DET_TRANSFORM.BUILD_TB_AUTH_LOGIC; END;';
                    dbms_output.put_line('AUTHORITIES'||' '||execString);
                    execute immediate (execString);
                    dbms_output.put_line('AUTHORITIES'||' '||execString);
                END IF;
                l_step := 'Step 07_05';
                if upper(j_load_entities) like '%AUTHORITIES%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_UPDATE.COMPARE_AUTHORITIES('||l_preview||'); END;';
                    dbms_output.put_line('AUTHORITIES'||' '||execString);
                    execute immediate (execString);
                    execString:='BEGIN '||l_schema||'.DET_UPDATE.COMPARE_AUTHORITY_LOGIC('||l_preview||'); END;';
                    dbms_output.put_line('AUTHORITIES'||' '||execString);
                    execute immediate (execString);
                    execString:='BEGIN '||l_schema||'.DET_UPDATE.COMPARE_CONTRIBUTING_AUTHS('||l_preview||'); END;';
                    dbms_output.put_line('AUTHORITIES'||' '||execString);
                    execute immediate (execString);
                    dbms_output.put_line('AUTHORITIES'||' '||execString);
                END IF;
                if l_etl_flag = 4
                then
                    pull_etl.update_etl_log(l_etl_log_id, 1);
                end if;
             when ii = 5
             THEN
                l_step := 'Step 07_06';
                if upper(j_pull_entities) LIKE '%TAXES%'
                THEN
                    l_etl_flag := 1;
                    pull_etl.set_etl_log(l_processid, 'TAX', 0, l_etl_log_id, j_tag_group, 'Staging', j_instance);
                    dbms_output.put_line('TAX pull process started');
                    execString :='BEGIN content_repo.pull_etl.pull_taxes(:x1, :x2, :x3); END;';
                    execute immediate (execString) USING j_tag_group, 'TAX', l_schema;
                    -- pull_etl.pull_administrators(j_tag_group, 'All', l_schema);
                    dbms_output.put_line('TAX pull process completed');
                    dbms_output.put_line('execString value is '||execString);
                END IF;

                l_step := 'Step 07_07';

                if upper(j_extract_entities) like '%RATES%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString :='BEGIN '||l_schema||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
                    DBMS_OUTPUT.Put_Line(execString||' Tag Group '||j_tag_group||' Entity '||'RATES');
                    execute immediate (execString) USING j_tag_group, 'RATES';
                    dbms_output.put_line('execString value is '||execString);
                END IF;
                l_step := 'Step 07_08';

                if upper(j_transform_entities) like '%RATES%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_TRANSFORM.BUILD_TB_RATES; END;';
                    execute immediate (execString);
                    dbms_output.put_line('RATES'||' '||execString);
                END IF;
                l_step := 'Step 07_09';
                if upper(j_load_entities) like '%RATES%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_UPDATE.COMPARE_RATES('||l_preview||'); END;';
                    execute immediate (execString);
                    dbms_output.put_line('RATES'||' '||execString);
                END IF;
                if l_etl_flag = 4
                then
                    pull_etl.update_etl_log(l_etl_log_id, 1);
                end if;
             when ii = 6
             THEN
                l_step := 'Step 07_10';
                if upper(j_pull_entities) like '%TAXABILITY%'
                THEN
                    l_etl_flag := 1;
                    pull_etl.set_etl_log(l_processid, 'TAXABILITY', 0, l_etl_log_id, j_tag_group, 'Staging', j_instance);
                    dbms_output.put_line('TAXABILITY pull process started');
                    execString :='BEGIN content_repo.pull_etl.pull_taxabilities(:x1, :x2, :x3); END;';
                    execute immediate (execString) USING j_tag_group, 'TAXABILITY', l_schema;
                    dbms_output.put_line('TAXABILITY pull process completed');
                    dbms_output.put_line('execString value is '||execString);
                END IF;
                l_step := 'Step 07_11';

                if upper(j_extract_entities) like '%RULES%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString :='BEGIN '||l_schema||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
                    DBMS_OUTPUT.Put_Line(execString||' Tag Group '||j_tag_group||' Entity '||'TAXABILITY');
                    execute immediate (execString) USING j_tag_group, 'RULES';
                    dbms_output.put_line('execString value is '||execString);
                END IF;
                l_step := 'Step 07_12';

                if upper(j_transform_entities) like '%RULES%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_TRANSFORM.BUILD_TB_RULES; END;';
                    execute immediate (execString);
                    dbms_output.put_line('RULES'||' '||execString);
                END IF;
                l_step := 'Step 07_13';
                if upper(j_load_entities) like '%RULES%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_UPDATE.COMPARE_RULES('||l_preview||'); END;';
                    execute immediate (execString);
                    dbms_output.put_line('RULES'||' '||execString);
                END IF;

                if l_etl_flag = 4
                then
                    pull_etl.update_etl_log(l_etl_log_id, 1);
                end if;

             when ii = 3
             THEN
                l_step := 'Step 07_14';
                if upper(j_pull_entities) like '%COMMODITY%'
                THEN
                    l_etl_flag := 1;
                    pull_etl.set_etl_log(l_processid, 'COMMODITY', 0, l_etl_log_id, j_tag_group, 'Staging', j_instance);
                    dbms_output.put_line('COMMODITY pull process started');
                    execString :='BEGIN content_repo.pull_etl.pull_commodities(:x1, :x2, :x3); END;';
                    execute immediate (execString) USING j_tag_group, 'COMMODITY', l_schema;
                    -- pull_etl.pull_administrators(j_tag_group, 'All', l_schema);
                    dbms_output.put_line('COMMODITY pull process completed');
                    dbms_output.put_line('execString value is '||execString);
                END IF;
                l_step := 'Step 07_15';
                if upper(j_extract_entities) like '%PRODUCTS%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString :='BEGIN '||l_schema||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
                    DBMS_OUTPUT.Put_Line(execString||' Tag Group '||j_tag_group||' Entity '||'PRODUCTS');
                    execute immediate (execString) USING j_tag_group, 'PRODUCTS';
                    dbms_output.put_line('execString value is '||execString);
                END IF;
                l_step := 'Step 07_16';
                if upper(j_transform_entities) like '%PRODUCTS%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_TRANSFORM.BUILD_TB_PRODUCT_CATEGORIES; END;';
                    dbms_output.put_line('COMMODITY'||' Transform Started. '||execString);
                    execute immediate (execString);
                    dbms_output.put_line('COMMODITY'||' Transform Completed. '||execString);

                END IF;
                l_step := 'Step 07_17';
                if upper(j_load_entities) like '%PRODUCTS%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_UPDATE.COMPARE_PRODUCTS(-2,'||l_preview||'); END;';
                    execute immediate (execString);
                    dbms_output.put_line('COMMODITY'||' '||execString);
                END IF;

                if l_etl_flag = 4
                then
                    pull_etl.update_etl_log(l_etl_log_id, 1);
                end if;

             when ii = 4
             THEN
                l_step := 'Step 07_18';
                if upper(j_pull_entities) like '%REFERENCE GROUP%'
                THEN
                    l_etl_flag := 1;
                    pull_etl.set_etl_log(l_processid, 'REFERENCE GROUP', 0, l_etl_log_id, j_tag_group, 'Staging', j_instance);
                    dbms_output.put_line('REFERENCE GROUP pull process started');
                    execString :='BEGIN content_repo.pull_etl.pull_reference_groups(:x1, :x2, :x3); END;';
                     execute immediate (execString) USING j_tag_group, 'REFERENCE GROUP', l_schema;
                    dbms_output.put_line('execString value is '||execString);
                    dbms_output.put_line('REFERENCE_GROUPS pull process completed');
                END IF;
                l_step := 'Step 07_19';
                if upper(j_extract_entities) like '%REFERENCE GROUP%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString :='BEGIN '||l_schema||'.cr_extract.LOCAL_EXTRACT(:x1, :x2); END;';
                    DBMS_OUTPUT.Put_Line(execString||' Tag Group '||j_tag_group||' Entity '||'REFERENCE GROUP');
                     execute immediate (execString) USING j_tag_group, 'REFERENCE GROUP';
                    dbms_output.put_line('execString value is '||execString);
                END IF;
                l_step := 'Step 07_20';
                if upper(j_transform_entities) like '%REFERENCE GROUP%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_TRANSFORM.BUILD_TB_REFERENCE_LISTS; END;';
                    execute immediate (execString);
                    dbms_output.put_line('REFERENCE_GROUPS '||' '||execString);
                END IF;
                l_step := 'Step 07_21';
                if upper(j_load_entities) like '%REFERENCE GROUP%'
                THEN
                    l_etl_flag := l_etl_flag + 1;
                    execString:='BEGIN '||l_schema||'.DET_UPDATE.COMPARE_REFERENCE_LISTS('||l_preview||'); END;';
                    execute immediate (execString);
                    dbms_output.put_line('REFERENCE_GROUPS'||' '||execString);
                END IF;

                if l_etl_flag = 4
                then
                    pull_etl.update_etl_log(l_etl_log_id, 1);
                end if;

             else
                l_step := 'Step 07_22';
                dbms_output.put_line('Empty --> Fail');
                raise_application_error(-20201, 'Entity name issue, processed till '||l_step);
         end case pull;

     END LOOP;

     content_repo.pull_etl.clean_tmp_extract;
        dbms_output.put_line('l_extract_id VALUE IS '||l_extract_id);
/*
         if l_extract_id != null then
         execString:='BEGIN CRAPP_EXTRACT.PULL.SET_ETL_COMPLETE(:extract_id); END;';
            DBMS_OUTPUT.Put_Line( execString );
    --     execute immediate (execString) USING l_extract_id;
        end if;
*/
    else
      raise E_Process;
    end if;
        l_step := 'Step 08';

    exception
    when E_Process then
      pull_etl.update_etl_log(l_processid, -1);
      errlogger.REPORT_AND_GO(err_in=> -30001, msg_in=> 'ETL Missing parameters for a run. Nothing processed, Step No:'||l_step);
      RAISE_APPLICATION_ERROR(-30001,'ETL Missing parameters for a run. Nothing processed, Step No: '||l_step);
    when E_ETLRun then
      pull_etl.update_etl_log(l_processid, -1);
      errlogger.REPORT_AND_GO(err_in=> -30002, msg_in=> 'ETL Process failed at Step '||l_step);
      RAISE_APPLICATION_ERROR(-30002,'Failed at '||l_step||'Database error '||SQLERRM);

  end tdretlprocess_advanced;

PROCEDURE UPD_ETL_STATUS(schema_name_i VARCHAR2, ENTITY_NAME_I varchar2)
IS
BEGIN
    if schema_name_i = 'SBXTAX'
    then
        if ENTITY_NAME_I = 'RATES' then
            update tdr_etl_entity_status set etl_us = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'TAX' from sbxtax.tdr_etl_tb_rates);
        elsif ENTITY_NAME_I = 'RULES' then
            update tdr_etl_entity_status set etl_us = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'TAXABILITY' from sbxtax.tdr_etl_tb_rules);
        elsif ENTITY_NAME_I = 'AUTHORITIES' then
            update tdr_etl_entity_status set etl_us = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'JURISDICTION' from sbxtax.tdr_etl_tb_authorities);
        elsif ENTITY_NAME_I = 'PRODUCTS' then
            update tdr_etl_entity_status set etl_us = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'COMMODITY' from sbxtax.tdr_etl_ct_product_tree);
        elsif ENTITY_NAME_I = 'REFERENCE GROUP' then
            update tdr_etl_entity_status set etl_us = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'REFERENCE GROUP' from sbxtax.tdr_etl_tb_reference_lists);
		elsif ENTITY_NAME_I = 'ADMINISTRATOR' then
            update tdr_etl_entity_status set etl_us = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'ADMINISTRATOR' from sbxtax.extract_log);
        END IF;

    ELSIF schema_name_i = 'SBXTAX4'
    THEN
        if ENTITY_NAME_I = 'RATES' then
            update tdr_etl_entity_status set etl_telco = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'TAX' from sbxtax4.tdr_etl_tb_rates);
        elsif ENTITY_NAME_I = 'RULES' then
            update tdr_etl_entity_status set etl_telco = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'TAXABILITY' from sbxtax4.tdr_etl_tb_rules);
        elsif ENTITY_NAME_I = 'AUTHORITIES' then
            update tdr_etl_entity_status set etl_telco = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'JURISDICTION' from sbxtax4.tdr_etl_tb_authorities);
        elsif ENTITY_NAME_I = 'PRODUCTS' then
            update tdr_etl_entity_status set etl_telco = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'COMMODITY' from sbxtax4.tdr_etl_ct_product_tree);
        elsif ENTITY_NAME_I = 'REFERENCE GROUP' then
            update tdr_etl_entity_status set etl_telco = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'REFERENCE GROUP' from sbxtax4.tdr_etl_tb_reference_lists);
		elsif ENTITY_NAME_I = 'ADMINISTRATOR' then
            update tdr_etl_entity_status set etl_telco = systimestamp where (nkid, rid, entity) in ( select nkid, rid, 'ADMINISTRATOR' from sbxtax4.extract_log);
        END IF;
    END IF;

END;

END TDR_ETL_LIB;
/