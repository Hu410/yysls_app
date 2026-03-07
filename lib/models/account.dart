class Account {
  final String id;
  final String name;

  const Account({required this.id, required this.name});

  Account copyWith({String? id, String? name}) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
