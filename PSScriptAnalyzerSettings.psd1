@{
    # Severity levels that matter for CI.
    Severity     = @('Error', 'Warning')

    # These scripts are interactive CLI helpers targeting pwsh 7, so a few default
    # rules don't apply.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',                       # Write-Host is intentional UX here
        'PSReviewUnusedParameter',                     # .env params are resolved dynamically
        'PSUseShouldProcessForStateChangingFunctions', # thin wrappers around az, not cmdlets
        'PSAvoidUsingPositionalParameters',
        'PSUseBOMForUnicodeEncodedFile'                # UTF-8 without BOM is correct for pwsh 7
    )
}
