<h1 align="center"><center>
<img src="artwork/sit-inbox.png" alt="sit-inbox" width="150">
</center>
<br>
sit-inbox
</h1>

*sit-inbox* is a tool that helps managing inbound additions for
[SIT](https://sit.fyi) repositories over different transports. A common case
would be accepting patches for a Git repository for a SIT repository portion of
it, allowing others to contribute their additions to other parties in an
automated way.

This tool is built with decentralized scenarios in mind. It can enable workflows that
don't require hosting it on a publicly accessible server. For example, by piggying back
on e-mail, it can be operated on a regular end-user computer, sporadically connected
to the internet.

Currently, sit-inbox supports:

* receiving patches for **Git-hosted** SIT repositories over **IMAP, POP3** and **Maildir**

This list is expected to grow.

It is packaged as a Docker container to make its installation and operation easier.

## Building

In order to build it, you'll need `make` and `docker`:

```
make
```

## Usage

sit-inbox comes with a small convenience helper that can be used either directly
from the source root or installed using `make install`:

```
sit-inbox new path/to/new/setup
```

This will create default structure for an inbox. You will need to edit
`etc/config.toml` [configuration](#configuration) and possibly add more arguments
to the docker container (most likely, for extra volumes) in `.dockerargs.

In order to run the inbox, simply do this:

```
sit-inbox run path/to/setup
```

After (successful) [re-]provisioning, you should see something like this:

<img src="doc/sit-inbox.png" alt="Screenshot" width="300px">

Upon startup, sit-inbox will attempt to retrieve updates
from inboxes that don't have `autostart` disabled.

By default, it will keep fetching email every minute. this can be changed
with the `cron` option for every `inbox` config entry, it
takes the standard crontab time entry format:

```
*     *     *   *    *
-     -     -   -    -
|     |     |   |    |
|     |     |   |    +----- day of week (0 - 6) (Sunday=0)
|     |     |   +------- month (1 - 12)
|     |     +--------- day of        month (1 - 31)
|     +----------- hour (0 - 23)
+------------- min (0 - 59)
```

The above user interface also  allows the operator to observe logs and manually
invoke operations such as mail retrieval.

## Configuration

An example configuration for a trivial setup will look something like:

```toml
[target.repo]
type = "git"
source = "https://username:password@host/repo.git"
git_username = "sit-inbox"
git_email = "inbox@server.com"

[inbox.email]
type = "email"
retriever = "SimpleIMAPSSLRetriever"
server = "mail.server.com"
username = "inbox@server.com"
password = "password"
default_target = "repo"
```

Please refer to [schema.yaml](schema.yaml) for *almost-human-interpretable*
schema for the `config.toml` file. It'd be great to convert it into Markdown
or something like it, so if you're up to it -- please contribute.

## Updating issues

In order to manage issues and merge requests in this project, we're using
[SIT](https://sit.fyi) with
[issue-tracking](https://modules.sit.fyi/issue-tracking) module and
**sit-inbox** itself (duh!)

Assuming basic familiarity with SIT workflow (sit-web for issues, `sit mr`
script), prepare a branch with a patch and send updates to this repository:

```
git send-email --to=sit-inbox@inbox.sit.fyi master..<branch>
```
