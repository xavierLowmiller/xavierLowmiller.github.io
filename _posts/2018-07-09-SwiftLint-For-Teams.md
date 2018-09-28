---
layout: post
title: "SwiftLint For Teams"
date: 2018-07-09
---

[SwiftLint][1] is an indispensible tool in the arsenal of the modern iOS
developer. If you have more than a single iOS developer on the team, chances
are you are already using it to enforce style guides and perform linting.
Our iOS Team discusses [new rules][2] on a regular basis and decides which ones
make sense for our style guide.

However, if you are working on multiple projects at the same time, updating the
`.swiftlint.yml` files can become a hassle. Luckily, there's a way out of this
repetitive task.

## Hosting and loading the shared config 

We use a dedicated repository to host our coding guidelines and best practices.
Part of that repo is our default `.swiftlint.yml` file that we keep updated.

Luckily, most git providers make it easy to download files via an API: Here's
how to get a file [from GitHub][3]:

```shell
SWIFTLINT_CONFIG_PATH="/tmp/.swiftlint.yml"

curl -s https://raw.github.com/realm/SwiftLint/.swiftlint.yml -o $SWIFTLINT_CONFIG_PATH
```

(Notice the *raw*.github.com)

GitLab provides [a similar API][4]. If your provider does not have an API,
you can use the [git-archive][5] command:

```shell
git archive --remote=git://yourGitRepo.com/<user>/<repo> .swiftlint.yml | tar -x -C /tmp
```

## Using the shared file for linting

Using the file is a trivial matter:

```shell
/usr/local/bin/swiftlint autocorrect --config ${SWIFTLINT_CONFIG_PATH}
/usr/local/bin/swiftlint lint --config ${SWIFTLINT_CONFIG_PATH}
```

You can extract all of this into a script (say, `run-swiftlint.sh`) and replace
your SwiftLint build phase with an invocation of this script (or just paste it
in the Run Script phase).

Be aware that this will download the `.swiftlint.yml` on every single build.
Since this will slow local builds and rate limiting is a thing with most
git providers, this is a bad idea.

In production, we use a more sophisticated script.
It will try to download the file at most every 24 hours, or if it was deleted.
Furthermore, it employs caching because `If-Modified-Since` requests
[do not count][6] against the rate limit.

## Overriding rules locally

![SnapshotHelper project setup]({{ "/assets/2018-07-09-first-run-after-lint.png" }})

So what do you do when the new shared configuration introduces a lot of
errors to a project so that it isn't feasible to fix them right now? Since the
new config is shared, you can't just disable the rules temporarily.
Luckily, SwiftLint has a feature that makes this easy: <br>
*nested configurations*.

Consider the following project setup:

![SnapshotHelper project setup]({{ "/assets/2018-07-09-Nested-Config.png" }})

Let's say your style guide forbids force unwrapping because you never ever want
the app to crash in production. Your `.swiftlint.yml` file then might contain a
rule that forbids them and produces errors:

```yaml
opt_in_rules:
  - force_unwrapping
```

Now, how do you allow force unwrapping in tests? You could use a
`//swiftlint:disable force_unwrapping` every time you want to use a `!`, 
but this gets boring quickly. Leveraging SwiftLint's nested configurations,
this is as easy as adding another `.swiftlint.yml` file to your `Tests` folder
that disables the `force_unwrapping` rule again for this subfolder:

```yaml
disabled_rules:
  - force_unwrapping
```

You can now force unwrap in your test files like there's no tomorrow!

This feature can be used to disable rules that are new to the shared config but
break the local project. Unfortunately, I haven't found a way to put a
`.swiftlint.yml` file in the root folder of the project since that one is
overridden by the `--config` parameter in the script, so you have to create
separate ones for the `Sources` and `Tests` directories.

#### ⚠️ Limitations

`include` and `exclude` will be ignored in nested configurations, so you
probably should have folders like `Pods` or `Carthage` in the shared
configuration.

## Recap

- Use a shared `.swiftlint.yml` that is hosted somewhere on your git
- Download the file before linting using a script
- Replace your SwiftLint build phase with the script
- Override shared rules with specific ones using Nested Configurations

This is the script we currently use across our team:

```shell
#!/bin/bash

SWIFTLINT_CONFIG_PATH=".swiftlint.yml"
TEMP_FILE=".temp.yml"

# If the file does not exist or is older than 1 day, download it
if [[ ! -f $SWIFTLINT_CONFIG_PATH ]] || [[ $(find "$SWIFTLINT_CONFIG_PATH" -mtime +1 -print) ]]; then
    last_modified=$(date -u -r $SWIFTLINT_CONFIG_PATH "+%a, %d %b %Y %H:%M:%S GMT" 2>/dev/null || true)
    http_code=$(curl \
        -H 'Accept: application/vnd.github.v4.raw' \
        -H "If-Modified-Since: $last_modified" \
        -w "%{http_code}" \
        -o $TEMP_FILE \
        https://api.github.com/repos/adorsys/csi-coding-guidelines/contents/iOS/.swiftlint.default.yml)

    if [[ 200 == "$http_code" ]]; then
        mv $TEMP_FILE $SWIFTLINT_CONFIG_PATH
    else
        rm -f $TEMP_FILE
    fi
fi

if [[ -e $SWIFTLINT_CONFIG_PATH ]]; then
    "${PODS_ROOT}/SwiftLint/swiftlint" autocorrect --config ${SWIFTLINT_CONFIG_PATH}
    "${PODS_ROOT}/SwiftLint/swiftlint" lint --config ${SWIFTLINT_CONFIG_PATH}
fi
```

You can also find the current version [on our GitHub][7].

---

[1]: https://github.com/realm/SwiftLint
[2]: https://github.com/realm/SwiftLint/blob/master/Rules.md
[3]: https://developer.github.com/v3/repos/contents/
[4]: https://docs.gitlab.com/ee/api/repository_files.html
[5]: https://git-scm.com/docs/git-archive
[6]: https://developer.github.com/v3/?#staying-within-the-rate-limit
[7]: https://github.com/adorsys/csi-coding-guidelines/blob/master/iOS/SwiftLint.md
