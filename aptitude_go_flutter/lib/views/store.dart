// ignore_for_file: avoid_build_context_async
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────
//  Store item type helpers
// ─────────────────────────────────────────────
enum _ItemType { life, frame, avatar, unknown }

_ItemType _itemType(String type, String name) {
  final t = type.toUpperCase();
  if (t == 'LIFE') return _ItemType.life;
  if (t == 'FRAME') return _ItemType.frame;
  if (t == 'AVATAR') return _ItemType.avatar;
  return _ItemType.unknown;
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  String? _error;
  int _userCoins = 0;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  Future<void> _fetchStoreData() async {
    setState(() { _isLoading = true; _error = null; });
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('gamification/store/');
      if (mounted) {
        setState(() {
          _items = response.data['items'] ?? [];
          _userCoins = response.data['coins'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = "Failed to load store catalog."; _isLoading = false; });
      }
    }
  }

  Future<void> _purchaseOrEquip(int itemId, bool isPurchased, _ItemType type) async {
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.post('gamification/buy/$itemId/');
      if (!mounted) return;
      if (response.data['success'] == true) {
        final message = response.data['message'] ??
            (isPurchased
                ? (response.data['is_equipped'] == true ? "Item equipped!" : "Item unequipped!")
                : "Item purchased successfully!");

        // ── Apply purchase effects immediately ──
        _applyPurchaseEffect(api, response.data, type);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppTheme.emeraldGreen),
        );

        await api.checkAuthStatus();
        _fetchStoreData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['error'] ?? "Action failed."),
            backgroundColor: AppTheme.livesRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to connect to store gateway."),
            backgroundColor: AppTheme.livesRed,
          ),
        );
      }
    }
  }

  /// Push immediate effects into ApiClient so the whole app reacts instantly.
  void _applyPurchaseEffect(
    ApiClient api,
    Map<String, dynamic> data,
    _ItemType type,
  ) {
    final coins = data['coins'] as int?;
    final lives = data['lives'] as int?;
    final isEquipped = data['is_equipped'] as bool? ?? false;

    final updates = <String, dynamic>{};
    if (coins != null) updates['coins'] = coins;
    if (lives != null) updates['lives'] = lives;

    switch (type) {
      case _ItemType.frame:
        updates['has_golden_frame'] = isEquipped;
        break;
      case _ItemType.avatar:
        updates['has_pro_avatar'] = isEquipped;
        break;
      default:
        break;
    }

    if (updates.isNotEmpty) {
      api.updateCurrentUser(updates);
    }
  }

  // ─────────────────────────────────────────────
  //  Rich item artwork
  // ─────────────────────────────────────────────

  Widget _buildPreview(_ItemType type, String name, bool isPurchased, bool isEquipped) {
    switch (type) {
      case _ItemType.life:
        return _LifeRefillPreview();
      case _ItemType.frame:
        return _GoldenFramePreview(equipped: isEquipped);
      case _ItemType.avatar:
        return _ProAvatarPreview(equipped: isEquipped);
      default:
        return _GenericPreview();
    }
  }

  Widget _buildStoreCard(dynamic item) {
    final id = item['id'] as int;
    final name = item['name'] as String;
    final cost = item['cost'] as int;
    final isPurchased = item['is_purchased'] as bool? ?? false;
    final isEquipped = item['is_equipped'] as bool? ?? false;
    final description = item['description'] as String? ?? '';
    final rawType = item['item_type'] as String? ?? '';
    final type = _itemType(rawType, name);

    final borderColor = _borderColorFor(type, isEquipped, isPurchased);
    final glowColor = isEquipped ? borderColor : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isEquipped ? 1.8 : 1),
        boxShadow: isEquipped
            ? [BoxShadow(color: glowColor.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: 2)]
            : [],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildPreview(type, name, isPurchased, isEquipped),
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            _displayName(name, type),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4),
          ),
          const SizedBox(height: 14),
          // Price / owned badge
          if (!isPurchased || type == _ItemType.life)
            _PriceBadge(cost: cost)
          else
            _OwnedBadge(equipped: isEquipped),
          const SizedBox(height: 10),
          // Action button
          _buildCardActionButton(id, name, cost, isPurchased, isEquipped, type),
        ],
      ),
    );
  }

  Color _borderColorFor(_ItemType type, bool isEquipped, bool isPurchased) {
    if (!isPurchased) return Theme.of(context).dividerColor;
    if (isEquipped) {
      switch (type) {
        case _ItemType.frame:  return const Color(0xFFF59E0B);
        case _ItemType.avatar: return AppTheme.neonPurple;
        default: return AppTheme.emeraldGreen;
      }
    }
    return AppTheme.emeraldGreen.withValues(alpha: 0.4);
  }

  String _displayName(String name, _ItemType type) => name;

  Widget _buildCardActionButton(
    int id, String name, int cost, bool isPurchased, bool isEquipped, _ItemType type,
  ) {
    String label;
    Color bg;
    if (!isPurchased || type == _ItemType.life) {
      label = type == _ItemType.life && isPurchased ? "Refill" : "Purchase";
      bg = const Color(0xFF6366F1); // Indigo
    } else if (isEquipped) {
      label = "Unequip";
      bg = const Color(0xFF334155);
    } else {
      label = "Equip";
      bg = AppTheme.emeraldGreen;
    }

    return ElevatedButton(
      onPressed: () => _purchaseOrEquip(id, isPurchased, type),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiClient>(context);
    final user = api.currentUser!;
    final coins = user['coins'] ?? _userCoins;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Store"),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchStoreData,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPurple),
                        child: const Text("Retry"),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Coins chip ──
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.cardBgColor,
                              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.5), width: 1.5),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  blurRadius: 16, spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on, color: Color(0xFFF59E0B), size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  "$coins Coins",
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // ── Grid ──
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int cols = 4;
                            if (constraints.maxWidth < 900) cols = 2;
                            if (constraints.maxWidth < 500) cols = 1;
                            final itemWidth = (constraints.maxWidth - (cols - 1) * 16) / cols;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: _items.map((item) {
                                return SizedBox(
                                  width: itemWidth,
                                  child: _buildStoreCard(item),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ─────────────────────────────────────────────
//  Price & Owned badges
// ─────────────────────────────────────────────

class _PriceBadge extends StatelessWidget {
  final int cost;
  const _PriceBadge({required this.cost});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.monetization_on, color: Color(0xFFF59E0B), size: 16),
        const SizedBox(width: 4),
        Text(
          "$cost Coins",
          style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _OwnedBadge extends StatelessWidget {
  final bool equipped;
  const _OwnedBadge({required this.equipped});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: equipped
              ? AppTheme.emeraldGreen.withValues(alpha: 0.15)
              : Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          equipped ? "✓ Equipped" : "Owned",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: equipped ? AppTheme.emeraldGreen : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Item Artwork Widgets
// ─────────────────────────────────────────────

/// ♥ Life Refill
class _LifeRefillPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3D0A10), Color(0xFF7F0E1E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow behind hearts
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppTheme.livesRed.withValues(alpha: 0.6), blurRadius: 30, spreadRadius: 10)],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeartIcon(size: 26, opacity: 0.4),
              const SizedBox(width: 4),
              _HeartIcon(size: 34, opacity: 0.7),
              const SizedBox(width: 4),
              _HeartIcon(size: 40, opacity: 1.0),
              const SizedBox(width: 4),
              _HeartIcon(size: 34, opacity: 0.7),
              const SizedBox(width: 4),
              _HeartIcon(size: 26, opacity: 0.4),
            ],
          ),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.livesRed.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text("×5 Lives", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartIcon extends StatelessWidget {
  final double size;
  final double opacity;
  const _HeartIcon({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.favorite_rounded, color: AppTheme.livesRed.withValues(alpha: opacity), size: size);
  }
}

/// 🖼 Golden Frame
class _GoldenFramePreview extends StatelessWidget {
  final bool equipped;
  const _GoldenFramePreview({required this.equipped});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B00), Color(0xFF4A2E00), Color(0xFF2D1B00)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: equipped ? const Color(0xFFFFD700) : const Color(0xFFB8860B),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: equipped ? 0.6 : 0.2),
                blurRadius: 20, spreadRadius: 4,
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E293B),
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFFFFD700), size: 36),
          ),
        ),
      ),
    );
  }
}

/// 👤 Pro Avatar
class _ProAvatarPreview extends StatelessWidget {
  final bool equipped;
  const _ProAvatarPreview({required this.equipped});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0533), Color(0xFF3B0764), Color(0xFF1A0533)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo glow
          if (equipped)
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.neonPurple.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 10)],
              ),
            ),
          // Stars scatter
          ..._buildStars(),
          // Avatar circle
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.8), width: 2.5),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 38),
          ),
          Positioned(
            top: 8, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.neonPurple,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text("PRO", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    final positions = [
      [10.0, 12.0], [90.0, 8.0], [15.0, 90.0], [100.0, 88.0], [55.0, 10.0],
    ];
    return positions.map((pos) {
      return Positioned(
        left: pos[0], top: pos[1],
        child: Icon(Icons.star_rounded, color: AppTheme.neonPurple.withValues(alpha: 0.4), size: 10),
      );
    }).toList();
  }
}



class _GenericPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.redeem_rounded, color: AppTheme.neonPurple, size: 48),
      ),
    );
  }
}
