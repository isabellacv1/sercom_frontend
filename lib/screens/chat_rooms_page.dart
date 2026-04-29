        import 'package:flutter/material.dart';

        import '../models/chat_room.dart';
        import '../services/chat_service.dart';
        import 'chat_page.dart';
        import '../services/chat_socket_service.dart';

        class ChatRoomsPage extends StatefulWidget {
          final String role;

          const ChatRoomsPage({
            super.key,
            this.role = 'all',
          });

          @override
          State<ChatRoomsPage> createState() => _ChatRoomsPageState();
        }

        class _ChatRoomsPageState extends State<ChatRoomsPage> {
          final ChatService _chatService = ChatService();
          final ChatSocketService _chatSocketService = ChatSocketService();
          final TextEditingController _searchController = TextEditingController();

          bool _isLoading = true;
          String? _errorMessage;
          List<ChatRoom> _rooms = [];
          List<ChatRoom> _filteredRooms = [];

          @override
          void initState() {
            super.initState();
            _loadRooms();
            _initSocket();
          }

          @override
          void dispose() {
            for (final room in _rooms) {
              _chatSocketService.leaveRoom(room.id);
            }

            _searchController.dispose();
            super.dispose();
          }

    Future<void> _loadRooms({bool showLoading = true}) async {
      if (showLoading && mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      try {
        final rooms = await _chatService.getMyRooms(role: widget.role);
        await _joinRooms(rooms);

        if (!mounted) return;

        setState(() {
          _rooms = rooms;
          _filteredRooms = _filterRooms(rooms, _searchController.text);
          _isLoading = false;
          _errorMessage = null;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }


    Future<void> _joinRooms(List<ChatRoom> rooms) async {
      await _chatSocketService.connect();

      for (final room in rooms) {
        if (room.id.isNotEmpty) {
          await _chatSocketService.joinRoom(room.id);
        }
      }
    }

          List<ChatRoom> _filterRooms(List<ChatRoom> rooms, String query) {
            final q = query.toLowerCase().trim();
            if (q.isEmpty) return rooms;

            return rooms.where((room) {
              return room.participantName.toLowerCase().contains(q) ||
                  room.title.toLowerCase().contains(q) ||
                  room.lastMessagePreview.toLowerCase().contains(q);
            }).toList();
          }

          void _onSearchChanged(String value) {
            setState(() {
              _filteredRooms = _filterRooms(_rooms, value);
            });
          }

         Future<void> _openRoom(ChatRoom room) async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatPage(room: room)),
            );

            if (mounted) {
              await _loadRooms(showLoading: false);
              await _initSocket();
            }
          }

        Future<void> _initSocket() async {
          try {
            await _chatSocketService.connect();

            _chatSocketService.listenNewMessages((message) {
              if (!mounted) return;

              final belongsToMyRooms = _rooms.any((room) => room.id == message.roomId);
              if (!belongsToMyRooms) return;

              _loadRooms(showLoading: false);
            });

            _chatSocketService.listenMessagesRead((data) {
              if (!mounted) return;

              final roomId = data['roomId']?.toString();
              final belongsToMyRooms = _rooms.any((room) => room.id == roomId);
              if (!belongsToMyRooms) return;

              _loadRooms(showLoading: false);
            });
          } catch (e) {
            debugPrint('Error socket rooms: $e');
          }
        }

          @override
          Widget build(BuildContext context) {
            final canPop = Navigator.of(context).canPop();

            return Scaffold(
              backgroundColor: const Color(0xFFF6F7FB),
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(canPop),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                          ? _buildErrorState()
                          : _buildRoomsList(),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget _buildHeader(bool canPop) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (canPop) ...[
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(23),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Mensajes',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Conversaciones de tus servicios',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: IconButton(
                          onPressed: _loadRooms,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por persona o servicio',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          Widget _buildRoomsList() {
            if (_rooms.isEmpty) {
              return _buildEmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Aún no tienes chats',
                message:
                    'Cuando una misión tenga conversación disponible aparecerá aquí.',
              );
            }

            if (_filteredRooms.isEmpty) {
              return _buildEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Sin resultados',
                message: 'No encontramos conversaciones con esa búsqueda.',
              );
            }

            return RefreshIndicator(
              onRefresh: _loadRooms,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                itemCount: _filteredRooms.length,
                itemBuilder: (context, index) {
                  final room = _filteredRooms[index];
                  return _ChatRoomTile(room: room, onTap: () => _openRoom(room));
                },
              ),
            );
          }

          Widget _buildErrorState() {
            return _buildEmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'No se pudieron cargar tus chats',
              message: _errorMessage ?? 'Intenta nuevamente.',
              action: ElevatedButton.icon(
                onPressed: _loadRooms,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          }

          Widget _buildEmptyState({
            required IconData icon,
            required String title,
            required String message,
            Widget? action,
          }) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(icon, color: const Color(0xFF2563EB), size: 38),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    if (action != null) ...[const SizedBox(height: 20), action],
                  ],
                ),
              ),
            );
          }
        }

        class _ChatRoomTile extends StatelessWidget {
          final ChatRoom room;
          final VoidCallback onTap;

          const _ChatRoomTile({required this.room, required this.onTap});

          @override
          Widget build(BuildContext context) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _ChatAvatar(
                        name: room.participantName,
                        imageUrl: room.participantAvatarUrl,
                        size: 56,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    room.participantName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatRoomTime(room.updatedAt),
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              room.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    room.lastMessagePreview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: room.unreadCount > 0
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF64748B),
                                      fontSize: 14,
                                      fontWeight: room.unreadCount > 0
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (room.unreadCount > 0) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 52),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF97316),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      room.unreadCount == 1
                                          ? 'Nuevo'
                                          : room.unreadCount > 99
                                              ? '99+'
                                              : room.unreadCount.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          static String _formatRoomTime(DateTime? date) {
            if (date == null) return '';

            final now = DateTime.now();
            final sameDay =
                date.year == now.year && date.month == now.month && date.day == now.day;

            if (sameDay) {
              return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
            }

            final yesterday = now.subtract(const Duration(days: 1));
            final isYesterday =
                date.year == yesterday.year &&
                date.month == yesterday.month &&
                date.day == yesterday.day;

            if (isYesterday) return 'Ayer';

            return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
          }
        }

        class _ChatAvatar extends StatelessWidget {
          final String name;
          final String imageUrl;
          final double size;

          const _ChatAvatar({
            required this.name,
            required this.imageUrl,
            required this.size,
          });

          @override
          Widget build(BuildContext context) {
            final hasImage = imageUrl.trim().isNotEmpty;

            return CircleAvatar(
              radius: size / 2,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
              child: hasImage
                  ? null
                  : Text(
                      _initials(name),
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            );
          }

          String _initials(String value) {
            final parts = value
                .trim()
                .split(RegExp(r'\s+'))
                .where((part) => part.isNotEmpty)
                .toList();

            if (parts.isEmpty) return 'CH';
            if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
            return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          }
        }

