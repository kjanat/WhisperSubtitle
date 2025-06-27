# Contributing to WhisperSubtitle

Thank you for your interest in contributing to the WhisperSubtitle PowerShell module! We welcome all contributions, from bug reports to new features.

## How to Contribute

1.  **Fork the Repository**: Start by forking the [WhisperSubtitle repository](https://github.com/kjanat/WhisperSubtitle) to your GitHub account.

2.  **Clone Your Fork**: Clone your forked repository to your local machine:
    ```bash
    git clone https://github.com/YOUR_USERNAME/WhisperSubtitle.git
    cd WhisperSubtitle
    ```

3.  **Create a New Branch**: Create a new branch for your feature or bug fix. Use a descriptive name:
    ```bash
    git checkout -b feature/your-feature-name
    # or
    git checkout -b bugfix/issue-description
    ```

4.  **Make Your Changes**: Implement your changes, adhering to the coding style and conventions of the project.

    -   **Coding Style**: Follow the existing PowerShell coding style. Use PascalCase for function names and variables. Indent with 4 spaces.
    -   **Error Handling**: Ensure proper error handling and logging using `Write-ModuleLog`.
    -   **Tests**: Write Pester tests for your changes. All new features and bug fixes should have corresponding tests.

5.  **Test Your Changes**: Run the existing Pester tests and any new tests you've added to ensure everything works as expected:
    ```powershell
    Invoke-Pester -Path ".\Tests\"
    ```

6.  **Update Documentation**: If your changes affect the module's functionality or parameters, update the relevant documentation (e.g., `README.md`, `Docs/API-Reference.md`).

7.  **Commit Your Changes**: Commit your changes with a clear and concise commit message. Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification (e.g., `feat: add new feature`, `fix: resolve bug`).
    ```bash
    git commit -m "feat: add amazing new feature"
    ```

8.  **Update Changelog (Manual)**: Currently, the `CHANGELOG.md` is updated manually. Please add an entry for your changes under the `[Unreleased]` section, following the existing format.

    *Future Automation*: We plan to automate changelog generation based on Conventional Commits. Tools like `standard-version` or `conventional-changelog-cli` may be integrated in the future.

8.  **Push to Your Fork**: Push your changes to your forked repository:
    ```bash
    git push origin feature/your-feature-name
    ```

9.  **Create a Pull Request**: Open a pull request from your branch to the `main` branch of the original WhisperSubtitle repository. Provide a detailed description of your changes and reference any related issues.

## Code of Conduct

We adhere to a [Code of Conduct](CODE_OF_CONDUCT.md) to ensure a welcoming and inclusive environment for all contributors. Please review it before contributing.

## Reporting Bugs

If you find a bug, please open an issue on GitHub. Provide as much detail as possible, including steps to reproduce the bug, expected behavior, and actual behavior.

## Feature Requests

We welcome feature requests! Open an issue on GitHub and describe your idea in detail. Explain why you think it would be a valuable addition to the module.
