import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const DzJobApp());
}

// ==========================================
// 1. MODÈLES DE DONNÉES & MÉTIERS (TRILINGUE)
// ==========================================

class JobCategory {
  final String id;
  final Map<String, String> titles;
  final List<String> searchKeywords; // Mots-clés envoyés aux sites algériens

  JobCategory({
    required this.id,
    required this.titles,
    required this.searchKeywords,
  });
}

class JobOffer {
  final String title;
  final String company;
  final String location;
  final String source;
  final String url;
  final String date;

  JobOffer({
    required this.title,
    required this.company,
    required this.location,
    required this.source,
    required this.url,
    required this.date,
  });
}

// Liste de métiers adaptée au marché algérien
final List<JobCategory> jobCategories = [
  JobCategory(
    id: 'piping_mech',
    titles: {
      'fr': 'Ingénieur Tuyauterie / Mécanique / Chaudronnerie',
      'en': 'Piping / Mechanical / Boiler Engineer',
      'ar': 'مهندس أنابيب / ميكانيك / صناعة الغلايات'
    },
    searchKeywords: ['tuyauterie', 'piping', 'mécanique', 'chaudronnerie'],
  ),
  JobCategory(
    id: 'process_indus',
    titles: {
      'fr': 'Ingénieur Procédés / Industriel',
      'en': 'Process / Industrial Engineer',
      'ar': 'مهندس طرائق / صناعي'
    },
    searchKeywords: ['procédés', 'process', 'industriel', 'maintenance'],
  ),
  JobCategory(
    id: 'cad_draftsman',
    titles: {
      'fr': 'Dessinateur Projeteur (SolidWorks / AutoCAD)',
      'en': 'CAD Draftsman (SolidWorks / AutoCAD)',
      'ar': 'مصمم مشاريع (SolidWorks / AutoCAD)'
    },
    searchKeywords: ['projeteur', 'dessinateur', 'solidworks', 'autocad'],
  ),
  JobCategory(
    id: 'it_dev',
    titles: {
      'fr': 'Développeur Informatique / Mobile / Web',
      'en': 'Software / Mobile / Web Developer',
      'ar': 'مطور برمجيات / تطبيقات / ويب'
    },
    searchKeywords: ['développeur', 'informatique', 'developer', 'mobile'],
  ),
  JobCategory(
    id: 'hse',
    titles: {
      'fr': 'Ingénieur / Superviseur HSE',
      'en': 'HSE Engineer / Supervisor',
      'ar': 'مهندس / مشرف أمن صناعي HSE'
    },
    searchKeywords: ['hse', 'sécurité', 'environnement'],
  ),
  JobCategory(
    id: 'finance',
    titles: {
      'fr': 'Comptable / Financier',
      'en': 'Accountant / Finance Officer',
      'ar': 'محاسب / مالي'
    },
    searchKeywords: ['comptable', 'finance', 'comptabilité'],
  ),
  JobCategory(
    id: 'sales',
    titles: {
      'fr': 'Commercial / Technico-Commercial',
      'en': 'Sales Representative / Technical Sales',
      'ar': 'مندوب تجاري / تقني تجاري'
    },
    searchKeywords: ['commercial', 'vente', 'technico-commercial'],
  ),
];

// ==========================================
// 2. DICTIONNAIRE D'INTERFACE (FR / EN / AR)
// ==========================================

const Map<String, Map<String, String>> appStrings = {
  'fr': {
    'app_title': 'Algérie Emploi Agrégateur',
    'select_job': 'Sélectionnez un métier',
    'select_wilaya': 'Wilaya (Optionnel)',
    'all_wilayas': 'Toutes les wilayas',
    'search_btn': 'Lancer la recherche',
    'sources': 'Sites interrogés : Emploitic, EmploiPartner, Ouedkniss...',
    'no_results': 'Aucune offre directe trouvée, utilisez l\'accès rapide aux portails ci-dessous.',
    'open_offer': 'Voir l\'offre',
    'direct_portals': 'Accès direct aux résultats filtrés :',
  },
  'en': {
    'app_title': 'Algeria Job Aggregator',
    'select_job': 'Select a profession',
    'select_wilaya': 'Province / Wilaya (Optional)',
    'all_wilayas': 'All Wilayas',
    'search_btn': 'Search Jobs',
    'sources': 'Active sources: Emploitic, EmploiPartner, Ouedkniss...',
    'no_results': 'No direct items parsed, use the quick portal buttons below.',
    'open_offer': 'View Offer',
    'direct_portals': 'Direct access to filtered portals:',
  },
  'ar': {
    'app_title': 'باحث الوظائف في الجزائر',
    'select_job': 'اختر المهنة أو التخصص',
    'select_wilaya': 'الولاية (اختياري)',
    'all_wilayas': 'كل الولايات',
    'search_btn': 'بحث عن الوظائف',
    'sources': 'المواقع: Emploitic, EmploiPartner, Ouedkniss...',
    'no_results': 'استخدم الروابط المباشرة بالأسفل لتصفح العروض مباشرة.',
    'open_offer': 'عرض التفاصيل',
    'direct_portals': 'وصول مباشر لنتائج البحث في المواقع:',
  }
};

final List<String> wilayas = [
  'Toutes / الكل / All',
  '16 - Alger',
  '06 - Béjaïa',
  '31 - Oran',
  '19 - Sétif',
  '25 - Constantine',
  '30 - Ouargla (Hassi Messaoud)',
  '35 - Boumerdès',
  '09 - Blida',
  '23 - Annaba',
];

// ==========================================
// 3. SERVICE DE RECHERCHE & SCRAPING
// ==========================================

class JobScraperService {
  static const Map<String, String> headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept-Language': 'fr-FR,fr;q=0.9,ar;q=0.8,en;q=0.7',
  };

  /// Génère les URLs de recherche directe sur les sites algériens
  static Map<String, String> buildPortalUrls(String keyword, String wilaya) {
    final String cleanQuery = Uri.encodeComponent(keyword);
    return {
      'Emploitic': 'https://emploitic.com/offres-d-emploi?q=$cleanQuery',
      'Ouedkniss': 'https://www.ouedkniss.com/emploi_offres-r?keywords=$cleanQuery',
      'EmploiPartner': 'https://www.emploipartner.com/fr/offres-d-emploi?q=$cleanQuery',
      'OptionCarriere DZ': 'https://www.optioncarriere.dz/emploi?s=$cleanQuery&l=Alg%C3%A9rie',
    };
  }

  /// Récupère et parse les offres depuis les moteurs d'emploi algériens
  static Future<List<JobOffer>> searchAllSites(
      JobCategory category, String wilaya) async {
    List<JobOffer> results = [];
    final String mainKeyword = category.searchKeywords.first;
    final String encodedKeyword = Uri.encodeComponent(mainKeyword);

    // 1. Extraction depuis OptionCarriere Algérie (Agrège Emploitic, EmploiPartner, etc.)
    try {
      final url = Uri.parse(
          'https://www.optioncarriere.dz/emploi?s=$encodedKeyword&l=Alg%C3%A9rie');
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var articles = document.querySelectorAll('article.job');

        for (var article in articles) {
          final titleEl = article.querySelector('h2 a');
          final companyEl = article.querySelector('p.company');
          final locationEl = article.querySelector('ul.location li');
          final dateEl = article.querySelector('footer time');

          if (titleEl != null) {
            String link = titleEl.attributes['href'] ?? '';
            if (link.startsWith('/')) {
              link = 'https://www.optioncarriere.dz$link';
            }
            results.add(JobOffer(
              title: titleEl.text.trim(),
              company: companyEl?.text.trim() ?? 'Entreprise Algérie',
              location: locationEl?.text.trim() ?? 'Algérie',
              source: 'Portail Algérie (Agrégé)',
              url: link,
              date: dateEl?.text.trim() ?? 'Récent',
            ));
          }
        }
      }
    } catch (_) {
      // Ignorer silencieusement si le réseau ou Cloudflare bloque et passer au suivant
    }

    // 2. Extraction directe depuis Emploitic
    try {
      final empUrl =
          Uri.parse('https://emploitic.com/offres-d-emploi?q=$encodedKeyword');
      final response = await http
          .get(empUrl, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var items = document.querySelectorAll('a[href*="/offres-d-emploi/"]');

        for (var item in items.take(8)) {
          final text = item.text.trim();
          final href = item.attributes['href'] ?? '';
          if (text.length > 10 && href.isNotEmpty) {
            results.add(JobOffer(
              title: text.split('\n').first.trim(),
              company: 'Via Emploitic',
              location: wilaya.startsWith('Toutes') ? 'Algérie' : wilaya,
              source: 'Emploitic',
              url: href.startsWith('http') ? href : 'https://emploitic.com$href',
              date: 'Disponible',
            ));
          }
        }
      }
    } catch (_) {}

    return results;
  }
}

// ==========================================
// 4. APPLICATION PRINCIPALE & INTERFACE (UI)
// ==========================================

class DzJobApp extends StatefulWidget {
  const DzJobApp({super.key});

  @override
  State<DzJobApp> createState() => _DzJobAppState();
}

class _DzJobAppState extends State<DzJobApp> {
  String _currentLang = 'fr';

  void _changeLanguage(String langCode) {
    setState(() {
      _currentLang = langCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DZ Job Finder',
      locale: Locale(_currentLang),
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      home: JobHomeScreen(
        currentLang: _currentLang,
        onLangChanged: _changeLanguage,
      ),
    );
  }
}

class JobHomeScreen extends StatefulWidget {
  final String currentLang;
  final Function(String) onLangChanged;

  const JobHomeScreen({
    super.key,
    required this.currentLang,
    required this.onLangChanged,
  });

  @override
  State<JobHomeScreen> createState() => _JobHomeScreenState();
}

class _JobHomeScreenState extends State<JobHomeScreen> {
  late JobCategory _selectedCategory;
  String _selectedWilaya = wilayas.first;
  List<JobOffer> _offers = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = jobCategories.first;
  }

  String t(String key) => appStrings[widget.currentLang]?[key] ?? key;

  Future<void> _runSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final results = await JobScraperService.searchAllSites(
      _selectedCategory,
      _selectedWilaya,
    );

    setState(() {
      _offers = results;
      _isLoading = false;
    });
  }

  Future<void> _openUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir : $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final portalLinks = JobScraperService.buildPortalUrls(
      _selectedCategory.searchKeywords.first,
      _selectedWilaya,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Text(t('app_title'), style: const TextStyle(fontSize: 18)),
        actions: [
          // Sélecteur de langue FR / AR / EN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF0D47A1),
                value: widget.currentLang,
                icon: const Icon(Icons.language, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: 'fr',
                      child: Text('🇫🇷 FR',
                          style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(
                      value: 'ar',
                      child: Text('🇩🇿 AR',
                          style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(
                      value: 'en',
                      child: Text('🇬🇧 EN',
                          style: TextStyle(color: Colors.white))),
                ],
                onChanged: (val) {
                  if (val != null) widget.onLangChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sélection du métier
            Text(t('select_job'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<JobCategory>(
              value: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: jobCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(
                    cat.titles[widget.currentLang] ?? cat.titles['fr']!,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 12),

            // Sélection de la Wilaya
            Text(t('select_wilaya'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedWilaya,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: wilayas.map((w) {
                return DropdownMenuItem(value: w, child: Text(w));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedWilaya = val);
              },
            ),
            const SizedBox(height: 14),

            // Bouton Rechercher
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isLoading ? null : _runSearch,
              icon: const Icon(Icons.search),
              label: Text(t('search_btn'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            // Boutons d'accès direct aux portails (contourne 100% des blocages Cloudflare)
            Text(t('direct_portals'),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: portalLinks.entries.map((entry) {
                return ActionChip(
                  avatar: const Icon(Icons.open_in_new, size: 16),
                  label: Text(entry.key),
                  onPressed: () => _openUrl(entry.value),
                );
              }).toList(),
            ),
            const Divider(height: 24),

            // Liste des résultats extraits
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasSearched
                      ? Center(
                          child: Text(
                            t('sources'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : _offers.isEmpty
                          ? Center(
                              child: Text(
                                t('no_results'),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _offers.length,
                              itemBuilder: (context, index) {
                                final offer = _offers[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    title: Text(
                                      offer.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                        '${offer.company} • ${offer.location}\nSource : ${offer.source} (${offer.date})'),
                                    isThreeLine: true,
                                    trailing: ElevatedButton(
                                      onPressed: () => _openUrl(offer.url),
                                      child: Text(t('open_offer')),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
