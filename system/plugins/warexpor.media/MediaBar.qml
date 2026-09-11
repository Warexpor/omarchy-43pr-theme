import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

// Cloned from omarchy.media. Keep moduleName as the stock id (same pattern as
// warexpor.monitor) so host injectProps / service lookup keep working.
BarWidget {
  id: root
  moduleName: "omarchy.media"

  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("omarchy.media")
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property var sourcePlayers: mediaService ? mediaService.sourcePlayers : []

  readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle || activePlayer.trackArtist)
  readonly property string playIcon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
  readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string label: title + (artist ? "  ·  " + artist : "")

  property bool popupOpen: false
  property bool hovered: false

  function close() { popupOpen = false }
  property real maxLabelWidth: 180

  visible: hasMedia
  implicitWidth: hasMedia ? row.implicitWidth + Style.space(14) : 0
  implicitHeight: barSize

  function run(action) {
    console.warn("[warexpor.media] MediaBar.run", action, "t=" + Date.now())
    if (root.mediaService) root.mediaService.runAction(action, false)
  }

  // One step down from 20 — still larger than body text, not oversized.
  readonly property int transportSize: 16
  readonly property int transportSlot: 22

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Style.space(4)
    spacing: Style.space(10)

    Row {
      id: transport
      spacing: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: Style.space(1)
      height: root.transportSlot

      Item {
        id: prevGlyph
        width: root.transportSlot
        height: parent.height
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: "󰒮"
          color: root.bar.barForeground
          font.family: root.bar.fontFamily
          font.pixelSize: root.transportSize
          font.bold: true
        }
      }

      Item {
        id: playGlyph
        width: root.transportSlot
        height: parent.height
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.playIcon
          color: activePlayer && activePlayer.isPlaying ? root.bar.barForeground : Qt.darker(root.bar.barForeground, 1.5)
          font.family: root.bar.fontFamily
          font.pixelSize: root.transportSize
          font.bold: true
          Behavior on color {
            enabled: !root.bar || root.bar.foregroundAnimationEnabled
            ColorAnimation { duration: 160 }
          }
        }
      }

      Item {
        id: nextGlyph
        width: root.transportSlot
        height: parent.height
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: "󰒭"
          color: root.bar.barForeground
          font.family: root.bar.fontFamily
          font.pixelSize: root.transportSize
          font.bold: true
        }
      }
    }

    Item {
      id: scrollClip
      // Same measure as stock omarchy.media: live Text.implicitWidth, not TextMetrics.
      width: root.label === "" ? 0 : Math.min(root.maxLabelWidth, labelText.implicitWidth)
      height: root.barSize
      clip: true
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.bar.vertical && root.label !== ""

      // Full-width label; clipped by parent. Marquee only while hovered.
      Text {
        id: labelText
        textFormat: Text.PlainText
        text: root.label
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter
        // Hide under the elided overlay while idle so we don't show a hard clip.
        opacity: (root.hovered || !needsScroll) ? 1 : 0
        x: 0

        readonly property bool needsScroll: implicitWidth > root.maxLabelWidth
        readonly property real scrollTravel: scrollClip.width + implicitWidth
        readonly property int scrollMs: Math.max(3500, Math.round(scrollTravel * 14))
        // First pass is shorter (starts on-screen at x=0).
        readonly property int firstPassMs: Math.max(2000, Math.round(implicitWidth * 14))

        // Hover: ease off from the static left position, then train-loop forever.
        SequentialAnimation {
          id: scrollAnim
          running: false

          NumberAnimation {
            target: labelText
            property: "x"
            from: 0
            to: -labelText.implicitWidth
            duration: labelText.firstPassMs
            easing.type: Easing.Linear
          }

          SequentialAnimation {
            loops: Animation.Infinite
            NumberAnimation {
              target: labelText
              property: "x"
              from: scrollClip.width
              to: -labelText.implicitWidth
              duration: labelText.scrollMs
              easing.type: Easing.Linear
            }
          }
        }
      }

      // Idle overflow: static ellipsis (stock always-marquees; we only scroll on hover).
      Text {
        id: idleLabel
        textFormat: Text.PlainText
        text: root.label
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter
        width: scrollClip.width
        elide: Text.ElideRight
        visible: !root.hovered && labelText.needsScroll
      }
    }
  }

  // HoverHandler is what Tray/Indicators use under ModuleSlot's drag MouseArea.
  HoverHandler {
    id: mediaHover
    onHoveredChanged: {
      root.hovered = hovered
      if (hovered && labelText.needsScroll && !root.popupOpen && !root.bar.vertical) {
        labelText.x = 0
        scrollAnim.restart()
      } else {
        scrollAnim.stop()
        labelText.x = 0
      }
    }
  }

  onPopupOpenChanged: {
    if (root.popupOpen) {
      scrollAnim.stop()
      labelText.x = 0
    } else if (root.hovered && labelText.needsScroll && !root.bar.vertical) {
      labelText.x = 0
      scrollAnim.restart()
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.activePlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (!root.activePlayer) return
      if (mouse.button === Qt.MiddleButton) {
        root.run("next")
        return
      }
      if (mouse.button === Qt.RightButton) {
        root.popupOpen = !root.popupOpen
        return
      }

      // Hit-test transport glyphs (bar ModuleSlot otherwise eats child areas).
      function hit(g) {
        var p = mapToItem(g, mouse.x, mouse.y)
        return p.x >= -2 && p.x <= g.width + 2 && p.y >= -4 && p.y <= g.height + 4
      }
      if (hit(prevGlyph)) { root.run("previous"); return }
      if (hit(nextGlyph)) { root.run("next"); return }
      root.run("playPause")
    }

    onWheel: function(wheel) {
      if (!root.activePlayer) return
      if (wheel.angleDelta.y > 0) root.run("previous")
      else if (wheel.angleDelta.y < 0) root.run("next")
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        spacing: Style.space(10)
        width: parent.width

        BorderSurface {
          width: Style.space(64)
          height: Style.space(64)
          radius: Style.spacing.labelGap
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

          Image {
            anchors.fill: parent
            anchors.margins: Style.space(2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: root.activePlayer && root.activePlayer.trackArtUrl ? root.activePlayer.trackArtUrl : ""
            visible: source !== ""
          }

          Text {
            anchors.centerIn: parent
            visible: !root.activePlayer || !root.activePlayer.trackArtUrl
            text: "󰝚"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          spacing: Style.space(4)
          width: parent.width - Style.space(74)

          Text {
            textFormat: Text.PlainText
            text: root.title || "Nothing playing"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            textFormat: Text.PlainText
            text: root.artist
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }

          Text {
            textFormat: Text.PlainText
            text: root.activePlayer && root.activePlayer.trackAlbum ? root.activePlayer.trackAlbum : ""
            color: Qt.darker(root.bar.foreground, 1.6)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)

        Button {
          iconText: "󰒮"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.activePlayer && root.activePlayer.canGoPrevious
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("previous", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.panelGap
          verticalPadding: Style.spacing.controlPaddingY
          iconSize: Style.font.iconLarge
          enabled: root.activePlayer && (root.activePlayer.canTogglePlaying || root.activePlayer.canPlay || root.activePlayer.canPause)
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: "󰒭"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.activePlayer && root.activePlayer.canGoNext
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("next", false, root.mediaService.playerKey(root.activePlayer))
        }
      }

      PanelSeparator {
        visible: root.sourcePlayers.length > 1
        foreground: root.bar.foreground
      }

      Column {
        id: sourceList
        visible: root.sourcePlayers.length > 1
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          model: root.sourcePlayers

          BorderSurface {
            id: sourceRow
            required property var modelData

            readonly property var player: modelData
            readonly property bool selected: root.activePlayer && player
              && root.mediaService.playerKey(root.activePlayer) === root.mediaService.playerKey(player)
            readonly property string sourceTitle: player ? (player.trackTitle || player.identity || player.desktopEntry || "Media source") : "Media source"
            readonly property string sourceDetail: player && player.trackArtist ? player.trackArtist : (player && player.identity ? player.identity : "")

            width: sourceList.width
            height: sourceInner.implicitHeight + Style.space(10)
            radius: Style.spacing.labelGap
            color: selected ? Style.selectedFillFor(root.bar.foreground, Color.accent) : "transparent"
            borderSpec: selected ? Border.controlSpec("normal", root.bar.foreground, Color.accent) : Border.none()

            Row {
              id: sourceInner
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: sourceRow.borderLeft + Style.space(8)
              anchors.rightMargin: sourceRow.borderRight + Style.space(8)
              spacing: Style.space(8)

              Text {
                textFormat: Text.PlainText
                text: sourceRow.player && sourceRow.player.isPlaying ? "󰏤" : "󰐊"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                width: Style.space(18)
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - Style.space(26)
                spacing: Style.space(1)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  textFormat: Text.PlainText
                  text: sourceRow.sourceTitle
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: sourceRow.selected
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  textFormat: Text.PlainText
                  text: sourceRow.sourceDetail
                  color: Qt.darker(root.bar.foreground, 1.5)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  width: parent.width
                  visible: text !== ""
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.mediaService) root.mediaService.selectPlayer(root.mediaService.playerKey(sourceRow.player))
            }
          }
        }
      }
    }
  }
}
