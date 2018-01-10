CREATE MATERIALIZED VIEW content_repo.mvtax_definitions2 ("ID",nkid,rid,next_rid,juris_tax_id,juris_tax_nkid,juris_tax_rid,juris_tax_next_rid,tax_outline_id,tax_outline_nkid,tax_outline_rid,tax_outline_next_rid,min_threshold,max_limit,"VALUE",currency_id,value_type,ref_juris_tax_id,definition_status,status_modified_date,entered_by,entered_date,is_current) 
TABLESPACE content_repo
AS SELECT td.id,
           td.nkid,
           td.rid,
           td.next_rid,
           jti.id,
           jtr.nkid,
           jtr.id,
           jtr.next_rid,
           tou.id,
           tou.nkid,
           tou.rid,
           tou.next_rid,
           td.min_threshold,
           td.max_limit,
           td.VALUE,
           td.currency_id,
           td.value_type,
           td.defer_to_juris_tax_id,
           td.status definition_status,
           td.status_modified_date,
           td.entered_by,
           td.entered_date,
           is_current (td.rid, jtr.next_rid, td.next_rid) is_current
      FROM jurisdiction_tax_revisions jtr, mv_juris_tax_impositions jti, tax_outlines tou, tax_definitions td
     WHERE jti.nkid = jtr.nkid
       AND tou.juris_tax_imposition_id = jti.id
       AND (td.tax_outline_id = tou.id AND rev_join (td.rid, jtr.id, td.next_rid) = 1);