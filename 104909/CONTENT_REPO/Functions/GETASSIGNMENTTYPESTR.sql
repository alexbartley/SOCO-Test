CREATE OR REPLACE FUNCTION content_repo."GETASSIGNMENTTYPESTR" (pAssignmentType in assignment_types.id%type) return varchar2
is
 rtnAssignment assignment_types.name%type;
begin
 Select nvl(name,'') into rtnAssignment
 From assignment_types t
 Where t.id = pAssignmentType;

 Return rtnAssignment;
end;
 
 
/