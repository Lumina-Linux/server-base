import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import calamares.slideshow 1.0

ColumnLayout {
    id: welcomeView
    spacing: 30
    anchors.centerIn: parent

    // 1. El Logo de Lumina OS (Tu ruta blindada que ya sabemos que sí existe)
    Image {
        id: logoLumina
        source: "file:///etc/calamares/branding/lumina/logo.svg"
        sourceSize.width: 150
        sourceSize.height: 150
        Layout.alignment: Qt.AlignHCenter
        fillMode: Image.PreserveAspectFit
    }

    // Un espacio muerto discreto para que no se encimen
    Item {
        Layout.preferredHeight: 15
    }

    // 2. El Spinner de carga (Para que el usuario vea que el descompresor sigue vivo)
    BusyIndicator {
        id: loadingIndicator
        running: true
        Layout.alignment: Qt.AlignHCenter
    }
}
