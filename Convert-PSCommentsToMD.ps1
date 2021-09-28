<#
	.SYNOPSIS
		Converts comment-based help to Markdown format.
	.DESCRIPTION
		Gets the comment-based help from the specified Powershell command and creates a Markdown formatted file.
	.PARAMETER Command
		A command name to retrieve its comment-based help.
	.PARAMETER Markdown
		The Markdown file path where the comment-based help will be stored. 
	.EXAMPLE
		Convert-PSCommentsToMD.ps1 Select-Object
		Gets comment-based help of `Select-Object` command, formats to Markdown and saves it to `Select-Object.md` in the current directory.
	.EXAMPLE
		Convert-PSCommentsToMD.ps1 Select-Object -Markdown C:\SelectObject.md
		Gets comment-based help of `Select-Object` command, formats to Markdown and saves it to the path specified by -Markdown.
#>
[CmdletBinding()]
param
(
	[Parameter(Mandatory=$true)][string]$Command,
	[string]$Markdown = "$Command.md"
)
function Add([string]$content)
{
	<#
		.SYNOPSIS
			Adds specified content to markdown file.
	#>
	Add-Content $Markdown $content
}
function GetTypeLink($type)
{
	<#
		.SYNOPSIS
			Gets documentation of the specified type.
	#>
	"[$($type.Name)](https://docs.microsoft.com/dotnet/api/$($type.Name))"
}
# ─── Get help ───────────────────────────────────────────────────────────────────
$help = Get-Help $Command -Full # Get command help
if (-not $help)
{
	return
}
# ─── Change buffer size ─────────────────────────────────────────────────────────
$bufferSizeCurrentWidth = $Host.UI.RawUI.BufferSize.Width
try
{
	$Host.UI.RawUI.BufferSize = New-Object $Host.UI.RawUI.BufferSize.GetType().FullName (512, $Host.UI.RawUI.BufferSize.Height)
	$newLine = "`r`n"
# ─── Create Markdown file ───────────────────────────────────────────────────────
	Set-Content $Markdown "# $($help.Name)" # Add command name
# ─── Add synopsis ───────────────────────────────────────────────────────────────
	if ($help.Synopsis -and $help.Synopsis -ne "")
	{
		Add ">$($help.Synopsis)$newLine"
	}
# ─── Add description ────────────────────────────────────────────────────────────
	if ($help.Description)
	{
		Add "$newLine$(($help.Description | Out-String).Trim())"
	}
	if ($help.Syntax)
	{
		Add @"
## Syntax
``````powershell
$((($help.Syntax | Out-String) -replace $newLine, $($newLine + $newLine)).Trim())
``````
"@
	}
# ─── Add examples ───────────────────────────────────────────────────────────────
	if ($help.Examples)
	{
		Add "## Examples"
		foreach ($example in $help.Examples.Example)
		{
			$codeAndRemarks = (($example | Out-String) -replace ($example.Title), "").Trim() -split $newLine
			for ($i = 0; $i -lt $codeAndRemarks.Length; $i++)
			{
				if (1 -le $i -and $i -le 2)
				{
					continue
				}
				Add $codeAndRemarks[$i]
			}
			Add $newLine
		}
	}
# ─── Add parameters ─────────────────────────────────────────────────────────────
	if ($help.Parameters)
	{
		Add "## Parameters"
		foreach ($parameter in $help.parameters.parameter)
		{
			Add @"
### -$($parameter.name) &lt;$($parameter.type.name)&gt;
$(($parameter.Description | Out-String).Trim())
``````
$(((($parameter | Out-String).Trim() -split $newLine)[-5..-1] | ForEach-Object { $_.Trim() }) -join $newLine)
``````
"@
		}
	}
# ─── Add inputs ─────────────────────────────────────────────────────────────────
	if ($help.InputTypes)
	{
		Add @"
## Inputs
$(GetTypeLink $help.InputTypes.InputType.Type)
"@
	}
# ─── Add outputs ────────────────────────────────────────────────────────────────
	if ($help.ReturnValues)
	{
		Add @"
## Outputs
$(GetTypeLink $help.ReturnValues.ReturnValue.Type)
"@
	}
# ─── Add notes ──────────────────────────────────────────────────────────────────
	if ($help.alertSet)
	{
		Add @"
## Notes
$(($help.alertSet.Alert | Out-String).Trim())
"@
	}
}
# ─── Restore buffer size ────────────────────────────────────────────────────────
finally
{
	if ($Host.UI.RawUI -and $Host.UI.RawUI.BufferSize.Width -lt 512)
	{
		$Host.UI.RawUI.BufferSize = New-Object $Host.UI.RawUI.BufferSize.GetType().FullName ($bufferSizeCurrentWidth, $Host.UI.RawUI.BufferSize.Height)
	}
}