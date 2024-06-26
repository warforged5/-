import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class VotingPage extends StatefulWidget {
  const VotingPage({super.key});

  @override
  _VotingPageState createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  List<VotingItem> _votingItems = [
    VotingItem('Item 1', VotingStatus.pending),
    VotingItem('Item 2', VotingStatus.pending),
    VotingItem('Item 3', VotingStatus.pending),
    // Add more voting items as needed
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      body: (_) => _buildBody(),
      smallBody: (_) => _buildSmallBody(),
      secondaryBody: (_) => _buildSecondaryBody(),
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.list),
          label: 'Voting List',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(child: _buildVotingList()),
        _buildVotingButtons(),
      ],
    );
  }

  Widget _buildSmallBody() {
    return Column(
      children: [
        Expanded(child: _buildVotingList()),
        _buildVotingButtons(),
      ],
    );
  }

  Widget _buildSecondaryBody() {
    return Container(
      color: Colors.blue.shade100,
      child: const Center(
        child: Text(
          'Secondary Body',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }

  Widget _buildVotingList() {
    return ListView.builder(
      itemCount: _votingItems.length,
      itemBuilder: (context, index) {
        final item = _votingItems[index];
        return ListTile(
          title: Text(item.title),
          trailing: _buildVotingStatusIcon(item.status),
        );
      },
    );
  }

  Widget _buildVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.pending:
        return const Icon(Icons.hourglass_empty);
      case VotingStatus.passed:
        return const Icon(Icons.check, color: Colors.green);
      case VotingStatus.failed:
        return const Icon(Icons.close, color: Colors.red);
    }
  }

  Widget _buildVotingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            _showVotingDialog(VotingStatus.passed);
          },
          child: const Text('Pass'),
        ),
        ElevatedButton(
          onPressed: () {
            _showVotingDialog(VotingStatus.failed);
          },
          child: const Text('Fail'),
        ),
      ],
    );
  }

  void _showVotingDialog(VotingStatus status) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Voting'),
          content: Text('Are you sure you want to vote ${status.toString().split('.').last}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateVotingStatus(status);
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _updateVotingStatus(VotingStatus status) {
    setState(() {
      _votingItems = _votingItems.map((item) {
        return VotingItem(item.title, status);
      }).toList();
    });
  }
}

class VotingItem {
  final String title;
  final VotingStatus status;

  VotingItem(this.title, this.status);
}

enum VotingStatus {
  pending,
  passed,
  failed,
}