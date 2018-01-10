CREATE OR REPLACE FORCE VIEW content_repo.vadministrator_taxes ("ID",nkid,rid,next_rid,admin_id,admin_nkid,admin_rid,admin_next_rid,juris_tax_id,juris_tax_nkid,juris_tax_rid,jurisdiction_rid,jurisdiction_nkid,jurisdiction_next_rid,administrator_name,jurisdiction_name,reference_code,start_date,end_date,juris_tax_next_rid,"VALUE",value_type,status,status_modified_date,entered_by,entered_date) AS
SELECT ta.id,
          ta.nkid,
          ta.rid,
          ta.next_rid,
          ad.id,
          ad.nkid,
          ad.rid,
          ad.next_rid,
          ti.id,
          ti.nkid,
          jti.rid juris_tax_rid,
          j.rid,
          j.nkid,
          j.next_rid,
          ad.name,
          j.official_name,
          jti.reference_code,
          jti.start_date,
          jti.end_Date,
          jti.next_rid,
          td.value,
          td.value_type,
          ta.status,
          ta.status_modified_date,
          ta.entered_by,
          ta.entered_date
     FROM vadministrators ad
          JOIN tax_administrators ta
             ON (ta.administrator_id = ad.id)
          JOIN vtax_ids ti
             ON (ti.id = ta.juris_tax_imposition_id)
          JOIN juris_tax_impositions jti
             ON (ti.nkid = jti.nkid)
          JOIN tax_outlines tao
             ON (tao.juris_tax_imposition_id = ti.id)
          JOIN tax_definitions td
             ON (td.tax_outline_id = tao.id)
          JOIN vjurisdictions j
             ON (j.id = jti.jurisdiction_id)
 
 
 ;