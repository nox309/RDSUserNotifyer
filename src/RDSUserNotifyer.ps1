<#
.NAME
    RDSUserNotifyer
.SYNOPSIS
    Script to notify user on terminal server / RDS.
.DESCRIPTION
    This small tool can notify users on RDS servers with the help of a poopup, where the text is freely selectable.
.FUNCTIONALITY
    TODO: Funktion beschreiben
.NOTES
    Author: nox309
    Email: support@inselmann.it
    Git: https://github.com/nox309
    Version: 0.1.0
    DateCreated: 2023/04/27
.EXAMPLE
    Get-Something -UserPrincipalName "username@thesysadminchannel.com"
.LINK
    https://github.com/nox309/RDSUserNotifyer/
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
$WID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$Prp = New-Object System.Security.Principal.WindowsPrincipal($WID)
$IsAdmin = $Prp.IsInRole($Adm)
if( !$IsAdmin ){
    Write-Host -ForegroundColor Red "The script does not have enough rights to run. Please start with admin rights!"
    break
    }

$ConfigFilePath = ".\config.ini"
if (-not (Test-Path $ConfigFilePath)) {
    Write-Warning "config.ini file not found. Creating default file."
    $defaultIniContent = @"
[Settings]
;the log path must be writable by every user
Logpath=\\Server\Logpath\RDSUserNotifyer\
;allowed values for the log level 'Information', 'Warning', 'Error', 'Debug
Loglevel=Information
ConsolenOutput=true
messagetitel=Info from the IT department
message=This is an example message.
rdsessionhost=false
Broker=DemoRDSB1.demo.local

[rdsessionhost]
;RDS Host can be extended arbitrarily in the same notation. If there is only one, please delete the key
RDS1=RDS1.demo.local
RDS2=RDS1.demo.local

"@
    $defaultIniContent | Out-File $ConfigFilePath -Encoding utf8
    Write-Warning "Config file with default data available, please adjust and restart script."
    Pause
    Break
    }

Write-host "Config present and readable"

#Check if necessary modules are present 
if (!(Get-Command Get-IniContent -ErrorAction SilentlyContinue)) {
    # Install the PsIni module from the PSGallery
    if (!(Get-Module -ListAvailable PsIni)) {
        Write-Host "Installing PsIni module from PSGallery..."
        Install-Module -Name PsIni -Repository PSGallery -Force -Confirm:$false
    }
    #Make sure that the function is now available.
    Import-Module PsIni
}
#---------------------------------------------------------[Config]-----------------------------------------------------------------
$config = Get-IniContent $ConfigFilePath

$date = (get-date -Format yyyyMMdd)
$filename = $date + "_RDSUserNotifyer.log"
$logpath = $config["Settings"]["Logpath"]
$cLoglevel = $config["Settings"]["Loglevel"]
$cConole = if ($config["Settings"]["ConsolenOutput"]) { $true } else { $false }
$log = $logpath + $filename
$rdsessionhost = if ($config["Settings"]["rdsessionhost"]) { $true } else { $false }
$Broker = $config["Settings"]["Broker"]

$messagetitel = $config["Settings"]["messagetitel"]
$message = $config["Settings"]["message"]


if(!(Test-Path  $logpath)) 
{
    mkdir $logpath
}
if(!(Test-Path  $log))
{
    "Timestamp | Severity | Message" | Out-File -FilePath $log -Append -Encoding utf8
    "$(get-date -Format yyyyMMdd-HH:mm:ss) | Information | Log started" | Out-File -FilePath $log -Append -Encoding utf8
}

#---------------------------------------------------------[Functions]--------------------------------------------------------------

#Log Funktion
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [parameter(Mandatory=$false)]
        [bool]$console, 

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error','Debug')]
        [string]$Severity = 'Information'
    )

    $time = (get-date -Format yyyyMMdd-HH:mm:ss)

    if ($console) {
        if ($Severity -eq "Information") {
            $color = "Gray"
        }

        if ($Severity -eq "Warning") {
            $color = "Yellow"
        }

        if ($Severity -eq "Error") {
            $color = "Red"
        }

        if ($Severity -eq "Debug") {
            $color = "Green"
        }

        Write-Host -ForegroundColor $color "$Time | $Severity | $Message"
    }

    "$Time | $Severity | $Message" | Out-File -FilePath $log -Append -Encoding utf8

}

#checking module if its installed
function Get-InstalledModule {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$modulename
    )
    
    if ($cLoglevel -eq "Debug"){
        Write-Log "Checking if module $modulename is installed correctly" -console $cConole -Severity $cLoglevel
    }
    if (Get-Module -ListAvailable -Name $modulename) {
      $Script:moduleavailable = $true
      if ($cLoglevel -eq "Debug"){
        Write-Log "Module $modulename found successfully!" -console $cConole -Severity $cLoglevel
        }
    } 
    else {
        if ($cLoglevel -eq "Debug"){
            Write-Log "Module $modulename not found!" -console $cConole -Severity $cLoglevel
            Write-Log "Module $modulename will be installed now!" -console $cConole -Severity $cLoglevel
            }
        if ($cLoglevel -eq "Error"){
            Write-Log "Module $modulename not found!" -console $cConole -Severity $cLoglevel
            Write-Log "Module $modulename will be installed now!" -console $cConole -Severity $cLoglevel
            }
        if ($cLoglevel -eq "Warning"){
            Write-Log "Module $modulename not found!" -console $cConole -Severity $cLoglevel
            Write-Log "Module $modulename will be installed now!" -console $cConole -Severity $cLoglevel
            }
        Install-Module $modulename
    }
  
  }

 #checking if module is imported, if not load it
  function Get-ImportedModule {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$modulename
    )
         #check if module is imported, otherwise try to import it
         if (Get-Module -Name $modulename) {
            if ($cLoglevel -eq "Debug"){
                Write-Log "Module $modulename already loaded" -console $cConole -Severity $cLoglevel
                }

        }
        else {
            if ($cLoglevel -eq "Debug"){
                Write-Log "Module found but not imported, import starting" -console $cConole -Severity $cLoglevel
                }
            if ($cLoglevel -eq "Error"){
                Write-Log "Module found but not imported, import starting" -console $cConole -Severity $cLoglevel
                }
            if ($cLoglevel -eq "Warning"){
                Write-Log "Module found but not imported, import starting" -console $cConole -Severity $cLoglevel
                }
            Import-Module $modulename -force
            Write-Log "Module $modulename loaded successfully" -console $cConole -Severity $cLoglevel
        }
  }

  function Send-RDMessageAll {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$msgtitel,
      [Parameter(Mandatory = $true)]
      [string]$msg,
      [Parameter(Mandatory = $true)]
      [string]$Allbroker
  
    )
         #getting all active session on rdbroker
         Write-Verbose "Getting all user ids from active users"
         $userids = Get-RDUserSession -ConnectionBroker "$Allbroker" | Sort-Object Username
         Write-Output "script paused for 10 seconds before sending, to abort press crtl+c ... "
         Write-Verbose "waiting 10 seconds before sending to all users on broker $broAllbrokerer"
         Start-Sleep -Seconds 10
         #send message to each user with active session
         foreach($uid in $userids){
            $id = (($uid).UnifiedSessionID)
            $user = (($uid).UserName)
            $hostserver = (($uid).HostServer)
            Write-output "sending message to $user with titel $msgtitel on server $hostserver"
            Send-RDUserMessage -HostServer $Allbroker -UnifiedSessionID $id -MessageTitle "$msgtitel" -MessageBody "$msg"
            Write-Verbose "send message on rdbroker $Allbroker to usersessionid $id with titel $msgtitel on RDSH $hostserver"
            }
            
  }

  function Send-RDMessageRDSH {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory = $true)]
      [string]$msgtitel,
      [Parameter(Mandatory = $true)]
      [string]$msg,
      [Parameter(Mandatory = $true)]
      [string]$RDSHbroker,
      [Parameter(Mandatory = $true)]
      [string]$sessionhost
  
    )
         #getting all active session on rdbroker
         Write-Verbose "Getting all user ids from active users"
         $userids = Get-RDUserSession -ConnectionBroker "$RDSHbroker"| Where-Object {$_.HostServer -eq "$sessionhost"} | Sort-Object Username
         Write-Output "script paused for 10 seconds before sending, to abort press crtl+c ... "
         Write-Verbose "waiting 10 seconds before sending to users on sessionhost $RDSHbroker "
         Start-Sleep -Seconds 10
         #send message to each user with active session
         foreach($uid in $userids){
            $id = (($uid).UnifiedSessionID)
            $user = (($uid).UserName)
            $hostserver = (($uid).HostServer)
            Write-output "sending message to $user with titel $msgtitel"
            Send-RDUserMessage -HostServer $RDSHbroker -UnifiedSessionID $id -MessageTitle "$msgtitel" -MessageBody "$msg"
            Write-Verbose "send message on rdbroker $RDSHbroker to usersessionid $id with titel $msgtitel on RDSH $hostserver"
            }
            
  }
#---------------------------------------------------------[Logic]-------------------------------------------------------------------
if ($cLoglevel -eq "Debug"){
    Write-Log "The following log path was taken from the config: $logpath" -console $cConole -Severity $cLoglevel
    Write-Log "The following log level was taken from the config: $cLoglevel" -console $cConole -Severity $cLoglevel
    Write-Log "The following setting for displaying log information on the console was taken from the config: Show Console Output $cConole" -console $cConole -Severity $cLoglevel
    Write-Log "The following RDS brokers were loaded from the config" -console $cConole -Severity $cLoglevel
    foreach($Server in $Config["Broker"].Keys){
        $ServerValue = $Config["Broker"][$Server]
        Write-Log "RDS Broker: $ServerValue" -console $cConole -Severity $cLoglevel
    }
}

#call functions
Get-InstalledModule -modulename RemoteDesktop
Get-ImportedModule -modulename RemoteDesktop
if (!(Get-Command Send-RDUserMessage -ErrorAction SilentlyContinue)) {
    # Install the PsIni module from the PSGallery
    if (!(Get-Module -ListAvailable PsIni)) {
        Write-Log "It seems that the necessary module for Send-RDUserMessage is not available. Please check and if necessary install the RSAT tools and make the function available and try again." -console $true -Severity Error
        Pause
        Break
    }
}

# Enter the message details
Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "RDS User Notifyer"
$form.Width = 400
$form.Height = 300
$form.BringToFront()

# Creating the text field for the title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.Width = 350
$titleLabel.Text = "What is the headline of your message?"
$form.Controls.Add($titleLabel)

$titleTextBox = New-Object System.Windows.Forms.TextBox
$titleTextBox.Location = New-Object System.Drawing.Point(10, 30)
$titleTextBox.Width = 350
$titleTextBox.Text = $messagetitel
$form.Controls.Add($titleTextBox)

# Creating the text field for the content
$messageLabel = New-Object System.Windows.Forms.Label
$messageLabel.Location = New-Object System.Drawing.Point(10, 60)
$messageLabel.Width = 350
$messageLabel.Text = "What is the content of your message?"
$form.Controls.Add($messageLabel)

$messageTextBox = New-Object System.Windows.Forms.TextBox
$messageTextBox.Location = New-Object System.Drawing.Point(10, 80)
$messageTextBox.Multiline = $true
$messageTextBox.Width = 350
$messageTextBox.Height = 120
$messageTextBox.ScrollBars = "Vertical"
$messageTextBox.Text = $message
$form.Controls.Add($messageTextBox)

# Creating the OK button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(10, 220)
$okButton.Text = "OK"
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

# Displaying the form and waiting for the user action
$result = $form.ShowDialog()

# Check if the OK button has been clicked and save the input
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $messagetitel = $titleTextBox.Text
    $message = $messageTextBox.Text

    Write-Host "Title: $messagetitel"
    Write-Host "Message: $message"
}

Write-Log "The following value was chosen as the messagetitel: $messagetitel" -console $false -Severity $cLoglevel
Write-Log "The following value was chosen as the message: $message" -console $false -Severity $cLoglevel

if ($rdsessionhost) {
    Write-Log "Parameter rdessionhost is Ture, only connections on $rdsessionhost will be notified!" -console $false -Severity $cLoglevel
    Send-RDMessageRDSH -broker $Broker -sessionhost $rdsessionhost -msgtitel $messagetitel -msg $message
    }
    else {
    Write-Verbose "No RDSessionHost Server specified, all users on $Broker will be notified"
    Write-Log "No RDSessionHost Server specified, all users on $Broker will be notified" -console $false -Severity $cLoglevel
    Send-RDMessageAll -msgtitel $messagetitel -msg $message -broker $Broker

}

