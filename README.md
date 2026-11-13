# ADaM Skills

[Claude Code](https://claude.ai/code) skills for ADaM-based clinical trial
derivations and independent QC re-derivation, by Eric (Pingye) Zhang
(biostatistician, Eikon Therapeutics).

Each skill is self-contained (own `SKILL.md`, reference docs, and a tested
derivation engine) and installs independently — pick the ones you need.

## Skills

| Skill | What it derives |
|-------|------------------|
| [`confirmed-bor-recist11/`](confirmed-bor-recist11/) | Confirmed Best Overall Response (BOR) per RECIST 1.1's 13-rule confirmation algorithm |
| [`pfs-censoring-recist/`](pfs-censoring-recist/) | PFS event vs. censoring status (missed scheduled assessments, new anti-cancer therapy) |

More ADaM-review skills (e.g. ADSL/ADRS/ADTTE structural QC, AE/exposure
reconciliation) will be added here over time.

## Installation

Copy the skill folder you want into your project's `.claude/skills/`
directory, e.g.:

```bash
cp -r confirmed-bor-recist11 /path/to/project/.claude/skills/
```

No non-base-R dependencies are required beyond what your own data-reading
code needs (e.g. `haven` for SAS datasets).

## Usage

Type `/confirmed-bor-recist11` or `/pfs-censoring-recist`, or just describe
the task naturally — see each skill's own `README.md` for examples.

## License

[MIT](LICENSE)
