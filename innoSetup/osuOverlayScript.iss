; Script generated by the Inno Script Studio Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!
#include ReadReg(HKLM, 'Software\WOW6432Node\Mitrich Software\Inno Download Plugin', 'InstallDir') + '\idp.iss'

#define MyAppName "StreamCompanion - text ingame overlay plugin"
#define MyAppPublisher "Piotrekol"
#define MyAppURL "https://osustats.ppy.sh/"
#define AppId "{F6C83F00-59ED-493E-8310-181BB5B37A03}"

#define FilesRoot "..\build\Release_unsafe\"
#define ApplicationVersion GetFileVersion(FilesRoot +'Plugins\TextIngameOverlay.dll')
[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{#AppId}
AppName={#MyAppName}
AppVersion={#ApplicationVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=license.txt
OutputBaseFilename=StreamCompanion-textOverlay
SetupIconFile=..\osu!StreamCompanion\Resources\compiled.ico
Compression=lzma
SolidCompression=yes
AppMutex=Global\{{2c6fc9bd-4e26-42d3-acfa-0a4d846d7e9e}

UsePreviousAppDir=yes
CreateUninstallRegKey=no
UpdateUninstallLogAppName=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: {#FilesRoot}*; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[InstallDelete]
Type: files; Name: "{app}\Plugins\osuOverlayPlugin.dll"
[CustomMessages]
IDP_DownloadFailed=Download of VCRedist failed. VCRedist is required to run StreamCompanion text overlay.
IDP_RetryCancel=Click 'Retry' to try downloading the files again, or click 'Cancel' to terminate setup.
InstallingVCRedist=Installing VCRedist. This might take a few minutes...
VCRedistFailedToLaunch=Failed to launch VCRedist Installer with error "%1". Please fix the error then run this installer again.
VCRedistFailedOther=The VCRedist installer exited with an unexpected status code "%1". Please review any other messages shown by the installer to determine whether the installation completed successfully, and abort this installation and fix the problem if it did not.

[Code]

function InitializeSetup(): Boolean;
begin
  Result := True;
  if not (
          RegKeyExists(HKEY_LOCAL_MACHINE,
           'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1') or
          RegKeyExists(HKEY_CURRENT_USER,
           'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1') or
          RegKeyExists(HKEY_CURRENT_USER,
           'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1') 
          ) then
  begin
    MsgBox('StreamCompanion was not found - Aborting!', mbError, MB_OK);
    Result := False;
  end;
end;


function VCRedistIsMissing: Boolean;
var 
  Version: String;
begin
  if RegQueryStringValue(HKEY_LOCAL_MACHINE,
       'SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\X86', 'Version', Version) then
  begin
    // Is the installed version at least 14.32 ?
    Log('VC Redist Version check : found ' + Version);
    Result := (CompareStr(Version, 'v14.32.31326.00')<0);
  end
  else 
  begin
    // VCRedist not found
    Result := True;
  end;
end;

procedure InitializeWizard;
begin
  if VCRedistIsMissing() then
  begin
    idpAddFile('https://aka.ms/vs/17/release/vc_redist.x86.exe', ExpandConstant('{tmp}\vc_redist.x86.exe'));
    idpDownloadAfter(wpReady);
  end;
end;

function InstallVCRedist(): String;
var
  StatusText: string;
  ResultCode: Integer;
begin
  StatusText := WizardForm.StatusLabel.Caption;
  WizardForm.StatusLabel.Caption := CustomMessage('InstallingVCRedist');
  WizardForm.ProgressGauge.Style := npbstMarquee;
  try
    if not Exec(ExpandConstant('{tmp}\vc_redist.x86.exe'), '/passive /norestart /showrmui /showfinalerror', '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
    begin
      Result := FmtMessage(CustomMessage('VCRedistFailedToLaunch'), [SysErrorMessage(resultCode)]);
    end
    else
    begin
      case resultCode of
        0: begin
          // Successful
        end;
        else begin
          MsgBox(FmtMessage(CustomMessage('VCRedistFailedOther'), [IntToStr(resultCode)]), mbError, MB_OK);
        end;
      end;
    end;
  finally
    WizardForm.StatusLabel.Caption := StatusText;
    WizardForm.ProgressGauge.Style := npbstNormal;
    
    DeleteFile(ExpandConstant('{tmp}\vc_redist.x86.exe'));
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  if VCRedistIsMissing() then
  begin
    Result := InstallVCRedist();
  end;
end;
