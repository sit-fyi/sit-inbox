# sit-inbox

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

The interface allows the operator to observe logs and manually invoke
operations such as mail retrieval.

## Configuration

An example configuration for a trivial setup will look something like:

```toml
[repository.repo]
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
default_repository = "repo"
```

Please refer to [schema.yaml](schema.yaml) for *almost-human-interpretable*
schema for the `config.toml` file. It'd be great to convert it into Markdown
or something like it, so if you're up to it -- please contribute.
