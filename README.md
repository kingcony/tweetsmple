# iOSアプリとTwitter連携
Social.frameworkまたはUIActivityViewControllerが使えなくなったしまったので、TwitterKit3.4.0で、ツィートするところまで作ってみました。  
手順は  

* Twitter Developersでアプリ登録(本記事では省略)
* TwitterKitのインストール
* プロジェクトの設定
* 認証部実装
* ツィート実行部実装

で、実装しました。

## TwitterKitのインストール
今回はCocoaPodsを使用しました。  
Podfileは

```
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'twitterKitSmp' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for twitterKitSmp
  pod 'TwitterKit'  <-- 追加
end
```
のような感じです。

プロジェクトのディレクトリで

```
% pod init
<Podfileが作成されるので、pod 'TwitterKit'を追加>
% pod install
```

TwitterKitのインストールは以上です。

## プロジェクトの設定
info.plistに下記の追加を行います。

```
<key>CFBundleURLTypes</key>
  <array>
    <dict>
      <!-- 追加ここから -->
      <key>CFBundleURLSchemes</key>
      <array>
        <string>twitterkit-{CONSUMERKEY}</string>
      </array>
      <!-- 追加ここまで -->
    </dict>
  </array>
  <!-- 追加ここから -->
  <key>LSApplicationQueriesSchemes</key>
  <array>
    <string>twitter</string>
    <string>twitterauth</string>
  </array>
  <!-- 追加ここまで -->
```
CFBundleURLTypes.CFBundleURLSchemesとLSApplicationQueriesSchemesを追加します。
CFBundleURLSchemesはTwitterAPI側のCallbackURLにも追記します。

## 認証部実装
まず、TwitterKitの初期設定等を行います。

```swift:AppDelegate.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions
                 launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    // 1. TwitterAPIのAPI keyとAPI secret keyを設定
    TWTRTwitter.sharedInstance().start(withConsumerKey: "{CONSUMERKEY}",
                                       consumerSecret: "{CONSUMERSECRET}")
    return true
  }
  
  func application(_ app: UIApplication, open url: URL, 
                   options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // 2. Twitter認証からのコールバック
    if TWTRTwitter.sharedInstance().application(app, open: url, options: options) {
      return true
    }

    return false
  }
```
  
1. アプリ起動時にTwitterAPIのAPI keyとAPI secret keyを設定します。
2. Twitter認証からのコールバックを受け取ります。

次に認証開始部分を実装します。 　

```swift:ViewController.swift
func sndTweet() {
  // 1.ログインされているか？
  if TWTRTwitter.sharedInstance().sessionStore.hasLoggedInUsers() {
    // 2.ツィート開始
    sndTweetExec()
  } else {
    // 3.認証開始
    TWTRTwitter.sharedInstance().logIn(with: self, completion: { (session, error) in
      if let sess = session {
        print("Signed in as \(sess.userName)")
        // 4.ツィート開始
        self.sndTweetExec()
      } else {
        // 5.認証失敗
        print("login error: \(error?.localizedDescription)")
      }
    })
  }
}
```

1. Twitterにログインされているか確認します。
2. 既にログインされているため、ツィート開始へ進みます。
3. Twitter認証を開始します。Twitterのログイン画面に遷移します。ログイン後、アプリの連携を許可するか聞かれるので許可すればアプリへ戻ります。
4. 認証が成功したのでツィート開始へ進みます。
5. 認証失敗したのでここで終わります。

## ツィート実行部実装
ツィートはTwitterKitのTWTRComposerViewControllerを使用しました。  
またツィート実行後にアラートを出すように実装します。

```swift:ViewController.swift
func sndTweetExec() {
  let str:String = "サンプルツィート"
  
  // 1.コントローラー初期化
  let comp = TWTRComposerViewController.init(initialText: str, image: nil, videoData: nil)
  
  // 2.デレゲート
  comp.delegate = self
  
  // 3.コントローラ表示
  present(comp, animated: true, completion: nil)
}
```

1. TWTRComposerViewControllerを初期化します。今回はテキストのみ。
2. デレゲートを設定します。デレゲートはキャンセルとツィート成功、失敗が定義されています。
3. コントローラーを表示します。

次にデレゲートの処理を実装します。

```swift:ViewController.swift
extension ViewController: TWTRComposerViewControllerDelegate {
  // キャンセル時
  func composerDidCancel(_ controller: TWTRComposerViewController) {
    print("Cancel")
  }
  
  // ツィート失敗時
  func composerDidFail(_ controller: TWTRComposerViewController, withError error: Error) {
    print("Error")
    let store = TWTRTwitter.sharedInstance().sessionStore
    if let userID = store.session()?.userID {
      store.logOutUserID(userID)
    }
    dismiss(animated: false, completion: nil)
    DispatchQueue.main.async {
      self.tweetAlert(memo:"Twitterに投稿に失敗しました")
    }
  }
  
  // ツィート成功時
  func composerDidSucceed(_ controller: TWTRComposerViewController, with tweet: TWTRTweet) {
    print("Ok")
    dismiss(animated: false, completion: nil)
    DispatchQueue.main.async {
      self.tweetAlert(memo: "Twitterに投稿しました。\nご協力ありがとうございます。")
    }
  }

}
```

今回はツィート実行後にアラートを表示したいため、デレゲートメソッド内でdismiss()をコールして、Viewを閉じています。  
DispatchQueue.main.asyncは必要なかったかも知れませんが、念のため。。

## サンプルアプリ
<table>
<tr>
<td>
<img width="200" src="https://raw.githubusercontent.com/kingcony/tweetsmple/master/img/scr1.png">
</td>
<td>
<img width="200" src="https://raw.githubusercontent.com/kingcony/tweetsmple/master/img/scr2.png">
</td>
<td>
<img width="200" src="https://raw.githubusercontent.com/kingcony/tweetsmple/master/img/scr3.png">
</td>
</tr>
</table>
こんな感じのアプリにしてみました。  

## まとめ

以上、ざっとまとめましたが、木になる点として

* CallbackURLが指定できなかった。  
指定方法がありそうな気がしましたが、見つけられませんでした。
* ツィート画面のカスタマイズしたい。  
できそうな感じがしたのですが、今回はできませんでした。  
次回、機会があれば再トライしてみます。

