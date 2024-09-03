Declare @details Bit;
Set @details = 0

/* Basics */
Select
	ServerName			   = @@ServerName
  --, ServerVersion		   = @@Version
  , ServerVersionYear	   = Substring( @@Version, CharIndex( 'Microsoft SQL Server', @@Version, 0 ) + 20, 5 )
  , ServerEdition		   = Substring(
										  @@Version
										, CharIndex( 'Microsoft Corporation', @@Version, 0 ) + 21
										, ( CharIndex( 'Edition', @@Version, 0 ) - ( CharIndex( 'Microsoft Corporation', @@Version, 0 ) + 21 ))
									  )
  , SQLServerUpTimeDays	   = DateDiff( Day, sqlserver_start_time, GetDate())
  , SQLServerStartTime	   = sqlserver_start_time
  , CPUCount			   = cpu_count
  --, SocketCount			   = socket_count
  --, CoresPerSocket		   = cores_per_socket
  , HostPhysicalMemoryGB   = physical_memory_kb / 1024 / 1024
  , SqlInstanceMaxMemoryGB = (
								 Select Top ( 1 ) Cast(value_in_use As Int)
								 From sys.configurations
								 Where name = N'max server memory (MB)'
								 Order By value_in_use
							 ) / 1024
  , MaxSqlMemoryPct		   = Case
								 When (
										  Select Top ( 1 ) Cast(value_in_use As Int)
										  From sys.configurations
										  Where name = N'max server memory (MB)'
										  Order By value_in_use
									  ) = 2147483647 Then -1
								 Else Cast(((
												Select Top ( 1 ) Cast(value_in_use As Int)
												From sys.configurations
												Where name = N'max server memory (MB)'
												Order By value_in_use
											) / 1024.0 / ( physical_memory_kb / 1024.0 / 1024.0 )
										   ) * 100 As Numeric(4, 2))
							 End
  , db_size.RowsSizeGB
  , db_size.LogSizeGB
  , db_size.TotalSizeGB
--, MaxWorkerCount		   = max_workers_count
From sys.dm_os_sys_info os
Join (
		 Select
			 RowsSizeGB	 = Cast(( db_rows.sum_size * 8.0 ) / 1024.0 / 1024.0 As BigInt)
		   , LogSizeGB	 = Cast(( db_log.sum_size * 8.0 ) / 1024.0 / 1024.0 As BigInt)
		   , TotalSizeGB = Cast((( db_rows.sum_size + db_log.sum_size ) * 8.0 ) / 1024.0 / 1024.0 As BigInt)
		 From (
				  Select Sum( mf.size ) sum_size
				  From sys.master_files mf
				  Where mf.type = 0 --Rows
			  ) db_rows
		 Join (
				  Select Sum( mf.size ) sum_size
				  From sys.master_files mf
				  Where mf.type = 1 --Log
			  ) db_log
			 On 1 = 1
	 )					db_size
	On 1 = 1;

/* Server sizing */
If @details = 1
	Begin
		/* Server sizing */
		Select
			DatabaseName	  = Db_Name( mf.database_id )
		  , DatabaseOwnerName = sp.name
		  , RecoveryModel	  = db.recovery_model_desc
		  , DatabaseType	  = Case When Db_Name( mf.database_id ) In ( 'master', 'model', 'msdb', 'tempdb' ) Then 'System' Else 'User' End
		  , LogicalName		  = mf.name
		  , TypeDesc		  = mf.type_desc
		  , SizeGB			  = Cast(( mf.size * 8.0 ) / 1024.0 / 1024.0 As BigInt)
		  , GowthMB			  = ( mf.growth * 8 ) / 1024
		  , MaxSizeGB		  = Cast(Case When mf.max_size = 0 Then -1 Else Cast(Cast(mf.max_size As BigInt) * 8 / 1024 / 1024 As BigInt)End As Numeric(36, 2))
		  , PhysicalName	  = mf.physical_name
		From sys.master_files	   mf
		Join sys.databases		   db
			On mf.database_id = db.database_id

		Join sys.server_principals sp
			On db.owner_sid = sp.sid
		--Where
		--	Db_Name( mf.database_id ) Not In ( 'master', 'model', 'msdb' )
		Order By
			DatabaseType
		  , DatabaseName
		  , LogicalName;
	End;
Else
	Begin
		Select
			dbs.name		  DBName
		  , DatabaseType	  = Case When dbs.name In ( 'master', 'model', 'msdb', 'tempdb' ) Then 'System' Else 'User' End
		  , DatabaseOwnerName = sp.name
		  , RowsSizeGB		  = Cast(( db_rows.sum_size * 8.0 ) / 1024.0 / 1024.0 As BigInt)
		  , LogSizeGB		  = Cast(( db_log.sum_size * 8.0 ) / 1024.0 / 1024.0 As BigInt)
		  , TotalSizeGB		  = Cast((( db_rows.sum_size + db_log.sum_size ) * 8.0 ) / 1024.0 / 1024.0 As BigInt)
		From sys.databases		   dbs
		Join sys.server_principals sp
			On dbs.owner_sid = sp.sid

		Join (
				 Select
					 mf.database_id
				   , Sum( mf.size ) sum_size
				 From sys.master_files mf
				 Where mf.type = 0 --Rows
				 Group By mf.database_id
			 )					   db_rows
			On dbs.database_id = db_rows.database_id

		Join (
				 Select
					 mf.database_id
				   , Sum( mf.size ) sum_size
				 From sys.master_files mf
				 Where mf.type = 1 --Log
				 Group By mf.database_id
			 )					   db_log
			On dbs.database_id = db_log.database_id
		Where
			dbs.name Not In ( 'master', 'model', 'msdb' )
		Order By
			DatabaseType
		  , DBName;
	End;

