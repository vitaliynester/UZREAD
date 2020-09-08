class PreDownloadModel {
  final String bookAuthors;
  final String bookDescription;
  final String bookDownloadUrl;
  final String bookImage;
  final String bookName;

  PreDownloadModel(this.bookAuthors, this.bookDescription, this.bookDownloadUrl,
      this.bookImage, this.bookName);

  Map<String, dynamic> toJson() => {
        "book_authors": bookAuthors,
        "book_description": bookDescription,
        "book_download_url": bookDownloadUrl,
        "book_image": bookImage,
        "book_name": bookName,
      };

  PreDownloadModel.fromJson(Map<String, dynamic> json)
      : bookAuthors = json["book_authors"],
        bookDescription = json["book_description"],
        bookDownloadUrl = json["book_download_url"],
        bookImage = json["book_image"],
        bookName = json["book_name"];
}
