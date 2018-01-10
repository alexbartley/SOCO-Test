CREATE OR REPLACE Function content_repo.fn_Review_Report(entity in number, enteredBy in number, dtFrom in date) return review_xtable pipelined is
 -- Decided to keep them one by one, per entity due to different tables instead of one dynamic set.
 -- Tuning showed 'ok' 
 -- Other way of doing it: Cursor crsJuris(pEnteredBy in number, dtFrom in date)

begin
--
-- Administrator
--
if entity = 1 then
for rr in (
With x1 as
(
Select 
 lg.id lg_id
,vld.assigned_by
,vld.assignment_type_id
,lg.status current_status
,lg.primary_key
,lg.table_name
,lg.rid 
,ct.id
,lg.status_modified_date
,lg.status
,ct.citation_id
 from admin_chg_logs lg
 left join admin_chg_vlds vld on (vld.admin_chg_log_id = lg.id)
 left join admin_chg_cits ct on (ct.admin_chg_log_id = lg.id)
 where lg.status_modified_date > dtFrom
)
, x2 as
-- Ranking 0,1,2,3
(Select id,
Case name when
 'Final Review' then 4
 when 'Review 1' then 1
 when 'Review 2' then 2
 when 'Test in Staging' then 3
 else 0 
End ReviewLevel from 
assignment_types) 
, x3 as
(Select 
 x1.assigned_by
,x1.assignment_type_id
,x1.current_status
,x1.primary_key
,x1.table_name
,x1.rid 
,x1.id
,x1.status_modified_date
,x2.id vldtype
,x2.ReviewLevel 
,x1.status
,x1.citation_id
from x1
left join x2 on (x2.id = x1.assignment_type_id)
)
, x4 as
(select 
 rid
,listagg(primary_key,',') within group (order by id) CHGLOGIDS
,MIN(nvl(ReviewLevel,0)) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewMin
,MAX(ReviewLevel) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewLvl  
,Case MIN(nvl(ReviewLevel,0)) KEEP(DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) 
when 1 then 'Review' when 2 then 'Ready for Final' when 3 then 'Staging' when 4 then 'Final' else 'Pending' end LowestReview 
,count(distinct x3.citation_id) CCDOC
from x3
group by rid)
Select distinct 
'Administrator' hcentity,
jta.name
, ' ' CommodityName
, ' ' ref_rule_order
, x4.rid
, x4.CHGLOGIDS
, x4.reviewmin
, x4.reviewlvl
, x4.lowestreview
, rv.status_modified_date
, substr(usr.firstname,1,1)||'.'||usr.lastname LastModifBy
, ccdoc
, listagg(dtgs.name,',') within group (order by x4.rid) OVER (PARTITION BY x4.rid) as enttags 
from x4
join administrators jta on (jta.rid = x4.rid)
join administrator_revisions rv on (rv.id = x4.rid)
join crapp_admin.users usr on (usr.id = rv.entered_by)
left join administrator_tags xtgs on (xtgs.ref_nkid = jta.nkid)
     LEFT OUTER JOIN Tags dtgs ON (dtgs.id = xtgs.tag_id)
where usr.id = enteredby) 
 loop
   pipe row (obj_review_xview(rr.hcentity,
            rr.name,
            rr.CommodityName,
            rr.ref_rule_order,
            rr.rid,
            rr.CHGLOGIDS,
            rr.reviewmin,
            rr.reviewlvl,
            rr.lowestreview,
            to_char(rr.status_modified_date,'MM/DD/YYYY'),
            rr.LastModifBy,
            rr.ccdoc,
            rr.enttags));

 end loop; 
end if; 

--
-- Jurisdiction
--
if entity = 2 then
for rr in (
With x1 as
(
Select 
 lg.id lg_id
,vld.assigned_by
,vld.assignment_type_id
,lg.status current_status
,lg.primary_key
,lg.table_name
,lg.rid 
,ct.id
,lg.status_modified_date
,lg.status
,ct.citation_id
 from juris_chg_logs lg
 left join juris_chg_vlds vld on (vld.juris_chg_log_id = lg.id)
 left join juris_chg_cits ct on (ct.juris_chg_log_id = lg.id)
 where lg.status_modified_date > dtFrom
)
, x2 as
-- Ranking 0,1,2,3
(Select id,
Case name when
 'Final Review' then 4
 when 'Review 1' then 1
 when 'Review 2' then 2
 when 'Test in Staging' then 3
 else 0 
End ReviewLevel from 
assignment_types) 
, x3 as
(Select 
 x1.assigned_by
,x1.assignment_type_id
,x1.current_status
,x1.primary_key
,x1.table_name
,x1.rid 
,x1.id
,x1.status_modified_date
,x2.id vldtype
,x2.ReviewLevel 
,x1.status
,x1.citation_id
from x1
left join x2 on (x2.id = x1.assignment_type_id)
)
, x4 as
(select 
 rid
,listagg(primary_key,',') within group (order by id) CHGLOGIDS
,MIN(nvl(ReviewLevel,0)) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewMin
,MAX(ReviewLevel) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewLvl  
,Case MIN(nvl(ReviewLevel,0)) KEEP(DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) 
when 1 then 'Review' when 2 then 'Ready for Final' when 3 then 'Staging' when 4 then 'Final' else 'Pending' end LowestReview 
,count(distinct x3.citation_id) CCDOC
from x3
group by rid)
Select distinct 
'Jurisdiction' hcentity,
jta.official_name as name
, ' ' CommodityName
, ' ' ref_rule_order
, x4.rid
, x4.CHGLOGIDS
, x4.reviewmin
, x4.reviewlvl
, x4.lowestreview
, rv.status_modified_date
, substr(usr.firstname,1,1)||'.'||usr.lastname LastModifBy
, ccdoc
, listagg(dtgs.name,',') within group (order by x4.rid) OVER (PARTITION BY x4.rid) as enttags 
from x4
join jurisdictions jta on (jta.rid = x4.rid)
join jurisdiction_revisions rv on (rv.id = x4.rid)
join crapp_admin.users usr on (usr.id = rv.entered_by)
left join jurisdiction_tags xtgs on (xtgs.ref_nkid = jta.nkid)
     LEFT OUTER JOIN Tags dtgs ON (dtgs.id = xtgs.tag_id)
where usr.id = enteredby) 
 loop
   pipe row (obj_review_xview(rr.hcentity,
            rr.name,
            rr.CommodityName,
            rr.ref_rule_order,
            rr.rid,
            rr.CHGLOGIDS,
            rr.reviewmin,
            rr.reviewlvl,
            rr.lowestreview,
            to_char(rr.status_modified_date,'MM/DD/YYYY'),
            rr.LastModifBy,
            rr.ccdoc,
            rr.enttags));

 end loop; 
end if; 

--
-- Taxes
--
if entity = 3 then
for rr in (
With x1 as
(
Select 
 lg.id lg_id
,vld.assigned_by
,vld.assignment_type_id
,lg.status current_status
,lg.primary_key
,lg.table_name
,lg.rid 
,ct.id
,lg.status_modified_date
,lg.status
,ct.citation_id
 from juris_tax_chg_logs lg
 left join juris_tax_chg_vlds vld on (vld.juris_tax_chg_log_id = lg.id)
 left join juris_tax_chg_cits ct on (ct.juris_tax_chg_log_id = lg.id)
 where lg.status_modified_date > dtFrom
)
, x2 as
-- Ranking 0,1,2,3
(Select id,
Case name when
 'Final Review' then 4
 when 'Review 1' then 1
 when 'Review 2' then 2
 when 'Test in Staging' then 3
 else 0 
End ReviewLevel from 
assignment_types) 
, x3 as
(Select 
 x1.assigned_by
,x1.assignment_type_id
,x1.current_status
,x1.primary_key
,x1.table_name
,x1.rid 
,x1.id
,x1.status_modified_date
,x2.id vldtype
,x2.ReviewLevel 
,x1.status
,x1.citation_id
from x1
left join x2 on (x2.id = x1.assignment_type_id)
)
, x4 as
(select 
 rid
,listagg(primary_key,',') within group (order by id) CHGLOGIDS
,MIN(nvl(ReviewLevel,0)) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewMin
,MAX(ReviewLevel) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewLvl  
,Case MIN(nvl(ReviewLevel,0)) KEEP(DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) 
when 1 then 'Review' when 2 then 'Ready for Final' when 3 then 'Staging' when 4 then 'Final' else 'Pending' end LowestReview 
,count(distinct x3.citation_id) CCDOC
from x3
group by rid)
Select distinct 
'Taxes' hcentity,
j.official_name as name
, jta.reference_code as CommodityName
, ' ' ref_rule_order
, x4.rid
, x4.CHGLOGIDS
, x4.reviewmin
, x4.reviewlvl
, x4.lowestreview
, rv.status_modified_date
, substr(usr.firstname,1,1)||'.'||usr.lastname LastModifBy
, ccdoc
, listagg(dtgs.name,',') within group (order by x4.rid) OVER (PARTITION BY x4.rid) as enttags 
from x4
join juris_tax_impositions jta on (jta.rid = x4.rid)
join jurisdictions j on (jta.jurisdiction_id = j.id)
join jurisdiction_tax_revisions rv on (rv.id = x4.rid)
join crapp_admin.users usr on (usr.id = rv.entered_by)
left join juris_tax_imposition_tags xtgs on (xtgs.ref_nkid = jta.nkid)
     LEFT OUTER JOIN Tags dtgs ON (dtgs.id = xtgs.tag_id)
where usr.id = enteredby) 
 loop
   pipe row (obj_review_xview(rr.hcentity,
            rr.name,
            rr.CommodityName,
            rr.ref_rule_order,
            rr.rid,
            rr.CHGLOGIDS,
            rr.reviewmin,
            rr.reviewlvl,
            rr.lowestreview,
            to_char(rr.status_modified_date,'MM/DD/YYYY'),
            rr.LastModifBy,
            rr.ccdoc,
            rr.enttags));

 end loop; 
end if; 


--
-- Taxability
--
if entity = 4 then
for rr in (
With x1 as
(
Select 
 lg.id lg_id
,vld.assigned_by
,vld.assignment_type_id
,lg.status current_status
,lg.primary_key
,lg.table_name
,lg.rid 
,ct.id
,lg.status_modified_date
,lg.status
,ct.citation_id
 from juris_tax_app_chg_logs lg
 left join juris_tax_app_chg_vlds vld on (vld.juris_tax_app_chg_log_id = lg.id)
 left join juris_tax_app_chg_cits ct on (ct.juris_tax_app_chg_log_id = lg.id)
 where lg.status_modified_date > dtFrom
)
, x2 as
-- Ranking 0,1,2,3
(Select id,
Case name when
 'Final Review' then 4
 when 'Review 1' then 1
 when 'Review 2' then 2
 when 'Test in Staging' then 3
 else 0 
End ReviewLevel from 
assignment_types) 
, x3 as
(Select 
 x1.assigned_by
,x1.assignment_type_id
,x1.current_status
,x1.primary_key
,x1.table_name
,x1.rid 
,x1.id
,x1.status_modified_date
,x2.id vldtype
,x2.ReviewLevel 
,x1.status
,x1.citation_id
from x1
left join x2 on (x2.id = x1.assignment_type_id)
)
, x4 as
(select 
 rid
,listagg(primary_key,',') within group (order by id) CHGLOGIDS
,MIN(nvl(ReviewLevel,0)) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewMin
,MAX(ReviewLevel) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewLvl  
,Case MIN(nvl(ReviewLevel,0)) KEEP(DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) 
when 1 then 'Review' when 2 then 'Ready for Final' when 3 then 'Staging' when 4 then 'Final' else 'Pending' end LowestReview 
,count(distinct x3.citation_id) CCDOC
from x3
group by rid)
Select distinct
'Taxability' hcentity,
j.official_name
, Case When cc.id is null then 'Applies to all' else cc.name end CommodityName
, to_char(jta.ref_rule_order) ref_rule_order
, x4.rid
, x4.CHGLOGIDS
, x4.reviewmin
, x4.reviewlvl
, x4.lowestreview
, rv.status_modified_date
, substr(usr.firstname,1,1)||'.'||usr.lastname LastModifBy
, ccdoc
, listagg(dtgs.name,',') within group (order by x4.rid) OVER (PARTITION BY x4.rid) as enttags 
from x4
join juris_tax_applicabilities jta on (jta.rid = x4.rid)
join jurisdictions j on (jta.jurisdiction_id = j.id)
join juris_tax_app_revisions rv on (rv.id = x4.rid)
left join commodities cc on (cc.id = jta.commodity_id)
join crapp_admin.users usr on (usr.id = rv.entered_by)
left join juris_tax_app_tags xtgs on (xtgs.ref_nkid = jta.nkid)
     LEFT OUTER JOIN Tags dtgs ON (dtgs.id = xtgs.tag_id)
where usr.id = enteredby) 
 loop
   pipe row (obj_review_xview(rr.hcentity,
            rr.official_name,
            rr.CommodityName,
            rr.ref_rule_order,
            rr.rid,
            rr.CHGLOGIDS,
            rr.reviewmin,
            rr.reviewlvl,
            rr.lowestreview,
            to_char(rr.status_modified_date,'MM/DD/YYYY'),
            rr.LastModifBy,
            rr.ccdoc,
            rr.enttags));
 end loop; 
 end if; 

---
--- Commodities
---
if entity = 5 then
for rr in (
With x1 as
(
Select 
 lg.id lg_id
,vld.assigned_by
,vld.assignment_type_id
,lg.status current_status
,lg.primary_key
,lg.table_name
,lg.rid 
,ct.id
,lg.status_modified_date
,lg.status
,ct.citation_id
 from comm_chg_logs lg
 left join comm_chg_vlds vld on (vld.comm_chg_log_id = lg.id)
 left join comm_chg_cits ct on (ct.comm_chg_log_id = lg.id)
 where lg.status_modified_date > dtFrom
)
, x2 as
-- Ranking 0,1,2,3
(Select id,
Case name when
 'Final Review' then 4
 when 'Review 1' then 1
 when 'Review 2' then 2
 when 'Test in Staging' then 3
 else 0 
End ReviewLevel from 
assignment_types) 
, x3 as
(Select 
 x1.assigned_by
,x1.assignment_type_id
,x1.current_status
,x1.primary_key
,x1.table_name
,x1.rid 
,x1.id
,x1.status_modified_date
,x2.id vldtype
,x2.ReviewLevel 
,x1.status
,x1.citation_id
from x1
left join x2 on (x2.id = x1.assignment_type_id)
)
, x4 as
(select 
 rid
,listagg(primary_key,',') within group (order by id) CHGLOGIDS
,MIN(nvl(ReviewLevel,0)) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewMin
,MAX(ReviewLevel) KEEP (DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) ReviewLvl  
,Case MIN(nvl(ReviewLevel,0)) KEEP(DENSE_RANK LAST ORDER BY rid, TRUNC(status_modified_date)) 
when 1 then 'Review' when 2 then 'Ready for Final' when 3 then 'Staging' when 4 then 'Final' else 'Pending' end LowestReview 
,count(distinct x3.citation_id) CCDOC
from x3
group by rid)
Select distinct
'Commodities' hcentity,
jta.name as official_name
, ' ' CommodityName
, ' ' ref_rule_order
, x4.rid
, x4.CHGLOGIDS
, x4.reviewmin
, x4.reviewlvl
, x4.lowestreview
, rv.status_modified_date
, substr(usr.firstname,1,1)||'.'||usr.lastname LastModifBy
, ccdoc
, listagg(dtgs.name,',') within group (order by x4.rid) OVER (PARTITION BY x4.rid) as enttags 
from x4
join commodities jta on (jta.rid = x4.rid)
join commodity_revisions rv on (rv.id = x4.rid)
join crapp_admin.users usr on (usr.id = rv.entered_by)
left join commodity_tags xtgs on (xtgs.ref_nkid = jta.nkid)
     LEFT OUTER JOIN Tags dtgs ON (dtgs.id = xtgs.tag_id)
where usr.id = enteredby) 
 loop
   pipe row (obj_review_xview(rr.hcentity,
            rr.official_name,
            rr.CommodityName,
            rr.ref_rule_order,
            rr.rid,
            rr.CHGLOGIDS,
            rr.reviewmin,
            rr.reviewlvl,
            rr.lowestreview,
            to_char(rr.status_modified_date,'MM/DD/YYYY'),
            rr.LastModifBy,
            rr.ccdoc,
            rr.enttags));
 end loop; 
 end if; 

 
 return;
 
End FN_REVIEW_REPORT;
/