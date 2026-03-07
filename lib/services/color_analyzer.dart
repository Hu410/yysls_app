import 'dart:io';
import 'package:image/image.dart' as img;

enum EquipQuality { gold, purple, unknown }

class ColorAnalyzer {
  ColorAnalyzer._();

  /// Analyze the top portion of an equipment screenshot to determine quality.
  /// Purple equipment has a dominant purple/violet hue in the header area,
  /// while gold equipment has a warm yellow/amber hue.
  static Future<EquipQuality> analyzeEquipQuality(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return EquipQuality.unknown;

    // Sample the top 30% of the image (where the equipment header/name is)
    final sampleHeight = (decoded.height * 0.30).round().clamp(1, decoded.height);
    final sampleWidth = decoded.width;

    int purpleCount = 0;
    int goldCount = 0;
    int totalSampled = 0;

    // Sample every 4th pixel for performance
    const step = 4;
    for (var y = 0; y < sampleHeight; y += step) {
      for (var x = 0; x < sampleWidth; x += step) {
        final pixel = decoded.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final hsv = _rgbToHsv(r, g, b);
        final h = hsv[0]; // 0-360
        final s = hsv[1]; // 0-1
        final v = hsv[2]; // 0-1

        // Skip very dark or very desaturated pixels
        if (v < 0.15 || s < 0.10) continue;

        totalSampled++;

        // Purple range: hue ~240-310, with decent saturation
        if (h >= 230 && h <= 320 && s >= 0.15 && v >= 0.20) {
          purpleCount++;
        }
        // Gold/yellow/amber range: hue ~20-65
        else if (h >= 15 && h <= 70 && s >= 0.25 && v >= 0.30) {
          goldCount++;
        }
      }
    }

    if (totalSampled == 0) return EquipQuality.unknown;

    final purpleRatio = purpleCount / totalSampled;
    final goldRatio = goldCount / totalSampled;

    // Purple if purple pixels are >8% of sampled and more than gold
    if (purpleRatio > 0.08 && purpleRatio > goldRatio) {
      return EquipQuality.purple;
    }
    // Gold if gold pixels are >8% of sampled
    if (goldRatio > 0.08) {
      return EquipQuality.gold;
    }

    return EquipQuality.unknown;
  }

  static List<double> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final cMax = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
    final cMin = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
    final delta = cMax - cMin;

    double h = 0;
    if (delta != 0) {
      if (cMax == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (cMax == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
    }
    if (h < 0) h += 360;

    final s = cMax == 0 ? 0.0 : delta / cMax;
    final v = cMax;

    return [h, s, v];
  }
}
