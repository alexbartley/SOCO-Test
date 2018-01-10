CREATE OR REPLACE PROCEDURE content_repo.datacheck_dup_taxes
is
vcnt number;
begin

select count(1) into vcnt from (
select a.juris_tax_id, b.juris_tax_id, a.start_date, a.end_date, b.start_date, b.end_date
from kpmg_ext_juris_taxes a join kpmg_ext_juris_taxes b
on ( a.juris_tax_id = b.juris_tax_id )
where a.reference_code = b.reference_code
  and a.tax_structure = b.tax_structure
  and to_date(a.start_date,'mm/dd/yyyy')
        between to_date(b.start_date,'mm/dd/yyyy') and nvl(to_date(b.end_date,'mm/dd/yyyy'), '31-Dec-9999')
  and to_date(a.end_date,'mm/dd/yyyy') between to_date(b.start_date,'mm/dd/yyyy')
                and nvl(to_date(b.end_date,'mm/dd/yyyy'), '31-Dec-9999')
  and a.start_date != b.start_date
);

    if vcnt > 0
    then
        dbms_output.put_line('There exists few duplicate taxes that fall in the same data range');
        raise_application_error (-20201, 'datacheck_dup_taxes data check failed, please correct the data');
    else
         dbms_output.put_line('There are no dates overlapping of taxes');
    end if;

end;
/