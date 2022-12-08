import 'package:flutter/services.dart';

class MoonBridge {
  void sendMouseMove(double deltaX, double deltaY) {}

  void sendMousePosition(
      double x, double y, double referenceWidth, double referenceHeight) {}

  void sendMouseMoveAsMousePosition(double deltaX, double deltaY,
      double referenceWidth, double referenceHeight) {}

  void sendMouseButton(int buttonEvent, int mouseButton) {}

  // gamepad
  void sendMultiControllerInput(
      double controllerNumber,
      double activeGamepadMask,
      double buttonFlags,
      int leftTrigger,
      int rightTrigger,
      double leftStickX,
      double leftStickY,
      double rightStickX,
      double rightStickY) {}

  void sendControllerInput(
      double buttonFlags,
      int leftTrigger,
      int rightTrigger,
      double leftStickX,
      double leftStickY,
      double rightStickX,
      double rightStickY) {}

  // keyboard
  void sendKeyboardInput(double keyMap, int keyDirection, int modifier) {}

  void sendMouseScroll(int scrollClicks) {}
  void sendMouseHighResScroll(double scrollAmount) {}

  void handleMotionEvent(AndroidMotionEvent event) {
    // getToolType: event.pointerProperties[0];
  }
}
