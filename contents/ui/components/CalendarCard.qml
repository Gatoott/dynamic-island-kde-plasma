pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: root

    implicitWidth: 500
    implicitHeight: 200

    property color accentColor: "#3daee9"
    property int firstDayOfWeek: 1 // 1 = Senin (Monday), 0 = Minggu (Sunday)
    property string clockFontFamily: ""

    property date today: new Date()
    property date selectedDate: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    property var calendarModel: []

    property int slideDirection: 1
    property int targetPendingYear: viewYear
    property int targetPendingMonth: viewMonth

    readonly property bool isCurrentMonthAndYear: (viewYear === today.getFullYear() && viewMonth === today.getMonth())
    readonly property bool isShowingToday: isCurrentMonthAndYear && isSameDay(selectedDate, today)

    readonly property var weekdayIndices: firstDayOfWeek === 1 ? [1, 2, 3, 4, 5, 6, 0] : [0, 1, 2, 3, 4, 5, 6]

    function isSameDay(d1, d2) {
        if (!d1 || !d2) return false;
        return d1.getFullYear() === d2.getFullYear() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getDate() === d2.getDate();
    }

    function buildCalendarModel() {
        var cells = [];
        var firstDate = new Date(viewYear, viewMonth, 1);
        var jsDay = firstDate.getDay(); // 0 = Sun, 1 = Mon ...
        var leadDays = (firstDayOfWeek === 1) ? ((jsDay + 6) % 7) : jsDay;

        var daysInPrevMonth = new Date(viewYear, viewMonth, 0).getDate();
        var daysInCurrentMonth = new Date(viewYear, viewMonth + 1, 0).getDate();

        // Hari dari bulan sebelumnya
        for (var i = 0; i < leadDays; i++) {
            var prevDayNum = daysInPrevMonth - leadDays + 1 + i;
            var dPrev = new Date(viewYear, viewMonth - 1, prevDayNum);
            cells.push({
                day: prevDayNum,
                year: dPrev.getFullYear(),
                month: dPrev.getMonth(),
                date: dPrev,
                isCurrentMonth: false,
                isToday: isSameDay(dPrev, today),
                isSelected: isSameDay(dPrev, selectedDate)
            });
        }

        // Hari bulan ini
        for (var d = 1; d <= daysInCurrentMonth; d++) {
            var dCurr = new Date(viewYear, viewMonth, d);
            cells.push({
                day: d,
                year: viewYear,
                month: viewMonth,
                date: dCurr,
                isCurrentMonth: true,
                isToday: isSameDay(dCurr, today),
                isSelected: isSameDay(dCurr, selectedDate)
            });
        }

        // Hari dari bulan berikutnya hingga genap 42 sel (6 baris x 7 kolom)
        var nextDayNum = 1;
        while (cells.length < 42) {
            var dNext = new Date(viewYear, viewMonth + 1, nextDayNum);
            cells.push({
                day: nextDayNum,
                year: dNext.getFullYear(),
                month: dNext.getMonth(),
                date: dNext,
                isCurrentMonth: false,
                isToday: isSameDay(dNext, today),
                isSelected: isSameDay(dNext, selectedDate)
            });
            nextDayNum++;
        }

        calendarModel = cells;
    }

    function prevMonth() {
        if (monthTransitionAnim.running) return;
        slideDirection = -1;
        var newM = viewMonth - 1;
        var newY = viewYear;
        if (newM < 0) {
            newM = 11;
            newY--;
        }
        targetPendingMonth = newM;
        targetPendingYear = newY;
        monthTransitionAnim.restart();
    }

    function nextMonth() {
        if (monthTransitionAnim.running) return;
        slideDirection = 1;
        var newM = viewMonth + 1;
        var newY = viewYear;
        if (newM > 11) {
            newM = 0;
            newY++;
        }
        targetPendingMonth = newM;
        targetPendingYear = newY;
        monthTransitionAnim.restart();
    }

    function goToToday() {
        if (monthTransitionAnim.running) return;
        var now = new Date();
        today = now;
        selectedDate = now;
        if (viewYear === now.getFullYear() && viewMonth === now.getMonth()) {
            buildCalendarModel();
            return;
        }
        slideDirection = (now.getFullYear() > viewYear || (now.getFullYear() === viewYear && now.getMonth() > viewMonth)) ? 1 : -1;
        targetPendingMonth = now.getMonth();
        targetPendingYear = now.getFullYear();
        monthTransitionAnim.restart();
    }

    function selectCell(cellData) {
        selectedDate = cellData.date;
        if (!cellData.isCurrentMonth) {
            slideDirection = (cellData.year > viewYear || (cellData.year === viewYear && cellData.month > viewMonth)) ? 1 : -1;
            targetPendingMonth = cellData.month;
            targetPendingYear = cellData.year;
            monthTransitionAnim.restart();
        } else {
            buildCalendarModel();
        }
    }

    // Zero-polling midnight scheduler
    Timer {
        id: midnightTimer
        repeat: false
        onTriggered: {
            root.today = new Date();
            root.scheduleMidnight();
            root.buildCalendarModel();
        }
    }

    function scheduleMidnight() {
        var now = new Date();
        var tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 1);
        var diffMs = tomorrow.getTime() - now.getTime();
        if (diffMs <= 0) diffMs = 1000;
        midnightTimer.interval = diffMs;
        midnightTimer.restart();
    }

    onFirstDayOfWeekChanged: buildCalendarModel()

    onVisibleChanged: {
        if (visible) {
            today = new Date();
            scheduleMidnight();
            buildCalendarModel();
        }
    }

    Component.onCompleted: {
        today = new Date();
        selectedDate = new Date();
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
        scheduleMidnight();
        buildCalendarModel();
    }

    // Transition Animation (Slide + Fade)
    SequentialAnimation {
        id: monthTransitionAnim
        ParallelAnimation {
            NumberAnimation {
                target: gridContent
                property: "opacity"
                to: 0.0
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: gridContent
                property: "x"
                to: -20 * root.slideDirection
                duration: 100
                easing.type: Easing.OutQuad
            }
        }
        ScriptAction {
            script: {
                root.viewMonth = root.targetPendingMonth;
                root.viewYear = root.targetPendingYear;
                root.buildCalendarModel();
                gridContent.x = 20 * root.slideDirection;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: gridContent
                property: "opacity"
                to: 1.0
                duration: 120
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: gridContent
                property: "x"
                to: 0
                duration: 120
                easing.type: Easing.OutQuad
            }
        }
    }

    // Wheel navigation (Mouse scroll to change month)
    WheelHandler {
        target: root
        orientation: Qt.Vertical
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                root.prevMonth();
            } else if (event.angleDelta.y < 0) {
                root.nextMonth();
            }
        }
    }

    // Main Card Layout inside safe clearance area
    Item {
        anchors.fill: parent
        anchors.leftMargin: 44
        anchors.rightMargin: 44
        anchors.topMargin: 10
        anchors.bottomMargin: 38

        // 1. Header Bar: Month Year title & Actions
        Item {
            id: headerBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 22

            Text {
                id: monthYearText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var d = new Date(root.viewYear, root.viewMonth, 1);
                    var s = d.toLocaleDateString(Qt.locale(), "MMMM yyyy");
                    return s.length > 0 ? (s.charAt(0).toUpperCase() + s.slice(1)) : "";
                }
                font.pixelSize: 13
                font.bold: true
                color: "#ffffff"
                font.family: root.clockFontFamily !== "" ? root.clockFontFamily : "Inter, Roboto, sans-serif"
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // "Hari Ini" Button
                Rectangle {
                    id: todayBtn
                    visible: !root.isShowingToday
                    width: todayBtnText.implicitWidth + 14
                    height: 20
                    radius: 10
                    color: todayBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.09)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)

                    Text {
                        id: todayBtnText
                        anchors.centerIn: parent
                        text: (typeof i18n !== "undefined") ? i18n("Hari ini") : "Hari ini"
                        font.pixelSize: 10
                        font.bold: true
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: todayBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goToToday()
                    }
                }

                // Prev Month Button
                Rectangle {
                    id: prevBtn
                    width: 20
                    height: 20
                    radius: 10
                    color: prevBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)

                    SFSymbolIcon {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        name: "chevron.left"
                        strokeWidth: 1.8
                        color: prevBtnMa.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.8)
                    }

                    MouseArea {
                        id: prevBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevMonth()
                    }
                }

                // Next Month Button
                Rectangle {
                    id: nextBtn
                    width: 20
                    height: 20
                    radius: 10
                    color: nextBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)

                    SFSymbolIcon {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        name: "chevron.right"
                        strokeWidth: 1.8
                        color: nextBtnMa.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.8)
                    }

                    MouseArea {
                        id: nextBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextMonth()
                    }
                }
            }
        }

        // 2. Weekday Header Row
        Item {
            id: weekdayRow
            anchors.top: headerBar.bottom
            anchors.topMargin: 4
            anchors.left: parent.left
            anchors.right: parent.right
            height: 14

            Row {
                anchors.fill: parent
                Repeater {
                    model: root.weekdayIndices

                    Item {
                        required property int modelData
                        required property int index
                        width: weekdayRow.width / 7
                        height: weekdayRow.height

                        Text {
                            anchors.centerIn: parent
                            text: Qt.locale().dayName(modelData, Locale.ShortFormat)
                            font.pixelSize: 10
                            font.bold: true
                            color: Qt.rgba(1, 1, 1, 0.45)
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }

        // 3. Dates Grid Container (with slide/fade transition)
        Item {
            id: gridContainer
            anchors.top: weekdayRow.bottom
            anchors.topMargin: 3
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true

            Item {
                id: gridContent
                anchors.fill: parent

                Grid {
                    id: calendarGrid
                    anchors.fill: parent
                    columns: 7
                    columnSpacing: 0
                    rowSpacing: 0

                    Repeater {
                        model: root.calendarModel

                        Item {
                            required property var modelData
                            required property int index

                            width: gridContent.width / 7
                            height: gridContent.height / 6

                            // Date Indicator Bubble
                            Rectangle {
                                id: dateBubble
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                radius: 9

                                readonly property bool isToday: modelData.isToday
                                readonly property bool isSelected: modelData.isSelected
                                readonly property bool isCurrMonth: modelData.isCurrentMonth

                                color: {
                                    if (isToday) return root.accentColor;
                                    if (isSelected) return Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.28);
                                    if (cellMa.containsMouse) return Qt.rgba(1, 1, 1, 0.12);
                                    return "transparent";
                                }

                                border.width: (isSelected && !isToday) ? 1 : 0
                                border.color: root.accentColor

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    font.pixelSize: 10
                                    font.bold: dateBubble.isToday || dateBubble.isSelected
                                    color: {
                                        if (dateBubble.isToday || dateBubble.isSelected) return "#ffffff";
                                        if (!dateBubble.isCurrMonth) return Qt.rgba(1, 1, 1, 0.25);
                                        return Qt.rgba(1, 1, 1, 0.88);
                                    }
                                }

                                MouseArea {
                                    id: cellMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectCell(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
