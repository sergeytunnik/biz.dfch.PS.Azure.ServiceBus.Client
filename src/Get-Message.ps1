function Get-Message {
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
$message = Get-Message;
$message

Creates a message for the Service Bus Message Factory and against server defined within module configuration xml file.

	
#>
[CmdletBinding(
	HelpURI = 'http://dfch.biz/biz/dfch/PS/AzureServiceBus/Client/'
)]
[OutputType([Microsoft.ServiceBus.Messaging.BrokeredMessage])]
Param 
(
	# [Optional] The MessageSequenceNumber for a deferred message.
	[Parameter(Mandatory = $false, Position = 0)]
	[long] $MessageSequenceNumber
	, 
	# [Optional] The WaitTimeOutSec such as '10' Seconds for receiving a message before it times out. If you do not specify this 
	# value it is taken from the default parameter.
	[Parameter(Mandatory = $false, Position = 1)]
	[int] $WaitTimeoutSec = 10
	, 
	# [Optional] The Receivemode such as 'PeekLock'. If you do not specify this 
	# value it is taken from the default parameter.
	[Parameter(Mandatory = $false, Position = 2)]
	[ValidateSet('PeekLock', 'ReceiveAndDelete')]
	[string] $Receivemode = 'PeekLock'
	,
	# [Optional] The QueueName such as 'MyQueue'. If you do not specify this 
	# value it is taken from the module configuration file.
	[Parameter(Mandatory = $false, Position = 3)]
	[string] $QueueName = (Get-Variable -Name $MyInvocation.MyCommand.Module.PrivateData.MODULEVAR -ValueOnly).DefaultQueueName
	, 
	# Encrypted credentials as [System.Management.Automation.PSCredential] with 
	# which to perform login. Default is credential as specified in the module 
	# configuration file.
	[Parameter(Mandatory = $false, Position = 4)]
	[alias("cred")]
	$Credential = (Get-Variable -Name $MyInvocation.MyCommand.Module.PrivateData.MODULEVAR -ValueOnly).Credential
)

BEGIN 
{
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug $fn ("CALL. QueueName '{0}'; Username '{1}'" -f $QueueName, $Credential.Username ) -fac 1;

}
# BEGIN 

PROCESS 
{

[boolean] $fReturn = $false;

try 
{
	# Parameter validation
	# N/A
	
	# Create MessageClient
	$MessageClient = New-MessageReceiver -QueueName $QueueName -Receivemode $Receivemode;
	
	# Get Message
	[Microsoft.ServiceBus.Messaging.BrokeredMessage] $BrokeredMessage = $MessageClient.Receive((New-TimeSpan -Seconds $WaitTimeoutSec));
	$OutputParameter = $BrokeredMessage;
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

if($MyInvocation.ScriptName) { Export-ModuleMember -Function Get-Message; } 

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