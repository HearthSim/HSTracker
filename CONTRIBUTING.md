# Contributing

Feel free to fork and file a Pull Request, and file [new issues](https://github.com/HearthSim/HSTracker/issues).

In order to compile, you have to

- Clone the repository.  Fork it on Github!

```
git clone https://github.com/HearthSim/HSTracker.git
```

- Get / update swift dependencies using [Carthage](https://github.com/Carthage/Carthage/blob/master/README.md#installing-carthage)

```
carthage update --platform osx --no-use-binaries
```

- Install [SwiftLint](https://github.com/realm/SwiftLint/blob/master/README.md#installation). Example using Homebrew:

```
brew install swiftlint
```
- Download translations and latest card data (you need wget to pull the files, run `brew install wget` to install it)
```
bash bootstrap.sh
```

- Open the project in XCode and build it.
  If you run into code signing errors, go to the "Build Settings" and change the signing enitity and certificate to your profile.
  HSTracker _must_ be code signed in order to function properly.

### Commits and Pull Requests

Keep the commit log as healthy as the code. It is one of the first places new contributors will look at the project.

1. No more than one change per commit. There should be no changes in a commit which are unrelated to its message.
2. Every commit should pass all tests on its own.
3. Follow [these conventions](http://chris.beams.io/posts/git-commit/) when writing the commit message

When filing a Pull Request, make sure it is rebased on top of most recent master.
If you need to modify it or amend it in some way, you should always appropriately
[fixup](https://help.github.com/articles/about-git-rebase/) the issues in git and force-push your changes to your fork.

## Need help?

Please [join the developer community Discord](https://discord.gg/hearthsim-devs), channel `#hstracker`.
