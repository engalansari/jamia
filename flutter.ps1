param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $Args
)

& "$PSScriptRoot\tools\flutter\bin\flutter.bat" @Args
exit $LASTEXITCODE
