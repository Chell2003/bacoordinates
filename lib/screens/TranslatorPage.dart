import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:bacoordinates/providers/theme_provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bacoordinates/components/DarkModeToggle.dart';

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final _textController = TextEditingController();
  String _translatedText = '';
  String _selectedSourceLanguage = 'English';
  String _selectedTargetLanguage = 'Filipino';
  bool _isLoading = false;
  bool _isListening = false;
  final FlutterTts flutterTts = FlutterTts();
  String _errorMessage = '';

  final Map<String, String> _languageCodes = {
    'English': 'en',
    'Filipino': 'tl',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Chinese': 'zh',
    'Taiwanese': 'zh-TW',
    'Singaporean': 'ms-SG',
    'Malaysian': 'ms',
  };

  final List<String> _languages = [
    'English',
    'Filipino',
    'Japanese',
    'Korean',
    'Chinese',
    'Taiwanese',
    'Singaporean',
    'Malaysian',
  ];

  // Map to hold TTS language codes for each language
  final Map<String, String> _ttsLanguageCodes = {
    'English': 'en-US',
    'Filipino': 'fil-PH',
    'Japanese': 'ja-JP',
    'Korean': 'ko-KR',
    'Chinese': 'zh-CN',
    'Taiwanese': 'zh-TW',
    'Singaporean': 'ms-SG',
    'Malaysian': 'ms-MY',
  };

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    
    // Get available voices
    try {
      final voices = await flutterTts.getVoices;
      print("Available voices: $voices");
    } catch (e) {
      print("Could not get voices: $e");
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  TranslateLanguage? _getTranslateLanguage(String language) {
    switch (language) {
      case 'English':
        return TranslateLanguage.english;
      case 'Filipino':
        return TranslateLanguage.tagalog;
      case 'Japanese':
        return TranslateLanguage.japanese;
      case 'Korean':
        return TranslateLanguage.korean;
      case 'Chinese':
        return TranslateLanguage.chinese;
      case 'Taiwanese':
        return TranslateLanguage.chinese;
      case 'Singaporean':
        return TranslateLanguage.malay;
      case 'Malaysian':
        return TranslateLanguage.malay;
      default:
        return null;
    }
  }

  // Use both ML Kit and a fallback method to ensure translation works
  Future<void> _translate() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // First try with Google ML Kit
    try {
      await _translateWithMLKit();
    } catch (e) {
      print("ML Kit translation failed: $e");
      
      // If ML Kit fails, try with the fallback method
      try {
        await _translateWithFallback();
      } catch (e) {
        setState(() {
          _errorMessage = 'Translation failed: ${e.toString()}';
          _translatedText = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error translating: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ML Kit translation method
  Future<void> _translateWithMLKit() async {
    final sourceLang = _getTranslateLanguage(_selectedSourceLanguage);
    final targetLang = _getTranslateLanguage(_selectedTargetLanguage);

    if (sourceLang == null || targetLang == null) {
      throw Exception("Selected language is not supported by ML Kit.");
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
    );

    try {
      // Only try to download models if we're sure the plugin is available
      if (!_errorMessage.contains("MissingPluginException")) {
        final modelManager = OnDeviceTranslatorModelManager();
        
        bool isSourceModelDownloaded = await modelManager.isModelDownloaded(sourceLang.bcpCode);
        if (!isSourceModelDownloaded) {
          await modelManager.downloadModel(sourceLang.bcpCode);
        }
        
        bool isTargetModelDownloaded = await modelManager.isModelDownloaded(targetLang.bcpCode);
        if (!isTargetModelDownloaded) {
          await modelManager.downloadModel(targetLang.bcpCode);
        }
      }
      
      final translatedText = await translator.translateText(_textController.text);
      
      setState(() {
        _translatedText = translatedText;
      });
    } catch (e) {
      if (e.toString().contains("MissingPluginException")) {
        setState(() {
          _errorMessage = "Plugin not available on this device";
        });
      }
      rethrow;
    } finally {
      await translator.close();
    }
  }

  // Fallback translation using a free API
  Future<void> _translateWithFallback() async {
    final sourceLanguage = _languageCodes[_selectedSourceLanguage] ?? 'en';
    final targetLanguage = _languageCodes[_selectedTargetLanguage] ?? 'tl';
    final text = _textController.text.trim();
    
    // Use LibreTranslate API as fallback
    final url = Uri.parse('https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sourceLanguage&tl=$targetLanguage&dt=t&q=${Uri.encodeComponent(text)}');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data[0] != null) {
          String translatedText = '';
          for (var sentence in data[0]) {
            if (sentence[0] != null) {
              translatedText += sentence[0];
            }
          }
          
          setState(() {
            _translatedText = translatedText;
          });
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        throw Exception("API request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Fallback translation failed: ${e.toString()}");
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    
    try {
      // Set the language based on the target language
      final languageCode = _ttsLanguageCodes[_selectedTargetLanguage] ?? 'en-US';
      await flutterTts.setLanguage(languageCode);
      
      // Try to set a natural, human-like voice based on language
      try {
        List<dynamic>? voices = await flutterTts.getVoices;
        if (voices != null) {
          // Find a high-quality voice for the language
          var highQualityVoices = voices.where((voice) {
            try {
              Map<String, dynamic> voiceMap = voice as Map<String, dynamic>;
              String voiceName = voiceMap['name'] ?? '';
              String voiceLocale = voiceMap['locale'] ?? '';
              
              bool matchesLanguage = voiceLocale.toLowerCase().contains(languageCode.split('-')[0].toLowerCase());
              
              // Look for voices marked as female, enhanced quality or neural
              bool isHighQuality = voiceName.toLowerCase().contains('female') || 
                            voiceName.toLowerCase().contains('neural') ||
                            voiceName.toLowerCase().contains('enhanced') ||
                            voiceName.toLowerCase().contains('natural') ||
                            voiceName.toLowerCase().contains('wavenet');
              
              return matchesLanguage && isHighQuality;
            } catch (e) {
              return false;
            }
          }).toList();
          
          // If found a high-quality voice, use it
          if (highQualityVoices.isNotEmpty) {
            Map<String, dynamic> selectedVoice = highQualityVoices.first;
            String voiceName = selectedVoice['name'];
            await flutterTts.setVoice({"name": voiceName, "locale": languageCode});
            print("Using human-like voice: $voiceName");
          }
        }
      } catch (e) {
        print("Error setting voice: $e");
      }
      
      // Human-like speech settings by language
      switch (_selectedTargetLanguage) {
        case 'Chinese':
        case 'Taiwanese':
          await flutterTts.setSpeechRate(0.38);  // Slower for more natural Chinese
          await flutterTts.setPitch(1.03);       // Slightly higher pitch
          await flutterTts.setVolume(0.9);       // Slightly softer for natural sound
          break;
        case 'Japanese':
          await flutterTts.setSpeechRate(0.40);  // Moderate pace for Japanese
          await flutterTts.setPitch(1.08);       // Higher pitch common in Japanese
          await flutterTts.setVolume(0.95);      // Medium volume
          break;
        case 'Korean':
          await flutterTts.setSpeechRate(0.42);  // Slightly faster for Korean
          await flutterTts.setPitch(1.06);       // Moderate pitch increase
          await flutterTts.setVolume(0.92);      // Medium volume
          break;
        case 'Filipino':
          await flutterTts.setSpeechRate(0.45);  // Slightly faster for Filipino
          await flutterTts.setPitch(1.04);       // Moderate pitch
          await flutterTts.setVolume(0.93);      // Medium volume
          break;
        case 'English':
          await flutterTts.setSpeechRate(0.42);  // Conversation pace
          await flutterTts.setPitch(1.0);        // Natural pitch
          await flutterTts.setVolume(0.90);      // Medium volume
          break;
        default:
          await flutterTts.setSpeechRate(0.43);  // Default human conversation pace
          await flutterTts.setPitch(1.02);       // Slight pitch variation
          await flutterTts.setVolume(0.92);      // Medium volume
      }
      
      // Process text to add natural speech patterns
      String processedText = text;
      
      // Add pauses after punctuation for natural breathing
      processedText = processedText.replaceAll('. ', '. <silence ms="350"/>');
      processedText = processedText.replaceAll('? ', '? <silence ms="400"/>');
      processedText = processedText.replaceAll('! ', '! <silence ms="350"/>');
      processedText = processedText.replaceAll(', ', ', <silence ms="150"/>');
      
      // Add human-like voice quality
      await flutterTts.setQueueMode(1);  // Add to queue instead of cutting off
      
      // Speak with enhanced quality
      await flutterTts.speak(processedText);
      
    } catch (e) {
      print('TTS Error: $e');
      // Fallback to default language if the selected one isn't available
      await flutterTts.setLanguage('en-US');
      await flutterTts.setSpeechRate(0.45);
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(text);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Human-like voice for $_selectedTargetLanguage not available. Using standard voice instead.')),
      );
    }
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
    // TODO: Implement actual voice recognition
    if (_isListening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listening...')),
      );
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isListening = false;
        });
      });
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Widget _buildMicButton() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isListening ? 36 : 32,
      height: _isListening ? 36 : 32,
      decoration: BoxDecoration(
        color: _isListening 
            ? (isDarkMode ? const Color(0xFFFFB74D) : Theme.of(context).colorScheme.tertiary)
            : (isDarkMode ? const Color(0xFF4080FF) : Theme.of(context).colorScheme.primary),
        shape: BoxShape.circle,
        boxShadow: _isListening 
            ? [
                BoxShadow(
                  color: (isDarkMode ? const Color(0xFFFFB74D) : Theme.of(context).colorScheme.tertiary)
                      .withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ] 
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleListening,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: _isListening ? 18 : 16,
                key: ValueKey<bool>(_isListening),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ElevatedButton _buildTranslateButton() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final theme = Theme.of(context);
    
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _translate,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? SizedBox(
                key: const ValueKey('loading'),
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white70 : Colors.white,
                  ),
                ),
              )
            : const Icon(Icons.translate, size: 16, key: ValueKey('translate')),
      ),
      label: const Text('Translate', style: TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? const Color(0xFF4080FF) : theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        disabledBackgroundColor: isDarkMode 
            ? const Color(0xFF4080FF).withOpacity(0.3) 
            : Colors.blue.withOpacity(0.3),
      ),
    );
  }

  Widget _buildTranslatedResult() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    if (_translatedText.isEmpty) {
      return const SizedBox();
    }
    
    return Card(
      elevation: isDarkMode ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Translation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? const Color(0xFF4080FF) : Colors.blue,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.copy, 
                        color: isDarkMode ? const Color(0xFF4080FF) : Colors.blue, 
                        size: 20,
                      ),
                      onPressed: () => _copyToClipboard(_translatedText),
                      tooltip: 'Copy to clipboard',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up, 
                        color: isDarkMode ? const Color(0xFF4080FF) : Colors.blue, 
                        size: 20,
                      ),
                      onPressed: () => _speak(_translatedText),
                      tooltip: 'Listen',
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1, 
            color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey.shade200,
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey.shade200,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _translatedText,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    if (_errorMessage.isEmpty) {
      return const SizedBox();
    }
    
    return Card(
      elevation: isDarkMode ? 1 : 3,
      color: isDarkMode ? const Color(0xFF3A2027) : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline, 
              color: isDarkMode ? const Color(0xFFCF6679) : Colors.red.shade700, 
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFFCF6679) : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final theme = Theme.of(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Voice Translator',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.blue,
          ),
        ),
        elevation: isDarkMode ? 0 : 2,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: DarkModeToggle(showLabel: false, isMini: true),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Language Selection
                  Card(
                    elevation: isDarkMode ? 1 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSourceLanguage,
                              decoration: InputDecoration(
                                labelText: 'From',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.blue,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.blue,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDarkMode 
                                        ? const Color(0xFF3D3D3D) 
                                        : Colors.blue.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? const Color(0xFF4080FF) : Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              ),
                              items: _languages.map((String language) {
                                return DropdownMenuItem<String>(
                                  value: language,
                                  child: Text(
                                    language, 
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedSourceLanguage = newValue;
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.arrow_drop_down, 
                                color: isDarkMode ? const Color(0xFF4080FF) : Colors.blue, 
                                size: 20,
                              ),
                              dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              isDense: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFFFFB74D) : const Color(0xFFFFB300),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                              onPressed: () {
                                setState(() {
                                  final temp = _selectedSourceLanguage;
                                  _selectedSourceLanguage = _selectedTargetLanguage;
                                  _selectedTargetLanguage = temp;
                                });
                              },
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedTargetLanguage,
                              decoration: InputDecoration(
                                labelText: 'To',
                                labelStyle: TextStyle(
                                  color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.blue,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.blue,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDarkMode 
                                        ? const Color(0xFF3D3D3D) 
                                        : Colors.blue.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? const Color(0xFF4080FF) : Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              ),
                              items: _languages.map((String language) {
                                return DropdownMenuItem<String>(
                                  value: language,
                                  child: Text(
                                    language, 
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedTargetLanguage = newValue;
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.arrow_drop_down, 
                                color: isDarkMode ? const Color(0xFF4080FF) : Colors.blue, 
                                size: 20,
                              ),
                              dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Input Area
                  Card(
                    elevation: isDarkMode ? 1 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Enter Text',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? const Color(0xFFE0E0E0) : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 80,
                            child: TextField(
                              controller: _textController,
                              decoration: InputDecoration(
                                hintText: 'Type or speak text to translate...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode ? const Color(0xFF909090) : Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? const Color(0xFF4080FF) : Colors.blue,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                                contentPadding: const EdgeInsets.all(8),
                                isDense: true,
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
                              ),
                              maxLines: 4,
                              minLines: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTranslateButton(),
                              ),
                              const SizedBox(width: 10),
                              _buildMicButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildErrorMessage(),
                  
                  if (_errorMessage.isNotEmpty) 
                    const SizedBox(height: 12),
                  
                  _buildTranslatedResult(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}