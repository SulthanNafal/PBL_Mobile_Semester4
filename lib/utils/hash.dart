class HashCustom {
  static String encrypt(String text) {
    StringBuffer result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);

      // Huruf Kapital (A-Z: 65-90)
      if (charCode >= 65 && charCode <= 90) {
        result.writeCharCode(charCode + 7);
      }
      // Huruf Kecil (a-z: 97-122)
      else if (charCode >= 97 && charCode <= 122) {
        result.writeCharCode(charCode + 5);
      }
      // Angka (0-9: 48-57)
      else if (charCode >= 48 && charCode <= 57) {
        result.writeCharCode(charCode + 3);
      }
      // Simbol & Lainnya
      else {
        result.writeCharCode(charCode);
      }
    }
    return result.toString();
  }
}