$msbuild = "C:\Program Files (x86)\MSBuild\14.0\Bin\MsBuild.exe"

$projectFolder = "Tm.VoxImplant.Svc"
$project = "$($projectFolder)\Tm.VoxImplant.Svc.csproj"
$configuration = "Stage"
$outputPath = "bin\$($configuration)\";

$remoteServer = "192.168.1.1"
$remoteServiceName = "Tm.VoxImplant.Svc"
$remoteServicePath = "\\192.168.1.1\Telemedicine\Tm.VoxImplant.Svc"
$remoteServiceBackupPath = "\\192.168.1.1\Telemedicine\Backup"

$backupFolderName = (Split-Path $remoteServicePath -Leaf) + [DateTime]::Now.ToString("_yyyyMMdd-HHmmss")
$remoteServiceBackupFolderPath = ($remoteServiceBackupPath + "\" + $backupFolderName)


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

	### Backup
	Write-Output "Backuping..."
	robocopy.exe $remoteServicePath $remoteServiceBackupFolderPath /mir

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