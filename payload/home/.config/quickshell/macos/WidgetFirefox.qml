import QtQuick

// Firefox widget: your most visited sites (from Firefox's history).
WidgetProjects {
    appId: "firefox"
    appTitle: "Firefox"
    binary: "firefox"
    itemIcon: "public"
    projects: AppData.firefoxSites
    emptyText: "No browsing history yet"
    newLabel: "Open Firefox"
}
