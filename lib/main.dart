import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const QuoteApp());
}

class QuoteApp extends StatelessWidget {
  const QuoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Quotes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class Quote {
  final String text;
  final String author;
  final bool isFavorite;

  Quote({
    required this.text,
    required this.author,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'author': author,
    'isFavorite': isFavorite,
  };

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    text: json['text'],
    author: json['author'],
    isFavorite: json['isFavorite'] ?? false,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Quote currentQuote;
  List<Quote> favoriteQuotes = [];

  @override
  void initState() {
    super.initState();
    _loadQuoteOfTheDay();
    _loadFavorites();
  }

  Future<void> _loadQuoteOfTheDay() async {
    // For demo purposes, using a static quote. In a real app, you'd fetch from an API
    final quote = Quote(
        text: "Be the change you wish to see in the world",
        author: "Mahatma Gandhi"
    );

    setState(() {
      currentQuote = quote;
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList('favorites') ?? [];

    setState(() {
      favoriteQuotes = favoritesJson
          .map((json) => Quote.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (favoriteQuotes.any((q) => q.text == currentQuote.text)) {
        favoriteQuotes.removeWhere((q) => q.text == currentQuote.text);
      } else {
        favoriteQuotes.add(Quote(
          text: currentQuote.text,
          author: currentQuote.author,
          isFavorite: true,
        ));
      }
    });

    await prefs.setStringList(
      'favorites',
      favoriteQuotes.map((q) => jsonEncode(q.toJson())).toList(),
    );
  }

  void _shareQuote() {
    Share.share('"${currentQuote.text}" - ${currentQuote.author}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(favorites: favoriteQuotes),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        currentQuote.text,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '- ${currentQuote.author}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      favoriteQuotes.any((q) => q.text == currentQuote.text)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareQuote,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadQuoteOfTheDay,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Quote> favorites;

  const FavoritesScreen({super.key, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Quotes'),
      ),
      body: ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final quote = favorites[index];
          return ListTile(
            title: Text(quote.text),
            subtitle: Text(quote.author),
            trailing: const Icon(Icons.favorite, color: Colors.red),
          );
        },
      ),
    );
  }
}
