@echo off
set patchfile=
cls

GOTO ARKANOID

:ARKANOID
set   zip1=arkanoid.zip
set ifiles=ic81-v.3f+ic82-w.5f+a75-03.ic64+a75-04.ic63+a75-05.ic62+a75-07.ic24+a75-08.ic23+a75-09.ic22
set patchfile=a.arkanoid.ips
set md5valid=06d5c6b489dc0739902b9ed96f100399
if NOT EXIST flips.exe GOTO ERRORIPS
if NOT EXIST %patchfile% GOTO ERRORPF
GOTO START

:START
set  ofile=a.arkanoid.rom
set   zip2=arkatayt.zip


rem =====================================
setlocal ENABLEDELAYEDEXPANSION

set pwd=%~dp0
echo.
echo.

if NOT EXIST %zip1% GOTO ERRORZIP1
if NOT EXIST %zip2% GOTO ERRORZIP2
if NOT EXIST !pwd!7za.exe GOTO ERROR7Z

!pwd!7za x -y -otmp %zip1%
!pwd!7za x -y -otmp %zip2%
	if !ERRORLEVEL! EQU 0 ( 
		cd tmp
		copy /b/y %ifiles% !pwd!%ofile%
			if !ERRORLEVEL! EQU 0 ( 
				cd !pwd!
					if "%patchfile%" NEQ "" (
						flips.exe %patchfile% %ofile%
					)
				
				set "md5="
				echo certutil -hashfile "!pwd!%ofile%" MD5
					for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "!pwd!%ofile%" MD5') do (
						if not defined md5 (
							for %%Z in (%%#) do  (
								set "md5=%%Z"
							)
						
						)
					)	
			
				if "%md5valid%" EQU "!md5!" (
					echo.
					echo ** done **
					echo.
					echo Copy "%ofile%" into root, /bootrom folder or the folder of the core in SD card
				) else (
					echo.
					echo ** PROBLEM IN ROM **
					echo.
					echo MD5 MISMATCH! CHECK YOUR ZIP FILE
					echo.
					echo MD5 is "!md5!" but should be "%md5valid%"
				)
			)
		cd !pwd!
		rmdir /s /q tmp	
		GOTO END		
	)
		
:ERRORZIP1
	echo.
	echo Error: Cannot find "%zip1%". Put it in the same directory as "%~nx0"!
	GOTO END
:ERRORZIP2
	echo.
	echo Error: Cannot find "%zip2%". Put it in the same directory as "%~nx0"!
	GOTO END
:ERROR7Z
	echo.
	echo Error: Cannot find "7za.exe". Put it in the same directory as "%~nx0"!
	GOTO END
:ERRORIPS
	echo.
	echo Error: Cannot find "ips.exe". Put it in the same directory as "%~nx0"!
	GOTO END
:ERRORPF
	echo.
	echo Error: Cannot find "%patchfile%". Put it in the same directory as "%~nx0"!
	GOTO END
	
	
:END
echo.
echo.
pause
