pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import org.kde.plasma.workspace.dbus as DBus

QtObject {
    id: root

    property string busType: DBus.BusType.Session
    property string service: ""
    property string path: ""
    property string iface: ""
    property string member: ""
    property var arguments: []

    function call(customMember, customArgs, callback) {
        const bus = (root.busType === DBus.BusType.System) ? DBus.SystemBus : DBus.SessionBus;
        const msg = {
            "service": root.service,
            "path": root.path,
            "iface": root.iface,
            "member": customMember !== undefined && customMember !== "" ? customMember : root.member,
            "arguments": customArgs !== undefined && customArgs !== null ? customArgs : root.arguments
        };

        const reply = bus.asyncCall(msg);
        if (callback && reply) {
            reply.finished.connect(() => {
                try {
                    callback(reply);
                } catch (e) {
                    console.error("DBusCall callback error:", e);
                }
                reply.destroy();
            });
        }
    }
}
