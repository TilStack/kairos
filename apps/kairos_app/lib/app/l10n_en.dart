/// Interface texts in English. Same keys as `frStrings` (a test enforces it).
const enStrings = <String, String>{
  // Title screen and app
  'play': 'PLAY',
  'continue_game': 'CONTINUE',
  'lamp': 'MY LAMP',
  'journal': 'JOURNAL',
  'lamp.done': 'Meditated today · {n}-day streak',
  'lamp.todo': 'Time to meditate · Oil {oil}/{max}',
  'sound.off': 'Mute sound',
  'sound.on': 'Turn sound on',
  'voice.off': 'Turn off read-aloud',
  'voice.on': 'Turn on read-aloud',
  'voice.snack_off': 'Read-aloud turned off. You can still tap LISTEN.',
  'voice.snack_on': 'Read-aloud turned on: lines will be read out.',
  'howto.label': 'How to play',
  'lang.switch': 'Switch the game to French (Français)',
  'logo.semantic': 'KAIROS, the disciple\'s path',
  'logo.tagline': 'THE DISCIPLE\'S PATH',
  'startup.error': 'KAIROS cannot start.\n\n{msg}',
  'back': 'Back',
  'error': 'Error: {e}',

  // Read-aloud
  'listen': 'Listen',
  'stop': 'Stop',
  'listen.semantic': 'Listen to this line',
  'stop.semantic': 'Stop reading',

  // Heart traits
  'trait.faith': 'Faith',
  'trait.courage': 'Courage',
  'trait.integrity': 'Integrity',
  'trait.compassion': 'Compassion',
  'trait.humility': 'Humility',
  'trait.wisdom': 'Wisdom',

  // Discernment flaws
  'anomaly.distorted': 'Distorted verse',
  'anomaly.truncated': 'Cut-off verse',
  'anomaly.out_of_context': 'Taken out of context',
  'anomaly.misattributed': 'Falsely attributed',
  'anomaly.distorted.hint': 'Words were changed or added.',
  'anomaly.truncated.hint': 'The sentence is cut short: the rest changes the meaning.',
  'anomaly.out_of_context.hint': 'The verse exists, but it is made to say something else.',
  'anomaly.misattributed.hint': 'The sentence comes from elsewhere, not from the Bible.',

  // Door levels
  'level.1': 'Level 1 · Rebuild',
  'level.2': 'Level 2 · Missing words',
  'level.3': 'Level 3 · From memory',

  // Scripture and lamp
  'scripture.semantic': 'Scripture, {ref}',
  'scripture.missing': 'Text unavailable in this version.',
  'quote.open': '“',
  'quote.close': '”',
  'lamp.semantic': 'Lamp: oil {oil} of {max}, {streak}-day streak, {vials} gold vials',
  'lamp.oil': 'Oil: {oil} / {max}',
  'lamp.streak': 'Streak: {n} d',
  'lamp.vials': 'Gold vials: {n}',
  'lamp.hint': 'Oil drops a little every day. Meditate to refill it.',

  // How to play
  'howto.title': 'How to play',
  'howto.welcome': 'Welcome! Here is what you can do:',
  'howto.done': 'GOT IT',
  'howto.r1.title': 'Live the story',
  'howto.r1.text':
      'Read the dialogue and tap CONTINUE. When you face a choice, answer from your heart: there is no wrong answer.',
  'howto.r2.title': 'Forge Keys',
  'howto.r2.text':
      'Doors ask you to find a verse again. You get 3 attempts, hints help you, and nothing ever blocks you.',
  'howto.r3.title': 'Keep your lamp lit',
  'howto.r3.text':
      'Once a day, meditate on a passage in MY LAMP to refill the Oil. It drops slowly while you are away.',
  'howto.r4.title': 'Listen to the lines',
  'howto.r4.text':
      'Tap LISTEN to hear a line. The speaker on the title screen reads them all by itself; it stays off until you turn it on.',
  'howto.r5.title': 'Write your journal',
  'howto.r5.text':
      'Your meditations, Keys and notes are kept in your JOURNAL. They stay private, on your phone.',

  // Adventure map
  'map.title': 'Adventure',
  'map.progress': '{done} of {total} chapter{s} completed',
  'map.next.title': 'Your next step',
  'map.next.text': 'Tap chapter {n} to continue your story.',
  'map.done.title': 'Story complete!',
  'map.done.text': 'Replay a chapter to revisit its verses and strengthen your Keys.',
  'ch.done': 'Completed',
  'ch.done_theme': 'Completed · {theme}',
  'ch.locked': 'Finish chapter {n} to unlock it',
  'ch.next': 'Play next',
  'ch.next_theme': 'Play next · {theme}',

  // Reader
  'continue': 'CONTINUE',
  'reader.error':
      'This chapter cannot be opened. If the content was updated, restart the chapter.\n\n{e}',
  'choice.banner':
      'Tap the answer that feels like you. There is no wrong answer: your choices reveal your heart.',
  'disc.title': 'Discernment challenge',
  'disc.text': 'A verse is quoted, but something is off. Read it carefully, then tap the flaw you spot.',
  'disc.cited': 'Quoted as: {ref}',
  'disc.question': 'What is the flaw?',
  'fb.good': 'Well spotted!',
  'fb.bad': 'Not quite — here is why.',
  'fb.bad_short': 'Not quite.',
  'fb.kind': 'The verse was: {label}.',
  'debrief.title': 'In the light of Scripture',
  'debrief.traits': 'Your heart, revealed by your choices',
  'debrief.note': 'No trait is bad: Scripture is a mirror, not a courtroom.',
  'debrief.finish': 'FINISH CHAPTER',
  'end.back': 'BACK TO THE ADVENTURE',
  'end.title': 'Chapter complete',

  // Doors
  'door.forge': 'Forge the Key',
  'door.instr.1': 'Tap the words in the order of the verse, then press CHECK.',
  'door.instr.2': 'Write the missing words of the verse, then press CHECK.',
  'door.instr.3': 'Write the verse from memory, then its reference. Press CHECK.',
  'door.verify': 'CHECK',
  'door.continue': 'CONTINUE',
  'door.place_all': 'Place all the words to be able to check.',
  'door.slot_empty': 'Your verse will appear here, word by word.',
  'door.verse': 'Verse',
  'door.ref': 'Reference (e.g. John 3:16)',
  'door.forged': 'The Key is forged.',
  'door.no_hint': 'No hints at all: well done.',
  'door.in_chest': 'It is stored in your chest.',
  'door.exhausted': 'The Door opens anyway. The Key is waiting for you: you will come back.',
  'door.miss': 'Not quite. You have {n} attempt{s} left.',
  'door.hint': 'Hint: {h}',
  'door.attempts': 'Attempts',
  'door.attempts.semantic': 'Attempts left: {n} of {total}',
  'door.attempts.hint': 'After a mistake, a hint will help you.',

  // Meditation (Lamp)
  'med.title': 'My lamp',
  'med.none': 'No meditation passage is available for this story.',
  'med.done.title': 'You have meditated today.',
  'med.done.sub': 'Your lamp is shining. Come back tomorrow.',
  'med.blessing': 'Your lamp is refilled.',
  'med.vial': 'Seven days of faithfulness: a gold vial is yours!',
  'med.psalm.ref': 'Psalm 119:105',
  'med.psalm.text': 'Your word is a lamp to my feet, and a light for my path.',
  'med.journal_added': 'Your meditation was added to your Journal.',
  'med.banner.title': 'Refill your lamp',
  'med.banner.text':
      'Meditate in three steps: read the passage, answer the question, write your reflection. Take your time.',
  'med.step1': 'Read today\'s passage',
  'med.step2': 'Answer the question',
  'med.step3': 'Write your reflection',
  'med.hint': 'Your reflection stays private, on your phone.',
  'med.button': 'REFILL MY LAMP',
  'med.reject.tooFast': 'Take a little more time to read and meditate on the passage.',
  'med.reject.wrongAnswer': 'Read the passage again: the answer is in it.',
  'med.reject.reflectionTooShort': 'Write a few more words (at least {n} characters).',
  'med.reject.alreadyDone': 'You have already meditated today. See you tomorrow!',

  // Journal
  'journal.title': 'My journal',
  'journal.all': 'All',
  'jtype.meditation': 'Meditations',
  'jtype.key': 'Keys',
  'jtype.discernment': 'Discernment',
  'jtype.note': 'Notes',
  'journal.empty':
      'Your journal is empty for now. Your meditations, Keys and notes will appear here. Nothing leaves your phone.',
  'journal.add': 'NEW NOTE',
  'note.title': 'New note',
  'note.hint': 'A prayer, thanks…',
  'cancel': 'Cancel',
  'save': 'Save',
};
