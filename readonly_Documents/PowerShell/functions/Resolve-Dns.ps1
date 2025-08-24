Import-Module DnsClient
function Resolve-Dns {

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(0, 255)]
    [Microsoft.DnsClient.Commands.RecordType]
    ${Type},

    [ValidateCount(0, 5)]
    [string[]]
    ${Server},

    [switch]
    ${DnsOnly},

    [switch]
    ${CacheOnly},

    [switch]
    ${DnssecOk},

    [switch]
    ${DnssecCd},

    [switch]
    ${NoHostsFile},

    [switch]
    ${LlmnrNetbiosOnly},

    [switch]
    ${LlmnrFallback},

    [switch]
    ${LlmnrOnly},

    [switch]
    ${NetbiosFallback},

    [switch]
    ${NoIdn},

    [switch]
    ${NoRecursion},

    [switch]
    ${QuickTimeout},

    [switch]
    ${TcpOnly},

    [switch]
    ${AuthoritySection},
    
    [switch]
    ${AdditionalSection})

begin
{
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('DnsClient\Resolve-DnsName', [System.Management.Automation.CommandTypes]::Cmdlet)
        $sections = @()
        $sections += "Answer"

        if ($AuthoritySection) {
            [void]$PSBoundParameters.Remove("AuthoritySection")
            $sections += "Authority"
        }
        if ($AdditionalSection) {
            [void]$PSBoundParameters.Remove("AdditionalSection")
            $sections += "Additional"
        }

        $scriptCmd = {& $wrappedCmd @PSBoundParameters | Where-Object -Property Section -In $sections}

        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName DnsClient\Resolve-DnsName
.ForwardHelpCategory Cmdlet

#>

}