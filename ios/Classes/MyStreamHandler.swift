public class MyStreamHandler: NSObject, FlutterStreamHandler {

    var eventSink: FlutterEventSink?

    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {

        self.eventSink = events

        events(
            "MicroSensysPlugin: Registered"
        )

        return nil
    }

    public func onCancel(
        withArguments arguments: Any?
    ) -> FlutterError? {

        self.eventSink = nil

        return nil
    }
}