import QtQuick

// Kdenlive widget: recent video projects.
WidgetProjects {
    appId: "org.kde.kdenlive"
    appTitle: "Kdenlive"
    binary: "kdenlive"
    itemIcon: "movie"
    projects: AppData.kdenliveProjects
    emptyText: "No recent projects"
    newLabel: "New Project"
}
