[日本語](./README.md) | English

# Deprecated!

We have released a new WebRTC platform, [ECLWebRTC](https://webrtc.ecl.ntt.com/en/?origin=skyway), to take the place of SkyWay. We will be shutting down the SkyWay servers in March 2018. Customers who are currently using SkyWay are required to migrate to ECLWebRTC by then or their services will stop working.

If you are looking for the repository of ECLWebRTC, please see [SKWMeshRoom Class](https://webrtc.ecl.ntt.com/en/ios-reference/a00121.html) and [SKWSFURoom Class](https://webrtc.ecl.ntt.com/en/ios-reference/a00157.html).

# Multi Party

This is a library for easy implementation of group video chat with SkyWay(http://nttcom.github.io/skyway/) for iOS.

## Install

Podfile
```
pod 'SkyWay-iOS-SDK'
pod 'SkyWay-MultiParty-iOS', :git => 'https://github.com/nttcom/SkyWay-MultiParty-iOS.git'
```

Install
```
pod install
```

## API reference

### MultiParty

#### Property
* opened (BOOL)
    * Is YES if the connection is open.

#### Constructor
```objective-C
MultiPartyOption* option = [[MultiPartyOption alloc] init];
option.key = @"{API-KEY}";
option.domain = @”{DOMAIN}”;

MultiParty* party = [[MultiParty alloc] initWith options:option];
```
* options (MultiPartyOption)
    * Specify connection settings.

#### MultiPartyOption

* key (NSString)
    * an API key obtained from [SkyWay Web Site](https://skyway.io/ds/)
* domain (NSString)
    * The domain registered with the API key on ([the SkyWay developer's dashboard](https://skyway.io/ds/))。**Required**。
    * room (NSString)
        * room name。Unique Room ID is made from 'room','locationHost' and 'locationPath'. **dafault ''**
    * locationHost (NSString)
        * hostname of webapp(when you connect with [JS SDK](https://github.com/nttcom/SkyWay-MultiParty)). Unique Room ID is made from 'room','locationHost' and 'locationPath'.
    * locationPath (NSString)
        * path of webapp(when you connect with [JS SDK](https://github.com/nttcom/SkyWay-MultiParty)). Unique Room ID is made from 'room','locationHost' and 'locationPath'.
*  identity (NSString)
    * user id
* reliable (BOOL)
    * **true** indicates reliable data transfer (data channel). ```default : false```
* selialization (SerializationEnum)
    * set data selialization mode. ```default : BINARY```

    ```
    BINARY
    BINARY_UTF8
    JSON
    NONE
    ```

* constraints(MediaConstraints)
    * MediaConstraints[Android SDK API Reference](https://nttcom.github.io/skyway/docs/#Android-mediaconstraints)
* polling (boolean)
    * **true** indicates check user list via server polling. ```default: true```
* polling_interval (int)
    * polling interval in msec order. ```default: 3000```

* debug (DebugLevelEnum)
    * debug log level appeared in console.
```
NO_LOGS
ONLY_ERROR
ERROR_AND_WARNING
ALL_LOGS
```

* host (NSString)
    * peer server host name. ```default: skyway.io```
* port (number)
    * peer server port number. ```default: 443```
* path (NSString)
    * peer server path. ```default: /```
* secure (BOOL)
    * YES means peer server provide tls.

* config (NSArray)
   * it indicates custom ICE server configuration [IceConfig](https://nttcom.github.io/skyway/docs/#Android-iceconfig).
 * useSkyWayTurn (BOOL)
     * true if you're using SkyWay's TURN server. Defaults to false. You must apply [here](https://skyway.io/ds/turnrequest) to use this feature.

### start

Connect to the SkyWay server and all peers.
```objective-C
MultiParty* multiparty;
[multi start];
```

### on(event,callback)

Set event callback for MultiParty.

* event (MultiPartyEventEnum)
    * event type
* callback
    * Specifies the callback function to call when the event is triggered.


#### 'open'
```objective-C
MultiParty* multiparty;

[multiparty on:MULTIPARTY_EVENT_OPEN callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
	}
}];

```
* Emitted when a connection to SkyWay server has established.
* **peerId** : id of current window.

#### 'MULTIPARTY_EVENT_MY_MS'
```objective-C
[multiparty on:MULTIPARTY_EVENT_MY_MS callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSObject* src = dic[@"src"];
		NSString* peerId = dic[@"id"];
	}
}];
```
* Emitted when this window's video/audio stream has setuped.
* **src** : src for captured stream.
* **peerId** : current window's id.

#### 'MULTIPARTY_EVENT_PEER_MS'
```objective-C
[multiparty on:MULTIPARTY_EVENT_PEER_MS callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
    SKWMediaStream* src = dic[@"src"];
		NSString* peerId = dic[@"id"];
		BOOL reconnect = NO;
		if (nil != numValue)
		{
			reconnect = dic[@"reconnect"];
		}
	}
}];
```
* Emitted when peer's av stream has setuped.
* **src** : Object of peer's stream.
* **peerId** : peer's id.

#### 'MULTIPARTY_EVENT_PEER_SS'
```objective-C
multiparty.on(MultiParty.MultiPartyEventEnum.PEER_SS, new OnCallback() {
  @Override
  public void onCallback(JSONObject object) {
    String peerId = null;
    MediaStream stream = null;
    boolean reconnect = false;
    try
    {
        peerId = object.getString(“id”);
        stream = (MediaStream)object.get("src");
        reconnect = object.getBoolean("reconnect");
    }catch (JSONException e) {
      e.printStackTrace();
    }
  }
});
```
* Emitted when peer's screen captrure stream has setuped.
* **src** : Object of peer's screen capture stream.
* **id** :  peer's id.
* **reconnect** : **true** when connected via reconnect method.

#### 'MULTIPARTY_EVENT_MS_CLOSE'
```objective-C
[multiparty on:MULTIPARTY_EVENT_MS_CLOSE callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
    SKWMediaStream* src = dic[@"src"];
	}
}];
```
* Emitted when peer's media stream has closed.
* **peerId** : peer's id.
* **src** : Object of peer's stream.

#### 'MULTIPARTY_EVENT_SS_CLOSE'
```objective-C
[multiparty on:MULTIPARTY_EVENT_SS_CLOSE callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
		SKWMediaStream* src = dic[@"src"];
	}
}];
```
* Emitted when peer's screen cast stream has closed.
* **peerId** : peer's id.
* **src** : Object of peer's stream.

#### 'MULTIPARTY_EVENT_DC_OPEN'
```objective-C
[multiparty on:MULTIPARTY_EVENT_DC_OPEN callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
	}
}];
```
* Emitted when the connection for data channel with peer is setuped.
* **peerId** : peer's id.

#### 'MULTIPARTY_EVENT_MESSAGE '
```objective-C
[party on:MULTIPARTY_EVENT_MESSAGE callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
		NSData* data = dic[@"data"];
		if (nil != obj)
		{
			if ([obj isKindOfClass:[NSString class]])
			{
				NSString* strValue = (NSString *)obj;
			}
		}
	}
}];
```
* Emitted when receive message from peer.
* **peerId** : peer's id.
* **data** : Received data.

#### 'MULTIPARTY_EVENT_DC_CLOSE'
```objective-C
[multiparty on:MULTIPARTY_EVENT_DC_CLOSE callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
	}
}];
```
* Emitted when data connection has closed with peer.
* **peerId** : peer's id.

#### 'MULTIPARTY_EVENT_ERROR'
```objective-C
[party on:MULTIPARTY_EVENT_ERROR callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
		SKWPeerError* error = dic[@"peerError"];
	}
}];

```

* Emitted when an error occurs.
* **peerId** : peer's id.
* **error** : Error object.[PeerError](https://nttcom.github.io/skyway/docs/#Android-peererror)

### mute

Mute current video/audio.

void mute(boolean video,boolean sudio);

* video (BOOL)
    * YES:mute video NO:unmute video
* audio (BOOL)
    * YES:mute audio NO:unmute audio

```objective-C
[party muteVideo:YES audio:YES];
```

### removePeer

Close peer's media stream and data stream.

(BOOL)removePeer:(NSString \*)peerId;

* peerId (NSString)
    * peerId to be deleted

```objective-C
BOOL result = [party removePeer:peerId];
```

### send

boolean send(Object data)

send data

* data (Object)

```objective-c
String message ＝ ”Hello”；
multiparty.send(MESSAGE);
```

### close

Close every connection.

boolean close();

```objective-c
multiparty.close();
```

### listAllPeers(OnCallback() callback)
Get all of the connected peer ids.

boolean listAllPeers(OnCallback() callback)

```objective-c
party.listAllPeers(new OnCallback() {
  @Override
  public void onCallback(JSONObject object) {
    JSONArray list = null;
    try
    {
      list = object.getJSONArray(“peers”);
    }
    catch (JSONException e) {
    }
});
```


## LICENSE & Copyright

[LICENSE](./LICENSE)
