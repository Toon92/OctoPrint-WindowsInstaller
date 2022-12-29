; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "OctoPrint"
#ifndef OctoPrintVersion
  #define OctoPrintVersion "unknown"
#endif
#define MyAppVersion OctoPrintVersion
#define MyAppPublisher "OctoPrint"
#define MyAppURL "https://www.octoprint.org/"
#define MyAppExeName "octoprint.exe" 
#define public Dependency_NoExampleSetup
#include "CodeDependencies.iss"  

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={code:GetAppID}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={code:GetDefaultDirName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=OctoPrint Setup {#MyAppVersion}
SetupIconFile=OctoPrint.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
DisableReadyPage=True
UninstallDisplayIcon={app}\OctoPrint.ico    
WizardImageFile=WizModernImage-OctoPrint*.bmp
WizardSmallImageFile=WizModernSmallImage-OctoPrint*.bmp
DisableWelcomePage=no
DisableDirPage=no
FlatComponentsList=False
AppendDefaultGroupName=False
UsePreviousLanguage=no

[Run]
Filename: "{app}\OctoPrintService{code:GetOctoPrintPort}.exe"; Parameters: "install"; WorkingDir: "{app}"; Flags: runhidden runascurrentuser; Description: "Install OctoPrint Service"; StatusMsg: "Installing Service for port {code:GetOctoPrintPort}"; Tasks: install_service
Filename: "{app}\OctoPrintService{code:GetOctoPrintPort}.exe"; Parameters: "start"; WorkingDir: "{app}"; Flags: runhidden runascurrentuser; Description: "Start OctoPrint Service"; StatusMsg: "Starting Service on port {code:GetOctoPrintPort}"; Tasks: install_service
Filename: "http://localhost:{code:GetOctoPrintPort}/"; Flags: runasoriginaluser shellexec postinstall; Description: "Open OctoPrint to complete initial setup."; Tasks: install_service
Filename: "{app}\yawcam_install.exe"; Parameters: "/verysilent /SP-"; WorkingDir: "{app}"; Flags: runhidden runascurrentuser; Description: "Complete YawCAM Install"; StatusMsg: "Complete YawCAM Install"; Components: initial_instance; Tasks: include_yawcam
Filename: "{commonpf32}\YawCam\Yawcam_Service.exe"; Parameters: "-install"; WorkingDir: "{commonpf32}\YawCam\"; Flags: runascurrentuser runhidden postinstall; Description: "Install YawCam Service"; StatusMsg: "Installing YawCam Service"; Components: initial_instance; Tasks: include_yawcam; BeforeInstall: update_service_yawcam
Filename: "{sys}\net.exe"; Parameters: "START ""Yawcam"""; WorkingDir: "{sys}"; Flags: runascurrentuser runhidden postinstall; Description: "Start YawCam Service"; StatusMsg: "Starting YawCam Service"; Components: initial_instance; Tasks: include_yawcam
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""OctoPrint {code:GetOctoPrintPort}"" dir=in protocol=TCP localport={code:GetOctoPrintPort} action=allow"; WorkingDir: "{sys}"; Flags: runascurrentuser runhidden; Description: "Add Firewall Exception"; StatusMsg: "Adding firewall exception rule"; Components: initial_instance add_instance; Tasks: add_firewall_exception

[UninstallRun]
Filename: "{app}\OctoPrintService{code:GetOctoPrintPort}.exe"; Parameters: "stop --no-elevate --no-wait --force"; WorkingDir: "{app}"; Flags: runhidden; RunOnceId: "StopService"; Tasks: install_service
Filename: "{app}\OctoPrintService{code:GetOctoPrintPort}.exe"; Parameters: "uninstall --no-elevate"; WorkingDir: "{app}"; Flags: runhidden; RunOnceId: "DelService"; Tasks: install_service
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""OctoPrint {code:GetOctoPrintPort}"""; RunOnceId: "FirewallException"; Tasks: add_firewall_exception

[UninstallDelete]
;Type: filesandordirs; Name: "{app}\*"

[Registry]
Root: "HKLM"; Subkey: "Software\{#MyAppName}\Instances"; ValueType: string; ValueName: "{code:GetOctoPrintPort}"; ValueData: "{code:GetServiceWrapperPath}"; Flags: uninsdeletekeyifempty uninsdeletevalue
Root: "HKLM"; Subkey: "Software\{#MyAppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"

[Components]
Name: "initial_instance"; Description: "Initial Install"; Flags: exclusive; Check: not InstalledOnce
Name: "add_instance"; Description: "Adding New Instance"; Flags: exclusive; Check: InstalledOnce

[ThirdParty]
UseRelativePaths=True

[Tasks]
Name: "install_service"; Description: "Install OctoPrint as a Service"
Name: "include_ffmpeg"; Description: "Include ffmpeg (for timelapse support)"
Name: "include_yawcam"; Description: "Include YawCam (for webcam support)"; Flags: unchecked; Check: not InstalledOnce
Name: "add_firewall_exception"; Description: "Add firewall rule policy exception"

[Code]
function InitializeSetup: Boolean; 
begin 
  Dependency_AddVC2013;
  Result := True;          
end;

var
  InputQueryWizardPage: TInputQueryWizardPage;
  DataDirPage: TInputDirWizardPage;
  ComponentSelectPage: TWizardPage;
  YawCamSelectIP: TInputOptionWizardPage;
  WrapperPath: String;
  OctoPrintPort: String;
  OctoPrintBasedir: String;     
  ip_address_list : TStringList; 



const
 ERROR_INSUFFICIENT_BUFFER = 122;

function GetIpAddrTable( pIpAddrTable: Array of Byte;
  var pdwSize: Cardinal; bOrder: WordBool ): DWORD;
external 'GetIpAddrTable@IpHlpApi.dll stdcall';

procedure GetIpAddresses(Addresses : TStringList);
var 
 Size : Cardinal;
 Buffer : Array of Byte;
 IpAddr : String;
 AddrCount : Integer;
 I, J : Integer;
begin
  { Find Size }
  if GetIpAddrTable(Buffer,Size,False) = ERROR_INSUFFICIENT_BUFFER then
  begin
     { Allocate Buffer with large enough size }
     SetLength(Buffer,Size);
     { Get List of IP Addresses into Buffer }
     if GetIpAddrTable(Buffer,Size,True) = 0 then
     begin
       { Find out how many addresses will be returned. }
       AddrCount := (Buffer[1] * 256) + Buffer[0];
       { Loop through addresses. }
       For I := 0 to AddrCount - 1 do
       begin
         IpAddr := '';
         { Loop through each byte of the address }
         For J := 0 to 3 do
         begin
           if J > 0 then
             IpAddr := IpAddr + '.';
           { Navigate through record structure to find correct byte of Addr }
           IpAddr := IpAddr + IntToStr(Buffer[I*24+J+4]);
         end;
         Addresses.Add(IpAddr);
       end;
     end;
  end;
end;

function GetServiceWrapperPath(Param: string): String;
begin
  Result := WrapperPath;
end;

function GetOctoPrintPort(Param: string): String;
begin
  Result := OctoPrintPort;
end; 

function GetOctoPrintBasedir(Param: string): String;
begin
  Result := OctoPrintBasedir;
end;

function GetOctoPrintInstances(): TArrayOfString;
var
  Names: TArrayOfString;
  I: Integer;
  S: String;
begin
  if RegGetValueNames(HKLM, 'Software\OctoPrint\Instances', Names) then
  begin
    // any additional processing?
  end else
  begin
    // add any code to handle failure here
  end;
  Result := Names
end;

function GetOctoPrintInstancesAsString(OctoPrintInstances: TArrayOfString): string;
var
  I: integer;
  S: string;
begin
  S := '';
  for I := 0 to GetArrayLength(OctoPrintInstances)-1 do
    S := S + OctoPrintInstances[I] + #13#10;
  Result := S;
end;

function InstanceExists(OctoPrintInstances: TArrayOfString; sInstance: string): boolean;
var
  I: integer;
  bResult: boolean;
begin
  bResult := False;
  for I := 0 to GetArrayLength(OctoPrintInstances)-1 do
    if OctoPrintInstances[I] = sInstance then
      bResult := True;
  Result := bResult;
end;

function InstalledOnce: Boolean;
begin
  Result := RegKeyExists(HKLM, 'Software\OctoPrint\Instances');
end;

function CheckPortOccupied(Port:String):Boolean;
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{cmd}'), '/C netstat -na | findstr'+' /C:":'+Port+' "', '', 0,
       ewWaitUntilTerminated, ResultCode);
  if ResultCode <> 1 then 
  begin
    Result := True; 
  end
    else
  begin
    Result := False;
  end;
end;

procedure InitializeWizard;
var
  sInputQueryMessage: string; 
  ip_address: string;
  counter: integer;
begin
// Custom Component Select Page
  if InstalledOnce then 
  begin
    sInputQueryMessage := 'You are installing a new instance of OctoPrint. Enter a port number that has not been previouslly used, and then click Next.' + #13#10#13#10'Currently Used Ports:'#13#10 + GetOctoPrintInstancesAsString(GetOctoPrintInstances);
  end else 
  begin      
    sInputQueryMessage := 'You are installing OctoPrint for the first time, click Next.';
  end;

// OctoPrint Port Dialog Page     
  InputQueryWizardPage := CreateInputQueryPage(wpWelcome, 'OctoPrint Setup', 'Which port to use for this instance?', sInputQueryMessage);
  InputQueryWizardPage.Add('Port:', False);
  InputQueryWizardPage.Values[0] := GetPreviousData('OctoPrintPort', '5000');
  
// OctoPrint Basedir Selection Page  
  DataDirPage := CreateInputDirPage(wpSelectDir,
    'OctoPrint Setup', 'Where should OctoPrint data files be installed?',
    'Select the folder in which OctoPrint will store uploads, configs, and other data files, then click Next.',
    False, '');
  DataDirPage.Add('Basedir Path:');
  DataDirPage.Values[0] := GetPreviousData('DataDir', WizardDirValue() + '\basedir');

// YawCam Select IP Page

  YawCamSelectIP := CreateInputOptionPage(wpSelectTasks,
  'YawCam IP Selection', 'What IP should YawCam be configured for?',
  'Select the IP address that YawCam will use and automatically be added to OctoPrint''s config.yaml.',
  True, False);

  ip_address_list := TStringList.Create;
  GetIpAddresses(ip_address_list);
  for counter := 0 to ip_address_list.Count - 1 do
  begin
    ip_address := ip_address_list[counter];
    if not VarIsNull(ip_address) then
    begin
      YawCamSelectIP.Add(ip_address);
    end;
  end;    

// Initialize contstants
  OctoPrintPort := InputQueryWizardPage.Values[0];  
  WrapperPath := WizardDirValue() + '\OctoPrintService' + OctoPrintPort + '.exe';
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;

  if PageID = wpSelectComponents then
  begin
    Result := True;
  end;

  if (PageID = wpSelectDir) and InstalledOnce then
  begin
    Result := True;
  end;  
  
  if (PageID = YawCamSelectIP.ID) and not WizardIsTaskSelected('include_yawcam') then
  begin
    Result := True;
  end;
end;


function NextButtonClick(CurPageID: Integer): Boolean;
var
  bResult: boolean;
begin
  bResult := True;   
  if CurPageID = InputQueryWizardPage.ID then 
  begin
    if (InputQueryWizardPage.Values[0] = '') or InstanceExists(GetOctoPrintInstances, InputQueryWizardPage.Values[0]) or CheckPortOccupied(InputQueryWizardPage.Values[0]) then
    begin
      bResult := False;
      MsgBox('Port ' + InputQueryWizardPage.Values[0] + ' is already in use.', mbCriticalError, MB_OK);
    end;
    OctoPrintPort := InputQueryWizardPage.Values[0];
    WrapperPath := WizardDirValue() + '\OctoPrintService' + OctoPrintPort + '.exe';
  end;
  if (CurPageID = wpSelectDir) or ((CurPageID = InputQueryWizardPage.ID) and InstalledOnce) then 
  begin
    DataDirPage.Values[0] := WizardDirValue() + '\basedir\' + OctoPrintPort;
    WrapperPath := WizardDirValue() + '\OctoPrintService' + OctoPrintPort + '.exe';
    OctoPrintBasedir := DataDirPage.Values[0];
  end;
  if CurPageID = DataDirPage.ID then
  begin
    OctoPrintBasedir := DataDirPage.Values[0];
  end;
  Result := bResult;
end;

procedure rename_config();
var
  UnicodeStr: string;
  ANSIStr: AnsiString;
begin
  if LoadStringFromFile(ExpandConstant(CurrentFilename), ANSIStr) then
  begin
    UnicodeStr := String(ANSIStr);
    if StringChangeEx(UnicodeStr, '####APPDIR####', WrapperPath, True) > 0 then
      if DirExists(ExpandConstant(OctoPrintBasedir)) = False then
        ForceDirectories(ExpandConstant(OctoPrintBasedir));
      StringChangeEx(UnicodeStr, '####PIPPATH####', ExpandConstant('{app}\WPy64-31050\python-3.10.5.amd64\Scripts\pip.exe'), True);
      SaveStringToFile(ExpandConstant(OctoPrintBasedir + '\config.yaml'), AnsiString(UnicodeStr), False);
  end;
end; 

procedure update_config_ffmpeg();
var
  ANSIStr: AnsiString;
begin
  if LoadStringFromFile(OctoPrintBasedir + '\config.yaml', ANSIStr) then
  begin 
    ANSIStr := ANSIStr + #13#10 + 'webcam:' + #13#10 + '  ffmpeg: ' + ExpandConstant(CurrentFilename);
    SaveStringToFile(ExpandConstant(OctoPrintBasedir + '\config.yaml'), ANSIStr, False);
  end;
end;

procedure update_config_yawcam();
var
  ANSIStr: AnsiString;  
begin
  if LoadStringFromFile(OctoPrintBasedir + '\config.yaml', ANSIStr) then
  begin
    if Pos('webcam', ANSIStr) = 0 then
    begin
      ANSIStr := ANSIStr + #13#10 + 'webcam:';
    end;
    ANSIStr := ANSIStr + #13#10 + '  snapshot: http://' + ip_address_list[YawCamSelectIP.SelectedValueIndex] + ':8888/out.jpg';  
    ANSIStr := ANSIStr + #13#10 + '  stream: http://' + ip_address_list[YawCamSelectIP.SelectedValueIndex] + ':8081/video.mjpg';
    SaveStringToFile(ExpandConstant(OctoPrintBasedir + '\config.yaml'), ANSIStr, False);
  end;
end;  

procedure update_service_yawcam();
var
  ANSIStr: AnsiString;  
begin
  if LoadStringFromFile(ExpandConstant('{commonpf32}\YawCam\service_profile.cfg'), ANSIStr) then
  begin 
    ANSIStr := ExpandConstant('{app}');
    SaveStringToFile(ExpandConstant('{commonpf32}\YawCam\service_profile.cfg'), ANSIStr, False);
  end;
end;

procedure rename_service_wrapper();
var
  FolderPath: string;
begin
  FolderPath := ExpandConstant('{app}\Service Control\' + OctoPrintPort);
  FileCopy(ExpandConstant(CurrentFilename), WrapperPath, False); 
  ForceDirectories(FolderPath);
  CreateShellLink(FolderPath + '\Install OctoPrint Service.lnk', 'Install the OctoPrint service on port ' + OctoPrintPort, ExpandConstant(WrapperPath), 'install', ExpandConstant('{app}'), ExpandConstant('{app}\OctoPrint.ico'), 0, SW_SHOWNORMAL);  
  CreateShellLink(FolderPath + '\Restart OctoPrint Service.lnk', 'Restart the OctoPrint service on port ' + OctoPrintPort, ExpandConstant(WrapperPath), 'restart!', ExpandConstant('{app}'), ExpandConstant('{app}\OctoPrint.ico'), 0, SW_SHOWNORMAL);       
  CreateShellLink(FolderPath + '\Start OctoPrint Service.lnk', 'Start the OctoPrint service on port ' + OctoPrintPort, ExpandConstant(WrapperPath), 'start', ExpandConstant('{app}'), ExpandConstant('{app}\OctoPrint.ico'), 0, SW_SHOWNORMAL);      
  CreateShellLink(FolderPath + '\Stop OctoPrint Service.lnk', 'Stop the OctoPrint service on port ' + OctoPrintPort, ExpandConstant(WrapperPath), 'stop', ExpandConstant('{app}'), ExpandConstant('{app}\OctoPrint.ico'), 0, SW_SHOWNORMAL);       
  CreateShellLink(FolderPath + '\Uninstall OctoPrint Service.lnk', 'Uninstall the OctoPrint service on port ' + OctoPrintPort, ExpandConstant(WrapperPath), 'uninstall', ExpandConstant('{app}'), ExpandConstant('{app}\OctoPrint.ico'), 0, SW_SHOWNORMAL);
end;

procedure update_service_config(); 
var
  UnicodeStr: string;
  ANSIStr: AnsiString;
begin
  if LoadStringFromFile(ExpandConstant('{app}\OctoPrintService.xml'), ANSIStr) then
  begin
    UnicodeStr := String(ANSIStr);
    StringChangeEx(UnicodeStr, '####EXEPATH####', ExpandConstant('{app}\WPy64-31050\Scripts\python.bat'), True) 
    StringChangeEx(UnicodeStr, '####BASEDIR####', DataDirPage.Values[0], True) 
    StringChangeEx(UnicodeStr, '####PORT####', InputQueryWizardPage.Values[0], True)
    SaveStringToFile(ExpandConstant('{app}\OctoPrintService' + OctoPrintPort + '.xml'), AnsiString(UnicodeStr), False);
  end;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  { Store the settings so we can restore them next time }
  SetPreviousData(PreviousDataKey, 'DataDir', DataDirPage.Values[0]);  
  SetPreviousData(PreviousDataKey, 'OctoPrintPort', InputQueryWizardPage.Values[0]); 
end;

function StartServiceChecked(): boolean;
var
  bResult: boolean;
begin
  bResult := WizardForm.RunList.ItemEnabled[0];  
  Result := bResult;
end;

function GetAppID(const Value: string): string;
var
  AppID: string;
begin
  AppID := '{BBCED751-C716-423E-BEB9-57F817B1E3EA}';
  if Assigned(InputQueryWizardPage) then
    Result := AppID + OctoPrintPort
  else
    Result := AppID;
end;

function GetDefaultDirName(const Value: string): string;
var
  DirName: String;
begin
  DirName:= 'C:\{#MyAppName}';
  if RegQueryStringValue(HKEY_LOCAL_MACHINE, 'Software\{#MyAppName}\',
     'InstallPath', DirName) then
  begin
    // Successfully read the value
  end;
  Result := DirName;
end;

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "WPy64-31050\*"; DestDir: "{app}\WPy64-31050"; Flags: recursesubdirs createallsubdirs ignoreversion onlyifdoesntexist; Components: initial_instance
Source: "OctoPrint.ico"; DestDir: "{app}"; Components: initial_instance
Source: "OctoPrintService.exe"; DestDir: "{app}"; Components: initial_instance add_instance; AfterInstall: rename_service_wrapper
Source: "OctoPrintService.xml"; DestDir: "{app}"; Flags: ignoreversion; Components: initial_instance add_instance; AfterInstall: update_service_config
Source: "config.yaml"; DestDir: "{app}"; Flags: ignoreversion; Components: initial_instance add_instance; AfterInstall: rename_config
Source: "ffmpeg.exe"; DestDir: "{app}"; Flags: ignoreversion uninsneveruninstall; Tasks: include_ffmpeg; AfterInstall: update_config_ffmpeg
Source: "yawcam_install.exe"; DestDir: "{app}"; Components: initial_instance; Tasks: include_yawcam; AfterInstall: update_config_yawcam
Source: "yawcam_settings.xml"; DestDir: "{app}\.yawcam"; Components: initial_instance; Tasks: include_yawcam

[Icons]
Name: "{group}\{cm:ProgramOnTheWeb,OctoPrint Website}"; Filename: "{#MyAppURL}"
Name: "{group}\OctoPrint on Port {code:GetOctoPrintPort}"; Filename: "http://localhost:{code:GetOctoPrintPort}/"; IconFilename: "{app}\OctoPrint.ico"; IconIndex: 0
Name: "{group}\OctoPrint Service Control"; Filename: "{app}\Service Control"; WorkingDir: "{app}\Service Control"; Tasks: install_service
Name: "{group}\Uninstall OctoPrint on Port {code:GetOctoPrintPort}"; Filename: "{uninstallexe}"; WorkingDir: "{app}"; IconFilename: "{app}\OctoPrint.ico"; IconIndex: 0
