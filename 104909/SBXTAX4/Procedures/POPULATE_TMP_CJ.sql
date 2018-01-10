CREATE OR REPLACE PROCEDURE sbxtax4."POPULATE_TMP_CJ" 
    (startDate IN Date)
   IS
BEGIN

    INSERT INTO tmp_cj (table_name, primary_key, operation_date) (
    select distinct table_name, primary_key, min(operation_date) operation_date
    from tb_content_journal cj
    where operation_date > startDate 
    and not exists (
        select 1
        from tb_content_journal cj2
        where cj2.table_name = cj.table_name
        and cj2.primary_key = cj.primary_key
        and cj2.operation_date > startDate
        and operation = 'A'
    and exists (
        select 1
        from tb_content_journal cj3
        where cj3.table_name = cj2.table_name
        and cj3.primary_key = cj2.primary_key
        and cj3.operation_date > cj2.operation_Date
        and operation = 'D'        
        )
    )
    group by table_name, primary_key);
    COMMIT;
END;
 
 
 
/