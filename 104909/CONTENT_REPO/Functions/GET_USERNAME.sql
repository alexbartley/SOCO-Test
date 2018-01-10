CREATE OR REPLACE FUNCTION content_repo."GET_USERNAME" (pUserId in number) return varchar2
is
/** Get first name 'one char' and last name */
  l_username varchar2(64);
begin
 Select substr(usr.firstname,1,1)||'.'||usr.lastname
 Into l_username
 From users usr
 Where usr.id = pUserId;
 Return l_username;
end get_username;
 
 
/