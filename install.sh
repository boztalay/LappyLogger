rm -r /Applications/LappyLogger.app
cp -r ./LappyLoggerRelease/Products/Applications/LappyLogger.app /Applications/LappyLogger.app
cp ./LappyLoggerRelease/Products/Library/LaunchDaemons/com.boztalay.LappyLogger.plist /Library/LaunchDaemons/
rm /usr/local/bin/LappyLogger
ln -s /Applications/LappyLogger.app/LappyLogger /usr/local/bin/LappyLogger
