import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:invoice_app/database/database.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/line_item.dart';
// ignore: unused_import
import '../models/item.dart';
import '../providers/invoice_provider.dart';
import '../repositories/item_repository.dart';
import 'add_customer_screen.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  Customer? _selectedCustomer;
  final List<_InvoiceLineItem> _items = [];
  double _taxRate = 0.0;
  double _discount = 0.0;
  final _notesController = TextEditingController();
  DateTime? _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _tax - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Invoice'),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveInvoice,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer Section
          _buildCustomerSection(),
          const SizedBox(height: 24),

          // Items Section
          _buildItemsSection(),
          const SizedBox(height: 24),

          // Pricing Section
          _buildPricingSection(),
          const SizedBox(height: 24),

          // Additional Details
          _buildDetailsSection(),
          const SizedBox(height: 24),

          // Total Summary
          _buildTotalSummary(),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: _selectedCustomer != null && _items.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddItemBottomSheet(),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      child: InkWell(
        onTap: () => _showCustomerPicker(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _selectedCustomer == null
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_add, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Customer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to choose or add new',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                )
              : Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        _selectedCustomer!.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCustomer!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_selectedCustomer!.email != null)
                            Text(
                              _selectedCustomer!.email!,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showCustomerPicker(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    if (_selectedCustomer == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_items.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showAddItemBottomSheet(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_items.isEmpty)
          Card(
            child: InkWell(
              onTap: () => _showAddItemBottomSheet(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(32),
                child: const Column(
                  children: [
                    Icon(Icons.add_circle_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Add your first item',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (item.description != null && item.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _editItem(index),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() => _items.removeAt(index));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPricingSection() {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: (_taxRate * 100).toStringAsFixed(1),
                    decoration: const InputDecoration(
                      labelText: 'Tax Rate (%)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        _taxRate = (double.tryParse(value) ?? 0) / 100;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _discount.toStringAsFixed(2),
                    decoration: const InputDecoration(
                      labelText: 'Discount (\$)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        _discount = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Due Date'),
              subtitle: Text(
                _dueDate != null
                    ? DateFormat('MMM d, yyyy').format(_dueDate!)
                    : 'Not set',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
            ),
            const Divider(),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Payment instructions, terms, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSummary() {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow('Subtotal', _subtotal),
            if (_tax > 0) _SummaryRow('Tax', _tax),
            if (_discount > 0) _SummaryRow('Discount', -_discount, isNegative: true),
            const Divider(),
            _SummaryRow('Total', _total, isTotal: true),
          ],
        ),
      ),
    );
  }

  void _showCustomerPicker() async {
    final customersAsync = await ref.read(customersProvider.future);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Customer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCustomerScreen(),
                        ),
                      );
                      if (result == true) {
                        ref.invalidate(customersProvider);
                        _showCustomerPicker(); // Reopen with new customer
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: customersAsync.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No customers yet'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddCustomerScreen(),
                                ),
                              );
                              if (result == true) {
                                ref.invalidate(customersProvider);
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Customer'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: customersAsync.length,
                      itemBuilder: (context, index) {
                        final customer = customersAsync[index];
                        final isSelected = _selectedCustomer?.id == customer.id;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
                            child: Text(
                              customer.name[0].toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          title: Text(customer.name),
                          subtitle: customer.email != null ? Text(customer.email!) : null,
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                          onTap: () {
                            setState(() => _selectedCustomer = customer);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemBottomSheet({_InvoiceLineItem? existingItem, int? editIndex}) async {
    final itemRepo = await ItemRepository.create();
    final savedItems = await itemRepo.getAllItems();

    if (!mounted) return;

    final nameController = TextEditingController(text: existingItem?.name);
    final descController = TextEditingController(text: existingItem?.description);
    final qtyController = TextEditingController(
      text: existingItem?.quantity.toString() ?? '1',
    );
    final priceController = TextEditingController(
      text: existingItem?.unitPrice.toStringAsFixed(2) ?? '',
    );

    bool saveAsItem = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingItem == null ? 'Add Item' : 'Edit Item',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (savedItems.isNotEmpty && existingItem == null) ...[
                        const Text(
                          'Saved Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: savedItems.map((item) {
                            return ActionChip(
                              label: Text(item.name),
                              onPressed: () {
                                nameController.text = item.name;
                                descController.text = item.description ?? '';
                                priceController.text = item.defaultPrice.toStringAsFixed(2);
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              decoration: const InputDecoration(
                                labelText: 'Unit Price *',
                                border: OutlineInputBorder(),
                                prefixText: '\$ ',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (existingItem == null)
                        CheckboxListTile(
                          title: const Text('Save as reusable item'),
                          value: saveAsItem,
                          onChanged: (value) {
                            setModalState(() => saveAsItem = value ?? false);
                          },
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final qty = double.tryParse(qtyController.text) ?? 0;
                          final price = double.tryParse(priceController.text) ?? 0;

                          if (name.isEmpty || qty <= 0 || price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all required fields'),
                              ),
                            );
                            return;
                          }

                          if (saveAsItem) {
                            await itemRepo.createItem(
                              name: name,
                              description: descController.text.trim().isEmpty
                                  ? null
                                  : descController.text.trim(),
                              defaultPrice: price,
                            );
                          }

                          final newItem = _InvoiceLineItem(
                            name: name,
                            description: descController.text.trim().isEmpty
                                ? null
                                : descController.text.trim(),
                            quantity: qty,
                            unitPrice: price,
                          );

                          setState(() {
                            if (editIndex != null) {
                              _items[editIndex] = newItem;
                            } else {
                              _items.add(newItem);
                            }
                          });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(existingItem == null ? 'Add Item' : 'Update Item'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editItem(int index) {
    _showAddItemBottomSheet(
      existingItem: _items[index],
      editIndex: index,
    );
  }

  Future<void> _saveInvoice() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final invoiceRepo = await ref.read(invoiceRepositoryProvider.future);
      final db = await AppDatabase.instance.database;
      
      final branchResult = await db.query('branches', limit: 1);
      final branchId = branchResult.first['id'] as String;

      final lineItems = _items.map((item) {
        return LineItem(
          id: const Uuid().v4(),
          invoiceId: '', // Will be set by repository
          name: item.name,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          total: item.total,
        );
      }).toList();

      final invoice = await invoiceRepo.createInvoice(
        branchId: branchId,
        customerId: _selectedCustomer!.id,
        items: lineItems,
        taxRate: _taxRate,
        discount: _discount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        dueDate: _dueDate,
      );

      if (mounted) {
        ref.invalidate(unpaidInvoicesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${invoice.invoiceNumber} created')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _InvoiceLineItem {
  final String name;
  final String? description;
  final double quantity;
  final double unitPrice;

  _InvoiceLineItem({
    required this.name,
    this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;
  final bool isNegative;

  const _SummaryRow(
    this.label,
    this.amount, {
    this.isTotal = false,
    this.isNegative = false,
  });

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
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}