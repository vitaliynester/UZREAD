class DownloadedBookModel {
  final String bookPath;
  final String title;
  final String author;
  final String image;
  final String description;

  DownloadedBookModel(
      this.bookPath, this.title, this.author, this.image, this.description);

  Map<String, dynamic> toJson() => {
        "title": title,
        "author": author,
        "image": image,
        "description": description,
        "bookPath": bookPath,
      };

  DownloadedBookModel.fromJson(Map<String, dynamic> json)
      : title = json["title"],
        author = json["author"],
        image = json["image"],
        description = json["description"],
        bookPath = json["bookPath"];
}
