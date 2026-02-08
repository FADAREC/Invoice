import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/line_item.dart';
import '../providers/invoice_provider.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  int _currentStep = 0;
  
  // Step 1: Customer
  Customer? _selectedCustomer;
  
  // Step 2: Items
  final List<LineItem> _items = [];
  
  // Step 3: Pricing
  double _taxRate = 0.0;
  double _discount = 0.0;
  
  // Step 4: Details
  final _notesController = TextEditingController();
  DateTime? _dueDate;
  
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 3 ? 'Save Invoice' : 'Continue'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Customer'),
            content: _buildCustomerStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Items'),
            content: _buildItemsStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Pricing'),
            content: _buildPricingStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Details'),
            content: _buildDetailsStep(),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStep() {
    final customersAsync = ref.watch(customersProvider);

    return customersAsync.when(
      data: (customers) {
        if (customers.isEmpty) {
          return Center(
            child: Column(
              children: [
                const Text('No customers yet'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to add customer
                    Navigator.pushNamed(context, '/add-customer');
                  },
                  child: const Text('Add Customer'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a customer:'),
            const SizedBox(height: 16),
            ...customers.map((customer) {
              final isSelected = _selectedCustomer?.id == customer.id;
              return Card(
                color: isSelected ? Colors.blue.shade50 : null,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(customer.name[0].toUpperCase()),
                  ),
                  title: Text(customer.name),
                  subtitle: customer.email != null ? Text(customer.email!) : null,
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                  onTap: () {
                    setState(() {
                      _selectedCustomer = customer;
                    });
                  },
                ),
              );
            }).toList(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildItemsStep() {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No items added yet'),
            ),
          )
        else
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text('${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _items.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showAddItemDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
        ),
        const SizedBox(height: 16),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingStep() {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.total);
    final tax = subtotal * _taxRate;
    final total = subtotal + tax - _discount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: (_taxRate * 100).toStringAsFixed(1),
          decoration: const InputDecoration(
            labelText: 'Tax Rate (%)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _taxRate = (double.tryParse(value) ?? 0) / 100;
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _discount.toStringAsFixed(2),
          decoration: const InputDecoration(
            labelText: 'Discount (\$)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _discount = double.tryParse(value) ?? 0;
            });
          },
        ),
        const SizedBox(height: 24),
        const Divider(),
        _PricingRow('Subtotal', subtotal),
        if (tax > 0) _PricingRow('Tax', tax),
        if (_discount > 0) _PricingRow('Discount', -_discount),
        const Divider(),
        _PricingRow('Total', total, isTotal: true),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text('Due Date'),
          subtitle: Text(_dueDate != null ? _dueDate!.toString().split(' ')[0] : 'Not set'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _dueDate = date;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  void _onStepContinue() async {
    if (_currentStep == 0) {
      // Step 1: Customer validation
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      // Step 2: Items validation
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      // Step 3: Pricing (no validation needed)
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      // Step 4: Save invoice
      await _saveInvoice();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name *'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity *'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Unit Price *'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final quantity = double.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;

              if (name.isEmpty || quantity <= 0 || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              final item = LineItem(
                id: const Uuid().v4(),
                invoiceId: '', // Will be set when saving
                name: name,
                description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                quantity: quantity,
                unitPrice: price,
                total: quantity * price,
              );

              setState(() {
                _items.add(item);
              });

              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveInvoice() async {
    setState(() => _isSaving = true);

    try {
      final invoiceRepo = await ref.read(invoiceRepositoryProvider.future);
      
      // Get active branch ID
      final db = await ref.read(invoiceRepositoryProvider.future).then((repo) => repo.db);
      final branchResult = await db.query('settings', where: 'key = ?', whereArgs: ['active_branch_id']);
      final branchId = branchResult.isNotEmpty 
          ? branchResult.first['value'] as String
          : (await db.query('branches', limit: 1)).first['id'] as String;

      final invoice = await invoiceRepo.createInvoice(
        branchId: branchId,
        customerId: _selectedCustomer!.id,
        items: _items,
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

class _PricingRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _PricingRow(this.label, this.amount, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}