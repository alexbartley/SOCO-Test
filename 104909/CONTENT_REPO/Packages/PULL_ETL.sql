CREATE OR REPLACE PACKAGE content_repo.pull_etl
is
    procedure pull_authorities(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2);
    procedure pull_taxes(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2);
    procedure pull_commodities(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2);
    procedure pull_taxabilities(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2);
    procedure pull_reference_groups(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2);
    procedure pull_administrators(tag_group_i varchar2, entity_name_i varchar2, schema_name_i varchar2);
    procedure set_etl_log(process_id_i number, entity_i varchar2, status_i number, log_id out number, tag_group_i varchar2, stag_or_prod varchar2, tag_instance_i varchar2);
    procedure update_etl_log(log_id number, status_i number);
    procedure clean_tmp_extract;
    procedure refresh_comm4taxabilities(schema_name_i varchar2);
    procedure refresh_refgrps4taxabilities(schema_name_i varchar2);
end;
/