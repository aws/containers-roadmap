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
    [ValidateNotNullOrEmpty()]
    [string] $ServiceName = 'vpc-admission-webhook-svc',

    [ValidateNotNullOrEmpty()]
    [string] $SecretName = 'vpc-admission-webhook-certs',

    [ValidateNotNullOrEmpty()]
    [string] $Namespace = 'default'
)

if (!(Get-Command -Name openssl -ErrorAction SilentlyContinue))
{
    throw 'OpenSSL not found'
}

$TempDirectoryPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
New-Item -Type Directory -Path $TempDirectoryPath | Out-Null
Write-Verbose "Creating certificates in path: $TempDirectoryPath"

$CsrConfFilePath = Join-Path -Path $TempDirectoryPath -ChildPath 'csr.conf'
$CsrName = "$ServiceName`.$Namespace"
$ServiceAddress = "$CsrName`.svc"
@"
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $ServiceName
DNS.2 = $CsrName
DNS.3 = $ServiceAddress
"@ | `
Out-File -FilePath $CsrConfFilePath -Encoding ASCII

$ServerCertificateKeyFilePath = Join-Path -Path $TempDirectoryPath -ChildPath 'server-key.pem'
$CsrFilePath = Join-Path -Path $TempDirectoryPath -ChildPath 'server.csr'
openssl genrsa -out $ServerCertificateKeyFilePath 2048
openssl req -new -key $ServerCertificateKeyFilePath -subj "/CN=$ServiceAddress" -out $CsrFilePath -config $CsrConfFilePath

Write-Verbose 'Cleaning up any previously created CSR'
kubectl delete csr $CsrName 2> $Null

Write-Verbose 'Creating server CSR'
@"
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: $CsrName
spec:
  groups:
  - system:authenticated
  request: $([Convert]::ToBase64String([IO.File]::ReadAllBytes($CsrFilePath)))
  usages:
  - digital signature
  - key encipherment
  - server auth
"@ | `
kubectl create -f -

Write-Verbose 'Verifying CSR has been created'
do
{
    kubectl get csr $CsrName
    $Succeeded = $LASTEXITCODE -eq 0
    if (!$Succeeded)
    {
        Start-Sleep -Seconds 1
    }
}
while (!$Succeeded)

Write-Verbose 'Approving server CSR'
kubectl certificate approve $CsrName

Write-Verbose 'Getting signed certificate'
do
{
    $ServerCertificate = kubectl get csr $CsrName -o jsonpath='{.status.certificate}'
    $Succeeded = $LASTEXITCODE -eq 0
    if (!$Succeeded)
    {
        if (++$Attempts -ge 10)
        {
            throw 'Unable to get certificate after 10 attempts'
        }

        Start-Sleep -Seconds 1
    }
}
while (!$Succeeded)

Write-Verbose 'Writing signed certificate'
$ServerCertificateFilePath = Join-Path -Path $TempDirectoryPath -ChildPath 'server-cert.pem'
$ServerCertificate | openssl base64 -d -A -out $ServerCertificateFilePath

Write-Verbose 'Creating secret with CA certificate and server certificate'
kubectl create secret generic $SecretName `
    --from-file=key.pem=$ServerCertificateKeyFilePath `
    --from-file=cert.pem=$ServerCertificateFilePath `
    --dry-run -o yaml | `
    kubectl -n $Namespace apply -f -