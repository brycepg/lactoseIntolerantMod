$dirname=(Get-Item -Path '.\' -Verbose).FullName
$env:LUA_PATH = "$dirname\lactoseIntolerant\media\lua\client\?.lua;$dirname\lactoseIntolerant\media\lua\shared\?.lua;$dirname\lactoseIntolerant\media\lua\server\?.lua;$dirname\?.lua"
