import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unpaid'),
            Tab(text: 'Paid'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              // TODO: Navigate to analytics
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UnpaidInvoicesTab(),
          _PaidInvoicesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }
}

// Unpaid invoices tab
class _UnpaidInvoicesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(unpaidInvoicesProvider);

    return invoicesAsync.when(
      data: (invoices) {
        if (invoices.isEmpty) {
          return _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No unpaid invoices',
            subtitle: 'Create your first invoice to get started',
            actionLabel: 'Create Invoice',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(unpaidInvoicesProvider);
          },
          child: ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _InvoiceListItem(invoice: invoice);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading invoices: $error'),
      ),
    );
  }
}

// Paid invoices tab
class _PaidInvoicesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(paidInvoicesProvider);

    return invoicesAsync.when(
      data: (invoices) {
        if (invoices.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No paid invoices yet',
            subtitle: 'Paid invoices will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(paidInvoicesProvider);
          },
          child: ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _InvoiceListItem(invoice: invoice);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading invoices: $error'),
      ),
    );
  }
}

// Invoice list item widget
class _InvoiceListItem extends ConsumerWidget {
  final Invoice invoice;

  const _InvoiceListItem({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerRepositoryProvider);

    return customerAsync.when(
      data: (customerRepo) {
        return FutureBuilder<Customer?>(
          future: customerRepo.getCustomerById(invoice.customerId),
          builder: (context, snapshot) {
            final customerName = snapshot.data?.name ?? 'Unknown Customer';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoiceDetailScreen(invoiceId: invoice.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          _StatusBadge(status: invoice.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customerName,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${invoice.total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: invoice.status == InvoiceStatus.paid
                                      ? Colors.green
                                      : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (invoice.dueDate != null)
                            Text(
                              _getDueDateText(invoice),
                              style: TextStyle(
                                color: _getDueDateColor(invoice),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  String _getDueDateText(Invoice invoice) {
    if (invoice.status == InvoiceStatus.paid) {
      return 'Paid ${DateFormat('MMM d').format(invoice.paidAt!)}';
    }

    final daysUntilDue = invoice.dueDate!.difference(DateTime.now()).inDays;

    if (daysUntilDue < 0) {
      return 'Overdue by ${-daysUntilDue} days';
    } else if (daysUntilDue == 0) {
      return 'Due today';
    } else if (daysUntilDue <= 7) {
      return 'Due in $daysUntilDue days';
    } else {
      return 'Due ${DateFormat('MMM d').format(invoice.dueDate!)}';
    }
  }

  Color _getDueDateColor(Invoice invoice) {
    if (invoice.status == InvoiceStatus.paid) {
      return Colors.green;
    }

    final daysUntilDue = invoice.dueDate!.difference(DateTime.now()).inDays;

    if (daysUntilDue < 0) {
      return Colors.red;
    } else if (daysUntilDue <= 3) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
}

// Status badge widget
class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case InvoiceStatus.unpaid:
        color = Colors.orange;
        label = 'UNPAID';
        break;
      case InvoiceStatus.paid:
        color = Colors.green;
        label = 'PAID';
        break;
      case InvoiceStatus.deleted:
        color = Colors.red;
        label = 'DELETED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Empty state widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}