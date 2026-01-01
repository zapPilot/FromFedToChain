import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../providers/audio_provider.dart';
import '../config/app_config.dart';
import '../widgets/mini_player.dart';

/// Main home screen with language tabs, category filters, and content list
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConfig.supportedLanguages.length,
      vsync: this,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final language = AppConfig.supportedLanguages[_tabController.index];
        context.read<ContentProvider>().setLanguage(language);
      }
    });

    // Load initial content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadContent();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        bottom: TabBar(
          controller: _tabController,
          tabs: AppConfig.supportedLanguages.map((lang) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppConfig.getLanguageFlag(lang)),
                  const SizedBox(width: 8),
                  Text(AppConfig.getLanguageName(lang)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(
            child: _buildContentList(),
          ),
          // Mini player at bottom
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        final categories = [
          AppConfig.allCategoriesKey,
          ...AppConfig.supportedCategories,
        ];

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == provider.selectedCategory;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category != AppConfig.allCategoriesKey)
                      Text('${AppConfig.getCategoryEmoji(category)} '),
                    Text(AppConfig.getCategoryName(category)),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => provider.setCategory(category),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContentList() {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(provider.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadContent(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final content = provider.content;

        if (content.isEmpty) {
          return const Center(
            child: Text('No content available'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: content.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = content[index];
            final audioProvider = context.watch<AudioProvider>();
            final isPlaying = audioProvider.currentContent?.id == item.id;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(AppConfig.getCategoryEmoji(item.category)),
                ),
                title: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${AppConfig.getLanguageFlag(item.language)} ${item.language} · ${item.duration?.inSeconds ?? '--'}s · ${item.date.toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: isPlaying
                    ? const Icon(Icons.volume_up)
                    : const Icon(Icons.play_arrow),
                onTap: () {
                  audioProvider.play(item, playlist: content);
                },
              ),
            );
          },
        );
      },
    );
  }
}
