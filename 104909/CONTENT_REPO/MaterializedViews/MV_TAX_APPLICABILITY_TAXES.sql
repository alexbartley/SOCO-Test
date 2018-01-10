CREATE MATERIALIZED VIEW content_repo.mv_tax_applicability_taxes ("ID",juris_tax_imposition_id,start_date,end_date,nkid,rid,entered_by,status,status_modified_date,entered_date,next_rid,juris_tax_applicability_id,juris_tax_applicability_nkid,juris_tax_imposition_nkid,ref_rule_order,tax_type,tax_type_id) 
TABLESPACE content_repo
AS SELECT tat.*
      FROM (SELECT DISTINCT nkid, MAX (id) id
              FROM mv_juris_tax_app_revisions
            GROUP BY nkid) jtr,
           mv_juris_tax_applicabilities jta,
           tax_applicability_taxes tat
     WHERE     jtr.nkid = jta.nkid
           AND jta.nkid = tat.juris_tax_applicability_nkid
           AND tat.rid <= jtr.id;