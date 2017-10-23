日本語 | [English](./README.en.md)

# Deprecated!

このレポジトリは、2018年3月に提供を終了する旧SkyWayのiOS SDK向けMultiPartyライブラリです。[新しいSkyWay](https://webrtc.ecl.ntt.com/?origin=skyway)への移行をお願いします。

すでに新しいSkyWayをご利用の方は、[SKWMeshRoomクラス](https://webrtc.ecl.ntt.com/ios-reference/a00121.html)および[SKWSFURoomクラス](https://webrtc.ecl.ntt.com/ios-reference/a00157.html)をご利用ください。

# Multi Party

SkyWay( http://nttcom.github.io/skyway/ )を用い、多人数参加のグループビデオチャットを簡単に開発できるiOS向けのライブラリです。

## インストール

Podfile
```
pod 'SkyWay-iOS-SDK'
pod 'SkyWay-MultiParty-iOS', :git => 'https://github.com/nttcom/SkyWay-MultiParty-iOS.git'
```

Install
```
pod install
```

## APIリファレンス

### MultiParty

#### プロパティ
* opened (BOOL)
    * MultiPartyの接続状態

#### コンストラクタ
```objective-C
MultiPartyOption* option = [[MultiPartyOption alloc] init];
option.key = @"{API-KEY}";
option.domain = @”{DOMAIN}”;

MultiParty* party = [[MultiParty alloc] initWith options:option];
```
* options (MultiPartyOption)
    * 設定情報オブジェクトを指定

#### MultiPartyOption

 * key (NSString)
     * API key([skyway](https://skyway.io/ds/)から取得)。**必須**。
 * domain (NSString)
     * APIキーに紐付くドメイン([skyway](https://skyway.io/ds/)から登録)。**必須**。
 * room (NSString)
     * ルーム名。room,locationHost,locationPathからユニークなルームIDを作成する。指定がない場合は""
 * locationHost (NSString)
     * [JS版](https://github.com/nttcom/SkyWay-MultiParty)との接続時にWebアプリの設置ホストを指定。room,locationHost,locationPathからユニークなルームIDを作成する。
 * locationPath (NSString)
     * [JS版](https://github.com/nttcom/SkyWay-MultiParty)との接続時にWebアプリの設置パスを指定。room,locationHost,locationPathからユニークなルームIDを作成する。
 *  identity (NSString)
     * 自身のピアID指定。指定がない場合は""
 * reliable (BOOL)
     * データチャンネルで信頼性のあるデータ転送を行う。デフォルト値は **false**。
 * selialization (SerializationEnum)
     * データチャネルでデータシリアライゼーションモードをセットする。デフォルト値はBINARY。

   ```
   BINARY
   BINARY_UTF8
   JSON
   NONE
   ```

 * constraints(MediaConstraints)
     * ローカルメディアストリーム設定オブジェクトを指定。MediaConstraintsは[iOS SDK APIリファレンス](https://nttcom.github.io/skyway/docs/#iOS-mediaconstraints)に準ずる
 * polling (boolean)
     * サーバポーリングによるユーザリストのチェックを許可する。デフォルト値はtrue。
 * polling_interval (int)
     * ポーリング間隔(msec)を設定する。デフォルト値は3000。
 * debug (DebugLevelEnum)
     * デバッグ情報出力レベルを設定する。デフォルト値はNO_LOGS
 ```
 NO_LOGS ログを表示ない
 ONLY_ERROR エラーだけ表示
 ERROR_AND_WARNING エラーと警告だけ表示
 ALL_LOGS すべてのログを表示
 ```
 * host (NSString)
     * peerサーバのホスト名。デフォルト値は"skyway.io"
 * port (int)
     * peerサーバのポート番号。デフォルト値は443
 * path (NSString)
     * peerサーバのpath。デフォルト値は"/"
 * secure (BOOL)
     * peerサーバとの接続にTLSを使用する。デフォルト値はYES
 * config (NSArray).
     * STUN/TURNサーバ設定オブジェクトIceConfigのArrayListを設定する。IceConfigは[iOS SDK APIリファレンス](https://nttcom.github.io/skyway/docs/#iOS-iceconfig)に基づく
 * useSkyWayTurn (BOOL)
     * SkyWayのTURNサーバを使用する場合はtrue。SkyWayのTURNを使用する場合は別途、[TURNサーバ使用申請](https://skyway.io/ds/turnrequest)が必要。デフォルト値はtrue


### start()

SkyWayサーバに接続し、peerに接続します。失敗した場合にはMULTIPARTY_EVENT_ERRORが呼び出されます。
```objective-C
MultiParty* multiparty;
[multi start];
```

### on(event,callback)

各種イベント発生時のコールバックを設定できます。

* event (MultiPartyEventEnum)
    * 設定するイベント種別を指定
* callback
    * イベント発生時に実行するコールバックオブジェクトを設定

#### 'MultiPartyEventEnum.OPEN'
```objective-c
MultiParty* multiparty;

[multiparty on:MULTIPARTY_EVENT_OPEN callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
	}
}];
```
* SkyWayサーバとのコネクションが確立した際に発生します。
* **peerId** : 現在のウィンドウのid

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
* このウィンドウのvideo/audioストリームのセットアップが完了した際に発生します。
* **src** : キャプチャされたストリーム。
* **peerId** : 現在のウィンドウのid。

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
* peerのvideo/audioストリームのセットアップが完了した際に発生します。
* **src** : peerのストリーム。
* **peerId** : peerのid。

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
* peerのスクリーンキャプチャストリームのセットアップが完了した際に発生します。
* **src** : peerのスクリーンキャプチャストリーム。
* **id** : peerのid。
* **reconnect** :reconnectメソッドにより再接続された場合はtrueとなる。

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
* peerのメディアストリームがクローズした際に発生します。
* **peerId** : peerのid。
* **src** : peerのスクリーンキャプチャストリーム。

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
* peerのスクリーンキャストストリームがクローズした際に発生します。
* **peerId** : peerのid。
* **src** : peerのスクリーンキャプチャストリーム。

#### 'MULTIPARTY_EVENT_DC_OPEN'
```objective-C
[multiparty on:MULTIPARTY_EVENT_DC_OPEN callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
	}
}];
```
* データチャンネルのコネクションのセットアップが完了した際に発生します。
* **id** : peerのid。

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
				NSString* strValue = (NSString \*)obj;
			}
		}
	}
}];
```
* peerからメッセージを受信した際に発生します。
* **peerId** : peerのid。
* **data** : 受信したデータ。

#### 'MULTIPARTY_EVENT_DC_CLOSE'
```objective-C
[multiparty on:MULTIPARTY_EVENT_DC_CLOSE callback:^(NSDictionary* dic) {
	if (nil != dic)
	{
		NSString* peerId = dic[@"id"];
	}
}];
```
* データコネクションがクローズした際に発生します。
* **peerId** : peerのid。

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
* エラーが起きたら発生します。
* **peerId** : peerのid。
* **error** : 発生したErrorオブジェクト。[iOS SDK APIリファレンスのPeerErrorクラス](https://nttcom.github.io/skyway/docs/#iOS-peererror)に基づく

### mute(boolean video,boolean audio)
自分の映像と音声をミュートすることができます。

void mute(boolean video,boolean audio);

* video (BOOL)
    * YES:映像を停止 NO:映像を送出
* audio (BOOL)
    * YES:音声を停止 NO:音声を送出

```objective-C
[party muteVideo:YES audio:YES];
```

### removePeer
peerのメディアストリームとデータストリームをクローズします。

(BOOL)removePeer:(NSString \*)peerId;

* peerId (NSString)
    * 切断するリモートピアIDを指定

```objective-C
BOOL result = [party removePeer:peerId];
```

### send

boolean send(Object data)

peerにデータを送信します。

* data (Object)
    * 送信するデータ

```objective-c
NSString* message ＝ @”Hello”；
BOOL result = [party send:message];
```


### close()

コネクションを全て切断します。

-	(void)close

```objective-c
[multiparty close];
```

### listAllPeers(OnCallback() callback)
接続しているpeerのidを取得します。

boolean listAllPeers(OnCallback() callback)

```objective-c
[party listAllPeers:^(NSArray* aryPeers) {
	for (NSString* peerId in aryPeers)
	{
		NSArray* list = [aryPeers copy];
	}
}];
```

## LICENSE & Copyright

[LICENSE](./LICENSE)
