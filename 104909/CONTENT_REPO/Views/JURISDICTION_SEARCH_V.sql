CREATE OR REPLACE FORCE VIEW content_repo.jurisdiction_search_v ("ID",nkid,rid,next_rid,juris_entity_rid,juris_next_rid,official_name,description,location_category_id,location_category,currency,currency_id,start_date,end_date,status,status_modified_date,entered_by,entered_date,default_admin_id,default_admin_name,default_admin_collects_tax,transaction_type_id,taxation_type_id,spec_applicability_type_id,tag_id) AS
SELECT vj."ID",
        vj."NKID",
        vj."RID",
        vj."NEXT_RID",
        vj."JURIS_ENTITY_RID",
        vj."JURIS_NEXT_RID",
        vj."OFFICIAL_NAME",
        vj."DESCRIPTION",
        vj."LOCATION_CATEGORY_ID",
        vj."LOCATION_CATEGORY",
        vj."CURRENCY",
        vj."CURRENCY_ID",
        vj."START_DATE",
        vj."END_DATE",
        vj."STATUS",
        vj."STATUS_MODIFIED_DATE",
        vj."ENTERED_BY",
        vj."ENTERED_DATE",
        vj."DEFAULT_ADMIN_ID",
        vj."DEFAULT_ADMIN_NAME",
        vj."DEFAULT_ADMIN_COLLECTS_TAX",
        vtd.transaction_type_id,
        vtd.taxation_type_id,
        vtd.spec_applicability_type_id,
        vjt.tag_id
   FROM vjurisdictions vj
        LEFT JOIN vjuris_tax_descriptions vjtd
            ON vjtd.juris_rid = vj.rid
        LEFT JOIN vtax_descriptions vtd
            ON vjtd.tax_description_id = vtd.id
        LEFT JOIN vjurisdiction_tags vjt
            ON vj.nkid = vjt.juris_nkid;