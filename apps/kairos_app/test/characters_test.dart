import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos_app/characters/cast.dart';
import 'package:kairos_app/characters/character_animator.dart';
import 'package:kairos_app/characters/character_widget.dart';
import 'package:kairos_app/characters/pose.dart';

Future<void> loadFont() async {
  final data = File('assets/fonts/Nunito.ttf').readAsBytesSync();
  final loader = FontLoader('Nunito')..addFont(Future.value(ByteData.sublistView(data)));
  await loader.load();
}

void main() {
  group('poses et visages', () {
    test('poseFor est pure : meme instant, meme pose', () {
      final a = poseFor(CharacterAction.wave, 1.3);
      final b = poseFor(CharacterAction.wave, 1.3);
      expect(a.rArm, b.rArm);
      expect(a.rElbow, b.rElbow);
    });

    test('salut : le bras droit est leve, le gauche non', () {
      final p = poseFor(CharacterAction.wave, 0.5);
      expect(p.rArm, greaterThan(2));
      expect(p.lArm, lessThan(1));
    });

    test('joie : les deux bras en l air', () {
      final p = poseFor(CharacterAction.cheer, 0.2);
      expect(p.lArm, greaterThan(2.4));
      expect(p.rArm, greaterThan(2.4));
    });

    test('Pose.lerp : bornes et milieu', () {
      const a = Pose(rArm: 0);
      const b = Pose(rArm: 2);
      expect(Pose.lerp(a, b, 0).rArm, 0);
      expect(Pose.lerp(a, b, 1).rArm, 2);
      expect(Pose.lerp(a, b, 0.5).rArm, 1);
    });

    test('clignement : les yeux se ferment brievement, puis se rouvrent', () {
      expect(faceFor(Mood.happy, 1.0).eyeOpen, 1);
      expect(faceFor(Mood.happy, 3.29).eyeOpen, lessThan(0.5));
      expect(faceFor(Mood.happy, 3.45).eyeOpen, 1);
    });

    test('humeurs : triste et joyeux se distinguent', () {
      expect(faceFor(Mood.sad, 1).mouthSmile, lessThan(0));
      expect(faceFor(Mood.happy, 1).mouthSmile, greaterThan(0));
    });

    test('bouche qui parle : s ouvre et se ferme', () {
      final opens = [for (var i = 0; i < 20; i++) faceFor(Mood.neutral, i * 0.03, talking: true).mouthOpen];
      expect(opens.reduce((a, b) => a > b ? a : b), greaterThan(0.3));
      expect(opens.reduce((a, b) => a < b ? a : b), lessThan(0.1));
    });
  });

  group('animateur', () {
    test('changement d action : fondu progressif, sans saut', () {
      final a = CharacterAnimator()..update(0.5);
      final before = a.pose.rArm;
      a.setAction(CharacterAction.wave);
      a.update(0.05);
      final during = a.pose.rArm;
      expect(during, greaterThan(before));
      expect(during, lessThan(2.5)); // pas encore arrive
      a.update(1);
      expect(a.pose.rArm, greaterThan(2));
    });

    test('meme action : aucun fondu relance', () {
      final a = CharacterAnimator()..update(1);
      final t = a.pose.rArm;
      a.setAction(CharacterAction.idle);
      a.update(0);
      expect(a.pose.rArm, t);
    });
  });

  group('distribution', () {
    test('identifiants uniques et retrouvables', () {
      final ids = Cast.all.map((c) => c.id).toSet();
      expect(ids.length, Cast.all.length);
      expect(Cast.byId('joseph').name, 'Joseph');
      expect(Cast.byId('inconnu').id, 'lumo'); // repli sur la mascotte
    });

    test('la mascotte a une tete de feu', () {
      expect(Cast.lumo.flameHead, isTrue);
      expect(Cast.all.where((c) => c.flameHead), hasLength(1));
    });
  });

  testWidgets('chaque personnage se dessine sans erreur, a plusieurs instants', (tester) async {
    for (final spec in Cast.all) {
      for (final action in CharacterAction.values) {
        await tester.pumpWidget(MaterialApp(
          home: Center(child: CharacterWidget(spec: spec, action: action, mood: Mood.sly, talking: true)),
        ));
        await tester.pump(const Duration(milliseconds: 120));
        await tester.pump(const Duration(milliseconds: 400));
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('planche des personnages (capture)', (tester) async {
    await loadFont();
    tester.view.physicalSize = const Size(1400, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final actions = [
      CharacterAction.wave,
      CharacterAction.idle,
      CharacterAction.talk,
      CharacterAction.point,
      CharacterAction.idle,
      CharacterAction.think,
      CharacterAction.idle,
    ];
    final moods = [Mood.happy, Mood.neutral, Mood.neutral, Mood.wow, Mood.neutral, Mood.think, Mood.sly];
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Nunito'),
      home: RepaintBoundary(
        key: key,
        child: Container(
          color: const Color(0xFFF6EBD0),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              for (var i = 0; i < Cast.all.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CharacterWidget(spec: Cast.all[i], action: actions[i], mood: moods[i], height: 300),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('build/cast_sheet.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes.buffer.asUint8List());
    });
  });
}
