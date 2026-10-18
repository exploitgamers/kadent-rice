import QtQuick

// Apple-style spring driven by (response, dampingRatio), as in SwiftUI/UIKit.
//   response     — seconds to reach the target (not a fixed duration)
//   dampingRatio — 1.0 = critically damped (no overshoot), < 1 = bounce
// Interruptible: retargeting mid-flight continues from the live value and
// velocity, so reversals never jump or hit a "brick wall".
// Usage: Spring { id: s; target: open ? 0 : 100 }  …  y: s.value
Item {
    id: root

    property real target: 0
    property real value: 0
    property real velocity: 0
    property real response: Config.springResponse
    property real dampingRatio: Config.springDamping
    property real epsilon: 0.01

    property bool _ready: false
    readonly property bool settled: Math.abs(target - value) < epsilon && Math.abs(velocity) < epsilon

    visible: false

    // Start at rest on the initial target (no animation on load)
    Component.onCompleted: {
        value = target;
        _ready = true;
    }

    FrameAnimation {
        running: root._ready && !root.settled

        onTriggered: {
            if (Config.reducedMotion) {
                root.value = root.target;
                root.velocity = 0;
                return;
            }

            const k = Math.pow(2 * Math.PI / root.response, 2); // stiffness (mass = 1)
            const c = 4 * Math.PI * root.dampingRatio / root.response; // damping
            const dt = Math.min(frameTime, 1 / 20); // clamp after stalls
            const steps = Math.max(1, Math.ceil(dt * 240)); // stable substeps
            const h = dt / steps;

            let x = root.value;
            let v = root.velocity;
            for (let i = 0; i < steps; i++) {
                v += (-k * (x - root.target) - c * v) * h;
                x += v * h;
            }

            if (Math.abs(root.target - x) < root.epsilon && Math.abs(v) < root.epsilon) {
                x = root.target;
                v = 0;
            }
            root.value = x;
            root.velocity = v;
        }
    }
}
