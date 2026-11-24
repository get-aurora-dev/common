// TODO: remove this file from the system when most users have ran
// this migration script
// Restore the aurora default icon if user has had the FW icon in kickoff

const old_icon = "framework";
const new_icon = "distributor-logo-symbolic";

for (const panel of panels()) {
    for (const widget of panel.widgets()) {
        if (widget.type === "org.kde.plasma.kickoff") {
            widget.currentConfigGroup = ["General"];

            if (widget.readConfig("icon", "") === old_icon) {
                widget.writeConfig("icon", new_icon);
                widget.reloadConfig();
            }
        }
    }
}
