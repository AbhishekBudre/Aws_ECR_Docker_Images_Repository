######################################
# Excute this command first
#####################################

#  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# then 
# .\Deploy.ps1 apply
# .\Deploy.ps1 destroy


param (
[Parameter(Mandatory = $true)]
[ValidateSet("init", "plan", "apply", "destroy")]
[string]$Action
)

$TerraformPath = "C:\Three-Tier-Application\Docker-ec2"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Terraform Deployment Automation" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

Set-Location $TerraformPath

switch ($Action) {

"init" {
    Write-Host "Initializing Terraform..." -ForegroundColor Yellow

    terraform init

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform Init Failed!" -ForegroundColor Red
        exit 1
    }
}

"plan" {
    Write-Host "Running Terraform Plan..." -ForegroundColor Yellow

    terraform init

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform Init Failed!" -ForegroundColor Red
        exit 1
    }

    terraform plan

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform Plan Failed!" -ForegroundColor Red
        exit 1
    }
}

"apply" {
    Write-Host "Running Terraform Apply..." -ForegroundColor Yellow

    terraform init

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform Init Failed!" -ForegroundColor Red
        exit 1
    }

    terraform plan

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform Plan Failed!" -ForegroundColor Red
        exit 1
    }

    Write-Host "Applying Terraform Configuration..." -ForegroundColor Yellow

    terraform apply -auto-approve

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform Apply Failed!" -ForegroundColor Red
        exit 1
    }
}

"destroy" {
    Write-Host "Destroying Terraform Resources..." -ForegroundColor Red

    terraform destroy -auto-approve

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform Destroy Failed!" -ForegroundColor Red
        exit 1
    }
}

}

Write-Host "======================================" -ForegroundColor Green
Write-Host " Terraform $Action Completed!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green