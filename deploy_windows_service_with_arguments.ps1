### Arguments:
### -projectFolder:"Tm.RequestService.Svc"
### -projectName:"Tm.RequestService.Svc.csproj"
### -configuration:"Develop"
### -remoteServer:"192.168.30.4"
### -remoteServiceName:"Tm.RequestService.Svc-Develop"
### -remoteServicePath:"\\192.168.30.4\Telemedicine\Develop\Tm.RequestService.Svc"

param(
    [parameter(Mandatory=$true)] [string]$projectFolder,
    [parameter(Mandatory=$true)] [string]$projectName,
    [parameter(Mandatory=$true)] [string]$configuration,
    [parameter(Mandatory=$true)] [string]$remoteServer,
    [parameter(Mandatory=$true)] [string]$remoteServiceName,
    [parameter(Mandatory=$true)] [string]$remoteServicePath
)

$msbuild = "C:\Program Files (x86)\MSBuild\14.0\Bin\MsBuild.exe"
$project = "$($projectFolder)\$($projectName)"
$outputPath = "bin\$($configuration)\";

Write-Output "Searching service..."
$service = (Get-WmiObject -Computer $remoteServer Win32_Service -Filter "Name='$remoteServiceName'" )
if($service) {
	Write-Output "Service found..."

	### Init backup & deploy
	Write-Output "Initialization..."
	net use $remoteServicePath /delete
	net use $remoteServicePath

	### Build
	$params = @(
		$project,
		"/p:Configuration=$($configuration)",	
		"/p:OutputPath=$($outputPath)",
		"/t:Clean,Build"
	)
	Write-Output "Building..."
	& $msbuild $params
	if($LastExitCode) { 
		Write-Output "Build failed..."
		exit $LastExitCode;
	}

	### Stop service
	Write-Output "Stopping remote service..."
	$service.stopservice()
	   
	### Deploy
	Write-Output "Deploying..."
	robocopy.exe /mir "$($projectFolder)\$($outputPath)" $remoteServicePath

	### Start service
	Write-Output "Starting remote service..."
	$service.startservice()

	### Disposing
	Write-Output "Disposing..."
	net use $remoteServicePath /delete 
}
