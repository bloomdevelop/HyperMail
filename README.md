# HyperMail

> Work in Progress, expect unfinished stuff :)

## Roadmap

- [ ] Basic Stuff
  - [ ] Send and receive emails
  - [ ] Email Viewer
    - [ ] Plain View
    - [ ] HTML View
  - [ ] Email Composer
- [ ] Providers
  - [ ] Gmail
  - [ ] Outlook
  - [ ] IMAP/POP[^1]
- [ ] AI Stuff
  - [ ] Proofreading Tool
  - [ ] Email Summarization
  - [ ] AI-Generated Tags and Folders

## Developing

The Linux GTK4 backend uses the [odin-gtk](https://github.com/PucklaJ/odin-gtk) bindings, vendored as a git submodule at `vendor/odin-gtk`. After cloning, run:

```
git submodule update --init --recursive
```

[^1]: I'm sure that we can use Mozilla's database to discover needed IMAP/POP configurations.
