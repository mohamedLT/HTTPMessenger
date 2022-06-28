// ignore_for_file: camel_case_types, hash_and_equals

class user {
  final String firstName;
  final String lastName;
  final String userName;
  bool active;

  @override
  bool operator ==(other) => eq(this, other as user);
  user(this.firstName, this.lastName, this.userName, [this.active = false]);
  static String fullName(user user) => "${user.firstName} ${user.lastName}";
  static bool eq(user a, user b) {
    return a.firstName == b.firstName &&
        a.lastName == b.lastName &&
        a.userName == b.userName &&
        a.active == b.active;
  }
}

class message {
  final String data;
  final DateTime dateTime;
  final user sender;
  @override
  bool operator ==(o) {
    var other = o as message;
    return data == other.data &&
        dateTime == other.dateTime &&
        sender == other.sender;
  }

  message(this.data, this.dateTime, this.sender);
}
