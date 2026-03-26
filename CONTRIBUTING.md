# Contributing

Thank you for your interest in contributing to the bun_buildpack.

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch from `master`

## Branching Strategy

- `master` is protected and requires pull requests with at least 1 approval
- Create feature branches for all changes:

```bash
git checkout -b feat/my-feature master
```

### Branch naming convention

- `feat/description` — New features
- `fix/description` — Bug fixes
- `docs/description` — Documentation changes
- `refactor/description` — Code restructuring

## Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Examples:**

```
feat(detect): add bun.lock detection for Bun 1.2+
fix(supply): handle missing checksum gracefully
docs(readme): add mirror configuration examples
```

## Running Tests

Install [Bats](https://github.com/bats-core/bats-core) and run:

```bash
bats test/*.bats
```

## Pull Request Process

1. Ensure your branch is up to date with `master`
2. Write clear commit messages following the convention above
3. Open a pull request with:
   - A descriptive title
   - Summary of changes
   - Test plan describing how to verify the changes
4. Wait for at least 1 approval before merging

## Code of Conduct

- Be respectful and constructive in discussions
- Focus on the technical merit of contributions
- Welcome newcomers and help them get started

## License

By contributing, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
