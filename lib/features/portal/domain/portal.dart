enum PortalFailure {
  credentials,
  unreachable,
  timeout,
  expired,
  malformed,
  server,
  insecure,
  storage,
}

class PortalException implements Exception {
  const PortalException(this.kind);
  final PortalFailure kind;
  @override
  String toString() => 'PortalException(${kind.name})';
}

enum PortalSection {
  dashboard,
  service,
  traffic,
  usage,
  balance,
  payments,
  packages,
  reports,
  documents,
  notifications,
  profile,
  invoices,
}

class PortalField {
  const PortalField(this.label, this.value);
  final String label;
  final String value;
}

class UsageLink {
  const UsageLink(this.label, this.parameters);
  final String label;
  final Map<String, String> parameters;
}

class PortalTable {
  const PortalTable(this.headers, this.rows);
  final List<String> headers;
  final List<List<String>> rows;
}

class PortalPage {
  const PortalPage({
    this.fields = const [],
    this.tables = const [],
    this.usageLinks = const [],
    this.hourlyBytes = const [],
    this.notice,
    this.totalBytes,
    this.usedBytes,
  });
  final List<PortalField> fields;
  final List<PortalTable> tables;
  final List<UsageLink> usageLinks;
  final List<double> hourlyBytes;
  final double? totalBytes;
  final double? usedBytes;
  final String? notice;
  bool get isEmpty =>
      fields.isEmpty &&
      tables.every((t) => t.rows.isEmpty) &&
      usageLinks.isEmpty &&
      hourlyBytes.isEmpty;
}

abstract interface class PortalRepository {
  DateTime? get expiresAt;
  Future<bool> restore();
  Future<void> login(
    String baseUrl,
    String username,
    String password, {
    bool allowHttp = false,
  });
  Future<PortalPage> read(
    PortalSection section, {
    Map<String, String> usage = const {},
    String report = 'ServiceHistory',
  });
  Future<void> logout();
  Future<void> clear();
}
