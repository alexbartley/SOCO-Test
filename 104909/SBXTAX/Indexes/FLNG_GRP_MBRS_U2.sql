CREATE UNIQUE INDEX sbxtax.flng_grp_mbrs_u2 ON sbxtax.tb_filing_group_members(merchant_id,transaction_type,start_date,filing_group_id)

TABLESPACE ositax;