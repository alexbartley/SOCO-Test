CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax_applicabilities ("ID",nkid,rid,juris_nkid,juris_entity_rid,juris_tax_app_next_rid,reference_code,official_name) AS
select jta.id,
          jta.nkid,
          r.id,
          j2.nkid,
          j2.rid,
          r.next_rid,
          jta.reference_code,
          j2.official_name
     from juris_tax_app_revisions r
          join juris_tax_applicabilities jta
             on (    r.nkid = jta.nkid
                 and rev_join (jta.rid,
                               r.id,
                               coalesce (jta.next_rid, 9999999999)) = 1)
          inner join jurisdictions j
             on jta.jurisdiction_id = j.id
          inner join jurisdictions j2
             on j.nkid = j2.nkid
    where j2.next_rid is null;