/// Textes de l'interface en francais (langue de reference).
/// Les `{noms}` entre accolades sont remplaces a l'affichage.
const frStrings = <String, String>{
  // Ecran-titre et application
  'play': 'JOUER',
  'continue_game': 'CONTINUER',
  'lamp': 'MA LAMPE',
  'journal': 'JOURNAL',
  'lamp.done': 'Médité aujourd\'hui · série {n} j',
  'lamp.todo': 'À méditer aujourd\'hui · Huile {oil}/{max}',
  'sound.off': 'Couper le son',
  'sound.on': 'Activer le son',
  'voice.off': 'Couper la lecture à voix haute',
  'voice.on': 'Activer la lecture à voix haute',
  'voice.snack_off': 'Lecture à voix haute coupée. Tu peux toujours toucher ÉCOUTER.',
  'voice.snack_on': 'Lecture à voix haute activée : les répliques seront lues.',
  'howto.label': 'Comment jouer',
  'lang.switch': 'Passer le jeu en anglais (English)',
  'logo.semantic': 'KAIROS, le chemin du disciple',
  'logo.tagline': 'LE CHEMIN DU DISCIPLE',
  'startup.error': 'KAIROS ne peut pas démarrer.\n\n{msg}',
  'back': 'Retour',
  'error': 'Erreur : {e}',

  // Lecture a voix haute
  'listen': 'Écouter',
  'stop': 'Arrêter',
  'listen.semantic': 'Écouter cette réplique',
  'stop.semantic': 'Arrêter la lecture',

  // Traits du coeur
  'trait.faith': 'Foi',
  'trait.courage': 'Courage',
  'trait.integrity': 'Intégrité',
  'trait.compassion': 'Compassion',
  'trait.humility': 'Humilité',
  'trait.wisdom': 'Sagesse',

  // Anomalies de discernement
  'anomaly.distorted': 'Verset déformé',
  'anomaly.truncated': 'Verset tronqué',
  'anomaly.out_of_context': 'Sorti de son contexte',
  'anomaly.misattributed': 'Faussement attribué',
  'anomaly.distorted.hint': 'Des mots ont été changés ou ajoutés.',
  'anomaly.truncated.hint': 'La phrase est coupée : la suite change le sens.',
  'anomaly.out_of_context.hint': 'Le verset existe, mais on lui fait dire autre chose.',
  'anomaly.misattributed.hint': 'La phrase vient d\'ailleurs, pas de la Bible.',

  // Niveaux des Portes
  'level.1': 'Niveau 1 · Reconstitution',
  'level.2': 'Niveau 2 · Mots manquants',
  'level.3': 'Niveau 3 · De mémoire',

  // Ecriture et lampe
  'scripture.semantic': 'Écriture, {ref}',
  'scripture.missing': 'Texte indisponible dans cette version.',
  'quote.open': '« ',
  'quote.close': ' »',
  'lamp.semantic': 'Lampe : huile {oil} sur {max}, série de {streak} jours, {vials} fioles d\'or',
  'lamp.oil': 'Huile : {oil} / {max}',
  'lamp.streak': 'Série : {n} j',
  'lamp.vials': 'Fioles d\'or : {n}',
  'lamp.hint': 'L\'Huile baisse doucement chaque jour. Médite pour la recharger.',

  // Guide du joueur
  'howto.title': 'Comment jouer',
  'howto.welcome': 'Bienvenue ! Voici ce que tu peux faire :',
  'howto.done': 'J\'AI COMPRIS',
  'howto.r1.title': 'Vis l\'histoire',
  'howto.r1.text':
      'Lis les dialogues et touche CONTINUER. Quand on te pose un choix, réponds avec ton cœur : il n\'y a pas de mauvaise réponse.',
  'howto.r2.title': 'Forge des Clés',
  'howto.r2.text':
      'Des Portes te demandent de retrouver un verset. Tu as 3 essais, des indices t\'aident, et rien ne te bloque jamais.',
  'howto.r3.title': 'Garde ta lampe allumée',
  'howto.r3.text':
      'Une fois par jour, médite un passage dans MA LAMPE pour recharger l\'Huile. Elle baisse doucement quand tu t\'absentes.',
  'howto.r4.title': 'Écoute les répliques',
  'howto.r4.text':
      'Touche ÉCOUTER pour entendre une réplique. Le haut-parleur de l\'écran-titre les lit toutes seules ; il est coupé tant que tu ne l\'actives pas.',
  'howto.r5.title': 'Écris ton journal',
  'howto.r5.text':
      'Tes méditations, tes Clés et tes notes sont gardées dans ton JOURNAL. Elles restent privées, sur ton téléphone.',

  // Carte de l'aventure
  'map.title': 'Aventure',
  'map.progress': '{done} chapitre{s} sur {total} terminé{s}',
  'map.next.title': 'Ton prochain pas',
  'map.next.text': 'Touche le chapitre {n} pour continuer ton histoire.',
  'map.done.title': 'Arc terminé !',
  'map.done.text': 'Rejoue un chapitre pour revoir ses versets et affermir tes Clés.',
  'ch.done': 'Terminé',
  'ch.done_theme': 'Terminé · {theme}',
  'ch.locked': 'Termine le chapitre {n} pour l\'ouvrir',
  'ch.next': 'À jouer',
  'ch.next_theme': 'À jouer · {theme}',

  // Lecteur
  'continue': 'CONTINUER',
  'reader.error':
      'Ce chapitre ne peut pas être ouvert. Si le contenu a été mis à jour, recommence le chapitre.\n\n{e}',
  'choice.banner':
      'Touche la réponse qui te ressemble. Il n\'y a pas de mauvaise réponse : tes choix révèlent ton cœur.',
  'disc.title': 'Défi de discernement',
  'disc.text':
      'Un verset est cité, mais quelque chose cloche. Lis-le bien, puis touche l\'anomalie que tu repères.',
  'disc.cited': 'Cité comme : {ref}',
  'disc.question': 'Quelle est l\'anomalie ?',
  'fb.good': 'Bien vu !',
  'fb.bad': 'Pas tout à fait — voici pourquoi.',
  'fb.bad_short': 'Pas tout à fait.',
  'fb.kind': 'Il s\'agissait d\'un verset : {label}.',
  'debrief.title': 'À la lumière de l\'Écriture',
  'debrief.traits': 'Ton cœur, révélé par tes choix',
  'debrief.note': 'Aucun trait n\'est mauvais : l\'Écriture est un miroir, pas un tribunal.',
  'debrief.finish': 'TERMINER LE CHAPITRE',
  'end.back': 'RETOUR À L\'AVENTURE',
  'end.title': 'Chapitre terminé',

  // Portes
  'door.forge': 'Forge la Clé',
  'door.instr.1': 'Touche les mots dans l\'ordre du verset, puis appuie sur VÉRIFIER.',
  'door.instr.2': 'Écris les mots manquants du verset, puis appuie sur VÉRIFIER.',
  'door.instr.3': 'Écris le verset de mémoire, puis sa référence. Appuie sur VÉRIFIER.',
  'door.verify': 'VÉRIFIER',
  'door.continue': 'CONTINUER',
  'door.place_all': 'Pose tous les mots pour pouvoir vérifier.',
  'door.slot_empty': 'Ton verset apparaîtra ici, mot après mot.',
  'door.verse': 'Verset',
  'door.ref': 'Référence (ex. Jean 3:16)',
  'door.forged': 'La Clé est forgée.',
  'door.no_hint': 'Sans aucun indice : bravo.',
  'door.in_chest': 'Elle est rangée dans ton coffre.',
  'door.exhausted': 'La Porte s\'ouvre malgré tout. La Clé t\'attend : tu y reviendras.',
  'door.miss': 'Pas tout à fait. Il te reste {n} essai{s}.',
  'door.hint': 'Indice : {h}',
  'door.attempts': 'Essais',
  'door.attempts.semantic': 'Essais restants : {n} sur {total}',
  'door.attempts.hint': 'Après une erreur, un indice t\'aide.',

  // Meditation (Lampe)
  'med.title': 'Ma lampe',
  'med.none': 'Aucun passage de méditation disponible pour cet arc.',
  'med.done.title': 'Tu as médité aujourd\'hui.',
  'med.done.sub': 'Ta lampe brille. Reviens demain.',
  'med.blessing': 'Ta lampe est rechargée.',
  'med.vial': 'Sept jours de fidélité : une fiole d\'or t\'est offerte !',
  'med.psalm.ref': 'Psaumes 119:105',
  'med.psalm.text': 'Ta parole est une lampe à mes pieds, Et une lumière sur mon sentier.',
  'med.journal_added': 'Ta méditation a été ajoutée à ton Journal.',
  'med.banner.title': 'Recharge ta lampe',
  'med.banner.text':
      'Médite en trois étapes : lis le passage, réponds à la question, écris ta réflexion. Prends ton temps.',
  'med.step1': 'Lis le passage du jour',
  'med.step2': 'Réponds à la question',
  'med.step3': 'Écris ta réflexion',
  'med.hint': 'Ta réflexion reste privée, sur ton téléphone.',
  'med.button': 'RECHARGER MA LAMPE',
  'med.reject.tooFast': 'Prends encore un moment pour lire et méditer le passage.',
  'med.reject.wrongAnswer': 'Relis le passage : la réponse s\'y trouve.',
  'med.reject.reflectionTooShort': 'Écris quelques mots de plus ({n} caractères au moins).',
  'med.reject.alreadyDone': 'Tu as déjà médité aujourd\'hui. À demain !',

  // Journal
  'journal.title': 'Mon journal',
  'journal.all': 'Tout',
  'jtype.meditation': 'Méditations',
  'jtype.key': 'Clés',
  'jtype.discernment': 'Discernement',
  'jtype.note': 'Notes',
  'journal.empty':
      'Ton journal est vide pour l\'instant. Tes méditations, tes Clés et tes notes apparaîtront ici. Rien ne quitte ton téléphone.',
  'journal.add': 'NOUVELLE NOTE',
  'note.title': 'Nouvelle note',
  'note.hint': 'Prière, reconnaissance…',
  'cancel': 'Annuler',
  'save': 'Enregistrer',
};
