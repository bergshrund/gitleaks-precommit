# GitLeaks pre-commit hook

The installation process is quite straightforward. Run the next command in the root of the project directory:

```
curl -o- https://raw.githubusercontent.com/bergshrund/gitleaks-precommit/main/install.sh | bash -x
```

## IMPORTANT NOTICE:

The installation script does not affect the default Git hooks directory content in any way. Instead, it changes the default Git hooks directory to '.githooks' using a command:

```
git config core.hooksPath .githooks
```

and then, it installs a pre-commit hook to a subdirectory with the name 'pre-commit.d' inside this directory. It also adds a symlink to the pre-commit hook in the default '.git/hooks' directory if it exists, and wraps these scripts with a special wrapper that allows the sequential execution of several pre-commit hooks. 

```
ls /PATH/TO/GIT/.githooks/pre-commit
pre-commit
└── pre-commit.d
    └── 01-gitleaks
    └── 02-local-pre-commit --> .git/hooks/pre-commit
```

During the installation process, the script attempts to detect your OS type and architecture to install the gitleak binary accordingly. However, if it fails to do so, it will prompt you for this information. Please note that the current release of gitleaks (v8.18.1) does not provide a prebuilt binary for Windows amd64.

You don't need privilege escalation during the installation process because the gitleak binary will be installed locally in the .githooks/bin/ directory.
