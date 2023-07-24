$dirname=(Get-Item -Path '.\' -Verbose).FullName
$env:LUA_PATH = "$env:LUA_PATH;$dirname\lactoseIntolerant\media\lua\client\?.lua;$dirname\lactoseIntolerant\media\lua\shared\?.lua;$dirname\lactoseIntolerant\media\lua\server\?.lua;$dirname\?.lua"
$env:LUA_PATH = "$env:LUA_PATH;C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\media\lua\client"
$env:LUA_PATH = "$env:LUA_PATH;C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\media\lua\shared"
$env:LUA_PATH = "$env:LUA_PATH;C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\media\lua\re
shared"
