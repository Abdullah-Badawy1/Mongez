class ServiceItem {
  final String title;
  final String image;
  final String cover;
  final String workerImage;
  final String description;
  final List<String> comments;
  final String address;
  final int? workerId;
  final int? categoryId;

  ServiceItem({
    required this.title,
    required this.image,
    required this.cover,
    required this.workerImage,
    required this.description,
    required this.comments,
    required this.address,
    this.workerId,
    this.categoryId,
  });
}
