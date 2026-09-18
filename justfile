init-and-update-submodules:
    git submodule update --init --recursive

run:
    odin run .

compile-resources:
    glib-compile-resources platform/gtk/hypermail.gresource.xml \
        --sourcedir=platform/gtk \
        --target=platform/gtk/hypermail.gresource
