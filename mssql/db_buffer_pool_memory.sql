Declare @total_buffer Int;

Select @total_buffer = cntr_value
From   sys.dm_os_performance_counters
Where  RTrim( object_name ) Like '%Buffer Manager'
And counter_name = 'Database Pages';

;With src
As (
	Select
			 database_id
		   , db_buffer_pages = Count_Big( * )
	From	 sys.dm_os_buffer_descriptors
	Group By database_id
)
Select
		 db_name		   = Case database_id
								 When 32767
									  Then 'Resource DB'
								 Else Db_Name( database_id )
							 End
	   , db_buffer_pages
	   , db_buffer_MB	   = db_buffer_pages / 128
	   , db_buffer_percent = Convert( Decimal(6, 3), db_buffer_pages * 100.0 / @total_buffer )
From	 src
Order By db_buffer_MB Desc;

