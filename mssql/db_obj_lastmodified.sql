SELECT name, create_date, modify_date, type, type_desc
FROM sys.objects
WHERE 
	--type = 'P'
	type Not In ('S ','IT','SQ')
And name Not Like '%diagr%'
ORDER BY modify_date DESC
