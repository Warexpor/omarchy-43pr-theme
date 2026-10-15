import QtQuick
import Quickshell
import Quickshell.Io

// Watches ~/.local/state/omarchy/current (the background link and theme dir
// are swapped in there) and runs 43pr-adaptive-tint, which picks the shell
// glass alpha from wallpaper brightness and re-applies shell.toml.
Item {
  id: root

  // Injected by omarchy-shell (the first-party service loader).
  property var shell: null

  readonly property string currentDir: Quickshell.env("HOME") + "/.local/state/omarchy/current"
  property bool rerun: false

  function retint() {
    if (tintProcess.running) {
      root.rerun = true
      return
    }
    // $HOME is expanded by bash (plugin rsync does not template paths).
    tintProcess.command = ["bash", "-c", "exec \"$HOME\"/.config/omarchy/bin/43pr-adaptive-tint"]
    tintProcess.running = true
  }

  // theme-set and bg-set touch several entries in a burst; settle first.
  Timer {
    id: debounce
    interval: 700
    onTriggered: root.retint()
  }

  Process {
    id: tintProcess
    onExited: function(exitCode) {
      if (exitCode !== 0) console.log("43pr tint: exited " + exitCode)
      if (root.rerun) {
        root.rerun = false
        debounce.restart()
      }
    }
  }

  // inotifywait (inotify-tools, an Omarchy base package) reports the link and
  // theme swaps by name; a FileView on the directory missed some of them.
  Process {
    id: watcher
    running: true
    command: ["inotifywait", "-m", "-q", "-e", "create,moved_to,close_write", "--format", "%f", root.currentDir]
    stdout: SplitParser {
      onRead: function(line) {
        var name = String(line).trim()
        if (name === "background" || name === "theme" || name === "theme.name") debounce.restart()
      }
    }
    onExited: function(exitCode) {
      console.log("43pr tint: watcher exited " + exitCode + ", restarting")
      restartWatcher.restart()
    }
  }

  Timer {
    id: restartWatcher
    interval: 5000
    onTriggered: watcher.running = true
  }

  Component.onCompleted: debounce.restart()
}
