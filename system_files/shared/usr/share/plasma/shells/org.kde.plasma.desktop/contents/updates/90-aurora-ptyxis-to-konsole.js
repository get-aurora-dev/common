// Added in May 2026, TODO: remove this file from the system when most users have ran
// this migration script
// https://github.com/ublue-os/aurora/issues/1741

const old_app = "org.gnome.Ptyxis";
const new_app = "org.kde.konsole";

for (const panel of panels()) {
    for (const widget of panel.widgets()) {
        if (widget.type === "org.kde.plasma.icontasks") {
            widget.currentConfigGroup = ["General"];
            const launchers = widget.readConfig("launchers").toString();

            if (launchers.includes(old_app)) {

                const re = new RegExp(old_app.replace(/\./g, "\\."), "g");
                const updated = launchers.replace(re, new_app);

                widget.writeConfig("launchers", updated.split(','));
                widget.reloadConfig();
            }
        }
    }
}
