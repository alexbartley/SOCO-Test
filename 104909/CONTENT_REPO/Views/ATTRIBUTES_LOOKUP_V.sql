CREATE OR REPLACE FORCE VIEW content_repo.attributes_lookup_v (catid,catname,attrid,attrname) AS
(
-- Temp dev attributes lookup view for taxability
-- extend VATTRIBUTE_LOOKUPS?
SELECT
 acat.id catId
,acat.NAME catName
,attr.id attrId
,attr.NAME attrName
FROM additional_attributes attr
JOIN attribute_categories acat ON (acat.id = attr.attribute_category_id)
)
 
 
 ;