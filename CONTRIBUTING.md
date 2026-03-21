# Contributing

Contributions are welcome. If you find an error or have suggestions for improvement, I appreciate the help.

## Reporting Issues

If you find a bug or error, please open an issue with the following information:
- Which skill contains the problem
- Description of the issue (incorrect function name, wrong syntax, outdated API, etc.)
- Your MATLAB version
- The expected fix, if known

## Suggesting New Content

If you have ideas for new topics or better examples, please open an issue first so we can discuss the approach. This helps avoid duplicate effort.

## Submitting Fixes

For straightforward fixes such as typos or syntax corrections:

1. Fork the repository
2. Make your changes
3. Test if possible (load the skill in Claude and verify with a relevant question)
4. Open a pull request

## Skill Structure

```
skills/
└── matlab-<toolbox>-v2/
    ├── SKILL.md              # Overview of the skill's scope
    ├── knowledge/
    │   ├── INDEX.md          # Points to the detailed cards
    │   └── cards/
    │       └── *.md          # Detailed content (300-800 lines each)
    └── scripts/
        └── template_*.m     # Template scripts with %TODO placeholders
```

## Guidelines

- **Verify accuracy** — confirm function names and syntax against MATLAB documentation
- **Test examples** — code should run without modification
- **Document version requirements** — note if something requires R2024b+ or specific releases
- **Keep it practical** — focus on working code for researchers, not textbook explanations

## Questions

For questions or discussion, please open an issue.
