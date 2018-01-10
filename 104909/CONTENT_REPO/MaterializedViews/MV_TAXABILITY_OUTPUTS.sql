CREATE MATERIALIZED VIEW content_repo.mv_taxability_outputs ("ID",juris_tax_applicability_id,short_text,full_text,entered_by,status,entered_date,status_modified_date,rid,next_rid,nkid,juris_tax_applicability_nkid,tax_applicability_tax_id,tax_applicability_tax_nkid,start_date,end_date) 
TABLESPACE content_repo
AS SELECT DISTINCT tou.*
      FROM (SELECT DISTINCT nkid, MAX (id) id
              FROM mv_juris_tax_app_revisions
            GROUP BY nkid) jtr,
           mv_juris_tax_applicabilities jta,
           taxability_outputs tou
     WHERE     jtr.nkid = jta.nkid
           AND jta.nkid = tou.juris_tax_applicability_nkid
           AND tou.rid <= jtr.id;