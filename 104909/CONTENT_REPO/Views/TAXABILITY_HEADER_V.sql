CREATE OR REPLACE FORCE VIEW content_repo.taxability_header_v ("ID",reference_code,calculation_method_id,basis_percent,recoverable_percent,recoverable_amount,start_date,end_date,entered_by,entered_date,status,status_modified_date,rid,nkid,next_rid,jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,jurisdiction_official_name,all_taxes_apply,applicability_type_id,charge_type_id,unit_of_measure,ref_rule_order,default_taxability,product_tree_id,commodity_id,commodity_nkid,commodity_rid,commodity_name,commodity_code,h_code,conditions,tax_type,tax_applicabilities,verification,change_count,commodity_tree_id,is_local,legal_statement,canbedeleted,maxstatus,processing_order,verifylist) AS
SELECT
     jta.id
   , jta.reference_code
   , jta.calculation_method_id
   , jta.basis_percent
   , jta.recoverable_percent
   , jta.recoverable_amount
   , jta.start_date
   , jta.end_date
   , jta.entered_by
   , jta.entered_date
   , jta.status
   , jta.status_modified_date
   , r.id   rid
   , r.nkid
   , r.next_rid
   , jta.jurisdiction_id
   , jta.jurisdiction_nkid
   , j.rid jurisdiction_rid
   , j.official_name jurisdiction_official_name
   , jta.all_taxes_apply
   , jta.applicability_type_id
   , charge_type_id
   , jta.unit_of_measure
   , jta.ref_rule_order
   , CASE WHEN jta.default_taxability = 'D' THEN 1 ELSE 0 END default_taxability
   , jta.product_tree_id
   , jta.commodity_id
   , com.nkid commodity_nkid
   , com.rid commodity_rid
   , com.name commodity_name
   , com.commodity_code
   , com.h_code
   , case when tc.cnt > 0 then 'Y' else 'N' end as conditions 
    -- tc.juris_tax_applicability_id = jta.id -- changed to NKID 04/25/16 dlg
    -- Changed the join query and thus this case steatement for CRAPP-2715
   , jta.tax_type
   , ta.tax_applicabilities
   --, ver.verification
   , fntaxabilityver(r.id) verification -- crapp-2801
   , vcc.change_count
   , coalesce(jta.product_tree_id, com.product_tree_id) as commodity_tree_id
   , CASE WHEN jta.is_local = 'Y' THEN 1 ELSE 0 END is_local
   , jtaa.VALUE legal_statement
   , canBeDeleted
   , sts.maxstatus
   , NULL processing_order  -- crapp-2754
   , vlist.verifylist -- crapp-2801
FROM  juris_tax_app_revisions r
      JOIN juris_tax_applicabilities jta on ( r.nkid = jta.nkid
                                                 AND rev_join (jta.rid,
                                                               r.id,
                                                               COALESCE (jta.next_rid, 9999999999)) = 1)
       -- Attributes
       LEFT JOIN juris_tax_app_attributes jtaa
             ON ( jtaa.juris_tax_applicability_nkid = jta.nkid and jtaa.next_rid is null )    -- changed to NKID 04/26/16 dlg

       -- Applicable taxes --
       LEFT JOIN (
            select juris_tax_applicability_nkid, listagg(reference_code, ',') within group (order by length(reference_code), reference_code) as tax_applicabilities
            from (
                select distinct jti.reference_code, tat.juris_tax_applicability_nkid
                from tax_applicability_taxes tat
                JOIN juris_tax_impositions jti on jti.id = tat.juris_tax_imposition_id

            )
            group by (
                juris_tax_applicability_nkid
            )
       ) ta on ta.juris_tax_applicability_nkid = jta.nkid
       -- Conditions --
       LEFT JOIN ( select count(1) cnt, juris_tax_applicability_nkid from TRAN_TAX_QUALIFIERS tq  
                    -- Changed to fix displaying correct revisions when we have multiple conditions
                    -- where tq.juris_tax_applicability_nkid = r.nkid
                    group by tq.juris_tax_applicability_nkid 
                 )
                 tc on tc.juris_tax_applicability_nkid = jta.nkid
       -- Jurisdiction --
       LEFT JOIN jurisdictions j on j.nkid = jta.jurisdiction_nkid and j.next_rid is null
       -- Commodity --
       LEFT JOIN commodities com on ( com.nkid = jta.commodity_nkid and com.next_rid is null ) -- Modified to get the grid for each revision of commodity. 
       -- With this code, clicking on each commodity revision will show the results of all the revision data instead of specific one. 

       -- Taxability change count
       -- Allow to delete
        JOIN (SELECT lg.rid,
                     CASE WHEN MAX(rev.status) OVER (PARTITION BY lg.rid) > 0 THEN 0 ELSE 1 END canBeDeleted,
                     rev.status,
                     CASE WHEN rev.status = 2 THEN 0 ELSE COUNT(1) END change_count  -- CRAPP-2933                     
                     -- before 2933: COUNT(1) change_count
              FROM juris_tax_app_chg_logs lg
                   JOIN juris_tax_app_revisions rev ON (lg.rid = rev.id)
              GROUP BY lg.rid, rev.status ) vcc ON (vcc.rid = r.id) -- crapp-2714, changed from jta.rid
        JOIN (SELECT rid
                     ,MAX(status) maxstatus
              FROM juris_tax_app_chg_logs lg
             Group by rid) sts
           ON (sts.rid = r.id)
        -- Crapp-2801 - Taxability verification list --        
        LEFT JOIN (
                    SELECT rid
                           , TRIM(LISTAGG(veriftype,', ') WITHIN GROUP (ORDER BY rid)) verifylist
                    FROM (
                         SELECT DISTINCT
                                jtr.id rid
                                , NVL2(vld.assignment_type_id, get_username(vld.assigned_user_id), NULL) veriftype
                                --, NVL(a.ui_order, 0) ui_order
                                --, NVL2(vld.assignment_type_id, fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id), 'Pending') veriftype -- with Verification
                         FROM juris_tax_app_revisions jtr
                              JOIN juris_tax_app_chg_logs jtcl ON jtr.id = jtcl.rid
                              LEFT JOIN juris_tax_app_chg_vlds vld ON (vld.juris_tax_app_chg_log_id = jtcl.id)
                              LEFT JOIN assignment_types a ON vld.assignment_type_id = a.id
                         WHERE jtr.status <> 2 -- exclude published records
                        )
                    GROUP BY rid
                ) vlist ON (r.id = vlist.rid);