Select
		   Db_Name( a.database_id )															As [Database Name]
		 , b.name + N' [' + b.type_desc Collate SQL_Latin1_General_CP1_CI_AS + N']'			As [Logical File Name]
		 , Upper( Substring( b.physical_name, 1, 2 ))										As Drive
		 , Cast((( a.size_on_disk_bytes / 1024.0 ) / ( 1024.0 * 1024.0 )) As Decimal(9, 2)) As [Size (GB)]
		 , a.io_stall_read_ms																As [Total IO Read Stall]
		 , a.num_of_reads																	As [Total Reads]
		 , Case
			   When a.num_of_bytes_read > 0
					Then Cast(a.num_of_bytes_read / 1024.0 / 1024.0 / 1024.0 As Numeric(23, 1))
			   Else 0
		   End																				As [GB Read]
		 , Cast(a.io_stall_read_ms / ( 1.0 * a.num_of_reads ) As Int)						As [Avg Read Stall (ms)]
		 , Case
			   When b.type = 0
					Then 30 /* data files */
			   When b.type = 1
					Then 5	/* log files */
			   Else 0
		   End																				As [Max Rec Read Stall Avg]
		 , a.io_stall_write_ms																As [Total IO Write Stall]
		 , a.num_of_writes																	[Total Writes]
		 , Case
			   When a.num_of_bytes_written > 0
					Then Cast(a.num_of_bytes_written / 1024.0 / 1024.0 / 1024.0 As Numeric(23, 1))
			   Else 0
		   End																				As [GB Written]
		 , Cast(a.io_stall_write_ms / ( 1.0 * a.num_of_writes ) As Int)						As [Avg Write Stall (ms)]
		 , Case
			   When b.type = 0
					Then 30 /* data files */
			   When b.type = 1
					Then 2	/* log files */
			   Else 0
		   End																				As [Max Rec Write Stall Avg]
		 , b.physical_name																	As [Physical File Name]
		 , Case
			   When b.name = 'tempdb'
					Then 'N/A'
			   When b.type = 1
					Then 'N/A' /* log files */
			   Else 'PAGEIOLATCH*'
		   End																				As [Read-Related Wait Stat]
		 , Case
			   When b.type = 1
					Then 'WRITELOG'			   /* log files */
			   When b.name = 'tempdb'
					Then 'xxx'				   /* tempdb data files */
			   When b.type = 0
					Then 'ASYNC_IO_COMPLETION' /* data files */
			   Else 'xxx'
		   End																				As [Write-Related Wait Stat]
		 , GetDate()																		As [Sample Time]
		 , b.type_desc
From	   sys.dm_io_virtual_file_stats( Null, Null ) As a
Inner Join sys.master_files							  As b
	On a.file_id = b.file_id
	And a.database_id = b.database_id
Where	   a.num_of_reads > 0
And a.num_of_writes > 0
Order By   Cast(a.io_stall_read_ms / ( 1.0 * a.num_of_reads ) As Int) Desc;
