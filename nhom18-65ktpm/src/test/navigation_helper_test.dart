import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ketnoitinhnguyenvienxemay/features/navigation/navigation_helper.dart';

void main() {
  group('NavigationHelper - UC-06', () {
    test('formatDistance định dạng mét và km chính xác', () {
      expect(NavigationHelper.formatDistance(350), '350 m');
      expect(NavigationHelper.formatDistance(999), '999 m');
      expect(NavigationHelper.formatDistance(1000), '1.0 km');
      expect(NavigationHelper.formatDistance(2540), '2.5 km');
      expect(NavigationHelper.formatDistance(10200), '10.2 km');
    });

    test('formatDuration định dạng phút và giờ chính xác', () {
      expect(NavigationHelper.formatDuration(5), '5 phút');
      expect(NavigationHelper.formatDuration(59), '59 phút');
      expect(NavigationHelper.formatDuration(60), '1 giờ');
      expect(NavigationHelper.formatDuration(75), '1 giờ 15 phút');
      expect(NavigationHelper.formatDuration(120), '2 giờ');
    });

    test('estimateMotorbikeMinutes trả về tối thiểu 1 phút', () {
      expect(NavigationHelper.estimateMotorbikeMinutes(0), 1);
      expect(NavigationHelper.estimateMotorbikeMinutes(100), 1);
      // 5km chim bay * 1.25 = 6.25km đường; 6.25 / 28 * 60 ~= 14 phút
      final mins = NavigationHelper.estimateMotorbikeMinutes(5000);
      expect(mins, inInclusiveRange(12, 16));
    });

    test('parseOsrmRoute giải mã GeoJSON và chỉ dẫn từng chặng hợp lệ', () {
      final route = NavigationHelper.parseOsrmRoute({
        'routes': [
          {
            'distance': 2450.5,
            'duration': 310,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [105.8542, 21.0285],
                [105.8600, 21.0310],
                [105.8650, 21.0350],
              ],
            },
            'legs': [
              {
                'steps': [
                  {
                    'name': 'Đinh Tiên Hoàng',
                    'distance': 500,
                    'maneuver': {'type': 'depart'},
                  },
                  {
                    'name': 'Tràng Tiền',
                    'distance': 1950.5,
                    'maneuver': {'type': 'turn', 'modifier': 'left'},
                  },
                  {
                    'name': '',
                    'distance': 0,
                    'maneuver': {'type': 'arrive'},
                  },
                ],
              },
            ],
          },
        ],
      });

      expect(route, isNotNull);
      expect(route!.isRoadRoute, isTrue);
      expect(route.points.length, 3);
      expect(route.points.first.latitude, closeTo(21.0285, 1e-6));
      expect(route.points.first.longitude, closeTo(105.8542, 1e-6));
      expect(route.distanceMeters, closeTo(2450.5, 1e-3));
      expect(route.durationMinutes, 6);
      expect(route.steps.length, 3);
      expect(route.steps[0].instruction, 'Xuất phát trên Đinh Tiên Hoàng');
      expect(route.steps[1].instruction, 'Rẽ trái vào Tràng Tiền');
      expect(route.steps[2].instruction, 'Đã đến điểm đích');

      expect(NavigationHelper.parseOsrmRoute({'routes': []}), isNull);
      expect(NavigationHelper.parseOsrmRoute({}), isNull);
    });

    test('fetchRoadRoute tự động chuyển máy chủ OSRM dự phòng khi máy chủ chính lỗi', () async {
      final calledHosts = <String>[];
      final mockClient = MockClient((request) async {
        calledHosts.add(request.url.host);
        if (request.url.host == 'router.project-osrm.org') {
          return http.Response('Service Unavailable', 503);
        }
        return http.Response(
          jsonEncode({
            'routes': [
              {
                'distance': 1800,
                'duration': 240,
                'geometry': {
                  'type': 'LineString',
                  'coordinates': [
                    [105.8430, 21.0070],
                    [105.8490, 21.0150],
                    [105.8542, 21.0285],
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final route = await NavigationHelper.fetchRoadRoute(
        originLat: 21.0070,
        originLng: 105.8430,
        destinationLat: 21.0285,
        destinationLng: 105.8542,
        client: mockClient,
      );

      expect(calledHosts, [
        'router.project-osrm.org',
        'routing.openstreetmap.de',
      ]);
      expect(route, isNotNull);
      expect(route!.isRoadRoute, isTrue);
      expect(route.points.length, 3);
      expect(route.durationMinutes, 4);
    });
  });
}
