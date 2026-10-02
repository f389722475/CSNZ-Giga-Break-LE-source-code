# CSNZ BeamGunLE — native C/C++ 0.7.4-r1

## Connection hotfix: ipfix1

The standalone launcher previously passed the server IP as `-ip "127.0.0.1"`.
The game's command-line parser preserves those quotes, causing the connection to fail even with a correct INI.
The launcher now passes the already-validated address without quotes; executable paths remain quoted.
Only the standalone launcher behavior changes. Weapon logic and the game-build checks are unchanged.
The fixed `CSNZ_LENative.exe` has file version **0.7.4.2**; `BeamGunLE.dll` remains on the 0.7.4.1 weapon implementation.

The missing `build.cmd`, `package.ps1`, and `package/` installation scripts are restored.
After building, run `package.ps1`, extract the generated Deploy ZIP, and run `Install.cmd` to generate
`payload/native.ini` for your own game path and server. Then start the server normally and use `Start_Mod.cmd`.
Do not run an unconfigured EXE directly from the build directory.

For an existing compiled setup, replace only `CSNZ_LENative.exe` after exiting the game; keep your existing
`BeamGunLE.dll` and `native.ini`. For manual configuration, copy `package/native.ini.example` to `native.ini`
beside the EXE and DLL, then edit the game root, address, and port. The root must contain `Bin`.
`127.0.0.1:30002` is only the default for a server on the same machine. For non-ASCII paths, save the INI as UTF-16 LE with a BOM.
Never publish your generated INI or runtime logs.

The connection defect was reproduced with the original code. Changing only IP quoting restored the actual
isolated client/server connection and native `READY` initialization with the same weapon DLL.
This is not account-authentication, combat, or multiplayer acceptance.

A **native Windows x86 port** of the current 0.7.4 fix logic. The goal is to preserve the accepted feature scope,
remove the JS / Frida / Python runtimes, and introduce no additional weapon behavior as part of this port.

## What This Package Is

`src/beamgunle.cpp` contains the weapon logic; `src/game_abi.h` defines the empirically determined CSNZ0930 GoldSrc
ABI and offsets within extended structures; `src/native_runtime.cpp` implements the DLL and native entry-point hooks.
The code calls the current game's FireBullets3, TakeDamage, TraceLine, PlaybackEvent,
temporary-model, and Studio bone interfaces directly, using the x86 `__thiscall` / `__cdecl` / `__fastcall` calling conventions.

This is not a replacement `mp.dll` built against the original HLSDK, nor does it fabricate GetEntityAPI exports.
CSNZ's weapon classes, player objects, and TEMPENTITY have been extended; CS 1.6 SDK class layouts cannot be applied to them.
Without the complete CSNZ project and class definitions, the deliverable is a companion native extension DLL,
not a claimed reconstruction of the entire client/server. The source files are compilable C/C++, not JS wrappers.

## Build

On Windows, install Visual Studio 2022 Build Tools with the “Desktop development with C++” workload and the Windows SDK.
Run `build.cmd` directly to automatically locate an installed x86 build environment; alternatively, run it from an x86 Native Tools
Command Prompt. Do not launch it from an x64 build environment.

Outputs: `build/bin/BeamGunLE.dll` and `build/bin/CSNZ_LENative.exe`.
The build uses C++17, `/MT`, `/EHa`, and SSE2; the required C dependency, MinHook 1.3.4, is bundled with the source.
Compilation does not require CMake, Python, Node.js, Frida, or any game binaries.

`build/bin/CSNZ_LENative.exe --self-check` only loads the local DLL and checks its exports;
it does not launch the game or install hooks. There is no separate large-scale test project.

Packaging: after building, run `powershell -NoProfile -ExecutionPolicy Bypass -File package.ps1`.
By default, output goes to `dist` under this source directory; use `-DistRoot` to specify another absolute directory.
Two separate ZIP archives are generated: Source and Deploy. Existing ZIP archives with the same names will not be overwritten.

## Implementation Locations

| File | Contents |
| --- | --- |
| `src/beamgunle.cpp` | Firing, area-of-effect damage, state, charging, defense, wingmen, and local model balancing |
| `src/game_abi.h` | x86 calling signatures, vectors, TraceResult, and declarations for safe memory access |
| `src/build_profile.h` | Instruction entry points and relocation information for the current build; not file hashes |
| `src/native_runtime.cpp` | 9 native hooks, version gating, thread boundaries, deactivation cleanup, and DLL exports |
| `src/launcher.cpp` | Native launcher; loads the DLL only into a version-matched game process that it has newly launched itself |
| `third_party/minhook/` | Files required for x86 from upstream v1.3.4, with the complete license |

## Key Constraints

- Matches only ID 726 and the known LE vtable; preserves the game's original function call chain and does not write directly to the target's HP.
- Version matching uses PE machine / timestamp / SizeOfImage; entry-point handling uses 16-byte instruction sequences with correct relocation.
  No SHA256 hashes are generated, and on-disk file verification is not used as a version interface.
- All game logic runs on the engine callback thread. The startup worker thread handles only initialization, waiting, and control.
  State is protected by a reentrant lock; native damage calls can enter the defense hook on the same thread.
- The final-damage hook is located in the middle of a function. A dedicated x86 naked stub saves GPR, EFLAGS, and x87/SSE state.
  After restoring that state, execution resumes at the original instructions through a MinHook trampoline, rather than incorrectly returning from the mid-function hook as if it were an ordinary function.
- The DLL entry point neither installs hooks nor starts threads. The loader calls LE_Start only after LoadLibraryW completes.
  Remote addresses for system loader functions are resolved using the modules that actually contain them and their RVAs, accounting for KernelBase forwarding and ASLR.
- After deactivation, cleanup runs separately during server and client frames; the DLL is not forcibly unloaded while callbacks are still on the stack.
  The DLL and game modules remain loaded until the process exits. The full map/mode lifecycle remains outside the acceptance-tested scope.
- Logging is limited to initialization, failures, deactivation, and summaries; the old per-shot telemetry hooks are not ported.
- Shield restoration amounts, Fast Hands counts, and multiplayer synchronization retain their existing “partially complete” status; no speculative implementations are added.

## Validation Scope

Validation for the original 0.7.4-r1 release was limited to MSVC x86 compilation, export/dependency checks, and a standalone DLL load check. An installation preflight check
also verified the target game build; the game was not launched for acceptance testing of the native version. Results previously obtained in actual gameplay with the old JS version do not automatically apply
to this port.

## Licensing and Distribution

This package contains no game DLLs/EXEs, decompiled game source code, models, textures, accounts, databases, logs, or
game paths from the author's machine. The publisher determines the distribution license for the mod itself; no open-source license has been assigned without authorization.
See `third_party/minhook/LICENSE.txt` for the licenses of MinHook and its included components.
