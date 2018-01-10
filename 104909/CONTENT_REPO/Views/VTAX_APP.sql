CREATE OR REPLACE FORCE VIEW content_repo.vtax_app (reference_code,tax_app_rid) AS
SELECT jta.reference_code,
          jtar.id tax_app_rid
     FROM juris_tax_applicabilities jta
          JOIN
             juris_tax_app_revisions jtar
          ON jtar.id = jta.rid;