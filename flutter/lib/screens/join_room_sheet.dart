import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ctrl.text.trim().length == 4;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // grab handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withAlpha(120)),
            ),
            child: const Icon(Icons.login,
                color: AppColors.primaryLight, size: 26),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('輸入房間代碼',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('向房主索取 4 位數字代碼',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                letterSpacing: 12,
                fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: '0000',
              counterText: '',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                letterSpacing: 12,
                fontWeight: FontWeight.w800,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            maxLength: 4,
            onSubmitted: (v) => _submit(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(70),
                disabledForegroundColor: Colors.white.withAlpha(130),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: ready ? _submit : null,
              child: const Text('加入房間',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 28),
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
