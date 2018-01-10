CREATE OR REPLACE FORCE VIEW content_repo.vtax_calc_structures ("ID",tax_calc_structure_id,tax_structure_type_id,tax_structure_code,tax_structure,amount_type_code,amount_type,entered_by,entered_date) AS
SELECT tcs.id,
          tcs.id tax_calc_Structure_id,
          tcs.TAX_STRUCTURE_TYPE_ID,
          ts.name tax_structure_code,
          ts.description tax_structure,
          aty.name amount_type_code,
          aty.description amount_type,
          tcs.entered_by,
          tcs.entered_date
     FROM tax_calculation_structures tcs
          JOIN tax_structure_types ts
             ON (ts.id = tcs.tax_structure_type_id)
          JOIN amount_types aty
             ON (aty.id = tcs.amount_type_id)
 
 
 ;