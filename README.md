r-deploy-git
============

This package provides a script to `prebuild` R package. Here
`prebuild` is the procedure of generating R pkg from source file. For
example, if a R package is documented with roxygen, then `prebuild`
should generate Rd files from roxygen. As Rd files are generated from
other source files, they should be ignored by git. On the other hand,
the github repository is also often used for deploy. The Rd files must
be tracked by git, so `devtools::install_github` can install the
package from github, and the maintainer must make sure the Rd files
are synced with code, in each build.

The script `deploy.sh` is provided to handle sync and push to
github. It works on travis-ci, so each successful built commit on
source branch is prebuilt and deployed to deploy branch on github.

# Pros and Cons #

## Pros ##

 - The maintainers do not need to worry about sync Rd files any more.
 - The generated files are not tracked in source branch, so nobody
   will modify them by accident, saving your trouble from
   explaining why they should not be edited.
 - Only commits that pass the test will be deployed to pkg branch.

## Cons ##

  - We have to handle an extra branch. By default, developers are
    working on master branch and `devtools::install_github` install
    from maste branch. With an extra deploy branch, either the
    developers have to switch to the src branch, such as master-src,
    or the users must install from the deploy branch, such as
    master-pkg.

# What does `deploy.sh` do? #
It only works in travis-ci for now.
- Assume Rd files and other generated files are not tracked in source branch.
- Clone the project in sub directory _build. All the prebuild work is done
  in the sub directory, so the working project is left untouched.
- Switch to deploy branch, which by default is named as source
  branch + `-pkg`
- Merge the source branch to the deploy branch. No conflict should
  happen, as files added by prebuild are not tracked in source branch,
  and no source file is edited in deploy branch.
- Call prebuild command
    - If make file exist, than call `make`
    - Otherwise, call `devtools::document`
- `git add` the generated Rd files and R/RcppExports.R,
  src/RcppExports.cpp, if exist
- Make commit and push to github

# Usage #
- **The script is at early stage. Use at your own risk.** The good news
  is that it may only make mess in the deploy branch.
- It only works on travis-ci for now.
- **The later version of the script may change the interface and may not be backward compatible**
- Copy `deploy.sh` to R pkg directory and add it to `.Rbuildignore`.
- Create a new token in [github application settings](https://github.com/settings/applications)
- Encrypt the token following
  [the document on travis-ci](http://docs.travis-ci.com/user/encryption-keys/),
  by running the following command in the project directory

```
travis encrypt GH_TOKEN=your_token_created_on_github
```

- Edit `.travis.yml` based on the following template.

```
after_success:
  - git config --global user.email "email@example.com"
  - git config --global user.name "Your Name"
  - ./deploy.sh -s master-src -d master -c 'make -k prebuild'
env:
  global:
    secure: your_encryped_token
branches:
  except:
    ## exclude the deploy branch from build on travis-ci
    - master
```

- Add Makefile if necessary
- Set default branch as master-pkg, for the convenience of `devtools::intall_github`
