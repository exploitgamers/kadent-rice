import QtQuick

// VSCodium widget: recently opened folders/workspaces.
WidgetProjects {
    appId: "codium"
    appTitle: "VSCodium"
    binary: "codium"
    itemIcon: "folder_code"
    projects: AppData.codeFolders
    emptyText: "No recent folders"
    newLabel: "Open VSCodium"
}
