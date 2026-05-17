import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuraAssistBubble extends StatefulWidget {
  final Map<String, dynamic>? initialContext;
  const AuraAssistBubble({super.key, this.initialContext});

  @override
  State<AuraAssistBubble> createState() => _AuraAssistBubbleState();
}

class _AuraAssistBubbleState extends State<AuraAssistBubble> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  // Draggable physics states
  double _xPosition = 24.0;
  double _yPosition = 120.0;
  
  bool _isExpanded = false;
  bool _voiceEnabled = false;
  String _currentLanguage = "English";
  String _currentTip = "Tap 'Analyze' to scan your active workflow layout.";
  bool _isAnalyzing = false;

  final Map<String, Map<String, String>> _localizedTips = {
    "English": {
      "idle": "Tap 'Analyze' to scan your active workflow layout.",
      "analyzing": "Analyzing layout contexts dynamically...",
      "tip": "Step 1: Enter your IFSC Code. Most users forget this field."
    },
    "Tamil": {
      "idle": "பகுப்பாய்வு செய்ய 'Analyze' பொத்தானைத் தட்டவும்.",
      "analyzing": "பக்க அமைப்பை பகுப்பாய்வு செய்கிறது...",
      "tip": "படி 1: உங்கள் ஐ.எஃப்.எஸ்.சி குறியீட்டை உள்ளிடவும். பலர் இதை மறந்து விடுகிறார்கள்."
    },
    "Hindi": {
      "idle": "लेआउट स्कैन करने के लिए 'Analyze' पर टैप करें।",
      "analyzing": "लेआउट का विश्लेषण किया जा रहा है...",
      "tip": "चरण 1: अपना IFSC कोड दर्ज करें। अधिकांश उपयोगकर्ता इसे भूल जाते हैं।"
    },
    "Telugu": {
      "idle": "లేఅవుట్‌ను స్కాన్ చేయడానికి 'Analyze' పై నొక్కండి.",
      "analyzing": "లేఅవుట్ విశ్लेषण చేయబడుతోంది...",
      "tip": "దశ 1: మీ IFSC కోడ్‌ను నమోదు చేయండి. చాలా మంది దీనిని మరచిపోతారు."
    },
    "Kannada": {
      "idle": "ಲೇಔಟ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಲು 'Analyze' ಟ್ಯಾಪ್ ಮಾಡಿ.",
      "analyzing": "ಪುಟದ ವಿನ್ಯಾಸ ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ...",
      "tip": "ಹಂತ 1: ನಿಮ್ಮ IFSC ಕೋಡ್ ನಮೂದಿಸಿ. ಹೆಚ್ಚಿನ ಬಳಕೆದಾರರು ಇದನ್ನು ಮರೆಯುತ್ತಾರೆ."
    }
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAnalysis() {
    setState(() {
      _isAnalyzing = true;
      _currentTip = _localizedTips[_currentLanguage]!["analyzing"]!;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _currentTip = _localizedTips[_currentLanguage]!["tip"]!;
        });
      }
    });
  }

  void _changeLanguage(String lang) {
    setState(() {
      _currentLanguage = lang;
      _currentTip = _localizedTips[lang]!["idle"]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return Positioned(
      left: _xPosition,
      top: _yPosition,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPosition += details.delta.dx;
            _yPosition += details.delta.dy;
            
            // Constrain bubble within visible screen boundaries
            _xPosition = _xPosition.clamp(16.0, screenWidth - (_isExpanded ? 320.0 : 80.0));
            _yPosition = _yPosition.clamp(40.0, screenHeight - (_isExpanded ? 260.0 : 100.0));
          });
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: _isExpanded ? 300 : 64,
              height: _isExpanded ? 200 : 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1527).withOpacity(0.85),
                borderRadius: BorderRadius.circular(_isExpanded ? 24 : 32),
                border: Border.all(
                  color: _isAnalyzing
                      ? const Color(0xFFE11D48).withOpacity(0.5) // Glowing crimson
                      : const Color(0xFF06B6D4).withOpacity(0.4 + (_pulseController.value * 0.2)), // Pulse cyan
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isAnalyzing ? const Color(0xFFE11D48) : const Color(0xFF06B6D4))
                        .withOpacity(0.12 + (_pulseController.value * 0.08)),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_isExpanded ? 24 : 32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: _isExpanded ? _buildExpandedPanel() : _buildCompactBubble(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactBubble() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glowing neural core ring
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Solid center nucleus
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF06B6D4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isAnalyzing ? const Color(0xFFE11D48) : const Color(0xFF06B6D4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "AURA ASSIST",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF06B6D4),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _isExpanded = false),
              )
            ],
          ),
          const SizedBox(height: 12),
          
          // Actionable instruction text
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _currentTip,
                key: ValueKey<String>(_currentTip),
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          // Row of controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left control actions
              Row(
                children: [
                  _buildToolButton(
                    icon: _isAnalyzing ? Icons.hourglass_empty_rounded : Icons.psychology_outlined,
                    label: _isAnalyzing ? "Scanning..." : "Analyze",
                    onTap: _isAnalyzing ? () {} : _triggerAnalysis,
                  ),
                  const SizedBox(width: 8),
                  _buildLanguageSelector(),
                ],
              ),
              
              // Right interactive action (Voice prompt toggler)
              GestureDetector(
                onTap: () {
                  setState(() => _voiceEnabled = !_voiceEnabled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_voiceEnabled ? "Voice guidance activated." : "Voice guidance silenced."),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF0D1527),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _voiceEnabled ? const Color(0xFF06B6D4).withOpacity(0.15) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _voiceEnabled ? const Color(0xFF06B6D4).withOpacity(0.4) : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    _voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    size: 14,
                    color: _voiceEnabled ? const Color(0xFF06B6D4) : Colors.white60,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildToolButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF06B6D4)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white80,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return PopupMenuButton<String>(
      onSelected: _changeLanguage,
      color: const Color(0xFF0D1527),
      offset: const Offset(0, -180),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate_rounded, size: 13, color: Color(0xFF06B6D4)),
            const SizedBox(width: 6),
            Text(
              _currentLanguage,
              style: GoogleFonts.outfit(
                color: Colors.white80,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_drop_up_rounded, size: 12, color: Colors.white54),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupItem("English"),
        _buildPopupItem("Tamil"),
        _buildPopupItem("Hindi"),
        _buildPopupItem("Telugu"),
        _buildPopupItem("Kannada"),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String lang) {
    return PopupMenuItem<String>(
      value: lang,
      height: 32,
      child: Text(
        lang,
        style: GoogleFonts.outfit(
          color: _currentLanguage == lang ? const Color(0xFF06B6D4) : Colors.white90,
          fontSize: 12,
        ),
      ),
    );
  }
}
