import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice.dart';
import '../models/line_item.dart';
import '../models/customer.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/customer_repository.dart';

// Repository providers
final invoiceRepositoryProvider = FutureProvider<InvoiceRepository>((ref) async {
  return await InvoiceRepository.create();
});

final customerRepositoryProvider = FutureProvider<CustomerRepository>((ref) async {
  return await CustomerRepository.create();
});

// Invoice list providers
final unpaidInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final repo = await ref.watch(invoiceRepositoryProvider.future);
  return await repo.getUnpaidInvoices();
});

final paidInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final repo = await ref.watch(invoiceRepositoryProvider.future);
  return await repo.getPaidInvoices();
});

// Customer list provider
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = await ref.watch(customerRepositoryProvider.future);
  return await repo.getAllCustomers();
});

// Selected invoice provider (for viewing/editing)
final selectedInvoiceProvider = StateProvider<String?>((ref) => null);

// Invoice with items provider
final invoiceWithItemsProvider = FutureProvider.family<(Invoice, List<LineItem>), String>(
  (ref, invoiceId) async {
    final repo = await ref.watch(invoiceRepositoryProvider.future);
    return await repo.getInvoiceWithItems(invoiceId);
  },
);