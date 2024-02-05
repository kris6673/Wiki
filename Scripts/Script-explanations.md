# Explanation for scripts in this folder

## Table of contents <!-- omit in toc -->

1. [Install-RequiredModules.ps1](#install-requiredmodulesps1)
2. [Download-GithubRelease.ps1](#download-githubreleaseps1)

## Install-RequiredModules.ps1

Script found [here](/Scripts/Install-RequiredModules.ps1)  
This PowerShell script is designed to automate the process of installing and updating a list of specified PowerShell modules. The script will check if the module is installed, and if it is, it will check if it is up to date. If it is not installed, or if it is not up to date, it will install/update the module.  
It's designed to be copied into the top of the script you want to use the modules in.

Script requires to be run in a PowerShell 5.1+ environment. Make sure to run it with administrative privileges to avoid permission issues.

## [Download-GithubRelease.ps1](/Scripts/Download-GithubRelease.ps1)

Downloads the latest release of the specified software from GitHub.  
Rustdesk is used as an example in the script.
