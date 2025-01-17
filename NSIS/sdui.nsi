; Script generated by the HM NIS Edit Script Wizard.

Target amd64-unicode
Unicode True
SetCompressor /FINAL lzma
RequestExecutionLevel user
!AddPluginDir /amd64-unicode "."
; HM NIS Edit Wizard helper defines
!define PRODUCT_NAME "Easy Diffusion"
!define PRODUCT_VERSION "2.5"
!define PRODUCT_PUBLISHER "cmdr2 and contributors"
!define PRODUCT_WEB_SITE "https://stable-diffusion-ui.github.io"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Easy Diffusion\App Paths\installer.exe"

; MUI 1.67 compatible ------
!include "MUI.nsh"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"

!include "nsisconf.nsh"

Var Dialog
Var Label
Var Button

Var InstDirLen
Var LongPathsEnabled
Var AccountType

;---------------------------------------------------------------------------------------------------------
; This function returns the number of spaces in a string.
; The string is passed on the stack (using Push $STRING)
; The result is also returned on the stack and can be consumed with Pop $var
; https://nsis.sourceforge.io/Check_for_spaces_in_a_directory_path
Function CheckForSpaces
  Exch $R0
  Push $R1
  Push $R2
  Push $R3
  StrCpy $R1 -1
  StrCpy $R3 $R0
  StrCpy $R0 0
  loop:
    StrCpy $R2 $R3 1 $R1
    IntOp $R1 $R1 - 1
    StrCmp $R2 "" done
    StrCmp $R2 " " 0 loop
    IntOp $R0 $R0 + 1
  Goto loop
  done:
  Pop $R3
  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd

;---------------------------------------------------------------------------------------------------------
; The function DirectoryLeave is called after the user chose the installation directory.
; If it calls "abort", the user is sent back to choose a different directory.
Function DirectoryLeave
   ; check whether the installation directory path is longer than 30 characters.
   ; If yes, we suggest to the user to enable long filename support
   ;----------------------------------------------------------------------------
   StrLen $InstDirLen "$INSTDIR"

   ; Check whether the registry key that allows for >260 characters in a path name is set
   ReadRegStr $LongPathsEnabled HKLM "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled"

   ${If} $InstDirLen > 30
   ${AndIf} $LongPathsEnabled == "0"
      ; Check whether we're in the Admin group
      UserInfo::GetAccountType
      Pop $AccountType

      ${If} $AccountType == "Admin"
      ${AndIf} ${Cmd} `MessageBox MB_YESNO|MB_ICONQUESTION 'The path name is too long. $\n$\nYou can either enable long file name support in Windows,$\nor you can go back and choose a different path.$\n$\nFor details see: shorturl.at/auBD1$\n$\nEnable long path name support in Windows?' IDYES`
          ; Enable long path names
          WriteRegDWORD HKLM "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1
      ${Else}
          MessageBox MB_OK|MB_ICONEXCLAMATION "Installation path name too long. The installation path must not have more than 30 characters."
          abort
      ${EndIf}
   ${EndIf}
   
   ; Check for spaces in the installation directory path.
   ; ----------------------------------------------------

   ; $R0 = CheckForSpaces( $INSTDIR )
   Push $INSTDIR # Input string (install path).
     Call CheckForSpaces
   Pop $R0 # The function returns the number of spaces found in the input string.

   ; Check if any spaces exist in $INSTDIR.
   ${If} $R0 != 0
     ; Plural if more than 1 space in $INSTDIR.
     ; If $R0 == 1: $R1 = ""; else: $R1 = "s"
     StrCmp $R0 1 0 +3
       StrCpy $R1 ""
     Goto +2
       StrCpy $R1 "s"

     ; Show message box then take the user back to the Directory page.
     MessageBox MB_OK|MB_ICONEXCLAMATION "Error: The Installaton directory \
     has $R0 space character$R1.$\nPlease choose an installation directory without space characters."
     Abort
   ${EndIf}
   
   ; Check for NTFS filesystem. Installations on FAT fail.
   ; -----------------------------------------------------
   StrCpy $5 $INSTDIR 3
   System::Call 'Kernel32::GetVolumeInformation(t "$5",t,i ${NSIS_MAX_STRLEN},*i,*i,*i,t.r1,i ${NSIS_MAX_STRLEN})i.r0'
   ${If} $0 <> 0
   ${AndIf} $1 != "NTFS"
       MessageBox mb_ok "$5 has filesystem type '$1'.$\nOnly NTFS filesystems are supported.$\nPlease choose a different drive."
       Abort
   ${EndIf}

FunctionEnd


;---------------------------------------------------------------------------------------------------------
; Open the MS download page in a browser and enable the [Next] button
Function MSMediaFeaturepack
    ExecShell "open" "https://www.microsoft.com/en-us/software-download/mediafeaturepack"

    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 1
FunctionEnd

;---------------------------------------------------------------------------------------------------------
; Install the MS Media Feature Pack, if it is missing (e.g. on Windows 10 N)
Function MediaPackDialog
    !insertmacro MUI_HEADER_TEXT "Windows Media Feature Pack" "Required software module is missing"

    ; Skip this dialog if mf.dll is installed
    ${If} ${FileExists} "$WINDIR\system32\mf.dll"
        Abort
    ${EndIf}
    
    nsDialogs::Create 1018
    Pop $Dialog

    ${If} $Dialog == error
	Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 48u "The Windows Media Feature Pack is missing on this computer. It is required for Easy Diffusion.$\nYou can continue the installation after installing the Windows Media Feature Pack."
    Pop $Label
 	
    ${NSD_CreateButton} 10% 49u 80% 12u "Download Meda Feature Pack from Microsoft"
    Pop $Button

    GetFunctionAddress $0 MSMediaFeaturePack
    nsDialogs::OnClick $Button $0
    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 0
    nsDialogs::Show
FunctionEnd

;---------------------------------------------------------------------------------------------------------
; MUI Settings
;---------------------------------------------------------------------------------------------------------
!define MUI_ABORTWARNING
!define MUI_ICON "sd.ico"

!define MUI_WELCOMEFINISHPAGE_BITMAP "astro.bmp"

; Welcome page
!define MUI_WELCOMEPAGE_TEXT "This installer will guide you through the installation of Easy Diffusion.$\n$\n\
Click Next to continue."
!insertmacro MUI_PAGE_WELCOME
Page custom MediaPackDialog

; License page
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_LICENSE "..\CreativeML Open RAIL-M License"
; Directory page
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE "DirectoryLeave"
!insertmacro MUI_PAGE_DIRECTORY

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES 

; Finish page
!define MUI_FINISHPAGE_RUN "$INSTDIR\Start Stable Diffusion UI.cmd"
!insertmacro MUI_PAGE_FINISH

; Language files
!insertmacro MUI_LANGUAGE "English"
;---------------------------------------------------------------------------------------------------------
; MUI end
;---------------------------------------------------------------------------------------------------------

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "Install Easy Diffusion.exe"
InstallDir "C:\EasyDiffusion\"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show

;---------------------------------------------------------------------------------------------------------
; List of files to be installed
Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  File "..\CreativeML Open RAIL-M License"
  File "..\How to install and run.txt"
  File "..\LICENSE"
  File "..\scripts\Start Stable Diffusion UI.cmd"
  File /r "${EXISTING_INSTALLATION_DIR}\installer_files"
  File /r "${EXISTING_INSTALLATION_DIR}\profile"
  File /r "${EXISTING_INSTALLATION_DIR}\sd-ui-files"
  SetOutPath "$INSTDIR\scripts"
  File "${EXISTING_INSTALLATION_DIR}\scripts\install_status.txt"
  File "..\scripts\on_env_start.bat"
  File "C:\windows\system32\curl.exe"
  CreateDirectory "$INSTDIR\models"
  CreateDirectory "$INSTDIR\models\stable-diffusion"
  CreateDirectory "$INSTDIR\models\gfpgan"
  CreateDirectory "$INSTDIR\models\realesrgan"
  CreateDirectory "$INSTDIR\models\vae"
  CreateDirectory "$SMPROGRAMS\Easy Diffusion"
  CreateShortCut "$SMPROGRAMS\Easy Diffusion\Easy Diffusion.lnk" "$INSTDIR\Start Stable Diffusion UI.cmd"

  DetailPrint 'Downloading the Stable Diffusion 1.4 model...'
  NScurl::http get "https://huggingface.co/CompVis/stable-diffusion-v-1-4-original/resolve/main/sd-v1-4.ckpt" "$INSTDIR\models\stable-diffusion\sd-v1-4.ckpt" /CANCEL /INSIST /END

  DetailPrint 'Downloading the GFPGAN model...'
  NScurl::http get "https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.3.pth" "$INSTDIR\models\gfpgan\GFPGANv1.3.pth" /CANCEL /INSIST /END

  DetailPrint 'Downloading the RealESRGAN_x4plus model...'
  NScurl::http get "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" "$INSTDIR\models\realesrgan\RealESRGAN_x4plus.pth" /CANCEL /INSIST /END

  DetailPrint 'Downloading the RealESRGAN_x4plus_anime model...'
  NScurl::http get "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth" "$INSTDIR\models\realesrgan\RealESRGAN_x4plus_anime_6B.pth" /CANCEL /INSIST /END

  DetailPrint 'Downloading the default VAE (sd-vae-ft-mse-original) model...'
  NScurl::http get "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.ckpt" "$INSTDIR\models\vae\vae-ft-mse-840000-ema-pruned.ckpt" /CANCEL /INSIST /END

  DetailPrint 'Downloading the CLIP model (clip-vit-large-patch14)...'
  NScurl::http get "https://huggingface.co/openai/clip-vit-large-patch14/resolve/8d052a0f05efbaefbc9e8786ba291cfdf93e5bff/pytorch_model.bin" "$INSTDIR\profile\.cache\huggingface\hub\models--openai--clip-vit-large-patch14\snapshots\8d052a0f05efbaefbc9e8786ba291cfdf93e5bff\pytorch_model.bin" /CANCEL /INSIST /END

SectionEnd

;---------------------------------------------------------------------------------------------------------
; Our installer only needs 25 KB, but once it has run, we need 25 GB
; So we need to overwrite the automatically detected space requirements.
; https://nsis.sourceforge.io/Docs/Chapter4.html#4.9.13.7
; The example in section 4.9.13.7 seems to be wrong: the number
; needs to be provided in Kilobytes.
Function .onInit
   ; Set required size of section 'SEC01' to 25 Gigabytes
   SectionSetSize ${SEC01} 26214400
  
  
   ; Check system meory size. We need at least 8GB
   ; ----------------------------------------------------

   ; allocate a few bytes of memory
   System::Alloc 64
   Pop $1

   ; Retrieve HW info from the Windows Kernel
   System::Call "*$1(i64)"
   System::Call "Kernel32::GlobalMemoryStatusEx(i r1)"
   ; unpack the data into $R2 - $R10
   System::Call "*$1(i.r2, i.r3, l.r4, l.r5, l.r6, l.r7, l.r8, l.r9, l.r10)"

   # free up the memory
   System::Free $1

   ; Result mapping:
   ; "Structure size: $2 bytes"
   ; "Memory load: $3%"
   ; "Total physical memory: $4 bytes"
   ; "Free physical memory: $5 bytes"
   ; "Total page file: $6 bytes"
   ; "Free page file: $7 bytes"
   ; "Total virtual: $8 bytes"
   ; "Free virtual: $9 bytes"

   ; Mem size in MB
   System::Int64Op $4 / 1048576
   Pop $4

   ${If} $4 < "8000"
      MessageBox MB_OK|MB_ICONEXCLAMATION "Warning!$\n$\nYour system has less than 8GB of memory (RAM).$\n$\n\
You can still try to install Easy Diffusion,$\nbut it might have problems to start, or run$\nvery slowly."
   ${EndIf}
  
FunctionEnd


;Section -Post
;  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\installer.exe"
;SectionEnd
