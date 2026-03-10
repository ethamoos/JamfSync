# Repository Guidelines

## Project Structure & Module Organization
- CoreData contains the data model
- UI contains Swift UI views
- Model contains non-UI code that is used with the views
- Multipart contains code used for a multipart upload process
- Utility contains code that can be used separately from views
- JamfSyncTests contain the unit tests
- JamfSyncUITests contains the UI tests
- User Guide contains a pages document that is used to create the pdf in the Resources folder, and contains the images used in that document in a folder called Images.
- Resources contain the user guide pdf, assets used by the program

## Coding Style & Naming Conventions
- Use camel case variables, and when using acronyms, treat them as a single word (so not all upper case).
- Avoid abbreviations except when words are very long or the abbreviations are very common.

## Commit & Pull Request Guidelines
- Follow the existing history: concise, sentence-case summaries in present tense (e.g., `Update feature animation`) and reference issues with `(#ID)` when relevant.
- Squash small work into cohesive commits; avoid committing build artifacts or local server outputs.
- Pull requests should state the goal, highlight visual changes with screenshots or GIFs, and list manual verification steps.
