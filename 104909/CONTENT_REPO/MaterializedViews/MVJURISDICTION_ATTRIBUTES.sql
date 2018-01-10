CREATE MATERIALIZED VIEW content_repo.mvjurisdiction_attributes ("ID",nkid,rid,next_rid,juris_id,juris_nkid,juris_rid,juris_next_rid,attribute_category,attribute_category_id,"VALUE",value_id,attribute_name,attribute_id,start_date,end_date,status,status_modified_date,entered_by,entered_date)
ORGANIZATION HEAP  
TABLESPACE content_repo
LOB ("VALUE") STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
AS SELECT ja.id,
           ja.nkid,
           ja.rid,
           ja.next_rid,
           ji.id juris_id,
           ji.nkid juris_nkid,
           r.id juris_entity_rid,
           r.next_rid,
           ac.name,
           ac.id,
           CASE
               WHEN ja.attribute_id = content_repo.fnjurisattribadmin (pn => 1)
               THEN content_repo.fnlookupadminbyid (pid => VALUE)
               ELSE ja.VALUE 
           END
               VALUE,
           CASE
               WHEN ja.attribute_id = content_repo.fnjurisattribadmin (pn => 1)
               THEN
                   ja.VALUE
               ELSE
                   NULL
           END
               value_id,
           aa.name,
           aa.id,
           TO_CHAR (ja.start_date, 'mm/dd/yyyy') start_date,
           TO_CHAR (ja.end_date, 'mm/dd/yyyy') end_date,
           ja.status,
           ja.status_modified_date,
           ja.entered_by,
           ja.entered_date
      FROM jurisdiction_attributes ja,
           jurisdictions ji,
           jurisdiction_revisions r,
           additional_attributes aa,
           attribute_categories ac,
           tdr_etl_extract_list tel
     WHERE ji.id = ja.jurisdiction_id
       AND tel.nkid = r.nkid and tel.rid = r.id
       AND ( r.nkid = ji.nkid AND rev_join (ja.rid, r.id, COALESCE (ja.next_rid, 99999999)) = 1)
       AND aa.id = ja.attribute_id
       AND ac.id = aa.attribute_category_id;