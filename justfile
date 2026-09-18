init-and-update-submodules:
    git submodule update --init --recursive

run: compile-resources
    odin run .

compile-blueprints:
    mkdir -p platform/gtk/build/ui
    blueprint-compiler compile --output platform/gtk/build/ui/mailbox.ui \
        platform/gtk/ui/mailbox.blp

compile-resources: compile-blueprints
    glib-compile-resources platform/gtk/hypermail.gresource.xml \
        --sourcedir=platform/gtk \
        --target=platform/gtk/hypermail.gresource
