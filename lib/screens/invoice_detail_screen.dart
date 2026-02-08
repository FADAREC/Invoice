import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/line_item.dart';
import '../models/customer.dart';
import '../providers/invoice_provider.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceWithItemsProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share invoice
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(context, ref);
              }
            },
          ),
        ],
      ),
      body: invoiceAsync.when(
        data: (data) {
          final invoice = data.$1;
          final items = data.$2;
          return _InvoiceDetailBody(invoice: invoice, items: items);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repo = await ref.read(invoiceRepositoryProvider.future);
              await repo.deleteInvoice(invoiceId);
              
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail screen
              }
              
              ref.invalidate(unpaidInvoicesProvider);
              ref.invalidate(paidInvoicesProvider);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailBody extends ConsumerWidget {
  final Invoice invoice;
  final List<LineItem> items;

  const _InvoiceDetailBody({
    required this.invoice,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerRepositoryProvider);

    return customerAsync.when(
      data: (customerRepo) {
        return FutureBuilder<Customer?>(
          future: customerRepo.getCustomerById(invoice.customerId),
          builder: (context, snapshot) {
            final customer = snapshot.data;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.invoiceNumber,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                customer?.name ?? 'Unknown Customer',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),

                        // Customer info
                        if (customer != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer Details',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                if (customer.email != null)
                                  Text('Email: ${customer.email}'),
                                if (customer.phone != null)
                                  Text('Phone: ${customer.phone}'),
                                if (customer.address != null)
                                  Text('Address: ${customer.address}'),
                              ],
                            ),
                          ),

                        const Divider(),

                        // Line items
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Items',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              ...items.map((item) => _LineItemRow(item: item)),
                            ],
                          ),
                        ),

                        const Divider(),

                        // Totals
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _TotalRow('Subtotal', invoice.subtotal),
                              if (invoice.tax > 0)
                                _TotalRow('Tax', invoice.tax),
                              if (invoice.discount > 0)
                                _TotalRow('Discount', -invoice.discount),
                              const Divider(),
                              _TotalRow(
                                'Total',
                                invoice.total,
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),

                        // Payment info
                        if (invoice.status == InvoiceStatus.paid)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '✓ PAID',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Paid on: ${DateFormat('MMM d, yyyy').format(invoice.paidAt!)}',
                                  ),
                                  if (invoice.paymentMethod != null)
                                    Text('Method: ${invoice.paymentMethod}'),
                                ],
                              ),
                            ),
                          ),

                        if (invoice.notes != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(invoice.notes!),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                if (invoice.status == InvoiceStatus.unpaid)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Send invoice
                            },
                            icon: const Icon(Icons.send),
                            label: const Text('Send'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showMarkAsPaidDialog(context, ref),
                            icon: const Icon(Icons.check),
                            label: const Text('Mark as Paid'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading customer')),
    );
  }

  void _showMarkAsPaidDialog(BuildContext context, WidgetRef ref) {
    DateTime selectedDate = DateTime.now();
    String selectedMethod = 'Cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Mark as Paid'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Payment Date'),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: ['Cash', 'Bank Transfer', 'Check', 'Card', 'Other']
                      .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedMethod = value);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final repo = await ref.read(invoiceRepositoryProvider.future);
                  await repo.markAsPaid(
                    invoiceId: invoice.id,
                    paymentDate: selectedDate,
                    paymentMethod: selectedMethod,
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close detail screen
                  }

                  ref.invalidate(unpaidInvoicesProvider);
                  ref.invalidate(paidInvoicesProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice marked as paid')),
                    );
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  final LineItem item;

  const _LineItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.description != null)
                  Text(
                    item.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                Text(
                  '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _TotalRow(this.label, this.amount, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}