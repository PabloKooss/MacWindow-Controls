import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_controlsEnabled: enabledCheck.checked
    property alias cfg_buttonSize: sizeSpin.value
    property alias cfg_buttonSpacing: spacingSpin.value
    property alias cfg_animationEnabled: animCheck.checked
    property alias cfg_animationDuration: durationSpin.value
    property alias cfg_onlyWhenMaximized: maximizedCheck.checked
    property alias cfg_allActivities: activitiesCheck.checked

    // Defaults supplied by the config dialog (unused, declared to avoid warnings).
    property bool cfg_controlsEnabledDefault
    property int cfg_buttonSizeDefault
    property int cfg_buttonSpacingDefault
    property bool cfg_animationEnabledDefault
    property int cfg_animationDurationDefault
    property bool cfg_onlyWhenMaximizedDefault
    property bool cfg_allActivitiesDefault

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: enabledCheck
            Kirigami.FormData.label: i18n("Controls:")
            text: i18n("Enabled")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: sizeSpin
            Kirigami.FormData.label: i18n("Button size:")
            from: 8; to: 32
            textFromValue: function(v) { return i18n("%1 px", v); }
        }
        QQC2.SpinBox {
            id: spacingSpin
            Kirigami.FormData.label: i18n("Spacing:")
            from: 0; to: 24
            textFromValue: function(v) { return i18n("%1 px", v); }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: animCheck
            Kirigami.FormData.label: i18n("Animation:")
            text: i18n("Animate appearing and disappearing")
        }
        QQC2.SpinBox {
            id: durationSpin
            Kirigami.FormData.label: i18n("Duration:")
            enabled: animCheck.checked
            from: 0; to: 600; stepSize: 25
            textFromValue: function(v) { return i18n("%1 ms", v); }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: maximizedCheck
            Kirigami.FormData.label: i18n("Visibility:")
            text: i18n("Only when the window is maximized")
        }
        QQC2.CheckBox {
            id: activitiesCheck
            text: i18n("Consider windows from all activities")
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("When unchecked, only windows of the current activity are tracked.")
        }
    }
}
