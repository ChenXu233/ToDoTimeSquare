[Setup]
AppName=ToDoTimeSquare
AppVersion=0.1.0alpha
DefaultDirName={pf}\ToDoTimeSquare
DefaultGroupName=ToDoTimeSquare
OutputDir=build\windows\installer
OutputBaseFilename=ToDoTimeSquareInstaller
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\ToDoTimeSquare"; Filename: "{app}\ToDoTimeSquare.exe"
Name: "{group}\Uninstall ToDoTimeSquare"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\todo_time_square.exe"; Description: "Launch ToDoTimeSquare"; Flags: nowait postinstall skipifsilent
