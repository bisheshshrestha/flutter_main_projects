import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MLClassificationService {
  static Interpreter? _interpreter;
  static List<String>? _labels;
  static bool _isInitialized = false;

  // Model configuration
  static const int _inputSize = 224; // Adjust based on your model
  static const double _threshold = 0.6; // Confidence threshold

  // Category mapping from model labels to app categories
  static const Map<String, String> _categoryMapping = {
    'plastic': 'Plastic Bottle',
    'paper': 'Paper',
    'glass': 'Glass',
    'cardboard': 'Cardboard', // Map cardboard to Paper category
    'metal': 'Metal', // You might want to add Metal category
  };

  /// Initialize the ML model and labels
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');

      // Load labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.trim().isNotEmpty).toList();

      _isInitialized = true;
      print('ML Model initialized successfully');
      print('Labels loaded: $_labels');
      return true;
    } catch (e) {
      print('Error initializing ML model: $e');
      return false;
    }
  }

  /// Classify an image and return the predicted category
  static Future<ClassificationResult> classifyImage(File imageFile) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return ClassificationResult(
          success: false,
          error: 'Failed to initialize ML model',
        );
      }
    }

    try {
      // Preprocess the image
      final input = await _preprocessImage(imageFile);
      if (input == null) {
        return ClassificationResult(
          success: false,
          error: 'Failed to preprocess image',
        );
      }

      // Run inference
      final output = List.filled(_labels!.length, 0.0).reshape([1, _labels!.length]);
      _interpreter!.run(input, output);

      // Process results
      final predictions = output[0] as List<double>;
      final result = _processResults(predictions);

      return result;
    } catch (e) {
      print('Error during classification: $e');
      return ClassificationResult(
        success: false,
        error: 'Classification failed: ${e.toString()}',
      );
    }
  }

  /// Preprocess image for model input
  static Future<List<List<List<List<double>>>>?> _preprocessImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize image to model input size
      final resized = img.copyResize(image, width: _inputSize, height: _inputSize);

      // Convert to normalized float values
      final input = List.generate(
        1,
            (i) => List.generate(
          _inputSize,
              (y) => List.generate(
            _inputSize,
                (x) => List.generate(3, (c) {
              final pixel = resized.getPixel(x, y);
              switch (c) {
                case 0: return (img.getRed(pixel) / 255.0); // R
                case 1: return (img.getGreen(pixel) / 255.0); // G
                case 2: return (img.getBlue(pixel) / 255.0); // B
                default: return 0.0;
              }
            }),
          ),
        ),
      );

      return input;
    } catch (e) {
      print('Error preprocessing image: $e');
      return null;
    }
  }

  /// Process model output and return classification result
  static ClassificationResult _processResults(List<double> predictions) {
    if (_labels == null || predictions.isEmpty) {
      return ClassificationResult(
        success: false,
        error: 'Invalid predictions or labels',
      );
    }

    // Find the highest confidence prediction
    double maxConfidence = 0.0;
    int maxIndex = 0;

    for (int i = 0; i < predictions.length; i++) {
      if (predictions[i] > maxConfidence) {
        maxConfidence = predictions[i];
        maxIndex = i;
      }
    }

    final predictedLabel = _labels![maxIndex].toLowerCase().trim();
    final confidence = maxConfidence;

    print('Predicted: $predictedLabel with confidence: ${(confidence * 100).toStringAsFixed(1)}%');

    // Check if confidence meets threshold
    if (confidence < _threshold) {
      return ClassificationResult(
        success: false,
        error: 'Low confidence prediction. Cannot determine recyclable category.',
        confidence: confidence,
        predictedLabel: predictedLabel,
        allPredictions: _getAllPredictions(predictions),
      );
    }

    // Map to app category
    final appCategory = _categoryMapping[predictedLabel];
    if (appCategory == null) {
      return ClassificationResult(
        success: false,
        error: 'Item detected but not recyclable in our system.',
        confidence: confidence,
        predictedLabel: predictedLabel,
        allPredictions: _getAllPredictions(predictions),
      );
    }

    return ClassificationResult(
      success: true,
      category: appCategory,
      confidence: confidence,
      predictedLabel: predictedLabel,
      allPredictions: _getAllPredictions(predictions),
    );
  }

  /// Get all predictions with labels for debugging
  static List<PredictionResult> _getAllPredictions(List<double> predictions) {
    final results = <PredictionResult>[];
    for (int i = 0; i < predictions.length && i < _labels!.length; i++) {
      results.add(PredictionResult(
        label: _labels![i],
        confidence: predictions[i],
      ));
    }
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  /// Dispose resources
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isInitialized = false;
  }

  /// Get available recyclable categories
  static List<String> getAvailableCategories() {
    return _categoryMapping.values.toSet().toList();
  }

  /// Check if a category is supported
  static bool isCategorySupported(String category) {
    return _categoryMapping.containsValue(category);
  }
}

/// Result of image classification
class ClassificationResult {
  final bool success;
  final String? category;
  final double? confidence;
  final String? predictedLabel;
  final String? error;
  final List<PredictionResult>? allPredictions;

  ClassificationResult({
    required this.success,
    this.category,
    this.confidence,
    this.predictedLabel,
    this.error,
    this.allPredictions,
  });

  @override
  String toString() {
    if (success) {
      return 'Success: $category (${(confidence! * 100).toStringAsFixed(1)}%)';
    } else {
      return 'Error: $error';
    }
  }
}

/// Individual prediction result
class PredictionResult {
  final String label;
  final double confidence;

  PredictionResult({
    required this.label,
    required this.confidence,
  });

  @override
  String toString() {
    return '$label: ${(confidence * 100).toStringAsFixed(1)}%';
  }
}