import 'dart:async';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import 'nfc_snapshot.dart';

abstract class NfcTagService {
  Future<NfcServiceAvailability> checkAvailability();

  /// Starts a single Android ISO 14443 discovery session and returns its tag.
  Future<ScannedNfcTag> readTag();

  /// Starts another session, verifies [expectedUid], then writes the snapshot.
  Future<void> writeTag({
    required String expectedUid,
    required Uint8List payload,
  });

  Future<void> cancelSession();
}

enum NfcServiceAvailability { enabled, disabled, unsupported }

enum NfcTagKind { ndef, blankNdef, formatable, unsupported }

class ScannedNfcTag {
  const ScannedNfcTag({
    required this.uid,
    required this.kind,
    this.message,
    this.isWritable,
    this.maxSize,
  });

  final String uid;
  final NfcTagKind kind;
  final NdefMessage? message;
  final bool? isWritable;
  final int? maxSize;
}

class NfcTagServiceException implements Exception {
  const NfcTagServiceException(this.code, this.message, {this.cause});

  final NfcTagServiceError code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'NfcTagServiceException($code): $message';
}

enum NfcTagServiceError {
  disabled,
  unsupported,
  unsupportedTag,
  readOnly,
  capacity,
  uidMismatch,
  malformedMessage,
  readFailed,
  writeFailed,
}

/// Android implementation backed by nfc_manager. It has no persistence and
/// deliberately ends each session as soon as the tag operation completes.
class PlatformNfcTagService implements NfcTagService {
  bool _sessionActive = false;

  @override
  Future<NfcServiceAvailability> checkAvailability() async {
    try {
      return switch (await NfcManager.instance.checkAvailability()) {
        NfcAvailability.enabled => NfcServiceAvailability.enabled,
        NfcAvailability.disabled => NfcServiceAvailability.disabled,
        NfcAvailability.unsupported => NfcServiceAvailability.unsupported,
      };
    } on UnsupportedError {
      return NfcServiceAvailability.unsupported;
    }
  }

  @override
  Future<ScannedNfcTag> readTag() async {
    await _requireEnabled();
    final result = Completer<ScannedNfcTag>();
    try {
      _sessionActive = true;
      await NfcManager.instance.startSession(
        pollingOptions: const {NfcPollingOption.iso14443},
        onDiscovered: (tag) => _completeRead(tag, result),
      );
    } catch (error) {
      _sessionActive = false;
      throw NfcTagServiceException(
        NfcTagServiceError.readFailed,
        'Unable to start NFC reading.',
        cause: error,
      );
    }
    return result.future;
  }

  @override
  Future<void> writeTag({
    required String expectedUid,
    required Uint8List payload,
  }) async {
    await _requireEnabled();
    final result = Completer<void>();
    try {
      _sessionActive = true;
      await NfcManager.instance.startSession(
        pollingOptions: const {NfcPollingOption.iso14443},
        onDiscovered: (tag) =>
            _completeWrite(tag, expectedUid, payload, result),
      );
    } catch (error) {
      _sessionActive = false;
      throw NfcTagServiceException(
        NfcTagServiceError.writeFailed,
        'Unable to start NFC writing.',
        cause: error,
      );
    }
    return result.future;
  }

  @override
  Future<void> cancelSession() async {
    if (!_sessionActive) {
      return;
    }
    _sessionActive = false;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // The native session may already have ended; cancellation stays idempotent.
    }
  }

  Future<void> _requireEnabled() async {
    switch (await checkAvailability()) {
      case NfcServiceAvailability.enabled:
        return;
      case NfcServiceAvailability.disabled:
        throw const NfcTagServiceException(
          NfcTagServiceError.disabled,
          'NFC is disabled.',
        );
      case NfcServiceAvailability.unsupported:
        throw const NfcTagServiceException(
          NfcTagServiceError.unsupported,
          'This device does not support NFC.',
        );
    }
  }

  void _completeRead(NfcTag tag, Completer<ScannedNfcTag> result) async {
    if (result.isCompleted) {
      return;
    }
    try {
      result.complete(await _readDiscoveredTag(tag));
    } on NfcTagServiceException catch (error) {
      result.completeError(error);
    } catch (error) {
      result.completeError(
        NfcTagServiceException(
          NfcTagServiceError.readFailed,
          'Unable to read this NFC tag.',
          cause: error,
        ),
      );
    } finally {
      await cancelSession();
    }
  }

  void _completeWrite(
    NfcTag tag,
    String expectedUid,
    Uint8List payload,
    Completer<void> result,
  ) async {
    if (result.isCompleted) {
      return;
    }
    try {
      final uid = _uidFrom(tag);
      final message = NfcWriteValidator.messageFor(payload);
      final ndef = Ndef.from(tag);
      if (ndef != null) {
        NfcWriteValidator.validate(
          expectedUid: expectedUid,
          actualUid: uid,
          message: message,
          isWritable: ndef.isWritable,
          maxSize: ndef.maxSize,
        );
        await ndef.write(message: message);
      } else {
        final formatable = NdefFormatableAndroid.from(tag);
        if (formatable == null) {
          throw const NfcTagServiceException(
            NfcTagServiceError.unsupportedTag,
            'This tag is neither NDEF nor NDEF-formatable.',
          );
        }
        NfcWriteValidator.validate(
          expectedUid: expectedUid,
          actualUid: uid,
          message: message,
        );
        await formatable.format(message);
      }
      result.complete();
    } on NfcTagServiceException catch (error) {
      result.completeError(error);
    } catch (error) {
      result.completeError(
        NfcTagServiceException(
          NfcTagServiceError.writeFailed,
          'Unable to write this NFC tag.',
          cause: error,
        ),
      );
    } finally {
      await cancelSession();
    }
  }

  Future<ScannedNfcTag> _readDiscoveredTag(NfcTag tag) async {
    final uid = _uidFrom(tag);
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      return ScannedNfcTag(
        uid: uid,
        kind: NdefFormatableAndroid.from(tag) == null
            ? NfcTagKind.unsupported
            : NfcTagKind.formatable,
      );
    }
    final message = ndef.cachedMessage ?? await ndef.read();
    return ScannedNfcTag(
      uid: uid,
      kind: message == null || message.records.isEmpty
          ? NfcTagKind.blankNdef
          : NfcTagKind.ndef,
      message: message,
      isWritable: ndef.isWritable,
      maxSize: ndef.maxSize,
    );
  }

  String _uidFrom(NfcTag tag) {
    final tagData = NfcTagAndroid.from(tag);
    if (tagData == null || tagData.id.isEmpty) {
      throw const NfcTagServiceException(
        NfcTagServiceError.unsupportedTag,
        'The Android tag UID is unavailable.',
      );
    }
    return tagData.id
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}

/// Platform-independent checks around actual NDEF size and identity. Keeping
/// these separate makes the most failure-prone NFC behaviour testable without
/// an Android reader session.
class NfcWriteValidator {
  NfcWriteValidator._();

  static NdefMessage messageFor(Uint8List payload) => NdefMessage(
    records: [
      NdefRecord(
        typeNameFormat: TypeNameFormat.unknown,
        type: Uint8List(0),
        identifier: Uint8List(0),
        payload: payload,
      ),
    ],
  );

  static void validate({
    required String expectedUid,
    required String actualUid,
    required NdefMessage message,
    bool? isWritable,
    int? maxSize,
  }) {
    if (actualUid != expectedUid) {
      throw const NfcTagServiceException(
        NfcTagServiceError.uidMismatch,
        'The rescanned tag does not match the tag being edited.',
      );
    }
    if (message.byteLength > CompBoxSnapshot.conservativeNdefLimit) {
      throw NfcTagServiceException(
        NfcTagServiceError.capacity,
        'The NDEF message is ${message.byteLength} bytes; CompBox allows at most ${CompBoxSnapshot.conservativeNdefLimit}.',
      );
    }
    if (isWritable == false) {
      throw const NfcTagServiceException(
        NfcTagServiceError.readOnly,
        'This NFC tag is read-only.',
      );
    }
    if (maxSize != null && message.byteLength > maxSize) {
      throw NfcTagServiceException(
        NfcTagServiceError.capacity,
        'The NDEF message is ${message.byteLength} bytes but the tag only has $maxSize bytes.',
      );
    }
  }
}
