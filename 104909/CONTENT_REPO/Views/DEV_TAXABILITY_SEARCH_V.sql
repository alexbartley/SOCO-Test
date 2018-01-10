CREATE OR REPLACE FORCE VIEW content_repo.dev_taxability_search_v ("ID",reference_code,calculation_method_id,basis_percent,recoverable_percent,recoverable_amount,start_date,end_date,entered_by,entered_date,status,status_modified_date,rid,nkid,next_rid,jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,jurisdiction_official_name,all_taxes_apply,applicability_type_id,charge_type_id,unit_of_measure,ref_rule_order,default_taxability,product_tree_id,commodity_id,commodity_nkid,commodity_rid,commodity_name,commodity_code,h_code,conditions,tax_type,tax_applicabilities,verification,change_count,commodity_tree_id,is_local,legal_statement,canbedeleted,maxstatus) AS
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
   , jta.rid
   , jta.nkid
   , jta.next_rid
   , jta.jurisdiction_id
   , jta.jurisdiction_nkid
   , j.rid jurisdiction_rid
   , j.official_name jurisdiction_official_name
   , jta.all_taxes_apply
   , jta.applicability_type_id
   , jta.charge_type_id --case when jta.related_charge = '1' then 1 when jta.allocated_charges = 1 then 2 else null end 
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
   , (
        SELECT CASE
            WHEN COUNT(*) > 0 THEN 'Y'
            WHEN COUNT(*) <= 0 THEN 'N'
        END
        FROM TRAN_TAX_QUALIFIERS tc
        WHERE tc.juris_tax_applicability_nkid = jta.nkid        -- tc.juris_tax_applicability_id = jta.id -- changed to NKID 04/25/16 dlg
     ) conditions
   , jta.tax_type
   , ta.tax_applicabilities
   , ver.verification
   , vcc.change_count
   , coalesce(jta.product_tree_id, com.product_tree_id) as commodity_tree_id
   , CASE WHEN jta.is_local = 'Y' THEN 1 ELSE 0 END is_local
   , CASE WHEN attribute_id = 24 AND jtaa.next_rid IS NULL THEN jtaa.VALUE ELSE NULL END legal_statement
   , canBeDeleted
   , sts.maxstatus
FROM juris_tax_applicabilities jta
       
       -- Attributes
       LEFT JOIN juris_tax_app_attributes jtaa
             ON ( jtaa.juris_tax_applicability_nkid = jta.nkid )    -- changed to NKID 04/26/16 dlg
       
       -- Applicable taxes --
       LEFT JOIN (
            select juris_tax_applicability_nkid, listagg(reference_code, ',') within group (order by reference_code) as tax_applicabilities
            from (
                select distinct jti.reference_code, tat.juris_tax_applicability_nkid
                from tax_applicability_taxes tat
                JOIN juris_tax_impositions jti on jti.id = tat.juris_tax_imposition_id
            ) 
            group by (
                juris_tax_applicability_nkid
            )
       ) ta on ta.juris_tax_applicability_nkid = jta.nkid
       
       -- Jurisdiction --
       LEFT JOIN jurisdictions j on j.nkid = jta.jurisdiction_nkid and j.next_rid is null
       
       -- Commodity --
       LEFT JOIN commodities com on com.id = jta.commodity_id
       
       -- Taxability verification
       LEFT JOIN                     -- change after new data load - 04/25/16 dlg
       (SELECT jtacv.rid,
               CASE MIN(ast.ui_order)
                   WHEN 1 THEN 'R1'
                   WHEN 2 THEN 'R2'
                   WHEN 4 THEN 'FR'
                   ELSE 'Pending'
               END
                   AS verification
          FROM juris_tax_app_chg_vlds jtacv
               JOIN assignment_types ast ON ast.id = jtacv.assignment_type_id
        GROUP BY jtacv.rid) ver
           ON (ver.rid = jta.rid
            AND jta.next_rid IS NULL -- change after new data load - 04/25/16 dlg
            AND jta.status <> 2)     -- change after new data load - 04/25/16 dlg
       
-- Taxability change count
       -- Allow to delete
       -- This might have to change to nkid and additional flags for collections
        /*JOIN (SELECT rid, COUNT (*) change_count
               FROM (SELECT * FROM juris_tax_app_chg_logs)
             GROUP BY rid) vcc
           ON vcc.rid = jta.rid
        */   
        JOIN (Select lg.rid,
              case when
              max(rev.status) over (partition by lg.rid) > 0 then 0 else 1 end canBeDeleted,
              rev.status,
              COUNT (*) change_count
              FROM juris_tax_app_chg_logs lg
              join juris_tax_app_revisions rev on (lg.rid = rev.id)
              GROUP BY lg.rid, rev.status ) vcc
           ON (vcc.rid = jta.rid)

        -- 04/30/16 --
        JOIN (SELECT rid
                     ,MAX(status) over (partition by lg.rid) maxstatus
              FROM juris_tax_app_chg_logs lg
             ) sts
           ON (sts.rid = jta.rid);