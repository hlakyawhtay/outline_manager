import 'package:flutter/material.dart';

import '../../model/access_keys.dart';
import '../../model/outline_server.dart';
import '../../repository/firestore_repository.dart';

class AccessKeySearchSelection {
  const AccessKeySearchSelection({
    required this.accessKey,
    required this.server,
  });

  final AccessKey accessKey;
  final OutlineServer server;
}

class AccessKeySearchDelegate
    extends SearchDelegate<AccessKeySearchSelection?> {
  AccessKeySearchDelegate({
    required this.firestoreRepository,
    required this.serverLookup,
  });

  final FirestoreRepository firestoreRepository;
  final Map<String, OutlineServer> serverLookup;

  @override
  String get searchFieldLabel => 'Search users or notes';

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _SearchResultsList(
      query: query,
      firestoreRepository: firestoreRepository,
      serverLookup: serverLookup,
      onSelect: (selection) => close(context, selection),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _SearchResultsList(
      query: query,
      firestoreRepository: firestoreRepository,
      serverLookup: serverLookup,
      onSelect: (selection) => close(context, selection),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.query,
    required this.firestoreRepository,
    required this.serverLookup,
    required this.onSelect,
  });

  final String query;
  final FirestoreRepository firestoreRepository;
  final Map<String, OutlineServer> serverLookup;
  final void Function(AccessKeySearchSelection selection) onSelect;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const _SearchHint(message: 'Start typing a user name.');
    }
    if (trimmed.length < 2) {
      return const _SearchHint(message: 'Enter at least 2 characters.');
    }
    return FutureBuilder<List<AccessKey>>(
      future: firestoreRepository.searchAccessKeysByName(trimmed, limit: 25),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _SearchHint(message: 'Error: ${snapshot.error}');
        }
        final results = snapshot.data ?? const [];
        if (results.isEmpty) {
          return const _SearchHint(message: 'No users matched that name.');
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, index) {
            final key = results[index];
            final server = key.serverId != null
                ? serverLookup[key.serverId!]
                : null;
            final note = key.note;
            return ListTile(
              title: Text(key.name.isEmpty ? key.outlineId : key.name),
              subtitle: Text(
                server != null
                    ? [
                        server.name,
                        _expiryLabel(key),
                        if (note != null && note.isNotEmpty) 'Note: $note',
                      ].join(' · ')
                    : 'Server unavailable',
              ),
              trailing: const Icon(Icons.north_east),
              onTap: () {
                if (server == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Server information missing. Sync servers and try again.',
                      ),
                    ),
                  );
                  return;
                }
                onSelect(
                  AccessKeySearchSelection(accessKey: key, server: server),
                );
              },
            );
          },
        );
      },
    );
  }

  String _expiryLabel(AccessKey key) {
    final expiry = key.expiredDate;
    if (expiry == null) return 'No expiry';
    final days = expiry.difference(DateTime.now()).inDays;
    return days >= 0 ? 'Expires in ${days}d' : 'Expired';
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
