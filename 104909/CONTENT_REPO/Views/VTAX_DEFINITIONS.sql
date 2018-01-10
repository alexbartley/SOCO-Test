CREATE OR REPLACE FORCE VIEW content_repo.vtax_definitions ("ID",nkid,rid,next_rid,juris_tax_id,juris_tax_nkid,juris_tax_rid,juris_tax_next_rid,tax_outline_id,tax_outline_nkid,tax_outline_rid,tax_outline_next_rid,start_date,end_date,calculation_structure_id,outline_status,tax_structure_type_id,min_threshold,max_limit,"VALUE",value_type,ref_juris_tax_id,definition_status,status_modified_date,entered_by,entered_date) AS
SELECT td.id,
          td.nkid,
          td.rid,
          td.next_rid,
          ti.id juris_tax_id,
          jt.nkid juris_tax_nkid,
          jt.id juris_tax_rid,
          jt.next_rid juris_tax_next_rid,
          td.tax_outline_id,
          tao.nkid,
          tao.rid,
          tao.next_rid,
          tao.start_date,
          tao.end_date,
          tao.calculation_structure_id,
          tao.status outline_status,
          TCS.TAX_STRUCTURE_TYPE_ID,
          td.min_threshold,
          td.max_limit,
          td.VALUE,
          td.value_type,
          td.defer_to_juris_tax_id,
          td.status definition_status,
          td.status_modified_date,
          td.entered_by,
          td.entered_date
     FROM tax_outlines tao
          JOIN vtax_ids ti
             ON (ti.id = tao.juris_tax_imposition_id)
          JOIN jurisdiction_tax_revisions jt
             ON (jt.nkid = ti.nkid AND jt.id >= tao.rid)
          JOIN vtax_outline_ids toi
             ON (toi.nkid = tao.nkid)
          JOIN tax_definitions td
             ON (td.tax_outline_id = toi.id AND tao.rid >= jt.id)
          JOIN VTAX_CALC_STRUCTURES TCS
             ON (TAO.CALCULATION_STRUCTURE_ID = TCS.TAX_CALC_STRUCTURE_ID)
 
 
 ;