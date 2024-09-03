Create Table #results
(
[Server Name] varchar(255)
, [Database Name] varchar(255)
, [Object Name] varchar(255)
, [Index Name] varchar(255)
, [Index ID] int
, [Total Writes] bigint
, [Total Reads] bigint
, [Difference] bigint
);
Insert	Into #results
Exec sp_MSforeachdb
	@command1 = 'USE [?];
Select
			@@servername As [Server Name]
		, DB_NAME() As [Database Name]
		, OBJECT_NAME( s.[object_id] ) As [Table Name]
		, i.name As [Index Name]
		, i.index_id As [Index ID]
		, user_updates As [Total Writes]
		, user_seeks + user_scans + user_lookups As [Total Reads]
		, user_updates - ( user_seeks + user_scans + user_lookups ) As [Difference]
From		sys.dm_db_index_usage_stats As s With ( NoLock )
Inner Join	sys.indexes As i With ( NoLock )
	On s.[object_id] = i.[object_id]
	And i.index_id = s.index_id
Where
			OBJECTPROPERTY( s.[object_id], ''IsUserTable'' ) = 1
And s.database_id = DB_ID()
And user_updates > ( user_seeks + user_scans + user_lookups )
And i.index_id > 1
Order By
			[Difference] Desc
		, [Total Writes] Desc
		, [Total Reads] Asc
Option ( Recompile );'
;
Select		*
From		#results
Order By	[Total Reads];
Drop Table #results;
