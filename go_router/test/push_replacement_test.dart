// ignore_for_file: cascade_invocations, diagnostic_describe_all_properties

// Since we are maintaing this branch separately, it's easier to have our tests
// in a separate file to avoid conflicts in `go_router_test.dart` whenever we 
// catch up with upstream/main by either merging or rebasing

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/src/go_route_match.dart';

import 'go_router_test.dart';

void main() {
  group('replacement', () {
    test('replace last page', () {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: _dummy),
          GoRoute(
            path: '/family/:fid',
            builder: (context, state) => FamilyScreen(
              state.params['fid']!,
            ),
          ),
        ],
        errorBuilder: _dummy,
      );

      router.go('/family/f1');
      router.push('/family/f2');
      router.push('/family/f3');
      // replace the third page
      router.pushReplacement('/family/f4');

      // there should be three pages only.
      expect(router.routerDelegate.matches.length, 3);

      final page1 = router.screenFor(router.routerDelegate.matches[0]) as FamilyScreen;
      final page2 = router.screenFor(router.routerDelegate.matches[1]) as FamilyScreen;
      final page3 = router.screenFor(router.routerDelegate.matches[2]) as FamilyScreen;

      expect(page1.fid, 'f1');
      expect(page2.fid, 'f2');
      expect(page3.fid, 'f4');
    });

    test('expect unique pageKeys for similar fullpaths in the stack', () {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: _dummy),
          GoRoute(
            path: '/family/:fid',
            builder: (context, state) => FamilyScreen(
              state.params['fid']!,
            ),
          ),
          GoRoute(
            name: 'person',
            path: '/person/:pid',
            builder: (context, state) => const PersonScreen('dummy', 'dummy'),
          ),
        ],
        errorBuilder: _dummy,
      );

      router.go('/person/p1');
      // fullpath to be duplicated
      router.push('/family/f1');
      router.push('/person/p2');
      // page to be replaced
      router.push('/person/p3');
      // replace the third page with an existing full path
      router.pushReplacement('/family/f1');

      // full paths must be equal
      final page2Fullpath = router.routerDelegate.matches[1].fullpath;
      final page4Fullpath = router.routerDelegate.matches[3].fullpath;

      expect(page2Fullpath == page4Fullpath, true);

      // keys must be different
      final page2Key = router.routerDelegate.matches[1].pageKey;
      final page4Key = router.routerDelegate.matches[3].pageKey;

      expect(page2Key != page4Key, true);
    });
  });
}

Widget _dummy(BuildContext context, GoRouterState state) => const DummyScreen();

extension on GoRouter {
  Page<dynamic> _pageFor(GoRouteMatch match) {
    final matches = routerDelegate.matches;
    final i = matches.indexOf(match);
    final pages = routerDelegate.getPages(DummyBuildContext(), matches).toList();
    return pages[i];
  }

  Widget screenFor(GoRouteMatch match) => (_pageFor(match) as NoTransitionPage<void>).child;
}
