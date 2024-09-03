Select
	UserName		 = Case princ.type When 'S' Then princ.name When 'U' Then ulogin.name Collate Latin1_General_CI_AI End
  , UserType		 = Case princ.type When 'S' Then 'SQL User' When 'U' Then 'Windows User' End
  , DatabaseUserName = princ.name
  , Role			 = Null
  , PermissionType	 = perm.permission_name
  , PermissionState	 = perm.state_desc
  , ObjectType		 = obj.type_desc --perm.[class_desc],       
  , ObjectName		 = Object_Name( perm.major_id )
  , ColumnName		 = col.name
From sys.database_principals	 princ --database user

Left Join sys.login_token		 ulogin --Login accounts
	On princ.sid = ulogin.sid

Left Join sys.database_permissions perm --Permissions
	On perm.grantee_principal_id = princ.principal_id

Left Join sys.columns				 col --Table columns
	On col.object_id = perm.major_id
	And col.column_id = perm.minor_id

Left Join sys.objects		 obj
	On perm.major_id = obj.object_id
Where
	princ.type In ( 'S', 'U' )
Union
--List all access provisioned to a sql user or windows user/group through a database or application role
Select
	UserName		 = Case memberprinc.type When 'S' Then memberprinc.name When 'U' Then ulogin.name Collate Latin1_General_CI_AI End
  , UserType		 = Case memberprinc.type When 'S' Then 'SQL User' When 'U' Then 'Windows User' End
  , DatabaseUserName = memberprinc.name
  , Role			 = roleprinc.name
  , PermissionType	 = perm.permission_name
  , PermissionState	 = perm.state_desc
  , ObjectType		 = obj.type_desc --perm.[class_desc],   
  , ObjectName		 = Object_Name( perm.major_id )
  , ColumnName		 = col.name
From sys.database_role_members members --Role/member associations
Join sys.database_principals	  roleprinc --Roles
	On roleprinc.principal_id = members.role_principal_id

Join sys.database_principals	  memberprinc --Role members (database users)
	On memberprinc.principal_id = members.member_principal_id

Left Join sys.login_token			  ulogin --Login accounts
	On memberprinc.sid = ulogin.sid

Left Join sys.database_permissions  perm --Permissions
	On perm.grantee_principal_id = roleprinc.principal_id

Left Join sys.columns				  col --Table columns
	On col.object_id = perm.major_id
	And col.column_id = perm.minor_id

Left Join sys.objects		  obj
	On perm.major_id = obj.object_id
Union
--List all access provisioned to the public role, which everyone gets by default
Select
	UserName		 = '{All Users}'
  , UserType		 = '{All Users}'
  , DatabaseUserName = '{All Users}'
  , Role			 = roleprinc.name
  , PermissionType	 = perm.permission_name
  , PermissionState	 = perm.state_desc
  , ObjectType		 = obj.type_desc --perm.[class_desc],  
  , ObjectName		 = Object_Name( perm.major_id )
  , ColumnName		 = col.name
From sys.database_principals	 roleprinc --Roles

Left Join sys.database_permissions perm --Role permissions
	On perm.grantee_principal_id = roleprinc.principal_id

Left Join sys.columns				 col --Table columns
	On col.object_id = perm.major_id
	And col.column_id = perm.minor_id

Join sys.objects				 obj --All objects
	On obj.object_id = perm.major_id
Where
	roleprinc.type = 'R' --Only roles
And roleprinc.name = 'public' --Only public role
And obj.is_ms_shipped = 0 --Only objects of ours, not the MS objects
Order By
	princ.name
  , Object_Name( perm.major_id )
  , col.name
  , perm.permission_name
  , perm.state_desc
  , obj.type_desc; --perm.[class_desc] 
