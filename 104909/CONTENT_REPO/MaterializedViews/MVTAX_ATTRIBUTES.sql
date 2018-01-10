CREATE MATERIALIZED VIEW content_repo.mvtax_attributes ("ID",nkid,rid,next_rid,juris_tax_id,juris_tax_nkid,juris_tax_rid,juris_tax_next_rid,attribute_id,attribute_category_id,attribute_category,attribute_name,"VALUE",start_date,end_date,status,status_modified_date,entered_by,entered_date) 
TABLESPACE content_repo
AS SELECT ta.id,
          ta.nkid,
          ta.rid,
          ta.next_rid,
          ti.id,
          jt.nkid,
          jt.id,
          jt.next_rid,
          ta.attribute_id,
          ac.id,
          ac.name,
          aa.name,
          ta.VALUE,
          TO_CHAR (ta.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (ta.end_date, 'mm/dd/yyyy') end_date,
          ta.status,
          ta.status_modified_date,
          ta.entered_by,
          ta.entered_date
     FROM tax_attributes ta
          JOIN mv_juris_tax_impositions ti
             ON (ti.id = ta.juris_tax_imposition_id)
          JOIN mv_jurisdiction_tax_revisions jt
             ON (    jt.nkid = ti.nkid
                 AND jt.id >= ta.rid
                 AND jt.id < NVL (ta.next_rid, 99999999)
           )
          JOIN content_repo.additional_attributes aa
             ON (Aa.id = ta.attribute_id)
          JOIN content_repo.attribute_categories ac
             ON (Ac.id = aa.attribute_category_id);