#***************************************************************************************************************
# Author: Damien VAN ROBAEYS
# Website: http://www.systanddeploy.com
# Twitter: https://twitter.com/syst_and_deploy
#***************************************************************************************************************
Param
 (
	[String]$Type,	  
	[String]$ScriptPath	
 )

$FolderPath = Split-Path (Split-Path "$ScriptPath" -Parent) -Leaf
$FileName = (get-item $ScriptPath).BaseName
$Full_FileName = (get-item $ScriptPath).Name
$DirectoryName = (get-item $ScriptPath).DirectoryName

$Sandbox_Shared_Path = "C:\Users\WDAGUtilityAccount\Desktop\$FolderPath"
$Full_Startup_Path = "$Sandbox_Shared_Path\$Full_FileName"
$Full_Startup_Path = """$Full_Startup_Path"""

$ProgData = $env:ProgramData
$Run_in_Sandbox_Folder = "$ProgData\Run_in_Sandbox"

$xml = "$Run_in_Sandbox_Folder\Sandbox_Config.xml"
$my_xml = [xml] (Get-Content $xml)
$Sandbox_VGpu = $my_xml.Configuration.VGpu
$Sandbox_Networking = $my_xml.Configuration.Networking
$Sandbox_ReadOnlyAccess = $my_xml.Configuration.ReadOnlyAccess

$User_Profile = $env:USERPROFILE
$User_Desktop = "$User_Profile\Desktop"
$Sandbox_File_Path = "$User_Desktop\$FileName.wsb"

If(test-path $Sandbox_File_Path)
	{
		remove-item $Sandbox_File_Path
	}

Function Generate_WSB
	{
		Param
		 (
			[String]$Command_to_Run	
		 )	
		 
		new-item $Sandbox_File_Path -type file -force | out-null
		add-content $Sandbox_File_Path  "<Configuration>"	
		add-content $Sandbox_File_Path  "<VGpu>$Sandbox_VGpu</VGpu>"	
		add-content $Sandbox_File_Path  "<Networking>$Sandbox_Networking</Networking>"	

		add-content $Sandbox_File_Path  "<MappedFolders>"	
		add-content $Sandbox_File_Path  "<MappedFolder>"	
		add-content $Sandbox_File_Path  "<HostFolder>$DirectoryName</HostFolder>"	
		add-content $Sandbox_File_Path  "<ReadOnly>$Sandbox_ReadOnlyAccess</ReadOnly>"	
		add-content $Sandbox_File_Path  "</MappedFolder>"	
		add-content $Sandbox_File_Path  "</MappedFolders>"	

		add-content $Sandbox_File_Path  "<LogonCommand>"	
		add-content $Sandbox_File_Path  "<Command>$Command_to_Run</Command>"	
		add-content $Sandbox_File_Path  "</LogonCommand>"	
		add-content $Sandbox_File_Path  "</Configuration>"		
	}

	
If($Type -eq "PS1Params")
	{
		$Full_Startup_Path = $Full_Startup_Path.Replace('"',"")
	
		[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 	| out-null	
		[System.Reflection.Assembly]::LoadFrom("$Run_in_Sandbox_Folder\assembly\MahApps.Metro.dll") | out-null 
		[System.Reflection.Assembly]::LoadFrom("$Run_in_Sandbox_Folder\assembly\MahApps.Metro.IconPacks.dll") | out-null  	
		function LoadXml ($global:file1)
		{
			$XamlLoader=(New-Object System.Xml.XmlDocument)
			$XamlLoader.Load($file1)
			return $XamlLoader
		}

		$XamlMainWindow=LoadXml("$Run_in_Sandbox_Folder\RunInSandbox_Params.xaml")
		$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
		$Form_PS1 = [Windows.Markup.XamlReader]::Load($Reader)		
			
		$parameters_to_add = $Form_PS1.findname("parameters_to_add") 
		$add_parameters = $Form_PS1.findname("add_parameters") 
		
		$add_parameters.add_click({
			$Script:Paramaters = $parameters_to_add.Text.ToString()
			$Script:Startup_Command = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -sta -WindowStyle Hidden -noprofile -executionpolicy unrestricted -file $Full_Startup_Path $Paramaters"				
			
			Generate_WSB -Command_to_Run $Startup_Command				
			$Form_PS1.close()
		})
		
		$Form_PS1.Add_Closing({
			$Script:Paramaters = $parameters_to_add.Text.ToString()
			$Script:Startup_Command = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -sta -WindowStyle Hidden -noprofile -executionpolicy unrestricted -file $Full_Startup_Path $Paramaters"				
			Generate_WSB -Command_to_Run $Startup_Command				
		})			
		
		
		$Form_PS1.ShowDialog() | Out-Null	
	}
	
ElseIf($Type -eq "PS1Basic")
	{
		$Script:Startup_Command = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -sta -WindowStyle Hidden -noprofile -executionpolicy unrestricted -file $Full_Startup_Path"			

		Generate_WSB -Command_to_Run $Startup_Command		
	}	
	
ElseIf($Type -eq "EXE")
	{
		$Full_Startup_Path = $Full_Startup_Path.Replace('"',"")

		[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 				| out-null	
		[System.Reflection.Assembly]::LoadFrom("$Run_in_Sandbox_Folder\assembly\MahApps.Metro.dll") | out-null 
		[System.Reflection.Assembly]::LoadFrom("$Run_in_Sandbox_Folder\assembly\MahApps.Metro.IconPacks.dll")      | out-null  
		function LoadXml ($global:file2)
		{
			$XamlLoader=(New-Object System.Xml.XmlDocument)
			$XamlLoader.Load($file2)
			return $XamlLoader
		}

		$XamlMainWindow=LoadXml("$Run_in_Sandbox_Folder\RunInSandbox_EXE.xaml")
		$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
		$Form_EXE=[Windows.Markup.XamlReader]::Load($Reader)		
			
		$swicthes_for_exe = $Form_EXE.findname("swicthes_for_exe") 
		$add_swicthes = $Form_EXE.findname("add_swicthes") 
		
		$add_swicthes.Add_Click({
			$Global:Swicthes_EXE = $swicthes_for_exe.Text.ToString()
			$Script:Startup_Command = "$Full_Startup_Path $Swicthes_EXE"				

			Generate_WSB -Command_to_Run $Startup_Command						
			$Form_EXE.close()
		})		
		
		$Form_EXE.Add_Closing({
			$Global:Swicthes_EXE = $swicthes_for_exe.Text.ToString()
			$Script:Startup_Command = "$Full_Startup_Path $Swicthes_EXE"				
			Generate_WSB -Command_to_Run $Startup_Command						
		})			
		
		$Form_EXE.ShowDialog() | Out-Null			
	}
	
ElseIf($Type -eq "MSI")
	{
		$Full_Startup_Path = $Full_Startup_Path.Replace('"',"")

		[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 				| out-null	
		[System.Reflection.Assembly]::LoadFrom("$Run_in_Sandbox_Folder\assembly\MahApps.Metro.dll") | out-null 
		[System.Reflection.Assembly]::LoadFrom("$Run_in_Sandbox_Folder\assembly\MahApps.Metro.IconPacks.dll")      | out-null  
		function LoadXml ($global:file2)
		{
			$XamlLoader=(New-Object System.Xml.XmlDocument)
			$XamlLoader.Load($file2)
			return $XamlLoader
		}

		$XamlMainWindow=LoadXml("$Run_in_Sandbox_Folder\RunInSandbox_EXE.xaml")
		$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
		$Form_MSI=[Windows.Markup.XamlReader]::Load($Reader)		
			
		$swicthes_for_exe = $Form_MSI.findname("swicthes_for_exe") 
		$add_swicthes = $Form_MSI.findname("add_swicthes") 
		
		$add_swicthes.Add_Click({
			$Global:Swicthes_MSI = $swicthes_for_exe.Text.ToString()
			$Script:Startup_Command = "$Full_Startup_Path $Swicthes_MSI"			
			Generate_WSB -Command_to_Run $Startup_Command						
			$Form_MSI.close()
		})		
		
		$Form_MSI.Add_Closing({
			$Global:Swicthes_MSI = $swicthes_for_exe.Text.ToString()
			$Script:Startup_Command = "$Full_Startup_Path $Swicthes_MSI"						
			Generate_WSB -Command_to_Run $Startup_Command						
		})			
		
		$Form_MSI.ShowDialog() | Out-Null			
	}	

ElseIf($Type -eq "VBSParams")
	{
		$Full_Startup_Path = $Full_Startup_Path.Replace('"',"")
	
		[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 	| out-null	
		[System.Reflection.Assembly]::LoadFrom("$Run_in_Sandbox_Folder\assembly\MahApps.Metro.dll") | out-null 
		[System.Reflection.Assembly]::LoadFrom("$Run_in_Sandbox_Folder\assembly\MahApps.Metro.IconPacks.dll") | out-null  	
		function LoadXml ($global:file1)
		{
			$XamlLoader=(New-Object System.Xml.XmlDocument)
			$XamlLoader.Load($file1)
			return $XamlLoader
		}

		$XamlMainWindow=LoadXml("$Run_in_Sandbox_Folder\RunInSandbox_Params.xaml")
		$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
		$Form_VBS = [Windows.Markup.XamlReader]::Load($Reader)		
			
		$parameters_to_add = $Form_VBS.findname("parameters_to_add") 
		$add_parameters = $Form_VBS.findname("add_parameters") 
		
		$add_parameters.add_click({
			$Script:Paramaters = $parameters_to_add.Text.ToString()
			$Script:Startup_Command = "wscript.exe $Full_Startup_Path $Paramaters"	
			Generate_WSB -Command_to_Run $Startup_Command					
			$Form_VBS.close()
		})
		
		$Form_VBS.Add_Closing({
			$Script:Paramaters = $parameters_to_add.Text.ToString()
			$Script:Startup_Command = "wscript.exe $Full_Startup_Path $Paramaters"			
			Generate_WSB -Command_to_Run $Startup_Command						
		})				

		$Form_VBS.ShowDialog() | Out-Null	
	}
	
ElseIf($Type -eq "VBSBasic")
	{
		$Script:Startup_Command = "wscript.exe $Full_Startup_Path"	
		
		Generate_WSB -Command_to_Run $Startup_Command		
	}

& $Sandbox_File_Path