/*
====================================================================
Author:           Dominic Wirth
Date created:     2019-10-04
Date last change: 2019-12-21
Script-Version:   1.1
Tested with:      SQL Server 2012 and above
Description: This script shows important information regarding
SQL Jobs and Job Schedules. Please feel free to change the
translated values from English to your desired language.
====================================================================
*/
With JobSchedules
As (
	Select
		 schedule_id
	   , name
	   , enabled
	   , Frequency = Case freq_type
			 When 1
				  Then 'One time only'
			 When 4
				  Then 'Daily'
			 When 8
				  Then 'Weekly'
			 When 16
				  Then 'Monthly'
			 When 32
				  Then 'Monthly'
			 When 64
				  Then 'When SQL Server Agent starts'
			 When 128
				  Then 'When computer is idle'
		 End																							    
	   , DayInterval = Iif(
			 freq_type = 32
		  And freq_relative_interval <> 0
		   , Case freq_relative_interval
				 When 1
					  Then 'First '
				 When 2
					  Then 'Second '
				 When 4
					  Then 'Third '
				 When 8
					  Then 'Fourth '
				 When 16
					  Then 'Last '
			 End
		   , '')
		 + Case freq_type
			   When 1
					Then ''
			   When 4
					Then Iif(freq_interval = 1, 'Every day', 'Every ' + Cast(freq_interval As Varchar(3)) + ' day(s)')
			   When 8
					Then Iif(freq_interval & 2 = 2, 'Mon ', '') + Iif(freq_interval & 4 = 4, 'Tue ', '')
						 + Iif(freq_interval & 8 = 8, 'Wed ', '') + Iif(freq_interval & 16 = 16, 'Thu ', '')
						 + Iif(freq_interval & 32 = 32, 'Fri ', '') + Iif(freq_interval & 64 = 64, 'Sat ', '')
						 + Iif(freq_interval & 1 = 1, 'Sun ', '')
			   When 16
					Then 'On the ' + Cast(freq_interval As Varchar(3)) + ' day of the month.'
			   When 32
					Then Case freq_interval
							 When 1
								  Then 'Sunday'
							 When 2
								  Then 'Monday'
							 When 3
								  Then 'Tuesday'
							 When 4
								  Then 'Wednesday'
							 When 5
								  Then 'Thursday'
							 When 6
								  Then 'Friday'
							 When 7
								  Then 'Saturday'
							 When 8
								  Then 'Day'
							 When 9
								  Then 'Weekday'
							 When 10
								  Then 'Weekend day'
						 End
			   When 64
					Then ''
			   When 128
					Then ''
		   End																							   
	   ,DailyFrequency = Iif(freq_subday_interval <> 0
		   , Case freq_subday_type
				 When 1
					  Then 'At '
						   + Stuff(
								 Stuff( Right('00000' + Cast(active_start_time As Varchar(6)), 6), 3, 0, ':' )
								, 6
								, 0
								, ':'
							 )
				 When 2
					  Then 'Repeat every ' + Cast(freq_subday_interval As Varchar(3)) + ' seconds'
				 When 4
					  Then 'Repeat every ' + Cast(freq_subday_interval As Varchar(3)) + ' minutes'
				 When 8
					  Then 'Repeat every ' + Cast(freq_subday_interval As Varchar(3)) + ' hours'
			 End
		   , '')																						   
	   , Recurrence = Case
			 When freq_type = 8
				  Then 'Repeat every ' + Cast(freq_recurrence_factor As Varchar(3)) + ' week(s).'
			 When freq_type In ( 16, 32 )
				  Then 'Repeat every ' + Cast(freq_recurrence_factor As Varchar(3)) + ' month(s).'
			 Else ''
		 End																							   
	   ,StartTime = Stuff( Stuff( Right('00000' + Cast(active_start_time As Varchar(6)), 6), 3, 0, ':' ), 6, 0, ':' ) 
	   ,EndTime = Stuff( Stuff( Right('00000' + Cast(active_end_time As Varchar(6)), 6), 3, 0, ':' ), 6, 0, ':' ) 
	From msdb.dbo.sysschedules
), jobRunTime As (
	Select
			   j.name
			 , avgMinDuration = Avg(
						DateDiff(
							Second
					 , 0
					 , Stuff( Stuff( Right('000000' + Convert( Varchar(6), run_duration ), 6), 5, 0, ':' ), 3, 0, ':' )
						) / 60
					)
			, j.job_id
	From	   msdb.dbo.sysjobhistory As h
	Inner Join msdb.dbo.sysjobs		  As j
		On h.job_id = j.job_id
	Where	   h.step_id = 0
	Group By   j.name, j.job_id
)

Select
		ServerName = @@ServerName
		, J.name						  As JobName
		, J.enabled						  As JobIsEnabled
		, IsNull( SP.name, 'Unknown' )	  As JobOwner
		, IsNull( JS.enabled, 0 )		  As ScheduleIsEnabled
		, IsNull( JS.Frequency, '' )	  As Frequency
		, IsNull( JS.DayInterval, '' )	  As DayInterval
		, IsNull( JS.DailyFrequency, '' ) As DailyFrequency
		, IsNull( JS.Recurrence, '' )	  As Recurrence
		, IsNull( JS.StartTime, '' )	  As StartTime
		, IsNull( JS.EndTime, '' )		  As EndTime
		, jrt.avgMinDuration
From	  msdb.dbo.sysjobs		   As J
Left Join sys.server_principals	   As SP
	On J.owner_sid = SP.sid

Left Join msdb.dbo.sysjobschedules As JJS
	On J.job_id = JJS.job_id

Left Join JobSchedules			   As JS
	On JJS.schedule_id = JS.schedule_id

Left Join jobRunTime jrt On j.job_id = jrt.job_id

Where	  IsNull( JS.Frequency, '' ) != 'One time only'
And J.enabled = 1
And IsNull( JS.enabled, 0 ) = 1
Order By  J.name Asc;
