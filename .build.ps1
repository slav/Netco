<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)

.Description
	How to use this script and build the module:

	Get the utility script Invoke-Build.ps1:
	https://github.com/nightroman/Invoke-Build

	Copy it to the path. Set location to this directory. Build:
	PS> Invoke-Build Build

	This command builds the module and installs it to the $ModuleRoot which is
	the working location of the module. The build fails if the module is
	currently in use. Ensure it is not and then repeat.

	The build task Help fails if the help builder Helps is not installed.
	Ignore this or better get and use the script (it is really easy):
	https://github.com/nightroman/Helps
#>

param
(
	$Configuration = 'Release'
)

$project_name = "Netco"

# Folder structure:
# \build - Contains all code during the build process
# \build\artifacts - Contains all files during intermidiate bulid process
# \build\output - Contains the final result of the build process
# \release - Contains final release files for upload
# \release\archive - Contains files archived from the previous builds
# \src - Contains all source code
$build_dir = "$BuildRoot\build"
$log_dir = "$BuildRoot\log"
$build_artifacts_dir = "$build_dir\artifacts"
$build_output_dir = "$build_dir\output"
$release_dir = "$BuildRoot\release"
$archive_dir = "$release_dir\archive"

$src_dir = "$BuildRoot\src"
$solution_file = "$src_dir\Netco.sln"
$nuget = "$src_dir\.nuget\NuGet.exe"
	
# Use MSBuild.
use Framework\v4.0.30319 MSBuild

task Clean { 
	exec { MSBuild "$solution_file" /t:Clean /p:Configuration=$configuration /v:quiet } 
	Remove-Item -force -recurse $build_dir -ErrorAction SilentlyContinue | Out-Null
}

task Init Clean, { 
	New-Item $build_dir -itemType directory | Out-Null
	New-Item $build_artifacts_dir -itemType directory | Out-Null
	New-Item $build_output_dir -itemType directory | Out-Null
}, NuGetRestore

task NuGetRestore {
	exec{ . $nuget restore $solution_file }
}

task Build {
	exec { MSBuild "$solution_file" /t:Build /p:Configuration=$configuration /v:minimal /p:OutDir="$build_artifacts_dir\" }
}

task RunSpecs Build, {
	$nurunner = Get-ChildItem -recurse $src_dir\packages -include nunit-console.exe | Sort-Object LastWriteTime -descending | Select-Object -First 1
	$specs = Get-ChildItem -recurse $build_artifacts_dir\*.Specs.dll
		
	exec { . $nurunner.FullName $specs /result=$log_dir\Test.Results.xml /process=Multiple /framework:net-4.5 }
}

task Package  {
	New-Item $build_output_dir\Netco\lib\net45 -itemType directory -force | Out-Null
	Copy-Item $build_artifacts_dir\Netco.??? $build_output_dir\Netco\lib\net45 -PassThru |% { Write-Host "Copied " $_.FullName }
	
	New-Item $build_output_dir\Netco.NLog\lib\net45 -itemType directory -force | Out-Null
	Copy-Item $build_artifacts_dir\Netco.*.NLog*.* $build_output_dir\Netco.NLog\lib\net45 -PassThru |% { Write-Host "Copied " $_.FullName }
	
	New-Item $build_output_dir\Netco.Serilog\lib\net45 -itemType directory -force | Out-Null
	Copy-Item $build_artifacts_dir\Netco.*.Serilog*.* $build_output_dir\Netco.Serilog\lib\net45 -PassThru |% { Write-Host "Copied " $_.FullName }
}

# Set $script:Version = assembly version
task Version {
	assert (( Get-Item $build_artifacts_dir\Netco.dll ).VersionInfo.FileVersion -match '^(\d+\.\d+\.\d+)')
	$script:Version = $matches[1]
}

task Archive {
	New-Item $release_dir -ItemType directory -Force | Out-Null
	New-Item $archive_dir -ItemType directory -Force | Out-Null
	Move-Item -Path $release_dir\*.* -Destination $archive_dir
}

task Zip Version, {
	$7z = Get-ChildItem -recurse $src_dir\packages -include 7za.exe | Sort-Object LastWriteTime -descending | Select-Object -First 1
	$release_zip_file = "$release_dir\$project_name.$Version.zip"
	
	Write-Host "Zipping release to: " $release_zip_file
	
	exec { & $7z a $release_zip_file $build_output_dir\Netco\lib\net45\* -mx9 }
	exec { & $7z a $release_zip_file $build_output_dir\Netco.NLog\lib\net45\* -mx9 }
	exec { & $7z a $release_zip_file $build_output_dir\Netco.Serilog\lib\net45\* -mx9 }
}

task NuGet Package, Version, {

	Write-Host ================= Preparing Netco Nuget package =================
	$text = "Collection of common classes to simplify and speed up development. See documentation for details."
	# nuspec
	Set-Content $build_output_dir\Netco\Netco.nuspec @"
<?xml version="1.0"?>
<package>
	<metadata>
		<id>Netco</id>
		<version>$Version</version>
		<authors>Slav Ivanyuk</authors>
		<owners>Slav Ivanyuk</owners>
		<projectUrl>https://github.com/slav/Netco</projectUrl>
		<licenseUrl>https://raw.github.com/slav/Netco/master/License.txt</licenseUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<copyright>Copyright (C) Agile Harbor LLC</copyright>
		<summary>$text</summary>
		<description>$text</description>
		<tags></tags>
		<dependencies> 
			<dependency id="CuttingEdge.Conditions" version="1.2.0.0" />
		</dependencies>
	</metadata>
</package>
"@
	# pack
	exec { & $nuget pack $build_output_dir\Netco\Netco.nuspec -Output $build_dir }
	
	Write-Host ================= Preparing Netco NLog Integration Nuget package =================
	$text = "Integrates Netco to work with NLog platform."
	# nuspec
	Set-Content $build_output_dir\Netco.NLog\Netco.NLog.nuspec @"
<?xml version="1.0"?>
<package>
	<metadata>
		<id>Netco.NLog</id>
		<version>$Version</version>
		<authors>Slav Ivanyuk</authors>
		<owners>Slav Ivanyuk</owners>
		<projectUrl>https://github.com/slav/Netco</projectUrl>
		<licenseUrl>https://raw.github.com/slav/Netco/master/License.txt</licenseUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<copyright>Copyright (C) Agile Harbor LLC</copyright>
		<summary>$text</summary>
		<description>$text</description>
		<tags></tags>
		<dependencies> 
			<dependency id="Netco" version="$Version" />
			<dependency id="NLog" version="4.2.3" />
		</dependencies>
	</metadata>
</package>
"@
	# pack
	exec { & $nuget pack $build_output_dir\Netco.NLog\Netco.NLog.nuspec -Output $build_dir }
	
	Write-Host ================= Preparing Netco Serilog Integration Nuget package =================
	$text = "Integrates Netco to work with Serilog platform."
	# nuspec
	Set-Content $build_output_dir\Netco.Serilog\Netco.Serilog.nuspec @"
<?xml version="1.0"?>
<package>
	<metadata>
		<id>Netco.Serilog</id>
		<version>$Version</version>
		<authors>Slav Ivanyuk</authors>
		<owners>Slav Ivanyuk</owners>
		<projectUrl>https://github.com/slav/Netco</projectUrl>
		<licenseUrl>https://raw.github.com/slav/Netco/master/License.txt</licenseUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<copyright>Copyright (C) Agile Harbor LLC</copyright>
		<summary>$text</summary>
		<description>$text</description>
		<tags></tags>
		<dependencies> 
			<dependency id="Netco" version="$Version" />
			<dependency id="Serilog" version="1.5.14" />
		</dependencies>
	</metadata>
</package>
"@
	# pack
	exec { & $nuget pack $build_output_dir\Netco.Serilog\Netco.Serilog.nuspec -Output $build_dir }
	
	$pushNetco = Read-Host 'Push Netco ' $Version ' to NuGet? (Y/N)'
	Write-Host $pushNetco
	if( $pushNetco -eq "y" -or $pushNetco -eq "Y" )	{
		Get-ChildItem $build_dir\*.nupkg |% { exec { & $nuget push  $_.FullName }}
	}
}

task . Init, Build, RunSpecs, Package, Zip, NuGet