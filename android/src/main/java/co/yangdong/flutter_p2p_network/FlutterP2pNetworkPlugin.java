package co.yangdong.flutter_p2p_network;

import android.app.Activity;
import android.content.Context;
import android.net.wifi.WifiManager;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import p2p.P2pPeer;
import p2p.PeerState;

/**
 * FlutterP2pPlugin
 */
public class FlutterP2pNetworkPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    public static final String pluginName = "co.yangdong.p2pnetwork";
    final String ON_MESSAGE_EVENT = pluginName + ".onMessage";
    final String ON_START_METHOD = pluginName + ".onStart";
    final String ON_STOP_METHOD = pluginName + ".onStop";
    final String SND_MESSAGE_METHOD = pluginName + ".sendMessage";

    private MethodChannel methodChannel;
    private EventChannel onMessageEventChannel;
    private EventChannel.EventSink eventSink;

    private Context context;
    private Activity activity;

    private P2pPeer p2p;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();

        methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), pluginName);
        methodChannel.setMethodCallHandler(this);

        p2p = new P2pPeer();

        registerReceivedEventChannel(flutterPluginBinding);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case ON_START_METHOD:
                onStart(call, result);
                break;
            case ON_STOP_METHOD:
                onStop(result);
                break;
            case SND_MESSAGE_METHOD:
                sendMessage(call, result);
                break;
            default:
                result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        onMessageEventChannel.setStreamHandler(null);
    }

    private void registerReceivedEventChannel(@NonNull FlutterPluginBinding flutterPluginBinding) {
        onMessageEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), ON_MESSAGE_EVENT);
        onMessageEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {

            }
        });

    }


    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }

    private void onStart(@NonNull MethodCall call, @NonNull Result result) {
        try {
            WifiManager wifi = (WifiManager) context
                    .getApplicationContext()
                    .getSystemService(Context.WIFI_SERVICE);
            WifiManager.MulticastLock multicastLock = wifi.createMulticastLock("multicastLock");
            multicastLock.setReferenceCounted(true);
            multicastLock.acquire();
            String bootId = call.argument("bootId");
            String bootAddress = call.argument("bootAddress");
            String keyPath = call.argument("keyPath");
            PeerState peerState = p2p.startPeer(
                    bootId,
                    bootAddress,
                    keyPath);
            Map<String, Object> map = new HashMap<>();
            map.put("id", peerState.getId());
            map.put("address", peerState.getAddresses());
            map.put("uptime", peerState.getUptime());
            map.put("reachAbility", peerState.getReachability());
            setPeerListener();
            result.success(map);
        } catch (Exception ex) {
            result.error(ErrorCode.ON_START_ERROR, ex.getMessage(), ex);
        }
    }

    private void setPeerListener() {
        p2p.setPeerListener((remotePeerId, length, data) -> {
            if (activity != null) {
                activity.runOnUiThread(() -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("remotePeerId", remotePeerId);
                    map.put("length", length);
                    map.put("data", data);
                    eventSink.success(map);
                });
            }
        });
    }

    private void sendMessage(@NonNull MethodCall call, @NonNull Result result) {
        try {
            String peerId = call.argument("peerId");
            byte[] data = call.argument("data");
            p2p.sendMessage(peerId, data);
            result.success(null);
        } catch (Exception ex) {
            result.error(ErrorCode.ON_REQUEST_ERROR, ex.getMessage(), ex);
        }
    }

    private void onStop(@NonNull Result result) {
        try {
            p2p.stopPeer();
            result.success(null);
        } catch (Exception ex) {
            result.error(ErrorCode.ON_STOP_ERROR, ex.getMessage(), ex);
        }
    }
}
