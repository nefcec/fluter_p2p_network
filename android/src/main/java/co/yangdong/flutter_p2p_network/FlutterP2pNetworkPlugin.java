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
import p2p.MessageInfo;
import p2p.NodeInfo;
import p2p.OnMessageListener;
import p2p.OnStartListener;
import p2p.P2pPeer;

/**
 * FlutterP2pPlugin
 */
public class FlutterP2pNetworkPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    public static final String pluginName = "co.yangdong.p2pnetwork";
    final String ON_MESSAGE_EVENT = pluginName + ".onMessage";
    final String ON_FIND_CLIENTS_EVENT = pluginName + ".onFindClients";
    final String ON_PEER_STATE_CHANGE_EVENT = pluginName + ".onPeerStateChange";
    final String ON_START_METHOD = pluginName + ".onStart";
    final String ON_STOP_METHOD = pluginName + ".onStop";
    final String SND_MESSAGE_METHOD = pluginName + ".sendMessage";
    final String ON_START_RECEIVE_MESSAGE_METHOD = pluginName + ".onStartReceiveMessage";
    final String GET_PEER_METHOD = pluginName + ".getPeerState";

    private MethodChannel methodChannel;
    private EventChannel onMessageEventChannel;
    private EventChannel.EventSink onMessageEventSink;
    private EventChannel onFindClientsEventChannel;
    private EventChannel.EventSink onFindClientsEventSink;

    private EventChannel onPeerStateChangeEventChannel;
    private EventChannel.EventSink onPeerStateChangeEventSink;

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
            case ON_START_RECEIVE_MESSAGE_METHOD:
//                onStartReceiveMessage();

            case GET_PEER_METHOD:

            default:
                result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        onMessageEventChannel.setStreamHandler(null);
        onFindClientsEventChannel.setStreamHandler(null);
        onPeerStateChangeEventChannel.setStreamHandler(null);
    }

    private void registerReceivedEventChannel(@NonNull FlutterPluginBinding flutterPluginBinding) {
        onMessageEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), ON_MESSAGE_EVENT);
        onMessageEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                onMessageEventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                onMessageEventSink = null;
            }
        });

        onFindClientsEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), ON_FIND_CLIENTS_EVENT);
        onFindClientsEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                onFindClientsEventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                onFindClientsEventSink = null;
            }
        });

        onPeerStateChangeEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), ON_PEER_STATE_CHANGE_EVENT);
        onPeerStateChangeEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                onPeerStateChangeEventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                onPeerStateChangeEventSink = null;
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
            setOnMessageListener();
            String bootId = call.argument("bootId");
            String bootAddress = call.argument("bootAddress");
            String keyPath = call.argument("keyPath");
            p2p.onStart(bootId, bootAddress, keyPath, new OnStartListener() {
                @Override
                public void onFailed(Exception e) {
                    result.error(ErrorCode.ON_START_ERROR, e.getMessage(), e);
                }

                @Override
                public void onSuccess(NodeInfo nodeInfo) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("nodeId", nodeInfo.getId());
                    map.put("address", nodeInfo.getAddresses());
                    map.put("uptime", nodeInfo.getUptime());
                    map.put("reachAbility", nodeInfo.getReachability());
                    result.success(map);
                }
            });
        } catch (Exception ex) {
            result.error(ErrorCode.ON_START_ERROR, ex.getMessage(), ex);
        }
    }

    private void setOnMessageListener() {
        p2p.setOnMessageListener(new OnMessageListener() {
            @Override
            public void onFailed(Exception e) {
                onMessageEventSink.error(ErrorCode.ON_MESSAGE_ERROR, e.getMessage(), e);
            }

            @Override
            public void onMessage(MessageInfo messageInfo) {
                if (activity != null) {
                    activity.runOnUiThread(() -> {
                        Map<String, Object> map = new HashMap<>();
                        map.put("remoteId", messageInfo.getRemoteId());
                        map.put("length", messageInfo.getLength());
                        map.put("data", messageInfo.getData());
                        onMessageEventSink.success(map);
                    });
                }
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
            result.error(ErrorCode.ON_SEND_MESSAGE_ERROR, ex.getMessage(), ex);
        }
    }

    private void onStop(@NonNull Result result) {
        try {
            p2p.onStop();
            result.success(null);
        } catch (Exception ex) {
            result.error(ErrorCode.ON_STOP_ERROR, ex.getMessage(), ex);
        }
    }
}
