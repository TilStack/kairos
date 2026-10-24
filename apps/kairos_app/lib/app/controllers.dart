import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_core/kairos_core.dart';

import '../data/repository.dart';
import 'providers.dart';

// ------------------------------------------------------------ progression

class ProgressController extends AsyncNotifier<ArcProgress> {
  @override
  Future<ArcProgress> build() {
    final arc = ref.watch(arcProvider);
    return ref.watch(repositoryProvider).loadProgress(arc.id);
  }

  /// Chapitre termine : on garde ce qui est reporte au chapitre suivant.
  Future<void> completeChapter(String chapterId, GameState finished) async {
    final arc = ref.read(arcProvider);
    final repo = ref.read(repositoryProvider);
    final current = await future;
    final next = ArcProgress(
      completed: {...current.completed, chapterId},
      traits: finished.traits,
      flags: finished.flags,
      keys: finished.keys,
    );
    await repo.saveProgress(arc.id, next);
    state = AsyncData(next);
  }
}

final progressProvider = AsyncNotifierProvider<ProgressController, ArcProgress>(ProgressController.new);

// ---------------------------------------------------------------- journal

class JournalController extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() => ref.watch(repositoryProvider).journalEntries();

  Future<void> add(JournalEntry entry) async {
    await ref.read(repositoryProvider).addJournalEntry(entry);
    state = AsyncData(await ref.read(repositoryProvider).journalEntries());
  }

  Future<void> addNote(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return Future.value();
    return add(JournalEntry.note(
      id: ref.read(idProvider)(),
      at: ref.read(clockProvider)(),
      text: clean,
    ));
  }
}

final journalProvider = AsyncNotifierProvider<JournalController, List<JournalEntry>>(JournalController.new);

// ------------------------------------------------------------------ huile

class LampController extends AsyncNotifier<LampState> {
  int get _today => dayNumber(ref.read(clockProvider)());

  @override
  Future<LampState> build() async {
    final repo = ref.watch(repositoryProvider);
    final stored = await repo.loadLamp();
    final decayed = applyDecay(stored, dayNumber(ref.read(clockProvider)()));
    if (decayed.oil != stored.oil || decayed.lastUpdateDay != stored.lastUpdateDay) {
      await repo.saveLamp(decayed);
    }
    return decayed;
  }

  /// Valide la meditation du jour. En cas de succes, la lampe et l'entree
  /// du Journal sont ecrites ensemble (tout ou rien).
  Future<MeditationResult> meditate(Meditation meditation, MeditationAttempt attempt) async {
    final repo = ref.read(repositoryProvider);
    final arc = ref.read(arcProvider);
    final lamp = await future;
    final result = completeMeditation(lamp, meditation, attempt, _today);
    if (!result.accepted) return result;

    final entry = JournalEntry.meditation(
      id: ref.read(idProvider)(),
      at: ref.read(clockProvider)(),
      arcId: arc.id,
      meditation: meditation,
      reflection: attempt.reflection,
    );
    await repo.transaction(() async {
      await repo.saveLamp(result.lamp);
      await repo.addJournalEntry(entry);
    });
    state = AsyncData(result.lamp);
    ref.invalidate(journalProvider);
    return result;
  }
}

final lampProvider = AsyncNotifierProvider<LampController, LampState>(LampController.new);

// ----------------------------------------------------------------- lecteur

/// Retour pedagogique d'un defi de discernement, a lire avant de continuer.
class DiscernmentFeedback {
  const DiscernmentFeedback(this.node, {required this.correct});
  final DiscernmentNode node;
  final bool correct;
}

class ReaderState {
  const ReaderState({this.chapterId, this.game, this.feedback, this.error});

  final String? chapterId;
  final GameState? game;
  final DiscernmentFeedback? feedback;
  final Object? error;

  ReaderState copyWith({GameState? game, DiscernmentFeedback? feedback, bool clearFeedback = false}) =>
      ReaderState(
        chapterId: chapterId,
        game: game ?? this.game,
        feedback: clearFeedback ? null : (feedback ?? this.feedback),
      );
}

/// Pilote le moteur narratif et persiste l'etat a chaque noeud.
class ReaderController extends Notifier<ReaderState> {
  @override
  ReaderState build() => const ReaderState();

  NarrativeEngine get _engine => ref.read(engineProvider);
  KairosRepository get _repo => ref.read(repositoryProvider);
  Arc get _arc => ref.read(arcProvider);

  /// Ouvre un chapitre : reprise exacte de la sauvegarde si elle existe,
  /// sinon demarrage avec ce qui est reporte des chapitres precedents.
  Future<void> open(String chapterId) async {
    state = ReaderState(chapterId: chapterId);
    try {
      final save = await _repo.loadSave(_arc.id);
      GameState game;
      if (save != null && save.chapterId == chapterId && !save.finished) {
        game = save;
        _engine.view(game); // echoue clairement si le contenu a change
      } else {
        final progress = await ref.read(progressProvider.future);
        game = _engine.start(
          chapterId,
          keys: progress.keys,
          traits: progress.traits,
          flags: progress.flags,
        );
        await _repo.writeSave(game, ref.read(clockProvider)());
      }
      state = ReaderState(chapterId: chapterId, game: game);
    } on Object catch (e) {
      state = ReaderState(chapterId: chapterId, error: e);
    }
  }

  Future<void> advance() => _apply((g) => _engine.advance(g));

  Future<void> choose(String optionId) => _apply((g) => _engine.choose(g, optionId));

  Future<void> answerDiscernment(AnomalyType answer) async {
    final game = state.game!;
    final node = _engine.view(game).node as DiscernmentNode;
    final result = _engine.answerDiscernment(game, answer);
    await _commit(result.state, journal: [
      JournalEntry.discernment(
        id: ref.read(idProvider)(),
        at: ref.read(clockProvider)(),
        arcId: _arc.id,
        node: node,
        correct: result.correct,
      ),
    ]);
    state = state.copyWith(feedback: DiscernmentFeedback(node, correct: result.correct));
  }

  void dismissFeedback() => state = state.copyWith(clearFeedback: true);

  /// Mastery actuelle d'un verset (nouvelle si jamais travaille).
  Future<KeyMastery> masteryFor(String verseId) async =>
      await _repo.mastery(verseId) ?? KeyMastery.fresh(verseId, ref.read(clockProvider)());

  /// Fin d'une Porte : maitrise, Journal et recit avancent ensemble.
  Future<ReviewOutcome> finishDoor(DoorChallenge challenge, KeyMastery before) async {
    final now = ref.read(clockProvider)();
    final outcome = challenge.outcome(before, now);
    final forged = challenge.status == DoorStatus.forged;
    final next = _engine.resolveDoor(state.game!, forged: forged);
    await _commit(
      next,
      mastery: outcome.mastery,
      journal: [
        if (forged)
          JournalEntry.keyForged(
            id: ref.read(idProvider)(),
            at: now,
            arcId: _arc.id,
            verseId: challenge.verseId,
            label: BibleRef.tryParse(challenge.verseId)?.label ?? challenge.verseId,
            text: challenge.verse,
          ),
      ],
    );
    return outcome;
  }

  Future<void> _apply(GameState Function(GameState) step) async {
    final game = state.game;
    if (game == null) return;
    await _commit(step(game));
  }

  /// Ecrit atomiquement sauvegarde, maitrise et Journal, puis publie l'etat.
  /// En fin de chapitre, la progression est enregistree et la sauvegarde effacee.
  Future<void> _commit(GameState next, {KeyMastery? mastery, List<JournalEntry> journal = const []}) async {
    await _repo.transaction(() async {
      if (mastery != null) await _repo.saveMastery(mastery);
      for (final e in journal) {
        await _repo.addJournalEntry(e);
      }
      await _repo.writeSave(next, ref.read(clockProvider)());
    });
    if (journal.isNotEmpty) ref.invalidate(journalProvider);
    state = state.copyWith(game: next);
    if (next.finished) {
      await ref.read(progressProvider.notifier).completeChapter(next.chapterId, next);
      await _repo.clearSave(_arc.id);
    }
  }
}

final readerProvider = NotifierProvider<ReaderController, ReaderState>(ReaderController.new);
