CREATE OR REPLACE FORCE VIEW content_repo.vtax_relationships ("ID",jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,related_jurisdiction_id,related_jurisdiction_nkid,this_jurisdiction_id,this_juris_nkid,this_jurisdiction_name,this_jurisdiction_rid,relationship_type,related_juris_id,related_juris_nkid,related_jurisdiction_name,basis_percent,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT DISTINCT 
          tr.id
          -- UI required columns --
          , j.id    jurisdiction_id
          , j.nkid  jurisdiction_nkid
          , jr.id   jurisdiction_rid --,tr.jurisdiction_rid     
          , tr.related_jurisdiction_id
          , tr.related_jurisdiction_nkid          
          -- End UI column list
          , j.id                         this_jurisdiction_id
          , j.nkid                       this_juris_nkid
          , j.official_name              this_jurisdiction_name
          , tr.jurisdiction_rid          this_jurisdiction_rid
          , tr.relationship_type
          , j_related.id   related_juris_id
          , j_related.nkid related_juris_nkid
          , j_related.official_name      related_jurisdiction_name
          , tr.basis_percent
          , tr.start_date
          , tr.end_date
          , tr.status
          , tr.status_modified_date
          , tr.entered_by
          , tr.entered_date
     FROM tax_relationships tr
          JOIN jurisdictions j ON (tr.jurisdiction_nkid = j.nkid )
          JOIN jurisdiction_revisions jr on (  jr.nkid = j.nkid AND jr.id >= j.rid AND jr.id < NVL (j.next_rid, 999999999))
          LEFT JOIN jurisdictions j_related ON (tr.related_jurisdiction_id = j_related.id)
union 
SELECT DISTINCT 
          tr.id
          -- UI required columns --
          , j_related.id    jurisdiction_id
          , j_related.nkid  jurisdiction_nkid
          , jr.id   jurisdiction_rid --,tr.jurisdiction_rid     
          , j.id
          , j.nkid
          -- End UI column list
          , j_related.id                         this_jurisdiction_id
          , j_related.nkid                       this_juris_nkid
          , j_related.official_name              this_jurisdiction_name
          , tr.jurisdiction_rid          this_jurisdiction_rid
          , 'CONTRIBUTING TO'
          , j.id   related_juris_id
          , j.nkid related_juris_nkid
          , j.official_name      related_jurisdiction_name
          , tr.basis_percent
          , tr.start_date
          , tr.end_date
          , tr.status
          , tr.status_modified_date
          , tr.entered_by
          , tr.entered_date
     FROM tax_relationships tr
          JOIN jurisdictions j_related ON (tr.related_jurisdiction_nkid = j_related.nkid )
          JOIN jurisdiction_revisions jr on (  jr.nkid = j_related.nkid AND jr.id >= j_related.rid AND jr.id < NVL (j_related.next_rid, 999999999))
          LEFT JOIN jurisdictions j ON (tr.jurisdiction_nkid = j.nkid);