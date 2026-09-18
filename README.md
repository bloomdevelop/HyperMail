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

### Available `just` commanads

```bash
just run # run the application
just compile-resources # compile the GTK resources
just init-and-update-submodules # initialize and update submodules
```

### GTK (Linux)

The Linux GTK4 backend uses the [odin-gtk](https://github.com/PucklaJ/odin-gtk) bindings, vendored as a git submodule at `vendor/odin-gtk`. After cloning, run:

```
git submodule update --init --recursive
```

The GTK4 backend defines its windows in GtkBuilder `.ui` files under `platform/ui/`. They are loaded from the source tree at runtime, so UI changes don't require a recompile; release builds should embed them as a `.gresource` instead.

[^1]: I'm sure that we can use Mozilla's database to discover needed IMAP/POP configurations.
