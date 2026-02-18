loadTemplate("org.kde.plasma.desktop.defaultPanel")

var allPanels = panels();

for (var i = 0; i < allPanels.length; ++i) {
    const panel = allPanels[i];
    var widgets = panel.widgets();

    for (var j = 0; j < widgets.length; ++j) {
        var widget = widgets[j];

        if (widget.type === "org.kde.plasma.icontasks") {
            widget.currentConfigGroup = ["General"];

            widget.writeConfig("launchers", [
                "preferred://browser",
                "applications:io.github.kolunmi.Bazaar.desktop",
                "applications:org.gnome.Ptyxis.desktop",
                "preferred://filemanager"
            ]);
            widget.reloadConfig();
        }
    }
}

