You are evaluating one restructuring run of a Flutter sample app.

Inputs (all paths are given to you by the caller):
- RUN_DIR: the restructured app (a git repo). The commit recorded in OUT_DIR/base_commit.txt is the state before the agent started; everything after it is the agent's work (`git diff <base>..HEAD`, plus uncommitted changes in `git status`).
- SAMPLE_DIR: the original sample; read its BEHAVIORS.md (the numbered behaviours B1…Bn that must survive).
- OUT_DIR: `claude.json` (the agent's final message is in the `result` field), `post.txt` (analyze/test/git output and the final file tree), `prompt.txt`.
- CRITERIA: the evaluation criteria file. Apply every criterion C1…C10 exactly as written.
- REFERENCE: the MyMali repository, read-only, for checking exact names and shapes.

Method:
1. Read BEHAVIORS.md, prompt.txt, the agent's final message, MIGRATION_NOTES.md in RUN_DIR (if any), and post.txt.
2. Read the run's lib/ and test/ trees in full (they are small).
3. For C1 build a table of every expected name: present with the exact spelling / present under another spelling (give it) / absent.
4. For C3 go through B1…Bn one at a time, each with a verdict and the file:line that proves it (or the absence).
5. For C10 quote every justification verbatim, with where it appears.
6. Do not fix anything. Do not write into RUN_DIR. Write your full report to the path the caller gives you (REPORT_PATH) as markdown with one section per criterion, then return the JSON summary.

Be adversarial: a run that *looks* right but renamed a preference key, dropped a timeout, added a cache, or changed a user-visible string has broken the contract. Be exact about spellings: `ApiHost` vs `APIHost` is a mismatch.
