class UpdateInfo {
  final String version;
  final String tagName;
  final String releaseNotes;
  final String? apkDownloadUrl;
  final String? ipaDownloadUrl;
  final String publishedAt;

  const UpdateInfo({
    required this.version,
    required this.tagName,
    required this.releaseNotes,
    this.apkDownloadUrl,
    this.ipaDownloadUrl,
    required this.publishedAt,
  });
}
