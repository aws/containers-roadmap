# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

[CmdLetBinding()]
param
(
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string] $DeploymentTemplateFilePath,

    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputFilePath
)

Write-Verbose 'Getting CA bundle'
$CaBundle = (kubectl config view --raw -o json --minify | ConvertFrom-Json).clusters[0].cluster."certificate-authority-data"

Write-Verbose 'Updating deployment YAML'
Get-Content -Path $DeploymentTemplateFilePath | `
%{ $_ -replace '\${CA_BUNDLE}', $CaBundle } | `
Out-File -FilePath $OutputFilePath