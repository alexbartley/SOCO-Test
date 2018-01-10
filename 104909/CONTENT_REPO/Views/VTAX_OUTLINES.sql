CREATE OR REPLACE FORCE VIEW content_repo.vtax_outlines ("ID",nkid,rid,next_rid,juris_tax_id,juris_tax_rid,juris_tax_nkid,juris_tax_next_rid,calculation_structure_id,tax_structure_type_id,start_date,end_date,outline_status,status_modified_date,entered_by,entered_date,is_current) AS
SELECT
    ta.id,
    ta.nkid,
    ta.rid,
    ta.next_rid,
    ti.id,
    jt.id,
    jt.nkid,
    jt.next_rid,
    ta.calculation_structure_id,
    TCS.TAX_STRUCTURE_TYPE_ID,
    TO_CHAR (ta.start_date, 'mm/dd/yyyy') start_date,
    TO_CHAR (ta.end_date, 'mm/dd/yyyy')   end_date,
    ta.status,
    ta.status_modified_date,
    ta.entered_by,
    ta.entered_date,
    is_current(ta.rid,jt.next_rid,ta.next_rid) is_current
FROM
    tax_outlines ta
JOIN
    vtax_ids ti
ON
    (
        ti.id = ta.juris_tax_imposition_id)
JOIN
    jurisdiction_tax_revisions jt
    --ON (jt.nkid = ti.nkid AND jt.id >= ta.rid)
ON
    (
        jt.nkid = ti.nkid
         AND rev_join(ta.rid,jt.id,ta.next_rid) = 1
    )
    --and rev_join(ta.rid,jt.id,ta.next_rid) = 1)
JOIN
    VTAX_CALC_STRUCTURES TCS
ON
    (
        TA.CALCULATION_STRUCTURE_ID = TCS.TAX_CALC_STRUCTURE_ID)
    /*
    entity_rid_i >= record_rid_i
    AND entity_rid_i < nvl(record_next_rid_i, 999999999999)*/
 
 ;