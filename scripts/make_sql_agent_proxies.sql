USE [msdb]
GO

/****** Object:  ProxyAccount [proxy_ssis]    Script Date: 10/28/2014 09:58:44 ******/
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'proxy_ssis',@credential_name=N'credential_ssis', 
		@enabled=1
GO

EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'proxy_ssis', @subsystem_id=11
GO

USE [msdb]
GO

/****** Object:  ProxyAccount [ps_proxy]    Script Date: 10/28/2014 09:59:13 ******/
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'ps_proxy',@credential_name=N'credential_ssis', 
		@enabled=1
GO

EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'ps_proxy', @subsystem_id=3
GO

EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'ps_proxy', @subsystem_id=12
GO

