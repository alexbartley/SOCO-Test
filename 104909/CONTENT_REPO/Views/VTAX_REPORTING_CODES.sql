CREATE OR REPLACE FORCE VIEW content_repo.vtax_reporting_codes ("ID",nkid,rid,next_rid,juris_tax_id,juris_tax_nkid,juris_tax_rid,"VALUE",start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT trc.id,
          trc.nkid,
          trc.rid,
          trc.next_rid,
          jts.id juris_tax_id,
          jts.nkid juris_tax_nkid,
          jtr.id juris_tax_rid,
          trc.VALUE,
          trc.start_date,
          trc.end_date,
          trc.status,
          trc.status_modified_date,
          trc.entered_By,
          trc.entered_date
     FROM jurisdiction_tax_revisions jtr
          JOIN juris_tax_impositions jts
             ON (jtr.nkid = jts.nkid)
          JOIN tax_attributes trc
             ON (    trc.juris_tax_imposition_id = jts.id
                 AND jtr.id >= trc.rid
                 AND jtr.id < NVL (trc.next_rid, 99999999))
          JOIN additional_attributes aa
             ON (aa.id = trc.attribute_id AND aa.name = 'Reporting Code')
 
 
 ;