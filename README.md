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

### Available `just` commands

```bash
just run # compile resources and run the application
just compile-blueprints # compile Blueprint sources to GtkBuilder XML
just compile-resources # compile Blueprints and GTK resources
just init-and-update-submodules # initialize and update submodules
```

### GTK (Linux)

The Linux GTK4 backend uses the [odin-gtk](https://github.com/PucklaJ/odin-gtk) bindings, vendored as a git submodule at `vendor/odin-gtk`. After cloning, run:

```
git submodule update --init --recursive
```

The GTK4 backend defines its windows in Blueprint `.blp` files under `platform/gtk/ui/`. Install [`blueprint-compiler`](https://gnome.pages.gitlab.gnome.org/blueprint-compiler/setup.html) to build them. `just run` compiles the Blueprints to ignored GtkBuilder XML artifacts, bundles them in `platform/gtk/hypermail.gresource`, and then starts the application.

[^1]: I'm sure that we can use Mozilla's database to discover needed IMAP/POP configurations.
