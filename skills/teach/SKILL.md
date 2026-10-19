---
name: teach
description: Teach a new skill or concept in the current project workspace; use `setup <topic>` to initialize project-grounded learning files after user approval.
disable-model-invocation: true
argument-hint: "What would you like to learn? Use setup <topic> to prepare this project for teaching."
---

The user has asked you to teach them something. This is a stateful request - they intend to learn the topic over multiple sessions.

This skill owns persistent learning artifacts only when the user explicitly invokes `/teach` for setup or lesson work. If another workflow uses Teach mode for explanations, that workflow may read an existing track but must not create or update files from this skill.

## Teaching Workspace

The current project/workspace root is the **project context**, not the learning-artifact directory. Keep the project's existing structure intact. Each learning track lives under `./learning/<topic-slug>/`; only the `*-FORMAT.md` links below resolve from this skill's folder. Confirm the project root if it is ambiguous. Learning artifacts belong to the user's project, never the plugin installation.

For a track such as `contoso`, use this structure:

```text
learning/contoso/
	MISSION.md
	RESOURCES.md
	GLOSSARY.md                 # when the topic has terminology worth keeping
	NOTES.md                    # only when useful
	lessons/                    # created when the first lesson is written
	reference/                  # created when the first reference is written
	learning-records/           # created when the first record is earned
	assets/                     # created when a component will be reused
```

- `MISSION.md`: why the user is learning and what success looks like. Ground lessons in this. Use [MISSION-FORMAT.md](./MISSION-FORMAT.md).
- `RESOURCES.md`: trusted project and external sources, annotated with what they cover. Use [RESOURCES-FORMAT.md](./RESOURCES-FORMAT.md).
- `GLOSSARY.md`: canonical topic terminology at the track root. Use [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md).
- `lessons/*.html`: short, self-contained lessons; this is the primary teaching artifact.
- `reference/*.html`: printable, compact references such as cheat sheets, algorithms, or syntax summaries.
- `learning-records/*.md`: earned records of demonstrated understanding, prior knowledge, corrections, or mission changes. Use [LEARNING-RECORD-FORMAT.md](./LEARNING-RECORD-FORMAT.md).
- `assets/*`: reusable components shared by multiple lessons.
- `NOTES.md`: teaching preferences or working notes.

All lesson links to references/assets and all cross-links between learning records must be relative to this track directory, so moving one track does not break another.

## Set up a teaching workspace

When the user invokes `/teach setup <topic>` (or asks to prepare this project for teaching), initialize a learning track in `./learning/<topic-slug>/`, leaving the project root and source files untouched. For example, `/teach setup how Contoso works` uses `learning/contoso/`. Do not silently assume the project root: confirm it if the active workspace has multiple roots or the invocation directory is unclear. If a matching track already exists, use it; do not create a duplicate.

1. Inspect project context before drafting content: README, docs, folder structure, manifests, and a small set of relevant source/tests for the requested topic. Do not read the whole repository indiscriminately.
2. Derive a lowercase, dash-case topic slug. Show the resolved project root and proposed track directory. If the slug is ambiguous or collides with an unrelated track, ask the user to choose one.
3. Inspect existing artifacts under that track. Read and preserve them; never replace existing missions, resources, lessons, references, records, notes, or assets without asking.
4. Ask why the user wants to learn the topic and what they want to be able to do. Draft `learning/<topic-slug>/MISSION.md` with [MISSION-FORMAT.md](./MISSION-FORMAT.md).
5. Research trustworthy project and external sources; draft `learning/<topic-slug>/RESOURCES.md` with [RESOURCES-FORMAT.md](./RESOURCES-FORMAT.md). Clearly separate project sources from external references and note gaps.
6. Propose the first lesson and useful reference/glossary material. Create `learning/<topic-slug>/lessons/` and `learning/<topic-slug>/reference/` only when writing their first files. Create the track's `GLOSSARY.md` only when the topic has terminology worth retaining.
7. Inside `learning/<topic-slug>/`, create `learning-records/` only after the user demonstrates learning or discloses prior knowledge, as defined by [LEARNING-RECORD-FORMAT.md](./LEARNING-RECORD-FORMAT.md). Create `assets/` only for components reused by multiple lessons. Create `NOTES.md` only for teaching preferences or useful notes.
8. Before writing, show every proposed path and content. Ask whether to proceed. Check `.gitignore` and explain whether the materials will be tracked; do not edit ignore rules unless asked.

After setup, `/teach <topic>` resolves the matching track under `learning/`, reads its mission, resources, glossary, relevant prior lessons/records, and inspects relevant project files to prepare the next lesson. If no matching track exists, ask whether to set it up or teach conversationally without writing files. Each session saves a lesson only when it actually produces one; a conversational explanation alone does not imply files were created.

## Philosophy

To learn at a deep level, the user needs three things:

- **Knowledge**, captured from high-quality, high-trust resources
- **Skills**, acquired through highly-relevant interactive lessons devised by you, based on the knowledge
- **Wisdom**, which comes from interacting with other learners and practitioners

Before the `RESOURCES.md` is well-populated, your focus should be to find high-quality resources which will help the user acquire knowledge. Never trust your parametric knowledge.

Some topics may require more skills than knowledge. Learning more about theoretical physics might be more knowledge-based. For yoga, more skills-based.

### Fluency vs Storage Strength

You should be careful to split between two types of learning:

- **Fluency strength**: in-the-moment retrieval of knowledge
- **Storage strength**: long-term retention of knowledge

Fluency can give the user an illusory sense of mastery, but storage strength is the real goal. Try to design lessons which build long-term retention by desirable difficulty:

- Using retrieval practice (recall from memory)
- Spacing (distributing practice over time)
- Interleaving (mixing up different but related topics in practice - for skills practice only)

## Lessons

A lesson is the main thing you produce: the unit in which knowledge and skills reach the user. Each lesson is one self-contained HTML file, saved to `learning/<topic-slug>/lessons/` and titled `0001-<dash-case-name>.html` where the number increments within that topic track.

A lesson should be **beautiful**, with clean, readable typography and layout, since the user will return to these later to review. Think Tufte.

The lesson should be short, and completable very quickly. Learners' working memory is very small, and we need to stay within it. But each lesson should give the user a single tangible win that they can build on. It should be directly tied to the mission, and should be in the user's zone of proximal development.

If possible, open the lesson file for the user by running a CLI command.

Each lesson should link via HTML anchors to other lessons and reference documents in the same topic track, using paths relative to `learning/<topic-slug>/`.

Each lesson should recommend a primary source for the user to read or watch. This should be the most high-quality, high-trust resource you found on the topic.

Each lesson should contain a reminder to ask followup questions to the agent. The agent is their teacher, and can assist with anything that's unclear.

## Assets

Lessons are built from reusable **components**, stored in the track's `./assets/`: stylesheets, quiz widgets, simulators, diagram helpers, and anything else a second lesson could reuse.

Reuse is the default, not the exception. Before authoring a lesson, read `./assets/` and build from the components already there. When a lesson needs something new and reusable, write it as a component in `./assets/` and link to it; never inline code a future lesson would duplicate.

A shared stylesheet is the first component a track earns: every lesson links it, so the lessons look like one consistent course rather than a pile of one-offs. As the track grows, so should the component library.

## The Mission

Every lesson should be tied into the mission - the reason that the user is interested in learning about the topic.

If the user is unclear about the mission, or the track's `MISSION.md` is not populated, your first job should be to question the user on why they want to learn this.

Failing to understand the mission will mean knowledge acquisition is not grounded in real-world goals. Lessons will feel too abstract. You will have no way of judging what the user should do next.

Missions may change as the user develops more skills and knowledge. This is normal - make sure to update the track's `MISSION.md` and add a learning record to capture the change. Confirm with the user before changing the mission.

## Zone Of Proximal Development

Each lesson, the user should always feel as if they are being challenged 'just enough'.

The user may specify an exact thing they want to learn. If they don't, figure out their zone of proximal development by:

- Reading `learning/<topic-slug>/learning-records/` for the current track
- Figuring out the right thing to teach them based on their mission
- Teach the most relevant thing that fits in their zone of proximal development

## Knowledge

Lessons should be designed around a skill the user is going to learn. The knowledge in the lesson should be only what's required to acquire that skill. You teach the knowledge first, then get the user to practice the skills via an interactive feedback loop.

Knowledge should first be gathered from trusted resources. Use `learning/<topic-slug>/RESOURCES.md` to keep track of them. Lessons should be littered with citations - links to external resources to back up any claim made. This increases the trustworthiness of the lesson.

For acquiring knowledge, difficulty is the enemy. It eats working memory you need for understanding.

## Skills

If knowledge is all about acquisition, skills are about durability and flexibility. Make the knowledge stick.

For skill acquisition, difficulty is the tool. Effortful retrieval is what builds storage strength. Skills should be taught through interactive lessons. There are several tools at your disposal:

- Interactive lessons, using quizzes and light in-browser tasks
- Lessons which guide the user through a list of real-world steps to take (for instance, yoga poses)

Each of these should be based on a **feedback loop**, where the user receives feedback on their performance. This feedback loop should be as tight as possible, giving feedback immediately - and ideally automatically.

For quizzes, each answer should be exactly the same number of words (and characters, if possible). Vary which position holds the correct answer across questions. Don't give the user any clues about the answer through formatting or order.

## Acquiring Wisdom

Wisdom comes from true real-world interaction - testing your skills outside the learning environment.

When the user asks a question that appears to require wisdom, your default posture should be to attempt to answer - but to ultimately delegate to a **community**.

A community is a place (online or offline) where the user can test their skills in the real world. This might be a forum, a subreddit, a real-world class (budget permitting) or a local interest group.

You should attempt to find high-reputation communities the user can join. If the user expresses a preference that they don't want to join a community, respect it.

## Reference Documents

While creating lessons, you should also create reference documents. Lessons can reference these documents - they are useful for tracking raw units of knowledge useful across lessons.

Lessons will rarely be revisited later - reference documents will be. They should be the compressed essence of the lesson, in a format designed for quick reference.

Some learning topics lend themselves to reference:

- Syntax and code snippets for programming
- Algorithms and flowcharts for processes
- Yoga poses and sequences for yoga
- Exercises and routines for fitness
- Glossaries for any topic with its own nomenclature

Glossaries, in particular, are an essential reference. Once one is created, it should be adhered to in every lesson.

## `NOTES.md`
Store this file at `learning/<topic-slug>/NOTES.md`, alongside that topic's mission and resources.

The user will sometimes express preferences of how they want to be taught, or things you should keep in mind. This is the place to record those preferences, so you can refer back to them when designing lessons or working with the user.
