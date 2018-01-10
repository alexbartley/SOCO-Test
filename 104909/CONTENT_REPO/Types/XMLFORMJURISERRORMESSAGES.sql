CREATE OR REPLACE TYPE content_repo.XMLFORMJURISERRORMESSAGES AS OBJECT
( 
  	id number,
  	rid number,
  	jurisdiction_id number,
  	severity_id number,
  	error_msg varchar2(240),
   	description varchar2(2000),
	start_date date,
 	end_date date,
   	entered_by number,
  	nkid number,
  	modified number,
  	deleted number
);
/