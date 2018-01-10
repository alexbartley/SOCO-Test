CREATE MATERIALIZED VIEW content_repo.mvtax_outlines ("ID",nkid,rid,next_rid,juris_tax_id,juris_tax_rid,juris_tax_nkid,juris_tax_next_rid,calculation_structure_id,tax_structure_type_id,start_date,end_date,outline_status,status_modified_date,entered_by,entered_date,is_current) 
TABLESPACE content_repo
AS SELECT ta.id,
           ta.nkid,
           ta.rid,
           ta.next_rid,
           ti.id,
           jt.id,
           jt.nkid,
           jt.next_rid,
           ta.calculation_structure_id,
           tcs.tax_structure_type_id,
           TO_CHAR (ta.start_date, 'mm/dd/yyyy') start_date,
           TO_CHAR (ta.end_date, 'mm/dd/yyyy') end_date,
           ta.status,
           ta.status_modified_date,
           ta.entered_by,
           ta.entered_date,
           is_current (ta.rid, jt.next_rid, ta.next_rid) is_current
      FROM mv_tax_outlines ta, mv_juris_tax_impositions ti, jurisdiction_tax_revisions jt, vtax_calc_structures tcs
      WHERE ti.id = ta.juris_tax_imposition_id
        AND (jt.nkid = ti.nkid AND rev_join (ta.rid, jt.id, ta.next_rid) = 1)
        AND ta.calculation_structure_id = tcs.tax_calc_structure_id;