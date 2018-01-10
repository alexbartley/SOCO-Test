CREATE MATERIALIZED VIEW content_repo.mvtax_administrators_prod ("ID",nkid,rid,next_rid,admin_id,admin_nkid,admin_rid,juris_tax_id,juris_tax_nkid,juris_tax_rid,administrator_name,collects_tax,collector_name,collector_id,collector_nkid,collector_rid,start_date,end_date,status,status_modified_date,entered_by,entered_date) 
TABLESPACE content_repo
AS SELECT distinct ta.id,
       ta.nkid,
       ta.rid,
       ta.next_rid,
       ad.id,
       ad.nkid,
       ad.rid,
       ti.id,
       jt.nkid,
       jt.id juris_tax_rid,
       ad.name,
       NVL2 (co.id, 0, 1) collects_tax,
       co.name collector_name,
       co.id coll_id,
       co.nkid coll_nkid,
       co.rid coll_rid,
       TO_CHAR (ta.start_date, 'mm/dd/yyyy') start_date,
       TO_CHAR (ta.end_date, 'mm/dd/yyyy') end_date,
       ta.status,
       ta.status_modified_date,
       ta.entered_by,
       ta.entered_date
  FROM tax_administrators ta
       JOIN juris_tax_impositions ti
          ON (ti.id = ta.juris_tax_imposition_id)
       JOIN jurisdiction_tax_revisions jt
          ON (    jt.nkid = ti.nkid
              AND jt.id >= ta.rid
              AND jt.id < NVL (ta.next_rid, 99999999))
       JOIN mvjurisdictions mj on ( mj.nkid = ti.jurisdiction_nkid )
       JOIN administrators ad
          ON (ad.id = ta.administrator_id)
       LEFT OUTER JOIN administrators co
          ON (co.id = NVL (ta.collector_id, -1))
where jt.status = 2;