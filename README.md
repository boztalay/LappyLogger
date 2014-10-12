LappyLogger
===========

A Mac OS X tool to log various statistics about the usage of my laptop. Here's what it currently gathers every minute:

* Battery level (%)
* Battery life (time remaining)
* Whether the charger is plugged in
* Number of keystrokes in the last minute
* Number of mouse clicks in the last minute

It also tracks when it starts up, which correlates with how often I reboot my laptop.

It's a lightweight background process that's registered with launchd to make sure it starts up at login and persists. It also provides a quick tool for exporting the logged data to a `.csv` for analysis.

The logging data is stored in a custom binary file format to cut down on the size of the files, and the data sources only record data if they need to. If the battery life hasn't changed in the last minute, it won't record another data point.

It has measures in place to handle its data files getting corrupted, so it'll create a new data file for a data source if its data file gets corrupted, while still keeping the old file around so it that data isn't completely lost.

Building and Installing
-----------------------

NOTE: You're welcome to use this yourself (I'd love pull requests!), but keep in mind that this isn't 100% polished (which should be evident from this installation process).

First of all, clone this repository and open up `LappyLogger.xcodeproj` under `LappyLogger/`. You'll need at least Xcode 6 to build the background process, and 6.1 (beta at the time of writing) to build the app.

To build the background process, select the `LappyLoggerRelease` scheme in the top left, then build an archive by going to `Product -> Archive`. When the archive is done building, the Organizer window should pop up. Select the latest archive and export it, selecting to save the build products. Navigate to the root of this repository and save them there under `LappyLoggerRelease/` (sometimes Xcode likes to rename them).

To install the background process, run the following commands.

```bash
# Copies the binary and launchd plist to the appropriate places
sudo ./install.sh

# Tells launchd about the process and launches it
sudo launchctl load -w -F /Library/LaunchAgents/com.boztalay.LappyLogger.plist
```

It should be up and running! Check that `~/.LappyLogger` exists now. That directory holds the configuration (`config.plist`), log file (`LappyLogger.log`), and the actual data (`logData/`).

If you ever want to stop using LappyLogger, you can unload the process from launchd by running

```bash
sudo launchctl unload /Library/LaunchAgents/com.boztalay.LappyLogger.plist
```

Notes
-----

Keep in mind that the background process gets run as root, which it needs to capture keypresses and mouse clicks. If that sketches you out (totally understandable), you should be able to see in the code that there's no funny business.

Also, even though the background process is started up at login, you won't see it in the Login Items screen under System Preferences.

Known Issues - To Do
--------------------

* Screen brightness data source
* Volume data source
* Keyboard brightness data source
* Other data sources?
* Switch to use as much event-based monitoring as possible instead of polling
* If the entire `~/.LappyLogger/` directory gets deleted, recreate it
* Finish the reader app
