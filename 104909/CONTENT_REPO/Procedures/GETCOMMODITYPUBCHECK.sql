CREATE OR REPLACE PROCEDURE content_repo.getcommoditypubcheck( pCommodityId IN number, oErr out number, publishId in number default crapp_admin.pk_action_log_process_id.nextval)
/******************************************************************************/
/* Commodity tree publish check
/* CONCEPT to be added to package PUBLISH
/*
/* 20170602 tnn - Create.
/*                oErr - status flag (UI fail and data will be in the log)
/*                Thought behind this was to pass JSON back to UI. This changed
/*                to only show information in Admin Log.
/*
/******************************************************************************/
is
    l_err number:=0;
    l_nkid number;
    l_rid number;
    l_prodtree number;
    l_ui_comm_link varchar2(2000);
  begin
    --dbms_lob.createtemporary( l_rv, true, dbms_lob.call );
    -- Q/D product tree
    Select product_tree_id into l_prodtree from commodities
    where id = pCommodityId;

    for r_dept in (
        With sx1 as
        (
        SELECT
         id commodity_id,
         rid,
         next_rid,
         nkid,
         product_tree_id,
         trim(h_code) h_code,
         trim(regexp_replace(h_code,
         '[^.]+.',' ',
         1,regexp_count(h_code,'[^.]+')) ) parent_h_code,
         trim(h_code) child_h_code,
         regexp_count(h_code,'[^.]+') level_id,
         name,
         description,
         commodity_code,
         entered_by,
         entered_date,
         status,
         status_modified_date,
         start_date,
         end_date
        FROM commodities
        where product_tree_id = l_prodtree
         and next_rid is null
         )
        ,sx2 as
        (
        SELECT
          decode(ca.status,0,'Pending',1,'Locked',2,'Published',3,'Deprecated','---') txt_status,
        LEVEL c_level
        , status o_status
        , level_id h_code_level
        , LPAD('  ',4 * (LEVEL_ID-1) ) || ca.NAME commodity_name
        , ca.NAME o_commodity_name
        , ca.parent_h_code
        , ca.CHILD_H_CODE
        , commodity_id
        , ca.nkid CommodityNkid
        , ca.start_date
        , ca.end_date
        , ca.commodity_code
        , ca.product_tree_id
        , ca.status_modified_date
        --, substr(SYS_CONNECT_BY_PATH(ca.NAME, ','),2) || ',' Path
        FROM sx1 ca
        where ca.product_tree_id = l_prodtree
        Start with ca.commodity_id = pCommodityID
        CONNECT BY PRIOR ca.parent_h_code = ca.child_h_code
        ORDER SIBLINGS BY ca.CHILD_h_code
        )
        -- Either a single output or a rollup.
        Select
          commodity_id                        id
        , CommodityNkid                       nkid
        , h_code_level                        rorder
        , commodity_name                      name
        , commodity_code                      commodity_code
        , product_tree_id                     prod_tree
        , status_modified_date                stmod
        , o_status                            status
        , decode(o_status,2,1,3,1,0)          validCid
        , start_date
        , end_date
        From sx2
        where commodity_id <> pCommodityID
        order by h_code_level)
        loop
        /*********************************************************************/
        /* If JSON is required, add items using tdr_json library
        /* This only exist in DEV for now
        /*********************************************************************/
        /*l_jv :=
        dev_tdr_json.add_item( l_jv
              , dev_tdr_json.json( 'id', dev_tdr_json.jv( r_dept.id )
              , 'nkid', dev_tdr_json.jv( r_dept.nkid )
              , 'name', dev_tdr_json.jv( r_dept.name )
              , 'commodityCode', dev_tdr_json.jv( r_dept.commodity_code )
              , 'startDate', dev_tdr_json.jv(r_dept.start_date, l_date_format )
              , 'endDate', dev_tdr_json.jv(r_dept.end_date, l_date_format )
              , 'status', dev_tdr_json.jv(r_dept.status )
              , 'valid', dev_tdr_json.jv(r_dept.validCid )
            ));
            l_rv := dev_tdr_json.stringify( l_jv );
        */

        IF (r_dept.validCid = 0) then
            -- Add to collection for bulk insert to LOG
            /* Todo: Action Log Url does not contain a URL for Commodities
            /* Using Taxability URL with a change of the entity id for now */
            DBMS_OUTPUT.Put_Line( 'Log'||r_dept.id||' '||r_dept.name );
            Select nkid, rid into l_nkid, l_rid from commodities where id = r_dept.id;

            Select replace(replace(replace(url, 'nkid', l_nkid), 'rid',l_rid),'/4/','/5/')
              into l_ui_comm_link
              from action_log_url where entity = 'TAXABILITY_DEP' and action = 'TAXABILITY_URL';
              l_ui_comm_link := '{"process":"publication","entity":"''commodity''","entity_change_log":"'||l_ui_comm_link||'","Error Unpublished Commodity Parent":"'||r_dept.name||'"}';
            Insert into crapp_admin.action_log ( action_start, action_end, status, referrer, entered_by, parameters, process_id)
            Values (sysdate, sysdate, -1, '/admin/publication', -1703, l_ui_comm_link, publishId);

            l_err:=1;
        END IF;
    end loop;
    -- dev_tdr_json.free;

    oErr := l_Err;

end getCommodityPubCheck;
/