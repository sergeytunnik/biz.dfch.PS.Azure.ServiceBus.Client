function New-Message {
<#
.SYNOPSIS
Creates a message for the Service Bus Message Factory.

.DESCRIPTION
Creates a message for the Service Bus Message Factory.

.OUTPUTS
This Cmdlet returns the SequenceNumber from the MessageFactory Message object. On failure it returns $null.

.INPUTS
See PARAMETER section for a description of input parameters.

.EXAMPLE
$messageid = New-Message;

Creates a message for the Service Bus Message Factory and against server defined within module configuration xml file.
#>
[CmdletBinding(
	HelpURI = 'http://dfch.biz/biz/dfch/PS/AzureServiceBus/Client/'
)]
[OutputType([string])]
Param 
(
	# [Required] The Message such as 'Message 123'.
	[Parameter(Mandatory = $true, Position = 0)]
	[ValidateNotNullorEmpty()]
	$InputObject
	,
	# [Optional] Set message id.
	[Parameter(Mandatory = $false, Position = 1)]
	[alias("MessageId")]
	[string] $Id
	, 
	# [Optional] Sets a application specific label.
	[Parameter(Mandatory = $false, Position = 2)]
	[alias("MessageLabel")]
	[string] $Label
	, 
	# [Optional] Sets addional message properties.
	[Parameter(Mandatory = $false, Position = 3)]	
	[hashtable] $Properties
	, 
	# [Optional] The TimeToLive is the duration after which the message expires, starting from when the message is sent to the Service Bus.
	[Parameter(Mandatory = $false, Position = 4)]
	[ValidateNotNullorEmpty()]
	[alias("ttl")]
	[int] $TimeToLiveSec
	, 
	# [Optional] The Facility such as 'MyQueue'. If you do not specify this 
	# value it is taken from the module configuration file.
	[Parameter(Mandatory = $false, Position = 5)]
	[ValidateNotNullorEmpty()]
	[alias("queue")]
	[alias("topic")]
	[alias("QueueName")]
	[string] $Facility = (Get-Variable -Name $MyInvocation.MyCommand.Module.PrivateData.MODULEVAR -ValueOnly).SendFacility
	, 
	# [Optional] The Format such as 'JSON'. If you do not specify this 
	# value it is taken from the module configuration file.
	[Parameter(Mandatory = $false, Position = 6)]
	[ValidateNotNullorEmpty()]
	[string] $Format = (Get-Variable -Name $MyInvocation.MyCommand.Module.PrivateData.MODULEVAR -ValueOnly).Format
	, 
	# [Optional] Messaging Client (instance of the MessagingFactory)
	[Parameter(Mandatory = $false, Position = 7)]
	[alias("MessageClient")]
	$Client
	,
	# [Optional] The Retry. If you do not specify this 
	# value it is taken from the module configuration file.
	[Parameter(Mandatory=$false, Position = 8)]
	[int]$Retry = (Get-Variable -Name $MyInvocation.MyCommand.Module.PrivateData.MODULEVAR -ValueOnly).CommandRetry 
	,
	# [Optional] The RetryInterval. If you do not specify this 
	# value it is taken from the module configuration file.
	[Parameter(Mandatory=$false, Position = 9)]
	[int]$RetryInterval = (Get-Variable -Name $MyInvocation.MyCommand.Module.PrivateData.MODULEVAR -ValueOnly).CommandRetryInterval
)

BEGIN 
{
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug $fn ("CALL. Facility '{0}'" -f $Facility ) -fac 1;

}
# BEGIN 

PROCESS 
{

	[boolean] $fReturn = $false;
	[int] $CmdRetryCount = 0;

	$Params = @{};
	$ParamsList = (Get-Command -Name $MyInvocation.InvocationName).Parameters;
	foreach ($key in $ParamsList.keys)
	{
		$var = Get-Variable -Name $key -ErrorAction SilentlyContinue;
		if($var)
		{
			if ( @('Retry', 'RetryInterval') -notcontains $($var.name) -and $var.value -ne $null -and $($var.value) -ne '' ) 
			{
				$Params.Add($($var.name), $var.value);
			}
		}
	}
	Log-Debug $fn ("Operation [{0}] arguments: {1}" -f ($fn -replace 'Worker', ''), ($Params | Out-String));

	# Retry handling
	for($c = 1; $c -le ($Retry+1); $c++)
	{
		try
		{
			$OutputParameter = New-MessageWorker @Params;
			break;
		}
		catch
		{
			# Throw last execption
			if ( $c -gt $Retry -or $_.Exception.Message -match 'Connect to the message factory before using the Cmdlet.' )
			{
				throw;
			}
			Log-Debug $fn ("[{0}/{1}] Retrying operation [{2}]" -f $c, $Retry, ($fn -replace 'Worker', ''));
			Start-Sleep -Seconds $RetryInterval;
			$RetryInterval *= 2;
			continue;
		}
	}
	return $OutputParameter;
	$fReturn = $true;

}
# PROCESS

END 
{
	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
}
# END

} # function
if($MyInvocation.ScriptName) { Export-ModuleMember -Function New-Message; } 

function New-MessageWorker {
<#
.SYNOPSIS
Creates a message for the Service Bus Message Factory.

.DESCRIPTION
Creates a message for the Service Bus Message Factory.

.OUTPUTS
This Cmdlet returns the SequenceNumber from the MessageFactory Message object. On failure it returns $null.

.INPUTS
See PARAMETER section for a description of input parameters.

.EXAMPLE
$messageid = New-MessageWorker;

Creates a message for the Service Bus Message Factory and against server defined within module configuration xml file.
#>
[CmdletBinding(
	HelpURI = 'http://dfch.biz/biz/dfch/PS/AzureServiceBus/Client/'
)]
[OutputType([string])]
Param 
(
	# [Required] The Message such as 'Message 123'.
	[Parameter(Mandatory = $true, Position = 0)]
	[ValidateNotNullorEmpty()]
	$InputObject
	,
	# [Optional] Set message id.
	[Parameter(Mandatory = $false, Position = 1)]
	[alias("MessageId")]
	[string] $Id
	, 
	# [Optional] Sets a application specific label.
	[Parameter(Mandatory = $false, Position = 2)]
	[alias("MessageLabel")]
	[string] $Label
	, 
	# [Optional] Sets addional message properties.
	[Parameter(Mandatory = $false, Position = 3)]
	[alias("MessageProperties")]
	[hashtable] $Properties
	, 
	# [Optional] The TimeToLive is the duration after which the message expires, starting from when the message is sent to the Service Bus.
	[Parameter(Mandatory = $false, Position = 4)]
	[ValidateNotNullorEmpty()]
	[alias("ttl")]
	[int] $TimeToLiveSec
	, 
	# [Optional] The Facility such as 'MyQueue'. If you do not specify this 
	# value it is taken from the module configuration file.
	[Parameter(Mandatory = $false, Position = 5)]
	[ValidateNotNullorEmpty()]
	[alias("queue")]
	[alias("topic")]
	[alias("QueueName")]
	[string] $Facility = (Get-Variable -Name $MyInvocation.MyCommand.Module.PrivateData.MODULEVAR -ValueOnly).SendFacility
	, 
	# [Optional] The Format such as 'JSON'. If you do not specify this 
	# value it is taken from the module configuration file.
	[Parameter(Mandatory = $false, Position = 6)]
	[ValidateNotNullorEmpty()]
	[string] $Format = (Get-Variable -Name $MyInvocation.MyCommand.Module.PrivateData.MODULEVAR -ValueOnly).Format
	, 
	# [Optional] Messaging Client (instance of the MessagingFactory)
	[Parameter(Mandatory = $false, Position = 7)]
	[alias("MessageClient")]
	$Client
)

BEGIN 
{
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug $fn ("CALL. Facility '{0}'" -f $Facility ) -fac 1;

}
# BEGIN 

PROCESS 
{

[boolean] $fReturn = $false;

try 
{
	# Parameter validation
	# N/A
	
	# Create message client
	try 
	{
		if ( !$PSBoundParameters.ContainsKey('Client') ) 
		{
			$Client = New-MessageSender -Facility $Facility;
		}
	} 
	catch 
	{
		$msg = $_.Exception.Message;
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $Client;
		Log-Error $fn -msg $msg;
		$PSCmdlet.ThrowTerminatingError($e);
	}

	# Convert message body
	$MessageBody = $InputObject.ToString();
	# switch($Format) 
	# {
		# 'xml' { $MessageBody = (ConvertTo-Xml -InputObject $InputObject).OuterXml; }
		# 'xml-pretty' { $MessageBody = Format-Xml -String (ConvertTo-Xml -InputObject $InputObject).OuterXml; }
		# 'json' { $MessageBody = ConvertTo-Json -InputObject $InputObject -Compress; }
		# 'json-pretty' { $MessageBody = ConvertTo-Json -InputObject $InputObject; }
		# Default { $MessageBody = $InputObject; }
	# }
	
	Log-Debug $fn ("-> MessageBody '{0}'; Type '{1}'; As '{2}'; AsType '{3}'" -f $MessageBody.toString(), $MessageBody.GetType(), $Format.toString(), $Format.GetType() );
		
	# Create message
	[Microsoft.ServiceBus.Messaging.BrokeredMessage] $BrokeredMessage = [Microsoft.ServiceBus.Messaging.BrokeredMessage]($MessageBody.ToString());

	# Set message properties
	if ( $PSBoundParameters.ContainsKey('Properties') ) 
	{
		foreach ( $MessageProperty in $Properties.GetEnumerator() ) 
		{
			$BrokeredMessage.Properties[$MessageProperty.Name] = $MessageProperty.Value.ToString();
		}
	}
	if ( $PSBoundParameters.ContainsKey('Id') ) 
	{
		$BrokeredMessage.MessageId = $Id;
	}
	if ( $PSBoundParameters.ContainsKey('Label') ) 
	{
		$BrokeredMessage.Label = $Label;
	}
	if ( $PSBoundParameters.ContainsKey('TimeToLiveSec') ) 
	{
		$BrokeredMessage.TimeToLive = (New-TimeSpan -Seconds $TimeToLiveSec);
	}	
	
	try 
	{
		# Send message
		$Client.Send($BrokeredMessage);	
	} 
	catch 
	{
		$msg = $_.Exception.Message;
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $Client;
		Log-Error $fn -msg $msg;
		$PSCmdlet.ThrowTerminatingError($e);
	}
	
	$OutputParameter = $BrokeredMessage.MessageId;
	$fReturn = $true;

}
catch 
{
	if($gotoSuccess -eq $_.Exception.Message) 
	{
			$fReturn = $true;
	} 
	else 
	{
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) 
		{
			Log-Critical $fn "Login to Uri '$Uri' with Username '$Username' FAILED [$_].";
			Log-Debug $fn $ErrorText -fac 3;
		}
		else 
		{
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) 
			{
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} 
			elseif($gotoFailure -ne $_.Exception.Message) 
			{ 
				Write-Verbose ("$fn`n$ErrorText"); 
			} 
			else 
			{
				# N/A
			}
		}
		$fReturn = $false;
		$OutputParameter = $null;
	}
}
finally 
{
	# Clean up
	# N/A
}
return $OutputParameter;

}
# PROCESS

END 
{
	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
}
# END

} # function

# 
# Copyright 2014-2015 d-fens GmbH
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

# SIG # Begin signature block
# MIIXDwYJKoZIhvcNAQcCoIIXADCCFvwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUilUq6Wuux/x49w7I9aCUI+VW
# xfCgghHCMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BCkwggMRoAMCAQICCwQAAAAAATGJxjfoMA0GCSqGSIb3DQEBCwUAMEwxIDAeBgNV
# BAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWdu
# MRMwEQYDVQQDEwpHbG9iYWxTaWduMB4XDTExMDgwMjEwMDAwMFoXDTE5MDgwMjEw
# MDAwMFowWjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# MDAuBgNVBAMTJ0dsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBTSEEyNTYgLSBH
# MjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKPv0Z8p6djTgnY8YqDS
# SdYWHvHP8NC6SEMDLacd8gE0SaQQ6WIT9BP0FoO11VdCSIYrlViH6igEdMtyEQ9h
# JuH6HGEVxyibTQuCDyYrkDqW7aTQaymc9WGI5qRXb+70cNCNF97mZnZfdB5eDFM4
# XZD03zAtGxPReZhUGks4BPQHxCMD05LL94BdqpxWBkQtQUxItC3sNZKaxpXX9c6Q
# MeJ2s2G48XVXQqw7zivIkEnotybPuwyJy9DDo2qhydXjnFMrVyb+Vpp2/WFGomDs
# KUZH8s3ggmLGBFrn7U5AXEgGfZ1f53TJnoRlDVve3NMkHLQUEeurv8QfpLqZ0BdY
# Nc0CAwEAAaOB/TCB+jAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIB
# ADAdBgNVHQ4EFgQUGUq4WuRNMaUU5V7sL6Mc+oCMMmswRwYDVR0gBEAwPjA8BgRV
# HSAAMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3Jl
# cG9zaXRvcnkvMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9jcmwuZ2xvYmFsc2ln
# bi5uZXQvcm9vdC1yMy5jcmwwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHwYDVR0jBBgw
# FoAUj/BLf6guRSSuTVD6Y5qL3uLdG7wwDQYJKoZIhvcNAQELBQADggEBAHmwaTTi
# BYf2/tRgLC+GeTQD4LEHkwyEXPnk3GzPbrXsCly6C9BoMS4/ZL0Pgmtmd4F/ximl
# F9jwiU2DJBH2bv6d4UgKKKDieySApOzCmgDXsG1szYjVFXjPE/mIpXNNwTYr3MvO
# 23580ovvL72zT006rbtibiiTxAzL2ebK4BEClAOwvT+UKFaQHlPCJ9XJPM0aYx6C
# WRW2QMqngarDVa8z0bV16AnqRwhIIvtdG/Mseml+xddaXlYzPK1X6JMlQsPSXnE7
# ShxU7alVrCgFx8RsXdw8k/ZpPIJRzhoVPV4Bc/9Aouq0rtOO+u5dbEfHQfXUVlfy
# GDcy1tTMS/Zx4HYwggSfMIIDh6ADAgECAhIRIQaggdM/2HrlgkzBa1IJTgMwDQYJ
# KoZIhvcNAQEFBQAwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzIw
# HhcNMTUwMjAzMDAwMDAwWhcNMjYwMzAzMDAwMDAwWjBgMQswCQYDVQQGEwJTRzEf
# MB0GA1UEChMWR01PIEdsb2JhbFNpZ24gUHRlIEx0ZDEwMC4GA1UEAxMnR2xvYmFs
# U2lnbiBUU0EgZm9yIE1TIEF1dGhlbnRpY29kZSAtIEcyMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAsBeuotO2BDBWHlgPse1VpNZUy9j2czrsXV6rJf02
# pfqEw2FAxUa1WVI7QqIuXxNiEKlb5nPWkiWxfSPjBrOHOg5D8NcAiVOiETFSKG5d
# QHI88gl3p0mSl9RskKB2p/243LOd8gdgLE9YmABr0xVU4Prd/4AsXximmP/Uq+yh
# RVmyLm9iXeDZGayLV5yoJivZF6UQ0kcIGnAsM4t/aIAqtaFda92NAgIpA6p8N7u7
# KU49U5OzpvqP0liTFUy5LauAo6Ml+6/3CGSwekQPXBDXX2E3qk5r09JTJZ2Cc/os
# +XKwqRk5KlD6qdA8OsroW+/1X1H0+QrZlzXeaoXmIwRCrwIDAQABo4IBXzCCAVsw
# DgYDVR0PAQH/BAQDAgeAMEwGA1UdIARFMEMwQQYJKwYBBAGgMgEeMDQwMgYIKwYB
# BQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAkG
# A1UdEwQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9ncy9nc3RpbWVzdGFtcGluZ2cy
# LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly9zZWN1cmUu
# Z2xvYmFsc2lnbi5jb20vY2FjZXJ0L2dzdGltZXN0YW1waW5nZzIuY3J0MB0GA1Ud
# DgQWBBTUooRKOFoYf7pPMFC9ndV6h9YJ9zAfBgNVHSMEGDAWgBRG2D7/3OO+/4Pm
# 9IWbsN1q1hSpwTANBgkqhkiG9w0BAQUFAAOCAQEAgDLcB40coJydPCroPSGLWaFN
# fsxEzgO+fqq8xOZ7c7tL8YjakE51Nyg4Y7nXKw9UqVbOdzmXMHPNm9nZBUUcjaS4
# A11P2RwumODpiObs1wV+Vip79xZbo62PlyUShBuyXGNKCtLvEFRHgoQ1aSicDOQf
# FBYk+nXcdHJuTsrjakOvz302SNG96QaRLC+myHH9z73YnSGY/K/b3iKMr6fzd++d
# 3KNwS0Qa8HiFHvKljDm13IgcN+2tFPUHCya9vm0CXrG4sFhshToN9v9aJwzF3lPn
# VDxWTMlOTDD28lz7GozCgr6tWZH2G01Ve89bAdz9etNvI1wyR5sB88FRFEaKmzCC
# BNYwggO+oAMCAQICEhEhDRayW4wRltP+V8mGEea62TANBgkqhkiG9w0BAQsFADBa
# MQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEwMC4GA1UE
# AxMnR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBDQSAtIFNIQTI1NiAtIEcyMB4XDTE1
# MDUwNDE2NDMyMVoXDTE4MDUwNDE2NDMyMVowVTELMAkGA1UEBhMCQ0gxDDAKBgNV
# BAgTA1p1ZzEMMAoGA1UEBxMDWnVnMRQwEgYDVQQKEwtkLWZlbnMgR21iSDEUMBIG
# A1UEAxMLZC1mZW5zIEdtYkgwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDNPSzSNPylU9jFM78Q/GjzB7N+VNqikf/use7p8mpnBZ4cf5b4qV3rqQd62rJH
# RlAsxgouCSNQrl8xxfg6/t/I02kPvrzsR4xnDgMiVCqVRAeQsWebafWdTvWmONBS
# lxJejPP8TSgXMKFaDa+2HleTycTBYSoErAZSWpQ0NqF9zBadjsJRVatQuPkTDrwL
# eWibiyOipK9fcNoQpl5ll5H9EG668YJR3fqX9o0TQTkOmxXIL3IJ0UxdpyDpLEkt
# tBG6Y5wAdpF2dQX2phrfFNVY54JOGtuBkNGMSiLFzTkBA1fOlA6ICMYjB8xIFxVv
# rN1tYojCrqYkKMOjwWQz5X8zAgMBAAGjggGZMIIBlTAOBgNVHQ8BAf8EBAMCB4Aw
# TAYDVR0gBEUwQzBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93
# d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADATBgNVHSUE
# DDAKBggrBgEFBQcDAzBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8vY3JsLmdsb2Jh
# bHNpZ24uY29tL2dzL2dzY29kZXNpZ25zaGEyZzIuY3JsMIGQBggrBgEFBQcBAQSB
# gzCBgDBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNvbS9j
# YWNlcnQvZ3Njb2Rlc2lnbnNoYTJnMi5jcnQwOAYIKwYBBQUHMAGGLGh0dHA6Ly9v
# Y3NwMi5nbG9iYWxzaWduLmNvbS9nc2NvZGVzaWduc2hhMmcyMB0GA1UdDgQWBBTN
# GDddiIYZy9p3Z84iSIMd27rtUDAfBgNVHSMEGDAWgBQZSrha5E0xpRTlXuwvoxz6
# gIwyazANBgkqhkiG9w0BAQsFAAOCAQEAAApsOzSX1alF00fTeijB/aIthO3UB0ks
# 1Gg3xoKQC1iEQmFG/qlFLiufs52kRPN7L0a7ClNH3iQpaH5IEaUENT9cNEXdKTBG
# 8OrJS8lrDJXImgNEgtSwz0B40h7bM2Z+0DvXDvpmfyM2NwHF/nNVj7NzmczrLRqN
# 9de3tV0pgRqnIYordVcmb24CZl3bzpwzbQQy14Iz+P5Z2cnw+QaYzAuweTZxEUcJ
# bFwpM49c1LMPFJTuOKkUgY90JJ3gVTpyQxfkc7DNBnx74PlRzjFmeGC/hxQt0hvo
# eaAiBdjo/1uuCTToigVnyRH+c0T2AezTeoFb7ne3I538hWeTdU5q9jGCBLcwggSz
# AgEBMHAwWjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# MDAuBgNVBAMTJ0dsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBTSEEyNTYgLSBH
# MgISESENFrJbjBGW0/5XyYYR5rrZMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTEYf2XoiyG3zvw
# 3pebKHjwQl+CWjANBgkqhkiG9w0BAQEFAASCAQCpMxAcwN/PRwdnh9GEfUyqY+cg
# ggoEBrTu6fkhZMJDBSjzdXF9PhReEOt3TqjlupO4Rph2r7zSP+beDh5GTpGsYODn
# SBlGyNgA4KDydTeWViYxObNngHzHcNRtvIdPy86owmR72f/TJeqEyrlcwMC6Pbg3
# E5Lnf3myPXJeViFXUsbN4nn0qks2nvET/yZ1CB4EpUYG733mcd9aqxuXEHg3L+5j
# 3ExkpjOGQT5FDSGrmxv9KoVNByyePIucVwIhRdcekkldBkEvY0CT5jL6r40OLJxX
# FjFYm06IHh7x4Lf3jzz4r1n3TlaAYLYFRQrLLoZGs92fp+kmrkAzTKeoaxeJoYIC
# ojCCAp4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAX
# BgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGlt
# ZXN0YW1waW5nIENBIC0gRzICEhEhBqCB0z/YeuWCTMFrUglOAzAJBgUrDgMCGgUA
# oIH9MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE1
# MTEwNDE0MzkxOFowIwYJKoZIhvcNAQkEMRYEFE5bYtTiIwUSX5Mdgq8IrmiWOL8C
# MIGdBgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUs2MItNTN7U/PvWa5Vfrjv7Es
# KeYwbDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYt
# c2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh
# BqCB0z/YeuWCTMFrUglOAzANBgkqhkiG9w0BAQEFAASCAQAQuekRKtHSEjBiy7qt
# 3k3pjKgt7rtCqRxR5o2u/y057xDOUqgclVjVlom8q+9Bdvqumvxe6WIKIMS9J5Yi
# kjSOXxwgMWBDYI7iDdrYtNBKUiL91qYipGwYBlAI7T5mcIBXpMDBsGYSYxJZjyuc
# FXV+t0OqACWsLkLFttLWjQXFz1gyoMVehOPW5VB66sVXC8ycF5cDLuPz6H7das74
# m+XJJo3cU2kEadSO0HecVQAV0xbwp6/m2N564zlwMa/kqGJkXQRA/T6zFnEqpiZP
# tIrKBFSOF5wo3EXTSLjbhA0nTRaAjYCcmblWRBgrUJms5IxDFUFp4glddRYa0yr6
# elGC
# SIG # End signature block
