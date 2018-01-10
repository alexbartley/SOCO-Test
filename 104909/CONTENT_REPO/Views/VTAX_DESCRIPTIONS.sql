CREATE OR REPLACE FORCE VIEW content_repo.vtax_descriptions ("ID",taxation_type_id,taxation_type,transaction_type_id,transaction_type,spec_applicability_type_id,specific_applicability_type,entered_by,entered_date) AS
SELECT ts.id, ts.taxation_type_id, tat.name taxation_type, ts.transaction_type_id, trt.name transaction_type,
    ts.spec_applicability_Type_id, sat.name specific_applicability_type, ts.entered_by, ts.entered_date
FROM tax_descriptions ts
join taxation_types tat on (tat.id = ts.taxation_type_id)
join transaction_types trt on (trt.id = ts.transaction_type_id)
join specific_applicability_types sat on (sat.id = ts.spec_applicability_type_id)
 
 
 ;