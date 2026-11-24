import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../models/place_model.dart';
import '../../repository/overpass_repository.dart';

class OpenStreetMapScreen extends StatefulWidget {
  const OpenStreetMapScreen({super.key});

  @override
  State<OpenStreetMapScreen> createState() => _OpenStreetMapScreenState();
}

class _OpenStreetMapScreenState extends State<OpenStreetMapScreen> {
  static const _initial = LatLng(21.0285, 105.8542);
  static const _ink = Color(0xFF173C35);
  static const _green = Color(0xFF218568);
  final _mapController = MapController();
  final _repository = OverpassRepository();
  final _searchController = TextEditingController();
  final _areaController = TextEditingController(text: 'Hà Nội');
  final _picker = ImagePicker();
  final List<ItineraryStop> _stops = [];
  final List<DateTime> _days = [DateUtils.dateOnly(DateTime.now())];
  final Map<PlaceCategory, IconData> _icons = const {
    PlaceCategory.all: Icons.explore,
    PlaceCategory.attraction: Icons.museum_outlined,
    PlaceCategory.restaurant: Icons.restaurant_outlined,
    PlaceCategory.cafe: Icons.coffee_outlined,
    PlaceCategory.lodging: Icons.hotel_outlined,
    PlaceCategory.entertainment: Icons.celebration_outlined,
  };

  List<Place> _places = [];
  Place? _selected;
  PlaceCategory _category = PlaceCategory.all;
  LatLng _center = _initial;
  LatLng _regionCenter = _initial;
  DateTime _selectedDay = DateUtils.dateOnly(DateTime.now());
  bool _loading = false;
  String? _searchError;
  int _tab = 0;
  Timer? _debounce;
  int _searchGeneration = 0;

  List<ItineraryStop> get _dayStops =>
      _stops.where((s) => DateUtils.isSameDay(s.date, _selectedDay)).toList();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _areaController.dispose();
    _repository.dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 650), _searchPlaces);
  }

  Future<void> _searchPlaces() async {
    _debounce?.cancel();
    final generation = ++_searchGeneration;
    _regionCenter = _areaCenter(_areaController.text);
    setState(() {
      _loading = true;
      _searchError = null;
    });
    try {
      final results = await _repository.search(
        query: _searchController.text,
        area: _areaController.text,
        category: _category,
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _places = results;
        _loading = false;
      });
      if (results.isNotEmpty && _selected == null) {
        _moveMap(results.first.location, zoom: 13);
      }
    } on Object catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _loading = false;
        _searchError = _friendlyError(error);
      });
    }
  }

  LatLng _areaCenter(String input) {
    final area = input.trim().toLowerCase();
    final coordinates = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*[,; ]\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(area);
    if (coordinates != null) {
      final latitude = double.tryParse(coordinates.group(1)!);
      final longitude = double.tryParse(coordinates.group(2)!);
      if (latitude != null &&
          longitude != null &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180) {
        return LatLng(latitude, longitude);
      }
    }
    if (area.contains('đà nẵng') || area == 'da nang') {
      return const LatLng(16.0544, 108.2022);
    }
    if (area.contains('huế') || area == 'hue') {
      return const LatLng(16.4637, 107.5909);
    }
    if (area.contains('hội an') || area == 'hoi an') {
      return const LatLng(15.8801, 108.3380);
    }
    if (area.contains('hồ chí minh') ||
        area.contains('sài gòn') ||
        area == 'ho chi minh') {
      return const LatLng(10.7769, 106.7009);
    }
    return _initial;
  }

  String _friendlyError(Object error) {
    if (error is OverpassSearchUnavailableException) return error.toString();
    final message = error.toString();
    if (error is TimeoutException ||
        message.contains('SocketException') ||
        message.contains('Failed host lookup')) {
      return 'Không kết nối được OpenStreetMap. Kiểm tra mạng rồi thử lại.';
    }
    if (error is FormatException) return error.message;
    return message.replaceFirst('Exception: ', '');
  }

  void _moveMap(LatLng point, {double zoom = 15}) {
    _center = point;
    _mapController.move(point, zoom);
    setState(() {});
  }

  void _selectPlace(Place place) {
    setState(() => _selected = place);
    _moveMap(place.location, zoom: 16);
  }

  Future<void> _showDetails(Place place) async {
    _selectPlace(place);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _placeDetails(context, place),
    );
  }

  Widget _placeDetails(BuildContext context, Place place) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE6F4EF),
                child: Icon(_icons[place.category], color: _green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            place.category.label,
            style: const TextStyle(color: _green, fontWeight: FontWeight.w600),
          ),
          if (place.address != null && place.address!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(place.address!),
            ),
          if (place.description != null && place.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(place.description!),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${place.location.latitude.toStringAsFixed(5)}, ${place.location.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openStopForm(place: place);
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm vào lịch trình'),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _openStopForm({
    required Place place,
    ItineraryStop? existing,
  }) async {
    final start = TextEditingController(text: existing?.start ?? '08:00');
    final end = TextEditingController(text: existing?.end ?? '09:00');
    final cost = TextEditingController(
      text: existing == null ? '0' : existing.cost.toStringAsFixed(0),
    );
    final note = TextEditingController(text: existing?.note ?? '');
    var date = existing?.date ?? _selectedDay;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(
            existing == null ? 'Thêm vào lịch trình' : 'Sửa hoạt động',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    place.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(_dateLabel(date)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) {
                      refresh(() => date = DateUtils.dateOnly(picked));
                    }
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: start,
                        decoration: const InputDecoration(
                          labelText: 'Bắt đầu',
                          hintText: '08:00',
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: end,
                        decoration: const InputDecoration(
                          labelText: 'Kết thúc',
                          hintText: '09:00',
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: cost,
                  decoration: const InputDecoration(
                    labelText: 'Chi phí ước tính (₫)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final from = _parseTime(start.text);
                final to = _parseTime(end.text);
                final parsedCost = double.tryParse(
                  cost.text.trim().replaceAll(',', '.'),
                );
                if (from == null || to == null) {
                  refresh(() => error = 'Nhập giờ theo định dạng 08:30.');
                  return;
                }
                if (to <= from) {
                  refresh(() => error = 'Giờ kết thúc phải sau giờ bắt đầu.');
                  return;
                }
                if (parsedCost == null || parsedCost < 0) {
                  refresh(() => error = 'Chi phí phải là số không âm.');
                  return;
                }
                final overlap = _stops.any(
                  (s) =>
                      s.id != existing?.id &&
                      DateUtils.isSameDay(s.date, date) &&
                      from < _parseTime(s.end)! &&
                      to > _parseTime(s.start)!,
                );
                if (overlap) {
                  refresh(
                    () => error =
                        'Khung giờ bị trùng với hoạt động khác trong ngày.',
                  );
                  return;
                }
                final stop = ItineraryStop(
                  id:
                      existing?.id ??
                      '${place.id}-${DateTime.now().microsecondsSinceEpoch}',
                  place: place,
                  date: date,
                  start: start.text.trim(),
                  end: end.text.trim(),
                  cost: parsedCost,
                  note: note.text.trim(),
                  checkedInAt: existing?.checkedInAt,
                  checkInLocation: existing?.checkInLocation,
                  photoPath: existing?.photoPath,
                );
                setState(() {
                  if (existing != null) {
                    final index = _stops.indexWhere((s) => s.id == existing.id);
                    if (index >= 0) _stops[index] = stop;
                    if (!_days.any((d) => DateUtils.isSameDay(d, date))) {
                      _days.add(date);
                      _days.sort();
                    }
                    _selectedDay = date;
                  } else {
                    _stops.add(stop);
                    final newDayStops =
                        _stops
                            .where(
                              (item) => DateUtils.isSameDay(item.date, date),
                            )
                            .toList()
                          ..sort((a, b) => a.start.compareTo(b.start));
                    _stops.removeWhere(
                      (item) => DateUtils.isSameDay(item.date, date),
                    );
                    _stops.addAll(newDayStops);
                    if (!_days.any((d) => DateUtils.isSameDay(d, date))) {
                      _days.add(date);
                    }
                    _selectedDay = date;
                  }
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      existing == null
                          ? 'Đã thêm ${place.name} vào lịch trình.'
                          : 'Đã cập nhật hoạt động.',
                    ),
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    start.dispose();
    end.dispose();
    cost.dispose();
    note.dispose();
  }

  int? _parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    return h > 23 || m > 59 ? null : h * 60 + m;
  }

  Future<void> _addDay() async {
    final initial = _days.last.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Chọn ngày chuyến đi',
    );
    if (picked == null) return;
    final day = DateUtils.dateOnly(picked);
    if (_days.any((d) => DateUtils.isSameDay(d, day))) {
      setState(() => _selectedDay = day);
      return;
    }
    setState(() {
      _days.add(day);
      _days.sort();
      _selectedDay = day;
    });
  }

  Future<void> _checkIn(ItineraryStop stop) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _notice('Bật dịch vụ vị trí để check-in.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _notice(
          permission == LocationPermission.deniedForever
              ? 'Quyền vị trí đã bị từ chối. Hãy bật trong Cài đặt.'
              : 'Ứng dụng cần quyền vị trí để check-in.',
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 20));
      final here = LatLng(position.latitude, position.longitude);
      final meters = const Distance().as(
        LengthUnit.Meter,
        here,
        stop.place.location,
      );
      if (meters > 150) {
        _notice(
          'Bạn đang cách địa điểm ${meters.round()} m. Cần ở trong phạm vi 150 m để check-in.',
        );
        return;
      }
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 78,
      );
      if (!mounted || photo == null) {
        if (mounted) _notice('Đã hủy chụp ảnh; chưa lưu check-in.');
        return;
      }
      final index = _stops.indexWhere((s) => s.id == stop.id);
      if (index < 0) return;
      setState(
        () => _stops[index] = stop.copyWith(
          checkedInAt: DateTime.now(),
          checkInLocation: here,
          photoPath: photo.path,
        ),
      );
      _notice('Đã check-in tại ${stop.place.name}.');
    } on TimeoutException {
      _notice('Không lấy được vị trí GPS kịp thời. Hãy thử lại ngoài trời.');
    } on Object catch (error) {
      _notice(
        'Không thể check-in: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _deleteStop(ItineraryStop stop) {
    setState(() => _stops.removeWhere((s) => s.id == stop.id));
    _notice('Đã xóa ${stop.place.name} khỏi lịch trình.');
  }

  Future<void> _showCheckInPhoto(String path) => showDialog<void>(
    context: context,
    builder: (context) =>
        Dialog(child: InteractiveViewer(child: Image.file(File(path)))),
  );

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('Bản đồ & lịch trình'),
        centerTitle: false,
        backgroundColor: const Color(0xFFF5F8F6),
        foregroundColor: _ink,
        actions: [
          IconButton(
            tooltip: 'Tìm địa điểm',
            onPressed: () {
              setState(() => _tab = 0);
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.map_outlined),
                  label: Text('Khám phá'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.route_outlined),
                  label: Text('Lịch trình'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
          ),
          Expanded(child: _tab == 0 ? _exploreView() : _itineraryView()),
        ],
      ),
    );
  }

  Widget _exploreView() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth > 700;
      final map = _mapView();
      final search = _searchPanel();
      if (wide) {
        return Row(
          children: [
            SizedBox(width: 350, child: search),
            Expanded(child: map),
          ],
        );
      }
      return Column(
        children: [
          Expanded(flex: 5, child: map),
          Expanded(flex: 6, child: search),
        ],
      );
    },
  );

  Widget _mapView() => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 12,
            onTap: (_, point) {
              _selected = null;
              _center = point;
              setState(() {});
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'vn.edu.tlu.travel_buddy',
              maxZoom: 19,
            ),
            if (_dayStops.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _dayStops.map((s) => s.place.location).toList(),
                    color: _green.withValues(alpha: .8),
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                ..._places.map(
                  (p) => Marker(
                    point: p.location,
                    width: 46,
                    height: 52,
                    child: GestureDetector(
                      onTap: () => _selectPlace(p),
                      child: Icon(
                        Icons.location_on,
                        size: 42,
                        color: _selected?.id == p.id
                            ? Colors.deepOrange
                            : _green,
                      ),
                    ),
                  ),
                ),
                ..._dayStops.map(
                  (s) => Marker(
                    point: s.place.location,
                    width: 36,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showDetails(s.place),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: _ink,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_dayStops.indexOf(s) + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          right: 12,
          top: 12,
          child: FloatingActionButton.small(
            heroTag: 'recenter_osm',
            tooltip: 'Về trung tâm khu vực',
            backgroundColor: Colors.white,
            foregroundColor: _ink,
            onPressed: () => _moveMap(_regionCenter),
            child: const Icon(Icons.my_location),
          ),
        ),
        if (_dayStops.length > 1)
          Positioned(
            left: 12,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  'Tuyến nối minh họa · Không phải đường giao thông',
                  style: TextStyle(fontSize: 11, color: _ink),
                ),
              ),
            ),
          ),
        if (_selected != null)
          Positioned(
            left: 12,
            right: 68,
            bottom: 12,
            child: Card(
              child: ListTile(
                dense: true,
                title: Text(
                  _selected!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_selected!.category.label),
                trailing: IconButton(
                  onPressed: () => _showDetails(_selected!),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _searchPanel() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _scheduleSearch(),
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _searchPlaces();
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Bạn muốn khám phá gì?',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _searchPlaces,
              tooltip: 'Tìm kiếm',
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _areaController,
          onSubmitted: (_) => _searchPlaces(),
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.location_on_outlined),
            labelText: 'Khu vực hoặc tọa độ (vd. Hà Nội, 21.03,105.85)',
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: PlaceCategory.values
                .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(category.label),
                      selected: _category == category,
                      onSelected: (_) {
                        setState(() => _category = category);
                        _scheduleSearch();
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _loading
                    ? 'Đang tìm địa điểm…'
                    : _searchError != null
                    ? 'Có lỗi khi tìm kiếm'
                    : '${_places.length} địa điểm',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
            if (_searchError != null)
              TextButton(
                onPressed: _searchPlaces,
                child: const Text('Thử lại'),
              ),
          ],
        ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              _searchError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: _loading && _places.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _places.isEmpty
              ? Center(
                  child: Text(
                    _searchError == null
                        ? 'Nhập từ khóa rồi tìm địa điểm quanh khu vực.'
                        : 'Không tải được kết quả. Vui lòng thử lại.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  itemCount: _places.length,
                  itemBuilder: (context, index) => _placeCard(_places[index]),
                ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Bản đồ © OpenStreetMap contributors',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ),
      ],
    ),
  );

  Widget _placeCard(Place place) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: () => _showDetails(place),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8F4EF),
        child: Icon(_icons[place.category], color: _green, size: 20),
      ),
      title: Text(
        place.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${place.category.label} · ${place.location.latitude.toStringAsFixed(4)}, ${place.location.longitude.toStringAsFixed(4)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Hiện trên bản đồ',
        onPressed: () => _selectPlace(place),
        icon: const Icon(Icons.near_me_outlined, color: _green),
      ),
    ),
  );

  Widget _itineraryView() {
    final dayStops = _dayStops;
    final total = dayStops.fold<double>(0, (sum, stop) => sum + stop.cost);
    return Column(
      children: [
        _daySelector(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: const Color(0xFFE9F4EF),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.route, color: _green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${dayStops.length} hoạt động · ${_durationLabel(dayStops)}',
                    ),
                  ),
                  Text(
                    '${_money(total)} ₫',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: dayStops.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.luggage_outlined,
                          size: 50,
                          color: _green,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ngày này chưa có hoạt động',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tìm địa điểm và thêm vào lịch trình của bạn.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => setState(() => _tab = 0),
                          icon: const Icon(Icons.explore),
                          label: const Text('Khám phá địa điểm'),
                        ),
                      ],
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
                  itemCount: dayStops.length,
                  onReorderItem: (oldIndex, newIndex) {
                    final item = dayStops.removeAt(oldIndex);
                    dayStops.insert(newIndex, item);
                    setState(() {
                      _stops.removeWhere(
                        (s) => DateUtils.isSameDay(s.date, _selectedDay),
                      );
                      _stops.addAll(dayStops);
                    });
                  },
                  itemBuilder: (context, index) =>
                      _stopCard(dayStops[index], index),
                ),
        ),
      ],
    );
  }

  Widget _daySelector() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _days
                  .map(
                    (day) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          'Ngày ${_days.indexOf(day) + 1} · ${day.day}/${day.month}',
                        ),
                        selected: DateUtils.isSameDay(_selectedDay, day),
                        onSelected: (_) => setState(() => _selectedDay = day),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        IconButton(
          onPressed: _addDay,
          tooltip: 'Thêm ngày',
          icon: const Icon(Icons.add_circle_outline, color: _green),
        ),
      ],
    ),
  );

  String _durationLabel(List<ItineraryStop> stops) {
    final minutes = stops.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    return '${minutes ~/ 60} giờ ${minutes % 60} phút dự kiến';
  }

  String _money(double value) => value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  Widget _stopCard(ItineraryStop stop, int index) => Card(
    key: ValueKey(stop.id),
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F4EE),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Icon(Icons.drag_indicator, color: Colors.black38, size: 19),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.place.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stop.start} – ${stop.end} · ${stop.durationMinutes} phút',
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('${stop.place.category.label} · ${_money(stop.cost)} ₫'),
                if (stop.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      stop.note,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                if (stop.checkedInAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: _green, size: 17),
                        const SizedBox(width: 4),
                        Text(
                          'Đã check-in ${stop.checkedInAt!.hour.toString().padLeft(2, '0')}:${stop.checkedInAt!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (stop.photoPath != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap: () => _showCheckInPhoto(stop.photoPath!),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(stop.photoPath!),
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.broken_image_outlined,
                                    size: 20,
                                    color: _green,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _openStopForm(place: stop.place, existing: stop),
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Sửa'),
                    ),
                    TextButton.icon(
                      onPressed: () => _checkIn(stop),
                      icon: const Icon(Icons.location_searching, size: 17),
                      label: Text(
                        stop.checkedInAt == null ? 'Check-in' : 'Chụp lại',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteStop(stop),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 17,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Xóa',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_places.isEmpty && !_loading && _searchError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchPlaces();
      });
    }
  }
}
