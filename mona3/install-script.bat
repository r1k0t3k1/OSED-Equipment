reg import ..\windbg\windbg-classic.reg

.\python-3.9.13\python-3.9.13-x86.exe /quiet PrependPath=1 Include_pip=1
.\python-3.9.13\python-3.9.13-x64.exe /quiet PrependPath=1 Include_pip=1

.\VisualC++\vc_redist.x86.exe /quiet /norestart
.\VisualC++\vc_redist.x64.exe /quiet /norestart

py -3.9-32 -m pip install --no-index --find-links=.\python-module pykd keystone-engine
py -3.9-64 -m pip install --no-index --find-links=.\python-module pykd keystone-engine

mkdir C:\Tools\mona3
copy mona.py C:\Tools\mona3\
copy windbglib.py C:\Tools\mona3\

mkdir "%LOCALAPPDATA%\DBG\EngineExtensions32\"
mkdir "%LOCALAPPDATA%\DBG\EngineExtensions\"

copy pykd-ext\x86\pykd.dll "%LOCALAPPDATA%\DBG\EngineExtensions32\"
copy pykd-ext\x64\pykd.dll "%LOCALAPPDATA%\DBG\EngineExtensions\"

copy ..\windbg\narly.dll "%LOCALAPPDATA%\DBG\EngineExtensions32\"
