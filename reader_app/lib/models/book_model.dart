class BookModel {
  final String title;
  final String author;
  final String size;
  final String image;
  final String description;

  BookModel(this.title, this.author, this.size, this.image, this.description);

  Map<String, dynamic> toJson() => {
        "title": title,
        "author": author,
        "size": size,
        "image": image,
        "description": description,
      };
  BookModel.fromJson(Map<String, dynamic> json)
      : title = json["title"],
        author = json["author"],
        size = json["size"],
        image = json["image"],
        description = json["description"];
}
