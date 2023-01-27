    # This function is used to build the actual dynamically generated cmdlets
    function BuildCmdlet {
        [CmdletBinding()]
        param(
            [string] $CommandName,
            [scriptblock] $Definition,
            [ValidateSet('global','script','local')]
            [string] $Scope = 'global',
            [string] $querystring,
            [hashtable] $queryArguments,
            [object] $ReferenceOverride
        )

        begin {
            # Another DSL keyword; this time for creating parameters
            function parameter {
                param(
                    [type] $ParameterType = [object],
                    [Parameter(Mandatory)]
                    [string] $ParameterName,
                    [string[]] $ValidateSet,
                    [string] $HelpMessage,
                    [System.Collections.ObjectModel.Collection[System.Attribute]] $Attributes = (New-Object parameter )
                )

                process {

                    # $CommandName coming from parent scope:
                    $MyCommandInfo = $__CommandInfo[$CommandName]

                    if ($MyCommandInfo -eq $null -or -not $MyCommandInfo.ContainsKey('Parameters')) {
                        Write-Error "Unable to find command definition for '$CommandName'"
                        return
                    }
                    if ($HelpMessage) { $Attributes[0].HelpMessage = $HelpMessage}
                    if ($ValidateSet) {
                        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
                        $Attributes.Add($ValidateSetAttribute)
                    }
                    
                    # Create a runtime defined parameter that the reference script block will use in the DynamicParam{} block
                    $MyCommandInfo['Parameters'][$ParameterName] = New-Object System.Management.Automation.RuntimeDefinedParameter (
                        $ParameterName,
                        $ParameterType,
                        $Attributes
                    )
                }
            }
        }
        process {
            $__CommandInfo[$CommandName] = @{
                Parameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
                QueryString = "$querystring"
                Arguments = "$queryArguments"
            }
            & $Definition
            if ($ReferenceOverride) {
                $null = New-Item -Path function: -Name ${Scope}:${CommandName} -Value $ReferenceOverride -Force
            } else {
                $null = New-Item -Path function: -Name ${Scope}:${CommandName} -Value $ReferenceCommand  -Force
            }
            
            
            Export-ModuleMember -Function $CommandName
        }
    }