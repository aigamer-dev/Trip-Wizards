import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/group_chat_service.dart';
import 'package:travel_wizards/src/shared/services/encryption_service.dart';

/// Widget that displays a chat message with async decryption support
class DecryptedMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final TextStyle? style;

  const DecryptedMessageWidget({
    super.key,
    required this.message,
    this.style,
  });

  @override
  State<DecryptedMessageWidget> createState() => _DecryptedMessageWidgetState();
}

class _DecryptedMessageWidgetState extends State<DecryptedMessageWidget> {
  String? _decryptedMessage;
  bool _isDecrypting = false;
  bool _decryptionFailed = false;

  @override
  void initState() {
    super.initState();
    _decryptMessage();
  }

  Future<void> _decryptMessage() async {
    if (!widget.message.isEncrypted || widget.message.encryptedData == null) {
      setState(() {
        _decryptedMessage = widget.message.message;
      });
      return;
    }

    setState(() {
      _isDecrypting = true;
    });

    try {
      final decrypted = await EncryptionService.instance
          .decryptMessage(widget.message.encryptedData!);
      
      if (mounted) {
        setState(() {
          _decryptedMessage = decrypted;
          _isDecrypting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _decryptedMessage = '[Unable to decrypt message]';
          _isDecrypting = false;
          _decryptionFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDecrypting) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Decrypting...',
            style: widget.style?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (widget.message.isEncrypted && !_decryptionFailed)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.lock,
              size: 14,
              color: widget.style?.color?.withOpacity(0.7),
            ),
          ),
        Expanded(
          child: Text(
            _decryptedMessage ?? widget.message.message,
            style: widget.style,
          ),
        ),
      ],
    );
  }
}
