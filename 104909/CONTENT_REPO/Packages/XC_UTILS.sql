CREATE OR REPLACE PACKAGE content_repo."XC_UTILS" AS
/*
#  H_CODE [2013 spec]
#  tnn - 2013
#
*/  
       function fxvCommoditySeq(ph_code IN commodities.h_code%type) 
             RETURN commodities.h_code%TYPE;
       END XC_UTILS;
 
 
/