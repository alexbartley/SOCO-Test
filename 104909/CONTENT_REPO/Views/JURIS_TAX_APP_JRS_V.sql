CREATE OR REPLACE FORCE VIEW content_repo.juris_tax_app_jrs_v ("ID",nkid,rid,jta_next_rid,jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,official_name,reference_code,start_date,end_date,status,status_modified_date,entered_by,entered_date,all_taxes_apply,is_current) AS
(SELECT jta.id id,
          jta.nkid nkid,
          jta.rid rid,
          jta.next_rid jta_next_rid,
          j.id jurisdiction_id,
          j.nkid jurisdiction_nkid,
          j.rid jurisdiction_rid,
          j2.official_name,
          jta.reference_code,
          jta.start_date,
          jta.end_date,
          jta.status,
          jta.status_modified_date,
          jta.entered_by,
          jta.entered_date,
          jta.all_taxes_apply,
          is_current (jta.rid, r.next_rid, jta.next_rid) is_current
     FROM JURIS_TAX_APP_REVISIONS r
          JOIN JURIS_TAX_APPLICABILITIES jta
             ON (    r.nkid = jta.nkid
                 AND rev_join (jta.rid,
                               r.id,
                               COALESCE (jta.next_rid, 9999999999)) = 1)
          INNER JOIN JURISDICTIONS J
             ON JTA.JURISDICTION_ID = J.ID
          INNER JOIN JURISDICTIONS J2
             ON J.NKID = J2.NKID
    WHERE J2.NEXT_RID IS NULL
)
 
 ;