[Setup]
AppName=ToDoTimeSquare
AppVersion=$version
DefaultDirName={pf}\ToDoTimeSquare
DefaultGroupName=ToDoTimeSquare
OutputDir=build\windows\installer
OutputBaseFilename=ToDoTimeSquareInstaller
Compression=lzma
SolidCompression=yes
SetupIconFile=windows\runner\resources\app_icon.ico

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\ToDoTimeSquare"; Filename: "{app}\ToDoTimeSquare.exe"
Name: "{group}\Uninstall ToDoTimeSquare"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\todo_time_square.exe"; Description: "Launch ToDoTimeSquare"; Flags: nowait postinstall skipifsilent