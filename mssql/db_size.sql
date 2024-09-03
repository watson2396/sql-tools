/*
Exec sp_helpdb 'tempdb';

Exec sys.sp_spaceused;

Exec sys.sp_databases;
*/


With DBConfig
As (
	Select
		DatabaseName = Db_Name( database_id )
	  , LogicalName	 = name
	  , TypeDesc	 = type_desc
	  , SizeGB		 = ( Cast(size As BigInt) * 8 ) / 1024 / 1024
	  , GowthMB		 = ( growth * 8 ) / 1024
	  , MaxSizeGB	 = ( Cast(max_size As BigInt) * 8 ) / 1024 / 1024
	  , PhysicalName = physical_name
	From sys.master_files
	Where Db_Name( database_id ) = Db_Name()
)
   , DBRowSpace
As (
	Select
		DatabaseName = db.name
	  , FreeSpacePct = Round(
						   ((( Sum( Cast(db_fs.unallocated_extent_page_count As BigInt)) * 1.0 / 128 ) / 1024 )
							/ (( Sum( Cast(db_fs.total_page_count As BigInt)) * 1.0 / 128 ) / 1024 )
						   ) * 100
						 , 2
					   )
	  , TotalSpaceGB = Round(( Sum( Cast(db_fs.total_page_count As BigInt)) * 1.0 / 128 ) / 1024, 2 )
	  , UsedSpaceGB	 = Round(( Sum( Cast(db_fs.allocated_extent_page_count As BigInt)) * 1.0 / 128 ) / 1024, 2 )
	  , FreeSpaceGB	 = Round(( Sum( Cast(db_fs.unallocated_extent_page_count As BigInt)) * 1.0 / 128 ) / 1024, 2 )
	  , FreeSpaceMB	 = Round(( Sum( Cast(db_fs.unallocated_extent_page_count As BigInt)) * 1.0 / 128 ), 2 )
	  , TypeDesc	 = 'ROWS'
	From sys.dm_db_file_space_usage db_fs
	Join sys.databases				db
		On db.database_id = db_fs.database_id
	Group By db.name
)
   , DBLogSpace
As (
	Select
		DatabaseName	= Db_Name( database_id )
	  , TotalLogSpaceGB = Round( Cast(total_log_size_in_bytes As BigInt) * 1.0 / 1024 / 1024 / 1024, 2 )
	  , FreeLogSpacePct = Round(
							  ( Cast(( total_log_size_in_bytes - used_log_space_in_bytes ) As BigInt) * 1.0 / 1024
								/ 1024
							  ) / ( Cast(total_log_size_in_bytes As BigInt) * 1.0 / 1024 / 1024 ) * 100
							, 2
						  )
	  , FreeLogSpaceMB	= Round(
							  Cast(( total_log_size_in_bytes - used_log_space_in_bytes ) As BigInt) * 1.0 / 1024 / 1024
							, 2
						  )
	  , FreeLogSpaceGB	= Round(
							  Cast(( total_log_size_in_bytes - used_log_space_in_bytes ) As BigInt) * 1.0 / 1024 / 1024
							  / 1024
							, 2
						  )
	  , UsedLogSpaceMB	= Round( Cast(used_log_space_in_bytes As BigInt) * 1.0 / 1024 / 1024, 2 )
	  , TypeDesc		= 'LOG'
	From sys.dm_db_log_space_usage
)

/*
	Database level
*/
Select
	ServerName	 = @@ServerName
  , dbc.DatabaseName
  , dbc.LogicalName
  , dbc.TypeDesc
  , dbc.SizeGB
  , FreeSpaceGB	 = Cast(Coalesce( dbs.FreeSpaceGB, dbl.FreeLogSpaceGB ) As Numeric(15, 2))
  , FreeSpacePct = Cast(Coalesce( dbs.FreeSpacePct, dbl.FreeLogSpacePct ) As Numeric(15, 2))
  , FreeSpaceMB	 = Cast(Coalesce( dbs.FreeSpaceMB, dbl.FreeLogSpaceMB ) As Numeric(15, 2))
  , dbc.GowthMB
  , dbc.MaxSizeGB
  , dbc.PhysicalName
From DBConfig		 dbc
Left Join DBRowSpace dbs
	On dbc.DatabaseName = dbs.DatabaseName
	And dbc.TypeDesc = dbs.TypeDesc

Left Join DBLogSpace dbl
	On dbc.DatabaseName = dbl.DatabaseName
	And dbc.TypeDesc = dbl.TypeDesc
Order By
	dbc.DatabaseName, dbc.LogicalName;


/*
	Schema level
*/
Select
	sub.SchemaName
  , sub.SchemaTableCount
  , sub.SchemaTotalSizeGB
  , sub.SchemaUnusedSizeGB
  , SchemaPctofDatabase = Cast(( sub.SchemaTotalSizeGB / Sum( NullIf( sub.SchemaTotalSizeGB, 0 )) Over ()) * 100 As Numeric(10, 2))
  , DatabaseSchemaCount = Count( sub.SchemaName ) Over ()
  , DatabaseTableCount	= Sum( sub.SchemaTableCount ) Over ()
From (
	Select
		DatabaseName	   = Db_Name()
	  , SchemaName		   = s.name
	  , SchemaTableCount   = Count( Distinct t.name )
	  , SchemaTotalSizeGB  = Sum( Cast(Round((( a.total_pages * 8 ) / 1000000.00 ), 2 ) As Numeric(36, 2)))
	  , SchemaUsedSizeGB   = Sum( Cast(Round((( a.used_pages * 8 ) / 1000000.00 ), 2 ) As Numeric(36, 2)))
	  , SchemaUnusedSizeGB = Sum(
								 Cast(Round((( a.total_pages * 8 ) / 1000000.00 ), 2 ) As Numeric(36, 2))
								 - Cast(Round((( a.used_pages * 8 ) / 1000000.00 ), 2 ) As Numeric(36, 2))
							 )
	From sys.partitions		  p
	Join sys.tables			  t
		On t.object_id = p.object_id

	Join sys.indexes		  i
		On p.index_id = i.index_id
		And p.object_id = i.object_id

	Join sys.allocation_units a
		On p.partition_id = a.container_id

	Left Join sys.schemas	  s
		On t.schema_id = s.schema_id
	Group By
		s.schema_id, s.name
) sub
Order By SchemaPctofDatabase Desc;


/*
	Table level
*/
Select
	TableName	  = t.name
  , SchemaName	  = s.name
  , RowCounts	  = Format( Max( p.rows ), 'N0' )
  , TotalSpaceKB  = Format( Sum( a.total_pages ) * 8, 'N2' )
  , TotalSpaceMB  = Format( ( Sum( a.total_pages ) * 8 ) / 1024.00, 'N2' )
  , UsedSpaceKB	  = Format( Sum( a.used_pages ) * 8, 'N2' )
  , UnusedSpaceKB = Format(( Sum( a.total_pages ) - Sum( a.used_pages )) * 8, 'N2' )
From sys.tables					t
Inner Join sys.indexes			i
	On t.object_id = i.object_id

Inner Join sys.partitions		p
	On i.object_id = p.object_id
	And i.index_id = p.index_id

Inner Join sys.allocation_units a
	On p.partition_id = a.container_id

Left Outer Join sys.schemas		s
	On t.schema_id = s.schema_id
Where
	t.name Not Like 'dt%'
And t.is_ms_shipped = 0
And i.object_id > 255
Group By
	t.name, s.name
Order By
	( Sum( a.total_pages ) * 8 ) Desc;

