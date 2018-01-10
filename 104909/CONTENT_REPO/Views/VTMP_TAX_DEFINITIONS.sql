CREATE OR REPLACE FORCE VIEW content_repo.vtmp_tax_definitions ("ID",nkid,rid,next_rid,juris_tax_id,juris_tax_nkid,juris_tax_rid,juris_tax_next_rid,tax_outline_id,tax_outline_nkid,tax_outline_rid,tax_outline_next_rid,start_date,end_date,calculation_structure_id,min_threshold,max_limit,"VALUE",value_type,ref_juris_tax_id,status,status_modified_date,entered_by,entered_date) AS
select td.id, td.nkid, td.rid, td.next_rid,
    jt.id juris_tax_id, jt.nkid juris_tax_nkid, jt.id juris_tax_rid, jt.next_rid juris_tax_next_rid,
    td.tax_outline_id, tao.nkid, tao.rid, tao.next_rid, tao.start_date, tao.end_date,
    tao.calculation_structure_id, td.min_threshold, td.max_limit, td.value, td.value_type,
    td.defer_to_juris_tax_id, td.status, td.status_modified_date, td.entered_by, td.entered_date
from tax_outlines tao
join vtax_ids ti on (ti.id = tao.juris_tax_imposition_id)
join jurisdiction_tax_revisions jt on (
    jt.nkid = ti.nkid
    and jt.id >= tao.rid
    )
join tax_definitions td on (td.tax_outline_id =tao.id)
 
 
 ;