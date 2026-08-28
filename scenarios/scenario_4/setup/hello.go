// Scenario 4 controlled payload for the MSc dissertation testbed.
//
// Cross compiled for Windows amd64 and placed at \PORTABLE\HelloWorld.exe
// on the DISS-USB stick. Launched from Explorer during scenario execution
// to generate a Prefetch entry, a Security 4688 process creation event
// and an Amcache trace tied to a specific USB volume.
//
// Author: Syed Muhammad Saqlain Abbas (W21634541)
// Module: 7CSEF001W.2 MSc Cyber Security and Forensics Project
// Repo:   github.com/dx7er/msc-diss-7csef001w
//
// The program has no side effects beyond stdout. It does not read the
// filesystem, does not open network sockets and does not modify the
// registry. It waits for Enter so the researcher can visually confirm
// execution before the process exits.

package main

import (
	"bufio"
	"fmt"
	"os"
	"os/user"
	"strings"
	"time"
)

const (
	moduleCode = "7CSEF001W.2"
	moduleName = "MSc Cyber Security and Forensics Project"
	university = "University of Westminster"
	author     = "Syed Muhammad Saqlain Abbas (W21634541)"
	repository = "github.com/dx7er/msc-diss-7csef001w"
	scenarioID = "Scenario 4 (USB attach, browse, execute)"
)

func main() {
	rule := strings.Repeat("=", 78)

	fmt.Println(rule)
	fmt.Printf("  %s (%s)\n", moduleName, moduleCode)
	fmt.Printf("  %s\n", university)
	fmt.Println(rule)
	fmt.Println()

	fmt.Printf("Author       : %s\n", author)
	fmt.Printf("Repository   : %s\n", repository)
	fmt.Printf("Scenario     : %s\n", scenarioID)
	fmt.Println()

	fmt.Println("Purpose")
	fmt.Println("  This executable is a controlled forensic payload for the")
	fmt.Println("  dissertation testbed. It is staged on a prepared USB stick")
	fmt.Println("  (volume label DISS-USB) at \\PORTABLE\\HelloWorld.exe and")
	fmt.Println("  launched from Windows Explorer during scenario execution.")
	fmt.Println()
	fmt.Println("  Running it produces correlated artefacts across the three")
	fmt.Println("  classes examined in this dissertation:")
	fmt.Println("    * Prefetch          HELLOWORLD.EXE-*.pf")
	fmt.Println("    * Event Logs        Security 4688 process creation")
	fmt.Println("    * ShellBags         BagMRU entry for the USB \\PORTABLE\\ path")
	fmt.Println()
	fmt.Println("  It performs no network activity, writes no files and makes")
	fmt.Println("  no registry changes. Output is limited to this console.")
	fmt.Println()

	hostname, _ := os.Hostname()
	currentUser := "(unknown)"
	if u, err := user.Current(); err == nil {
		currentUser = u.Username
	}
	nowUTC := time.Now().UTC().Format("2006-01-02 15:04:05 UTC")

	fmt.Println("Runtime")
	fmt.Printf("  Host       : %s\n", hostname)
	fmt.Printf("  User       : %s\n", currentUser)
	fmt.Printf("  Started at : %s\n", nowUTC)
	fmt.Println()

	fmt.Println(rule)
	fmt.Println("Press Enter to close this window.")
	fmt.Println(rule)

	bufio.NewReader(os.Stdin).ReadString('\n')
}
