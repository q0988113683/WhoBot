import 'package:flutter/material.dart';
import '../core/constants.dart';

class JoinRoomSheet extends StatefulWidget {
  final void Function(String code) onJoin;
  const JoinRoomSheet({super.key, required this.onJoin});

  @override
  State<JoinRoomSheet> createState() => _JoinRoomSheetState();
}

class _JoinRoomSheetState extends State<JoinRoomSheet> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('輸入房間代碼',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                letterSpacing: 4,
                fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0000',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            maxLength: 4,
            onSubmitted: (v) => _submit(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submit,
              child: const Text('加入房間',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _submit() {
    final code = _ctrl.text.trim();
    if (code.length == 4) {
      Navigator.pop(context);
      widget.onJoin(code);
    }
  }
}
