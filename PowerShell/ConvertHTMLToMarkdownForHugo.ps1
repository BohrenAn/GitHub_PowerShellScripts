###############################################################################
# Convert HTML Files to Markdown
# Used for my Hugo Blog
# V1.0 - Initial Version - Andres Bohren
###############################################################################

#Get HTML Files from a Directory
$Files = Get-Childitem C:\GIT_WorkingDir\blog.icewolf.ch\blog.icewolf.ch\content\202304 -Filter "*.html"

#Loop through the Files
Foreach ($File in $Files)
{
	$htmlfile = $File.VersionInfo.FileName
	Write-Host "Working on: $htmlfile"
	
	#$htmlfile = "C:\GIT_WorkingDir\blog.icewolf.ch\blog.icewolf.ch\content\202304\exchange-online-sends-now-dmarc-aggregate-reports.html"

	#Extract FrontMatter
	$html = Get-Content -Path $htmlfile -Raw
	$start = $html.IndexOf("---")
	$end = $html.IndexOf("---",4)
	$frontmatter = $html.Substring($start,$end+3)
	$frontmatter

	#Convert HTML to Markdown
	[string]$Markdown = ConvertFrom-HTMLToMarkdown -Path $HTMLfile -UnknownTags bypass -GithubFlavored
	$Markdown

	#Remove converted Fontmatter and add orginal FrontMatter
	$mdstart = $Markdown.IndexOf("---",4)
	$mdend = $Markdown.Length - $mdstart -3
	$MD = $frontmatter + $Markdown.Substring($mdstart+3,$mdend)

	#Replace FileName with .md
	$mdfile = $htmlfile.Replace("html","md")

	#Save converted Markdown
	Set-Content -path $Mdfile -value $md
	
}
