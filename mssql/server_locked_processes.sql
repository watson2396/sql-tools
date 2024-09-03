Use master;
Go

-- Kill BlockingSessionID
/*
KILL 454

Kill 114 with statusonly
*/

-- Check all running proccesses
/*
Exec dbo.sp_WhoIsActive
*/

Select
	er.blocking_session_id		 As BlockingSessionID
  , database_name				 = Db_Name( er.database_id )
  , BlockingQuery				 = (
		Select text
		From sys.sysprocesses
		Cross Apply sys.dm_exec_sql_text( sql_handle )
		Where spid = blocking_session_id
	)
  , VictimSessionID				 = er.session_id
  , VictimQuery					 = st.text
  , WaitDurationSecond			 = er.wait_time / 1000
  , WaitInMinutes				 = er.wait_time / 1000.0 / 60
  , WaitType					 = er.wait_type
  , BlockingQueryCompletePercent = er.percent_complete
From sys.dm_exec_requests					   er
Cross Apply sys.dm_exec_sql_text( sql_handle ) st
Where blocking_session_id > 0
Order By
	BlockingSessionID
  , VictimSessionID;


--Check Background processes
/*

Select 
	session_id
	,database_name = DB_NAME(database_id)
	,status
	,text
	,blocking_session_id AS BlockingSessionID
	,total_elapsed_time/1000.0/60 total_minutes
   , start_time
   , command
   , sql_handle
   , request_id, statement_start_offset   , statement_end_offset   , plan_handle   , database_id
   , user_id   , connection_id   , blocking_session_id   , wait_type   , wait_time   , last_wait_type
   , wait_resource   , open_transaction_count   , open_resultset_count   , transaction_id   , context_info
   , percent_complete   , estimated_completion_time   , cpu_time   , total_elapsed_time   , scheduler_id   , task_address
   , reads   , writes   , logical_reads   , text_size
FROM sys.dm_exec_requests
CROSS APPLY sys.dm_exec_sql_text([sql_handle])
Order By total_minutes desc, start_time, cast(session_id as int)

*/




