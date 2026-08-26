/// Raster format to use when exporting PDF pages as images.
enum ImageOutputFormat {
  png,
  jpg;

  String get extension => this == ImageOutputFormat.png ? 'png' : 'jpg';
}
