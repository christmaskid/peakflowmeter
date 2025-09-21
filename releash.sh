flutter build apk --release
zip -r build/app/outputs/flutter-apk/app-release.apk ../peakflowmeter.apk.zip
mv ../peakflowmeter.apk.zip ../peakflowmeter-$(date +%Y%m%d-%H%M%S).apk.zip

flutter build windows --release
zip -r build/windows/runner/Release ../peakflowmeter-windows.zip
mv ../peakflowmeter-windows.zip ../peakflowmeter-windows-$(date +%Y%m%d-%H%M%S).zip