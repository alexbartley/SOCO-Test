CREATE OR REPLACE FORCE VIEW content_repo.reference_items_v ("ID",nkid,rid,next_rid,ref_grp_id,ref_grp_nkid,ref_grp_rid,ref_grp_next_rid,"VALUE",value_type,ref_nkid,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT tr.id,
          tr.nkid,
          tr.rid,
          tr.next_rid,
          a.id comm_grp_id,
          a.nkid comm_grp_nkid,
          ar.id comm_grp_rid,
          ar.next_rid,
            value,
            value_type,
            ref_nkid,
          TO_CHAR (tr.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (tr.end_date, 'mm/dd/yyyy') end_date,
          tr.status,
          tr.status_modified_date,
          tr.entered_by,
          tr.entered_date
     FROM reference_items tr
          JOIN reference_groups a
             ON (tr.reference_group_id = a.id)
          JOIN ref_group_revisions ar
             ON (    ar.nkid = a.nkid
                 AND rev_join (tr.rid,
                               ar.id,
                               COALESCE (tr.next_rid, 99999999)) = 1)
 
 
 ;