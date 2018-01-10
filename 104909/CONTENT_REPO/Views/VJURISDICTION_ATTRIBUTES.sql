CREATE OR REPLACE FORCE VIEW content_repo.vjurisdiction_attributes ("ID",nkid,rid,next_rid,juris_id,juris_nkid,juris_rid,juris_next_rid,attribute_category,attribute_category_id,"VALUE",value_id,attribute_name,attribute_id,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT ja.id,
          ja.nkid,
          ja.rid,
          ja.next_rid,
          ji.id juris_id,
          ji.nkid juris_nkid,
          r.id juris_entity_rid,
          r.next_rid,
          ac.name,
          ac.id,
          -- CRAPP-1973
          CASE WHEN ja.attribute_id = fnjurisattribadmin(pn=> 1)
               then fnlookupadminbyid(pid=> value)
          else
               ja.value
          END value,
          CASE WHEN ja.attribute_id = fnjurisattribadmin(pn=> 1)
               then ja.value
          else
               null
          END value_id,
          aa.name,
          aa.id,
          TO_CHAR (ja.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (ja.end_date, 'mm/dd/yyyy') end_date,
          ja.status,
          ja.status_modified_date,
          ja.entered_by,
          ja.entered_date
     FROM jurisdiction_attributes ja
        JOIN vjuris_ids ji ON (
            ji.id = ja.jurisdiction_id
        )
        JOIN jurisdiction_revisions r ON (
            r.nkid = ji.nkid
            and rev_join(ja.rid,r.id,COALESCE(ja.next_rid,99999999)) = 1
            )
          JOIN additional_attributes aa
             ON (aa.id = ja.attribute_id)
          JOIN attribute_categories ac
             ON (ac.id = aa.attribute_category_id)
 
 ;