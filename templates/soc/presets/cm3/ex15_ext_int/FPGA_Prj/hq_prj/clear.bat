@echo off
setlocal enabledelayedexpansion
cd hq_run
rd /s /q "hq_temp"
del *.log

for /R %%F in (*) do (
    set "file=%%F"
    set "ext=%%~xF"
    :: 检查文件扩展名不是 .bin
    if /i not "!ext!"==".bin" (
        echo 删除: "%%F"
        del /f /q "%%F"
    )
)


