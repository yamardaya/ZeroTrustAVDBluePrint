<#
.SYNOPSIS
    Reads Zero Trust scenarios from Excel and generates corresponding C# code to represent scenarios.
.DESCRIPTION
    This cmdlet assumes the file ZeroTrust config file 'Zero Trust Scenarios_ForWizards_UseThisCopy.xlsx' 
    stored in the ZT Advisory V-Team SharePoint site has been synced to the local device where this script is running.
    Run the script to import the latest wording from the config file to a .cs file.
    The .cs file needs to include a region with the following name.
    #region AutoGeneratedZeroTrustDataFromExcel

    The generated code will be 
    Requires module
    * Install-Module ImportExcel

.EXAMPLE
    PS C:\> Import-ZeroTrustScenarios 
        -ExcelPath 'F:\OneDrive\Zero Trust Scenarios_ForWizards_UseThisCopy.xlsx'
        -AssessmentSharedProjectFolder 'F:\code\msassessment\src\Assessment\Assessment.Shared'
#>

param (
    # Location of the Zero Trust Scenarios excel file. e.g. 'F:\OneDrive\Zero Trust Scenarios_ForWizards_UseThisCopy.xlsx'
    [Parameter(Mandatory = $true)]
    [string] $ExcelPath,

    # Location of the Assessment.Shared project folderwhere the generated C# code will be inserted. e.g. 'F:\code\msassessment\src\Assessment\Assessment.Shared'
    [Parameter(Mandatory = $true)]
    [string] $AssessmentSharedProjectFolder
)

# Removes new line characters and returns the first line in the cell.
function GetFirstLine($text) {
    if ($text) {
        $arr = $text -split "`n"
        foreach ($line in $arr) {
            if (![string]::IsNullOrEmpty($line)) {
                return $line.Trim()
            }
        }
        return $text.Trim()    
    }
    else {
        return $text
    }
}

function GetClassName($checkId) {
    if([string]::IsNullOrEmpty($checkId)) { return $null }

    $checkIdItems = $checkId -split "_"
    if($checkIdItems.Length -eq 2){
        $classPrefix = $checkIdItems[0]
        $recoCodeFolder = Join-Path $AssessmentSharedProjectFolder '\ZeroTrust\Recommendations'
        $recoFilePath = Get-ChildItem -Path $recoCodeFolder -Filter "$($classPrefix)_*"
        if($recoFilePath){
            return [System.IO.Path]::GetFileNameWithoutExtension($recoFilePath)
        }
        else {
            throw "No classname with $classPrefix prefix was found in the Assessment.Shared/Recommendations folder."
        }
    }
    else {
        throw "$checkId is not a valid name for Name in ZT Assessment Tool. Needs to be in format Rnnnn_Cnn."
    }
}

Import-Module PSExcel

$ztScenarios = Import-Excel $ExcelPath -WorksheetName "Wizards- Foundational Scenarios" -Raw -StartRow 2
$excel = New-Excel -Path $ExcelPath
$ws = $excel.Workbook.Worksheets[1]

$code = "#region AutoGeneratedZeroTrustDataFromExcel`r`n"
$code += "        private ZeroTrustData InitializeMetadata()`r`n"
$code += "        {`r`n"
$code += "            ZeroTrustData zeroTrustData = new ZeroTrustData();`r`n"
$code += "            ZeroTrustBusinessScenario bs; ZeroTrustTechnicalScenario ts; ZeroTrustRecommendation r; ZeroTrustCheck c;`r`n"

$row = 3

while($row -lt 500){   

    $bs = GetFirstLine $ws.Cells[$row, 4].Value #$item.'Business Scenario'
    $ts = GetFirstLine $ws.Cells[$row, 5].Value #$item.'Technical Scenario'
    $r = GetFirstLine $ws.Cells[$row, 6].Value #$item.'M365 Controls / IT Actions'
    $checkId = $ws.Cells[$row, 11].Value #$item.'Name in ZT Asssessment Tool'
    $c = GetFirstLine $ws.Cells[$row, 7].Value #$item.'Sub Tasks'
    $docLinkText = $ws.Cells[$row, 8].Value #Link to docs
    $docLinkUrl = $ws.Cells[$row, 8].Hyperlink.OriginalString #Link to docs
    $license = $ws.Cells[$row, 9].Value #$item.'License Required'
    $productName = $ws.Cells[$row, 10].Value #$item.'Product Name'
    $ztPrincipal = $ws.Cells[$row, 12].Value #$item.'Zero Trust Principal'

    if (![string]::IsNullOrEmpty($bs)) {
        $code += "            bs = new ZeroTrustBusinessScenario() { Name = `"$bs`" }; zeroTrustData.BusinessScenarios.Add(bs);`r`n"
    }
    
    if (![string]::IsNullOrEmpty($ts)) {
        $code += "               ts = new ZeroTrustTechnicalScenario() { Name = `"$ts`" }; bs.TechnicalScenarios.Add(ts);`r`n"
    }
    if (![string]::IsNullOrEmpty($r)) {
        $className = GetClassName $checkId
        $code += "                  r = new ZeroTrustRecommendation() { Name = `"$r`", ClassName = `"$className`" }; ts.Recommendations.Add(r);`r`n"
    }

    if (![string]::IsNullOrEmpty($c) -and ($checkId -ne 'Ignore')) {
        $code += "                     c = new ZeroTrustCheck(r, ts, bs) { Id = `"$checkId`", Name = `"$c`", License = `"$license`", ProductName = `"$productName`", ZeroTrustPrincipal = `"$ztPrincipal`", DocLinkText = `"$docLinkText`", DocLinkUrl = `"$docLinkUrl`" }; r.Checks.Add(c); zeroTrustData.Checks.Add(c);`r`n"
    }
    $row++
}
$code += "            return zeroTrustData;`r`n"
$code += "        }`r`n"
$code += "        #endregion`r`n";

$csCodePath = Join-Path $AssessmentSharedProjectFolder '\ZeroTrust\ZeroTrustDataService.cs'
$content = Get-Content $csCodePath -Raw
$generatedContent = $content -replace '\#region AutoGeneratedZeroTrustDataFromExcel[\s\S]*?\#endregion.*?', $code
Set-Content -Path $csCodePath -Value $generatedContent