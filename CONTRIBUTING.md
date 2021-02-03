# Contributing

## Contributor License Agreement

HearthSim requires a signed CLA from any contributor before his/her PR can be merged.

### What's a CLA?

> A CLA is a legal document in which you state you are entitled to contribute
the code/documentation/translation to the project you’re contributing to and are
willing to have it used in distributions and derivative works. This means that
should there be any kind of legal issue in the future as to the origins and
ownership of any particular piece of code, then that project has the necessary
forms on file from the contributor(s) saying they were permitted to make this
contribution.

> The CLA also ensures that once you have provided a contribution, you cannot try
to withdraw permission for its use at a later date. People and companies can
therefore use that software, confident that they will not be asked to stop using
pieces of the code at a later date.

# Contributing after the CLA is in place

Feel free to fork and file a Pull Request, and file [new issues](https://github.com/HearthSim/HSTracker/issues).

In order to compile, you have to

- Clone the repository.  Fork it on Github!

```
git clone https://github.com/HearthSim/HSTracker.git
```

- Install [SwiftLint](https://github.com/realm/SwiftLint/blob/master/README.md#installation). Example using Homebrew:

```
brew install swiftlint
```

- Open the project in XCode and build it.
  If you run into code signing errors, edit `Config.xcconfig` and swap the comments around. This will allow you to compile for running locally. Alternatively, go to the "Build Settings" and change the signing enitity and certificate to your profile.
  HSTracker _must_ be code signed in order to function properly.
  
  NOTE: Do not submit changes to `Config.xcconfig` on pull requests. The file is meant to make life simple when developing and running locally.

### Commits and Pull Requests

Keep the commit log as healthy as the code. It is one of the first places new contributors will look at the project.

1. No more than one change per commit. There should be no changes in a commit which are unrelated to its message.
2. Every commit should pass all tests on its own.
3. Follow [these conventions](http://chris.beams.io/posts/git-commit/) when writing the commit message

When filing a Pull Request, make sure it is rebased on top of most recent master.
If you need to modify it or amend it in some way, you should always appropriately
[fixup](https://help.github.com/articles/about-git-rebase/) the issues in git and force-push your changes to your fork.

### Releases

We use several tools to help with releases:

* [AppCenter](https://appcenter.ms/) for crash monitoring
* [Sparkle](https://sparkle-project.org) for auto-update
* Github to host the [releases](https://github.com/HearthSim/HSTracker/releases)

The general flow to make a release is:

* Update [CHANGELOG.md](Changelog.md)
* Update `CFBundleShortVersionString`
* Tag 
* Build & export
* Upload to AppCenter
* Upload to github
* Publish appcast file

You can use [hst-release](https://github.com/martinbonnin/hst-release) to automate this process. 
Or if you like ruby better, [hstracker_release.rb](scripts/hstracker_release.rb)

## Need help?

Please [join the developer community Discord](https://discord.gg/hearthsim-devs), channel `#hstracker`.
