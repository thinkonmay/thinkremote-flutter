import 'package:flutter/services.dart';
import 'package:flutter_webrtc_client/input/MouseButtonPacket.dart';

import 'moon_bridge.dart';

class NvConnection {
  final Object mouseInputLock = Object();
  late double relMouseX, relMouseY, relMouseWidth, relMouseHeight;
  late double absMouseX, absMouseY, absMouseWidth, absMouseHeight;
  late bool batchMouseInput;
  // late bool isMonkey;

  NvConnection(bool batchMouseInput) {
    this.batchMouseInput = batchMouseInput;
  }

  // touch
  sendMouseMove(final double deltaX, final double deltaY) {
    // if (!isMonkey) {
    synchronized(mouseInputLock) {
      relMouseX += deltaX;
      relMouseY += deltaY;

      // Reset these to ensure we don't send this as a position update
      relMouseWidth = 0;
      relMouseHeight = 0;
    }

    if (!batchMouseInput) {
      flushMousePosition();
    }
    // }
  }

  void sendMousePosition(
      double x, double y, double referenceWidth, double referenceHeight) {
    // if (!isMonkey) {
    synchronized(mouseInputLock) {
      absMouseX = x;
      absMouseY = y;
      absMouseWidth = referenceWidth;
      absMouseHeight = referenceHeight;
    }

    if (!batchMouseInput) {
      flushMousePosition();
    }
    // }
  }

  void sendMouseMoveAsMousePosition(double deltaX, double deltaY,
      double referenceWidth, double referenceHeight) {
    // if (!isMonkey) {
    synchronized(mouseInputLock) {
      // Only accumulate the delta if the reference size is the same
      if (relMouseWidth == referenceWidth &&
          relMouseHeight == referenceHeight) {
        relMouseX += deltaX;
        relMouseY += deltaY;
      } else {
        relMouseX = deltaX;
        relMouseY = deltaY;
      }

      relMouseWidth = referenceWidth;
      relMouseHeight = referenceHeight;
    }

    if (!batchMouseInput) {
      flushMousePosition();
    }
    // }
  }

  void sendMouseButtonDown(final int mouseButton) {
    // if (!isMonkey) {
    flushMousePosition();
    MoonBridge().sendMouseButton(MouseButtonPacket.PRESS_EVENT, mouseButton);
    // }
  }

  void sendMouseButtonUp(final int mouseButton) {
    // if (!isMonkey) {
    flushMousePosition();
    MoonBridge().sendMouseButton(MouseButtonPacket.RELEASE_EVENT, mouseButton);
    // }
  }

  // gamepad

  void sendMultiControllerInput(
      final double controllerNumber,
      final double activeGamepadMask,
      final double buttonFlags,
      final int leftTrigger,
      final int rightTrigger,
      final double leftStickX,
      final double leftStickY,
      final double rightStickX,
      final double rightStickY) {
    // if (!isMonkey) {
    MoonBridge().sendMultiControllerInput(
        controllerNumber,
        activeGamepadMask,
        buttonFlags,
        leftTrigger,
        rightTrigger,
        leftStickX,
        leftStickY,
        rightStickX,
        rightStickY);
    // }
  }

  void sendControllerInput(
      final double buttonFlags,
      final int leftTrigger,
      final int rightTrigger,
      final double leftStickX,
      final double leftStickY,
      final double rightStickX,
      final double rightStickY) {
    // if (!isMonkey) {
    MoonBridge().sendControllerInput(buttonFlags, leftTrigger, rightTrigger,
        leftStickX, leftStickY, rightStickX, rightStickY);
    // }
  }

  // keyboard
  void sendKeyboardInput(double keyMap, int keyDirection, int modifier) {
    // if (!isMonkey) {
    MoonBridge().sendKeyboardInput(keyMap, keyDirection, modifier);
    // }
  }

  void sendMouseScroll(int scrollClicks) {
    // if (!isMonkey) {
    flushMousePosition();
    MoonBridge().sendMouseScroll(scrollClicks);
    // }
  }

  void sendMouseHighResScroll(double scrollAmount) {
    // if (!isMonkey) {
    flushMousePosition();
    MoonBridge().sendMouseHighResScroll(scrollAmount);
    // }
  }

  //////////////////////////////////////////////////////////////////////////////////////////
  void flushMousePosition() {
    synchronized(mouseInputLock) {
      if (relMouseX != 0 || relMouseY != 0) {
        if (relMouseWidth != 0 || relMouseHeight != 0) {
          MoonBridge().sendMouseMoveAsMousePosition(
              relMouseX, relMouseY, relMouseWidth, relMouseHeight);
        } else {
          MoonBridge().sendMouseMove(relMouseX, relMouseY);
        }
        relMouseX = relMouseY = relMouseWidth = relMouseHeight = 0;
      }
      if (absMouseX != 0 ||
          absMouseY != 0 ||
          absMouseWidth != 0 ||
          absMouseHeight != 0) {
        MoonBridge().sendMousePosition(
            absMouseX, absMouseY, absMouseWidth, absMouseHeight);
        absMouseX = absMouseY = absMouseWidth = absMouseHeight = 0;
      }
    }
  }
}
