CREATE OR REPLACE FORCE VIEW content_repo.copy_jta_items_v (process_id,"ID",start_date,end_date,commodity_id,jurisdiction_id,applicability_type_id,commodity_nkid) AS
(SELECT itm.process_id
        , jta.id
        , jta.start_date
        , jta.end_date
        , jta.commodity_id
        , jta.jurisdiction_id
        , jta.applicability_type_id
        , jta.commodity_nkid
  FROM juris_tax_applicabilities jta
       JOIN copy_taxabilities_item itm on (jta.id = itm.juris_tax_applicability_id
  )
);