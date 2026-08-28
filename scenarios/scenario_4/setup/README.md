# Scenario 4 setup assets

Assets required to prepare the controlled USB stick used by Scenario 4 (USB attach, browse, execute).

## Files

| File            | Purpose                                          |
|-----------------|--------------------------------------------------|
| `HelloWorld.exe`| Small console executable placed at `\PORTABLE\HelloWorld.exe` on the USB stick and launched at step A05 of every run. Cross compiled Windows PE32+ (x86-64), console subsystem, no external DLL dependencies, no network activity, no filesystem writes. |
| `hello.go`      | Source for `HelloWorld.exe`, retained for reproducibility. Any Go 1.21+ toolchain will rebuild an equivalent binary (byte for byte reproducibility depends on toolchain version and build flags). |

## What the payload does

Prints a header identifying the module (7CSEF001W.2 MSc Cyber Security and Forensics Project), author, repository, scenario ID, and its own purpose statement, followed by the host name, current user and UTC start time. Waits for the researcher to press Enter, then exits. No network sockets are opened, no files are written, no registry keys are touched. Output is limited to the console window.

## Build provenance

Rebuilt on 2026-08-22 in the Cowork sandbox with:

```bash
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 \
  go build -trimpath -ldflags="-s -w" -o HelloWorld.exe hello.go
```

Go toolchain: `go1.24.7 linux/amd64`. `file HelloWorld.exe` reports `PE32+ executable (console) x86-64, for MS Windows`.

## SHA-256

Recorded at build time; the same hash MUST appear on the USB stick and in the acquisition manifest for every run:

```
0c1f7fdf4a47f67d36042559e0b2b91e557cc1dd12b097bb78ba01ec7182954a  HelloWorld.exe
```

Same physical stick, same binary, across all 3 repetitions per catalogue rule (constant VID, PID, serial).

## History

* 2026-08-18 initial build (`3e6e823cf1b26da7dace80d9b2666bca3a97d27862bf307668555ee38daf889d`), minimal placeholder message.
* 2026-08-22 rebuilt with a professional dissertation identification header describing the module, author, repository, scenario purpose and expected forensic artefacts. New hash above. Old binary superseded and MUST NOT be reused.
