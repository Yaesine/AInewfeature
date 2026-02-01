# StepFlow AI (iOS)

This repo now includes an Xcode project so you can run the app on a device.

## Run on iPhone
1. Open `StepFlowAI.xcodeproj` in Xcode 15+.
2. Select the **StepFlowAI** target.
3. Set your **Team** in **Signing & Capabilities** (required for device builds).
4. Plug in your iPhone and select it as the run destination.
5. Press **Run**.

If you see a signing error, ensure you have a valid Apple Developer account and that the bundle identifier is unique for your team.

## Notes
- The app uses an asset catalog placeholder for AppIcon. You can replace it with your own icons later.
- iOS deployment target is set to **iOS 17.0**.
