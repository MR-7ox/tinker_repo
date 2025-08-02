class DummyNotes {
  String name;
  final DateTime Date;
  final Duration time;
  final String relevance;
  final String notes;

  DummyNotes({
    required this.name,
    required this.Date,
    required this.time,
    required this.relevance,
    required this.notes,
  });
}

List<DummyNotes> dummyNotesList = [
  DummyNotes(
    name: "Math Lecture - Algebra",
    Date: DateTime(2025, 7, 1),
    time: Duration(minutes: 45),
    relevance: "High",
    notes: '''
Algebra is a fundamental part of mathematics dealing with symbols and the rules for manipulating those symbols. It is about finding the unknown or putting real-life variables into equations.

In this lecture, we reviewed linear equations and systems of equations. We also practiced factoring quadratics and identifying patterns in expressions.

The focus was on building a strong foundation in solving for x and understanding the role of variables in expressions.

Homework includes solving problems from page 52–57, covering factoring, graphing, and solving linear systems.
''',
  ),
  DummyNotes(
    name: "Physics - Quantum Basics",
    Date: DateTime(2025, 6, 28),
    time: Duration(minutes: 60),
    relevance: "Medium",
    notes: '''
Quantum mechanics is the branch of physics that deals with phenomena at the atomic and subatomic levels. It departs from classical mechanics primarily in how it treats energy and matter.

Today's session explored wave-particle duality, focusing on the double-slit experiment and the concept of superposition.

We discussed the implications of measurement on particle behavior and introduced the idea of quantum entanglement.

Students are encouraged to watch the recommended video on Schrödinger’s Cat and complete the quiz by Monday.
''',
  ),
  DummyNotes(
    name: "Chemistry - Organic Reactions",
    Date: DateTime(2025, 6, 25),
    time: Duration(minutes: 50),
    relevance: "Low",
    notes: '''
Organic reactions involve the transformation of organic compounds through chemical processes. Understanding reaction mechanisms is key.

We covered substitution and elimination reactions, highlighting SN1, SN2, E1, and E2 mechanisms with practical examples.

Special focus was given to the factors influencing reaction pathways: solvent type, temperature, and steric effects.

A worksheet on identifying reaction types will be provided in the next class for practice.
''',
  ),
  DummyNotes(
    name: "History - WW2 Analysis",
    Date: DateTime(2025, 6, 20),
    time: Duration(minutes: 40),
    relevance: "Medium",
    notes: '''
World War II was a global conflict that reshaped the modern world. This lecture focused on the political and economic roots of the war.

We examined the rise of totalitarian regimes in Germany and Italy, and the failure of the League of Nations in preventing aggression.

There was a deep dive into major battles and turning points, including D-Day and the Battle of Stalingrad.

Class discussion emphasized the human cost of war and its long-term impact on international relations and reconstruction.
''',
  ),
  DummyNotes(
    name: "Biology - Cell Division",
    Date: DateTime(2025, 6, 18),
    time: Duration(minutes: 35),
    relevance: "High",
    notes: '''
Cell division is a crucial biological process that enables organisms to grow, repair, and reproduce. We focused on both mitosis and meiosis.

The phases of mitosis (prophase, metaphase, anaphase, telophase) were illustrated using animations and labeled diagrams.

In contrast, meiosis was explained in terms of gamete formation and genetic variation across generations.

Students should complete the concept map assignment and review the DNA replication process before the next session.
''',
  ),
];
