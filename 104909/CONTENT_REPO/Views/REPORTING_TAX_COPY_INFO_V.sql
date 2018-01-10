CREATE OR REPLACE FORCE VIEW content_repo.reporting_tax_copy_info_v (cpy_from_juris_tax_id,reference_code,cpy_to_jurisdiction,official_name,status,log_id,log_date,section_copied) AS
(select
 cpy_from_juris_tax_id,
 jti.reference_code,
 cpy_to_jurisdiction,
 j.official_name,
 case cpy_status when
 1 then 'Ok'
 when
 2 then 'Definitions copied'
 when
 -1 then 'No Tax Categorization exists'
 when
 0 then 'Tax reference already exists'
 end Status,
 log_id,
 log_date,
 case cpy_section when 1 then 'Taxes copied'
 when 2 then 'Tax Definitions Copied' end Section_Copied
 from tax_copy_log lg
 join juris_tax_impositions jti on (lg.cpy_from_juris_tax_id = jti.id)
 join jurisdictions j on (j.id = lg.cpy_to_jurisdiction)
)
 
 
 ;