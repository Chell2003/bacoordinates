import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bacoordinates/providers/theme_provider.dart';
import 'package:bacoordinates/components/DarkModeToggle.dart';

/// StyleGuide is a development tool to showcase the app's design system
/// This component is not meant to be used in production
class StyleGuide extends StatelessWidget {
  const StyleGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Style Guide',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.blue,
          ),
        ),
        actions: const [DarkModeToggle(isMini: true)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('BacoTrip Style Guide', isHeader: true),
            const SizedBox(height: 24),
            
            _buildSection('Colors'),
            _buildColorPalette(context),
            const SizedBox(height: 24),
            
            _buildSection('Typography'),
            _buildTypography(context),
            const SizedBox(height: 24),
            
            _buildSection('Components'),
            _buildComponents(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isHeader ? 24 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildColorPalette(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    
    final darkModeColors = {
      'Primary': const Color(0xFF4080FF),
      'Background': const Color(0xFF121212),
      'Surface': const Color(0xFF1E1E1E),
      'Card': const Color(0xFF1E1E1E),
      'Input': const Color(0xFF2A2A2A),
      'Border': const Color(0xFF3D3D3D),
      'Text (High Emphasis)': const Color(0xFFE0E0E0),
      'Text (Medium Emphasis)': const Color(0xFFB0B0B0),
      'Text (Low Emphasis)': const Color(0xFF909090),
      'Accent': const Color(0xFFFFB74D),
      'Error': const Color(0xFFCF6679),
    };
    
    final lightModeColors = {
      'Primary': Colors.blue,
      'Background': Colors.white,
      'Surface': Colors.white,
      'Card': Colors.white,
      'Input': Colors.grey.shade50,
      'Border': Colors.grey.shade300,
      'Text (High Emphasis)': Colors.black87,
      'Text (Medium Emphasis)': Colors.grey.shade700,
      'Text (Low Emphasis)': Colors.grey.shade600,
      'Accent': const Color(0xFFFFB300),
      'Error': Colors.red.shade700,
    };
    
    final colors = isDarkMode ? darkModeColors : lightModeColors;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.entries.map((entry) {
        return _buildColorSwatch(entry.key, entry.value);
      }).toList(),
    );
  }
  
  Widget _buildColorSwatch(String name, Color color) {
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '#${color.value.toRadixString(16).toUpperCase().substring(2)}',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 100,
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTypography(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Headline Large', style: theme.textTheme.headlineLarge),
        Text('Headline Medium', style: theme.textTheme.headlineMedium),
        Text('Headline Small', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Title Large', style: theme.textTheme.titleLarge),
        Text('Title Medium', style: theme.textTheme.titleMedium),
        Text('Title Small', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Body Large', style: theme.textTheme.bodyLarge),
        Text('Body Medium', style: theme.textTheme.bodyMedium),
        Text('Body Small', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text('Label Large', style: theme.textTheme.labelLarge),
        Text('Label Medium', style: theme.textTheme.labelMedium),
        Text('Label Small', style: theme.textTheme.labelSmall),
      ],
    );
  }
  
  Widget _buildComponents(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildComponentSection('Buttons'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Elevated'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Text'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        _buildComponentSection('Inputs'),
        SizedBox(
          width: double.infinity,
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Text Field',
              hintText: 'Enter some text',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        _buildComponentSection('Cards'),
        Card(
          elevation: isDarkMode ? 1 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Card Component'),
          ),
        ),
        const SizedBox(height: 16),
        
        _buildComponentSection('Custom Components'),
        const DarkModeToggle(),
      ],
    );
  }
  
  Widget _buildComponentSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 