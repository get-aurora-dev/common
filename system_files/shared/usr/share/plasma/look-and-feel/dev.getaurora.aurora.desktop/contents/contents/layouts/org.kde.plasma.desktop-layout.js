var allPanels = panels();

for (var i = 0; i < allPanels.length; ++i) {
    var widgets = allPanels[i].widgets();
    for (var j = 0; j < widgets.length; ++j) {
        var widget = widgets[j];

        if (widget.type === "org.kde.plasma.taskmanager" || widget.type === "org.kde.plasma.icontasks") {

            widget.currentConfigGroup = new Array("General");

            var newLaunchers = [
                "preferred://browser",
                "applications:io.github.kolunmi.Bazaar.desktop",
                "applications:org.gnome.Ptyxis.desktop",
                "preferred://filemanager"
            ];
            
            widget.writeConfig("launchers", newLaunchers);
            widget.reloadConfig();
        }
    }
}
