# Code Quality Config

## Overview

Contains the configuration files for various code quality tools for different languages/formats.

## Tools

### CSS

#### [Stylelint](https://stylelint.io/)

- [.stylelintrc.json](./css/.stylelintrc.json)

### Docker

#### [Hadolint](https://github.com/hadolint/hadolint)

- [.hadolint.yaml](./docker/.hadolint.yaml)

### Java

#### [Checkstyle](https://github.com/checkstyle/checkstyle)

- [checkstyle.xml](./java/checkstyle.xml)
- [checkstyle-suppression.xml](./java/checkstyle-suppression.xml)

#### [Maven License Plugin](https://mathieu.carbou.me/license-maven-plugin/)

- [license-header-definition.txt](./java/license-header-definition.txt)

#### [PMD](https://pmd.github.io/pmd/pmd_rules_java.html)

- [pmd-ruleset.xml](./java/pmd-ruleset.xml)

#### [SpotBugs](https://spotbugs.github.io/)

- [spotbugs-include-filter-file.xml](./java/spotbugs-include-filter-file.xml)
- [spotbugs-exclude-filter-file.xml](./java/spotbugs-exclude-filter-file.xml)

### JavaScript

#### [ESLint](https://eslint.org/docs/latest/rules/)

- [eslint.config.cjs](./javascript/eslint.config.cjs)

### LICENSE

#### [BSD Zero Clause](https://opensource.org/license/0bsd)

- [bsd0.txt](./licenses/bsd0.txt)

### Markdown

#### [markdownlint](https://github.com/DavidAnson/markdownlint)

- [.markdownlint.json](./markdown/.markdownlint.json)

### Python

#### [Ruff](https://docs.astral.sh/ruff/rules/)

- [ruff.toml](./python/ruff.toml)

### TypeScript

#### [typescript-esline](https://typescript-eslint.io/rules/)

- [eslint.config.mjs](./typescript/eslint.config.mjs)
