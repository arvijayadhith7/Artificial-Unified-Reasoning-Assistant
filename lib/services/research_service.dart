import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ResearchState {
  final String status;
  final List<String> sources;
  final String synthesis;
  final List<dynamic> correlations;
  final bool isResearching;

  ResearchState({
    this.status = '',
    this.sources = const [],
    this.synthesis = '',
    this.correlations = const [],
    this.isResearching = false,
  });

  ResearchState copyWith({
    String? status,
    List<String>? sources,
    String? synthesis,
    List<dynamic>? correlations,
    bool? isResearching,
  }) {
    return ResearchState(
      status: status ?? this.status,
      sources: sources ?? this.sources,
      synthesis: synthesis ?? this.synthesis,
      correlations: correlations ?? this.correlations,
      isResearching: isResearching ?? this.isResearching,
    );
  }
}

class ResearchNotifier extends StateNotifier<ResearchState> {
  ResearchNotifier() : super(ResearchState());

  WebSocketChannel? _channel;

  void startResearch(String prompt, String category) {
    state = ResearchState(isResearching: true, status: 'Connecting to AURA Research Core...');
    
    // Production URL (Hugging Face Space)
    const baseUrl = 'wss://vijayadhith7-aura-backend.hf.space/research';
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(baseUrl));
      
      _channel!.sink.add(jsonEncode({
        'prompt': prompt,
        'category': category,
        'history': [],
      }));

      _channel!.stream.listen((data) {
        final Map<String, dynamic> msg = jsonDecode(data);
        
        if (msg.containsKey('done')) {
          state = state.copyWith(isResearching: false, status: 'Research Complete.');
          _channel?.sink.close();
          return;
        }

        final type = msg['type'];
        final content = msg['content'];

        switch (type) {
          case 'status':
            state = state.copyWith(status: content);
            break;
          case 'sources':
            state = state.copyWith(sources: List<String>.from(content));
            break;
          case 'synthesis':
            String formattedContent = "";
            if (content is Map) {
              formattedContent = "# ${content['title'] ?? 'Research Analysis'}\n\n";
              formattedContent += "## Summary\n${content['summary'] ?? ''}\n\n";
              
              if (content['key_findings'] != null) {
                formattedContent += "## Key Findings\n";
                for (var finding in content['key_findings']) {
                  formattedContent += "- $finding\n";
                }
                formattedContent += "\n";
              }

              if (content['technical_analysis'] != null) {
                formattedContent += "## Technical Analysis\n${content['technical_analysis']}\n\n";
              }

              if (content['statistics'] != null) {
                formattedContent += "## Statistics\n";
                for (var stat in content['statistics']) {
                  formattedContent += "- $stat\n";
                }
                formattedContent += "\n";
              }

              if (content['future_scope'] != null) {
                formattedContent += "## Future Scope\n${content['future_scope']}\n\n";
              }
              
              if (content['references'] != null) {
                formattedContent += "## Sources & References\n";
                for (var ref in content['references']) {
                  formattedContent += "- [${ref['title']}](${ref['url']}) (${ref['source']})\n";
                }
              }
            } else {
              formattedContent = content.toString();
            }
            state = state.copyWith(synthesis: state.synthesis + formattedContent);
            break;
          case 'correlation':
            state = state.copyWith(correlations: List<dynamic>.from(content));
            break;
        }
      }, onError: (error) {
        state = state.copyWith(isResearching: false, status: 'Research Disrupted: $error');
      });
    } catch (e) {
      state = state.copyWith(isResearching: false, status: 'Failed to connect: $e');
    }
  }

  void reset() {
    state = ResearchState();
    _channel?.sink.close();
  }
}

final researchProvider = StateNotifierProvider<ResearchNotifier, ResearchState>((ref) {
  return ResearchNotifier();
});
