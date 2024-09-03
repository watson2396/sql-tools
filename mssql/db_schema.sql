Select
	 query_text = Case
		 When sub.query_text != First_Value( sub.query_text ) Over ( Order By sub.dbid )
			  Then 'union all ' + sub.query_text
		 Else sub.query_text
	 End
From (
	Select
		  d.dbid
		, query_text = 'Select catalog_name as db_name, SCHEMA_NAME as schema_name, schema_owner as schema_owner From '
					   + d.name
					   + '.INFORMATION_SCHEMA.SCHEMATA s Where (s.SCHEMA_NAME not like ''db_%'' and s.SCHEMA_NAME not in (''INFORMATION_SCHEMA'',''sys'',''guest''))'
	From  master.dbo.sysdatabases d
	Where name Not In ( 'master', 'msdb', 'model', 'tempdb')
) sub;
