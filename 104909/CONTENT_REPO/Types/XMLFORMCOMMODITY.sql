CREATE OR REPLACE TYPE content_repo."XMLFORMCOMMODITY"                                          as object 
(id number, rid number,
name varchar2(500),
start_date DATE,
end_date DATE,
nkid number,
description varchar2(1000), 
entered_by number,
modified number,
deleted NUMBER,
parent_id number,
commodity_code varchar2(100),
product_tree_id number,
product_tree_short_name varchar2(60),
h_code varchar2(128)
);
/