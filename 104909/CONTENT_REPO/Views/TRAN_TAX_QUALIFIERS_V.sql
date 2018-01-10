CREATE OR REPLACE FORCE VIEW content_repo.tran_tax_qualifiers_v ("ID",nkid,rid,next_rid,entity_rid,entity_nkid,entity_next_rid,juris_tax_applicability_id,taxability_element_id,logical_qualifier,"VALUE",jurisdiction_id,start_date,end_date,status,status_modified_date,entered_by,entered_date,is_current) AS
SELECT ttq.id,
          ttq.nkid,
          ttq.rid,
          ttq.next_rid,
          tis.entity_rid,
          tis.entity_nkid,
          tis.entity_next_rid,
          ttq.juris_tax_applicability_id,
          ttq.taxability_element_id,
          ttq.logical_qualifier,
          ttq.value,
          ttq.jurisdiction_id,
          TO_CHAR (ttq.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (ttq.end_date, 'mm/dd/yyyy') end_date,
          ttq.status,
          ttq.status_modified_date,
          ttq.entered_by,
          ttq.entered_date,
          is_current(ttq.rid,tis.entity_next_rid,ttq.next_rid) is_current
     FROM tran_tax_qual_id_sets tis
          JOIN tran_tax_qualifiers ttq
             ON (  ttq.id = tis.id);