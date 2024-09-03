/* Basics */
Select
	ServerName			   = @@ServerName
  , ServerVersion		   = @@Version
  , SQLServerUpTimeDays	   = DateDiff( Day, sqlserver_start_time, GetDate())
  , SQLServerStartTime	   = sqlserver_start_time
  , CPUCount			   = cpu_count
  , SocketCount			   = socket_count
  , CoresPerSocket		   = cores_per_socket
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
								 ) = 2147483647
									 Then -1
								 Else Cast(((
												Select Top ( 1 ) Cast(value_in_use As Int)
												From sys.configurations
												Where name = N'max server memory (MB)'
												Order By value_in_use
											) / 1024.0 / ( physical_memory_kb / 1024.0 / 1024.0 )
										   ) * 100 As Numeric(4, 2))
							 End
  , MaxWorkerCount		   = max_workers_count
From sys.dm_os_sys_info;

Select
	configuration_id
  , name
  , value_in_use
  --, minimum
  --, maximum
  , description
  , is_dynamic
  , is_advanced
From sys.configurations
Where
	name In ( N'max degree of parallelism'
			, N'backup checksum default'
			, N'remote admin connections'
			, N'backup compression default'
			, N'max server memory (MB)'
			, N'min server memory (MB)'
			, N'cost threshold for parallelism'
			, N''
	);
Go

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
Where
	Db_Name( mf.database_id ) Not In ( 'master', 'model', 'msdb' )
Order By
	DatabaseType
  , DatabaseName
  , LogicalName;
