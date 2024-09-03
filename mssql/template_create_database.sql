USE [master]
GO
/*
Highlights:
    * Rows file starting size       : 100,000   MB (mebibyte)
    * Rows file growth factor:      : 512       MB (mebibyte)
    * Log file starting size        : 6250      MB (mebibyte)
    * Log file growth factor        : 64        MB (mebibyte)

    * Recovery model                : Simple

    * Change database owner to      : sa

Instructions:
    * Check data and log file paths and updated accordingly
    * Highlight database name and find and replace with new database name then run

*/


CREATE DATABASE [<database-name>]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'<database-name>', FILENAME = N'S:\SQL_Data\<database-name>.mdf' , SIZE = 100000MB , MAXSIZE = UNLIMITED, FILEGROWTH = 512MB )
 LOG ON 
( NAME = N'<database-name>_log', FILENAME = N'L:\SQL_Log\<database-name>_log.ldf' , SIZE = 6250MB , MAXSIZE = 204800MB , FILEGROWTH = 64MB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO

Alter authorization on DATABASE::<database-name> to sa;
Go

Alter Database [<database-name>] Set Recovery Simple 
Go

Alter Database [<database-name>] Set  Multi_User 
Go

ALTER DATABASE [<database-name>] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [<database-name>] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [<database-name>] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [<database-name>] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [<database-name>] SET ARITHABORT OFF 
GO

ALTER DATABASE [<database-name>] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [<database-name>] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [<database-name>] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [<database-name>] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [<database-name>] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [<database-name>] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [<database-name>] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [<database-name>] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [<database-name>] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [<database-name>] SET ENABLE_BROKER 
GO

ALTER DATABASE [<database-name>] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

Alter Database [<database-name>] Set Date_Correlation_Optimization Off 
Go

Alter Database [<database-name>] Set Trustworthy Off 
Go

Alter Database [<database-name>] Set Allow_Snapshot_Isolation Off 
Go

Alter Database [<database-name>] Set Parameterization Simple 
Go

Alter Database [<database-name>] Set Read_Committed_Snapshot Off 
Go

Alter Database [<database-name>] Set Honor_Broker_Priority Off 
Go

Alter Database [<database-name>] Set Page_Verify Checksum  
Go

Alter Database [<database-name>] Set Db_Chaining Off 
Go

Alter Database [<database-name>] Set FileStream( Non_Transacted_Access = Off ) 
Go

Alter Database [<database-name>] Set Target_Recovery_Time = 60 Seconds 
Go

Alter Database [<database-name>] Set Delayed_Durability = Disabled 
Go

Alter Database [<database-name>] Set Accelerated_Database_Recovery = Off  
Go

Alter Database [<database-name>] Set Query_Store = Off
Go

Alter Database [<database-name>] Set  Read_Write 
Go


