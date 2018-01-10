CREATE OR REPLACE PACKAGE content_repo.publish
  IS
    TYPE rid_list IS TABLE OF NUMBER;

   FUNCTION administrators(
        published_by_i IN NUMBER,
        publishId in number default crapp_admin.pk_action_log_process_id.nextval
        ) RETURN NUMBER;

   FUNCTION jurisdictions(
        published_by_i IN NUMBER,
        publishId in number default crapp_admin.pk_action_log_process_id.nextval
        ) RETURN NUMBER;

   FUNCTION taxes(
        published_by_i IN NUMBER,
        publishId in number default crapp_admin.pk_action_log_process_id.nextval
        ) RETURN NUMBER;

   FUNCTION taxabilities(
        published_by_i IN NUMBER,
        publishId in number default crapp_admin.pk_action_log_process_id.nextval
        ) RETURN NUMBER;

   FUNCTION commodities(
        published_by_i IN NUMBER,
        publishId in number default crapp_admin.pk_action_log_process_id.nextval
        ) RETURN NUMBER;

   FUNCTION reference_groups(
        published_by_i IN NUMBER,
        publishId in number default crapp_admin.pk_action_log_process_id.nextval
        ) RETURN NUMBER;

    -- Changes for CRAPP-2871
   FUNCTION jurisdiction_types(
        published_by_i IN NUMBER,
        publishId in number default 0
        ) RETURN NUMBER;

   FUNCTION administrator_revision(rid_i NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER;
   FUNCTION jurisdiction_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER;
   -- CRAPP-2871
   FUNCTION jurisdiction_type_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number default 0) RETURN NUMBER;
   FUNCTION tax_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER;
   FUNCTION taxability_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER;
   FUNCTION commodity_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER;
   --FUNCTION commodity_group_revision(rid_i NUMBER, published_by_i IN NUMBER) RETURN NUMBER;
   FUNCTION reference_group_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER;

   PROCEDURE unpublished_entity_tags;
   PROCEDURE publish_lookups;

END publish;
/