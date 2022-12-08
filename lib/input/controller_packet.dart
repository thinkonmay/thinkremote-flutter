class ControllerPacket {
  static const double A_FLAG = 0x1000;
  static const double B_FLAG = 0x2000;
  static const double X_FLAG = 0x4000;
  static const double Y_FLAG = 0x8000;
  static const double UP_FLAG = 0x0001;
  static const double DOWN_FLAG = 0x0002;
  static const double LEFT_FLAG = 0x0004;
  static const double RIGHT_FLAG = 0x0008;
  static const double LB_FLAG = 0x0100;
  static const double RB_FLAG = 0x0200;
  static const double PLAY_FLAG = 0x0010;
  static const double BACK_FLAG = 0x0020;
  static const double LS_CLK_FLAG = 0x0040;
  static const double RS_CLK_FLAG = 0x0080;
  static const double SPECIAL_BUTTON_FLAG = 0x0400;
}
