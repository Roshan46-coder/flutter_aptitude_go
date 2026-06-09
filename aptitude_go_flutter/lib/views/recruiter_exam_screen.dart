import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class RecruiterExamScreen extends StatefulWidget {
  const RecruiterExamScreen({super.key});

  @override
  State<RecruiterExamScreen> createState() => _RecruiterExamScreenState();
}

class _RecruiterExamScreenState extends State<RecruiterExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController(text: "10");
  final _thresholdValueController = TextEditingController(text: "0");

  int? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _categoriesLoading = true;

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = TimeOfDay.now();

  String _thresholdType = 'TIME'; // TIME (FCFS seats) or LEVEL
  bool _isSubmitting = false;

  // Questions state
  final List<Map<String, dynamic>> _questions = [];

  // Controllers for the current question form
  final _qTextController = TextEditingController();
  final _opAController = TextEditingController();
  final _opBController = TextEditingController();
  final _opCController = TextEditingController();
  final _opDController = TextEditingController();
  String _correctOption = 'A';
  final _marksController = TextEditingController(text: "1");

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _thresholdValueController.dispose();
    _qTextController.dispose();
    _opAController.dispose();
    _opBController.dispose();
    _opCController.dispose();
    _opDController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final res = await api.get('tests/categories/');
      if (mounted) {
        setState(() {
          _categories = res.data['categories'] ?? [];
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories[0]['id'];
          }
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      try {
        final res = await api.get('tests/practice/');
        if (mounted) {
          final List<dynamic> practiceCats = res.data['general_categories'] ?? [];
          setState(() {
            _categories = practiceCats;
            if (_categories.isNotEmpty) {
              _selectedCategoryId = _categories[0]['id'];
            }
            _categoriesLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _categoriesLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _addQuestion() {
    if (_qTextController.text.trim().isEmpty ||
        _opAController.text.trim().isEmpty ||
        _opBController.text.trim().isEmpty ||
        _opCController.text.trim().isEmpty ||
        _opDController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all question fields'), backgroundColor: AppTheme.livesRed),
      );
      return;
    }

    setState(() {
      _questions.add({
        'text': _qTextController.text.trim(),
        'option_a': _opAController.text.trim(),
        'option_b': _opBController.text.trim(),
        'option_c': _opCController.text.trim(),
        'option_d': _opDController.text.trim(),
        'correct_option': _correctOption,
        'marks': int.tryParse(_marksController.text.trim()) ?? 1,
      });

      // Clear fields
      _qTextController.clear();
      _opAController.clear();
      _opBController.clear();
      _opCController.clear();
      _opDController.clear();
      _correctOption = 'A';
      _marksController.text = "1";
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _submitExam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one question to the exam'), backgroundColor: AppTheme.livesRed),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final api = Provider.of<ApiClient>(context, listen: false);

    // Construct start and end datetimes
    final startDT = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDT = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final payload = {
      'title': _titleController.text.trim(),
      'category_id': _selectedCategoryId,
      'description': _descController.text.trim(),
      'start_time': startDT.toUtc().toIso8601String(),
      'end_time': endDT.toUtc().toIso8601String(),
      'time_limit_seconds': (int.tryParse(_durationController.text.trim()) ?? 10) * 60,
      'threshold_type': _thresholdType,
      'threshold_value': int.tryParse(_thresholdValueController.text.trim()) ?? 0,
      'questions': _questions,
    };

    try {
      final res = await api.post('events/create/', data: payload);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res.data != null && res.data['success'] == true) {
          final code = res.data['access_code'] as String? ?? 'ERROR';
          _showCodePopup(code);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['error'] ?? 'Failed to create exam'), backgroundColor: AppTheme.livesRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.livesRed),
        );
      }
    }
  }

  void _showCodePopup(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 50),
              SizedBox(height: 12),
              Text(
                "Exam Code Generated Successfully",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Provide this secure code to candidates to join the exam.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppTheme.neonPurple),
                      tooltip: "Copy Code",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text("Code copied to clipboard!"),
                            duration: Duration(seconds: 1),
                            backgroundColor: AppTheme.neonPurple,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Pop Create Exam Screen back to Dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedStartDate = "${_startDate.day}/${_startDate.month}/${_startDate.year}";
    final formattedStartTime = _startTime.format(context);
    final formattedEndDate = "${_endDate.day}/${_endDate.month}/${_endDate.year}";
    final formattedEndTime = _endTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Private Exam"),
      ),
      body: _categoriesLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- EXAM DETAILS SECTION ---
                    _sectionHeader("Exam Configuration"),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: "Exam Title",
                                prefixIcon: Icon(Icons.title_rounded),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: "Description (optional)",
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.description_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Aptitude Category",
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _categories.map<DropdownMenuItem<int>>((cat) {
                                return DropdownMenuItem<int>(
                                  value: cat['id'] as int,
                                  child: Text(cat['name'] as String? ?? 'Category'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedCategoryId = val);
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Duration (minutes)",
                                      prefixIcon: Icon(Icons.timer_outlined),
                                    ),
                                    validator: (val) => val == null || int.tryParse(val) == null ? "Enter valid duration" : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- TIME LIMITS ---
                    _sectionHeader("Scheduling"),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.play_circle_outline, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                                const SizedBox(width: 8),
                                Text("Exam Starts:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectDate(context, true),
                                    icon: const Icon(Icons.calendar_month, size: 14),
                                    label: Text(formattedStartDate),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectTime(context, true),
                                    icon: const Icon(Icons.access_time, size: 14),
                                    label: Text(formattedStartTime),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.stop_circle_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                                const SizedBox(width: 8),
                                Text("Exam Ends (Cut-off):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectDate(context, false),
                                    icon: const Icon(Icons.calendar_month, size: 14),
                                    label: Text(formattedEndDate),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectTime(context, false),
                                    icon: const Icon(Icons.access_time, size: 14),
                                    label: Text(formattedEndTime),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- ACCESS & THRESHOLDS ---
                    _sectionHeader("Candidate Restrictions"),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _thresholdType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Restriction Type",
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'TIME', child: Text("Seat Limit (First Come First Serve)")),
                                DropdownMenuItem(value: 'LEVEL', child: Text("Minimum Level Required")),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _thresholdType = val);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _thresholdValueController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: _thresholdType == 'TIME' ? "Max Candidates (0 for Unlimited)" : "Level Required",
                                prefixIcon: Icon(_thresholdType == 'TIME' ? Icons.event_seat : Icons.star_border_rounded),
                              ),
                              validator: (val) => val == null || int.tryParse(val) == null ? "Enter numeric value" : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- ADD QUESTIONS FORM ---
                    _sectionHeader("Add Exam Questions (${_questions.length} added)"),
                    const SizedBox(height: 12),
                    Card(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.6),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _qTextController,
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: "Question Text"),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: TextFormField(controller: _opAController, decoration: const InputDecoration(labelText: "Option A"))),
                                const SizedBox(width: 10),
                                Expanded(child: TextFormField(controller: _opBController, decoration: const InputDecoration(labelText: "Option B"))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: TextFormField(controller: _opCController, decoration: const InputDecoration(labelText: "Option C"))),
                                const SizedBox(width: 10),
                                Expanded(child: TextFormField(controller: _opDController, decoration: const InputDecoration(labelText: "Option D"))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: _correctOption,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: "Correct Answer"),
                                    items: const [
                                      DropdownMenuItem(value: 'A', child: Text("Option A")),
                                      DropdownMenuItem(value: 'B', child: Text("Option B")),
                                      DropdownMenuItem(value: 'C', child: Text("Option C")),
                                      DropdownMenuItem(value: 'D', child: Text("Option D")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _correctOption = val);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _marksController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: "Marks"),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _addQuestion,
                              icon: const Icon(Icons.add_circle_outline, size: 16),
                              label: const Text("Add Question to List"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.15),
                                foregroundColor: AppTheme.neonPurple,
                                side: BorderSide(color: AppTheme.neonPurple.withValues(alpha: 0.3)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- QUESTIONS LIST ---
                    if (_questions.isNotEmpty) ...[
                      Text(
                        "Exam Questions Overview",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70)),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _questions.length,
                        itemBuilder: (context, idx) {
                          final q = _questions[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              title: Text(
                                "${idx + 1}. ${q['text']}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "A: ${q['option_a']} | B: ${q['option_b']} | C: ${q['option_c']} | D: ${q['option_d']}\nCorrect: Option ${q['correct_option']} | Marks: ${q['marks']}",
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.livesRed),
                                onPressed: () => _removeQuestion(idx),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- GENERATE CODE BUTTON ---
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitExam,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Generate Exam Code",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: AppTheme.neonPurple,
        letterSpacing: 0.5,
      ),
    );
  }
}
