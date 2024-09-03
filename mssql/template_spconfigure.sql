Exec sys.sp_configure N'show advanced options', N'1';
Go
Reconfigure
go
Exec sys.sp_configure N'max degree of parallelism', N'8';

Exec sys.sp_configure N'backup checksum default', N'1';

Exec sys.sp_configure N'cost threshold for parallelism', N'50';
Exec sys.sp_configure N'remote admin connections', N'1';
Exec sys.sp_configure N'backup compression default', N'1';

/* Set max SQL Server memory to n% of server memory */
Declare @StringToExecute Nvarchar(400);
Select @StringToExecute = N'Exec sys.sp_configure N''max server memory (MB)'', N'''
        + Cast(Cast( physical_memory_kb / 1024 * .8 as int) as nvarchar(20)) + N''';'
    From sys.dm_os_sys_info;
Exec(@StringToExecute);
Go
Reconfigure;
Go
