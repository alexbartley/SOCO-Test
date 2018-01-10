CREATE INDEX content_repo.tax_definitions_j1 ON content_repo.tax_definitions(tax_outline_id)

TABLESPACE content_repo PARALLEL 4;